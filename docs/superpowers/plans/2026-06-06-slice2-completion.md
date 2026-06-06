# Slice 2 Completion — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: `superpowers:executing-plans` — execute ONE microsprint (one area) per session, with a review checkpoint at each MS boundary. Each MS runs the same 5-phase per-area pipeline. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Finish Slice 2 (white-label functional clone of the B2C Spoke Route Planner) area-by-area, each area run through the mandatory 5-phase pipeline (modern-stack research → fresh live Spoke dump of ONLY that area → implement TDD → harness validation → harness-current), ending with a green `v1.1.0`.

**Architecture:** No new module. One MS per area. The invariant every MS runs is the 5-phase pipeline + the dependency-ordered sequence. Triggers live in `apps/mobile/lib/app.dart` (the inline GoRouter `_routerProvider` — there is NO `app_router.dart`).

**Tech Stack:** Flutter 3.44.0 / Dart 3.12.0 · flutter_riverpod 3.0.0 (codegen) · go_router 14.6.0 · google_maps_flutter 2.17.1 · Material 3. Backend Fastify v5 + TypeBox + Prisma 7 (Slice 3, mostly stubbed here). 3 post-cutoff idioms are LIVE: `onReorderItem`, `RadioGroup<T>`, sealed `AsyncValue`.

**Spec:** `docs/superpowers/specs/2026-06-06-slice2-completion.md`

**Branch:** finish Área 5 on `feat/m2-slice-2-area-5-route-details`; new areas on per-area branches `feat/m2-slice-2-area-N-<topic>` OR an integration branch `feat/m2-slice-2-spoke-clone` (decide at MS0). PR to develop, tag `v1.1.0` at the end.

---

## Working directory

Repo root: `/Users/eduardorodrigues/Documents/Projetos/Clientes/ueslei-workana/app-roteirizadorpro`. Paths below are repo-root-relative.

## Plan execution rules

1. **One area = one microsprint = one (or few) logical commits.** Conventional Commits + valid scope from `commitlint.config.cjs`. No `--no-verify`.
2. **The 5-phase per-area pipeline (§Phase template) is MANDATORY** — it is not optional ceremony; it is the cure for the MS4/MS5 stale-baseline failures.
3. **Riverpod codegen:** after editing any `@riverpod` file, the PostToolUse hook regenerates `.g.dart` (90s debounce); else run `cd apps/mobile && dart run build_runner build --delete-conflicting-outputs`. Do NOT commit `.g.dart` (ADR-0005).
4. **Surgical scope:** `git diff <base> HEAD --stat` shows only the area's files + `app.dart` if nav touched. After any Workflow/3+-agent dispatch: `git status` + `git diff HEAD --stat` BEFORE staging.
5. **3.44 idioms over memory:** verify every widget API against Dart MCP (`mcp__dart__hover`/`analyze_files`). Never emit `onReorder` (use `onReorderItem`), per-Radio `groupValue` (use `RadioGroup<T>`), or `AsyncValue` with a `default` branch.
6. **Zero debt:** no `// TODO`/`// FIXME`/`// MS` in the diff. A divergence is fixed in its MS or escalated as BLOCKED.
7. **Push + checkpoint after each MS** (when Eduardo asks). PR only after MS-DEBT + the last area.

## Execution order (dependency-forced — do NOT reorder)

```
1. MS-A5.6  Área 5 — Pausa sheet            ┐
2. MS-A5.7  Área 5 — wire Á3 config rows    │ finish Área 5 (current branch)
3. MS-A5.8  Área 5 — persistence + FTUE     │
4. MS-A5.9  Área 5 — integration_test+D4+PR ┘  ← FIRST integration_test authored
5. MS-A3    Área 3 — wire triggers (Otimizar CTA / stop-card tap / kebab)
6. MS-A6    Área 6 — Editar parada (sheet, 14 fields)
7. MS-A7    Área 7 — Otimizar (3 states + 3 FTUE)
8. MS-A8    Área 8 — Modo Delivery
9. MS-A9    Área 9 — Conclusão + core telas
   ── independent, interleave anytime ──
   MS-A1    Área 1 — auth UI leftovers     (NO Spoke baseline)
   MS-A10   Área 10 — Settings             (precede MS-A11)
   MS-A11   Área 11 — Notifications        (NO Spoke baseline; row inside Settings)
   MS-DEBT  23 analyze lints burn-down     (before the slice PR)
   MS-PR    Integration + slice PR + tag v1.1.0
```

---

## Phase 0 — Pre-flight (once, at MS0; no commits)

### Task 0: Verify environment + decide branch strategy

- [ ] **0.1 Clean tree + branch.** `git status`; `git rev-parse --abbrev-ref HEAD`; `git log --oneline -3`. For Área 5 MSs stay on `feat/m2-slice-2-area-5-route-details`. For new areas decide: per-area branches vs one `feat/m2-slice-2-spoke-clone`. After any prior Workflow: `git diff HEAD --stat` to catch staged cross-scope edits.
- [ ] **0.2 Toolchain.** `flutter --version` (expect 3.44.0 / Dart 3.12.0), `bun --version`, `node --version`. `flutter doctor -v`.
- [ ] **0.3 Device + Spoke.** Confirm M54: `adb devices` shows `RQCW401G33T`; `mcp__maestro__list_devices` returns it. Spoke (`com.underwood.route_optimiser`) logged in. (Ask Eduardo for a one-line confirm.)
- [ ] **0.4 Read the spec + roadmap Slice 2 + the NEVER-AGAIN list.** The 30-item bad-practices catalogue in the spec is the safety net every MS upholds.

No commit.

---

## Phase template — the 5-phase per-area pipeline (run inside EVERY area MS below)

Every area MS (MS-A5.6 … MS-A11) executes these five phases. The per-area sections below specify only what's AREA-SPECIFIC; the phase mechanics are here, once.

### Phase 1 — Modern-stack research (no code)
- [ ] Dart MCP first for installed-package symbols (`mcp__dart__hover`, `mcp__dart__analyze_files`, `mcp__dart__pub_dev_search`).
- [ ] Context7 next (`mcp__claude_ai_Context7__resolve-library-id` → `query-docs`) for `/websites/flutter_dev`, `/rrousselgit/riverpod`, `/websites/pub_dev_google_maps_flutter`.
- [ ] WebSearch only for post-cutoff release notes.
- [ ] **Output:** the current 3.44 idiom for each widget/pattern the area needs + cited source + gotcha. MUST confirm the relevant post-cutoff breaking change(s).

### Phase 2 — Fresh live Spoke dump of ONLY this area  *(SKIP for MS-A1, MS-A11 — no Spoke baseline)*
- [ ] Confirm M54 + Spoke logged in. Dispatch `spoke-parity-checker` UPFRONT with a description that EXPLICITLY requests the `bounds | content-desc/text | visual pattern | SPECIFIC Flutter widget` table.
- [ ] Maestro MCP `inspect_screen` + `take_screenshot` at EVERY state of the area's screen(s). Save PNGs to `/tmp/spoke-<areaSlug>-inspection/`.
- [ ] Cite screenshot PIXELS for every icon presence/absence claim (XML is blind to Compose icons).
- [ ] **Halt condition:** if the live capture contradicts the roadmap/inventory STRUCTURALLY (widget shape / nav model / state model / persistence model), escalate to Eduardo and file a new ADR BEFORE implementing. Do NOT implement either version. A prior `/tmp` capture is corroboration only.

### Phase 3 — Implement (TDD, Spoke-faithful, zero debt)
- [ ] (Optional) `flutter-test-author` writes the failing test first + `throw UnimplementedError()` stub.
- [ ] Implement with Phase-1 idioms + Phase-2 Spoke shape. Every divergence → code change + paired test assertion (assert the Spoke shape, not old spec wording).
- [ ] Quality rules: no silent `onTap`, `AsyncValue` 3-state, `ListView.builder` for data lists, no dead-end flow, `Semantics(identifier:)` on interactive elements.
- [ ] If nav touched, edit `apps/mobile/lib/app.dart` (the router) — it's in scope.

### Phase 4 — Harness validation gates (before declaring the area done)
- [ ] `cd apps/mobile && flutter analyze` clean (scope). `flutter test` ≥ baseline ("All tests passed!" + exact count).
- [ ] `cd apps/backend && bun run typecheck` if backend touched.
- [ ] **`integration_test/` on M54 if nav touched:** `cd apps/mobile && flutter test integration_test/ -d RQCW401G33T`.
- [ ] `spoke-parity-checker` D4 closing (NOT MS-A1/MS-A11) — must-fix BLOCKS; should-fix → explicit TODO debt; nit ignored. Report cites screenshot pixels + `Inspection path:`.
- [ ] `flutter-perf-auditor` sweep (9-check). `adr-guardian` if stack touched.
- [ ] Smoke E2E release on M54: `bash apps/mobile/scripts/build-release-apk.sh` (wires `--dart-define`).
- [ ] **Mechanical gate-check:** All tests passed (count) + No issues found (scope) + `git diff <base> HEAD --stat` scope-only + `git grep -nE 'TODO|FIXME|// MS' apps/mobile/lib/` empty in diff + every divergence → code AND test. If ANY fails, the area is NOT done.

### Phase 5 — Harness current (end of area)
- [ ] Update `TODO.md` inline (mark `[x]`, add discovered `[ ]`). Mark the area ✅ in `docs/08-ROADMAP-v2.md`. CHANGELOG inline. Session log if non-obvious.
- [ ] Checkpoint: `git push` + TODO sub-bullet + session log if needed. Commit/push only when Eduardo asks.

---

## Phase MS-A5.6 — Área 5: Pausa sheet

**Files:** Create `apps/mobile/lib/features/route_config/presentation/widgets/break_scheduler_sheet.dart` + test; Modify `route_details_page.dart` (replace the `:290` "Pausa em breve" SnackBar), `route_config.dart`/controllers if the Pausa state isn't modeled.

- [ ] **Phase 1:** verify `showTimePicker` Material 3 + chip selection (FilterChip/ChoiceChip) idioms.
- [ ] **Phase 2:** live-dump the Spoke Pausa sub-flow (tap "Adicionar pausa" → capture the picker: horário field + duração options 15/30/60/custom).
- [ ] **Phase 3:** build `break_scheduler_sheet.dart` (returns-intent pattern — pop the chosen break; parent applies). Wire `route_details_page.dart:290` to open it. TDD.
- [ ] **Phase 4 + 5.** Commit `feat(route-config): Área 5 MS6 break scheduler sheet`.

## Phase MS-A5.7 — Área 5: wire Área 3 config rows

**Files:** Modify `apps/mobile/lib/features/routes/presentation/route_shell_page.dart` (the 3 inline config rows Início/Ida-e-volta/Pausa → clickable, reopen sub-pickers), `app.dart` if a row pushes a route.

- [ ] **Phase 1:** confirm sheet-returns-intent + GoRouter sub-route patterns (re-read lesson #5).
- [ ] **Phase 2:** re-confirm the Spoke inline-config rows behavior (which row opens which sub-picker).
- [ ] **Phase 3:** make each row clickable → reopen Partida/Destino/Pausa. NO silent onTap. TDD.
- [ ] **Phase 4:** **integration_test if a row pushes a route.** Commit `feat(route-config): Área 5 MS7 wire active-route config rows`.

## Phase MS-A5.8 — Área 5: persistence + FTUE

**Files:** Modify `route_defaults_controller.dart` + `route_defaults.dart` (SharedPreferencesAsync `route_defaults_v1` envelope), FTUE trigger in the wizard/details flow.

- [ ] **Phase 1:** confirm `SharedPreferencesAsync` API (the project standard, not legacy `SharedPreferences`).
- [ ] **Phase 2:** **re-confirm the open Q8** — "Salvar como padrão" default (currently UNCHECKED per ADR-0043) against a FRESH Spoke account; and whether Detalhes is FTUE one-time (§13.C.2 resolved FTUE).
- [ ] **Phase 3:** persist the envelope; wire FTUE-once. Respect the `_omit` sentinel clear-path (anti-pattern #9) + test it. Bare-catch logging (anti-pattern #11).
- [ ] **Phase 4 + 5.** Commit `feat(route-config): Área 5 MS8 persist route defaults + FTUE`.

## Phase MS-A5.9 — Área 5: integration_test + D4 + PR  *(FIRST integration_test authored)*

**Files:** Create `apps/mobile/integration_test/area5_route_details_flow_test.dart` (+ `integration_test/` dir, `dev_dependencies: integration_test` if absent).

- [ ] **Phase 1:** confirm `integration_test` + `IntegrationTestWidgetsFlutterBinding` + the device-run idiom.
- [ ] **Phase 3:** author the **5-route Android-back chain** test (open details → Partida → Destino → Pausa → back-stack pops correctly). Use `Semantics(identifier:)` ids; do NOT `tapOn` inner text (anti-pattern #7).
- [ ] **Phase 4:** run `flutter test integration_test/ -d RQCW401G33T` — must pass. `spoke-parity-checker` D4 closing for the whole Área 5 flow. Maestro YAML smoke (creds via `${MAESTRO_EMAIL}` env, anti-pattern #28).
- [ ] **Phase 5 + PR:** open the Área 5 PR (or fold into the slice integration branch per MS0). Mark Área 5 ✅.

## Phase MS-A3 — Área 3: wire the triggers

**Files:** Modify `route_shell_page.dart` (map layer-toggle + recenter `:17`/`:205`; Otimizar CTA → Área 7 route; stop-card tap `:103` → Área 6 edit-stop; kebab/bottom-bar `:483` → Área 9 surfaces), `app.dart` (register Área 6/7/9 routes as they land).

- [ ] **Phase 1:** `google_maps_flutter` controller (layer/recenter via `GoogleMapController` + `mapType`/`animateCamera`).
- [ ] **Phase 2:** re-confirm the Spoke active-route controls + triggers.
- [ ] **Phase 3:** wire layer-toggle + recenter (real, not `_comingSoon`). Wire Otimizar CTA + stop-card tap + kebab to push the (initially placeholder, then real) Área 6/7/9 routes. NO silent onTap — if a target area isn't built yet, an interim "em breve" SnackBar is acceptable ONLY as a temporary bridge, removed when the target lands.
- [ ] **Phase 4:** integration_test for the new nav. Commit `feat(routes): Área 3 wire map controls + area triggers`.

> Note: MS-A3 can interleave with MS-A6/7/9 — wire each trigger as its target area lands, to avoid a dead "em breve" shipping.

## Phase MS-A6 — Área 6: Editar parada (sheet, 14 fields)

**Files:** Create `apps/mobile/lib/features/routes/presentation/widgets/edit_stop_sheet.dart` + color/instructions sub-sheets + tests; Modify `add_stop_page.dart:103` (replace "Editar parada em breve"), the shared `/home/routes/add-stop` route mounting, Stop domain/controllers for the 14 fields.

- [ ] **Phase 1:** `showModalBottomSheet(isScrollControlled:true, useSafeArea:true, showDragHandle:true)` + `SingleChildScrollView` + `viewInsets.bottom` for the 14-field form; `SegmentedButton<T>` (Set selection); destructive `ListTile` + `colorScheme.error` + `AlertDialog`. (Spec §best-practices.)
- [ ] **Phase 2:** live-dump Editar parada at EVERY state — the 14 fields, the color sub-sheet (5 colors, Limpar/Concluído), the "Instruções de acesso" 2nd sheet (sticky-to-address, §13.C.3). Cite pixels for icons.
- [ ] **Phase 3:** build the sheet. Sheet-returns-intent for any navigation (anti-pattern #5). "Remover parada" → AlertDialog confirm. Pacotes/Ordem/Tipo always active (§13.C.1). NO failure-reason picker (B2B). "Mudar endereço" re-enters Á4 (inherits live Places key). TDD each field.
- [ ] **Phase 4:** integration_test (sheet open/edit/close nav). `spoke-parity-checker` D4. Commit `feat(routes): Área 6 edit-stop sheet`.

## Phase MS-A7 — Área 7: Otimizar (3 states + 3 FTUE)

**Files:** Create `optimize_route_*` (AsyncNotifier provider + 3 state screens + 3 FTUE modals) + tests; Modify `route_shell_page.dart` (Otimizar CTA), `app.dart`.

- [ ] **Phase 1:** Riverpod 3 `@riverpod` AsyncNotifier + `AsyncValue.guard` + **sealed `AsyncValue` exhaustive switch** (no default). `ReorderableListView.onReorderItem` (NOT `onReorder`) if reorder lands here. `@Riverpod(keepAlive:true)` so the optimize result survives navigation.
- [ ] **Phase 2:** live-dump the 3 states (FTUE "IDs ajustados" → PRE-CONFIRM map+polyline+summary+3 CTAs → "IDs definitivos" → "Carregar veículo?" → Ready-to-Run). **§13.C.4 PENDING:** live-inspect "Refinar"; if impractical, fallback = single-button re-run, recorded as explicit decision.
- [ ] **Phase 3:** build the funnel. 3 FTUE flags in SharedPrefsAsync. Optimize is FREE (no paywall). CUT: "Compartilhar rota em tempo real" (B2B) + "Carregar veículo" (OUT-OF-SCOPE M2). "Iniciar rota" → Área 8 route. TDD.
- [ ] **Phase 4:** integration_test (state transitions + FTUE-once). D4. Commit `feat(routes): Área 7 optimize flow`.

## Phase MS-A8 — Área 8: Modo Delivery

**Files:** Create `delivery_mode_*` (provider + screen + status mutations + marker encoding) + tests; Modify `app.dart`.

- [ ] **Phase 1:** `google_maps_flutter` live-following (controller + geolocator stream + `_followUser` flag + `distanceFilter`). `AsyncValue.guard` for status mutations. **`Column { Expanded(GoogleMap), sheet }` — NEVER Stack** (anti-pattern #4).
- [ ] **Phase 2:** live-dump the per-stop states (3 status buttons conditional by `Stop.type`; marker encoding pending/failed/delivered/current; "Destino final" 2-button state). Confirm "Navegar" deeplink + X-close confirm dialog.
- [ ] **Phase 3:** build. "Navegar" → `url_launcher` geo: URI (paywall checkpoint — verifies `user.isPaid`, bypassed in Slice 2). "Não entregue" → silent Failed + auto-advance (NO reason picker). "Entregue"/"Coletado" conditional. Map follows with the flag. TDD.
- [ ] **Phase 4:** integration_test (status + auto-advance + handoff nav). D4. perf-auditor (map screen). Commit `feat(routes): Área 8 delivery mode`.

## Phase MS-A9 — Área 9: Conclusão + core telas

**Files:** Create completion screen + ShareSheet (`/settings/share`) + active-route kebab sheet + RoutesListPage + reorder; tests; Modify `app.dart`, `route_shell_page.dart` kebab `:483`.

- [ ] **Phase 1:** `ReorderableListView.onReorderItem` (reorder); QR (`qr_flutter` if needed → ADR + Context7); summary metric cards via a derived `@riverpod` provider (NOT stored totals — anti-pattern #9).
- [ ] **Phase 2:** live-dump "Rota concluída!" + kebab (3 options, RotPro 4th "Compartilhar resumo" opportunity) + active-route kebab (5 options). **§13.C.5 PENDING:** peer-transfer semantics — both postponed.
- [ ] **Phase 3:** build completion + ShareSheet (WhatsApp + copy link + QR) + RoutesListPage + drag-reorder. CUT: "Compartilhar cópia"/"Transferir paradas" (B2B-adjacent, postponed → "Em breve"). TDD.
- [ ] **Phase 4:** integration_test (completion + wizard-reuse nav). D4. Commit `feat(routes): Área 9 completion + core screens`.

## Phase MS-A10 — Área 10: Settings (13 rows)

**Files:** Create `apps/mobile/lib/features/settings/` (settings page + radio-modal pickers + providers) + tests; Modify `app.dart` (`/settings` route), drawer gear entry.

- [ ] **Phase 1:** Material 3 `ListView`+`ListTile`/`SwitchListTile.adaptive`; **`RadioGroup<T>` ancestor** (NOT per-Radio groupValue — anti-pattern via #7/post-cutoff). Section headers via `Padding(Text())`.
- [ ] **Phase 2:** live-dump Settings (several pickers were INFERRED, not tap-drilled — tag `[INFERRED — VERIFY BEFORE LOCK]` and drill the ones the MS touches). App-de-navegação = GoogleMaps/Waze/Outro only (no Yandex). Vehicle 5 options (Caminhão grande unsupported).
- [ ] **Phase 3:** build the 13 rows + radio modals (return chosen value, parent updates — don't mutate from dialog). "Sair" = red logout (clears secure storage). Decide "Balão do modo de navegação": disabled/removed (no internal nav). Drop the Tema row + empty section. TDD.
- [ ] **Phase 4:** integration_test (settings route + picker modals). D4. Commit `feat(settings): Área 10 settings screen`.

## Phase MS-A11 — Área 11: Notifications  *(NO Spoke baseline)*

**Files:** Create `notifications_settings_page.dart` + provider + test; Modify `app.dart` (`/settings/notifications`), the Settings list (add the Notificações row).

- [ ] **Phase 1:** `SwitchListTile` / `RadioGroup<T>`; `SharedPreferencesAsync` persistence.
- [ ] **Phase 2: SKIP** — no Spoke baseline. This is original RotPro UI derived from directive #9 + the Slice-3 FCM plan. Do NOT dispatch `spoke-parity-checker`.
- [ ] **Phase 2-alt: confirm with Eduardo** that "Atualização de status" = self-notification (B2C), NOT customer-notification (B2B). Record the answer.
- [ ] **Phase 3:** 3 toggles (Lembrete início rota / Atualização de status / Promoções) persisted in SharedPrefsAsync. FCM real is Slice 3. TDD.
- [ ] **Phase 4:** integration_test (route). NO D4 parity (no baseline). Commit `feat(settings): Área 11 notification settings stub`.

## Phase MS-A1 — Área 1: auth UI leftovers  *(NO Spoke baseline)*

**Files:** Create `forgot_password_page.dart` + test; Modify `login_page.dart:223` (replace SnackBar; add Google button), `register_page.dart` (Google button), `app.dart` (`/auth/forgot-password`).

- [ ] **Phase 1:** form validation + GoRouter route idioms (match existing login/register style).
- [ ] **Phase 2: SKIP** — RotPro keeps its existing auth screens (directive #8); Spoke login was never deep-inspected and isn't being cloned. No parity-checker.
- [ ] **Phase 3:** forgot-password screen (email + "Enviar link" — UI only, backend Slice 3). "Continuar com Google" button on login + register (Apple/Facebook cut, directive #2). NO silent onTap (interim SnackBar until Slice 3 backend). TDD.
- [ ] **Phase 4:** integration_test (auth route). Commit `feat(auth): Área 1 forgot-password screen + Google button (UI)`.

## Phase MS-DEBT — 23 analyze lints burn-down

**Files:** `reuse_stops_page.dart` (11), `add_stop_map_page.dart` (5), `places_repository.dart` (4), `drawer_header_card.dart` (1), `app_drawer.dart` (1), `current_route_stops_provider_test.dart` (1).

- [ ] **Read each lint first.** Fix root cause (trailing commas, untyped `dio.post/get` generics, unused `_kebabActionLabel`, inference_failure). NEVER `// ignore:` (anti-pattern — suppression banned).
- [ ] `cd apps/mobile && flutter analyze` → **"No issues found!"**. `flutter test` ≥ 249.
- [ ] Commit `fix(routes): clear 23 pre-existing analyze lints (Slice 2 Done gate)`.

## Phase MS-PR — Integration + slice PR + tag

- [ ] **Full sweep:** `flutter analyze` clean + `flutter test` ≥ 249+ + `bun run typecheck` + `flutter test integration_test/ -d RQCW401G33T`.
- [ ] **`/verify-slice`** GO verdict. **Smoke E2E** golden path (spec §Goals 1–7) on M54 release build.
- [ ] **Open PR** `feat/m2-slice-2-spoke-clone` → develop (PR body per `M2-SLICE-CHECKLIST.md`). Await Vercel preview if landing touched (it isn't).
- [ ] **Promotion PR** develop → main, tag `v1.1.0`, production smoke. `/session-end`. Mark Slice 2 ✅ in roadmap + TODO.

---

## Self-review

**Spec coverage:** every spec section maps to tasks.
- §Decisions Q1 (all areas) → all MS-A* + MS-DEBT. Q2 (order) → the execution-order block. Q3 (5-phase) → the Phase template, run in every MS. Q4 (no baseline) → MS-A1/MS-A11 Phase-2 SKIP. Q5 (integration_test) → every MS Phase-4 + MS-A5.9 first. Q6 (lints) → MS-DEBT. Q7 (3.44 idioms) → each MS Phase-1 + rule #5. Q8 (B2B cuts) → MS-A7/A9/A11 explicit cuts.
- §Goals (golden path) → MS-PR smoke. §Architecture (pipeline + graph) → Phase template + order. §Risks → mitigations inside each MS. §Bad-practices → embedded per area + rules #4/#5/#6.

**Placeholder scan:** no `TBD`/`TODO` in step bodies; the `[INFERRED]` tags in MS-A10 are intentional (drill-before-lock guards).

**Scope check:** one area per MS, dependency-ordered, single slice, ending in one PR + tag.

**Type consistency:** router file is `app.dart` (NOT `app_router.dart`) everywhere; baseline 249 tests; branch + tag (`v1.1.0`) consistent.

The plan is ready.

---

## Execution Handoff

Execute ONE area MS per session via `superpowers:executing-plans`, in the dependency order above. Each MS runs the 5-phase pipeline; the live-dump (Phase 2) is the non-skippable cure for the MS4/MS5 failures. Do NOT open the PR until MS-DEBT + the last area. The `spoke-microsprint.js` workflow (after the restructure sprint renames it) can drive any area MS with its halt gates.
