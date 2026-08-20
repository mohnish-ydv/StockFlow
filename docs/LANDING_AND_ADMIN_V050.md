# StockFlow v0.5.0 — Landing + Admin Pages Repair

## Buyer-facing landing screen

- Added `lib/screens/landing_screen.dart` as the signed-out entry experience.
- Returning authenticated users still go directly to the marketplace.
- Signed-out users see a real marketplace value proposition before authentication instead of being dropped into a form.
- Added restrained first-frame entrance motion and reduced-motion support.
- Added clear Get Started / Sign In paths and an Auth → Landing back path.
- Logout returns to the landing experience.

## Admin control center

- Restored the missing admin static site into `docs/admin/`.
- Added a dedicated GitHub Pages deployment workflow.
- Redesigned the admin UI to match the light, human marketplace visual language instead of the former dark/neon prototype treatment.
- Kept privileged credentials out of the static frontend.
- Added `ADMIN_ACCESS.md` with the required one-time GitHub Pages setting and staging credentials.
