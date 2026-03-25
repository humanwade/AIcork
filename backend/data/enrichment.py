from __future__ import annotations

import re
from typing import Any, Dict, Optional

from sqlalchemy.orm import Session

from catalog_utils import master_wine_legacy_dict
from database import SessionLocal
from models import MasterWine


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

    m = re.search(r"\b(19|20)\d{2}\b", systitle)
    if m:
        vintage = m.group(0)

    title_lower = systitle.lower()
    style = None
    for key in ["cabernet sauvignon", "pinot noir", "chardonnay", "riesling", "merlot", "malbec"]:
        if key in title_lower:
            style = key
            break

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


def enrich_master_wines(session: Optional[Session] = None, limit: int | None = None) -> None:
    """
    Backfill structured columns on master_wines from existing LCBO fields.

    Uses the application database (APP_DATABASE_URL). Safe to re-run.
    """

    own = session is None
    db = session or SessionLocal()
    try:
        q = db.query(MasterWine)
        if limit is not None:
            q = q.limit(int(limit))
        for mw in q:
            derived = _derive_basic_profile(master_wine_legacy_dict(mw))
            for field in ("name", "winery", "vintage", "style", "body", "acidity", "tannin", "sweetness"):
                v = derived.get(field)
                if v is not None:
                    setattr(mw, field, v)
        db.commit()
    finally:
        if own:
            db.close()


if __name__ == "__main__":
    enrich_master_wines()
