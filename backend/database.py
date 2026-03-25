from __future__ import annotations

import os
from pathlib import Path

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, DeclarativeBase


BASE_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = BASE_DIR.parent
APP_SQLITE_PATH = PROJECT_ROOT / "data" / "app.db"


class Base(DeclarativeBase):
    pass


def _db_url() -> str:
    # Primary transactional DB URL (users, auth, cellar, scan history, etc.)
    # Production: set APP_DATABASE_URL (e.g., postgresql+psycopg://...)
    # Local fallback: SQLite
    return os.getenv("APP_DATABASE_URL", f"sqlite:///{APP_SQLITE_PATH.as_posix()}")


def _is_sqlite_url(url: str) -> bool:
    return url.startswith("sqlite")


_DATABASE_URL = _db_url()
_engine_kwargs = {"pool_pre_ping": True}
if _is_sqlite_url(_DATABASE_URL):
    # SQLite requires check_same_thread=False for FastAPI thread usage.
    _engine_kwargs["connect_args"] = {"check_same_thread": False}
engine = create_engine(_DATABASE_URL, **_engine_kwargs)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def init_db() -> None:
    # Ensure local SQLite parent exists only when SQLite is used.
    if _is_sqlite_url(_DATABASE_URL):
        APP_SQLITE_PATH.parent.mkdir(parents=True, exist_ok=True)

    import models  # noqa: F401

    Base.metadata.create_all(bind=engine)

    # Legacy SQLite column patching; skip for PostgreSQL.
    if _is_sqlite_url(_DATABASE_URL):
        _migrate_wine_entries_tasting_columns()


def _migrate_wine_entries_tasting_columns() -> None:
    """Add tasting columns to wine_entries if they do not exist (SQLite)."""
    conn = engine.raw_connection()
    try:
        cur = conn.cursor()
        cur.execute("PRAGMA table_info(wine_entries)")
        existing = {row[1] for row in cur.fetchall()}
        for col, sql in [
            ("tasted_at", "ALTER TABLE wine_entries ADD COLUMN tasted_at DATETIME"),
            ("flavors_json", "ALTER TABLE wine_entries ADD COLUMN flavors_json TEXT"),
            ("aromas_json", "ALTER TABLE wine_entries ADD COLUMN aromas_json TEXT"),
            ("body_style_json", "ALTER TABLE wine_entries ADD COLUMN body_style_json TEXT"),
            ("purchase_notes", "ALTER TABLE wine_entries ADD COLUMN purchase_notes TEXT"),
        ]:
            if col not in existing:
                cur.execute(sql)
                conn.commit()
        cur.close()
    finally:
        conn.close()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

