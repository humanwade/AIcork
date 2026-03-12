from __future__ import annotations

from typing import Any, Dict, List, Tuple

from langchain_community.vectorstores import FAISS


def retrieve_candidates(
    *,
    vectorstore: FAISS,
    query: str,
    k: int = 100,
) -> List[Tuple[Any, float]]:
    """
    Retrieve semantic candidates from FAISS, returning (Document, semantic_similarity).

    Uses similarity_search_with_score so downstream scoring can combine
    deterministic features with semantic similarity.
    """

    # LangChain FAISS returns (Document, distance). We invert distance to a
    # bounded similarity score in [0, 1].
    results_with_scores = vectorstore.similarity_search_with_score(query, k=k)

    candidates: List[Tuple[Any, float]] = []
    for doc, distance in results_with_scores:
        try:
            # Distance is usually smaller for closer vectors; convert to similarity.
            # This is a heuristic; we simply squash into (0, 1].
            sim = 1.0 / (1.0 + float(distance))
        except Exception:
            sim = 0.0
        candidates.append((doc, sim))

    return candidates

