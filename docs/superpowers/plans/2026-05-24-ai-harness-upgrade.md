# M2-AI Harness Upgrade Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade the Roteirizador Pro AI development harness by adopting the official Dart & Flutter MCP server, adding one PostToolUse hook for Riverpod codegen, two specialized subagents (`flutter-test-author`, `flutter-perf-auditor`), deciding on the community `mcp_flutter` visual-snapshot plugin, and seeding `golden_toolkit` regression coverage — each step backed by its own ADR, none of which touch product code under `apps/mobile/lib/features/`. The result: a fresh session on `feat/m2-ai-harness` can resolve real Flutter APIs via MCP (zero hallucination), have `.g.dart` files auto-regenerated after every relevant edit, and invoke specialized subagents for TDD and performance review.

**Architecture:** This plan ships 0 product code. It adds: 1 MCP server entry in `.claude/settings.json`; 1 PostToolUse hook script under `.claude/hooks/`; 2 subagent definitions under `.claude/agents/`; 6 ADRs (0023–0028, with 0026 conditional on Phase 6 execution); 1 golden test scaffold under `apps/mobile/test/`. Documentation touches: `CLAUDE.md`, `docs/sprints/2026-05-24-m2-ai-harness.md`, `docs/02-ARCHITECTURE.md`, `docs/03-CONVENTIONS.md`, `docs/10-CHANGELOG.md`, `docs/M2-SLICE-CHECKLIST.md`, `TODO.md`, plus one session log per executed phase and `docs/sessions/0001-INDEX.md` updates.

**Tech Stack:** Dart ≥ 3.9 (existing); `dart_mcp_server` (new, global Dart package); `mocktail` OR `mockito` (Phase 3 decision); `golden_toolkit` (Phase 6 dev-dep); optionally `mcp_flutter` (Phase 5 conditional). No backend changes; ADR-0011 (Bun) untouched.

**Spec:** `docs/superpowers/specs/2026-05-24-ai-harness-upgrade-design.md`

**Branch:** `feat/m2-ai-harness` (off `feat/m2-slice-2-telas-core` at `7808911`, already created in Phase 0).

---

## Working directory

All commands assume `cwd` is the repo root:
`/Users/eduardorodrigues/Documents/Projetos/Clientes/ueslei-workana/app-roteirizadorpro`

From here on, paths are repo-root-relative.

## Plan execution rules

1. **One phase = one logical commit set** (most phases = one commit; Phase 5 may be two if it adopts).
2. **TDD where logic exists.** The hook script (Phase 2) gets a manual smoke test (no automated test framework for bash hooks in this repo); subagents (Phases 3–4) get manual smoke tests against planted scenarios.
3. **No `--no-verify`.** Lefthook runs on every commit; if it complains, fix the underlying issue.
4. **ADR-in-same-commit.** Every phase that introduces a decision (1–6) commits the implementation **and** the ADR in the same `git commit`.
5. **Surgical edits only.** No "while I'm here" cleanups in adjacent files. Out-of-scope ideas go to `TODO.md`.
6. **MCP-first after Phase 1.** Once `dart_mcp_server` is up, use it for any Flutter/Dart symbol lookup instead of `Read`ing pub-cache.
7. **Stop between phases.** Each phase ends with a session log + index update + push; the human reviews before unlocking the next phase.

## File structure created/modified by this plan

See spec §Architecture "Harness file layout" for the full tree. Summary:

- `.claude/` — 1 settings.json modification, 1 hook script, 2 subagent definitions.
- `docs/decisions/` — 6 new ADRs (0023–0028).
- `docs/superpowers/` — 1 spec + 1 plan (this file).
- `docs/sessions/` — 1 kickoff + up to 7 per-phase logs + 1 retro + index updates.
- `docs/` — 4 doc modifications (02, 03, 10, M2-SLICE-CHECKLIST).
- `apps/mobile/` — `pubspec.yaml` + `test/flutter_test_config.dart` + 1 golden test (Phase 6 only).
- Root — `CLAUDE.md`, `docs/sprints/2026-05-24-m2-ai-harness.md`, `TODO.md`.

---

## Phase 0 — Pre-flight (✅ shipped 2026-05-24, session 19, commits `4b528f8` + `baaea44` + `782eb99`)

### Task 0.1: Verify branch and clean tree

**Files:** none (read-only checks).

- [x] **Step 0.1.1: Confirm branch and base**

Run:
```bash
git status
git rev-parse --abbrev-ref HEAD
git rev-parse HEAD
```

Expected:
- Branch: `feat/m2-ai-harness`
- HEAD: `7808911...` (the tip of `feat/m2-slice-2-telas-core` at sprint kickoff)
- Working tree may have pre-existing untracked: `CONTINUATION-PROMPT.md`, `docs/sprints/2026-05-24-m2-ai-harness.md`, plus modified `infra/docker-compose.yml`, `infra/graphhopper/extract-sp.sh` — these are NOT part of Phase 0. Leave untouched.

If branch is wrong: `git checkout feat/m2-ai-harness` (already created).

### Task 0.2: Scaffold spec and plan

- [x] **Step 0.2.1: Spec exists**

`docs/superpowers/specs/2026-05-24-ai-harness-upgrade-design.md` — created in Phase 0 of this sprint (file you're authoring from).

- [x] **Step 0.2.2: Plan exists**

`docs/superpowers/plans/2026-05-24-ai-harness-upgrade.md` — this file.

### Task 0.3: Update docs/sprints/2026-05-24-m2-ai-harness.md filename convention

- [x] **Step 0.3.1: Fix the proposed paths in SPRINT-MD**

`docs/sprints/2026-05-24-m2-ai-harness.md` currently references `docs/superpowers/specs/0002-ai-harness-upgrade.md` (numeric). The repo's actual convention is `YYYY-MM-DD-<slug>-design.md` for specs and `YYYY-MM-DD-<slug>.md` for plans. Update the SPRINT-MD header references and any in-body mentions to the date-based paths. Drop the `0002-` prefix entirely.

### Task 0.4: Add TODO.md tracking entry

- [x] **Step 0.4.1: Append sprint section to TODO.md**

Under "## M2 — Slices" or as a sibling top-level section, add:

```markdown
### 🔧 Sprint M2-AI (Harness upgrade — orthogonal to slice 2)

Branch `feat/m2-ai-harness`. Playbook in `docs/sprints/2026-05-24-m2-ai-harness.md`. Spec
in `docs/superpowers/specs/2026-05-24-ai-harness-upgrade-design.md`. Plan
in `docs/superpowers/plans/2026-05-24-ai-harness-upgrade.md`.

- [x] Phase 0 — Pre-flight (spec + plan + branch + TODO + session log) — `4b528f8` + `baaea44` + `782eb99` (sessão 19).
- [x] Phase 1 — Dart & Flutter MCP server (ADR-0023) — `2abe6bc` + `8c15f7c` (sessão 20).
- [x] Phase 2 — Riverpod codegen hook (ADR-0024) — `0a6f094` (sessão 22).
- [x] Phase 3 — `flutter-test-author` subagent (ADR-0025) + housekeeping ADR-0026 — `3dd30f8` (sessão 22b).
- [x] Phase 4 — `flutter-perf-auditor` subagent (ADR-0027) — `95d365f` (sessão 22c).
- [x] Phase 5 — `mcp_flutter` decision (ADR-0028) — REJECTED with re-evaluation trigger, `b09e207` (sessão 22d).
- [x] Phase 6 — Golden tests baseline (ADR-0029) — pivot from discontinued `golden_toolkit` to `alchemist`, `6a7f4f0` (sessão 22e).
- [x] Phase 7 — Docs consolidate + retro — `714147c` (sessão 22f). Sprint CLOSED.
```

### Task 0.5: Create kickoff session log

- [x] **Step 0.5.1: Author session log**

Create `docs/sessions/2026-05-24-19-ai-harness-kickoff.md` from the `0000-template.md`. Sequence `19` because `2026-05-20-18-ms-01b-statefulshellroute.md` is the last log of 2026-05-20 and the current date `2026-05-24` would normally restart at 01 — but the project's convention (checked in `0001-INDEX.md`) is monotonic across dates per the index ordering. **Verify at commit time which convention applies** and adjust if needed.

- [x] **Step 0.5.2: Append to index**

Append the new session entry to `docs/sessions/0001-INDEX.md` following the existing format.

### Task 0.6: Commit Phase 0 (✅ done)

- [x] **Step 0.6.1: Stage Phase 0 files only**

```bash
git add docs/sprints/2026-05-24-m2-ai-harness.md \
        docs/superpowers/specs/2026-05-24-ai-harness-upgrade-design.md \
        docs/superpowers/plans/2026-05-24-ai-harness-upgrade.md \
        docs/sessions/2026-05-24-19-ai-harness-kickoff.md \
        docs/sessions/0001-INDEX.md \
        TODO.md
```

Do **not** stage `CONTINUATION-PROMPT.md`, `infra/docker-compose.yml`, `infra/graphhopper/extract-sp.sh` — these are pre-existing untracked/modified files unrelated to Phase 0.

- [x] **Step 0.6.2: Commit**

```bash
git commit -m "$(cat <<'EOF'
docs(harness): kickoff M2-AI sprint — spec + plan

Phase 0 of the M2-AI harness upgrade sprint. Scaffolds the canonical
spec + plan + kickoff session log; tracks phases in TODO.md; corrects
SPRINT-MD filename convention from numeric to date-based to match
project precedent (Q6 in spec).

No code changes. No ADR yet — ADRs land in their respective phase
commits (0023..0028).

Spec:  docs/superpowers/specs/2026-05-24-ai-harness-upgrade-design.md
Plan:  docs/superpowers/plans/2026-05-24-ai-harness-upgrade.md
Sprint playbook: docs/sprints/2026-05-24-m2-ai-harness.md
EOF
)"
```

- [x] **Step 0.6.3: Run harness validation**

After commit, run the harness validation pipeline (see Phase 0 Self-Review below) and confirm everything is consistent. `adr-guardian` audit went YELLOW → YELLOW → GREEN across two follow-up commits (`baaea44` ADR renumber 0021..0026 → 0023..0028 to avoid collision with real ADRs 0021/0022; `782eb99` stale-ref sweep for two spots the rename sed missed).

---

## Phases 1–7

The full step-by-step bodies for Phases 1–7 are documented in `docs/sprints/2026-05-24-m2-ai-harness.md` (root of repo). That document is the canonical execution playbook; this plan's role is to register the spec linkage and the Phase 0 task breakdown.

When executing Phase N (N ≥ 1):

1. Re-read the corresponding section in `docs/sprints/2026-05-24-m2-ai-harness.md`.
2. Re-read the spec's §Architecture, §Data flow, and §Risks rows relevant to that phase.
3. Decompose into TDD-shaped tasks if not already (the SPRINT-MD's "Tarefas" lists are close — promote each to a Task with steps as needed).
4. Commit at the end of the phase with the ADR.
5. Add a session log + index update.
6. Push.

The plan file (this file) is amended only if a phase reveals that the SPRINT-MD playbook is wrong — in which case both files update in the same commit (per CLAUDE.md "Source of truth" rule: the more specific doc wins, and contradictions are bugs to fix immediately).

---

## Self-review

The plan author runs this checklist before declaring Phase 0 complete.

**Spec coverage (Phase 0 only — full coverage validated at each phase's commit):**

- §Context → Task 0.1 (read repo state).
- §Decisions Q1–Q6 → all six locked in spec; Phase 0 acts on Q6 only (filename convention).
- §Goals → not yet (sprint Goals validate after Phase 7).
- §Architecture (harness file layout) → Phase 0 creates 4 of the listed files.
- §Sub-slice plan (Phase 0 row) → 0.5h estimate; tasks 0.1–0.6 fit.
- §Libraries → nothing new in Phase 0.
- §ADRs filed → none in Phase 0 (correct).
- §Risks → Q6 risk (filename drift) mitigated in Task 0.3.
- §Verification gates → Phase 0 gate is "all four files exist + ADR drift hook silent" — validated at Task 0.6.3.

**Placeholder scan:** no `TBD`, no `TODO` in step bodies, no "implement later". (Q3 mock-lib decision is explicitly deferred to Phase 3 — documented, not a placeholder.)

**Scope check:** Phase 0 touches only `.md` files and `git` state. No code. No tests. No ADRs.

The plan's Phase 0 section is ready.

---

## Execution Handoff

Phase 0 executes **inline in the current session** (small, all-docs, no subagent needed). Phases 1–7 will be evaluated for subagent-driven vs inline at the start of each phase (per the spec's Sub-slice plan table — most are inline-friendly; Phase 3 might benefit from a subagent for the subagent-authoring meta-recursion if it gets unwieldy).
