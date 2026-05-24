# 2026-05-24-19 — AI Harness Sprint Kickoff

## Metadata

- **Date**: 2026-05-24 (America/Sao_Paulo)
- **Sequence**: 19
- **Agent**: Claude Code (Opus 4.7)
- **Human**: Eduardo
- **Topic**: M2-AI harness upgrade — Phase 0 kickoff
- **Duration**: ~1h (research + sprint MD + Phase 0 scaffolds)
- **Related ADRs**: none in this commit; ADRs 0021–0026 land in their respective phase commits
- **Related TODO items**: new section "Sprint M2-AI (Harness upgrade — orthogonal to slice 2)"

## Goal of the Session

Bootstrap the M2-AI harness sprint: a parallel, branch-isolated effort to absorb the official Flutter team's AI tooling (Dart MCP server, AI Rules, Agent Skills doc) plus two community-inspired subagents and one PostToolUse hook, without disturbing slice 2 (Telas Core) which continues on its own branch. Phase 0 scope is pure scaffolding: branch + spec + plan + tracking + this log.

## What Was Done

- Ran research pass via WebSearch + Context7 (`/websites/flutter_dev`) on 2026-05-24 covering: official Flutter AI rules (updated 2026-01-05), Dart & Flutter MCP server doc, Agent Skills doc, community subagents (cleydson/flutter-claude-code, evanca/flutter-ai-rules, VoltAgent/awesome-claude-code-subagents, affaan-m), MCP plugins (Arenukvern/mcp_flutter), and competing spec-driven systems (gmickel/flow-next, gotalab/cc-sdd).
- Synthesized a 7-phase sprint into `SPRINT-M2-AI-HARNESS.md` at repo root — playbook with motivation, tarefas, gate de aceite, riscos, commit message per phase, plus a "how a future session resumes this sprint" section.
- Created branch `feat/m2-ai-harness` off `feat/m2-slice-2-telas-core` at SHA `7808911`.
- Authored canonical spec at `docs/superpowers/specs/2026-05-24-ai-harness-upgrade-design.md` with 13 H2 sections, including a 6-row Decisions table (Q1 adopt MCP now; Q2 PostToolUse not Stop; Q3 mock-lib deferred to Phase 3; Q4 mcp_flutter deferred to Phase 5; Q5 parallel branch not block; Q6 date-based filename convention).
- Authored companion plan at `docs/superpowers/plans/2026-05-24-ai-harness-upgrade.md` with Phase 0 fully decomposed; Phases 1–7 reference back to the SPRINT-MD as the canonical execution playbook.
- Detected and corrected a convention mismatch: my SPRINT-MD draft originally referenced numeric paths (`0002-ai-harness-upgrade.md`); the actual repo convention is `YYYY-MM-DD-<slug>-design.md` for specs and `YYYY-MM-DD-<slug>.md` for plans. Q6 locks the correction; SPRINT-MD updated in the same commit.
- Appended sprint tracking section to `TODO.md` (8 phase checkboxes).
- Authored this session log; appended to `docs/sessions/0001-INDEX.md`.

## Decisions Made

1. **Sprint runs on `feat/m2-ai-harness` orthogonal to slice 2** (Q5). Branch-isolated; sprint never touches `apps/mobile/lib/features/`. Slice 2 continues unblocked on its own branch.
2. **Filename convention: `YYYY-MM-DD-<slug>`, not numeric** (Q6). Matches all four existing spec/plan artifacts. SPRINT-MD amended.
3. **Phase 0 ships no ADR.** ADRs 0021–0026 are phase-scoped, one per decision, committed alongside their implementation in their own phase. Phase 0 = pure scaffolding.
4. **`SPRINT-M2-AI-HARNESS.md` is the canonical execution playbook;** the plan file (`2026-05-24-ai-harness-upgrade.md`) registers spec linkage and Phase 0 decomposition but defers Phase 1–7 step bodies to the SPRINT-MD to avoid duplication that would drift.
5. **Rejected from adoption: `flow-next` and `cc-sdd`** (documented in spec §References). Our `superpowers:` SDD is well-calibrated; replacing it would be churn-for-churn.

## Open Questions Left

- [ ] (Phase 3) Mock library for `flutter-test-author` — inspect `apps/mobile/pubspec.yaml` at execution time; if neither `mocktail` nor `mockito` present, default to `mocktail`. Lock in ADR-0023.
- [ ] (Phase 5) `mcp_flutter` adopt or reject — decision criteria documented in SPRINT-MD §Phase 5; outcome (either way) ships as ADR-0025.
- [ ] (Phase 1) Exact `dart_mcp_server` version to pin — resolve at install via `dart pub global activate` output and record in ADR-0021.

## Files Changed

**Created**:
- `SPRINT-M2-AI-HARNESS.md` (root)
- `docs/superpowers/specs/2026-05-24-ai-harness-upgrade-design.md`
- `docs/superpowers/plans/2026-05-24-ai-harness-upgrade.md`
- `docs/sessions/2026-05-24-19-ai-harness-kickoff.md` (this file)

**Modified**:
- `docs/sessions/0001-INDEX.md` (one new entry appended)
- `TODO.md` (new "Sprint M2-AI" section)

**Deleted**: none.

## Commits Pushed

```
(pending — Phase 0 commit lands at Step 0.6.2 of the plan; this log written pre-commit and included in the same commit)
```

## Hand-off Notes for Next Session

- **Branch:** `feat/m2-ai-harness` (off `feat/m2-slice-2-telas-core` at `7808911`).
- **Sprint state:** Phase 0 complete; Phases 1–7 not started.
- **Next phase:** Phase 1 — install `dart_mcp_server` (highest ROI of the sprint). Re-read `SPRINT-M2-AI-HARNESS.md` §"Fase 1" before starting.
- **Slice 2 is unaffected:** `feat/m2-slice-2-telas-core` continues its own work. Do NOT merge or rebase this sprint's branch into slice-2 until at least Phase 7 closes.
- **Pre-existing untracked items on the branch** (carried over from `feat/m2-slice-2-telas-core` tip): `CONTINUATION-PROMPT.md`, `infra/docker-compose.yml` (modified), `infra/graphhopper/extract-sp.sh` (modified). These are NOT this sprint's responsibility — leave untouched.
- **Validation gate at end of every phase:** the three Stop-hooks (`analyze-changed-dart.sh`, `check-dto-mirror.sh`, `warn-adr-drift.sh`) auto-fire; `warn-adr-drift.sh` should stay silent on Phase 0 (no `pubspec.yaml`/`package.json`/`schema.prisma`/`docker-compose.yml` edits) and active on Phase 1 (no ADR added means the hook should warn — but we ARE adding ADR-0021 in Phase 1, so it should be silent post-commit).

## Reference Material Used

- WebSearch queries (2026-05-24):
  - "Flutter Dart Claude Code agents skills hooks best practices 2026"
  - "Flutter AI assistant rules CLAUDE.md cursor rules awesome 2026"
  - "Flutter MCP server Dart language tools AI development 2026"
  - "\"flutter\" \"claude code\" subagents spec-driven workflow site:github.com"
- Context7: `/websites/flutter_dev` queried for "AI rules MCP server agent development assistant guidelines" (2026-05-24).
- Official Flutter docs fetched: `docs.flutter.dev/ai/ai-rules` (updated 2026-01-05), `/ai/mcp-server`, `/ai/agent-skills`, `/ai/coding-assistants`, `/ai/create-with-ai`.
- Project artifacts read: `CLAUDE.md` (full), `TODO.md` (first 80 lines), `docs/superpowers/specs/0000-template.md`, `docs/superpowers/plans/0000-template.md`, `docs/sessions/0000-template.md`, `docs/sessions/0001-INDEX.md` (first 30 lines for convention).
