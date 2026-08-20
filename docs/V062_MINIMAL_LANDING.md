# StockFlow v0.6.2 — Minimal landing rebuild

## Problem observed on-device
The v0.6.1 landing page looked busy because the same value proposition was repeated through multiple visual layers: an eyebrow pill, three trust pills, two CTAs, helper copy, a large buyer/seller explainer module and another row of proof cards. The duplicate top-right `Sign in` action also competed with the full-width sign-in button.

## v0.6.2 direction
The landing page is intentionally reduced to a single-screen hierarchy:
1. Brand mark and product name.
2. Small B2B context label.
3. Short hero statement.
4. One concise supporting sentence.
5. Two clear account actions: Create account and Sign in.
6. One quiet trust line.
7. A restrained product footer line.

Removed from landing:
- buyer/seller explainer cards
- repeated proof cards
- pill-heavy trust UI
- duplicate top-right sign-in action
- legal/helper paragraph under the CTAs

The detailed marketplace explanation remains available after entry into the app and the legal documents remain inside the authentication flow.

## CI hardening
The mobile workflow guard now checks the v0.6.2 landing phrase and artifact names instead of the v0.6.1 copy, so a legitimate copy/design change does not fail before Flutter analysis and tests run.
