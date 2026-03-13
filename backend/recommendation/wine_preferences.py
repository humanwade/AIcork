"""
Wine Preferences from the UI (Wine Preferences screen).
Used as soft ranking signals, never as hard filters.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import List, Optional


@dataclass
class WinePreferences:
    """User preferences from Wine Preferences screen (stored in Flutter)."""

    preferred_styles: List[str]  # Red, White, Rosé, Sparkling
    preferred_body: str  # Light, Medium, Full
    preferred_flavors: List[str]  # Fruity, Crisp, Bold, Dry, Earthy, Smooth
    default_budget: float

    def is_empty(self) -> bool:
        """True if no meaningful preferences are set."""
        return (
            not any(s and s.strip() for s in self.preferred_styles)
            and not (self.preferred_body and self.preferred_body.strip())
            and not any(f and f.strip() for f in self.preferred_flavors)
            and self.default_budget <= 0
        )
