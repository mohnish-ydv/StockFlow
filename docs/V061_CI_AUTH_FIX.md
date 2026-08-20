# StockFlow v0.6.1 — CI guard + auth compile hardening

## Failure found in GitHub Actions
The v0.6.0 redesign never reached Flutter static analysis or widget tests. Both Android and iOS jobs stopped in the design regression guard because the workflow still required the old v0.5 landing headline `Good stock shouldn’t`, while v0.6 intentionally changed that copy to `Move surplus stock without the waste.`

## Fixes
- Replaced the stale v0.5 headline assertion with v0.6 landing/auth/legal contract checks.
- Added `auth_screen.dart` and `legal_screens.dart` to package preflight.
- Updated CI user-agent and Android/iOS artifact names to v0.6.1.
- Fixed `AuthMode` initialization: it now reads `widget.initialMode` inside `initState`, after the State widget is attached.
- Made the legal consent callback nullable so the checkbox can be safely disabled while the auth flow is busy.
- Reworked the auth top bar into a mobile-safe stacked layout so Back + logo + Register/Sign-in controls do not crowd a ~360dp phone width.
- Bumped package version to `0.6.1+8`.

## Local validation available in this environment
- mobile.yml + admin-pages.yml YAML parse: PASS
- JSON parse: PASS
- package/branding/design/auth/legal guards: PASS
- relative Dart imports: PASS
- 26 Dart files delimiter/static-structure scan: PASS
- ZIP integrity: PASS

The local sandbox does not include Flutter/Dart SDK, so GitHub Actions remains the authoritative analyzer/test/build gate.
