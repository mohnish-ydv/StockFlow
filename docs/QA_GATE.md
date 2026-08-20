# StockFlow release QA gate

A client build must not be labelled final unless all applicable gates are green.

## Automated mobile gates
- [ ] `flutter analyze --fatal-infos` passes.
- [ ] Unit and widget tests pass.
- [ ] Design regression guard finds none of the retired prototype strings/tokens.
- [ ] No privileged Supabase key is present in Flutter client source.
- [ ] Live staging API health check passes.
- [ ] Android release APK builds and is non-empty.
- [ ] APK is a valid ZIP and larger than the minimum sanity threshold.
- [ ] Built APK contains `android.permission.INTERNET`.
- [ ] iOS unsigned release compile succeeds.
- [ ] iOS `.app` output exists.

## Functional regression
- [ ] Login/session restore/logout.
- [ ] Home feed and categories.
- [ ] Search query, location, condition, price and fulfilment filters.
- [ ] Search sorting.
- [ ] Listing detail, save/recent.
- [ ] Seller application → admin approval → seller access.
- [ ] Create single and bulk listing with image upload.
- [ ] Chat and private contact model.
- [ ] Offer → counter → accept/reject.
- [ ] Cart + direct checkout.
- [ ] Accepted-offer checkout preserves price/quantity.
- [ ] Buyer cannot buy own listing.
- [ ] MOQ, stock, shipping and COD are server validated.
- [ ] Seller orders, AWB and tracking progression.

## Real-device visual smoke
Check at minimum:
- [ ] Android Home: no dark/neon prototype styling.
- [ ] Android Search/filter sheet.
- [ ] Android Listing detail + sticky action bar.
- [ ] Android Sell/create listing.
- [ ] Android Chat/composer.
- [ ] Android Checkout.
- [ ] iOS compile uses platform-specific route/glass layer code.
- [ ] No unrelated `picsum` image is displayed as a real product.
- [ ] Small screen: no overflow with keyboard open.
- [ ] Long titles/prices remain readable.
- [ ] Loading/error/empty states are usable.

## Admin browser UI
Tracked separately from the mobile redesign. Supabase Edge Function default-domain HTML is not a valid rendered-hosting target; static hosting must be verified independently before client handoff.
