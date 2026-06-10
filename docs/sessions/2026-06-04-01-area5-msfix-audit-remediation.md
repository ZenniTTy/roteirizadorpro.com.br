# Área 5 MS-FIX — retrospective audit + 14-item remediation

## Metadata

- **Date**: 2026-06-04 (America/Sao_Paulo) — work spanned 2026-06-03 late → 2026-06-04
- **Sequence**: 01
- **Agent**: Claude Code (Opus 4.8)
- **Human**: Eduardo
- **Topic**: Área 5 retrospective audit + MS-FIX remediation
- **Related ADRs**: ADR-0043 (§Decision 3 divergence table + Q8 note added)
- **Related TODO items**: Slice 2 / Área 5 / MS-FIX
- **Commits**: `21d43c4` (code), `6e1f738` (docs), `3fb9e3f` (TODO), + this session/CHANGELOG commit

## Goal of the Session

After MS5 shipped, Eduardo asked for (1) a **process change** — re-inspect Spoke
live before every new feature, never trust a prior-session baseline — and (2) a
**read-only retrospective audit** of MS1–MS5 to catch anything auto-mode hid.
Then: fix everything the audit found, breaking-change-aware.

## What Was Done

- **Locked the process directive in memory** (`feedback_spoke_evidence_per_ms`):
  fresh live Spoke re-inspection per feature is now mandatory — a prior capture
  that exists and is non-zero can still be WRONG (MS4 numpad: 0-byte; MS5
  Destino: mislabeled). The non-zero-byte gate would have passed on the MS5
  mislabel; only re-inspecting the named widget catches it. Order of ops:
  map → live-inspect → implement → validate.
- **Ran a read-only audit Workflow** (`w39xs7ic8`, 37 agents, 6 dimensions:
  Spoke-parity LIVE re-inspect, harness best-practices, hallucinations/silent-
  failures, ADR↔code drift, test quality, perf) → adversarial verification
  (30 raw findings → 21 confirmed, 9 dropped as false-positive) → synthesis.
  Verdict: `minor-issues`. Report at
  `docs/audits/2026-06-03-area5-ms1-ms5-retro-audit.md`. 50+ good practices
  confirmed; zero crash/silent-failure on reachable code.
- **Wrote the MS-FIX plan** (`docs/superpowers/plans/2026-06-03-area5-msfix-audit-remediation.md`)
  with breaking-change guardrails (every behavior change updates its locking
  test in the same edit; S2 keeps the validity provider in the domain; S1
  encapsulates the Timer).
- **Re-inspected Spoke live** (Maestro MCP, M54) for the 3 parity fixes I'd
  touch — confirmed: time-picker headers `bsp_input_time` = "Definir primeiro
  horário" / "Definir último horário"; "Iniciar agora mesmo" row has a live
  wall-clock sibling tracking the system clock; "Concluído" Button enabled with
  no times set. Saved `/tmp/spoke-a5-msfix/EVIDENCE.md` + 2 header PNGs.
- **Fixed all 14 punch-list items:**
  - **M1 (must-fix):** time-picker SHEET headers → "Definir primeiro/último
    horário" (Destino ROW placeholder left correct + untouched).
  - **S2:** "Concluído" always enabled (Spoke renders it tappable with no times
    set). Decoupled `isRouteConfigValidProvider` from the button — provider +
    `RouteConfig.isValid` KEPT in the domain + still tested (Slice-3 solver).
  - **S1:** live wall-clock on the unconfigured "Iniciar agora mesmo" row via a
    new `LiveClockLabel` (Timer.periodic 30s, `dispose` cancels, injectable
    clock for deterministic tests). Confirmed-state collapse (23ff0ff) preserved.
  - **S3:** picker hints → one original shared "Buscar endereço" (ADR-0035:
    original, not Spoke's verbatim "Insira um endereço"). Removed the false
    "distinct placeholder" comment.
  - **S4:** "Adicionar pausa" row no longer inert — interim "Pausa em breve"
    SnackBar until the MS6 scheduler.
  - **N2/N3/N4/N6:** catch-logging in `RouteDefaults.fromJson`; documented
    `merge()` additive-only + pinned the `copyWith` `_omit` clear-path; fixed
    the `_popWithStartLocation` docstring; added Concluído/close-X pop tests.
  - **S5/N5/N8 docs:** `app_router.dart` → `app.dart` across spec+plan;
    scroll-wheel → numpad in spec Goal #10 + Risks; ADR-0043 §Decision 3
    divergence table (canonical `#N`) + Q8 unchecked-checkbox note.
  - **N7 deferred** (checkbox-widget perf extract — negligible, tracked nit).
- **Two reviewers** (spec-parity + code-quality). Spec-parity: `compliant`.
  Code-quality: `changes_requested` with ONE must-fix — a self-inflicted
  inconsistency: the ADR-0043 divergence table I wrote declared itself canonical
  for the code's `#N`, but my numbering (#5/#6 visual) collided with the code's
  (#5/#6 behavioral). Fixed by rewriting the table to match the code exactly
  (#2-#4 visual, #5-#6 behavioral). Plus 2 comment nits fixed.
- **Final:** 249 tests pass (+9 net), analyze clean in scope, zero tech debt,
  no `.g.dart`. Commits pushed.
- **docs-lint pass** (Eduardo asked "tudo atualizado seguindo as boas práticas?"):
  0 CRITICAL, 2 IMPORTANT (this session log + CHANGELOG were missing), 1 MINOR
  (docs/audits/ had no pointer). All links/refs/ADR-statuses/commands clean.
  This session + the CHANGELOG entry + the pointer close the IMPORTANT/MINOR.

## Decisions Made

1. **Process: live-inspect per feature, never trust prior baseline** — the root
   cause of both MS4 and MS5 parity misses. Now a standing directive.
2. **S2 decouple, don't delete** — `isRouteConfigValidProvider` /
   `RouteConfig.isValid` stay in the domain for the Slice-3 solver; only the UI
   stops consuming them. Avoids a breaking change to the domain + its tests.
3. **S1 Timer encapsulated** — `LiveClockLabel` owns the lifecycle (dispose +
   injectable clock) so the page stays presentational and the test is
   deterministic (no real wall-time dependence, leak-proof).
4. **ADR-0043 divergence table matches the CODE, not an idealized scheme** —
   after the reviewer caught my numbering collision, the table now mirrors the
   code's `#N` exactly (mixing visual + behavioral, because the code does).
5. **CHANGELOG scope = Área 5 from the reset** — recorded ADR-0041/42/43 +
   MS1-MS5 + MS-FIX; did NOT backfill ADR-0031-0040 (other slices' work;
   pre-existing gap, noted not fixed).

## Open Questions Left

- [ ] `docs/10-CHANGELOG.md` still lacks entries for ADR-0031-0040 (sprints
  before Área 5). Pre-existing gap, out of this session's scope — decide whether
  to backfill before M2 closes.
- [ ] MS9 must author `integration_test/area5_route_details_flow_test.dart`
  (5-route Android-back chain) BEFORE the slice PR (tracked since MS5).
- [ ] "Salvar como padrão" checked-default re-confirm vs a fresh Spoke account
  before Slice 3 (ADR-0043 §Decision 4 open item).

## Files Changed

**Created**:
- `docs/audits/2026-06-03-area5-ms1-ms5-retro-audit.md`
- `docs/superpowers/plans/2026-06-03-area5-msfix-audit-remediation.md`
- `docs/sessions/2026-06-04-01-area5-msfix-audit-remediation.md` (this file)

**Modified** (code): `route_config/{domain/route_defaults.dart,
presentation/pages/route_details_page.dart,
presentation/widgets/route_config_row.dart, state/picker_mode.dart,
state/route_defaults_controller.dart}`, `routes/.../add_stop_page.dart` + their
6 test files.

**Modified** (docs): `docs/decisions/0043-...md`,
`docs/superpowers/{specs,plans}/2026-06-02-area5-route-details.md`, `TODO.md`,
`docs/sessions/0001-INDEX.md`, `docs/10-CHANGELOG.md`.

## Commits Pushed

```
3fb9e3f docs(todo): record Área 5 MS-FIX audit remediation
6e1f738 docs(area5): MS1–MS5 audit report + MS-FIX plan + doc-staleness fixes
21d43c4 fix(route-config): Área 5 audit remediation — Spoke parity + affordance fixes (MS-FIX)
```
(+ this session/CHANGELOG/pointer commit.)

## Hand-off Notes for Next Session

- Branch `feat/m2-slice-2-area-5-route-details`, clean + pushed.
- Next: **MS6 Sub-tela Pausa** (chips horário + duração). Use the live-inspect-
  first directive + the `area5-microsprint.js` template (args msNumber=6) — and
  include the router file in `filesToTouch` if any "Personalizar" chip pushes a
  route (the MS5 scope-error lesson). MS6 also picks up the S4 stub → real
  scheduler.
- Do NOT open PR — MS9 D4.

## Reference Material Used

- Live Spoke re-inspection via Maestro MCP → `/tmp/spoke-a5-msfix/`.
- Audit Workflow `w39xs7ic8` (6 dimensions + adversarial verify).
- Two code-reviewer subagents (spec-parity + code-quality).
- `/docs-lint` skill (adapted to this project's `0001-INDEX.md` + `10-CHANGELOG.md`).
- Memory: `feedback_spoke_evidence_per_ms` (updated this session),
  `feedback_spoke_parity_zero_debt_per_ms`,
  `feedback_escalate_recurring_and_gate_check`,
  `lesson_checkpoint_discipline_between_microsprints`.
