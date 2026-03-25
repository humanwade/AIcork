from __future__ import annotations

import os
import sys
from pathlib import Path
from typing import Optional, Set

from sqlalchemy import create_engine, inspect, text
from sqlalchemy.orm import Session, sessionmaker

BACKEND_DIR = Path(__file__).resolve().parents[1]
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from catalog_utils import master_wine_from_flat_row  # noqa: E402
from database import Base  # noqa: E402
from models import MasterWine, ScanHistory, User, UserContributedWine, WineEntry  # noqa: E402


def _sqlite_url() -> str:
    default_path = Path(__file__).resolve().parents[2] / "data" / "pairings.db"
    source_path = os.getenv("SOURCE_SQLITE_PATH", str(default_path))
    return f"sqlite:///{Path(source_path).as_posix()}"


def _postgres_url() -> str:
    url = os.getenv("APP_DATABASE_URL", "").strip()
    if not url:
        raise RuntimeError("APP_DATABASE_URL is required (target PostgreSQL).")
    if not url.startswith("postgresql"):
        raise RuntimeError("APP_DATABASE_URL must point to PostgreSQL for this migration.")
    return url


def _copy_table(
    src: Session,
    dst: Session,
    model,
    valid_user_ids: Optional[Set[int]] = None,
) -> int:
    rows = src.query(model).all()
    if not rows:
        return 0

    columns = [c.name for c in model.__table__.columns]
    inserted = 0
    skipped_orphan_user = 0
    for row in rows:
        payload = {col: getattr(row, col) for col in columns}
        if valid_user_ids is not None and "user_id" in payload:
            user_id = payload.get("user_id")
            if user_id is None or int(user_id) not in valid_user_ids:
                skipped_orphan_user += 1
                continue
        dst.add(model(**payload))
        inserted += 1
    if skipped_orphan_user:
        print(
            f"[migrate] {model.__tablename__}: skipped {skipped_orphan_user} rows with missing users"
        )
    return inserted


def _try_set_replication_role(dst: Session, role: str) -> bool:
    """
    Best-effort FK/trigger bypass for PostgreSQL migration sessions.
    On managed DBs this may fail due to privilege restrictions.
    """
    try:
        dst.execute(text(f"SET session_replication_role = '{role}';"))
        return True
    except Exception as exc:
        print(f"[migrate] session_replication_role={role} skipped: {exc}")
        dst.rollback()
        return False


def _copy_master_wines_raw(src_engine, dst: Session) -> int:
    inspector = inspect(src_engine)
    if "master_wines" not in inspector.get_table_names():
        return 0

    inserted = 0
    with src_engine.connect() as conn:
        result = conn.execution_options(stream_results=True).execute(text("SELECT * FROM master_wines"))
        while True:
            chunk = result.fetchmany(300)
            if not chunk:
                break
            for row in chunk:
                m = row._mapping
                d = dict(m)
                mw = master_wine_from_flat_row(d)
                if mw is None:
                    continue
                dst.merge(mw)
                inserted += 1
            dst.commit()
    return inserted


def main() -> None:
    source_engine = create_engine(
        _sqlite_url(),
        connect_args={"check_same_thread": False},
        pool_pre_ping=True,
    )
    target_engine = create_engine(_postgres_url(), pool_pre_ping=True)

    Base.metadata.create_all(bind=target_engine)

    inspector = inspect(source_engine)
    source_tables = set(inspector.get_table_names())

    SourceSession = sessionmaker(bind=source_engine, autocommit=False, autoflush=False)
    TargetSession = sessionmaker(bind=target_engine, autocommit=False, autoflush=False)

    table_models = [
        ("users", User),
        ("wine_entries", WineEntry),
        ("user_contributed_wines", UserContributedWine),
        ("scan_history", ScanHistory),
    ]

    with TargetSession() as dst:
        dst.execute(
            text(
                "TRUNCATE TABLE master_wines, scan_history, user_contributed_wines, "
                "wine_entries, users RESTART IDENTITY CASCADE"
            )
        )
        dst.commit()

    with SourceSession() as src, TargetSession() as dst:
        total = 0
        replication_role_enabled = _try_set_replication_role(dst, "replica")
        try:
            for table_name, model in table_models:
                if table_name not in source_tables:
                    print(f"[migrate] skip missing source table: {table_name}")
                    continue
                valid_user_ids: Optional[Set[int]] = None
                if table_name != "users" and any(c.name == "user_id" for c in model.__table__.columns):
                    user_ids = src.query(User.id).all()
                    valid_user_ids = {int(uid) for (uid,) in user_ids if uid is not None}
                count = _copy_table(src, dst, model, valid_user_ids=valid_user_ids)
                total += count
                print(f"[migrate] {table_name}: copied {count} rows")
            dst.commit()
            print(f"[migrate] transactional total rows copied: {total}")
        finally:
            if replication_role_enabled:
                _try_set_replication_role(dst, "origin")
                dst.commit()

    with TargetSession() as dst:
        n_master = _copy_master_wines_raw(source_engine, dst)
        print(f"[migrate] master_wines: copied {n_master} rows")
        dst.commit()

    print("[migrate] done.")


if __name__ == "__main__":
    main()
