from __future__ import annotations

import random
import sqlite3
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

from sqlalchemy.orm import Session

from database import PROJECT_ROOT
from models import WineEntry
from wine_type import normalize_wine_type


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

