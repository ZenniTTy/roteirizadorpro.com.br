# MS-FIX — Área 5 audit remediation (all 14 punch-list items)

> **Date:** 2026-06-03 · **Branch:** `feat/m2-slice-2-area-5-route-details` (HEAD `8024e1e`)
> **Source:** `docs/audits/2026-06-03-area5-ms1-ms5-retro-audit.md` (1 must + 5 should + 8 nits)
> **Live Spoke evidence:** `/tmp/spoke-a5-msfix/EVIDENCE.md` + `timepicker-{inicio,termino}-header.png` (fresh re-inspection 2026-06-03 per directive)
> **Goal:** remediate every confirmed finding in one microsprint, breaking-change-aware, TDD where behavior changes, zero new debt.

## Breaking-change guardrails (read first)

This MS touches already-green code + tests. Each item that changes behavior MUST:
1. Update the test that pins the OLD behavior in the SAME edit (red→green is "change the assertion to the Spoke-correct value, watch it pass").
2. Keep public API intact unless the audit explicitly says to decouple (only S2 — and there we KEEP the provider, only stop the UI from consuming it).
3. Run the full suite after each item group, not just at the end, to localize any regression.

The two highest-risk items:
- **S2** — do NOT delete `isRouteConfigValidProvider` / `RouteConfig.isValid`. Slice 3 solver needs them. Only stop `RouteDetailsPage` from `ref.watch`-ing it for the button's `enabled`. The provider + domain method stay, with their existing tests (which test the DOMAIN, not the button) untouched.
- **S1** — new lifecycle (Timer). Encapsulate in a dedicated `_LiveClockLabel` StatefulWidget with `dispose()` cancelling the timer + an injectable clock for deterministic tests. No raw Timer in the page state.

## Items (grouped by file-blast-radius, smallest first)

### Group A — pure doc (no code, no tests) — S5 + N nits
- **S5a** `app_router.dart` → `app.dart` across spec (L105 + refs) and plan (7 refs).
- **S5b** spec Goal #10 (L55) + Risks (L180): rewrite "scroll wheel" → 4×3 numpad (ADR-0042); drop "flick velocity test".
- **N5** `route_details_page.dart:284-305` + test `:233-428`: drop the unsourced "divergence #N" numbering OR add a divergence table to ADR-0043 §Decision 3. → **Choose: add the table to ADR-0043** (keeps the code comments meaningful + documents the parent-row icons RoundTrip=cornerUpLeft? NO — parent row uses `repeat`/`cornerDownLeft`/`mapPin`/`flag`; pin the ACTUAL icons). Then rewrite the code comments to reference "ADR-0043 §Decision 3 row N" instead of bare "#N".
- **N8** spec Q8 says checkbox default `true`; code ships `false`. Add a one-line note to ADR-0043 (or a new short ADR amendment) documenting the deliberate flip + the evidence (unchecked matches verifiable returning-user Spoke). → **Choose: amend ADR-0043** with a "Salvar como padrão default" note.

### Group B — comment-only code (no behavior, no test change)
- **S3-comment** `picker_mode.dart:7-12`: delete the false "uses a distinct search-field placeholder" sentence.
- **N4** `add_stop_page.dart:166-169`: fix `_popWithStartLocation` docstring — it claims a textual-fields fallback the code does NOT do (it throws + SnackBars). Rewrite to the hard-failure contract.
- **N2** `route_defaults.dart:64-66`: the broad `catch (_)` → `empty()` logs nothing. Add `debugPrint` of the offending error before degrading (mirror `route_defaults_repository.dart:37`). This is a 1-line behavior-adjacent change; existing roundtrip tests still pass (degradation path unchanged, only adds a log).

### Group C — string fix + test (S3 hint, M1 titles)
- **M1** `route_details_page.dart:124,165`: `'Definir horário de início'` → `'Definir primeiro horário'`; `'Definir horário de término'` → `'Definir último horário'`. Update the 2 locking tests in `route_details_page_test.dart` (title assertions). Add a comment citing `/tmp/spoke-a5-msfix/timepicker-*.png`. **Do NOT touch line 152** (Destino ROW placeholder `'Definir horário de término'` — correct Spoke for the ROW).
- **S3-string** `picker_mode.dart:39,54`: both `'Buscar local de partida'`/`'Buscar local de destino'` → one shared ORIGINAL hint `'Buscar endereço'` (per ADR-0035: original, not Spoke's verbatim `'Insira um endereço'`). Update `add_stop_page_test.dart:343-358` + cite the capture file.

### Group D — behavior change + tests (S2, S4)
- **S2** `route_details_page.dart:37,54`: remove the `ref.watch(isRouteConfigValidProvider)` line + set `enabled: true` on the button (or drop the `enabled` gate entirely so it's always tappable + always pops). Revise the 2 widget tests (`:93` "disabled when invalid" → delete or rewrite to "always enabled"; `:106` "enabled when valid" → "enabled regardless of time state"). Spec line 126: rewrite to "always enabled; solver-window validation is Slice 3, not a UI gate". The provider + `RouteConfig.isValid` + their domain tests stay.
- **S4** `route_details_page.dart:253-258`: the `'Adicionar pausa'` row `onTap: null` → an interim `onTap` showing a `SnackBar('Pausa em breve')` until MS6 wires the real scheduler. Add a widget test: tap → SnackBar shown. (Spoke's row is clickable; this is the minimum honest affordance.)

### Group E — new widget + lifecycle + test (S1)
- **S1** new `_LiveClockLabel` StatefulWidget (in `route_details_page.dart` or its own file under widgets/): when `timeStart == null`, the Partida-Início row renders `'Iniciar agora mesmo'` + a dimmer right-aligned live `HH:MM`. Implementation:
  - `Timer.periodic(Duration(seconds: 30), ...)` → `setState` reading the injected clock.
  - `dispose()` cancels the timer.
  - `@visibleForTesting` clock param (`TimeOfDay Function() now`) defaulting to `() => TimeOfDay.now()` so the test injects a fixed clock — NO dependence on real wall-time.
  - Dimmer styling: split the row label into two `Text` spans (the existing `RouteConfigRow` may need a `trailingValue`/`secondaryText` slot, or render via the row's existing subtitle/trailing mechanism — check `route_config_row.dart` first; reuse existing slots, do not invent a new layout).
  - Update the locking test `route_details_page_test.dart:177-183` (`find.text('Iniciar agora mesmo')`) to also assert the live clock span renders, using the injected clock.
  - The CONFIRMED branch (lone `HH:MM` after `23ff0ff`) stays untouched.

### Group F — coverage nits (optional but in-scope: N3, N6)
- **N3** `route_defaults_controller.dart:38-43`: `merge()` pre-coalesces, making the `_omit` clear-branch unreachable. Add a code comment documenting the additive-only constraint + add a domain test: `RouteDefaults(startLocation: x).copyWith(startLocation: null).startLocation` isNull AND `copyWith().startLocation` isNotNull (pins the sentinel both ways).
- **N6** `route_details_page_test.dart`: 2 widget tests tapping `route_details_confirm` + `route_details_close` with a 2-route GoRouter, asserting return-to-sender (covers the bare `context.pop()`). Low effort.
- **N7** (PERF, optional) extract `_SalvarComoPadraoCheckbox` as its own StatefulWidget to scope the `setState` rebuild. → **DEFER**: negligible perf, one-shot tap; not worth the churn/risk this MS. Note as a tracked nit, do not implement.

## Sequencing (commit boundaries)

One commit per group (A–F), each green before the next, so a regression is localized:
1. `docs(...)`: Group A (spec/plan/ADR doc fixes).
2. `docs(route-config)`: Group B (comment-only code).
3. `fix(route-config)`: Group C (M1 titles + S3 hint + tests).
4. `fix(route-config)`: Group D (S2 Concluído + S4 Pausa stub + tests).
5. `feat(route-config)`: Group E (S1 live clock widget + test).
6. `test(route-config)`: Group F (N3 + N6 coverage).

After all: full suite + analyze + 2 reviewers (spec-parity + code-quality) + scope/debt gate, then push + notify Eduardo.

## Verification gates (before "done")
- [ ] `flutter test` all pass, count ≥ 240 (current) + new tests.
- [ ] `flutter analyze` clean in route_config + add_stop_page + app scope.
- [ ] `git diff <base> HEAD --stat` only the files this MS touches.
- [ ] zero `TODO|FIXME|BackToStart|UnsupportedError`; no `.g.dart` committed.
- [ ] S1 timer disposed (no test-teardown leak warning).
- [ ] S2: `isRouteConfigValidProvider` + `RouteConfig.isValid` + their domain tests STILL present (decoupled, not deleted).
- [ ] 2 reviewers approve.

## Out of scope (tracked, not done here)
- N7 checkbox-widget perf extract (negligible — tracked nit).
- integration_test/ for the 5-route Android-back chain → MS9 (already tracked).
- Pause scheduler sheet → MS6.
- FTUE/persist wiring → MS8.
- "Salvar como padrão" checked-default re-confirm vs fresh Spoke account → before Slice 3.
