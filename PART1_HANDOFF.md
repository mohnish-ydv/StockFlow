# StockFlow — Part 1 Handoff

## Scope completed
- M0 foundation and premium Material 3 design system
- M1 staging phone/OTP identity flow and mandatory account session
- M2 marketplace home, categories, search, functional filters, listing details, saved and recently viewed
- M3 seller application, admin approval state, seller dashboard, single/bulk listing creation, image upload, MOQ, pickup/shipping/COD toggles
- M4 admin APIs and moderation controls; browser frontend hosting is tracked separately from the mobile build

## Live backend
Supabase project ref: `zuzihcjpjwhrlfeushwd`
Region: `ap-northeast-1`

Deployed Edge Functions:
- `stockflow-staging-api`
- `stockflow-staging-upload`
- `stockflow-admin`

Admin URL:
`https://zuzihcjpjwhrlfeushwd.supabase.co/functions/v1/stockflow-admin`

## Build pipeline
`.github/workflows/mobile.yml` compiles/tests Android on Ubuntu and performs an unsigned iOS release compile on macOS. Android APK is uploaded as the `StockFlow-Part1-Android` artifact.

## Security
- Flutter contains the Supabase project URL and publishable key only.
- No secret/service-role credential is committed.
- Staging identity/session tables are server-only.
- Production-facing public tables use RLS.
- Supabase security and performance advisors were reviewed and hardened.

## Staging vs production
Part 1 intentionally uses a zero-cost staging OTP/session layer. Production SMS OTP will replace this adapter after the client chooses/owns an SMS provider; marketplace screens and seller workflows do not need to be rewritten.
