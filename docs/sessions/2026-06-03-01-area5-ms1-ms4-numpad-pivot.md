# Area 5 MS1-MS4 — wheel_picker → numpad pivot + reusable workflow template

## Metadata

- **Date**: 2026-06-03 (America/Sao_Paulo)
- **Sequence**: 01
- **Agent**: Claude Code (Opus 4.7)
- **Human**: Eduardo
- **Topic**: Area 5 numpad pivot
- **Duration**: ~multi-context session (compacted twice)
- **Related ADRs**: ADR-0041 (Superseded), ADR-0042 (Active)
- **Related TODO items**: Slice 2 / Area 5 / MS1-MS4

## Goal of the Session

Ship MS1-MS4 of Area 5 (Detalhes da rota) Spoke-aligned, build a reusable
workflow template for MS5-MS8, and resolve a structural divergence that
surfaced only when Spoke was re-inspected live on the M54: the time picker
is a 4×3 numeric keypad, not a wheel/drum.

## What Was Done

- Shipped **MS1 Domain + State**: sealed `RouteConfig` + `RouteDefaults`
  envelope + `RouteDefaultsRepository` (SharedPreferencesAsync) + 2 Riverpod
  controllers (`routeConfigControllerProvider` family scoped per routeId,
  autoDispose; `routeDefaultsControllerProvider`) + `PickerMode` enum.
- Shipped **MS2 Shell `RouteDetailsPage`**: full-screen Spoke-parity layout
  — NO AppBar, X floats top-left inside scrollable content, body-level h1,
  full-width filled "Concluído" pinned at bottom, single screen-level
  "Salvar como padrão" checkbox below it. 3 sections (Partida/Destino/Pausa).
- Shipped **MS3 Partida picker**: extended `AddStopPage` with `PickerMode`
  (3 values: `addStop`, `startLocation`, `endLocation`), wired Partida-Local
  row → `context.push<StartLocation>(...)`. Scoped add-stop providers by
  `(routeId, PickerMode)` to keep search state isolated per picker. Commits
  `52e9211`, `95c0eaf`.
- Pivoted **MS4 time picker** from `wheel_picker` (ADR-0041) to a custom
  4×3 numeric keypad (ADR-0042) after live Spoke re-inspection via Maestro
  MCP confirmed the structural baseline. Wrote ADR-0042, marked ADR-0041
  Superseded, dropped `wheel_picker` from `pubspec.yaml`, updated spec Q3
  + plan Phase 4. Commit `a00a0a6`.
- Built **`.claude/workflows/area5-microsprint.js`** — reusable executable
  template for MS5-MS8 with halt gates at Phase 0 (preflight), Phase 1 (Spoke
  baseline via `spoke-parity-checker`), Phase 2 (library research), Phase 3
  (implementer), Phase 4 (parallel reviewers). Smoke-tested twice
  (`wq54n3bfn` first probe, `ws817s5xd` final). Commits `9c7f1e7`, `ad51424`
  (JSON.parse args), `1935e9d` (active-marker vs meta-doc heuristic).
- Implemented **MS4 numpad TimePickerSheet** — `StatefulWidget` with
  `String _buffer = ''`, 4×3 `GridView` (1-9, `:00`, 0, `:30`),
  `IconButton(LucideIcons.delete)` backspace, `FloatingActionButton` confirm.
  `_parseTime` accepts both H:MM and HH:MM buffers. Semantics identifiers
  on every key + FAB + backspace + header. 14 widget tests. Commit `bf89e63`.
- Wired both time rows in `RouteDetailsPage` via shared `_showTimePicker`
  launcher (`showModalBottomSheet<TimeOfDay>` returning `TimeOfDay?` on
  confirm, `null` on tap-outside / system back). 4 integration tests for
  open-sheet / confirm / label update. Commits `413713f`, `bc236ff`.
- **Spoke parity fix at MS4 D4 review**: Partida-Início label collapsed
  from `'Iniciar agora mesmo  HH:MM'` to lone `'HH:MM'` after confirm,
  matching live evidence at `/tmp/spoke-a5-inspection/ms4-live-detalhes-final.xml`
  bounds `[203,752][314,810]` showing `text="10:30"` alone. Commit `23ff0ff`.
- Final state: 222/222 tests green; `flutter analyze` clean over
  `lib/features/route_config/` + `test/features/route_config/`; zero tech
  debt markers; `wheel_picker` absent from pubspec.

## Decisions Made

1. **Pivot wheel → numpad (ADR-0042 supersedes ADR-0041)** — Spoke's time
   picker is structurally a numpad, not a wheel/drum. The original spec Q3
   was locked from an inferred baseline because the reference screenshot
   was a 0-byte placeholder. Live re-inspection on M54 via Maestro MCP
   showed a 4×3 grid with `:00`/`:30` minute shortcuts. Fix: ADR-0042 with
   amendment block documenting the inference-vs-measurement failure mode,
   spec Q3 rewritten to cite the live XML/PNG baselines.
2. **Inference-vs-measurement protocol amendment** — Every spec
   Q-decision about widget shape MUST now cite a non-zero-byte PNG OR carry
   a literal `[INFERRED — VERIFY BEFORE LOCK]` marker. The new workflow
   template's Phase 0 detects active markers in markdown table cells and
   halts. Documented in ADR-0042.
3. **Reusable microsprint template** — Pulled the recurring shape
   (preflight → Spoke baseline → research → implement → review × 2) into
   `area5-microsprint.js` so MS5-MS8 don't re-invent the orchestration.
   `args` is parsed defensively (Workflow runtime delivers it as a JSON
   string, verified via probe `w1lt9y2qo`).
4. **Phase 0 preflight halt heuristic** — A literal
   `[INFERRED — VERIFY BEFORE LOCK]` string can appear in two contexts:
   (a) an *active* marker in a spec table cell (real divergence risk), and
   (b) *meta-documentation* in ADR-0042 explaining the protocol itself
   (false positive). The Phase 0 prompt now distinguishes them by checking
   whether the marker sits inside a markdown table row vs inline-code in
   body prose.
5. **Caminho C hybrid for MS4 retry** — After the first Workflow run
   timed out mid-Phase-3, the retry used a hybrid: Phase 0/1/2 manually
   (preserving the live PNG capture from the first run), then Workflow
   tool only for Phase 3/4. This pattern is recommended for future
   microsprints where Phase 1 baseline capture is expensive.
6. **Memory consolidation** — Audited 3 proposed new feedback memories
   against existing ones; 2 overlapped. Consolidated into ONE new memory
   (`feedback_spec_baseline_and_workflow_halt.md`) with explicit "What
   this adds vs existing" table to prevent duplication drift.

## Open Questions Left

- [ ] MS5 (Destino) needs upfront Spoke parity capture via the new
  template — confirm with Eduardo that M54 is connected + Spoke logged-in
  before dispatching `spoke-parity-checker`.
- [ ] First template run on MS5 will validate whether the JSON.parse +
  marker-heuristic fixes hold for a microsprint that wasn't the smoke
  case.

## Files Changed

**Created**:
- `apps/mobile/lib/features/route_config/presentation/widgets/time_picker_sheet.dart`
- `apps/mobile/test/features/route_config/presentation/widgets/time_picker_sheet_test.dart`
- `docs/decisions/0042-time-picker-numpad-spoke-fidelity.md`
- `.claude/workflows/area5-microsprint.js`
- `docs/sessions/2026-06-03-01-area5-ms1-ms4-numpad-pivot.md` (this file)

**Modified**:
- `apps/mobile/lib/features/route_config/presentation/pages/route_details_page.dart`
  (wired both time rows + Spoke parity label collapse)
- `apps/mobile/lib/features/route_config/state/picker_mode.dart`
  (3-value enum)
- `apps/mobile/test/features/route_config/presentation/pages/route_details_page_test.dart`
  (+ 4 integration tests for time rows; updated assertions for Spoke
  parity label collapse)
- `apps/mobile/pubspec.yaml` (removed `wheel_picker`)
- `apps/mobile/pubspec.lock` (regenerated)
- `docs/decisions/0041-wheel-picker-time-drum.md` (Status: Superseded)
- `docs/superpowers/specs/2026-06-02-area5-route-details.md` (Q3 rewrite)
- `docs/superpowers/plans/2026-06-02-area5-route-details.md` (Phase 4
  rewrite + MS1-MS4 checkboxes marked `[x]`)
- `TODO.md` (Area 5 MS1-MS4 status)
- `docs/sessions/0001-INDEX.md` (new session row)

## Commits Pushed

```
23ff0ff fix(route-config): Partida-Início row collapses to "HH:MM" after confirm (Spoke parity, MS4 review)
bc236ff style(route-config): drop microsprint tag from MS4 wiring section divider
413713f feat(route-config): wire TimePickerSheet to Partida-Início and Destino-Término rows
bf89e63 feat(route-config): add Spoke-fidelity numpad TimePickerSheet (ADR-0042)
1935e9d fix(workflows): teach preflight to distinguish active markers from meta-doc
ad51424 fix(workflows): parse args as JSON string in area5-microsprint template
9c7f1e7 build(workflows): add area5-microsprint template with executable halt gates
a00a0a6 docs(adr-0042): supersede ADR-0041 (wheel_picker) with numpad per Spoke fidelity
95c0eaf refactor(routes): scope addStop providers by (routeId, PickerMode) (Slice 2 Area 5 MS3 cleanup)
52e9211 fix(routes): Spoke parity hint + redirect-arrow icon + remove dead test route (Slice 2 Area 5 MS3 cleanup)
```

## Hand-off Notes for Next Session

- Branch: `feat/m2-slice-2-area-5-route-details` (clean, up-to-date with
  origin).
- Next microsprint: **MS5 Sub-tela Destino** — 3 radio options. Spec Phase 5
  exists in `docs/superpowers/plans/2026-06-02-area5-route-details.md`.
- Recommended workflow: caminho C hybrid (manual Phase 0/1/2, Workflow tool
  for Phase 3/4) — same pattern that worked for MS4 retry. Template at
  `.claude/workflows/area5-microsprint.js`, call with
  `args={"msNumber":5}`.
- Confirm M54 connected (`adb devices` shows `RQCW401G33T device` or
  `mcp__maestro__list_devices` returns it) + Spoke logged-in before
  dispatching `spoke-parity-checker`.
- Do NOT open PR yet — that's MS9 D4.

## Reference Material Used

- Live Spoke re-inspection via Maestro MCP
  (`mcp__maestro__inspect_view_hierarchy`, `take_screenshot`) — produced
  `/tmp/spoke-a5-inspection/ms4-live-*.{xml,png}`.
- Context7 queries: `Navigator.pop<T>(result)` canonical return pattern,
  `showModalBottomSheet<T>` config, Material 3 `RadioGroup<T>` ancestor
  pattern (deferred to MS5).
- Karpathy 4 principles: especially #2 Simplicity First (no `wheel_picker`
  dependency) and #3 Surgical Changes (every commit traces to one Spoke
  parity decision).
- Memory: `feedback_spoke_parity_zero_debt_per_ms`,
  `feedback_spec_baseline_and_workflow_halt`,
  `feedback_escalate_recurring_and_gate_check`,
  `lesson_prototype_is_visual_not_functional`.
