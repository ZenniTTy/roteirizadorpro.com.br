# TODO

> **Owner:** Claude Code (read at session start, update at session end).
> **Scope:** M2 — slice-by-slice execution. M1 was delivered 2026-05-09.
> **M2 contract:** BRL 2,000. Sequence locked 2026-05-13: APK → Telas Core → VRP → Pix → Sentido casa → LGPD → Admin.
> **Source of truth:** `docs/08-ROADMAP.md`. This file tracks day-to-day progress; the roadmap defines scope.
> **Last updated:** 2026-05-19 (session 16 — harness Wave C landed; ADR-0020 amends ADR-0013 normalizing the `// Mirror of:` header grammar to ASCII `->` with single-DTO and multi-DTO productions; hook hardened to anchored regex; `/verify-slice` allowlist fixed. Harness modernization arc Waves A+B+C now complete).

## M2 — Slices

### ✅ Slice 1 — Android APK distribuível (shipped 2026-05-13 as `v1.0.0`)

Live at `https://roteirizadorpro.com.br/roteirizador-pro-v1.0.0.apk` (HTTP 200, 34.3 MB, `Content-Type: application/vnd.android.package-archive`, signed v2 + cert SHA-256 `D9:C9:61:D6:…:14:31`). Validated end-to-end on a Samsung Galaxy A06 against production API. ADR-0014 + session logs 09/10 + memory entry `flutter-android-release-internet-permission.md` capture the design, the diagnosis ladder, and the INTERNET-permission gotcha.

### 🟡 Slice 2 — Telas Core (IN PROGRESS — sub 2a Foundation 10/16 tasks done)

**Read first (resume order):** `docs/sessions/2026-05-18-12-m2-slice-2-tasks-1-10.md` → `docs/superpowers/specs/2026-05-13-m2-slice-2-telas-core-design.md` → `docs/superpowers/plans/2026-05-13-m2-slice-2-telas-core.md` (start at Task 11) → `docs/M2-SLICE-CHECKLIST.md` → `prototipo/screens-{a,b,d,e}.jsx`. The plan is the per-task source of truth from here on; the ROADMAP is still canonical for slice ordering and acceptance.

**Branch:** `feat/m2-slice-2-telas-core` — at `f0bb080` (post-session-14 will advance by one more session-end commit), 16+ commits ahead of `origin/develop`. 19/19 flutter tests passing, `flutter analyze` clean, `bun run typecheck` clean. Three of those commits are orthogonal harness work (Wave A); the slice-2 product surface is unchanged from session 13's tip `7437917`.

Pre-flight: ✅ done (session 12).

Brainstormed decisions (locked):
- ✅ Q1 Persistence: in-memory Riverpod + `SharedPreferencesAsync` for session restore (no backend routes table in slice 2).
- ✅ Q2 Default external nav: Google Maps default + toggle in Settings to Waze. ADR-0017 to file in sub 2d.
- ✅ Q3 Price: BRL 25.90/route locked through M2; revisit only via data-driven ADR after slice 7 surfaces 50-paying-user metrics.

Implementation tracker (sub-slice 2a, plan tasks 1-16):

- [x] **Task 1** — Add 11 pubspec deps (uuid, shared_preferences, url_launcher, permission_handler, geolocator, image_picker, speech_to_text, google_mlkit_text_recognition, flutter_map, latlong2, share_plus) + bump version to `1.1.0+2`. Commit `7181fb5`.
- [x] **Task 2** — Amend ADR-0015 table with resolved caret-semver pins. Commit `8074aef`.
- [x] **Task 3** — Enable `SystemUiMode.edgeToEdge` in `main.dart` (Android 15 opt-in). Commit `cf63313`.
- [x] **Task 4** — Add `android:enableOnBackInvokedCallback="true"` to `<application>` (Android 14 predictive back). Commit `9c3a025`.
- [x] **Task 5** — Evolve `OptimizeResponseSchema` to wire-final shape (`optimizedOrder, totalDistanceM, totalDurationS`); export `StopSchema` + `Stop` type; transient stub kept routes.ts typecheck green. Commit `c45f742`.
- [x] **Task 6** — Replace 501 placeholder with 200 mock returning input order via `stops.map((_, i) => i)`. Commit `7437c1a`. **Curl smoke (Step 6.4) DEFERRED** — needs Node 20 + Postgres up; captured before PR open (Task 39).
- [x] **Task 7** — `Stop` domain model with `@immutable`, copyWith, toJson/fromJson, value-equality. 5 TDD tests. Commit `1c3dfea`.
- [x] **Task 8** — `StopDto` mirror per ADR-0013 (`// Mirror of: apps/backend/src/routes/schemas.ts -> StopSchema`) + `Stop.toDto()` / `Stop.fromDto(...)` extension methods. 6 TDD tests. Commit `e9207db`.
- [x] **Task 9** — `StopsRepository` interface + `SharedPrefsStopsRepository` impl using `SharedPreferencesAsync` (NOT `getInstance()`), `_v: 1` envelope, corrupt-payload-returns-empty. Adds `shared_preferences_platform_interface: ^2.4.2` as dev-dep for `InMemorySharedPreferencesAsync` test substrate. 5 TDD tests. Commit `4889902`.
- [x] **Task 10** — `core/services/id.dart` uuid v4 wrapper. 2 TDD tests. Commit `c6d11f9`.
- [x] **Task 11** — `StopsController` (`@riverpod class StopsController extends _$StopsController`, codegen) with build/add/remove/updateStop/reorder/applyOptimizedOrder/clear methods. 7 TDD tests. Commits `826def0`. (Riverpod 3 reserves `update()` for atomic callback transitions; our mutation method renamed to `updateStop` to avoid the override clash — captured as memory `riverpod-3-asyncnotifier-update-reserved.md`.)
- [x] **Task 12** — Reusable `StopListItem` widget (shared by HomeList, Reorder, StopDetail). Commit `be88b30`. Dart 3 switch expression for `_sourceBadge`.
- [x] **Task 13** — `ScreenHomeEmpty` matching `prototipo/screens-a.jsx → ScreenHomeEmpty`. Commits `0b810b2` + refactor `46ac764` (`ConsumerWidget` → `StatelessWidget` since `ref` was never read). Used prototype strings `'Rota de hoje'` / `'Nenhuma entrega ainda'` over the plan's draft copy. `onAddPressed` callback injection for test friendliness.
- [x] **Task 14** — `ScreenHomeList` + GoRouter wiring (`/home`, `/stops/add`, `/stops/:id`). Commits `1ec55df` + a11y fix `bcd3728`. Dispatcher `HomeListPageOrEmpty` in own `home_page.dart`. Round FAB matching design-system spec (not the plan's `.extended`). Count chip with pluralized Semantics label. Placeholder `add_stop_page.dart` + `stop_detail_page.dart` to unblock GoRouter imports; replaced by Tasks 15 + 19.
- [x] **Task 15** — `ScreenAddStop` + shared `StopForm` widget. Commit `e08a84a` + a11y cleanup `b03a484`. **Address-only field** per prototype (no lat/lng inputs — Nominatim arrives in slice 3); stops minted with sentinel `lat: 0, lng: 0`. `onSaved` callback injection. `AutovalidateMode.onUserInteraction`.
- [x] **Task 16** — Sub 2a final verification + push. Suite green at 34/34 after sub 2a wrap.

Sub 2b foundation + Captura (plan tasks 17-18, 23-25):

- [x] **Task 17** — `AndroidManifest.xml` adds `ACCESS_FINE_LOCATION` / `RECORD_AUDIO` / `CAMERA` to `src/main/`; extends `<queries>` with `com.google.android.apps.maps`, `com.waze`, https VIEW intent. Commit `bd10c9a`.
- [x] **Task 18** — `core/services/permissions.dart` adds `AppPermissions` abstract + `@riverpod appPermissions(Ref)` codegen provider; `PermissionOutcome.{granted,denied,permanentlyDenied}`. 3 TDD tests. Commit `cf266ae`.
- [x] **Task 23** — `ScreenVoice` (`speech_to_text`) using `appPermissionsProvider.requestMicrophone()`. Transcript → Stop with `source: voice` + Null Island sentinel. **Extracted shared `FakeAppPermissions`** at `test/core/_helpers/`; migrated `permissions_test.dart` to use it. `onConfirmed` callback injection. Commit `dce83a2`.
- [x] **Task 24** — `ScreenOCR` (`image_picker` → `google_mlkit_text_recognition`) using `requestCamera()`. Extracted text → Stop with `source: ocr` + Null Island sentinel. `TextRecognizer.close()` in dispose. Commit `2221098`.
- [x] **Task 25** — `ScreenAddStopsMap` (`flutter_map` tap-to-add) — each tap mints a Stop with **real** lat/lng (natively geocoded, no sentinel). Undo + extended FAB confirm. `osmAttribution()` reuse. Commit `5c02ffb`. **Sub 2b complete.**

Sub 2c Manipulação (plan tasks 19-22):

- [x] **Task 19** — `ScreenStopDetail` replaces Task-14 placeholder. Adds `Stop.isGeocoded` getter closing the Null Island contract for Tasks 22 + 28. `onDeleted` / `onEditPressed` callback injections. 4 widget tests. Commit `373814a`.
- [x] **Task 20** — `ScreenEditStop` reuses `StopForm` pre-populated. Reconciled plan drift: `controller.update(stop)` → `.updateStop(stop)` (Riverpod 3 reserved); `StopFormData(lat,lng,label)` → `StopFormValue(label)` (address-only). `onSaved` callback. Commit `31eac55`.
- [x] **Task 21** — `ScreenReorder` (`ReorderableListView.builder`) reusing `StopListItem` in trailing-slot drag-handle pattern (no parallel `ListTile`). `buildDefaultDragHandles: false`. Commit `9e1253e`.
- [x] **Task 22** — `ScreenMapStops` with `flutter_map` + OSM tiles per ADR-0016. Applies `Stop.isGeocoded` filter (Null Island contract honored). Extracted `osmAttribution()` helper for tile-policy compliance. Commit `3d8e08d`. **Sub 2c complete.**

Refactors (cross-cutting DRY wins from the slice):

- [x] **`FakeStopsRepository`** — consolidated six private `_Repo` / `_FakeRepo` / `_EmptyRepo` fakes into one shared helper at `test/features/stops/_helpers/`. Net −106 LOC across 6 test files. Commit `2d628d9`.
- [x] **`stopsAsyncView`** — extracted the duplicated `async.when(loading, error, data)` boilerplate (100% identical across 5 screens) into a single shared helper at `presentation/shared/stops_async_view.dart`. Net −21 LOC; standardized error copy across all five. Commit `b691c90`.
- [x] **`FakeAppPermissions`** — pre-emptively extracted to `test/core/_helpers/` before Tasks 24 + 25 added 3rd / 4th copies. Migrated `permissions_test.dart` to use it. Shipped as part of commit `dce83a2`.

**Pre-slice cleanups:**
- [x] `apps/mobile/lib/features/home/presentation/home_placeholder_page.dart` deleted (was unreachable since Task 14). Empty parent dirs `features/home/presentation/` and `features/home/` also removed.

**Prototype fidelity findings (`prototype-fidelity-checker` subagent run 2026-05-19) — address before slice-2 PR opens (Task 39):**

Critical:
- [x] `HomeEmptyPage` — FAB + secondary `'Como funciona?'` pill added per `prototipo/screens-a.jsx:143–154`. Closed by `50ae78b`.
- [x] BottomNav bar — `HomeBottomNav` shared widget shipped, wired into `HomeEmptyPage` + `HomeListPage` per `prototipo/ui.jsx:186–211`. Settings placeholder route added so the `Configurações` tab has a target until Task 33. Closed by `bb71d16`.
- [x] `StopListItem` subtitle source-label removed per re-audit decision; complement + status badge data-model gap deferred to slice 3 with Nominatim. Closed by `9b81fc9`.

Important:
- [ ] `AddStopPage` full-page vs bottom-sheet presentation + 3 method-selector tabs (Keyboard / Voice / Camera) missing. Prototype: `prototipo/screens-a.jsx:279–364`. Either restructure to `showModalBottomSheet` or document as slice-3 deferral.
- [ ] `VoiceCapturePage` mic-button visual — prototype shows 100×100 gradient circle + 3 pulse rings (`prototipo/screens-a.jsx:373–386`); implementation uses `IconButton.filled`. Document in commit body or polish in a follow-up.
- [ ] `OcrCapturePage` — prototype is a full-screen dark camera viewfinder (`prototipo/screens-b.jsx:7–99`); implementation routes to OS camera via `image_picker`. To match would require swapping to `camera` package — scope decision.
- [x] `StopDetailPage` title — `'Parada N de M'` now computed via `asyncStops.maybeWhen` against `stopsControllerProvider`. Closed by `8a08386`.
- [ ] `OptimizeRoutePage` — neon `ROTA OTIMIZADA` badge from `prototipo/screens-e.jsx:221–231` (`RP.neon #C6FF3D` pill + pulsing dot overlaid on the map) absent. Implementation has a subtle metrics row under AppBar instead. Restore in slice 3 when route geometry is real.
- [ ] `OptimizeRoutePage` map pin shape — prototype `prototipo/screens-e.jsx:202–212` uses rounded-rect pin (`borderRadius: 5`, white fill, `RP.primary` border, `fontWeight: 700`); implementation uses `CircleAvatar` solid fill. Shape + typography divergent.
- [ ] `OptimizeRoutePage` start/end markers — prototype lines 186–199 show distinct origin dot + flag-icon end pin; implementation renders identical circle avatars for all stops including the first.
- [ ] `OptimizeRoutePage` stop list row — prototype lines 277–291 has two lines (label + subtitle address) + right-aligned ETA time string; implementation is single-line `ListTile.title`. Scaffold the ETA column when slice 3 brings GraphHopper leg durations.
- [ ] `OptimizeRoutePage` bottom sheet chrome — prototype line 241 has 40×4 drag-handle pill at top of sheet; implementation has a plain `Column` (no sheet). Address when re-skinning to `DraggableScrollableSheet`.
- [ ] `NavigatePage` Falhou button per stop — prototype `prototipo/screens-e.jsx:423-429` shows red `RP.errorBg / #B91C1C` "Falhou" alongside "Entregue" in the bottom stop card. Implementation ships a single checkbox per stop (success-only path). Add when slice 3 brings delivery-status tracking.
- [ ] `NavigatePage` stop metadata chips — prototype `prototipo/screens-e.jsx:414-421` shows `📦 Pequeno` and `🛍️ Sacola` chips per stop; `Stop` domain model has no `packageSize` / `bagType` fields yet. Data-model gap.
- [ ] `NavigatePage` AppBar vs full-screen — prototype `prototipo/screens-e.jsx:302` uses `<Phone hideNav>` (full-screen with no AppBar) plus a bottom black bar at line 442-464 (`12 min / 09:41 · 0,49 km`); implementation uses a standard `AppBar` because the turn-by-turn map mock requires Mapbox Nav SDK (ADR-0017 §6 deferral). Restore when in-app turn-by-turn is approved.
- [ ] `NavigatePage` button radius — prototype lines 426/433 use `borderRadius: 12` (`AppRadii.input`); implementation uses Material's default `FilledButton` pill (`AppRadii.btn`=24). Adjust when the Falhou/Entregue per-stop pair lands.
- [ ] `RouteCompletePage` savings banner absent — prototype `prototipo/screens-e.jsx:813-829` shows neon-light banner "Você economizou 1h 24min · 35 km 🎉". Requires unoptimized-baseline comparison from slice 3 VRP solver. **Must ship before M2 closes.**
- [ ] `RouteCompletePage` faded `BigMap` background — prototype lines 745-746. `BigMap` widget doesn't exist yet; add when `flutter_map` static decorative layer is integrated.
- [ ] `RouteCompletePage` microcopy — prototype line 833 says "Voltar para casa"; implementation uses "Nova rota". Prototype line 838 says "Compartilhar conquista →"; implementation uses "Compartilhar". Client sign-off before release.
- [ ] `HomeEmptyPage` `BottomNav` indicator pill geometry — Material 3 `NavigationBar` renders an oval-fit-to-icon indicator; prototype `prototipo/ui.jsx:193–196` specifies an explicit `64×32 borderRadius:16` pill. Re-audit Section C finding.
- [ ] `HomeBottomNav` border-top color — prototype `prototipo/ui.jsx:204` sets `borderTop: 1px solid RP.border` (`#E8E4F0`); Material 3 default may resolve differently. Re-audit Section C finding.
- [ ] `StopDetailPage` body fullness — prototype `prototipo/screens-b.jsx:162–210` has map placeholder + address card with DISTÂNCIA/TEMPO/CONTATO rows + Entregue/Falhou/Próxima action triplet + locked nav button + move-options list; implementation has only Excluir/Editar buttons. Pre-existing gap (not introduced by `8a08386`); restore in slice 3 polish pass.

Minor (post-merge polish):
- [ ] `stop_form.dart` input border radius — use `AppRadii.input` (12) instead of M3 default.
- [ ] `HomeEmptyPage` — replace `Icons.local_shipping_outlined` with the custom `EmptyIllustration` SVG (`prototipo/screens-a.jsx:112–130`).
- [ ] `HomeListPage` count chip — match the prototype's ghost-pill spec (`surface` + `border`, not M3 `Chip` defaults).
- [ ] `MapStopsPage` polish — floating header card, AO VIVO pill, teardrop markers (documented deferral in commit `3d8e08d`; slot here for tracking).
- [ ] `AddStopsMapPage` bottom-sheet address picker (deferred to slice 3 / Nominatim, commit `5c02ffb`).
- [ ] `StopListItem` address complement subtitle (data-model gap; introduce `Stop.complement` when prototype card semantics are fully restored).
- [ ] `OptimizeRoutePage` title — prototype `prototipo/screens-e.jsx:254` reads `"São Paulo · 27 paradas"` (city name prefix); implementation metrics row has no city label. Track for slice 3 when reverse geocode lands.
- [ ] `OptimizeRoutePage` sheet shadow — `prototipo/tokens.js:27` declares `sheetShadow: '0 -8px 32px rgba(108,63,197,0.16)'`; absent in current implementation (no sheet container). Restore alongside drag-handle when the sheet lands.
- [ ] `RouteCompletePage` confetti accents — prototype `prototipo/screens-e.jsx:749-763` shows 6 colored 8×14 rotated rectangles at fixed percentage positions (neon, primary, warning, success, accent, neonDark). Decorative only.
- [ ] `RouteCompletePage` neon ring around check circle — prototype lines 784-787, `2px solid neon` outset at `inset: -6 borderRadius: 42 opacity: 0.6`. Decorative.
- [ ] `SettingsPage` — wire "Indicar para um amigo" row that opens ScreenShare per `prototipo/screens-b.jsx:374`. Currently no entry point to /share exists from Settings. Address in Task 34 (ScreenShare) or as a follow-up commit.
- [ ] `SettingsPage` — "Conta" section currently shows only "Sair da conta"; prototype `prototipo/screens-b.jsx:367-370` has E-mail (display), Alterar senha, Minha assinatura. Add as disabled stubs once the post-M2 account flow lands.
- [ ] `SettingsPage` — section card visual: prototype `prototipo/screens-b.jsx:351` wraps each section in a white container with `border: 1px solid border` + `borderRadius: rCard (16)`. Implementation uses bare `ListTile` rows with `Divider` separators. Restore the card chrome.
- [ ] `SettingsPage` — row label drift: prototype `prototipo/screens-b.jsx:361` uses "App de GPS padrão" as the row label; implementation uses only the section header "Aplicativo de navegação" with no row label inside. Client sign-off on the copy choice.
- [ ] `ShareSheet` — WhatsApp branded card from `prototipo/screens-b.jsx:406-409` with pre-composed message. Android's native share sheet routes there generically, but without the pre-filled text.
- [ ] `ShareSheet` — "Copiar link de download" card from prototype lines 413-427 with `roteirizadorpro.com.br/download` copy + ephemeral "Copiado!" feedback pill (`RP.success` / `RP.successBg`).
- [ ] `ShareSheet` — QR Code card + expanded panel from prototype lines 431-447. Referral QR is post-M2 marketing.
- [ ] `ShareSheet` — referral subtitle "Passe o link para outro motoboy e ganhe um mês grátis quando ele assinar." (`prototipo/screens-b.jsx:401`). Currently absent.
- [ ] `ShareSheet` — `shareFn` typedef in `share_sheet.dart` uses positional `(text, {subject})` while `share_plus` 12.x canonical API is `SharePlus.instance.share(ShareParams)`. Production path wraps correctly; the typedef diverges only at the test injection boundary. Either align the typedef to take `ShareParams` directly or accept the wrapping shim. Code-correctness item only.

Sub 2d (Optimization + Nav, plan tasks 26-32) and Sub 2e (Periféricos, plan tasks 33-34): pending; details verbatim in the plan. Release tasks 35-41 follow.

ADRs to file during this slice:

- [ ] **ADR-0017** — external navigation hand-off (Google Maps default + Waze toggle, multi-stop semantics, fallback browser, `<queries>` rationale). Files in sub 2d Task 26.

Verification (per `docs/M2-SLICE-CHECKLIST.md`):

- [x] `flutter analyze` clean (continuous through tasks 1-10).
- [x] `flutter test` passes (19/19 as of Task 10).
- [x] `bun run typecheck` clean in `apps/backend/`.
- [ ] **Curl smoke** for `POST /routes/optimize` — three captures (200 / 401 / 400) before opening the slice-2 PR.
- [ ] `aapt2 dump permissions <new APK>` lists `INTERNET`, `ACCESS_FINE_LOCATION`, `RECORD_AUDIO`, `CAMERA` (release task 36).
- [ ] `apksigner verify` confirms cert SHA-256 matches keystore.
- [ ] Real-device E2E on Galaxy A06 (release task 37): 14-step golden path with screenshots per screen.
- [ ] Run `prototype-fidelity-checker` subagent against every shipped screen vs `prototipo/`.
- [ ] Run `adr-guardian` subagent against the slice 2 diff (ADR-0017 present, ADR-0015 amended).

Post-merge:

- [x] `pubspec.yaml` already at `1.1.0+2`. Rebuild + publish APK at `apps/landing/public/roteirizador-pro-v1.1.0.apk` (release task 38).
- [ ] Refactor four CTAs in `apps/landing/src/app/page.tsx` to read from a single `APK_LATEST_VERSION` constant in `apps/landing/src/lib/apk-version.ts` (release task 38).
- [ ] PR `feat/m2-slice-2-telas-core` → `develop` with full test plan + smoke captures + screenshots (release task 39).
- [ ] Promotion PR `develop` → `main`. Tag `v1.1.0` after merge (release task 40).
- [ ] `curl -sI https://roteirizadorpro.com.br/roteirizador-pro-v1.1.0.apk` returns 200 (release task 40).
- [ ] Session log + index update + TODO + CHANGELOG + ROADMAP slice-2 ✅ flip — single commit via `/session-end` (release task 41).

**Tech debt captured this slice (resurfaces in later slices, NOT in slice 2 scope):**

- `Stop.copyWith` cannot set `label` to null (current `??` semantics treat null as "use current"). Decide between sentinel pattern, `clearLabel()` method, or empty-string-as-null at controller layer when Task 22 (ScreenEditStop) lands.
- `SharedPrefsStopsRepository.load()` silently swallows corrupt-payload exceptions. Instrument with a non-fatal breadcrumb once Sentry/Crashlytics is approved post-M2 (per `M2-COST-MODEL.md` rejecting paid observability for M2 beta).
- Backend has no test framework today (`apps/backend/package.json` has only `tsx`/`typescript`/`prisma`). Slice 2 uses curl smoke in the PR body; revisit installing `bun test` (zero-install) or `vitest` post-slice-3 when the real solver makes formal tests high-leverage.
- Commitlint subject-case rule rejects camelCase identifiers (e.g. `StopDto`, `OptimizeResponseSchema`, `SharedPreferencesAsync`). Pattern: lowercase those tokens in the subject line; body keeps canonical case. Captured as a feedback memory entry.

### ⏳ Slice 3 — VRP real (after slice 2)

Replaces the `POST /routes/optimize` mock with a real solver. Approach in `docs/08-ROADMAP.md` slice 3 section: distance matrix from individual GraphHopper route calls (n² parallel) + nearest-neighbor + 2-opt in Node TS. New endpoint `POST /geocode` backed by Nominatim with the OSMF policy in mind. ADRs to file: ADR-0018 (geocoding policy + migration trigger), ADR-0019 (solver design). Estimated 3-5 days.

### ⏳ Slice 4 — Pix Split paywall via Efí Bank (after slice 3)

Pay-per-route flow per `02-ARCHITECTURE.md` Flow 3. **Prereqs from Eduardo before this slice starts:** `.p12` mTLS certificate (sandbox + prod) downloaded from the Efí dashboard, HMAC webhook secret configured. `client_id`/`client_secret` already in `.env.deploy` (both sandbox and prod). ADR-0007 already covers the architecture decision; this slice files no new ADR unless we deviate. Estimated 4-6 days.

### ⏳ Slice 5 — Sentido casa (after slice 4)

One toggle in Settings + a column on `users` + a branch in the slice 3 solver. Estimated 1 day.

### ⏳ Slice 6 — LGPD (after slice 5)

`GET /me/export`, `DELETE /me`, plus `/termos` and `/privacidade` static pages on the landing. ADR-0020 captures the export format and delete semantics. Estimated 2-3 days.

### ⏳ Slice 7 — Painel admin (after slice 6)

`apps/landing/src/app/(admin)/` with three pages (Users, Payments, Metrics) + admin role + protected backend endpoints. ADR-0021 captures the authorization model. Estimated 3-5 days.

### Total remaining

Approximately 17-25 working days of focused work — about 4-5 weeks of calendar time on a typical solo-dev schedule. Tracked slice-by-slice; don't compress.

---

## M1 — Closed 2026-05-09

> All four contracted criteria reached, escrow release in progress with the client.

## M1 acceptance criteria (verbatim from Workana)

To release escrow, all four must be true:

1. Site live at `https://roteirizadorpro.com.br` with HTTPS.
2. API responds correctly at `https://api.roteirizadorpro.com.br`.
3. Route calculation p95 < 200ms.
4. Client has full access to the server panel.

Detailed plan: `docs/08-ROADMAP.md`.

---

## Phase 1 — Foundations

- [x] Initialize `apps/mobile/` (source files authored 2026-05-08; `flutter create` deferred to first run on a machine with Flutter SDK — see `apps/mobile/README.md`).
- [x] Configure Flutter linter (`flutter_lints`), formatter, analysis options.
- [x] Install Flutter deps: `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`, `build_runner`, `dio`, `flutter_secure_storage`, `go_router` (declared in `pubspec.yaml`; `pub get` runs at first bootstrap).
- [x] Configure `--dart-define API_BASE_URL` and `apps/mobile/.env.example`.
- [x] Initialize `apps/backend/`: Node 20, TypeScript strict, Fastify v5 + TypeBox.
- [x] Initialize `apps/backend/` deps: `@fastify/jwt`, `@fastify/helmet`, `@fastify/cors`, `@fastify/rate-limit`, `@sinclair/typebox`, `@fastify/type-provider-typebox`, `pino`, `bcrypt`, `dotenv`.
- [x] Initialize Prisma 7 + `@prisma/adapter-pg` with `prisma.config.ts`.
- [x] Author `apps/backend/.env.example`.
- [x] Initialize `apps/landing/` with Next.js 14 (App Router) + Tailwind.
- [x] Author `infra/docker-compose.yml` with services: `postgres`, `redis`, `graphhopper`. Bind to 127.0.0.1. (GraphHopper sits behind the `routing` profile — opt-in until the SP PBF lands in Phase 2.)
- [x] `docker compose up` brings up postgres + redis healthy locally.

## Phase 2 — M1 features

- [x] **Backend auth**: `POST /auth/register`, `POST /auth/login`, `POST /auth/refresh`, `GET /auth/me`. JWT RS256, 15min access + 7d refresh, refresh rotation **with reuse detection** (revokes all of the user's refresh tokens on replay).
- [x] **Backend healthchecks**: `GET /health`, `/health/db`, `/health/graphhopper`.
- [x] **Backend `POST /routes/optimize`** placeholder — returns 501 (auth-gated). Full implementation in M2.
- [x] **Backend logging**: Pino JSON to stdout. Rate limits per endpoint: `/auth/login` 5/15min, `/auth/register` 3/h, `/auth/refresh` 10/min; `/health/*` excluded.
- [ ] **Flutter Login screen** (Screen 01 from `prototipo/`) — match prototype 1:1.
- [ ] **Flutter Register screen** (Screen 02 from `prototipo/`) — match prototype 1:1.
- [x] **Flutter Dio client** with base URL from env, Bearer interceptor, auto-refresh on 401 via `QueuedInterceptor` (separate refreshDio to avoid recursion).
- [x] **Flutter token storage** in `flutter_secure_storage` (`AndroidOptions(encryptedSharedPreferences: true)`).
- [x] **Flutter auth notifier** (`@riverpod class AuthController extends _$AuthController` — `build` validates persisted tokens via `/me`; `login`/`register`/`signOut`).
- [ ] **Landing sections**: Hero, product details, how it works, FAQ, contact buttons, footer, APK CTA placeholder.
- [ ] **Landing visual identity** applied (palette + Poppins, original — not Circuit's).
- [x] **GraphHopper SP PBF**: no SP-only PBF is published anywhere; `infra/graphhopper/extract-sp.sh` downloads `sudeste-latest.osm.pbf` from Geofabrik and clips capital SP via `osmium-tool` (bbox `-46.83,-23.78,-46.40,-23.36`, ~115 MB output). PBFs gitignored.
- [x] **GraphHopper config**: `infra/graphhopper/data/config.yml` (motorcycle profile, CH, `-Xmx800m`, `import.osm.ignored_highways` for motor-only, full `graph.encoded_values` list required by `motorcycle.json`).
- [x] **GraphHopper graph build (local)** — verified `curl http://localhost:8989/route?point=...&profile=motorcycle` works against the capital SP graph.
- [x] **Benchmark script** `infra/graphhopper/benchmark.sh` — 100 randomized capital-SP routes, sequential, no warmup, p50/p95/p99.
- [x] **Local benchmark run** — recorded in `docs/BENCHMARKS.md`.

## Phase 3 — M1 deploy

### Phase 3.A — Prep (laptop, no droplet access needed)

- [x] **`scripts/server-bootstrap.sh`** — idempotent one-shot for first SSH (sudo user with provided pubkey, SSH hardening, UFW, fail2ban, hostname/timezone, unattended-upgrades, Docker Engine + Compose, `/opt/roteirizador/` tree).
- [x] **`scripts/backup-postgres.sh`** — pg_dump (custom format, gzip) + 30-day rotation. Cron sample documented in script header.
- [x] **`scripts/rsync-graph-cache.sh`** — laptop → droplet wrapper for the prepared `graph-cache/` and source PBF.
- [x] **`infra/nginx/api.roteirizadorpro.com.br.conf`** — pre-Certbot Nginx site (HTTP-only with proxy_pass to 127.0.0.1:3000; Certbot adds the SSL block in place).
- [x] **`infra/systemd/roteirizador-backend.service`** — Fastify backend as systemd unit (loads `/opt/roteirizador/compose/.env`, runs `bun run start`, basic process hardening).
- [x] **`infra/docker-compose.yml`** made env-driven for Postgres credentials (`${POSTGRES_PASSWORD:-roteirizador}` etc.) so the same compose works dev + prod with `.env` overrides.
- [x] **Production `.env` template + dev/prod diff** documented in [`docs/07-INFRA.md`](docs/07-INFRA.md) §"Production .env template" (couldn't ship `.env.production.example` — `.env*` writes blocked by the project hook).
- [x] **`docs/INSTALL.md`** — end-to-end reproducible runbook spanning §1 bootstrap → §10 acceptance verification.

### Phase 3.B — Execute (DONE 2026-05-09, on droplet via API + SSH)

- [x] Provision droplet via DO API (NYC3, s-1vcpu-1gb, ubuntu-24-04-x64, ssh_keys=[56193220], cloud-init user_data). IPv4 `138.197.38.243`. Updated [`docs/07-INFRA.md`](docs/07-INFRA.md).
- [x] Run `scripts/server-bootstrap.sh` via SSH-stdin (cloud-init's runcmd was overridden by DO vendor data — script idempotently completed Docker install + UFW + fail2ban + SSH hardening + `/opt/roteirizador/` tree).
- [x] Manual fix for sudo NOPASSWD via DO console (the bootstrap script skipped it because the user already existed from an earlier failed attempt; one-line fix in console).
- [x] Add 2 GB swap file (osmium extract OOM'd on 1 GB without it; kept as safety net).
- [x] Repo via rsync, `.env` via scp (chmod 600), compose file copied, `config.yml` rsynced.
- [x] On droplet: install osmium-tool, download `sudeste-latest.osm.pbf` (803 MB, ~30 s on DO bandwidth), extract capital SP via `osmium extract --strategy simple` (smart strategy OOM'd; simple is fine for a routing bbox).
- [x] `docker compose --profile routing up -d` — postgres + redis + graphhopper all healthy. GraphHopper built the graph in ~3 min.
- [x] Install Bun + Node 20 LTS, `bun install --frozen-lockfile`, `node_modules/.bin/prisma migrate deploy` (note: `bunx` doesn't exist in this Bun build — use `bun x` or the local binary), `prisma generate`, install systemd unit, start.
- [x] DNS: `A api.roteirizadorpro.com.br → 138.197.38.243` (Vercel DNS panel, TTL 60).
- [x] Install Nginx + Certbot. `certbot --nginx --redirect` issued cert (expires 2026-08-07), wired SSL block, set up auto-renew via `certbot.timer`. Renewal dry-run passed.
- [x] Backup cron at `0 3 * * *`. Manual run produced a 1.4 KB dump. Restore drill on a throwaway DB succeeded (3 tables present, 1 prisma_migrations row).
- [x] DigitalOcean droplet snapshot `m1-acceptance-baseline-20260509` (action id `3177273363`).
- [ ] DNS: `A @ → 76.76.21.21` (Vercel apex) + `CNAME www → cname.vercel-dns.com`. *Already on Vercel per Eduardo (DNS total na Vercel) — verify the apex/www route to the landing project once the landing is built.*
- [ ] Vercel project root dir `apps/landing`. *Pending — landing page is the last Phase 2 track to build before the landing-related apex DNS.*

## Phase 4 — M1 acceptance

- [ ] **Criterion 1:** visit `https://roteirizadorpro.com.br` from external network. Screenshot. HTTPS green. *Pending the Phase 2 landing page build.*
- [x] **Criterion 2:** `curl https://api.roteirizadorpro.com.br/health` → 200. Auth round-trip works (register → login → me). Verified 2026-05-09 (external smoke from laptop).
- [x] **Criterion 3:** production benchmark, p95 < 200ms, documented in `docs/BENCHMARKS.md`. Three post-warmup runs landed p95 = 36.5–47.2 ms (4–5× under threshold). *Cold-start first-run was 205.6 ms which is the JIT-warm outlier — recorded for transparency.*
- [ ] **Criterion 4:** client confirms (in writing on Workana) that he has DO panel access and can list running containers.
- [x] Author `docs/INSTALL.md` — full reproducible install walkthrough (Phase 3.A — drafted before deploy so we don't author the runbook from memory after the fact). Will receive small additions after the actual deploy if anything diverges.
- [ ] Record demo video covering all four criteria (Loom).
- [ ] Tag `git tag -a v1.0-m1`. Push tag.
- [ ] Notify client in Workana with demo video link + acceptance checklist.

## Discovered while working

- [x] **2026-05-19 (session 16) — Harness Wave C (corrective) landed.** ADR-0020 filed amending ADR-0013 with a single normative `// Mirror of:` header grammar (ASCII `->`, two productions: single-DTO and multi-DTO with brace-list, optional clarifying notes on per-class `///` markers). Rewrote `auth_dtos.dart` L1 + 9 `///` markers to canonical form (was the seventh divergent form). Swept five docs to ASCII (CLAUDE, 03-CONVENTIONS, 02-ARCHITECTURE, M2-SLICE-CHECKLIST, 08-ROADMAP). Hardened `check-dto-mirror.sh` to anchored regex; smoke-tested it now correctly catches both real DTOs as orphaned mirrors when their schemas.ts is edited. Added defensive `xargs -0` to `analyze-changed-dart.sh`. Fixed `/verify-slice` allowed-tools to include `Agent`. Resolved a real Karpathy-violation tension: pre-existing untracked `optimize_route_page.dart` (with 3 info-level analyzer issues from session 13) blocked the second Wave C commit via lefthook `mobile-analyze`; refused `--no-verify`, stashed the untracked file, landed Wave C cleanly, restored. Five Conventional Commits without bypass.
- [x] **2026-05-19 (session 15) — Harness Wave B landed.** ADR-0019 filed; `docs/superpowers/specs/0000-template.md` + `docs/superpowers/plans/0000-template.md` extracted from slice-2 reference implementation (13 H2 sections in spec template; 8 Plan Execution Rules + Phase/Task/Step hierarchy + Self-Review + Execution Handoff in plan template). `/new-spec <slug>` and `/new-plan <slug>` skills created with `disable-model-invocation: true` + `allowed-tools` allowlists; both scaffold-and-stop at the brainstorming / writing-plans gate. Two self-corrections during session: (1) hallucinated "17 H2" → corrected to "13 H2" in ADR-0019 via separate `fix` commit (no amend); (2) invalid scope `superpowers` rejected by commitlint → re-committed as `docs(docs):`. Harness modernization arc (waves A + B together) closed.
- [x] **2026-05-19 (session 14) — Harness Wave A landed.** ADR-0018 filed; three Stop-matcher hooks (`analyze-changed-dart.sh`, `check-dto-mirror.sh`, `warn-adr-drift.sh`) wired in `.claude/settings.json`; `/verify-slice` skill created. All non-blocking (exit 0/1 only — only `block-env.sh` keeps the exit-2 blocking contract). Smoke-tested in six real scenarios before commit.
- [x] **2026-05-13 (between M1 and M2 slice 1)** — Android SDK installed; `flutter doctor` is green for Android tooling (SDK 36.1.0). The only remaining `flutter doctor` flag is CocoaPods (iOS), irrelevant to this Android-only project.
- [ ] Local dev currently runs Node v24 — runtime is locked to Node 20 LTS by ADR-0003. `.nvmrc` declares 20; run `nvm use` (or install nvm) before `bun run dev` / `bun run build` going forward.
- [ ] Re-evaluate TS 5 → 6 bump after M1 ships (TS 6.0 just released; deferred to avoid new strictness errors during Phase 2).
- [ ] Re-evaluate Tailwind 3 → 4 and React 18 → 19 after M1 ships (both require new ADRs because they propagate breaking changes).
- [ ] Disable `stripe` plugin manually in `~/.claude/settings.json` line 17 — set `"stripe@claude-plugins-official": false`. The in-session edit was blocked by Claude Code's self-modification guard.
- [ ] **Post-M1: switch password hashing from bcrypt cost 12 → argon2id.** OWASP 2026 recommends argon2id as the default; bcrypt cost 12 is still acceptable but argon2id is GPU-resistant. Requires new ADR (stack lock) + on-next-login migration helper.
- [ ] **Post-M1: revisit production runtime.** Backend currently runs via `tsx src/index.ts` in both dev and prod (Prisma 7's `prisma-client` generator emits TS-only with extension-less imports — needs a TS-aware runtime). Options post-M1: keep tsx (works fine on Node 20), bundle with esbuild/tsup, or switch the runtime to Bun (would invalidate ADR-0011's runtime split).
- [ ] **Post-M1: per-device refresh-token families.** Today, reuse detection revokes ALL of the user's refresh tokens (full re-auth across devices). Adding a `family_id` column scopes revocation to the compromised session only. Stricter security than necessary for M1; friction-y at scale.
- [x] Reconcile Claude Code hooks (`.claude/hooks/`) with Lefthook pre-commit. Boundary documented in [ADR-0012](docs/decisions/0012-dx-tooling.md) — Claude hooks fire on agent tool calls; Lefthook fires on `git commit` for everyone.
- [x] Convention mismatch in `docs/03-CONVENTIONS.md` Dart naming. Fixed to snake_case (Effective Dart) instead of the previously-listed kebab-case, matching the actual filenames in the repo.

---

## Done

- [x] **2026-05-05** — `CLAUDE.md` authored and rewritten (Karpathy + Anthropic primary sources).
- [x] **2026-05-05** — `CONTRIBUTING.md`, `docs/03-CONVENTIONS.md`, session log structure.
- [x] **2026-05-05** — `.gitignore`, `.editorconfig`, `README.md`.
- [x] **2026-05-05** — `docs/01-PROJECT.md`, `docs/02-ARCHITECTURE.md`.
- [x] **2026-05-05** — Roadmap docs (later replaced by `docs/08-ROADMAP.md`), `docs/09-DISASTER-RECOVERY.md`.
- [x] **2026-05-05** — ADRs 0001–0010 (all stack decisions documented).
- [x] **2026-05-05** — `docs/04-FEATURES.md`, `docs/05-SCREENS.md`.
- [x] **2026-05-05** — Monorepo skeleton (`apps/`, `infra/`, `scripts/`).
- [x] **2026-05-05** — `SECURITY.md`, `.github/pull_request_template.md`.
- [x] **2026-05-06** — `docs/06-DESIGN-SYSTEM.md`, `docs/07-INFRA.md`.
- [x] **2026-05-07** — Approved Claude Design prototype tracked in repo at `prototipo/`.
- [x] **2026-05-07** — Documentation reorganization: M1-focused, prototype-aligned, redundancy removed. See `docs/10-CHANGELOG.md`.
- [x] **2026-05-08** — Phase 1 Foundations complete: backend (Fastify v5 + TypeBox + Prisma 7), landing (Next.js 14 + Tailwind), mobile (Flutter source skeleton), `infra/docker-compose.yml` with postgres + redis healthy locally and graphhopper opt-in via `routing` profile.
- [x] **2026-05-08** — Migrated to Bun as package manager (Node 20 LTS stays the runtime). Bumped six compatible major deps in backend (`@fastify/jwt` 10, `@fastify/type-provider-typebox` 6, `bcrypt` 6, `pino` 10, `pino-pretty` 13, `dotenv` 17). See ADR-0011.
- [x] **2026-05-08** — Installed Flutter SDK 3.41.9 via `brew install --cask flutter`, ran `flutter create --platforms=android --org br.com.roteirizadorpro --project-name roteirizador_pro --no-pub .` in `apps/mobile/`, resolved deps with `flutter pub get`, verified with `flutter analyze` (clean) and `flutter test` (1/1 passing).
- [x] **2026-05-08** — Wired up Claude Code automations under `.claude/`: PreToolUse hook blocking `.env*` edits (except `.env.example`), PostToolUse hook auto-formatting Dart files inside `apps/mobile/`, two subagents (`prototype-fidelity-checker` for UI vs `prototipo/`, `adr-guardian` for stack-change/ADR enforcement), two skills (`session-end`, `new-flutter-feature` — both user-only), and replaced the blanket `.claude/` rule in `.gitignore` with a granular pattern so team-shared automations are versioned. Disabled `firebase` plugin globally; `stripe` deferred (sandbox blocked self-modification).
- [x] **2026-05-08** — Implemented Login + Register screens 1:1 with `prototipo/screens-a.jsx` Screen 01 and 02. Replaced placeholder. Added shared widgets (`RpButton`, `RpGhostButton`, `RpInput`, `RpLogo`), full prototipo color palette in `AppColors`, Poppins via `google_fonts`, GoogleSignIn glyph as bundled SVG asset (`flutter_svg`). Verified end-to-end on the Pixel 8 emulator.
- [x] **2026-05-08** — Adopted Lefthook 2.x + commitlint 20.x + commitizen at the repo root (ADR-0012). Pre-commit runs typecheck/lint/analyze for the changed app in parallel; `commit-msg` validates Conventional Commits; `bun run commit` walks an interactive Commitizen wizard. Added shared VS Code settings (`.vscode/extensions.json`, `.vscode/settings.json.example`) including `dart.flutterHotReloadOnSave: always`. Added GitHub Actions CI (`.github/workflows/ci.yml`) with `backend`, `landing`, `mobile`, `commitlint` jobs.
- [x] **2026-05-08** — Codified the schema source-of-truth ([ADR-0013](docs/decisions/0013-api-contract-source-of-truth.md)): Prisma owns the DB; TypeBox owns the HTTP API contract; Dart DTOs mirror TypeBox 1:1 with a `// Mirror of:` header. Added the rule to `CLAUDE.md`, `docs/02-ARCHITECTURE.md` ("API Contracts & Type Safety"), `docs/03-CONVENTIONS.md` §8, and the reference template at `apps/mobile/lib/features/auth/data/dto/_template.dart`. Verified clean with `flutter analyze --no-pub`. OpenAPI export + Dart codegen deferred to post-M1.
- [x] **2026-05-08** — Mobile auth integration shipped end-to-end. `flutter_secure_storage` (with `EncryptedSharedPreferences` + namespaced keys) wraps `access`/`refresh` tokens; `AuthRepository` wraps Dio; `AuthInterceptor extends QueuedInterceptor` adds Bearer on every non-`/auth/*` request and rotates atomically on 401 (separate `refreshDio` to avoid recursion; on refresh failure clears tokens + signals `signOutLocal` via Riverpod ref). `@riverpod AuthController` validates persisted tokens via `/auth/me` on startup and exposes `login`/`register`/`signOut`. GoRouter redirect is reactive to auth state via a `ChangeNotifier` bridge. `lib/features/home/presentation/home_placeholder_page.dart` is the post-login stub (real Screen 03 is M2). Android `network_security_config.xml` permits cleartext only for 10.0.2.2/127.0.0.1/localhost so prod stays HTTPS-only. End-to-end smoke-tested on Pixel_8 emulator: register-via-curl → login on UI → /home renders with `/auth/me` payload → tap Sair → /login. All `flutter analyze` clean post `dart run build_runner build`.
- [x] **2026-05-08** — Backend auth + healthchecks shipped (Phase 2). `POST /auth/{register,login,refresh}` and `GET /auth/me` with TypeBox schemas as source of truth, JWT RS256 (15min access + 7d opaque refresh, rotation + reuse detection cascading to revoke all of the user's tokens), bcrypt cost 12, per-route rate limits (login 5/15min, register 3/h, refresh 10/min), `GET /health{,/db,/graphhopper}`, and `POST /routes/optimize` placeholder (auth-gated, 501). Mirrored every TypeBox schema into `apps/mobile/lib/features/auth/data/dto/auth_dtos.dart` per ADR-0013, same commit. Smoke-tested all 12 paths (round-trip + reuse cascade + validation 400 + 401/403/409/501) green. Moved Prisma client generator output to `src/generated/client` so TS rootDir resolves; backend runtime standardized on `tsx src/index.ts` (tsx promoted from devDependency to dependency). Added `scripts/generate-jwt-keys.sh` for local key bootstrap.
