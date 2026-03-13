# Discover UX Completion — Implementation Summary

## Files Changed

| File | Change |
|------|--------|
| `lib/ui/pages/discover_page.dart` | Use `context.push` (GoRouter) instead of `Navigator.pushNamed`; add Learn Wine tap → article detail; fix RefreshIndicator to invalidate `discoverForYouProvider` |
| `lib/features/discover/presentation/screens/discover_collection_screen.dart` | Use `context.push` instead of `Navigator.pushNamed` for wine detail |
| `lib/features/discover/domain/models/learn_wine_article.dart` | **NEW** — Static article data (tannin, pairing basics, choose bottle) |
| `lib/features/discover/presentation/screens/learn_wine_detail_screen.dart` | **NEW** — Article detail screen |
| `lib/app/app_router.dart` | Add `/discover/learn` route |

---

## Code Summary

### Part 1 — Wine Cards Open Detail

**Root cause**: Discover used `Navigator.of(context).pushNamed('/home/results/detail', arguments: wine)`, but the app uses **GoRouter**, which expects `context.push(path, extra: data)`.

**Fix**: Replaced all `Navigator.pushNamed` with `context.push('/home/results/detail', extra: wine)` and added `import 'package:go_router/go_router.dart'`.

**Where applied**:
- Discover page: For You section (WineCard `onTap`)
- Discover page: Budget Picks section (WineCard `onTap`)
- Discover page: RefreshIndicator now invalidates `discoverForYouProvider` (was `discoverRecommendedProvider`)
- DiscoverCollectionScreen: WineCard `onTap` in Explore Styles result list

### Part 2 — Explore Styles Result Screen

**Status**: Already had `onTap` with `Navigator.pushNamed`. Updated to `context.push` for correct navigation.

### Part 3 — Learn Wine Detail

**Implementation**:
- **LearnWineArticle** — Model with `id`, `title`, `subtitle`, `sections` (list of paragraphs). Static data for 3 articles: tannin, pairing basics, choose bottle.
- **LearnWineDetailScreen** — Simple scrollable screen with title, subtitle, and section paragraphs. Uses app styling.
- **Route** — `/discover/learn` with `extra: LearnWineArticle`.
- **_LearnCard** — Wrapped in `InkWell` with `onTap` that pushes `/discover/learn` with the article.

### Part 4 — UX Consistency

- Back navigation uses `AppBar` default back button.
- Discover stays under its shell branch; `/discover/learn` is a child route.
- Wine detail uses the same `/home/results/detail` route as Home and Scan.
- No duplicate detail screens.

---

## Discover Wine Cards/Lists That Now Open Detail

| Section | Widget | Navigation Target |
|---------|--------|--------------------|
| For You | WineCard | `/home/results/detail` (WineDetailScreen) |
| Budget Picks | WineCard | `/home/results/detail` (WineDetailScreen) |
| Explore Styles → result list | WineCard | `/home/results/detail` (WineDetailScreen) |

---

## Learn Wine Detail Implementation

- **Data**: `LearnWineArticle.all` — 3 static articles in `learn_wine_article.dart`.
- **Screen**: `LearnWineDetailScreen` — title, subtitle, 2–4 paragraph sections.
- **Navigation**: Tap card → `context.push('/discover/learn', extra: article)`.
- **Content**: Local static content (no CMS, no backend).

---

## Manual Test Checklist

### A. For You
- [ ] Tap a wine → opens wine detail page
- [ ] Detail shows full wine info
- [ ] Can save to Wants from detail

### B. Budget Picks
- [ ] Tap a wine → opens wine detail page
- [ ] Detail shows full wine info

### C. Explore Styles
- [ ] Select a style → opens wine list
- [ ] Tap a wine from that list → opens wine detail page

### D. Wine Detail Integration
- [ ] From Discover-opened detail, can save to Wants
- [ ] Detail content renders correctly

### E. Learn Wine
- [ ] Tap "What is tannin?" → opens article detail
- [ ] Tap "Red vs white pairing basics" → opens article detail
- [ ] Tap "How to choose a bottle" → opens article detail
- [ ] Back returns to Discover

### F. Stability
- [ ] No compile/runtime errors
- [ ] Bottom nav and other flows unchanged
