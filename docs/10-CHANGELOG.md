# 10 — Changelog (Documentation)

Tracks structural and scope changes to the documentation itself. Code changes go into git history; this file is for documentation reorganization milestones.

## 2026-05-13 — M2 roadmap made canonical (session 11)

- **`docs/08-ROADMAP.md` rewritten** as the single source of truth for M2: 7 locked slices (APK ✅, Telas Core, VRP, Pix, sentido casa, LGPD, admin), per-slice scope and acceptance criteria, library choices validated via Context7, read-first map for future agents.
- **New: `docs/M2-SLICE-CHECKLIST.md`** — the rigid execution checklist used by every slice from slice 2 onward. Captures the verification steps (`aapt2 dump permissions`, `apksigner verify`, etc.) we lost time on during slice 1.
- **New: `docs/M2-COST-MODEL.md`** — the single source of truth for monthly infrastructure cost (target: ≤ BRL 200/month while in beta), per-transaction unit economics, and the explicit list of services we said no to and why.
- **New ADR-0015** — M2 plan and library choices: locks slice order, codifies `08-ROADMAP.md` as the source of truth, pins the slice 2 libraries (`flutter_map` 8.x, `speech_to_text` 7.x, `google_mlkit_text_recognition` 0.x, `geolocator` 14.x, `share_plus` 11.x).
- **New ADR-0016** — Map library + tile policy: `flutter_map` with public OSM tiles, OSMF acceptable-use compliance, documented migration trigger to self-hosted tiles.
- **Pricing model update propagated**: M2 moved from monthly subscription (BRL 25.90/month, original brief) to **pay-per-route** (BRL 25.90 per "Iniciar navegação," confirmed with client 2026-05-10). Reflected in `01-PROJECT.md`, `02-ARCHITECTURE.md` Flow 3, `04-FEATURES.md` F09/F10, `08-ROADMAP.md`.
- **Status corrected**: M1 marked closed in `01-PROJECT.md` and `04-FEATURES.md` (delivered 2026-05-09); slice 1 of M2 marked shipped (released as `v1.0.0` on 2026-05-13).

## 2026-05-13 — slice 1 (APK distribution)

- **New ADR-0014** ([Android release signing](decisions/0014-android-release-signing.md)) — keystore custody, distribution channel via Vercel public dir, single universal APK, signing config in Gradle. Includes "Sharp edges learned during slice 1" subsection capturing the INTERNET-permission gotcha.

## 2026-05-08

- **Schema source of truth codified** ([ADR-0013](decisions/0013-api-contract-source-of-truth.md)): Prisma owns the DB, TypeBox owns the HTTP contract, Dart DTOs mirror TypeBox 1:1 via a `// Mirror of:` header. Rule added to `CLAUDE.md`, new "API Contracts & Type Safety" section in `02-ARCHITECTURE.md`, new §8 in `03-CONVENTIONS.md`. Reference template at `apps/mobile/lib/features/auth/data/dto/_template.dart`. OpenAPI export + codegen deferred to post-M1.

## 2026-05-07

- **Documentation reorganization:** removed redundant files (`agents.md`, `CODE_OF_CONDUCT.md`, `docs/DESIGN-PROMPT.md`), unified roadmap into a single M1-focused `docs/08-ROADMAP.md`, renumbered docs to contiguous 01–10.
- **Prototype as canonical UI source:** `prototipo/` (Claude Design output, client-approved) is now referenced from `docs/05-SCREENS.md` and `docs/06-DESIGN-SYSTEM.md`. Tokens (including `neon`) and 19-screen list synced.
- **Roadmap focused on M1 only.** M2 scope deferred until post-M1 client conversation.
- **Server titularity clarified:** DigitalOcean account is the client's. Eduardo has admin access.
- **1GB droplet workaround documented as the M1 reality.** 8GB resize + Sudeste reimport is post-M1 work.
