from __future__ import annotations

from dataclasses import dataclass
from typing import List, Optional


@dataclass
class ParsedQuery:
    """
    Structured representation of a user's free-text query.

    Budget MUST NOT be parsed here; it always comes from the UI slider.
    """

    raw_query: str
    style: Optional[str]
    dish: Optional[str]
    occasion: Optional[str]
    desired_traits: List[str]
    avoid_traits: List[str]


_STYLE_KEYWORDS = {
    "cabernet": "cabernet sauvignon",
    "cabernet sauvignon": "cabernet sauvignon",
    "pinot noir": "pinot noir",
    "pinot": "pinot noir",
    "chardonnay": "chardonnay",
    "riesling": "riesling",
    "merlot": "merlot",
    "malbec": "malbec",
    "sauvignon blanc": "sauvignon blanc",
    "syrah": "syrah",
    "shiraz": "shiraz",
}

_TRAIT_KEYWORDS = {
    "bold": "bold",
    "full bodied": "full-bodied",
    "full-bodied": "full-bodied",
    "light": "light",
    "crisp": "crisp",
    "fresh": "fresh",
    "dry": "dry",
    "off-dry": "off-dry",
    "sweet": "sweet",
    "oaky": "oaky",
    "smoky": "smoky",
    "fruity": "fruity",
    "earthy": "earthy",
    "spicy": "spicy",
}

_AVOID_PREFIXES = {"no ", "avoid ", "not ", "without "}


def parse_query(query: str) -> ParsedQuery:
    """
    Very lightweight rules-based parser that turns natural language into intent.

    - DOES NOT attempt to parse price or budget.
    - Extracts approximate style + flavour traits.
    - Leaves dish/occasion mostly empty for now (can be enriched later).
    """

    q = (query or "").strip().lower()

    style: Optional[str] = None
    for key, normalized in _STYLE_KEYWORDS.items():
        if key in q:
            style = normalized
            break

    desired_traits: list[str] = []
    avoid_traits: list[str] = []

    for key, trait in _TRAIT_KEYWORDS.items():
        if key in q:
            is_avoid = any(prefix + key in q for prefix in _AVOID_PREFIXES)
            if is_avoid:
                avoid_traits.append(trait)
            else:
                desired_traits.append(trait)

    # TODO: optionally add simple dish / occasion extraction from common phrases.
    dish: Optional[str] = None
    occasion: Optional[str] = None

    return ParsedQuery(
        raw_query=query,
        style=style,
        dish=dish,
        occasion=occasion,
        desired_traits=desired_traits,
        avoid_traits=avoid_traits,
    )

