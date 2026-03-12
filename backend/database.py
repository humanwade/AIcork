from __future__ import annotations

from pathlib import Path

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, DeclarativeBase


BASE_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = BASE_DIR.parent
DB_PATH = PROJECT_ROOT / "data" / "pairings.db"


class Base(DeclarativeBase):
    pass


def _db_url() -> str:
    # SQLite file relative to project root
    return f"sqlite:///{DB_PATH.as_posix()}"


engine = create_engine(
    _db_url(),
    connect_args={"check_same_thread": False},  # FastAPI threads
    pool_pre_ping=True,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def init_db() -> None:
    # Ensure data directory exists
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    import models  # noqa: F401

    Base.metadata.create_all(bind=engine)
    _migrate_wine_entries_tasting_columns()
    # Extend master_wines schema for structured recommendation fields (non-destructive).
    try:
        from data.migrations import migrate_master_wines_schema

        migrate_master_wines_schema(DB_PATH)
    except Exception as exc:
        # Migration failures should not bring the app down; log and continue.
        print(f"[migrations] master_wines schema migration failed: {exc}")


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

