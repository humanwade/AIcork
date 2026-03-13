# User Taste Profile Personalization — Implementation Summary

## Files Changed

### Backend (Python)

| File | Change |
|------|--------|
| `backend/recommendation/user_profile.py` | **NEW** — Rule-based taste profile inference from Tried wines |
| `backend/auth.py` | Added `get_optional_current_user`, `oauth2_scheme_optional` |
| `backend/recommendation/scoring.py` | Added `compute_user_preference_bonus()` |
| `backend/recommendation/reranker.py` | Added optional `user_profile` param, applies bonus when present |
| `backend/recommendation/pipeline.py` | Added optional `db`, `user_id`; fetches profile, passes to reranker |
| `backend/api.py` | `/recommend` uses `get_optional_current_user`, passes `db`/`user_id`; added `GET /cellar/insights` |
| `backend/schemas.py` | Added `CellarInsightsOut` |

### Frontend (Flutter)

| File | Change |
|------|--------|
| `lib/features/cellar/data/datasources/cellar_api_service.dart` | Added `fetchInsights()`, `CellarInsights` model |
| `lib/features/cellar/domain/controllers/cellar_controller.dart` | Added `cellarInsightsProvider` |
| `lib/features/cellar/presentation/widgets/taste_profile_insights_card.dart` | **NEW** — Insights card widget |
| `lib/ui/pages/cellar_page.dart` | Insert Insights card above Wants/Tried tabs |

---

## Code Summary

### 1. User Taste Profile (`user_profile.py`)

- **`build_user_taste_profile(db, user_id) -> UserTasteProfile | None`**
- Requires ≥3 Tried entries with ratings
- Liked = rating ≥ 4.0
- Aggregates: wine_type, flavors, body_style, price from liked entries
- Optional avoid_traits from entries with rating < 3.0
- Summary text: e.g. "You tend to enjoy crisp whites and rosé wines. You often prefer medium-bodied under $25."

### 2. Optional Auth (`auth.py`)

- **`get_optional_current_user`** — Returns `User | None`
- Uses `OAuth2PasswordBearer(auto_error=False)` so missing/invalid token → `None`
- No 401 for anonymous requests

### 3. Personalization in Scoring (`scoring.py`, `reranker.py`)

- **`compute_user_preference_bonus(profile, doc, price) -> float`**
- Clamped to `[-0.10, +0.15]`
- Signals: wine_type match (+0.04), flavor overlap (+0.02), body/style (+0.03), price proximity (+0.01–0.03), avoid traits (−0.05)
- `rerank_candidates` adds bonus to `base_score` for sorting

### 4. API Endpoints

- **`POST /recommend`** — Optional `Authorization: Bearer`; when valid, personalization applied
- **`GET /cellar/insights`** — Auth required; returns `CellarInsightsOut` (summary, tags, enough_data)

### 5. My Cellar Insights Card

- Renders below header, above Wants/Tried tabs
- Only when `enough_data == true`
- Content: title "Your Taste Profile", summary line, 2–4 chips (wine types, flavors, body, price range)

---

## Manual Test Steps

### A. Recommendation fallback (unauthenticated)

1. Ensure no auth token (sign out or use incognito).
2. Call `POST /recommend` with `{"query": "red wine for steak", "max_budget": 50, "top_k": 3}`.
3. **Expected**: 200 OK, recommendations returned, no personalization errors.

### B. Personalized recommendation (authenticated + Tried history)

1. Sign in.
2. Add ≥3 Tried wines with ratings ≥4 (e.g. Rosé, Crisp Whites).
3. Call `POST /recommend` with same payload; include `Authorization: Bearer <token>`.
4. **Expected**: Backend logs show `recommend.user_profile_applied`, `rerank.user_preference_bonus`; ranking subtly adjusted.

### C. No-history case (authenticated, insufficient Tried)

1. Sign in with account that has <3 Tried or <3 rated.
2. Call `POST /recommend` with token.
3. **Expected**: 200 OK, normal recommendations; logs show `recommend.no_user_profile` or no profile.

### D. My Cellar Insights card

1. Sign in.
2. Add ≥3 Tried wines with ratings ≥4.
3. Open My Cellar.
4. **Expected**: "Your Taste Profile" card appears below header, above Wants/Tried tabs.
5. With <3 Tried or insufficient ratings: card hidden.

### E. Existing flows

- Mark as Tried — works
- Move to Wants — works
- Wants/Tried lists load
- No compile/runtime errors

---

## Example Score Breakdown (Before vs After Personalization)

**Before (no profile):**

```
base_score = 0.30·semantic + 0.20·food + 0.15·style + 0.15·flavor + 0.10·budget + 0.10·quality
final_score = base_score
```

**After (profile: prefers Rosé, crisp, $15–25):**

```
base_score = 0.30·semantic + 0.20·food + 0.15·style + 0.15·flavor + 0.10·budget + 0.10·quality
user_preference_bonus = clamp(
  wine_type_match(0.04) + flavor_overlap(0.02) + body_match(0.03) + price_proximity(0.01–0.03) - avoid_penalty(0.05),
  -0.10, 0.15
)
final_score = base_score + user_preference_bonus
```

Example: Candidate A (Rosé, crisp, $18) gets +0.10 bonus → moves up. Candidate B (bold red, $45) gets +0.00 → unchanged. Personalization is subtle; query intent remains primary.
