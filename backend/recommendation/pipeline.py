from __future__ import annotations

import logging
from typing import Any, Dict, List, Tuple

from langchain_community.vectorstores import FAISS
from langchain_google_genai import ChatGoogleGenerativeAI
from urllib.parse import quote_plus

from .candidate_retrieval import retrieve_candidates
from .filters import apply_hard_filters
from .query_parser import ParsedQuery, parse_query
from .reranker import rerank_candidates
from .scoring import ScoreBreakdown
from .explanation import build_sommelier_explanations
from wine_type import normalize_wine_type

logger = logging.getLogger("recommendation")


def recommend_wines(
    *,
    query: str,
    max_budget: float,
    top_k: int,
    postal_code: str | None,
    vectorstore: FAISS,
    llm: ChatGoogleGenerativeAI,
) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]]]:
    """
    End-to-end recommendation pipeline:

    user input
        → query understanding
        → candidate retrieval (FAISS)
        → hard filters (budget, validity)
        → structured reranking
        → explanation generation

    Returns:
        - list of response dicts compatible with existing WineResult
        - list of score breakdowns (for logging/debugging)
    """

    parsed: ParsedQuery = parse_query(query)
    logger.info(
        "recommend.parsed_query",
        extra={"parsed_query": parsed.__dict__},
    )

    raw_candidates = retrieve_candidates(vectorstore=vectorstore, query=query, k=100)
    logger.info(
        "recommend.candidate_retrieval",
        extra={"candidate_count_raw": len(raw_candidates)},
    )

    filtered = apply_hard_filters(candidates=raw_candidates, max_budget=max_budget)
    logger.info(
        "recommend.hard_filters",
        extra={"candidate_count_filtered": len(filtered), "max_budget": float(max_budget)},
    )

    if not filtered:
        return [], []

    reranked = rerank_candidates(
        parsed_query=parsed,
        candidates=filtered,
        max_budget=max_budget,
        top_k=top_k,
    )

    # Prepare structured attributes for the LLM and final API response.
    wine_payloads: List[Dict[str, Any]] = []
    score_debug: List[Dict[str, Any]] = []

    pc_clean = postal_code.strip() if postal_code else None

    for idx, (doc, price_val, semantic_sim, breakdown) in enumerate(reranked, start=1):
        m: Dict[str, Any] = doc.metadata or {}

        title = m.get("systitle", "Unknown Wine")
        notes = m.get("lcbo_tastingnotes", "No tasting notes available.")
        normalized_type = normalize_wine_type(
            raw_style=m.get("style") or m.get("wine_style"),
            title=title,
            notes=notes,
        )
        thumb = m.get("ec_thumbnails")
        ec_skus = m.get("ec_skus")
        sku = m.get("permanentid") or (
            ec_skus[0] if isinstance(ec_skus, (list, tuple)) and ec_skus else None
        )

        if pc_clean and sku:
            encoded_postal = quote_plus(pc_clean)
            inventory_url = f"https://www.lcbo.com/en/storeinventory?sku={sku}&postalCode={encoded_postal}"
        elif sku:
            inventory_url = f"https://www.lcbo.com/en/storeinventory?sku={sku}"
        else:
            inventory_url = None

        structured_attrs = {
            "name": title,
            "title": title,
            "price": float(price_val),
            "price_display": f"{float(price_val):.2f}",
            "notes": notes,
            "wine_type": normalized_type,
            # Placeholder structured fields – can be populated from enrichment later:
            "style": m.get("style") or m.get("wine_style"),
            "varietals": m.get("varietals") or [],
            "body": m.get("body"),
            "acidity": m.get("acidity"),
            "tannin": m.get("tannin"),
            "sweetness": m.get("sweetness"),
        }

        wine_payloads.append(
            {
                "systitle": title,
                "ec_final_price": float(price_val),
                "lcbo_tastingnotes": notes,
                "ec_thumbnails": thumb,
                "sku": sku,
                "inventory_url": inventory_url,
                "wine_type": normalized_type,
                "structured": structured_attrs,
            }
        )

        score_debug.append(
            {
                "index": idx,
                "sku": sku,
                "title": title,
                "price": float(price_val),
                "semantic_similarity": float(semantic_sim),
                "score_breakdown": {
                    "semantic_similarity": breakdown.semantic_similarity,
                    "food_pairing_match": breakdown.food_pairing_match,
                    "style_match": breakdown.style_match,
                    "flavor_profile_match": breakdown.flavor_profile_match,
                    "budget_fit": breakdown.budget_fit,
                    "quality_confidence": breakdown.quality_confidence,
                    "final_score": breakdown.final_score,
                },
            }
        )

    logger.info(
        "recommend.final_ranking",
        extra={"final_ranking": score_debug},
    )

    # Generate sommelier notes AFTER deterministic ranking.
    llm_input = [w["structured"] | {"notes": w["lcbo_tastingnotes"]} for w in wine_payloads]
    sommelier_notes = build_sommelier_explanations(
        llm=llm,
        parsed_query=parsed,
        wines=llm_input,
    )

    for wine, note in zip(wine_payloads, sommelier_notes):
        wine["sommelier_note"] = note

    return wine_payloads, score_debug

