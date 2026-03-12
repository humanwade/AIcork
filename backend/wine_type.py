from __future__ import annotations

from typing import Optional


ALLOWED_TYPES = {
    "Red",
    "White",
    "Rosé",
    "Sparkling",
    "Dessert",
    "Fortified",
    "Other",
}


def normalize_wine_type(
    raw_style: Optional[str] = None,
    title: str = "",
    notes: str = "",
) -> str:
    """
    Normalize raw style / title / notes into one of the allowed app-facing types:
    Red, White, Rosé, Sparkling, Dessert, Fortified, Other.
    """

    # If raw_style already matches a known type, trust it.
    if raw_style:
        s = raw_style.strip()
        if s in ALLOWED_TYPES:
            return s
        ls = s.lower()
        if "red" in ls:
            return "Red"
        if "white" in ls:
            return "White"
        if "rosé" in ls or "rose" in ls:
            return "Rosé"
        if any(k in ls for k in ("sparkling", "champagne", "prosecco", "cava")):
            return "Sparkling"
        if any(k in ls for k in ("dessert", "icewine", "late harvest")):
            return "Dessert"
        if any(k in ls for k in ("port", "sherry", "madeira", "fortified")):
            return "Fortified"

    text = f"{title} {notes}".lower()

    if any(k in text for k in ("rosé", " rose ")):
        return "Rosé"
    if "sparkling" in text or "champagne" in text or "prosecco" in text or "cava" in text:
        return "Sparkling"
    if "dessert" in text or "icewine" in text or "late harvest" in text:
        return "Dessert"
    if any(k in text for k in ("port", "sherry", "madeira", "fortified")):
        return "Fortified"

    # Generic red / white cues.
    if "red wine" in text:
        return "Red"
    if "white wine" in text:
        return "White"

    # If grape hints are present, map to red/white roughly.
    red_grapes = [
        "cabernet",
        "merlot",
        "pinot noir",
        "malbec",
        "syrah",
        "shiraz",
        "tempranillo",
        "sangiovese",
        "zinfandel",
    ]
    white_grapes = [
        "chardonnay",
        "sauvignon blanc",
        "riesling",
        "pinot grigio",
        "viognier",
        "chenin",
    ]
    if any(g in text for g in red_grapes):
        return "Red"
    if any(g in text for g in white_grapes):
        return "White"

    return "Other"

