# Fixed issues before StockFlow v0.3

## Android CI generated template test
Flutter platform-shell generation created `test/widget_test.dart` referencing the template `MyApp`. The workflow removes that generated test and runs StockFlow's own tests.

## Android release networking
The generated Android main manifest did not contain the INTERNET permission. The workflow now injects the permission after platform generation and inspects the final APK with `aapt dump permissions`; CI fails if the built APK does not contain it. Runtime socket/timeout errors are also converted to concise user-facing messages.

## Part 2 commerce hardening
- Missing foreign-key indexes were added during backend hardening.
- Checkout RPC is server-only.
- Seller cannot trigger buyer-only offer actions on their own listing.
- Conversation screens refresh full listing context.
- Accepted-offer checkout remains quantity/price specific.
- Inventory deduction is server controlled.

## Admin browser rendering — known hosting limitation
The previous attempt to serve the Admin UI directly from a hosted Supabase Edge Function displayed source text in mobile browsers. This is not treated as fixed in the mobile build. The admin frontend must be deployed to a standard static host (for example GitHub Pages) while continuing to call the server-side staging API.
