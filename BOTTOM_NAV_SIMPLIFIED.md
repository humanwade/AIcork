# Bottom Navigation — Simplified Design

## Files Changed

| File | Change |
|------|--------|
| `lib/app/app_router.dart` | Removed FAB and BottomAppBar; replaced with standard bar; added `_ScanNavItem` with rounded primary background |

---

## Code Summary

### Removed
- `FloatingActionButton`
- `FloatingActionButtonLocation.centerDocked`
- `BottomAppBar` with `CircularNotchedRectangle` notch
- Center placeholder `SizedBox(width: 56)`

### New Structure
- **Container** as bottom bar (same style as before: surface color, soft shadow)
- **5 nav items** in a Row: Home | Discover | Scan | My Cellar | My Page
- **Scan** uses `_ScanNavItem`: camera icon inside a rounded primary-colored container

### Scan Design
- Same icon size (26px) and label typography as other items
- Camera icon in `Container` with:
  - Background: primary color `#5C4A3F`
  - White icon
  - `BorderRadius.circular(13)`
  - Fixed size 38×26 to match other icon row height
- Same padding and spacing as other nav items

---

## Layout

```
┌─────────────────────────────────────────────────────────────┐
│  Home   │  Discover  │  [📷]   │  My Cellar  │  My Page    │
│   🏠    │     ✨     │ (Scan)  │     🍷     │     👤      │
└─────────────────────────────────────────────────────────────┘
```

Scan: camera icon in a small rounded primary-colored box; same baseline as other icons.

---

## Manual Test Steps

### A. Layout
- [ ] Bottom bar shows 5 items: Home, Discover, Scan, My Cellar, My Page
- [ ] No FAB; no notch; no overflow
- [ ] All items align on the same baseline

### B. Scan
- [ ] Scan has a rounded primary-colored background behind the camera icon
- [ ] White camera icon
- [ ] Tapping Scan opens Scan screen
- [ ] Same spacing and typography as other items

### C. Navigation
- [ ] Each tab switches to the correct screen
- [ ] Profile tab shows My Page (or Login when not authenticated)

### D. Home Screen
- [ ] No profile icon in top-right of Pairings screen
