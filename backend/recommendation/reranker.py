from __future__ import annotations

import logging
from typing import Any, Dict, List, Optional, Tuple

from .query_parser import ParsedQuery
from .scoring import (
    ScoreBreakdown,
    compute_combined_preference_bonus,
    score_candidate,
)
from .user_profile import UserTasteProfile
from .wine_preferences import WinePreferences

logger = logging.getLogger("recommendation")


def rerank_candidates(
    *,
    parsed_query: ParsedQuery,
    candidates: List[Tuple[Any, float, float]],
    max_budget: float,
    top_k: int,
    user_profile: Optional[UserTasteProfile] = None,
    wine_preferences: Optional[WinePreferences] = None,
) -> List[Tuple[Any, float, float, ScoreBreakdown]]:
    """
    Deterministically score & rerank candidates.
    Optionally applies user_preference_bonus from taste profile and/or wine preferences.
    Preferences are soft signals only; never filter results.

    Returns list of (doc, price, semantic_similarity, breakdown) sorted by final_score desc.
    """

    has_prefs = (user_profile is not None) or (
        wine_preferences is not None and not wine_preferences.is_empty()
    )
    if has_prefs:
        prefs_desc = []
        if user_profile:
            prefs_desc.append(
                f"taste_profile(styles={user_profile.preferred_wine_types}, body={user_profile.preferred_body_styles})"
            )
        if wine_preferences and not wine_preferences.is_empty():
            prefs_desc.append(
                f"wine_prefs(styles={wine_preferences.preferred_styles}, body={wine_preferences.preferred_body}, flavors={wine_preferences.preferred_flavors}, budget={wine_preferences.default_budget})"
            )
        logger.info(
            "User preferences detected: %s",
            "; ".join(prefs_desc),
        )

    scored: list[Tuple[Any, float, float, ScoreBreakdown]] = []
    for doc, semantic_sim, price in candidates:
        breakdown = score_candidate(
            parsed_query=parsed_query,
            doc=doc,
            semantic_similarity=semantic_sim,
            price=price,
            max_budget=max_budget,
        )
        scored.append((doc, price, semantic_sim, breakdown))

    def sort_key(item: Tuple[Any, float, float, ScoreBreakdown]) -> float:
        doc, price, _, breakdown = item
        base = breakdown.final_score
        if not has_prefs:
            return base
        bonus = compute_combined_preference_bonus(
            user_profile, wine_preferences, doc, price
        )
        sku = (doc.metadata or {}).get("permanentid")
        logger.debug(
            "Candidate wine scoring: base_score=%.2f user_preference_bonus=%.2f final_score=%.2f (sku=%s)",
            base,
            bonus,
            base + bonus,
            sku,
        )
        return base + bonus

    scored.sort(key=sort_key, reverse=True)
    return scored[:top_k]

