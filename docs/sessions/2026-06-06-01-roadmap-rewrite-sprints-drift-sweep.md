# Roadmap clean rewrite + 3 sprints authored + harness drift sweep

## Metadata

- **Date**: 2026-06-06 (America/Sao_Paulo)
- **Sequence**: 01
- **Agent**: Claude Code (Opus 4.8)
- **Human**: Eduardo
- **Topic**: Roadmap rewrite + planning sprints + harness drift cleanup
- **Related ADRs**: ADR-0042, ADR-0043 (referenced); ADR-0044 (planned, not yet filed — restructure sprint deliverable)
- **Related TODO items**: Slice 2 (all areas); the 3 authored sprints

## Goal of the Session

Docs/planning-only session (no `lib/`/`src/` edits by design). Eduardo asked, across several requests, to: (1) understand what remains until client delivery; (2) restructure remaining work so the recurring critical errors stop; (3) rewrite the roadmap clean as a single source of truth; (4) author a dedicated Slice-2 sprint with a strict per-area discipline (websearch/Context7 → fresh live Spoke dump per area → implement → validate); (5) verify ALL harness docs are free of stale references that could mislead next-session agents.

## What Was Done

- **Adversarial restructure analysis** (workflow `wvgn4h7fj`) — Eduardo proposed "clean prior work to avoid context pollution" + cut B2B features. Analysis confirmed him right on cutting B2B noise / keeping admin / live-validation / clearer roadmap, but pushed back on deleting mapping docs (root cause of MS4/MS5 was stale-baseline trust, NOT doc existence; the 2026-05-26 reset already deleted ~150 files and the failures STILL happened). Eduardo chose **keep-and-harden** (surgical) + a formal restructure spec/plan.
- **Authored the restructure sprint** — `docs/superpowers/{specs,plans}/2026-06-06-restructure-b2c-clarity-and-harden.md` (commit `498f16f`). Keystone deliverable: a researched B2C/B2B boundary doc + ADR-0044; generalize `area5-microsprint.js`→`spoke-microsprint.js`; promote the live-inspect contract into versioned files. NOT yet executed.
- **Researched the B2C/B2B boundary via WebSearch** (Eduardo's explicit "consult Spoke docs, don't assume") — see Decisions #1.
- **Delivery checklist** — produced the full what-remains list (Slice 2 ~55%, Slices 3–7 not started, backend `/optimize` is a mock).
- **Rewrote `docs/08-ROADMAP-v2.md` from scratch, clean** (commit `7d0eed7`, 407→~290 lines) — synced to real code, dependency-forced area order, B2C/B2B boundary section, 3 post-cutoff Flutter 3.44 breaking changes, gates (integration_test absent, 23 lints).
- **Authored the Slice-2 completion sprint** — `docs/superpowers/{specs,plans}/2026-06-06-slice2-completion.md` (same commit). One MS per remaining area, each running a mandatory 5-phase per-area pipeline; a 30-item NEVER-AGAIN bad-practices catalogue distilled from a 6-agent fact-gathering workflow (`wi6a2vnnw`).
- **Harness drift sweep** (workflow `w0qn8cx1t`, 5 agents, adversarially verified) — 41 raw findings → 34 confirmed drifts (16 conflicting) + 4 false-positives dropped. Fixed all 34 across two commits (`5804d73` + the human-authorized `dc2635e`).
- **Pushed** all 4 commits to origin.
- **Saved memory** `project_spoke_b2c_vs_b2b_boundary` (the researched classification).

## Decisions Made

1. **time-window + priority per stop are B2C, NOT B2B — keep them.** Official Spoke/Circuit docs (researched 2026-06-06) state the solo *Route Planner* "allows you to set delivery time windows and priority levels for specific stops." My pre-research instinct flagged them as B2B leaks to cut; the research reversed it. Cutting would have deleted legitimate consumer features AND violated locked directive #7.2/#13. The only genuine B2B feature (max-stops-per-plan) was already cut by ADR-0030. **The real B2C/B2B line is Spoke Route Planner (ours) vs Spoke Dispatch (assign-to-driver/fleet/team/customer-notifications — not ours).** Circuit rebranded to "Spoke" late 2025; "Circuit for Teams" → "Spoke Dispatch".
2. **Keep-and-harden over delete-and-restart.** Deleting the inventory/mapping docs repeats the 2026-05-26 reset that already failed. The cure is the live-inspect-per-feature discipline, not fewer docs.
3. **Slice-2 execution order is dependency-forced, not free.** Finish Á5 MS6–9 + Á3 triggers → 6→7→8→9; Á1/Á10/Á11 independent (Á10 precedes Á11). The old roadmap's "flexible order" was wrong — 6/7/9 each depend on a prior area's trigger.
4. **Áreas 1 + 11 have NO Spoke baseline → no `spoke-parity-checker` dispatch.** Á1 keeps our existing auth screens (directive #8); Á11 is original UI from directive #9 + the FCM plan. Dispatching parity-checker on a non-existent baseline wastes a cycle and invites inventing "parity".
5. **Old 2026-06-02 Á5 spec/plan: superseded-banner, not delete.** They hold the only detailed MS6–9 step bodies the new sprint references. Banner + fixed the stale facts inside (checkbox UNCHECKED, Concluído always-enabled, MS5 marked done).
6. **MCP tool-name fixes including the 3 `tools:` frontmatter lines were human-authorized.** The auto-mode guard correctly flagged them as permission changes; Eduardo authorized. Nuance disclosed: Maestro removed its isolated tools, so `spoke-parity-checker` now lists `run` (executes flow YAML) — more capable than the 4 it replaces, but the only way to navigate Spoke; it stays read-only for code (no Edit/Write).

## Open Questions Left

- [ ] The 3 authored sprints are NOT executed — restructure (boundary doc + ADR-0044 + workflow rename), revalidation (built-surface), Slice-2 completion (the build). Decide execution order next session.
- [ ] `integration_test/` directory still absent — Á5 MS9 authors the first (`area5_route_details_flow_test.dart`).
- [ ] 23 pre-existing analyze lints — MS-DEBT in the Slice-2 sprint burns them down before the slice PR.
- [ ] `feedback_spec_drafting_requires_live_widget_baseline.md` dangling pointer in ADR-0042:53 — flagged in the restructure sprint (MS6), not fixed this session.
- [ ] ADRs 0031–0040 still unbackfilled in CHANGELOG (owned by the revalidation sprint).

## Files Changed

**Created**:
- `docs/superpowers/{specs,plans}/2026-06-06-restructure-b2c-clarity-and-harden.md`
- `docs/superpowers/{specs,plans}/2026-06-06-slice2-completion.md`
- `~/.claude/.../memory/project_spoke_b2c_vs_b2b_boundary.md`
- `docs/sessions/2026-06-06-01-roadmap-rewrite-sprints-drift-sweep.md` (this file)

**Modified** (docs/harness only — zero `lib/`/`src/`):
- `docs/08-ROADMAP-v2.md` (full rewrite), `TODO.md`, `docs/10-CHANGELOG.md`, `CLAUDE.md`, `README.md`, `docs/M2-SLICE-CHECKLIST.md`, `docs/BUSINESS-RULES.md`, `docs/inventory/2026-05-26-spoke-vs-rotpro.md`
- `docs/superpowers/{specs,plans}/2026-06-02-area5-route-details.md` (superseded banners + drift fixes)
- `.claude/agents/{spoke-parity-checker,flutter-test-author,flutter-perf-auditor}.md`, `.claude/skills/verify-slice/SKILL.md`, `.claude/workflows/area5-microsprint.js`

## Commits Pushed

```
dc2635e docs(agents): fix dead MCP tool names in subagent tools: allowlists
5804d73 docs(harness): fix 34 verified drifts so agents don't act on stale facts
7d0eed7 docs(slice2): clean roadmap rewrite + dedicated Slice-2 completion sprint
498f16f docs(restructure): spec + plan for the B2C-clarity & harness-hardening sprint
```
(All pushed to `origin/feat/m2-slice-2-area-5-route-details`.)

## Hand-off Notes for Next Session

- Branch `feat/m2-slice-2-area-5-route-details`, clean + pushed (HEAD `dc2635e`).
- **Next dev step: MS-A5.6 (Área 5 sub-tela Pausa)** per `docs/superpowers/plans/2026-06-06-slice2-completion.md`. Run the 5-phase per-area pipeline; the live Spoke dump (Phase 2) is non-skippable. Replace the `route_details_page.dart:290` "Pausa em breve" SnackBar with a real break scheduler sheet (returns-intent pattern). Do NOT open PR (Á5 PR is MS-A5.9).
- The roadmap (`docs/08-ROADMAP-v2.md`) is now the single source of truth; TODO + CHANGELOG point at it. The 3 sprints are planning artifacts awaiting execution.
- Harness is drift-clean as of this session; subagent tool allowlists now name live MCP tools.

## Reference Material Used

- WebSearch + WebFetch: getcircuit.com / help.spoke.com / spoke.com / routific.com (B2C vs B2B Circuit/Spoke product line).
- Workflows: `wvgn4h7fj` (restructure analysis), `wi6a2vnnw` (Slice-2 fact base, 6 agents), `w0qn8cx1t` (drift scan, 5 agents).
- Live MCP tool lists (Maestro + Dart) to confirm dead-vs-live tool names.
- Memory: `feedback_spoke_evidence_per_ms`, `feedback_spec_baseline_and_workflow_halt`, `lesson_slice_checklist_integration_test_gate`, + the full anti-pattern set.
