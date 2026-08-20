# StockFlow v1.0.2 — Widget Test Reliability Fix

The v1.0.1 GitHub Actions run passed source preflight, backend smoke, live preview smoke, and `flutter analyze --fatal-infos` on both Android and iOS jobs. The only failure was a widget test that attempted to tap the registration screen’s bottom “Already have an account? Sign in” link while it was below the default 800×600 test viewport.

The production UI is intentionally scrollable. v1.0.2 updates the test to scroll the target into view with `tester.ensureVisible(...)` before tapping it, matching real user behavior without changing the approved auth UX.

Version: 1.0.2+14.
