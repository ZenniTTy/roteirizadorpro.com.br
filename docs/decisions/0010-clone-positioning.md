# ADR-0010: Functional Fork Positioning (No Visual Asset Copy of Circuit)

- **Status:** Accepted
- **Date:** 2026-05-05
- **Deciders:** Eduardo, client

## Context

The accepted Workana proposal asks for an app that "clones the fluidity and UX of Circuit Route Planner." During scoping, the client said he wants the app to be "practically 100% identical, with different visual identity, copying 100% of the front." This phrasing has two valid interpretations — a functional one that is legally fine, and a literal one that would expose both Eduardo and the client to copyright and trade dress claims.

Circuit (https://getcircuit.com) is a UK/US company actively maintaining and marketing its product. Its visual assets, microcopy, illustrations, and marketing materials are protected by copyright. Trade dress doctrine (US) and combined visual identity (BR Lei 9.279/96) protect the *combined look-and-feel* of a product when it serves as a brand identifier.

Workana's terms of service prohibit deliverables that infringe third-party IP. A complaint could result in account termination for both contractor and client.

## Options Considered

### Option A — Visual identity copy ("100% identical")

- Pros: Maximum perceived similarity; minimum design work.
- Cons: Direct copyright violation of icons, illustrations, microcopy. Trade dress claim risk. Workana ToS violation. Client's marketing investment exposes them more (Facebook Ads make the clone discoverable to Circuit). High legal risk.

### Option B — Functional fork with original visual identity

- Pros: Replicates flows, behaviors, screen structure, interaction patterns — the things that make Circuit useful. Original colors, typography, icons, illustrations, microcopy. Legally defensible (functionality is not protected by copyright; trade dress requires distinctiveness AND consumer confusion, both of which are mitigated by clearly distinct visual identity). Industry-standard approach (Instagram→Snapchat, etc.). No Workana ToS issue.
- Cons: Requires actual design work (palette, typography, icon set) — not zero effort.

### Option C — White-label off-the-shelf route planner

- Pros: Lowest effort.
- Cons: Defeats the purpose of the contract; no differentiation.

### Option D — Purchase license / partner with Circuit

- Pros: Fully legal.
- Cons: Not realistic at our budget.

## Decision

**Functional fork with original visual identity.**

Replicate from Circuit:
- Screen structure (route list, optimize, navigate, settings).
- Navigation hierarchy.
- Interaction flows (drag-to-reorder, swipe-to-complete, bottom sheets, FAB).
- UX patterns (route timeline at top, inline ETAs).
- Behaviors (auto-save, undo, animation timing feel).

Do **not** replicate from Circuit:
- Icons, logos, mascots, illustrations.
- Color palette (neither exact nor near-exact combinations).
- Typography (font family choices).
- Microcopy (button labels, error messages, onboarding text).
- Marketing imagery (screenshots, photographs).
- Lottie animations or any vector art.
- App name (✅ already different — "Roteirizador Pro").

## Consequences

- Positive: Legally defensible; client's marketing can scale without IP risk; product is genuinely the client's own to commercialize, sell, or pitch to investors.
- Negative: Eduardo (or a designer) must produce an original visual identity — palette, typography, icon set, microcopy. Adds work.
- Neutral: Quality of UX clone is unaffected — the things users care about are functional.

## Implementation Notes

- Eduardo will produce wireframes from Circuit usage (low fidelity, structure only — no Circuit assets in the wireframes).
- A new visual identity will be defined: 2-3 palette directions, typography pair, icon set sourced from a permissive library (e.g., Lucide, Phosphor) or commissioned originals.
- All microcopy will be written from scratch in Brazilian Portuguese.
- No Circuit screenshots, PSDs, SVGs, or design files may enter the repository at any time.
- App icon will be a fresh design (logo work pending).

## References

- LGPD positioning (`docs/05-LGPD.md` — separate concern).
- Workana ToS: https://www.workana.com/legal/terms-of-service (clause prohibiting IP infringement).
- Trade dress (US): Two Pesos, Inc. v. Taco Cabana, Inc., 505 U.S. 763 (1992).
- BR: Lei 9.279/96 (Industrial Property Law).
