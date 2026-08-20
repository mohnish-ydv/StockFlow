# StockFlow Admin Access

The admin control centre is included at `docs/admin/index.html` and deploys through `.github/workflows/admin-pages.yml`.

## GitHub Pages setup

1. Open the StockFlow repository on GitHub.
2. Go to **Settings → Pages**.
3. Under **Build and deployment → Source**, select **GitHub Actions**.
4. Go to **Actions → StockFlow Admin Pages → Run workflow**, or push this full package to the default branch.
5. Open the deployment URL shown by the workflow. For the existing `mohnish-ydv/StockFlow` project, the normal project-site URL is `https://mohnish-ydv.github.io/StockFlow/`.

## Staging admin login

- Mobile: `9999999999`
- OTP: `246810`

Development/staging only. Replace the staging adapter with production authentication before public release.

## v1.3 admin capabilities

- Overview metrics for listings, deal requests, approved sellers, promise fees and orders: day / week / month / all time
- 14-day charts
- marketplace order value
- category distribution
- product performance: views, buyer-interest requests, protected chats, offers, carts, orders, conversion and revenue
- private GPS-backed listing map + area counts
- mediated Deals desk with buyer/seller operations context, promise-fee state and protected-chat entitlement state
- security-event telemetry and rate-limit/contact-circumvention visibility
- seller application review
- listing moderation
- order inspection
- AI request health
- diagnostics/error references for customer support

The static browser frontend contains only the Supabase publishable key. Admin authorization and privileged data access are checked server-side. Exact seller/listing coordinates are returned only by the backend admin-analytics action after an admin-role check.
