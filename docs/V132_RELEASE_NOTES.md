# StockFlow v1.3.2 release notes

Build: `1.3.2+24`

## CI analyzer cleanup

The v1.3.1 release reached `flutter analyze --fatal-infos` on both Android and iOS. The analyzer reported exactly two source hygiene issues: a `Text` constructor in the protected-chat header could be `const`, and `listing_detail_screen.dart` still imported `platform_ui.dart` after the mediated-deal redesign stopped using it.

This patch fixes both findings without changing the v1.3 mediated-deal, promise-fee, location, AI, shared-database, admin, security, rate-limit, or contact-blocking behavior.

## CI expectations

The next GitHub Actions run should proceed past static analysis and reach the widget-test/build stages. Flutter/Dart are not installed in the packaging environment, so GitHub Actions remains the authoritative compile/test gate.
