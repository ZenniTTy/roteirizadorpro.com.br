# 10 — Changelog (Documentation)

Tracks structural and scope changes to the documentation itself. Code changes go into git history; this file is for documentation reorganization milestones.

## 2026-05-24 — Pix gateway migration: Efí Bank → Stripe + 30-day access pass model (ADR-0030)

Client decision late on 2026-05-24, after slice-2 fidelity work resumed: migrate the slice-4 Pix gateway from **Efí Bank** to **Stripe** and revert the brief 2026-05-10 "pay-per-route" model to a **30-day access pass** charged manually (R$ 25,90 grants 30 days; no Stripe Subscriptions, no automatic renewal — Pix Automático is invite-only in BR).

- **Filed [ADR-0030](decisions/0030-stripe-pix-30-day-access-pass.md)** — supersedes [ADR-0007](decisions/0007-efi-bank-payment.md). 4-row options table, decision in 1 sentence, consequences in 3 bullets, rollback, sandbox verification checklist.
- **ADR-0007 marked Superseded** with a header banner pointing at ADR-0030; body preserved as historical context.
- **`docs/BUSINESS-RULES.md`** got `Status: Accepted` + ADR cross-ref + clarification that "R$ 25,90 por mês" is **not** recurring billing; it's R$ 25,90 to start a fresh 30-day pass that the user actively renews via a new Pix payment.
- **Six canonical docs reconciled in this same PR** (CLAUDE.md, 01-PROJECT, 02-ARCHITECTURE Flow 3 + payment subsystem + DB schema, 04-FEATURES F09/F10, 08-ROADMAP §"Slice 4" + KPIs + cost line, M2-COST-MODEL fees + unit economics).
- **Hot-path docs swept** (README.md, PROJECT-CONTEXT.md, AGENTS.md, TODO.md slice-4 entry, SECURITY.md, Blueprint.md, 03-CONVENTIONS.md env-var example, 07-INFRA.md secrets inventory, 09-DISASTER-RECOVERY.md Scenario 6 outage + Scenario 7 secret-rotation, INSTALL.md `certs/` note). All references to Efí/mTLS/`.p12`/HMAC removed from active surface area; only intentional "ADR-0007 (Efí Bank) superseded by ADR-0030" cross-refs remain.
- **Untouched by design (historical immutability):** session logs (sessions 01–22f), `docs/briefing/original-briefing.md`, `docs/superpowers/specs/` and `plans/` older than this entry, ADR-0003 (its Efí mention was true at decision time — 2026-05-05), ADR-0007 body. ADR-0015's `Related ADRs` line got a `superseded by ADR-0030` annotation but body is untouched.
- **adr-guardian sweep:** GREEN, zero BLOCKING — no `pubspec.yaml` / `package.json` / `infra/` / `prisma/` touched (slice 4 will introduce Stripe deps + schema migration when it starts).

## 2026-05-24 — M2-AI harness sprint (sessions 19–22f)

Seven-phase sprint on `feat/m2-ai-harness` (orthogonal to slice 2) that adopts the official Flutter team's AI tooling onto the existing harness without disturbing product code. PR #8 against `feat/m2-slice-2-telas-core`.

- **ADR-0023** — official Dart & Flutter MCP server adopted via `.mcp.json` + `enabledMcpjsonServers` allowlist (Phase 1).
- **ADR-0024** — PostToolUse hook auto-regenerates Riverpod `.g.dart` after `@riverpod` edits, with 90 s lock-file debounce; sits next to `format-dart.sh` (Phase 2).
- **ADR-0025** — `flutter-test-author` subagent enforces test-first TDD for `apps/mobile/lib/`; refuses to write production code itself. `mocktail ^1.0.5` added as dev_dep, manual fakes remain the default (Phase 3).
- **ADR-0026** — `GH_DATA_DIR` env override in `infra/graphhopper/extract-sp.sh` (housekeeping; closed an `adr-guardian` BLOCKING finding from commit `bff1b6c` filed in another session).
- **ADR-0027** — `flutter-perf-auditor` read-only subagent, 9-item canonical perf checklist; Edit/Write/MultiEdit excluded from the allowlist so the read-only contract is mechanical, not just prompt-enforced. Wired into `M2-SLICE-CHECKLIST.md` §Verification (Phase 4).
- **ADR-0028** — `mcp_flutter` (Arenukvern) **rejected** for M2 with a documented re-evaluation trigger (iterations > 7/screen OR 2 consecutive device-E2E gates with > 2 Criticals each cleared by the static checker). Plugin is healthy (v3.0.7, debug-only) but the gap it would close is already covered by ADR-0021's device-E2E gate + ADR-0022's integration_test gate (Phase 5).
- **ADR-0029** — `alchemist ^0.14.0` (Betterment + VGV) adopted for golden tests after WebFetch confirmed `golden_toolkit` is discontinued by eBay. One canary baseline (`HomeEmptyPage`, 400×930 PNG) in CI mode. NOT a hook (Phase 6).
- **Docs updated:** `CLAUDE.md` ("Last updated" + 2 new Executable Commands rows + §"Context7 Mandatory" 3-tier precedence + §"In-Loop Auto-Validation" 4-hook split + §"Verify Your Work" 2 new bullets), `docs/03-CONVENTIONS.md` §Testing (2 bullets on TDD subagent + goldens), `docs/M2-SLICE-CHECKLIST.md` §Verification (perf-auditor + goldens bullets). `docs/02-ARCHITECTURE.md` unchanged — product topology unaffected by harness tooling.
- **Deferred to next session:** functional smoke dispatches of `flutter-test-author` and `flutter-perf-auditor` — Claude Code's agent registry only loads at session boot. Exact dispatch prompts captured in ADR-0025 §Verification and ADR-0027 §Verification.
- **In-loop validation:** every phase ran the in-loop hooks (`analyze-changed-dart.sh`, `check-dto-mirror.sh`, `warn-adr-drift.sh`) at turn end; `adr-guardian` dispatched at each phase boundary (caught and closed the ADR-0026 gap from commit `bff1b6c`); lefthook + commitlint passed on every commit without `--no-verify`.

## 2026-05-19 — slice 2 sub-2a remainder + sub-2b + sub-2c (session 13)

- **Sub 2a (Foundation) closed**: `StopsController` Riverpod 3 codegen with the 7 mutations the slice consumes (`add`, `remove`, `updateStop`, `reorder`, `applyOptimizedOrder`, `clear`, `build`-hydrate). `StopListItem` shared widget, `ScreenHomeEmpty`, `ScreenHomeList` with `HomeListPageOrEmpty` dispatcher + GoRouter wiring, `ScreenAddStop` with shared `StopForm` (address-only per prototype; Nominatim arrives in slice 3).
- **Sub 2b (Captura) closed**: `AndroidManifest.xml` declares `ACCESS_FINE_LOCATION` + `RECORD_AUDIO` + `CAMERA` in `src/main/` + `<queries>` block for Android 11+ package visibility (`com.google.android.apps.maps`, `com.waze`, https VIEW). `core/services/permissions.dart` `AppPermissions` wrapper with `@riverpod` codegen provider. `ScreenVoice` (`speech_to_text` pt-BR), `ScreenOCR` (`image_picker` → `google_mlkit_text_recognition`), `ScreenAddStopsMap` (`flutter_map` tap-to-add with real lat/lng).
- **Sub 2c (Manipulação) closed**: `ScreenStopDetail` (introduced `Stop.isGeocoded` getter), `ScreenEditStop` (reuses `StopForm`; reconciled the Riverpod 3 `update→updateStop` drift), `ScreenReorder` (`ReorderableListView.builder` + `ReorderableDragStartListener` + `StopListItem` reuse), `ScreenMapStops` (`flutter_map` + OSM tiles per ADR-0016, `Stop.isGeocoded` filter consumes the Null Island contract).
- **Cross-cutting DRY refactors**: shared `FakeStopsRepository` (eliminates 6-copy fake proliferation, net −106 LOC), shared `stopsAsyncView` for loading + error boilerplate across 5 screens (net −21 LOC + standardized error copy), pre-emptive `FakeAppPermissions` extraction before sub-2b screens spawned the 3rd / 4th copies.
- **Dead code purge**: removed M1's `apps/mobile/lib/features/home/presentation/home_placeholder_page.dart` (unreachable since Task 14 rebound `/home` to `HomeListPageOrEmpty`).
- **`Stop` domain extension**: added `bool get isGeocoded => lat != 0 || lng != 0;` to close the Null Island contract between `ScreenAddStop` / `ScreenVoice` / `ScreenOCR` (which mint stops with `lat=0, lng=0` until slice 3 geocodes) and `ScreenMapStops` / `external_nav` (must filter ungeocoded stops to avoid pinning markers / routing the rider to the Atlantic).
- **ADR-0015 amended** in session 12 to record the resolved pubspec.yaml caret-semver pins; `adr-guardian` confirmed no stack drift in the slice diff.
- **Prototype fidelity audit landed** (`prototype-fidelity-checker` subagent): 3 Critical + 4 Important divergences cataloged in `TODO.md` as slice-2-PR blockers (HomeEmpty FAB + "Como funciona?" pill, BottomNav across home family, StopListItem subtitle semantics, AddStop bottom-sheet presentation, Voice mic button visual, OCR dark viewfinder, StopDetail "Parada N de M" title).
- **Test suite grew from 26 to 53 tests**, full `flutter analyze` 0 issues, `bun run typecheck` clean. 22 commits on `feat/m2-slice-2-telas-core` pushed to origin between `e18f257` and the session-end audit-closure pack.

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
