from __future__ import annotations

import logging
from dataclasses import dataclass
from typing import TYPE_CHECKING, Any, Dict, List, Optional, Tuple

from .query_parser import ParsedQuery
from wine_type import normalize_wine_type

if TYPE_CHECKING:
    from .user_profile import UserTasteProfile
    from .wine_preferences import WinePreferences

logger = logging.getLogger("recommendation")

# Clamp user preference bonus to avoid overpowering query intent.
# Preferences must NEVER dominate the ranking.
USER_PREF_BONUS_MIN = -0.05
USER_PREF_BONUS_MAX = 0.10


@dataclass
class ScoreBreakdown:
    semantic_similarity: float
    food_pairing_match: float
    style_match: float
    flavor_profile_match: float
    budget_fit: float
    quality_confidence: float

    @property
    def final_score(self) -> float:
        return (
            0.30 * self.semantic_similarity
            + 0.20 * self.food_pairing_match
            + 0.15 * self.style_match
            + 0.15 * self.flavor_profile_match
            + 0.10 * self.budget_fit
            + 0.10 * self.quality_confidence
        )


def _safe_lower(s: Optional[str]) -> str:
    return (s or "").strip().lower()


def _style_match_score(parsed: ParsedQuery, meta: Dict[str, Any]) -> float:
    desired = _safe_lower(parsed.style)
    if not desired:
        return 0.0

    title = _safe_lower(meta.get("systitle"))
    style = _safe_lower(meta.get("style") or meta.get("wine_style"))

    if desired in style or desired in title:
        return 1.0

    # mild partial match heuristic
    if any(tok in title for tok in desired.split()):
        return 0.6
    return 0.0


def _budget_fit_score(price: float, max_budget: float) -> float:
    """
    Reward wines that are close to, but not over, the budget.
    Always in [0, 1].
    """

    if max_budget <= 0:
        return 0.0
    if price > max_budget:
        return 0.0

    # Linear ramp: perfect when using ~90% of budget, lower when far below.
    ratio = price / max_budget
    if ratio >= 0.9:
        return 1.0
    if ratio <= 0.4:
        return 0.3
    # interpolate between 0.3 and 1.0
    return 0.3 + (ratio - 0.4) * (1.0 - 0.3) / (0.9 - 0.4)


def _flavor_profile_match_score(parsed: ParsedQuery, meta: Dict[str, Any]) -> float:
    notes = _safe_lower(meta.get("lcbo_tastingnotes"))
    if not notes:
        return 0.0
    if not parsed.desired_traits and not parsed.avoid_traits:
        return 0.0

    score = 0.0
    for trait in parsed.desired_traits:
        if trait in notes:
            score += 0.25
    for trait in parsed.avoid_traits:
        if trait and trait in notes:
            score -= 0.25

    return max(0.0, min(1.0, score))


def _food_pairing_match_score(parsed: ParsedQuery, meta: Dict[str, Any]) -> float:
    # Until we have explicit food tags, we approximate via tasting notes text.
    if not parsed.dish:
        return 0.0
    notes = _safe_lower(meta.get("lcbo_tastingnotes"))
    if not notes:
        return 0.0
    return 0.7 if any(tok in notes for tok in parsed.dish.split()) else 0.0


def _quality_confidence_score(meta: Dict[str, Any]) -> float:
    """
    Placeholder: use explicit quality_confidence if present, else neutral prior.
    """

    qc = meta.get("quality_confidence")
    if isinstance(qc, (int, float)):
        # assume qc already in [0,1] or some known scale
        if 0.0 <= float(qc) <= 1.0:
            return float(qc)
    # neutral default; can be improved with ratings / LCBO metadata.
    return 0.6


def score_candidate(
    *,
    parsed_query: ParsedQuery,
    doc: Any,
    semantic_similarity: float,
    price: float,
    max_budget: float,
) -> ScoreBreakdown:
    """
    Compute a structured, deterministic score for a single wine candidate.
    """

    meta: Dict[str, Any] = doc.metadata or {}

    food_pairing_match = _food_pairing_match_score(parsed_query, meta)
    style_match = _style_match_score(parsed_query, meta)
    flavor_profile_match = _flavor_profile_match_score(parsed_query, meta)
    budget_fit = _budget_fit_score(price, max_budget)
    quality_confidence = _quality_confidence_score(meta)

    return ScoreBreakdown(
        semantic_similarity=float(semantic_similarity),
        food_pairing_match=food_pairing_match,
        style_match=style_match,
        flavor_profile_match=flavor_profile_match,
        budget_fit=budget_fit,
        quality_confidence=quality_confidence,
    )


def compute_user_preference_bonus(
    profile: "UserTasteProfile",
    doc: Any,
    price: float,
) -> float:
    """
    Compute a small bonus/penalty based on user taste profile.
    Clamped to [USER_PREF_BONUS_MIN, USER_PREF_BONUS_MAX].
    """
    meta: Dict[str, Any] = doc.metadata or {}
    bonus = 0.0

    # Wine type match (normalize candidate to app types: Red, White, Rosé, etc.)
    cand_type = normalize_wine_type(
        raw_style=meta.get("style") or meta.get("wine_style"),
        title=meta.get("systitle") or "",
        notes=meta.get("lcbo_tastingnotes") or "",
    )
    for pref in profile.preferred_wine_types:
        if pref and pref.strip() and pref.strip() == cand_type:
            bonus += 0.04
            break

    # Flavor overlap (from tasting notes)
    notes = _safe_lower(meta.get("lcbo_tastingnotes") or "")
    for pf in profile.preferred_flavors:
        if pf in notes:
            bonus += 0.02
            break

    # Body/style overlap
    cand_body = _safe_lower(str(meta.get("body") or ""))
    for pb in profile.preferred_body_styles:
        if pb in cand_body:
            bonus += 0.03
            break

    # Price proximity
    if profile.average_preferred_price is not None and profile.average_preferred_price > 0:
        ratio = price / profile.average_preferred_price
        if 0.7 <= ratio <= 1.3:
            bonus += 0.03
        elif 0.5 <= ratio <= 1.5:
            bonus += 0.01

    # Avoid traits penalty
    for avoid in profile.avoid_traits:
        if avoid and avoid in notes:
            bonus -= 0.05
            break

    clamped = max(USER_PREF_BONUS_MIN, min(USER_PREF_BONUS_MAX, bonus))
    return clamped


def compute_combined_preference_bonus(
    profile: Optional["UserTasteProfile"],
    prefs: Optional["WinePreferences"],
    doc: Any,
    price: float,
) -> float:
    """
    Combine taste profile (from DB) and wine preferences (from UI) into one bonus.
    Clamped to [USER_PREF_BONUS_MIN, USER_PREF_BONUS_MAX].
    Returns 0 if both are None/empty.
    """
    total = 0.0
    if profile:
        total += compute_user_preference_bonus(profile, doc, price)
    if prefs and not prefs.is_empty():
        total += compute_wine_preference_bonus(prefs, doc, price)
    return max(USER_PREF_BONUS_MIN, min(USER_PREF_BONUS_MAX, total))


def compute_wine_preference_bonus(
    prefs: "WinePreferences",
    doc: Any,
    price: float,
) -> float:
    """
    Compute a small bonus from Wine Preferences (UI settings).
    Used as soft ranking signal only; never filters.
    Clamped to [USER_PREF_BONUS_MIN, USER_PREF_BONUS_MAX].
    """
    if prefs.is_empty():
        return 0.0

    meta: Dict[str, Any] = doc.metadata or {}
    bonus = 0.0

    # 1. Wine style match
    cand_type = normalize_wine_type(
        raw_style=meta.get("style") or meta.get("wine_style"),
        title=meta.get("systitle") or "",
        notes=meta.get("lcbo_tastingnotes") or "",
    )
    for pref in prefs.preferred_styles:
        if pref and pref.strip() and pref.strip() == cand_type:
            bonus += 0.04
            break

    # 2. Body match
    cand_body = _safe_lower(str(meta.get("body") or ""))
    pref_body = _safe_lower(prefs.preferred_body or "")
    if pref_body and pref_body in cand_body:
        bonus += 0.03

    # 3. Flavor profile match (tasting notes text)
    notes = _safe_lower(meta.get("lcbo_tastingnotes") or "")
    for pf in prefs.preferred_flavors:
        if pf and pf.strip() and _safe_lower(pf) in notes:
            bonus += 0.02
            break

    # 4. Budget proximity
    if prefs.default_budget and prefs.default_budget > 0:
        ratio = price / prefs.default_budget
        if 0.7 <= ratio <= 1.3:
            bonus += 0.03
        elif 0.5 <= ratio <= 1.5:
            bonus += 0.01

    clamped = max(USER_PREF_BONUS_MIN, min(USER_PREF_BONUS_MAX, bonus))
    return clamped

