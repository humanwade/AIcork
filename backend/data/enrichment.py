from __future__ import annotations

import json
import re
import sqlite3
from pathlib import Path
from typing import Any, Dict, Iterable, Tuple

from database import DB_PATH


def _derive_basic_profile(row: Dict[str, Any]) -> Dict[str, Any]:
    """
    Very lightweight enrichment from existing LCBO fields.

    This is intentionally conservative and non-destructive; it can be
    improved over time and re-run as needed.
    """

    systitle = str(row.get("systitle") or "")
    notes = str(row.get("lcbo_tastingnotes") or "")

    name = systitle
    winery = None
    vintage = None

    # Simple vintage extraction from title (4-digit year).
    m = re.search(r"\b(19|20)\d{2}\b", systitle)
    if m:
        vintage = m.group(0)

    # Naive style detection from title.
    title_lower = systitle.lower()
    style = None
    for key in ["cabernet sauvignon", "pinot noir", "chardonnay", "riesling", "merlot", "malbec"]:
        if key in title_lower:
            style = key
            break

    # Very rough body/acidity/tannin cues from tasting notes.
    notes_lower = notes.lower()
    body = None
    if "full-bodied" in notes_lower or "full bodied" in notes_lower:
        body = "full"
    elif "medium-bodied" in notes_lower or "medium bodied" in notes_lower:
        body = "medium"
    elif "light-bodied" in notes_lower or "light bodied" in notes_lower:
        body = "light"

    acidity = None
    if "crisp" in notes_lower or "zesty" in notes_lower or "high acidity" in notes_lower:
        acidity = "high"
    elif "soft" in notes_lower or "low acidity" in notes_lower:
        acidity = "low"

    tannin = None
    if "firm tannin" in notes_lower or "grippy tannin" in notes_lower:
        tannin = "high"
    elif "soft tannin" in notes_lower or "smooth tannin" in notes_lower:
        tannin = "low"

    sweetness = None
    if "off-dry" in notes_lower:
        sweetness = "off-dry"
    elif "sweet" in notes_lower:
        sweetness = "sweet"
    elif "dry" in notes_lower:
        sweetness = "dry"

    return {
        "name": name,
        "winery": winery,
        "vintage": vintage,
        "style": style,
        "body": body,
        "acidity": acidity,
        "tannin": tannin,
        "sweetness": sweetness,
    }


def enrich_master_wines(db_path: Path | None = None, limit: int | None = None) -> None:
    """
    Backfill structured columns on master_wines from existing LCBO fields.

    - Reads from SQLite only (raw JSON file remains untouched).
    - Can be re-run safely; writes deterministic derived values.
    """

    path = db_path or DB_PATH
    if not path.exists():
        raise SystemExit(f"Database not found: {path}")

    con = sqlite3.connect(str(path))
    try:
        con.row_factory = sqlite3.Row
        cur = con.cursor()

        sql = "SELECT rowid, * FROM master_wines"
        if limit is not None:
            sql += " LIMIT ?"
            cur.execute(sql, (int(limit),))
        else:
            cur.execute(sql)

        rows = cur.fetchall()
        update_sql = """
        UPDATE master_wines
        SET
            name = COALESCE(?, name),
            winery = COALESCE(?, winery),
            vintage = COALESCE(?, vintage),
            style = COALESCE(?, style),
            body = COALESCE(?, body),
            acidity = COALESCE(?, acidity),
            tannin = COALESCE(?, tannin),
            sweetness = COALESCE(?, sweetness)
        WHERE rowid = ?
        """

        for r in rows:
            derived = _derive_basic_profile(dict(r))
            cur.execute(
                update_sql,
                (
                    derived["name"],
                    derived["winery"],
                    derived["vintage"],
                    derived["style"],
                    derived["body"],
                    derived["acidity"],
                    derived["tannin"],
                    derived["sweetness"],
                    r["rowid"],
                ),
            )

        con.commit()
    finally:
        con.close()


if __name__ == "__main__":
    enrich_master_wines()

