from __future__ import annotations

from typing import Any, Dict, List, Tuple

from .query_parser import ParsedQuery
from .scoring import ScoreBreakdown, score_candidate


def rerank_candidates(
    *,
    parsed_query: ParsedQuery,
    candidates: List[Tuple[Any, float, float]],
    max_budget: float,
    top_k: int,
) -> List[Tuple[Any, float, float, ScoreBreakdown]]:
    """
    Deterministically score & rerank candidates.

    Returns list of (doc, price, semantic_similarity, breakdown) sorted by final_score desc.
    """

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

    scored.sort(key=lambda x: x[3].final_score, reverse=True)
    return scored[:top_k]

