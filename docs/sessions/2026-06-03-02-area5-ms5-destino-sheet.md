# Area 5 MS5 — Destino bottom-sheet sub-picker + 3-state domain (ADR-0043)

## Metadata

- **Date**: 2026-06-03 (America/Sao_Paulo)
- **Sequence**: 02
- **Agent**: Claude Code (Opus 4.8)
- **Human**: Eduardo
- **Topic**: Area 5 MS5 Destino sub-picker
- **Related ADRs**: ADR-0043 (filed this session), ADR-0042 (same failure mode), ADR-0035/0036/0037
- **Related TODO items**: Slice 2 / Area 5 / MS5
- **Commits**: `83572e4` (docs/ADR-0043), `5dea345` (MS5 implementation)

## Goal of the Session

Ship MS5 of Area 5 — the Destino sub-picker — Spoke-aligned, using the
caminho-C hybrid (manual Phase 0/1/2, Workflow tool for Phase 3/4).

## What Was Done

- **Caught a recurring spec-baseline failure mode at Phase 1.** The spec's MS5
  design (full-screen page + 3 `RadioListTile` + AppBar X/Confirmar) was drawn
  from a **mislabeled baseline**: `/tmp/spoke-a5-destino.png` is actually the
  time-picker numpad, not the Destino screen. This is the SAME inference-vs-
  measurement failure that produced ADR-0042 (wheel_picker), recurring on the
  very next sub-picker. Live re-inspection on M54 via Maestro MCP captured the
  real widget.
- **Live Spoke truth:** the Destino picker is a `design_bottom_sheet` (bottom
  ~44%), header "Destino" + blue "Concluído" text button, `Divider`, then 3
  tappable CardViews (icon + title + subtitle), dismissed via tap-outside/Back.
  3 options: "Voltar ao ponto de partida"/"Ida e volta (recomendado)",
  "Destino em outro endereço"/"Digite qualquer endereço" (→ full-screen address
  search), "Não usar destino"/"Não recomendado para transportadoras". Icons:
  cornerUpLeft / mapPin / x (confirmed from screenshot pixels). Corroborated by
  a 2nd independent stale capture `/tmp/spoke-a5-idaevolta.xml` (2026-06-02).
- **Escalated the domain reconciliation to Eduardo** (a genuine product-
  semantics decision with persistence ripple, not a follow-Spoke call). The MS1
  domain had `BackToStart` + `RoundTrip` as separate types (Spoke folds them
  into ONE "Voltar ao ponto de partida" option) and lacked "Não usar destino".
  Eduardo chose: **align domain to Spoke's 3 states** — keep `RoundTrip` +
  `SpecificAddress`, remove `BackToStart`, add `NoDestination`.
- **Filed ADR-0043** documenting the widget shape + domain change, chaining
  explicitly to ADR-0042's failure mode. Revised spec (Q11 added, Q6 amended,
  §Goals 5/12, MS5 row, file tree) and plan Phase 5. Committed `83572e4` BEFORE
  any code, so the workflow's Phase 0 preflight would see a locked, corrected
  spec.
- **Dispatched the area5-microsprint Workflow** (`w29si5x7y`, args msNumber=5).
  It passed Phase 0/1/2 (zero architectural surprises — confirming the spec
  revision landed) and implemented ~90% in Phase 3, then **HALTED with
  BLOCKED_OTHER** — correctly. The implementer found my `filesToTouch`
  allowlist was internally inconsistent: it required the card-2 end-location
  navigation but omitted `app.dart` (the sole route-registration site), and
  the hard scope gate forbade editing it. Rather than silently edit out-of-
  scope OR ship a crash path, it escalated. Exemplary halt-gate behavior.
- **Resolved my scope error manually** (cheaper than re-running the whole
  workflow + preserves 90% verified work): added `app.dart` to scope (the
  GoRoute was already correct in the working tree), de-stubbed
  `add_stop_page.dart`'s `endLocation` arm (was `throw UnsupportedError`) with
  `_popWithEndLocation` mirroring `_popWithStartLocation` to pop a
  `SpecificAddress`, and added a paired behavioral test.
- **Ran Phase 4 reviewers manually** (2 parallel: spec-parity + code-quality).
  Both came back with ZERO must-fix. Two shouldFix items, both addressed:
  (1) stale doc comment on `picker_mode.dart` endLocation ("not wired yet" +
  references nonexistent `DestinationPickerPage`/"Selecionar endereço") — fixed;
  (2) card-2 two-hop nav had no end-to-end test — added 2 widget tests (apply +
  backout) with an in-test router registering the `end-location` route.
- **Final state:** 240 tests pass (+18 net), `flutter analyze` clean in MS5
  scope, zero tech debt markers, `BackToStart` fully removed from lib. Commit
  `5dea345` (14 files). Pushed.

## Decisions Made

1. **Domain aligned to Spoke's 3 states (ADR-0043)** — `RoundTrip` /
   `SpecificAddress` / `NoDestination`; `BackToStart` removed. Spoke does not
   distinguish loop-back from round-trip; carrying a UI-less `BackToStart` type
   into Slice 3's backend schema was rejected. No migration needed (Area 5
   unshipped; stale `'backToStart'` tag degrades to `empty()`).
2. **Bottom sheet, not page (ADR-0043)** — mirrors the MS4 `_showTimePicker`
   launcher. No GoRoute for the sheet (it's a modal). Card 2 needs a route
   (`end-location`) because it pushes a full-screen search.
3. **Card-2 returns-intent pattern** — the sheet pops `AddressSearchRequested`
   and the PARENT pushes `AddStopPage(mode: endLocation)`, avoiding the Flutter
   #155746 silent no-op on nested branch routes (memory
   `lesson_showmodalbottomsheet_returns_intent_pattern`).
4. **Manual fix over workflow re-run** — when the workflow halted on my scoping
   error with 90% done + 237 tests green in the working tree, finishing the one
   missing piece (de-stub) by hand was cheaper than discarding + re-running
   (~535k tokens). The halt was MY brief's fault, not a design problem.

## Open Questions Left

- [ ] MS9 must add an `integration_test/` covering the card-2 on-device golden
  path (Destino row → card 2 → address search → back-to-details with address
  applied). Widget tests cover it now, but the branch-route push is exactly
  what Flutter #155746 makes fragile on real GoRouter branch stacks (memory
  `lesson_slice_checklist_integration_test_gate`). There is still NO
  `integration_test/` dir in the repo.
- [ ] The parent Detalhes "Destino" row's `RoundTrip` icon is `LucideIcons.repeat`
  while the sheet card 1 uses `cornerUpLeft`. Both are pinned by tests as
  intentional, but worth a glance at MS9 D4 against the live parent-row icon.

## Process Lesson (for future MS dispatches)

When building the Workflow `filesToTouch` allowlist, trace EVERY navigation the
feature requires to its registration site. A card/button that pushes a route
implies the router file is in scope. My omission of `app.dart` forced a
mid-implementation halt. The fix is mechanical (add the route-registration site
when any new push is in scope), but the halt cost ~42 min + ~535k tokens. The
halt gate worked — it just fired on a preventable input error.

## Files Changed

**Created**:
- `apps/mobile/lib/features/route_config/presentation/widgets/destination_picker_sheet.dart`
- `apps/mobile/test/features/route_config/presentation/widgets/destination_picker_sheet_test.dart`
- `docs/decisions/0043-destination-picker-sheet-three-state-domain.md`
- `docs/sessions/2026-06-03-02-area5-ms5-destino-sheet.md` (this file)

**Modified**:
- `apps/mobile/lib/app.dart` (+ end-location GoRoute)
- `apps/mobile/lib/features/route_config/domain/route_config.dart` (BackToStart→NoDestination)
- `apps/mobile/lib/features/route_config/domain/route_defaults.dart` (JSON tags)
- `apps/mobile/lib/features/route_config/presentation/pages/route_details_page.dart` (wire + switch arms + launcher)
- `apps/mobile/lib/features/route_config/state/picker_mode.dart` (doc comment fix)
- `apps/mobile/lib/features/routes/presentation/pages/add_stop_page.dart` (de-stub endLocation)
- 5 route_config test files + add_stop_page_test.dart (BackToStart→NoDestination churn + new nav/pop tests)
- `docs/superpowers/specs/2026-06-02-area5-route-details.md` (Q11 + Goals + MS5 + tree)
- `docs/superpowers/plans/2026-06-02-area5-route-details.md` (Phase 5 rewrite)
- `TODO.md` (MS5 status)

## Commits Pushed

```
5dea345 feat(route-config): Destino bottom-sheet sub-picker + 3-state domain (MS5, ADR-0043)
83572e4 docs(adr-0043): Destino picker = bottom sheet + 3-state domain (Spoke re-inspection)
```

## Hand-off Notes for Next Session

- Branch `feat/m2-slice-2-area-5-route-details` clean + pushed (HEAD `5dea345`).
- Next: **MS6 Sub-tela Pausa** (2 ChoiceChip Wraps: horário 11/12/13 + duração
  15/30/60min + Personalizar). Spec risk noted: only 08:00+15:00 horários were
  seen in the original inspection — MS6.1 re-dispatches spoke-parity-checker for
  the FULL chips list before implementing. Use caminho-C hybrid + the
  `area5-microsprint.js` template (args msNumber=6) — but this time include the
  router file in `filesToTouch` if any chip's "Personalizar" pushes a route.
- Do NOT open PR — that's MS9 D4.

## Reference Material Used

- Live Spoke re-inspection via Maestro MCP — `/tmp/spoke-a5-inspection/ms5-live-*`.
- Context7 `/websites/api_flutter_dev` — `showModalBottomSheet<T>` result/pop pattern.
- Two parallel code-reviewer subagents (spec-parity + code-quality).
- Memory: `feedback_spoke_parity_zero_debt_per_ms`,
  `feedback_spec_baseline_and_workflow_halt`,
  `feedback_escalate_recurring_and_gate_check`,
  `lesson_showmodalbottomsheet_returns_intent_pattern`,
  `lesson_slice_checklist_integration_test_gate`,
  `lesson_copywith_nullable_field_pitfall`,
  `lesson_git_diff_head_before_commit_after_workflows`,
  `lesson_visual_screenshot_overrides_xml_inference_in_compose_apps`.
