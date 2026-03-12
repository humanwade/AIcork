from __future__ import annotations

from typing import Any, Dict, Iterable, List, Tuple


def apply_hard_filters(
    *,
    candidates: Iterable[Tuple[Any, float]],
    max_budget: float,
) -> List[Tuple[Any, float, float]]:
    """
    Apply hard filters (price, validity) before ranking.

    Returns a list of (doc, semantic_similarity, price).
    """

    budget = float(max_budget)
    kept: list[Tuple[Any, float, float]] = []

    for doc, semantic_sim in candidates:
        m: Dict[str, Any] = doc.metadata or {}
        raw_price = m.get("ec_final_price")
        try:
            price_val = float(raw_price)
        except (TypeError, ValueError):
            # Skip records without a usable price; they can't satisfy budget anyway.
            continue

        if price_val <= budget and price_val > 0:
            kept.append((doc, float(semantic_sim), price_val))

    return kept

