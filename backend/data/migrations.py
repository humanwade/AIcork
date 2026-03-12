from __future__ import annotations

import sqlite3
from pathlib import Path
from typing import Iterable, Tuple

from . import schema  # noqa: F401
from database import DB_PATH


def _ensure_column(
    cur: sqlite3.Cursor,
    table: str,
    column: str,
    ddl: str,
) -> None:
    cur.execute(f"PRAGMA table_info({table})")
    existing = {row[1] for row in cur.fetchall()}
    if column not in existing:
        cur.execute(ddl)


def migrate_master_wines_schema(db_path: Path | None = None) -> None:
    """
    Incrementally extend the master_wines table with structured columns.

    This migration is additive and non-destructive:
    - raw JSON-derived columns remain untouched
    - new columns are nullable and can be backfilled gradually
    """

    path = db_path or DB_PATH
    if not path.exists():
        # Nothing to migrate yet.
        return

    con = sqlite3.connect(str(path))
    try:
        cur = con.cursor()

        # Base structured fields
        _ensure_column(
            cur,
            "master_wines",
            "name",
            'ALTER TABLE master_wines ADD COLUMN name TEXT',
        )
        _ensure_column(
            cur,
            "master_wines",
            "winery",
            'ALTER TABLE master_wines ADD COLUMN winery TEXT',
        )
        _ensure_column(
            cur,
            "master_wines",
            "vintage",
            'ALTER TABLE master_wines ADD COLUMN vintage TEXT',
        )
        _ensure_column(
            cur,
            "master_wines",
            "country",
            'ALTER TABLE master_wines ADD COLUMN country TEXT',
        )
        _ensure_column(
            cur,
            "master_wines",
            "region",
            'ALTER TABLE master_wines ADD COLUMN region TEXT',
        )
        _ensure_column(
            cur,
            "master_wines",
            "subregion",
            'ALTER TABLE master_wines ADD COLUMN subregion TEXT',
        )
        _ensure_column(
            cur,
            "master_wines",
            "appellation",
            'ALTER TABLE master_wines ADD COLUMN appellation TEXT',
        )

        # Profile fields
        for col in [
            "varietals_json",
            "style",
            "body",
            "acidity",
            "tannin",
            "sweetness",
            "oak",
            "alcohol_level",
            "fruit_tags_json",
            "savory_tags_json",
            "floral_tags_json",
            "spice_tags_json",
            "earth_tags_json",
            "food_pairing_tags_json",
            "currency",
            "image_url",
            "lcbo_url",
            "inventory_status",
            "quality_confidence",
            "source_type",
            "source_updated_at",
        ]:
            _ensure_column(
                cur,
                "master_wines",
                col,
                f'ALTER TABLE master_wines ADD COLUMN {col} TEXT',
            )

        con.commit()
    finally:
        con.close()

