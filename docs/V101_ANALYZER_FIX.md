# StockFlow v1.0.1 analyzer repair

GitHub Actions for v1.0.0 reached `flutter analyze --fatal-infos` on both Android and iOS after source, design-system, backend, and preview smoke guards passed. Two info-level analyzer findings were promoted to build failures by `--fatal-infos`:

1. `auth_screen.dart`: OTP `InputDecoration` was const-eligible.
2. `listing_detail_screen.dart`: `_makeOffer()` used `context` after awaiting the auth gate without a mounted guard.

Repairs:
- made the OTP `InputDecoration` const;
- added `if (!mounted) return;` immediately after the async auth gate before opening the offer sheet;
- bumped package/artifact identity to v1.0.1+13.

No UX architecture or marketplace journey changes were made in this repair.
