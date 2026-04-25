from __future__ import annotations

import logging
from typing import Any, Dict, List, Optional, Tuple

from langchain_community.vectorstores import FAISS
from langchain_google_genai import ChatGoogleGenerativeAI
from sqlalchemy.orm import Session
from .candidate_retrieval import retrieve_candidates
from .explanation import build_sommelier_explanations
from .filters import apply_hard_filters
from .query_parser import ParsedQuery, parse_query
from .reranker import rerank_candidates
from .scoring import compute_combined_preference_bonus
from .scoring import ScoreBreakdown
from .user_profile import UserTasteProfile, build_user_taste_profile
from .wine_preferences import WinePreferences
from wine_type import normalize_wine_type

logger = logging.getLogger("recommendation")


def recommend_wines(
    *,
    query: str,
    max_budget: float,
    top_k: int,
    vectorstore: FAISS,
    llm: ChatGoogleGenerativeAI,
    db: Optional[Session] = None,
    user_id: Optional[int] = None,
    wine_preferences: Optional[WinePreferences] = None,
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

    user_profile: Optional[UserTasteProfile] = None
    if db is not None and user_id is not None:
        user_profile = build_user_taste_profile(db, user_id)
        if user_profile:
            logger.info(
                "recommend.user_profile_applied",
                extra={"user_id": user_id, "summary": user_profile.summary_text},
            )
        else:
            logger.debug("recommend.no_user_profile", extra={"user_id": user_id})

    reranked = rerank_candidates(
        parsed_query=parsed,
        candidates=filtered,
        max_budget=max_budget,
        top_k=top_k,
        user_profile=user_profile,
        wine_preferences=wine_preferences,
    )

    # Prepare structured attributes for the LLM and final API response.
    wine_payloads: List[Dict[str, Any]] = []
    score_debug: List[Dict[str, Any]] = []

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

        inventory_url = f"https://www.lcbo.com/en/storeinventory?sku={sku}" if sku else None

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

        user_pref_bonus = 0.0
        if user_profile or (wine_preferences and not wine_preferences.is_empty()):
            user_pref_bonus = compute_combined_preference_bonus(
                user_profile, wine_preferences, doc, float(price_val)
            )
        score_debug.append(
            {
                "index": idx,
                "sku": sku,
                "title": title,
                "price": float(price_val),
                "semantic_similarity": float(semantic_sim),
                "taste_profile_bonus": user_pref_bonus,
                "user_preference_bonus": user_pref_bonus,
                "score_breakdown": {
                    "semantic_similarity": breakdown.semantic_similarity,
                    "food_pairing_match": breakdown.food_pairing_match,
                    "style_match": breakdown.style_match,
                    "flavor_profile_match": breakdown.flavor_profile_match,
                    "budget_fit": breakdown.budget_fit,
                    "quality_confidence": breakdown.quality_confidence,
                    "final_score": breakdown.final_score,
                    "user_preference_bonus": user_pref_bonus,
                },
            }
        )

    logger.info(
        "recommend.final_ranking",
        extra={"final_ranking": score_debug},
    )

    # Generate sommelier notes AFTER deterministic ranking.
    llm_input = [
        w["structured"]
        | {
            "sku": w.get("sku"),
            "wine_type": w.get("wine_type"),
            "notes": w["lcbo_tastingnotes"],
        }
        for w in wine_payloads
    ]
    sommelier_notes = build_sommelier_explanations(
        llm=llm,
        parsed_query=parsed,
        wines=llm_input,
        top_k=top_k,
        max_budget=max_budget,
        wine_preferences=wine_preferences,
    )

    for wine, note in zip(wine_payloads, sommelier_notes):
        wine["sommelier_note"] = note

    return wine_payloads, score_debug

