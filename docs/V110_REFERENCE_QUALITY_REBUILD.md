# StockFlow v1.1.0 — Reference-inspired final rebuild

## Goal
Deliver the final pre-API UI/UX layer at consumer-commerce quality while preserving StockFlow's B2B surplus-stock marketplace model.

## Reference translation
The client-provided Shoppe mobile commerce file is a visual quality benchmark, not a source to copy. StockFlow translates its strongest qualities into a distinct B2B product: a white canvas, confident cobalt brand colour, soft abstract onboarding shapes, sparse copy, neutral rounded fields, image-first commerce, dedicated OTP verification, compact product grids, circular category discovery and a consistent bottom navigation.

No Shoppe logo, fashion-store copy, copyrighted imagery, exact screen composition or brand asset is included.

## High-frequency screen decisions
- Welcome: first-run only, one visual idea, one dominant action, low-emphasis auth choices.
- Authentication: phone first; OTP is a dedicated six-digit state; profile/legal consent appears only during registration.
- Home: location, search, categories, fresh stock and recently viewed content.
- Listing cards: image, price, title, MOQ/availability and location—no marketing copy.
- Listing details: image-led product view, commercial facts, fulfilment, seller context and sticky deal actions.
- Chat: listing context remains visible; structured offers live inside the conversation.
- Sell: seller gating and a five-step listing wizard instead of a dense single form.
- My Stock: operational inventory list rather than KPI dashboard cards.
- Cart/Checkout: product, quantity, address, payment, summary and one final action.
- Account: familiar grouped rows with minimal profile information.

## Visual system
- Primary: cobalt `#1769FF`
- Primary strong: `#0B56E8`
- Brand wash: `#EAF1FF`
- Field surface: `#F5F6F8`
- Ink: `#111318`
- Muted: `#7A818C`
- Line: `#ECEEF2`
- Success/danger stay semantic rather than decorative.

## Anti-slop constraints
- no decorative metrics or fake analytics
- no stacked generic cards as default page structure
- no random gradients/glassmorphism
- no repeated feature/trust copy
- no fake demo photography in the release feed
- no staging/preview OTP messaging in release UI
- no permanent authentication wall before marketplace value is visible
- no multiple competing CTAs with equal emphasis

## Production handoff
The backend contracts are preserved. Production OTP delivery, payment, logistics and final API wiring can replace staging services without another visual redesign.
