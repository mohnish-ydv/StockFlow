# v0.4 CI image-smoke fix

The first v0.4 Android CI run stopped before static analysis because a seeded preview
image used an external `unsplash.com/photos/.../download` endpoint that returned HTTP
401 to the GitHub Actions runner.

Backend preview data was corrected to remove all remaining legacy download endpoints.

The CI smoke check is now more useful:
- requires at least 12 preview listings,
- requires at least four sellers,
- rejects Picsum placeholders,
- rejects legacy Unsplash `/photos/.../download` URLs,
- validates the top 12 product image URLs,
- retries transient network failures twice,
- prints the exact failing URL before stopping the build.

This changes QA diagnostics only; no commerce or authentication logic is weakened.
