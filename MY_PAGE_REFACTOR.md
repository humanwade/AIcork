# My Page Refactor — Implementation Summary

## Files Changed

| File | Change |
|------|--------|
| `lib/features/auth/presentation/screens/profile_screen.dart` | Refactored into profile hub: Profile card, Wine Stats, Preferences, Support, Account |
| `lib/features/auth/presentation/screens/edit_profile_screen.dart` | **NEW** — Edit profile form (first name, last name, email, phone) |
| `lib/features/scan/presentation/providers/scan_providers.dart` | **NEW** — `scannerApiProvider`, `scanHistoryCountProvider` |
| `lib/app/app_router.dart` | Added `/profile/edit` route |

---

## Code Summary

### 1. Profile Card
- Compact card at top with avatar placeholder, display name, subtitle ("Wine explorer")
- "Edit profile" text button
- Rounded card, soft shadow

### 2. Your Wine Stats
- Three stat tiles in a row:
  - **Tried wines** — from `cellarControllerProvider.valueOrNull?.tried.length`
  - **Saved wines** — from `cellarControllerProvider.valueOrNull?.wants.length`
  - **Scanned wines** — from `scanHistoryCountProvider` (fetches `/scan/history`, returns count)
- Uses real user data from existing providers

### 3. Preferences
- Section with row-style items
- "Wine preferences" (placeholder for now)

### 4. Support
- Help & Support, Send feedback, Privacy policy, Terms of service
- Tappable rows (placeholder handlers for now)

### 5. Account
- Edit profile, Change password, Log out
- Delete account in separate card (destructive styling)

### Edit Profile Screen
- Full form: first name, last name, email (read-only), phone
- Save updates via `authRepository.updateProfile`
- Pops back to My Page on success; parent reloads profile

---

## Your Wine Stats — Data Sources

| Stat | Source |
|------|--------|
| Tried wines | `cellarControllerProvider` → `state.tried.length` |
| Saved wines | `cellarControllerProvider` → `state.wants.length` |
| Scanned wines | `scanHistoryCountProvider` → `ScannerApiService.fetchScanHistory().length` |

All use real current user data. No hardcoded values.

---

## Manual Test Checklist

1. [ ] My Page opens without errors
2. [ ] Top shows profile card (name, subtitle, Edit profile)
3. [ ] "Your Wine Stats" shows Tried, Saved, Scanned counts
4. [ ] Counts match actual cellar and scan history
5. [ ] Preferences section renders
6. [ ] Support section renders
7. [ ] Edit profile opens form, save works, returns to My Page
8. [ ] Change password works
9. [ ] Log out works
10. [ ] Delete account works (confirm + password)
11. [ ] No compile/runtime errors
