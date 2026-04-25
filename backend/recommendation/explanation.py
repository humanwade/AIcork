from __future__ import annotations

from dataclasses import asdict
from typing import Any, Dict, List, Optional

import re
from langchain_google_genai import ChatGoogleGenerativeAI

from .cache import (
    build_cache_key,
    get_cached_notes,
    hash_preferences,
    normalize_query,
    save_cached_notes,
)
from .query_parser import ParsedQuery
from .wine_preferences import WinePreferences


def _sanitize_markdown_to_plain(text: str) -> str:
    """
    Convert lightly-formatted markdown-like text into plain, UI-safe text.

    - Strips **bold**, __underline__, and *italic* markers.
    - Removes leading bullet symbols (-, •) while keeping numbered sections.
    - Normalizes whitespace while preserving single blank lines between sections.
    """

    if not text:
        return ""

    t = text.replace("\r\n", "\n").replace("\r", "\n")

    # Remove common emphasis markers.
    t = re.sub(r"\*\*(.*?)\*\*", r"\1", t)
    t = re.sub(r"__(.*?)__", r"\1", t)
    t = re.sub(r"\*(.*?)\*", r"\1", t)

    # Strip simple bullet prefixes but keep numbered items like "1)".
    t = re.sub(r"^\s*[-•]\s+", "", t, flags=re.MULTILINE)

    # Collapse excessive blank lines to at most 2.
    t = re.sub(r"\n{3,}", "\n\n", t)

    # Normalize internal spaces but keep newlines.
    lines = [re.sub(r"[ \t]+", " ", line).strip() for line in t.split("\n")]
    t = "\n".join([ln for ln in lines if ln is not None])

    return t.strip()


def build_sommelier_explanations(
    *,
    llm: ChatGoogleGenerativeAI,
    parsed_query: ParsedQuery,
    wines: List[Dict[str, Any]],
    top_k: int,
    max_budget: float,
    wine_preferences: Optional[WinePreferences] = None,
) -> List[str]:
    """
    Use Gemini to generate structured sommelier explanations.

    Each wine dict should contain pre-extracted, structured attributes, not just
    free-form tasting notes.
    """

    if not wines:
        return []

    normalized_query = normalize_query(parsed_query.raw_query)
    sku_list = [str(w.get("sku") or "") for w in wines]
    prefs_payload = asdict(wine_preferences) if wine_preferences else None
    preferences_hash = hash_preferences(prefs_payload)
    cache_key = build_cache_key(
        normalized_query=normalized_query,
        sku_list=sku_list,
        top_k=top_k,
        max_budget=max_budget,
        preferences_hash=preferences_hash,
    )
    cached = get_cached_notes(cache_key=cache_key)
    if cached and len(cached) == len(wines):
        return cached

    # High-level system-style guidance
    lines: List[str] = []
    lines.append("You are a professional LCBO sommelier in Canada.")
    lines.append(
        "You receive a list of wines with structured attributes and LCBO tasting notes. "
        "For each wine, explain why it fits the user's request."
    )
    lines.append("")
    lines.append("[User Query]")
    lines.append(parsed_query.raw_query)
    lines.append("")
    lines.append(
        "For each wine, respond using this exact 4-part numbered structure in PLAIN TEXT (no markdown):"
    )
    lines.append("1) Summary: <one concise sentence>")
    lines.append(
        "2) Pairing Logic: <2–3 sentences connecting tannin, acidity, body, sweetness, oak and flavours "
        "to the user's dish or occasion if mentioned. Reuse at least two concrete tasting-note keywords.>"
    )
    lines.append(
        "3) Flavor Bridge: <1–2 sentences explaining how the flavour profile (fruit, spice, earth, floral, savoury) "
        "connects to the user's preferences or food.>"
    )
    lines.append(
        "4) Serving Tip: <1 sentence with a practical serving suggestion (temperature, decanting, or simple side dish).>"
    )
    lines.append("")
    lines.append(
        "IMPORTANT OUTPUT RULES (MUST FOLLOW): "
        "Do NOT use markdown (no **bold**, no __underline__, no bullet lists). "
        "Do NOT use asterisks or underscores for formatting. "
        "Return plain text only, with line breaks between 1)–4)."
    )
    lines.append("")
    lines.append(
        'For each wine below, respond in order with a block that starts with "[Wine #<index>]" on its own line, '
        "followed by lines 1–4 in plain text. Do not add any commentary between wines."
    )
    lines.append("")

    for idx, wine in enumerate(wines, start=1):
        lines.append(f"[Wine #{idx}]")
        lines.append(f"Name: {wine.get('name') or wine.get('title')}")
        lines.append(f"Price: {wine.get('price_display', 'N/A')}")
        if wine.get("style"):
            lines.append(f"Style: {wine['style']}")
        if wine.get("varietals"):
            lines.append(f"Varietals: {', '.join(wine['varietals'])}")
        if wine.get("body"):
            lines.append(f"Body: {wine['body']}")
        if wine.get("acidity"):
            lines.append(f"Acidity: {wine['acidity']}")
        if wine.get("tannin"):
            lines.append(f"Tannin: {wine['tannin']}")
        if wine.get("sweetness"):
            lines.append(f"Sweetness: {wine['sweetness']}")
        lines.append("LCBO Tasting Notes:")
        raw_notes = str(wine.get("notes") or "No tasting notes available.")
        lines.append(raw_notes[:500])
        lines.append("")

    prompt = "\n".join(lines)
    try:
        raw_msg = llm.invoke(prompt)

        if hasattr(raw_msg, "text") and raw_msg.text:
            raw_text = raw_msg.text
        elif isinstance(raw_msg.content, str):
            raw_text = raw_msg.content
        else:
            raw_text = "\n".join(
                block.get("text", "")
                for block in raw_msg.content
                if isinstance(block, dict) and block.get("type") == "text"
            )

        # Parse back into per-wine notes keyed by "[Wine #i]"
        result_notes: List[str] = ["" for _ in wines]
        current_index: Optional[int] = None
        buffer: List[str] = []
        wine_header_re = re.compile(r"\[?Wine\s*#?\s*(\d+)\]?", re.IGNORECASE)

        for line in (raw_text or "").splitlines():
            stripped = line.strip()
            match = wine_header_re.match(stripped)
            if match:
                if current_index is not None and 1 <= current_index <= len(wines):
                    result_notes[current_index - 1] = "\n".join(buffer).strip()
                buffer = []
                current_index = int(match.group(1))
            else:
                if current_index is not None:
                    buffer.append(line)

        if current_index is not None and 1 <= current_index <= len(wines):
            result_notes[current_index - 1] = "\n".join(buffer).strip()

        raw_stripped = (raw_text or "").strip()
        for i, note in enumerate(result_notes):
            cleaned = note.strip()
            if not cleaned:
                if raw_stripped and i == 0:
                    cleaned = raw_stripped
                else:
                    cleaned = "Sommelier note could not be generated for this wine."
            result_notes[i] = _sanitize_markdown_to_plain(cleaned)

        save_cached_notes(
            cache_key=cache_key,
            normalized_query=normalized_query,
            sku_list=sku_list,
            top_k=top_k,
            max_budget=max_budget,
            preferences_hash=preferences_hash,
            response_notes=result_notes,
        )
        return result_notes
    except Exception:
        print("[recommend] Gemini failed, using fallback sommelier notes")
        fallback_notes: List[str] = []
        for wine in wines:
            wine_type = str(wine.get("wine_type") or "").strip()
            notes = str(wine.get("notes") or "").strip()
            note_prefix = (
                f"This {wine_type.lower()} wine was selected based on similarity to your request, "
                "price fit, and available tasting notes."
                if wine_type
                else "This wine was selected based on similarity to your request, price fit, and available tasting notes."
            )
            if notes:
                short = notes[:160].strip()
                fallback_notes.append(f"{note_prefix} Key note: {short}")
            else:
                fallback_notes.append(note_prefix)
        return fallback_notes



