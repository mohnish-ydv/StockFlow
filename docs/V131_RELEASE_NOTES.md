# StockFlow v1.3.1 release notes

Build: `1.3.1+23`

## CI reliability patch

The v1.3.0 mobile source reached the client/design regression guards on both Android and iOS, but those jobs still asserted an obsolete exact sentence (`Exact coordinates are private`). The shipped UI copy had already been improved to `Exact coordinates stay private ...`, so the workflow produced a false failure before static analysis.

This patch keeps the v1.3.0 mediated-deal, AI, location, security, shared-database and admin functionality unchanged while replacing the brittle wording assertion with a semantic regex (`Exact coordinates.*private`). Runtime location permission guards (`requestPermission`, `openLocationSettings`) remain mandatory.
