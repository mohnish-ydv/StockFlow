# StockFlow v1.1.0 — Figma handoff

Final reference-inspired key-screen file:
https://www.figma.com/design/AUPjv6fCbjrOwkUhViuT8U

## Reference use
The client-provided Shoppe community file is used as a quality benchmark only. StockFlow does not copy its brand, copyrighted assets, exact layouts or fashion-store content. The redesign translates its disciplined whitespace, cobalt/white visual confidence, rounded neutral controls, dedicated OTP experience and product-first hierarchy into StockFlow's B2B marketplace.

## Key-screen board
The final Figma board contains client-review compositions for:
1. Welcome
2. Sign in
3. Create account
4. OTP verification
5. Home
6. Search results
7. Listing detail
8. Buying chat
9. Make offer
10. Sell — step 1
11. Sell — review
12. My Stock
13. Orders
14. Account

The connected Figma Starter seat reached its MCP call quota while the additional Product Direction and Design System pages were being written. The complete design tokens and decisions are therefore also documented in `V110_REFERENCE_QUALITY_REBUILD.md` and implemented directly in `lib/core/theme.dart` / `lib/widgets/sf_ui.dart`.

The Flutter source in this package is the executable source of truth for the complete buyer and seller journeys, including Cart, Checkout, order success, seller verification, multi-step listing creation, settings, legal and system states.
