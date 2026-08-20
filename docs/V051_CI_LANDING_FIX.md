# StockFlow v0.5.1 — CI + landing viewport fix

## Failure reproduced from GitHub Actions logs

The v0.5.0 source passed dependency resolution, backend/data smoke checks, design guards and `flutter analyze --fatal-infos`. Both Android and iOS jobs failed at the same widget test: `signed-out landing gives the marketplace a deliberate first screen`.

The test runner uses an 800×600 viewport. The `Explore StockFlow` CTA was rendered below the initial viewport (center Y ≈ 809), so `tester.tap()` could not hit it and the callback assertion stayed false.

## Fix

- Moved the primary `Explore StockFlow` and returning-user sign-in actions above the marketplace preview card.
- This is also a real UX improvement for short/landscape phones: the user sees the purpose + immediate action before supporting detail.
- Retained scrolling, preview content, entrance motion and reduced-motion behavior.
- Strengthened the smoke test to assert the CTA center is inside the initial 600px test viewport before tapping it.
- Bumped package version to `0.5.1+6`.
- Updated Android artifact naming to v0.5.1.

No backend contract, auth credentials, admin-panel logic, order flow, listing parser or API fields were changed.
