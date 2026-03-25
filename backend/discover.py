from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING, Any, Dict, List, Optional, Tuple

from sqlalchemy import func
from sqlalchemy.orm import Session

from catalog_utils import master_wine_legacy_dict, parse_catalog_price
from models import MasterWine, WineEntry
from wine_type import normalize_wine_type

if TYPE_CHECKING:
  from recommendation.wine_preferences import WinePreferences


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


def _row_to_discover_wine(mw: MasterWine, reason: str) -> DiscoverWine:
  legacy = master_wine_legacy_dict(mw)
  title = (mw.systitle or legacy.get("systitle") or "Unknown Wine") or "Unknown Wine"
  notes = str(mw.lcbo_tastingnotes or legacy.get("lcbo_tastingnotes") or "")
  price = parse_catalog_price(mw.ec_final_price or legacy.get("ec_final_price"))
  thumb = mw.ec_thumbnails or legacy.get("ec_thumbnails")
  style = mw.style or legacy.get("style")

  wine_type = normalize_wine_type(
      raw_style=style,
      title=str(title),
      notes=notes,
  )

  return DiscoverWine(
      title=str(title),
      price=price,
      thumb=str(thumb) if thumb is not None else None,
      sku=mw.sku,
      notes=notes,
      wine_type=wine_type,
      reason=reason,
  )


def _fetch_random_master_wines(db: Session, limit: int = 50) -> List[MasterWine]:
  q = (
      db.query(MasterWine)
      .filter(MasterWine.price_numeric.isnot(None))
      .order_by(func.random())
      .limit(limit)
  )
  return q.all()


def discover_daily(db: Session, limit: int = 3) -> List[DiscoverWine]:
  rows = _fetch_random_master_wines(db, limit=80)
  results: List[DiscoverWine] = []
  seen_skus: set[str] = set()
  seen_titles: set[str] = set()

  for mw in rows:
    sku_str = (mw.sku or "").strip()
    if not sku_str:
      continue
    if sku_str in seen_skus:
      continue

    legacy = master_wine_legacy_dict(mw)
    title = (mw.systitle or legacy.get("systitle") or "").strip()
    if not title or title.lower() in seen_titles:
      continue

    notes = str(mw.lcbo_tastingnotes or legacy.get("lcbo_tastingnotes") or "")
    price = parse_catalog_price(mw.ec_final_price or legacy.get("ec_final_price")) or 0.0
    style = mw.style or legacy.get("style")

    wt = normalize_wine_type(
        raw_style=style,
        title=title,
        notes=notes,
    )

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

    wine = _row_to_discover_wine(mw, reason)
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


def discover_collection(db: Session, slug: str, limit: int = 10) -> List[DiscoverWine]:
  q = (
      db.query(MasterWine)
      .filter(MasterWine.price_numeric.isnot(None))
      .order_by(func.random())
      .limit(120)
  )
  rows = q.all()

  raw_count = len(rows)

  results: List[DiscoverWine] = []
  seen_skus: set[str] = set()
  seen_titles: set[str] = set()

  slug_reason_map = {
      "steak-night-reds": "Great with grilled meats",
      "under-20": "Good value under $20",
      "crisp-whites": "Fresh, citrusy white",
      "pasta-pairings": "Easy pairing for pasta",
      "summer-rose": "Chilled rosé for warm days",
      "sparkling-picks": "Bubbly pick for celebrations",
  }
  default_reason = "Thoughtful pick for this theme"

  for mw in rows:
    sku_str = (mw.sku or "").strip()
    if not sku_str or sku_str in seen_skus:
      continue

    legacy = master_wine_legacy_dict(mw)
    title = (mw.systitle or legacy.get("systitle") or "").strip()
    if not title or title.lower() in seen_titles:
      continue

    notes = str(mw.lcbo_tastingnotes or legacy.get("lcbo_tastingnotes") or "")
    price = parse_catalog_price(mw.ec_final_price or legacy.get("ec_final_price"))
    style = mw.style or legacy.get("style")
    nt = normalize_wine_type(raw_style=style, title=title, notes=notes)

    if slug == "steak-night-reds":
      if nt != "Red":
        continue
      text = f"{title} {notes}".lower()
      if not any(k in text for k in ("grill", "steak", "roast", "tannin", "bold", "full-bodied")):
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
    wine = _row_to_discover_wine(mw, reason)

    results.append(wine)
    seen_skus.add(sku_str)
    seen_titles.add(title.lower())

    if len(results) >= limit:
      break

  print(f"[discover] collection slug={slug} raw={raw_count} returned={len(results)}")
  return results


def discover_budget(db: Session, max_price: float = 20.0, limit: int = 3) -> List[DiscoverWine]:
  q = (
      db.query(MasterWine)
      .filter(
          MasterWine.price_numeric.isnot(None),
          MasterWine.price_numeric <= max_price,
      )
      .order_by(func.random())
      .limit(60)
  )
  rows = q.all()

  raw_count = len(rows)

  results: List[DiscoverWine] = []
  seen_skus: set[str] = set()
  seen_titles: set[str] = set()

  for mw in rows:
    sku_str = (mw.sku or "").strip()
    if not sku_str or sku_str in seen_skus:
      continue

    legacy = master_wine_legacy_dict(mw)
    title = (mw.systitle or legacy.get("systitle") or "").strip()
    if not title or title.lower() in seen_titles:
      continue

    price = parse_catalog_price(mw.ec_final_price or legacy.get("ec_final_price"))
    if price is None or price > max_price:
      continue

    wine = _row_to_discover_wine(mw, "Great value under $20")
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

  has_profile = profile is not None
  has_prefs = prefs is not None and not prefs.is_empty()
  if not has_profile and not has_prefs:
    print(f"[discover] for-you user_id={user_id} no profile or preferences, returning []")
    return []

  min_price, max_price = 5.0, 80.0
  if has_profile and profile.average_preferred_price and profile.average_preferred_price > 0:
    avg = profile.average_preferred_price
    min_price = max(5.0, avg * 0.7)
    max_price = max(min_price + 5, avg * 1.3)
  elif has_prefs and prefs.default_budget and prefs.default_budget > 0:
    b = prefs.default_budget
    min_price = max(5.0, b * 0.6)
    max_price = max(min_price + 5, b * 1.4)

  q = (
      db.query(MasterWine)
      .filter(
          MasterWine.price_numeric.isnot(None),
          MasterWine.price_numeric.between(min_price, max_price),
      )
      .order_by(func.random())
      .limit(150)
  )
  rows = q.all()

  class _Doc:
    def __init__(self, meta: Dict[str, Any]):
      self.metadata = meta

  scored: List[Tuple[float, MasterWine]] = []
  seen_skus: set[str] = set()
  seen_titles: set[str] = set()

  for mw in rows:
    sku_str = (mw.sku or "").strip()
    if not sku_str or sku_str in seen_skus:
      continue

    legacy = master_wine_legacy_dict(mw)
    title = (mw.systitle or legacy.get("systitle") or "").strip()
    if not title or title.lower() in seen_titles:
      continue

    notes = str(mw.lcbo_tastingnotes or legacy.get("lcbo_tastingnotes") or "")
    price_val = parse_catalog_price(mw.ec_final_price or legacy.get("ec_final_price")) or 0.0
    style_val = mw.style or legacy.get("style")
    thumb_val = mw.ec_thumbnails or legacy.get("ec_thumbnails")
    body_val = mw.body or legacy.get("body")
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
    bonus = compute_combined_preference_bonus(profile, prefs, doc, price_val)
    scored.append((bonus, mw))
    seen_skus.add(sku_str)
    seen_titles.add(title.lower())

  scored.sort(key=lambda x: x[0], reverse=True)
  results: List[DiscoverWine] = []
  for _, mw in scored[:limit]:
    wine = _row_to_discover_wine(mw, reason="")
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

  q = (
      db.query(MasterWine)
      .filter(
          MasterWine.price_numeric.isnot(None),
          MasterWine.price_numeric.between(min_price, max_price),
      )
      .order_by(func.random())
      .limit(80)
  )
  rows = q.all()

  results: List[DiscoverWine] = []
  seen_skus: set[str] = set()
  seen_titles: set[str] = set()

  for mw in rows:
    sku_str = (mw.sku or "").strip()
    if not sku_str or sku_str in seen_skus:
      continue

    legacy = master_wine_legacy_dict(mw)
    title = (mw.systitle or legacy.get("systitle") or "").strip()
    if not title or title.lower() in seen_titles:
      continue

    notes = str(mw.lcbo_tastingnotes or legacy.get("lcbo_tastingnotes") or "")
    style = mw.style or legacy.get("style")
    nt = normalize_wine_type(
        raw_style=style,
        title=title,
        notes=notes,
    )
    if nt != preferred_type:
      continue

    reason = f"Because you like {preferred_type.lower()} in this price range"
    wine = _row_to_discover_wine(mw, reason)
    results.append(wine)
    seen_skus.add(sku_str)
    seen_titles.add(title.lower())

    if len(results) >= limit:
      break

  return results
