"""
Lightweight rule-based user taste profile inference from Tried wines.

Prioritizes high-rated entries. Does not use AI.
"""

from __future__ import annotations

import logging
from collections import Counter
from dataclasses import dataclass
from typing import List, Optional

from sqlalchemy.orm import Session

from models import WineEntry

logger = logging.getLogger("recommendation")

# Minimum Tried entries with ratings to build a profile
MIN_TRIED_ENTRIES = 3

# Rating threshold: treat as "liked" if >= this
MIN_LIKED_RATING = 4.0

# Top N to consider for aggregation
TOP_WINE_TYPES = 3
TOP_FLAVORS = 5
TOP_BODY_STYLES = 3


@dataclass
class UserTasteProfile:
    preferred_wine_types: List[str]
    preferred_flavors: List[str]
    preferred_body_styles: List[str]
    average_preferred_price: Optional[float]
    avoid_traits: List[str]
    summary_text: Optional[str]

    def to_dict(self) -> dict:
        return {
            "preferred_wine_types": self.preferred_wine_types,
            "preferred_flavors": self.preferred_flavors,
            "preferred_body_styles": self.preferred_body_styles,
            "average_preferred_price": self.average_preferred_price,
            "avoid_traits": self.avoid_traits,
            "summary_text": self.summary_text,
        }


def build_user_taste_profile(db: Session, user_id: int) -> Optional[UserTasteProfile]:
    """
    Infer a lightweight taste profile from Tried wines, prioritizing higher-rated entries.

    Returns None if insufficient Tried history.
    """
    entries: List[WineEntry] = (
        db.query(WineEntry)
        .filter(WineEntry.user_id == user_id, WineEntry.is_tried == True)
        .all()
    )

    if len(entries) < MIN_TRIED_ENTRIES:
        logger.debug(
            "user_profile.insufficient_tried",
            extra={"user_id": user_id, "entries": len(entries)},
        )
        return None

    # Split into liked (high-rated) and disliked (low-rated)
    rated = [e for e in entries if e.rating is not None]
    if len(rated) < MIN_TRIED_ENTRIES:
        return None

    liked = [e for e in rated if e.rating >= MIN_LIKED_RATING]
    disliked = [e for e in rated if e.rating < 3.0]

    if not liked:
        return None

    # Aggregate from liked
    wine_type_counts: Counter = Counter()
    flavor_counts: Counter = Counter()
    body_counts: Counter = Counter()
    prices: List[float] = []

    for e in liked:
        if e.wine_type and e.wine_type.strip():
            wine_type_counts[e.wine_type.strip()] += 1
        if e.flavors:
            for f in e.flavors:
                if f and f.strip():
                    flavor_counts[f.strip().lower()] += 1
        if e.body_style:
            for b in e.body_style:
                if b and b.strip():
                    body_counts[b.strip().lower()] += 1
        if e.price is not None and e.price > 0:
            prices.append(float(e.price))

    preferred_wine_types = [
        t for t, _ in wine_type_counts.most_common(TOP_WINE_TYPES)
    ]
    preferred_flavors = [f for f, _ in flavor_counts.most_common(TOP_FLAVORS)]
    preferred_body_styles = [
        b for b, _ in body_counts.most_common(TOP_BODY_STYLES)
    ]

    average_preferred_price = (
        sum(prices) / len(prices) if prices else None
    )

    # Optional avoid traits from low-rated entries
    avoid_traits: List[str] = []
    for e in disliked:
        if e.flavors:
            for f in e.flavors:
                if f and f.strip():
                    avoid_traits.append(f.strip().lower())
    avoid_traits = list(dict.fromkeys(avoid_traits))[:5]

    # Build summary text (compact, human-readable)
    parts: List[str] = []
    if preferred_wine_types:
        wine_str = " and ".join(preferred_wine_types[:2]).lower()
        parts.append(f"You tend to enjoy {wine_str} wines.")
    if preferred_body_styles and average_preferred_price is not None:
        body_str = ", ".join(preferred_body_styles[:2]).lower()
        high = int(average_preferred_price * 1.2)
        parts.append(f"You often prefer {body_str} under ${high}.")
    elif average_preferred_price is not None:
        high = int(average_preferred_price * 1.2)
        parts.append(f"You often prefer bottles under ${high}.")
    summary_text = " ".join(parts).strip() or None

    profile = UserTasteProfile(
        preferred_wine_types=preferred_wine_types,
        preferred_flavors=preferred_flavors,
        preferred_body_styles=preferred_body_styles,
        average_preferred_price=average_preferred_price,
        avoid_traits=avoid_traits,
        summary_text=summary_text,
    )

    logger.info(
        "user_profile.built",
        extra={
            "user_id": user_id,
            "tried_count": len(entries),
            "liked_count": len(liked),
            "profile": profile.to_dict(),
        },
    )
    return profile
