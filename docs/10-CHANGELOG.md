# 10 — Changelog (Documentation)

Tracks structural and scope changes to the documentation itself. Code changes go into git history; this file is for documentation reorganization milestones.

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
