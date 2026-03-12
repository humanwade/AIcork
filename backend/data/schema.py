from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import List, Optional


@dataclass
class StructuredWine:
    """
    Structured wine record used by the recommendation engine.

    This is a logical schema that maps onto SQLite columns in master_wines.
    The raw LCBO JSON remains the source of truth; these fields are
    derived / enriched for recommendation use.
    """

    id: Optional[int]
    sku: str
    name: str
    winery: Optional[str]
    vintage: Optional[str]
    country: Optional[str]
    region: Optional[str]
    subregion: Optional[str]
    appellation: Optional[str]
    varietals_json: Optional[str]
    style: Optional[str]
    body: Optional[str]
    acidity: Optional[str]
    tannin: Optional[str]
    sweetness: Optional[str]
    oak: Optional[str]
    alcohol_level: Optional[float]
    fruit_tags_json: Optional[str]
    savory_tags_json: Optional[str]
    floral_tags_json: Optional[str]
    spice_tags_json: Optional[str]
    earth_tags_json: Optional[str]
    food_pairing_tags_json: Optional[str]
    price: float
    currency: str
    image_url: Optional[str]
    lcbo_url: Optional[str]
    inventory_status: Optional[str]
    quality_confidence: Optional[float]
    source_type: Optional[str]
    source_updated_at: Optional[datetime]

