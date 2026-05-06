# 01 — Project

## What This Project Is

**Roteirizador Pro** is an Android-only route-planning application for Brazilian delivery riders (motoboys), distributed as APK directly from `roteirizadorpro.com.br`. The product is a **functional fork of Circuit Route Planner** with original visual identity, self-hosted infrastructure to minimize operational cost, and an automated 50/50 revenue split between two business partners via Pix.

## Why It Exists

Independent Brazilian delivery riders need a fast, reliable route planner that respects local realities (one-way streets, cul-de-sacs, urban geography of São Paulo and the Sudeste region) and lets them end the workday near home. Circuit solves this elegantly but is priced and engineered for international markets. Roteirizador Pro is engineered for the Brazilian market specifically: monthly subscription in BRL, payment via Pix (instant and ubiquitous in Brazil), self-hosted routing engine to avoid Google Maps API fees, and APK distribution to bypass Play Store friction.

## Who It Is For

- **End users:** Independent delivery riders (motoboys) operating in the Sudeste region of Brazil — primarily São Paulo, Rio de Janeiro, Minas Gerais, and Espírito Santo.
- **Business partners:** Two co-founders (the client and his partner) who share revenue 50/50.
- **Marketing channels (post-launch):** Facebook Ads and influencer marketing targeted at the rider community.

## Business Model

- Single subscription tier: **BRL 25.90 per month per user**.
- Payment exclusively via Pix (no credit card support in V1).
- Effective gateway fee: 1.19% + BRL 0.31 per transaction (Efí Bank pricing).
- Revenue is automatically split 50/50 between the two partners at the moment of payment, using Efí Bank's native Pix Split feature.
- Distribution: APK direct download from the project's domain. **No Google Play Store** in V1 (the client explicitly chose to bypass Play Store bureaucracy and distribute the APK directly).

## Positioning Statement

**Functional fork + original visual identity.**

Roteirizador Pro replicates Circuit's screen structure, navigation hierarchy, interaction flows (drag-to-reorder, swipe-to-complete), and UX patterns (bottom sheets, FAB, route timeline). It does **not** replicate Circuit's icons, logo, color palette, typography, illustrations, animations, microcopy, or marketing imagery. Visual identity is 100% original.

Legal rationale: functional behavior is not protected by copyright, but visual assets and trade dress are. The fork-with-original-identity approach is the standard pattern (and the only legally sound one) for replicating a successful product's UX without infringing its IP.

Full reasoning in `docs/decisions/0010-clone-positioning.md`.

## Milestones

| Milestone | Scope summary | Value | Duration |
|---|---|---|---|
| **M1** | Server (DigitalOcean), GraphHopper, landing page, backend auth API, repo handoff | BRL 2,000 | 14 days |
| **M2** | Android APK with all features (OCR, voice, "sentido casa" optimization, paywall, Pix Split, partner dashboard, share/QR) | BRL 2,000 | 14 days |

Detailed M1 plan: `docs/04-ROADMAP-M1.md`.
Detailed M2 plan: `docs/04-ROADMAP-M2.md`.

## Stakeholders

| Role | Name | Contact |
|---|---|---|
| Project owner / contracted developer | Eduardo Rodrigues | `eduardo@ianelli.tech` |
| Client (one of two business partners) | (client) | (via Workana) |
| Client's partner (the other 50% recipient) | (partner) | (via client) |
| Platform | Workana | escrow + arbitration |

## Constraints

- **Time:** 14 days per milestone.
- **Budget:** BRL 4,000 total (paid via Workana escrow, milestone-based).
- **Operational cost target:** Per-subscription routing cost must be effectively zero (hence GraphHopper self-hosted, not Google Maps API).
- **Distribution:** APK direct download. Play Store is out of scope.
- **Geography:** V1 covers Sudeste Brazil (São Paulo, Rio de Janeiro, Minas Gerais, Espírito Santo). Other regions added later by re-importing PBFs.
- **Legal:** Must comply with LGPD (Brazilian data protection law). Must not infringe Circuit's IP.

## Out of Scope (V1)

These are explicit non-goals for the BRL 4,000 contract:

- iOS app.
- Play Store publication.
- Multi-language support (PT-BR only).
- Multi-tier pricing (single tier only).
- Credit card payments (Pix only).
- Geographic coverage beyond Sudeste.
- Real-time GPS tracking / dispatch features.
- Multi-rider team management.

## Success Definition

The contract is successful when:

1. Both milestones are paid out by the client via Workana escrow.
2. The client and his partner are able to operate the system independently (server access, payment dashboard, GitHub repo) without ongoing Eduardo dependency.
3. The app is installable on Android phones via the APK link and the core flow (register → add stops → optimize → navigate via Waze/Google Maps) works end to end.
