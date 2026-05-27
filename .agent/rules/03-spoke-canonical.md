---
trigger: glob
---

<!--
Activation: Glob (intended) — pattern: apps/mobile/lib/features/**/*.dart, docs/inventory/**, prototipo/**
Confirm in Antigravity UI: Customizations → Rules → this file → set "Glob" with the pattern above.
This rule encodes ADR-0035 + ADR-0036 + ADR-0037 source-of-truth hierarchy.
-->

# Spoke is Canonical for Behavior — Prototype is Canonical for Visual Identity Only

Roteirizador Pro is a **functional fork** of Spoke (ex-Circuit Route Planner). Two artifacts, each authoritative only on what it actually governs:

## 1. Spoke (`com.underwood.route_optimiser`) — behavior canonical

Which screens exist, how navigation flows, what settings are present, which gestures map to which actions, what features the app has. End-user is a delivery rider who already uses Spoke daily; functional parity is the contract per ADR-0010.

Inspection: runtime UX observation on Eduardo's licensed install (Samsung M54, `RQCW401G33T`). No decompilation, no asset extraction.

**Authoritative mapping per slice:** `docs/inventory/2026-05-26-spoke-vs-rotpro.md`.

## 2. `prototipo/` — visual identity canonical (visual only)

Color tokens (`prototipo/tokens.js`), spacing scale, radii, shadows, typography pairing, icon family (Lucide), animation patterns, decorative creativity. The prototype is a **creative reference, not a structural specification**.

When `docs/06-DESIGN-SYSTEM.md` references "the prototype", read it as "the visual identity source"; functional flows and screen presence trace back to Spoke.

## 3. Cliente Ueslei — tiebreaker

Final tiebreaker on any conflict between the two layers above. Seven locked directives in `docs/inventory/2026-05-26-spoke-vs-rotpro.md` §7.1 (e.g., no Apple/Facebook auth, no iOS).

## Decision flow

Before asking the user a UX/structure question for any slice-2 or slice-3 flow with a Spoke equivalent:

1. **Inspect Spoke first** (use the `spoke-inspect` skill in `.agent/skills/spoke-inspect/`).
2. Read the matching section of `docs/inventory/2026-05-26-spoke-vs-rotpro.md`.
3. Only THEN ask the user about:
   - (a) Decisions Spoke doesn't cover (data migration paths, original RotPro features, scope cuts per inventory §7).
   - (b) Directives that override Spoke (cliente preference per inventory §7.1).
   - (c) Visual identity choices (those come from `prototipo/`).

Out of scope for this rule: slices 4 (Stripe paywall), 5 (sentido casa), 6 (LGPD), 7 (admin panel) — those are original RotPro features with no Spoke equivalent.

**Never** file "deviation from prototype" ADRs for UX/structure questions. The prototype does not govern those.
