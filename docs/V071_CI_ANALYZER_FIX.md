# StockFlow v0.7.1 — CI analyzer fix

The v0.7.0 marketplace journey rebuild reached Flutter static analysis successfully on both Android and iOS. The workflow then failed on three analyzer findings:

- `my_stock_screen.dart`: two `const ListView(...)` invocations called a non-const constructor. They now use non-const `ListView` with const children.
- `sell_screen.dart`: the `if (mounted)` image-picker state update is now enclosed in braces so `curly_braces_in_flow_control_structures` does not fail `flutter analyze --fatal-infos`.

No marketplace journey or UX behavior was reverted.
