from __future__ import annotations

import json
from typing import Any, Dict, Optional

from models import MasterWine


def _as_opt_str(v: Any) -> Optional[str]:
    if v is None:
        return None
    return str(v)


def master_wine_from_flat_row(row: dict) -> Optional[MasterWine]:
    """
    Build a MasterWine from a flat dict (legacy SQLite row, JSON record, etc.).
    `sku` must be present (or use import script to inject derived sku before calling).
    """
    clean = {k: v for k, v in row.items() if k != "rowid"}
    sku_raw = clean.get("sku")
    if sku_raw is None or not str(sku_raw).strip():
        return None
    sku = str(sku_raw).strip()
    record = {k: flatten_record_value(v) for k, v in clean.items()}

    def col(key: str) -> Optional[str]:
        return _as_opt_str(clean.get(key))

    return MasterWine(
        sku=sku,
        record_json=record,
        systitle=col("systitle"),
        ec_final_price=col("ec_final_price"),
        ec_thumbnails=col("ec_thumbnails"),
        lcbo_tastingnotes=col("lcbo_tastingnotes"),
        price_numeric=parse_catalog_price(clean.get("ec_final_price")),
        name=col("name"),
        winery=col("winery"),
        vintage=col("vintage"),
        country=col("country"),
        region=col("region"),
        subregion=col("subregion"),
        appellation=col("appellation"),
        varietals_json=col("varietals_json"),
        style=col("style"),
        body=col("body"),
        acidity=col("acidity"),
        tannin=col("tannin"),
        sweetness=col("sweetness"),
        oak=col("oak"),
        alcohol_level=col("alcohol_level"),
        fruit_tags_json=col("fruit_tags_json"),
        savory_tags_json=col("savory_tags_json"),
        floral_tags_json=col("floral_tags_json"),
        spice_tags_json=col("spice_tags_json"),
        earth_tags_json=col("earth_tags_json"),
        food_pairing_tags_json=col("food_pairing_tags_json"),
        currency=col("currency"),
        image_url=col("image_url"),
        lcbo_url=col("lcbo_url"),
        inventory_status=col("inventory_status"),
        quality_confidence=col("quality_confidence"),
        source_type=col("source_type"),
        source_updated_at=col("source_updated_at"),
    )


def flatten_record_value(v: Any) -> Any:
    """Normalize values for JSON storage (matches legacy SQLite TEXT import style)."""
    if v is None:
        return None
    if isinstance(v, (dict, list)):
        return json.dumps(v, ensure_ascii=False)
    if isinstance(v, bool):
        return v
    if isinstance(v, (int, float)):
        return v
    return str(v)


def parse_catalog_price(raw: Any) -> Optional[float]:
    """Parse ec_final_price from catalog (TEXT or numeric) into a float."""
    if raw is None:
        return None
    if isinstance(raw, (int, float)):
        return float(raw)
    s = str(raw).strip()
    if not s:
        return None
    s = s.replace("$", "").split()[0]
    try:
        return float(s)
    except ValueError:
        return None


def master_wine_legacy_dict(mw: MasterWine) -> Dict[str, Any]:
    """
    Flat dict compatible with legacy sqlite3.Row / scan / FAISS consumers.

    JSON snapshot first, then SQL columns overlay (denormalized fields win).
    """
    out: Dict[str, Any] = {}
    if mw.record_json and isinstance(mw.record_json, dict):
        out.update(mw.record_json)
    overlay_keys = (
        "systitle",
        "ec_final_price",
        "ec_thumbnails",
        "lcbo_tastingnotes",
        "style",
        "body",
        "name",
        "winery",
        "vintage",
        "country",
        "region",
        "subregion",
        "appellation",
        "varietals_json",
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
    )
    for key in overlay_keys:
        val = getattr(mw, key, None)
        if val is not None:
            out[key] = val
    out["sku"] = mw.sku
    return out
