# Bottom Navigation Restructure — Implementation Summary

## Files Changed

| File | Change |
|------|--------|
| `lib/app/app_router.dart` | Reordered branches; replaced bottom bar with BottomAppBar + center FAB; added Profile branch; removed top-level /profile route |
| `lib/features/wine_recommendation/presentation/screens/search_screen.dart` | Removed profile icon from AppBar actions; removed unused auth imports |
| `lib/features/auth/presentation/screens/profile_tab_wrapper.dart` | **NEW** — Shows MyProfileScreen when authenticated, LoginScreen when not |

---

## Code Summary

### New Bottom Nav Structure

**Order (left to right):** Home | Discover | **Scan (FAB)** | My Cellar | My Page

**Branch indices:**
- 0: Home (`/home`)
- 1: Discover (`/discover`)
- 2: Scan (`/scan`) — center FAB
- 3: My Cellar (`/cellar`)
- 4: My Page (`/profile`)

### Scan Button Design

- **FloatingActionButton** with `FloatingActionButtonLocation.centerDocked`
- **BottomAppBar** with `CircularNotchedRectangle` for FAB notch
- Primary color: `#5C4A3F`
- White camera icon (`Icons.camera_alt_rounded`), size 28
- Elevation: 6, highlightElevation: 8
- Slightly elevated above the bar via the notch

### Profile Tab

- **ProfileTabWrapper** — Shows `MyProfileScreen` when authenticated, `LoginScreen` when not
- Profile icon: `Icons.person_outline_rounded`
- Label: "My Page"
- Removed top-right profile icon from Home/Pairings (SearchScreen)

### Layout

```
┌─────────────────────────────────────────────────┐
│                    App content                   │
└─────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────┐
│  Home  │ Discover │  (  )  │ My Cellar │ My Page│
│   🏠   │    ✨    │  📷   │    🍷    │   👤   │
└─────────────────────────────────────────────────┘
                    ↑
              Center FAB (Scan)
```

---

## Manual Test Steps

### A. Navigation Order
- [ ] Bottom nav shows: Home | Discover | Scan (center) | My Cellar | My Page
- [ ] Tapping each tab switches to the correct screen

### B. Scan FAB
- [ ] Scan is a circular button in the center
- [ ] Tap opens Scan screen
- [ ] Button uses primary color and white camera icon
- [ ] Button appears elevated above the bar

### C. Profile Tab
- [ ] Tapping My Page shows Profile when logged in
- [ ] Tapping My Page shows Login when not logged in
- [ ] After login from Profile tab, user can access profile

### D. Home Screen
- [ ] No profile icon in top-right of Pairings screen
- [ ] Home recommendations and search still work

### E. Existing Flows
- [ ] Discover, Cellar, Scan, recommendation flow unchanged
- [ ] No compile/runtime errors
