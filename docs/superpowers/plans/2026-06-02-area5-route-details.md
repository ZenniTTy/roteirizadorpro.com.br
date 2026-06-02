# Area 5 (Slice 2): Detalhes da rota — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` to implement this plan task-by-task. One subagent per MS (microsprint). Two-stage review after each MS: spec compliance first, then code quality.

**Goal:** Ship the Spoke-aligned "Detalhes da rota" screen with 5 sub-pickers + Area 3 sheet wiring + SharedPreferencesAsync persistence + FTUE trigger; total 14 testable acceptance steps on Samsung M54.

**Architecture:** New `apps/mobile/lib/features/route_config/` module with sealed `RouteConfig` + 3 pages + 4 widgets + 2 Riverpod controllers + 1 repository. Extend `AddStopPage` (Area 4) with `PickerMode` nullable enum to reuse search pipeline for Partida + Destino pickers. Wire Area 3 sheet rows. New `wheel_picker ^0.3.0` dependency (ADR-0040).

**Tech Stack:** Flutter 3.44 + Dart 3.12, Riverpod 3 (`@riverpod` codegen), GoRouter, Material 3, `wheel_picker ^0.3.0`, `SharedPreferencesAsync`.

**Spec:** `docs/superpowers/specs/2026-06-02-area5-route-details.md`

**Branch:** `feat/m2-slice-2-area-5-route-details` (off `develop` at `b4d2d0a`, already created).

---

## Working directory

`/Users/eduardorodrigues/Documents/Projetos/Clientes/ueslei-workana/app-roteirizadorpro` (no spaces — direct cwd from repo root).

## Plan execution rules

1. **One MS = one logical group of commits.** Each MS ends with both spec-reviewer ✅ + code-quality-reviewer ✅ before next MS starts.
2. **TDD red→green→commit** per task within MS.
3. **No `--no-verify`.**
4. **Riverpod codegen** — `dart run build_runner build --delete-conflicting-outputs` after every `@riverpod` edit; PostToolUse hook runs it automatically.
5. **Hot reload first** (`r` in `flutter run`). Hot restart only for new providers / new routes.
6. **Surgical edits only.** Touching `add_stop_page.dart` is in-scope for MS3; touching `route_sheet.dart` is in-scope for MS7. Nothing else outside `lib/features/route_config/` should change.
7. **Schema source-of-truth** — no backend changes in Area 5; field names of `RouteDefaults` JSON must mirror future TypeBox names (`startTime`/`endTime`/`destination` in camelCase).
8. **Push after each completed MS.** Open PR only at MS9.
9. **`git diff HEAD --stat` after each subagent dispatch** to catch stealth cross-scope edits (lesson `lesson_git_diff_head_before_commit_after_workflows`).
10. **Spoke screenshot evidence** — D-mid parity checks MUST cite pixel evidence from PNG screenshots, never XML alone (lesson `lesson_visual_screenshot_overrides_xml_inference_in_compose_apps`).

## File structure created/modified

### Mobile (`apps/mobile/lib/features/route_config/` — new module)

```
apps/mobile/lib/features/route_config/
├── domain/
│   ├── route_config.dart                  (CREATE, ~150 LOC sealed family)
│   └── route_defaults.dart                (CREATE, ~80 LOC envelope + JSON)
├── data/
│   └── route_defaults_repository.dart     (CREATE, ~60 LOC SharedPreferencesAsync)
├── state/
│   ├── route_config_controller.dart       (CREATE, ~120 LOC @riverpod family)
│   ├── route_defaults_controller.dart     (CREATE, ~80 LOC @riverpod)
│   └── picker_mode.dart                   (CREATE, ~10 LOC enum)
└── presentation/
    ├── pages/
    │   ├── route_details_page.dart        (CREATE, ~250 LOC shell)
    │   ├── destination_picker_page.dart   (CREATE, ~120 LOC)
    │   └── break_picker_page.dart         (CREATE, ~150 LOC)
    └── widgets/
        ├── route_details_section.dart     (CREATE, ~80 LOC)
        ├── route_config_row.dart          (CREATE, ~60 LOC)
        ├── time_picker_sheet.dart         (CREATE, ~200 LOC wheel_picker wrap)
        └── break_chip_groups.dart         (CREATE, ~100 LOC)
```

### Mobile (touch points)

```
apps/mobile/lib/features/routes/presentation/pages/add_stop_page.dart  (MODIFY: +PickerMode? mode param + AppBar branch)
apps/mobile/lib/features/routes/presentation/widgets/route_sheet.dart  (MODIFY: 3 rows → onTap push)
apps/mobile/lib/features/routes/state/route_creation_controller.dart   (MODIFY: FTUE push after complete())
apps/mobile/lib/app_router.dart                                        (MODIFY: +6 GoRoutes)
apps/mobile/pubspec.yaml                                                (MODIFY: +wheel_picker ^0.3.0)
apps/mobile/scripts/area5_route_details_flow.yaml                       (CREATE: Maestro smoke)
```

### Tests (`apps/mobile/test/features/route_config/`)

```
apps/mobile/test/features/route_config/
├── domain/
│   ├── route_config_test.dart                (CREATE)
│   └── route_defaults_test.dart              (CREATE)
├── data/
│   └── route_defaults_repository_test.dart   (CREATE)
├── state/
│   ├── route_config_controller_test.dart     (CREATE)
│   └── route_defaults_controller_test.dart   (CREATE)
└── presentation/
    ├── pages/
    │   ├── route_details_page_test.dart        (CREATE)
    │   ├── destination_picker_page_test.dart   (CREATE)
    │   └── break_picker_page_test.dart         (CREATE)
    └── widgets/
        ├── route_details_section_test.dart     (CREATE)
        ├── route_config_row_test.dart          (CREATE)
        ├── time_picker_sheet_test.dart         (CREATE)
        └── break_chip_groups_test.dart         (CREATE)

apps/mobile/integration_test/area5_route_details_flow_test.dart  (CREATE MS9)
```

### Docs

```
docs/decisions/0040-wheel-picker-time-drum.md  (CREATE MS1)
docs/sessions/2026-06-XX-area5-*.md            (CREATE per-MS as needed)
TODO.md                                         (UPDATE MS9)
```

---

## Phase 0 — Pre-flight (no commits)

### Task 0: Verify environment

**Files:** none (read-only).

- [ ] **Step 0.1:** `git status` — clean, branch = `feat/m2-slice-2-area-5-route-details`, HEAD = `b4d2d0a` or descendant.
- [ ] **Step 0.2:** `flutter --version` ≥ 3.44, `bun --version` ≥ 1.3, `node --version` 20.x.
- [ ] **Step 0.3:** `adb devices` shows `RQCW401G33T device` (Samsung M54).
- [ ] **Step 0.4:** `ls /tmp/spoke-a5-*` returns 21 artefatos (baseline preserved).
- [ ] **Step 0.5:** Read spec one more time (`docs/superpowers/specs/2026-06-02-area5-route-details.md`).

No commit.

---

## Phase 1 — Domain + State (MS1)

**Delivers:** sealed `RouteConfig`, `RouteDefaults` envelope, 2 Riverpod controllers, `PickerMode` enum, full unit + state tests. Zero UI.

### Task MS1: Domain + State foundation

**Files:**
- Create: `apps/mobile/lib/features/route_config/domain/route_config.dart`
- Create: `apps/mobile/lib/features/route_config/domain/route_defaults.dart`
- Create: `apps/mobile/lib/features/route_config/data/route_defaults_repository.dart`
- Create: `apps/mobile/lib/features/route_config/state/route_config_controller.dart`
- Create: `apps/mobile/lib/features/route_config/state/route_defaults_controller.dart`
- Create: `apps/mobile/lib/features/route_config/state/picker_mode.dart`
- Create: `apps/mobile/test/features/route_config/domain/route_config_test.dart`
- Create: `apps/mobile/test/features/route_config/domain/route_defaults_test.dart`
- Create: `apps/mobile/test/features/route_config/data/route_defaults_repository_test.dart`
- Create: `apps/mobile/test/features/route_config/state/route_config_controller_test.dart`
- Create: `apps/mobile/test/features/route_config/state/route_defaults_controller_test.dart`
- Modify: `apps/mobile/pubspec.yaml` (+ `wheel_picker: ^0.3.0`)
- Create: `docs/decisions/0040-wheel-picker-time-drum.md`

**Steps grouped — implementer subagent will TDD each:**

- [ ] **Step MS1.1:** Add `wheel_picker: ^0.3.0` to pubspec, `flutter pub get`.
- [ ] **Step MS1.2:** Write ADR-0040 (decision + alternatives + rationale + Context7 ID).
- [ ] **Step MS1.3:** Create `picker_mode.dart` enum (2 values: `startLocation`, `endLocation`).
- [ ] **Step MS1.4:** TDD `RouteConfig` sealed family — write failing tests for all 5 sub-types + invariants (e.g. `TimeStart.before(TimeEnd)`), then implement.
- [ ] **Step MS1.5:** TDD `RouteDefaults` envelope — schema v1 JSON roundtrip + nullable field handling (NO `copyWith` for nullable — build manually per `lesson_copywith_nullable_field_pitfall`).
- [ ] **Step MS1.6:** TDD `RouteDefaultsRepository` — read with `SharedPreferencesAsync.setMockInitialValues({})` (no envelope → returns `RouteDefaults.empty(firstRoute: true)`); write/read roundtrip; corrupted JSON → returns empty.
- [ ] **Step MS1.7:** TDD `routeConfigControllerProvider` (`@riverpod` family per routeId, autoDispose) — updates startLocation/timeStart/timeEnd/destination/breaks independently; `isValid` derived (endTime > startTime); autoDispose isolation across route IDs.
- [ ] **Step MS1.8:** TDD `routeDefaultsControllerProvider` (`@riverpod`) — emits from repository; `merge(patch)` writes + emits new value; `markFirstRouteComplete()` mutates `firstRoute` flag.
- [ ] **Step MS1.9:** `flutter analyze` clean, `flutter test test/features/route_config/` all passing.
- [ ] **Step MS1.10:** Commit (1 or multiple Conventional Commits — `feat(route-config): add domain RouteConfig sealed family`, `feat(route-config): add RouteDefaults envelope + repository`, `feat(route-config): add Riverpod controllers`, `chore(deps): add wheel_picker ^0.3.0`, `docs(adr-0040): wheel_picker ^0.3.0 adoption`).

**Spec compliance review focuses:** sealed exhaustiveness, JSON envelope field names match Q4 names, autoDispose family pattern, no UI imports leaking into domain.

**Code quality review focuses:** no dead code, no premature abstraction, test coverage of edge cases, follows existing conventions in `apps/mobile/lib/features/routes/`.

---

## Phase 2 — Shell page (MS2)

**Delivers:** `RouteDetailsPage` full-screen with topbar (X + Concluído), 3 sections (Partida/Destino/Pausas), 5 rows with placeholder onTap that prints to console (rows not yet wired to sub-pickers).

### Task MS2: Shell tela "Detalhes da rota"

**Files:**
- Create: `apps/mobile/lib/features/route_config/presentation/pages/route_details_page.dart`
- Create: `apps/mobile/lib/features/route_config/presentation/widgets/route_details_section.dart`
- Create: `apps/mobile/lib/features/route_config/presentation/widgets/route_config_row.dart`
- Modify: `apps/mobile/lib/app_router.dart` (+ `/home/routes/active/details` route)
- Create: 3 paired widget test files
- Capture: `/tmp/spoke-a5-shell.png` already exists; compare against new RotPro screenshot

**Steps:**

- [ ] MS2.1: TDD `RouteConfigRow` — renders label + trailing value + chevron; Semantics identifier set; tap dispatches callback. Use `prototipo/tokens.js` colors.
- [ ] MS2.2: TDD `RouteDetailsSection` — header text + List of rows + footer Checkbox "Salvar como padrão". Tap on checkbox flips state via callback.
- [ ] MS2.3: TDD `RouteDetailsPage` — AppBar with leading IconButton(Lucide.x) + trailing TextButton("Concluído", disabled when !isValid); body = 3 sections.
- [ ] MS2.4: Add GoRoute `/home/routes/active/details` to `app_router.dart`.
- [ ] MS2.5: Hot restart + manual nav (temp button somewhere) → tela renderiza.
- [ ] MS2.6: D-mid screenshot — `adb shell screencap` RotPro screen; compare side-by-side with `/tmp/spoke-a5-shell.png` (NOT XML — pixel evidence per `lesson_visual_screenshot_overrides_xml_inference_in_compose_apps`).
- [ ] MS2.7: Commit + `git diff HEAD --stat` verify no stealth changes.

---

## Phase 3 — Partida picker (MS3)

**Delivers:** `PickerMode` plumbing wired to `AddStopPage`; Partida row → push `AddStopPage(mode: startLocation)` → on selection callback updates `routeConfigController`.

### Task MS3: Reuse AddStopPage com PickerMode

**Files:**
- Modify: `apps/mobile/lib/features/routes/presentation/pages/add_stop_page.dart` (+ `PickerMode? mode` constructor + AppBar title branch + return value branch)
- Modify: `apps/mobile/lib/features/route_config/presentation/pages/route_details_page.dart` (wire Partida row onTap)
- Modify: `apps/mobile/lib/app_router.dart` (+ `/home/routes/active/details/start-location` route)
- Create: paired widget test for new `AddStopPage` branches
- Verify: existing Area 4 widget tests still PASS (regression check)

**Steps:**

- [ ] MS3.1: TDD: new test ensures `AddStopPage(mode: PickerMode.startLocation)` shows AppBar title "Local de início" and action button label "Selecionar" instead of "Adicionar parada".
- [ ] MS3.2: Add `mode` param + branches in `AddStopPage`. Default `null` = existing behavior.
- [ ] MS3.3: Run ALL Area 4 tests — must still PASS (regression gate).
- [ ] MS3.4: Wire Partida row in `route_details_page.dart` → `context.push('/home/routes/active/details/start-location')` and await result.
- [ ] MS3.5: Add GoRoute.
- [ ] MS3.6: D-mid Maestro tap → AppBar verify "Local de início" + back gesture → returns to Detalhes da rota.
- [ ] MS3.7: Commit.

---

## Phase 4 — Time pickers (MS4)

**Delivers:** `TimePickerSheet` widget using `wheel_picker ^0.3.0` with HH:MM drum + chips :00/:30; wired to Início + Término rows.

### Task MS4: TimePickerSheet (wheel_picker)

**Files:**
- Create: `apps/mobile/lib/features/route_config/presentation/widgets/time_picker_sheet.dart`
- Modify: `apps/mobile/lib/features/route_config/presentation/pages/route_details_page.dart` (wire Início + Término rows)
- Modify: `apps/mobile/lib/app_router.dart` (+ 2 modal routes OR use showModalBottomSheet)
- Create: paired widget tests

**Steps:**

- [ ] MS4.1: TDD: `TimePickerSheet` widget renders 2 wheels (hours 0-23 + minutes 0-59) + chips ":00", ":30", "Personalizar". Sheet pop returns `TimeOfDay`.
- [ ] MS4.2: Implement using `wheel_picker` `WheelPicker` × 2 side-by-side + `Wrap` of `ChoiceChip`.
- [ ] MS4.3: Wire Início + Término rows.
- [ ] MS4.4: D-mid screenshot drum feel side-by-side with `/tmp/spoke-a5-iniciar-time.png` — pixel comparison wheel design.
- [ ] MS4.5: `flutter-perf-auditor` dispatch — check no jank in scroll wheel.
- [ ] MS4.6: Commit.

---

## Phase 5 — Destino sub-tela (MS5)

**Delivers:** `DestinationPickerPage` with 3 RadioListTile (Voltar / Selecionar endereço / Ida e volta); option "Selecionar endereço" reuses `AddStopPage(mode: endLocation)` on tap.

### Task MS5: DestinationPickerPage

**Files:**
- Create: `apps/mobile/lib/features/route_config/presentation/pages/destination_picker_page.dart`
- Modify: `apps/mobile/lib/features/routes/presentation/pages/add_stop_page.dart` (extend PickerMode.endLocation branch)
- Modify: `apps/mobile/lib/features/route_config/presentation/pages/route_details_page.dart` (wire Destino row)
- Modify: `apps/mobile/lib/app_router.dart` (+ 2 routes: destination + destination/select-address)
- Create: paired widget tests

**Steps:**

- [ ] MS5.1: TDD: `DestinationPickerPage` renders 3 RadioListTile + AppBar (X + Confirmar) + Material 3 `RadioGroup<DestinationType>` ancestor.
- [ ] MS5.2: Implement strings 1:1 paridade Spoke per `/tmp/spoke-a5-destino.xml`.
- [ ] MS5.3: Wire option B (Selecionar endereço) → push `AddStopPage(mode: endLocation)`.
- [ ] MS5.4: Wire Destino row in `route_details_page.dart`.
- [ ] MS5.5: Add routes.
- [ ] MS5.6: D-mid screenshot strings side-by-side with `/tmp/spoke-a5-destino.png` + radio order.
- [ ] MS5.7: Commit.

---

## Phase 6 — Pausa sub-tela (MS6)

**Delivers:** `BreakPickerPage` with 2 ChoiceChip Wraps (horário: 11/12/13 + Personalizar; duração: 15/30/60min + Personalizar); Confirmar appends `BreakConfig` to `RouteConfig.breaks`.

### Task MS6: BreakPickerPage

**Files:**
- Create: `apps/mobile/lib/features/route_config/presentation/pages/break_picker_page.dart`
- Create: `apps/mobile/lib/features/route_config/presentation/widgets/break_chip_groups.dart`
- Modify: `apps/mobile/lib/features/route_config/presentation/pages/route_details_page.dart` (wire + Adicionar pausa CTA + render list of existing breaks)
- Modify: `apps/mobile/lib/app_router.dart` (+ `/break/:breakIndex?` route)
- Create: paired widget tests

**Steps:**

- [ ] MS6.1: BEFORE implementation — re-dispatch `spoke-parity-checker` on Spoke "Adicionar pausa" to capture FULL chips list (não vi 11/12/13, só 08:00 + 15:00 na primeira inspeção). New capture → `/tmp/spoke-a5-pause-full.xml + .png`.
- [ ] MS6.2: TDD: `BreakChipGroups` widget with 2 `Wrap` of `ChoiceChip<int>` (horário in seconds since midnight + duração in minutes). "Personalizar" chip dispatches Personalizar callback.
- [ ] MS6.3: TDD: `BreakPickerPage` — AppBar (X + Confirmar) + 2 sections + nullable `breakIndex` constructor (edit mode).
- [ ] MS6.4: Wire Adicionar pausa CTA in `route_details_page.dart`.
- [ ] MS6.5: Render existing breaks as rows above CTA (Pausa N • HH:MM • Xmin).
- [ ] MS6.6: D-mid screenshot chips side-by-side with `/tmp/spoke-a5-pause-full.png`.
- [ ] MS6.7: Commit.

---

## Phase 7 — Area 3 wire (MS7)

**Delivers:** 3 rows of "Configuração de rota" in Area 3 sheet become tappable → push `/home/routes/active/details`. Rows display current config values (não placeholder).

### Task MS7: Wire Area 3 sheet rows

**Files:**
- Modify: `apps/mobile/lib/features/routes/presentation/widgets/route_sheet.dart` (3 rows: onTap + computed display value)
- Modify: maybe also `apps/mobile/lib/features/routes/state/active_route_controller.dart` (expose `RouteConfig` for display)
- Create: paired widget tests verifying onTap dispatches correct push

**Steps:**

- [ ] MS7.1: TDD: tap on each of 3 rows pushes `/home/routes/active/details`.
- [ ] MS7.2: TDD: row trailing text reflects current `RouteConfig` (e.g. "08:00" for Início row).
- [ ] MS7.3: Implement (minimal touch — Karpathy 3 surgical).
- [ ] MS7.4: Regression: ALL Area 3 widget tests still PASS.
- [ ] MS7.5: D-mid manual M54 — tap → opens Detalhes → back → returns to Area 3 sheet at correct snap point (mid).
- [ ] MS7.6: Commit.

---

## Phase 8 — Persistência + FTUE (MS8)

**Delivers:** "Concluído" save persists via `RouteDefaultsRepository`; wizard "Criar rota" complete checks `firstRoute` flag and pushes Detalhes if true; mark flag false on first save.

### Task MS8: SharedPreferencesAsync + FTUE

**Files:**
- Modify: `apps/mobile/lib/features/route_config/presentation/pages/route_details_page.dart` (Concluído onPressed → save flow)
- Modify: `apps/mobile/lib/features/routes/state/route_creation_controller.dart` (FTUE branch)
- Modify: maybe `app_router.dart` (redirect after wizard complete)
- Create/Modify: widget tests covering save flow + FTUE behavior
- Create: `apps/mobile/integration_test/area5_route_details_flow_test.dart` (initial structure; expanded MS9)

**Steps:**

- [ ] MS8.1: TDD: Concluído tap → calls `routeDefaultsControllerProvider.notifier.merge()` with patch built from per-section "Salvar" checkbox state.
- [ ] MS8.2: TDD: FTUE — when `routeDefaultsControllerProvider.firstRoute == true` and wizard completes, push `/home/routes/active/details`.
- [ ] MS8.3: TDD: After first save, `firstRoute` flag flips false (no re-trigger).
- [ ] MS8.4: Implement save flow + FTUE wire.
- [ ] MS8.5: Manual M54: install fresh APK, create 1st route → Detalhes opens automatic → Concluído → 2nd route created via wizard → wizard pula Detalhes.
- [ ] MS8.6: Commit.

---

## Phase 9 — D4 closing + PR (MS9)

**Delivers:** D4 closing `spoke-parity-checker` dispatch + integration_test covering nav stack + Maestro YAML smoke + PR opened with full body.

### Task MS9: Closing parity + PR

**Files:**
- Expand: `apps/mobile/integration_test/area5_route_details_flow_test.dart`
- Create: `apps/mobile/scripts/area5_route_details_flow.yaml`
- Modify: `TODO.md` (Area 5 ✅, tech debt entries)
- Modify: `docs/sessions/0001-INDEX.md` (+ Area 5 session log)
- Create: `docs/sessions/2026-06-XX-area5-route-details.md`
- Open: PR via `gh pr create`

**Steps:**

- [ ] MS9.1: D4 `spoke-parity-checker` full dispatch — compare ALL 6 screen states (shell + partida + time + destino + pausa + back-orchestration) with screenshot pixel evidence per the discipline rule.
- [ ] MS9.2: Address parity report (must-fix only; should-fix gets ADR or tech debt).
- [ ] MS9.3: Expand integration_test covering 14-step golden path from spec §Goals.
- [ ] MS9.4: Author Maestro YAML smoke `area5_route_details_flow.yaml` using `${MAESTRO_EMAIL}` env vars (lesson `lesson_maestro_yaml_env_vars_not_embedded_credentials`).
- [ ] MS9.5: Run `flutter analyze`, `flutter test`, `bun run typecheck`, `/verify-slice`.
- [ ] MS9.6: Build release APK + manual install M54 + run 14-step golden path + screenshots.
- [ ] MS9.7: Update TODO + INDEX + session log.
- [ ] MS9.8: `git push -u origin feat/m2-slice-2-area-5-route-details`.
- [ ] MS9.9: `gh pr create` with body following `M2-SLICE-CHECKLIST.md` template.

---

## Self-review

**Spec coverage:**
- §Decisions Q1 (FTUE) → MS8
- §Decisions Q2 (Area 3 rows) → MS7
- §Decisions Q3 (wheel_picker) → MS1 + MS4
- §Decisions Q4 (SharedPrefs envelope) → MS1 + MS8
- §Decisions Q5 (wire agora) → MS7
- §Decisions Q6 (reuse AddStopPage) → MS3 + MS5
- §Decisions Q7-Q8 (chips + checkbox) → MS6 + MS2
- §Decisions Q9 (GoRouter back default) → covered by integration_test MS9
- §Decisions Q10 (endTime>startTime validation) → MS1 controller + MS2 button disabled state
- §Goals 14-step path → MS9 integration_test + manual run
- §Architecture file tree → covered MS1-MS8
- §Risks → mitigations embedded in MS1 (sealed/autoDispose/no copyWith for nullable), MS2 (Semantics), MS4 (perf-auditor), MS6 (re-dispatch parity), MS8 (FTUE flag), MS9 (integration_test)
- §Accessibility → Semantics identifiers MS2 onwards; M3 Radio/Chip tap targets default ≥48dp
- §Verification gates → MS9 closing tasks

**Placeholder scan:** none. Some MS bodies are bullet-level instead of step-level — that's intentional for MS2-MS9 since the implementer subagent receives full spec context including this plan + spec; they TDD inside each MS without needing me to write the test code verbatim. MS1 has detailed sub-tasks because it's the foundation.

**Type consistency:** `RouteConfig`, `RouteDefaults`, `PickerMode`, `routeConfigControllerProvider`, `routeDefaultsControllerProvider`, `RouteDetailsPage`, `DestinationPickerPage`, `BreakPickerPage` names consistent across all MSs and tests.

**Scope check:** single area (Area 5 of Slice 2), single PR, single branch.

The plan is ready.

---

## Execution Handoff

Plan complete. Using `superpowers:subagent-driven-development`:

- One implementer subagent per MS.
- After each MS: spec-reviewer dispatch first, then code-quality-reviewer.
- Loop until both ✅.
- Mark TodoWrite item completed.
- Move to next MS.
- After MS9: open PR.

Approved by Eduardo 2026-06-02.
