from __future__ import annotations

import random
import sqlite3
from dataclasses import dataclass
from pathlib import Path
from typing import TYPE_CHECKING, Any, Dict, List, Optional, Tuple

from sqlalchemy.orm import Session

from database import PROJECT_ROOT
from models import WineEntry
from wine_type import normalize_wine_type

if TYPE_CHECKING:
  from recommendation.wine_preferences import WinePreferences


DB_PATH = PROJECT_ROOT / "data" / "pairings.db"


@dataclass
class DiscoverWine:
  """Lightweight wine representation for Discover endpoints."""

  title: str
  price: Optional[float]
  thumb: Optional[str]
  sku: Optional[str]
  notes: str
  wine_type: Optional[str]
  reason: str


def _connect() -> sqlite3.Connection:
  con = sqlite3.connect(str(DB_PATH))
  con.row_factory = sqlite3.Row
  return con


def _parse_price(raw: Any) -> Optional[float]:
  """Best-effort numeric price parser from master_wines ec_final_price (stored as TEXT)."""
  if raw is None:
    return None
  if isinstance(raw, (int, float)):
    return float(raw)
  s = str(raw).strip()
  if not s:
    return None
  # Strip common currency formatting, keep leading numeric token.
  s = s.replace("$", "").split()[0]
  try:
    return float(s)
  except ValueError:
    return None


def _row_to_discover_wine(row: sqlite3.Row, reason: str) -> DiscoverWine:
  title = row["systitle"] or "Unknown Wine"
  notes = row["lcbo_tastingnotes"] or ""
  price = _parse_price(row["ec_final_price"])

  wine_type = normalize_wine_type(
    raw_style=row["style"],
    title=title,
    notes=notes,
  )

  return DiscoverWine(
    title=title,
    price=price,
    thumb=row["ec_thumbnails"],
    sku=row["sku"],
    notes=notes,
    wine_type=wine_type,
    reason=reason,
  )


def _fetch_random_master_wines(limit: int = 50) -> List[sqlite3.Row]:
  con = _connect()
  try:
    cur = con.cursor()
    cur.execute(
      """
      SELECT sku, systitle, ec_final_price, ec_thumbnails, lcbo_tastingnotes, style
      FROM master_wines
      WHERE ec_final_price IS NOT NULL
      ORDER BY RANDOM()
      LIMIT ?
      """,
      (limit,),
    )
    return cur.fetchall()
  finally:
    con.close()


def discover_daily(limit: int = 3) -> List[DiscoverWine]:
  rows = _fetch_random_master_wines(limit=80)
  results: List[DiscoverWine] = []
  seen_skus: set[str] = set()
  seen_titles: set[str] = set()

  for row in rows:
    sku = row["sku"]
    if not sku:
      continue
    sku_str = str(sku)
    if sku_str in seen_skus:
      continue

    title = (row["systitle"] or "").strip()
    if not title or title.lower() in seen_titles:
      continue

    notes = row["lcbo_tastingnotes"] or ""
    price = _parse_price(row["ec_final_price"]) or 0.0

    wt = normalize_wine_type(
      raw_style=row["style"],
      title=title,
      notes=notes,
    )

    # Simple reasoning based on type and price.
    reason = "Worth trying tonight"
    if wt == "White":
      reason = "Great everyday white"
    elif wt == "Red":
      reason = "Bold red for dinner"
    elif wt == "Rosé":
      reason = "Fresh rosé pick"
    elif wt == "Sparkling":
      reason = "Sparkling pick for celebrations"
    elif wt == "Dessert":
      reason = "Sweet finish for dessert"

    if price <= 20:
      reason = "Great value under $20"

    wine = _row_to_discover_wine(row, reason)
    results.append(wine)
    seen_skus.add(sku_str)
    seen_titles.add(title.lower())

    if len(results) >= limit:
      break

  return results


def discover_collections() -> List[Dict[str, str]]:
  return [
    {
      "slug": "steak-night-reds",
      "title": "Steak Night Reds",
      "subtitle": "Bold reds for rich dinners",
    },
    {
      "slug": "under-20",
      "title": "Best Under $20",
      "subtitle": "Good bottles that keep your budget happy",
    },
    {
      "slug": "crisp-whites",
      "title": "Crisp Whites",
      "subtitle": "Fresh, citrusy whites for salads & seafood",
    },
    {
      "slug": "pasta-pairings",
      "title": "Pasta Pairings",
      "subtitle": "Comforting reds and whites for pasta nights",
    },
    {
      "slug": "summer-rose",
      "title": "Summer Rosé",
      "subtitle": "Chilled rosé picks for sunny days",
    },
    {
      "slug": "sparkling-picks",
      "title": "Sparkling Picks",
      "subtitle": "Everyday bubbles and special bottles",
    },
  ]


def _collection_query(slug: str) -> Tuple[str, Tuple[Any, ...]]:
  base_sql = """
    SELECT sku, systitle, ec_final_price, ec_thumbnails, lcbo_tastingnotes, style
    FROM master_wines
    WHERE ec_final_price IS NOT NULL
  """
  params: Tuple[Any, ...] = ()

  # Keep SQL broad and do precise filtering in Python for robustness.
  sql = base_sql + " ORDER BY RANDOM() LIMIT 120"
  return sql, params


def discover_collection(slug: str, limit: int = 10) -> List[DiscoverWine]:
  sql, params = _collection_query(slug)
  con = _connect()
  try:
    cur = con.cursor()
    cur.execute(sql, params)
    rows = cur.fetchall()
  finally:
    con.close()

  raw_count = len(rows)

  results: List[DiscoverWine] = []
  seen_skus: set[str] = set()
  seen_titles: set[str] = set()

  slug_reason_map = {
    "steak-night-reds": "Great with grilled meats",
    "under-20": "Good value under \$20",
    "crisp-whites": "Fresh, citrusy white",
    "pasta-pairings": "Easy pairing for pasta",
    "summer-rose": "Chilled rosé for warm days",
    "sparkling-picks": "Bubbly pick for celebrations",
  }
  default_reason = "Thoughtful pick for this theme"

  for row in rows:
    sku = row["sku"]
    if not sku:
      continue
    sku_str = str(sku)
    if sku_str in seen_skus:
      continue

    title = (row["systitle"] or "").strip()
    if not title or title.lower() in seen_titles:
      continue

    notes = row["lcbo_tastingnotes"] or ""
    price = _parse_price(row["ec_final_price"])
    nt = normalize_wine_type(raw_style=row["style"], title=title, notes=notes)

    # Slug-specific Python filtering for robustness.
    if slug == "steak-night-reds":
      if nt != "Red":
        continue
      text = f"{title} {notes}".lower()
      if not any(k in text for k in ("grill", "steak", "roast", "tannin", "bold", "full-bodied")):
        # Allow generic reds but prefer food-friendly descriptors; no fallback to non-reds.
        pass
    elif slug == "under-20":
      if price is None or price > 20.0:
        continue
    elif slug == "crisp-whites":
      if nt != "White":
        continue
      text = notes.lower()
      if not any(k in text for k in ("crisp", "citrus", "zesty", "fresh", "mineral")):
        continue
    elif slug == "pasta-pairings":
      if nt not in ("Red", "White"):
        continue
      text = f"{title} {notes}".lower()
      # Prefer clear pasta-friendly language; if missing, still allow red/white but never other types.
      if not any(k in text for k in ("pasta", "tomato", "italian", "herb", "food-friendly", "versatile")):
        pass
    elif slug == "summer-rose":
      if nt != "Rosé":
        continue
      if price is not None and price > 25.0:
        continue
    elif slug == "sparkling-picks":
      if nt != "Sparkling":
        continue

    reason = slug_reason_map.get(slug, default_reason)
    wine = _row_to_discover_wine(row, reason)

    results.append(wine)
    seen_skus.add(sku_str)
    seen_titles.add(title.lower())

    if len(results) >= limit:
      break

  print(f"[discover] collection slug={slug} raw={raw_count} returned={len(results)}")
  return results


def discover_budget(max_price: float = 20.0, limit: int = 3) -> List[DiscoverWine]:
  con = _connect()
  try:
    cur = con.cursor()
    cur.execute(
      """
      SELECT sku, systitle, ec_final_price, ec_thumbnails, lcbo_tastingnotes, style
      FROM master_wines
      WHERE ec_final_price IS NOT NULL AND ec_final_price <= ?
      ORDER BY RANDOM()
      LIMIT 60
      """,
      (max_price,),
    )
    rows = cur.fetchall()
  finally:
    con.close()

  raw_count = len(rows)

  results: List[DiscoverWine] = []
  seen_skus: set[str] = set()
  seen_titles: set[str] = set()

  for row in rows:
    sku = row["sku"]
    if not sku:
      continue
    sku_str = str(sku)
    if sku_str in seen_skus:
      continue

    title = (row["systitle"] or "").strip()
    if not title or title.lower() in seen_titles:
      continue

    price = _parse_price(row["ec_final_price"])
    if price is None or price > max_price:
      continue

    wine = _row_to_discover_wine(row, "Great value under \$20")
    results.append(wine)
    seen_skus.add(sku_str)
    seen_titles.add(title.lower())

    if len(results) >= limit:
      break

  print(f"[discover] budget max_price={max_price} raw={raw_count} returned={len(results)}")
  return results


def discover_for_you(
  db: Session,
  user_id: int,
  limit: int = 6,
  wine_preferences: Optional["WinePreferences"] = None,
) -> List[DiscoverWine]:
  """
  Personalized picks using taste profile and/or wine preferences.
  Preferences affect RANKING only; no wines are filtered/hidden.
  Returns empty list if no profile and no preferences.
  """
  from recommendation.user_profile import build_user_taste_profile
  from recommendation.scoring import compute_combined_preference_bonus
  from recommendation.wine_preferences import WinePreferences

  profile = build_user_taste_profile(db, user_id)
  prefs = wine_preferences

  # Need at least one source for personalization
  has_profile = profile is not None
  has_prefs = prefs is not None and not prefs.is_empty()
  if not has_profile and not has_prefs:
    print(f"[discover] for-you user_id={user_id} no profile or preferences, returning []")
    return []

  # Build price range from profile or preferences
  min_price, max_price = 5.0, 80.0
  if has_profile and profile.average_preferred_price and profile.average_preferred_price > 0:
    avg = profile.average_preferred_price
    min_price = max(5.0, avg * 0.7)
    max_price = max(min_price + 5, avg * 1.3)
  elif has_prefs and prefs.default_budget and prefs.default_budget > 0:
    b = prefs.default_budget
    min_price = max(5.0, b * 0.6)
    max_price = max(min_price + 5, b * 1.4)

  con = _connect()
  try:
    cur = con.cursor()
    cur.execute(
      """
      SELECT sku, systitle, ec_final_price, ec_thumbnails, lcbo_tastingnotes, style, body
      FROM master_wines
      WHERE ec_final_price IS NOT NULL
        AND ec_final_price BETWEEN ? AND ?
      ORDER BY RANDOM()
      LIMIT 150
      """,
      (min_price, max_price),
    )
    rows = cur.fetchall()
  except Exception:
    cur.execute(
      """
      SELECT sku, systitle, ec_final_price, ec_thumbnails, lcbo_tastingnotes, style
      FROM master_wines
      WHERE ec_final_price IS NOT NULL
        AND ec_final_price BETWEEN ? AND ?
      ORDER BY RANDOM()
      LIMIT 150
      """,
      (min_price, max_price),
    )
    rows = cur.fetchall()
  finally:
    con.close()

  # Minimal doc-like object for scoring
  class _Doc:
    def __init__(self, meta: Dict[str, Any]):
      self.metadata = meta

  scored: List[Tuple[float, sqlite3.Row]] = []
  seen_skus: set[str] = set()
  seen_titles: set[str] = set()

  for row in rows:
    sku = row["sku"]
    if not sku:
      continue
    sku_str = str(sku)
    if sku_str in seen_skus:
      continue

    title = (row["systitle"] or "").strip()
    if not title or title.lower() in seen_titles:
      continue

    notes = row["lcbo_tastingnotes"] or ""
    price_val = _parse_price(row["ec_final_price"]) or 0.0
    style_val = row["style"] if "style" in row.keys() else None
    thumb_val = row["ec_thumbnails"] if "ec_thumbnails" in row.keys() else None
    body_val = row["body"] if "body" in row.keys() else None
    meta = {
      "systitle": title,
      "ec_final_price": price_val,
      "lcbo_tastingnotes": notes,
      "style": style_val,
      "ec_thumbnails": thumb_val,
      "body": body_val,
      "permanentid": sku_str,
    }
    doc = _Doc(meta)
    # Preferences affect ranking only; NO filtering by wine type
    bonus = compute_combined_preference_bonus(profile, prefs, doc, price_val)
    scored.append((bonus, row))
    seen_skus.add(sku_str)
    seen_titles.add(title.lower())

  # Sort by bonus descending, take top limit
  scored.sort(key=lambda x: x[0], reverse=True)
  results: List[DiscoverWine] = []
  for _, row in scored[:limit]:
    wine = _row_to_discover_wine(row, reason="")
    results.append(wine)

  print(f"[discover] for-you user_id={user_id} returned={len(results)}")
  return results


def discover_recommended(db: Session, user_id: int, limit: int = 3) -> List[DiscoverWine]:
  """Very lightweight personalized picks based on Tried history."""
  tried = (
    db.query(WineEntry)
    .filter(WineEntry.user_id == user_id, WineEntry.is_tried == True, WineEntry.rating != None)  # noqa: E712
    .order_by(WineEntry.added_at.desc())
    .limit(50)
    .all()
  )
  if len(tried) < 3:
    return []

  # Most common type
  type_counts: Dict[str, int] = {}
  prices: List[float] = []
  for t in tried:
    ttype = (t.wine_type or "Other").strip()
    type_counts[ttype] = type_counts.get(ttype, 0) + 1
    if t.price is not None:
      prices.append(float(t.price))

  if not prices:
    return []

  preferred_type = max(type_counts.items(), key=lambda kv: kv[1])[0]
  avg_price = sum(prices) / len(prices)

  min_price = max(0.0, avg_price - 5)
  max_price = avg_price + 8

  con = _connect()
  try:
    cur = con.cursor()
    cur.execute(
      """
      SELECT sku, systitle, ec_final_price, ec_thumbnails, lcbo_tastingnotes, style
      FROM master_wines
      WHERE ec_final_price IS NOT NULL
        AND ec_final_price BETWEEN ? AND ?
      ORDER BY RANDOM()
      LIMIT 80
      """,
      (min_price, max_price),
    )
    rows = cur.fetchall()
  finally:
    con.close()

  results: List[DiscoverWine] = []
  seen_skus: set[str] = set()
  seen_titles: set[str] = set()

  for row in rows:
    sku = row["sku"]
    if not sku:
      continue
    sku_str = str(sku)
    if sku_str in seen_skus:
      continue

    title = (row["systitle"] or "").strip()
    if not title or title.lower() in seen_titles:
      continue

    notes = row["lcbo_tastingnotes"] or ""
    nt = normalize_wine_type(
      raw_style=row["style"],
      title=title,
      notes=notes,
    )
    if nt != preferred_type:
      continue

    reason = f"Because you like {preferred_type.lower()} in this price range"
    wine = _row_to_discover_wine(row, reason)
    results.append(wine)
    seen_skus.add(sku_str)
    seen_titles.add(title.lower())

    if len(results) >= limit:
      break

  return results

