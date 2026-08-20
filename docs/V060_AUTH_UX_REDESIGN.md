# StockFlow v0.6.0 — Landing + Auth Redesign Notes

## Why the previous version felt weak
- Landing and auth were visually disconnected.
- CTA labels were generic and did not expose distinct register vs sign-in paths.
- Registration and sign-in were merged into one thin flow, which felt unfinished.
- Legal trust signals were missing: no proper Terms & Conditions, Privacy Policy or explicit consent checkbox.
- The auth form asked for city/state immediately with little context, making the page feel procedural instead of product-quality.
- The layout looked like a prototype form rather than a polished marketplace entry funnel.

## Research direction used
The redesign was inspired by current mobile-first account patterns instead of copied from any single app:
- Apple HIG account guidance: explain benefits, avoid unnecessary friction, and make sign-in actions obvious and trustworthy.
- Apple HIG Sign in with Apple guidance: primary sign-in actions should be visible without scrolling.
- USWDS authentication page guidance: reduce distractions, provide context, and make account creation/sign-in clearer.
- Material form guidance: use helper text, visible validation context and touch-friendly controls.

## UX decisions in v0.6.0
- Dedicated premium landing screen with stronger positioning and clearer product story.
- Two clear entry points: `Create account` and `Sign in`.
- Auth screen with explicit mode switcher instead of one ambiguous flow.
- Consent checkbox before continuing, plus in-app Terms & Conditions and Privacy Policy pages.
- Better microcopy explaining why the app needs the account and what the phone number is used for.
- OTP stage redesigned to feel intentional, with editable summary and trust messaging.
- Added trust footer blocks so the experience feels product-grade, not like a wireframe.
