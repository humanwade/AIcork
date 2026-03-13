# Discover "For You" — Taste Profile Integration

## Summary

The Discover "For You" section now uses the same `build_user_taste_profile` logic as:
- `/recommend` personalization
- My Cellar Insights

All three features share one profile source.

---

## Files Changed

### Backend

| File | Change |
|------|--------|
| `backend/discover.py` | Added `discover_for_you(db, user_id, limit=6)` using `build_user_taste_profile` and `compute_user_preference_bonus` |
| `backend/api.py` | Added `GET /discover/for-you`, imports `discover_for_you` |

### Frontend

| File | Change |
|------|--------|
| `lib/features/discover/data/datasources/discover_api_service.dart` | Added `fetchForYouRecommendations()` |
| `lib/features/discover/presentation/providers/discover_providers.dart` | Added `discoverForYouProvider` |
| `lib/ui/pages/discover_page.dart` | Switched For You section from `discoverRecommendedProvider` to `discoverForYouProvider` |

---

## Code Summary

### Backend: `discover_for_you(db, user_id, limit=6)`

1. Calls `build_user_taste_profile(db, user_id)` — returns `None` if &lt;3 rated Tried wines.
2. Builds price range from `average_preferred_price` (e.g. ±30%).
3. Queries `master_wines` for candidates in that price range.
4. Filters by `preferred_wine_types` (normalized).
5. Scores each candidate with `compute_user_preference_bonus(profile, doc, price)`.
6. Sorts by bonus descending, returns top 6.
7. Returns `DiscoverWine` with `reason=""` (no AI-style text).

### Backend: `GET /discover/for-you`

- Uses `get_optional_current_user` (no 401 when unauthenticated).
- If not authenticated → `[]`.
- If profile is `None` → `[]`.
- Response: `List[WineResult]` with `similarity_reason=None`.

### Frontend

- `fetchForYouRecommendations()` → `GET /discover/for-you`.
- `discoverForYouProvider` → `AsyncValue<List<WineRecommendationModel>>`.
- Discover page For You section uses `discoverForYouProvider`.
- Empty list → section hidden (same as before).

---

## Manual Test Steps

### A. Unauthenticated

1. Sign out.
2. Open Discover.
3. **Expected**: For You section hidden (empty list).

### B. Authenticated, insufficient Tried history

1. Sign in with account that has &lt;3 rated Tried wines.
2. Open Discover.
3. **Expected**: For You section hidden.

### C. Authenticated, sufficient Tried history

1. Sign in with account that has ≥3 Tried wines rated ≥4.
2. Open Discover.
3. **Expected**: For You section visible with horizontal WineCards (max 4).
4. Cards show: image, name, type + price, optional tasting note. No long AI explanations.

### D. Consistency

1. Add Tried wines with ratings.
2. Check My Cellar Insights — profile summary appears.
3. Check Discover For You — matching wines appear.
4. Use Home recommendations — personalization applied.
5. **Expected**: Same profile drives all three.

---

## Example API Response: `GET /discover/for-you`

**Request** (with `Authorization: Bearer <token>`):

```
GET /discover/for-you
```

**Response** (200 OK):

```json
[
  {
    "systitle": "Kim Crawford Sauvignon Blanc",
    "ec_final_price": 18.95,
    "lcbo_tastingnotes": "Crisp citrus and tropical fruit...",
    "ec_thumbnails": "https://...",
    "sku": "12345",
    "inventory_url": "https://www.lcbo.com/en/storeinventory?sku=12345",
    "sommelier_note": "",
    "similarity_reason": null,
    "wine_type": "White"
  },
  {
    "systitle": "Oyster Bay Sauvignon Blanc",
    "ec_final_price": 16.95,
    "lcbo_tastingnotes": "Fresh, zesty...",
    "ec_thumbnails": "https://...",
    "sku": "67890",
    "inventory_url": "https://www.lcbo.com/en/storeinventory?sku=67890",
    "sommelier_note": "",
    "similarity_reason": null,
    "wine_type": "White"
  }
]
```

**Response when not authenticated or insufficient data** (200 OK):

```json
[]
```
