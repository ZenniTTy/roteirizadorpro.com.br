# <Slice or feature name> Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** <one-paragraph restatement of what shipping this plan produces, in user-observable terms>.

**Architecture:** <one-paragraph summary of the layered choices — which controllers, which repositories, which services, which backend endpoints — that the spec's §Architecture documents in detail>.

**Tech Stack:** <bulleted or comma-separated list of every locked library and major language version>. Refer to ADR-NNNN for the stack lock.

**Spec:** `docs/superpowers/specs/<YYYY-MM-DD>-<slug>-design.md`

**Branch:** `feat/<slug>` (off `develop` at `<base-sha>`, already created and pushed).

<!--
Reading order for the AUTHOR before filling this file:
  1. The spec named above — every section, including §Decisions Locked, §Architecture, §Test strategy, §Verification gates.
  2. CLAUDE.md "Stack — Locked Versions" + "Schema Source of Truth" + Karpathy 4 principles.
  3. docs/M2-SLICE-CHECKLIST.md — the universal slice gates the plan must clear.
  4. The previous plan in docs/superpowers/plans/ — match its depth and per-task discipline.

REQUIRED PROCESS before authoring task bodies:
  Run `superpowers:writing-plans` to decompose the spec into atomic tasks.
  Each task = one logical commit. If a task body grows past 200 lines, split it.
-->

---

## Working directory

All commands assume `cwd` is the repo root:
`/Users/eduardorodrigues/Downloads/Elo Vision Digital/[EVD] - Meus Projetos/[APP] - Entrega Smart`

The path contains spaces and brackets — always quote it when needed in shell. From here on, paths are repo-root-relative.

## Plan execution rules

1. **One task = one logical commit.** Each task ends with `git commit` using Conventional Commits + a valid scope from `commitlint.config.cjs`. Lefthook runs typecheck/lint/analyze on the changed app(s).
2. **TDD where it makes sense.** Logic (controllers, repositories, services, URI builders, model conversions) → red test → green impl → commit. Widget screens → "renders without throwing" widget test first → screen impl → fidelity polish.
3. **No `--no-verify`.** If a hook fails, fix the underlying issue.
4. **Riverpod codegen.** Every controller is `@riverpod class X extends _$X { ... }`. After editing controllers, run `dart run build_runner build --delete-conflicting-outputs` and **commit the generated `.g.dart` files in the same commit** as the source.
5. **Hot reload over hot restart over full restart.** When `flutter run` is alive, prefer `r` for code changes inside `lib/**`. Full restart only for pubspec/native changes.
6. **Surgical edits only.** Don't refactor unrelated code. Match existing style in prior-slice files.
7. **Schema source-of-truth (ADR-0013 + ADR-0020).** TypeBox in `apps/backend/src/<feature>/schemas.ts` evolves first; Dart DTO mirror at `apps/mobile/lib/features/<feature>/data/dto/*.dart` ships in the same commit. The L1 header is exactly `// Mirror of: apps/backend/src/<feature>/schemas.ts -> <SchemaName>` (single-DTO) or `... -> {Schema1, Schema2, ...}` (multi-DTO), ASCII `->` only, no backticks. The `check-dto-mirror.sh` hook (ADR-0018) warns when you forget.
8. **Push after each completed sub-slice** (`git push` to keep origin current). Open the slice PR only after the release tasks at the end of this plan complete.

## File structure created/modified by this plan

<!--
For each app/layer this plan touches, draw the file tree of NEW + MODIFIED + DELETED files.
Slice 2's plan listed every file under apps/mobile/lib/, apps/mobile/test/, apps/backend/,
docs/, apps/landing/. Be exhaustive — the spec's §Architecture has the design; this list is
the contract every task lands against.
-->

### <App or layer> (`apps/<app>/<path>/`)

```
<tree>
```

---

## Phase 0 — Pre-flight (no commits)

### Task 0: Verify environment

**Files:** none (read-only checks).

- [ ] **Step 0.1: Confirm branch and clean tree**

Run:
```bash
git status
git rev-parse --abbrev-ref HEAD
git log --oneline -3
```

Expected:
- Branch: `feat/<slug>`
- Working tree clean
- HEAD points at `<base-sha>` (or later if amended) — the spec commit.

If any condition is false: STOP. <Concrete recovery instruction>.

- [ ] **Step 0.2: Confirm toolchain installed and version-locked**

Run:
```bash
flutter --version
flutter doctor -v
bun --version
node --version
```

Expected:
- Flutter ≥ <minimum from pubspec.yaml>
- Bun ≥ 1.3
- Node 20.x (per ADR-0011)

If anything is missing, fix host setup before continuing.

- [ ] **Step 0.3: <slice-specific pre-flight, e.g. device reachable, env vars present>**

- [ ] **Step 0.4: Read the spec one more time**

Open the spec named in the plan header. Skim §Goals (the N-step golden path) and §Test strategy. This is the contract every task below upholds.

No commit — Phase 0 is read-only.

---

## Phase 1 — <sub-slice or phase name>

<!--
For each phase / sub-slice, write a 1–2 sentence preamble summarizing what this phase
delivers and how it depends on (or is independent from) the previous phase.
-->

This phase <what it ships>.

### Task <N>: <task title in imperative — e.g. "Add slice 2 dependencies to pubspec.yaml">

**Files:**
- Create: `<path>`
- Modify: `<path>`
- Delete: `<path>` (only if explicitly required by the task)

<!--
Each task is ONE logical commit. Steps numbered <N>.1, <N>.2, … document the
sub-actions in execution order. Embed bash blocks with literal commands.
For TDD: use a "red test → green impl → commit" 3-step pattern. For non-TDD
edits (widget shells, docs): use a "edit → verify → commit" 3-step pattern.
-->

- [ ] **Step <N>.1: <what this step does>**

Run (or edit):
```bash
<command>
```

Expected: <what the human verifies before moving on>.

If <error mode>: <recovery>.

- [ ] **Step <N>.2: <next step>**

<!--
For tests: paste the test code in full. No "similar to Task M" shortcuts —
duplication is intentional in plans so the executor never cross-references.
-->

```dart
<test or impl code, verbatim>
```

- [ ] **Step <N>.3: Commit**

```bash
git add <file> [<file> ...]
git commit -m "$(cat <<'EOF'
<type>(<scope>): <subject in lowercase, ≤72 chars, no period>

<optional body, 72-col wrap, explaining WHY>
EOF
)"
```

<!--
Repeat the Task pattern for every task in this phase. Slice 2 had 41 tasks across
6 phases. Don't compress — explicit beats clever in a plan.
-->

---

## Phase <N> — <next phase>

<!--
Repeat the Phase pattern for every sub-slice or phase the spec's §Sub-slice plan declared.
-->

---

## Phase <final> — Release

### Task <M>: Final verification

<!--
The closing tasks: final analyze + test sweep across all changed apps; APK build + aapt2
dump + apksigner verify (if mobile); real-device E2E; build the PR body content; open
the feat PR; await Vercel preview; open the promotion PR; tag; production smoke;
session-end. Slice 2's Tasks 35–41 are the canonical template for this section.
-->

- [ ] **Step <M>.1: Run the full local verification**

```bash
cd apps/mobile && flutter analyze && flutter test && cd ../..
cd apps/backend && bun run typecheck && cd ../..
cd apps/landing && bun run lint && cd ../..
```

- [ ] **Step <M>.2: `/verify-slice`**

Run the `/verify-slice` skill (ADR-0018). Verdict must be GO before opening the PR.

### Task <M+1>: Build the release APK + verify

<!--
Only for slices that change the mobile APK. Otherwise drop this task.
-->

### Task <M+2>: Run the N-step golden path on the real device

<!--
Manual; capture screenshots.
-->

### Task <M+3>: Open the slice PR

```bash
gh pr create --base develop --head feat/<slug> \
  --title "<conventional title in lowercase>" \
  --body "$(cat <<'EOF'
## Summary
<2–4 bullets — what the user sees changed>

## What this slice ships (vs develop)
<bulleted high-level deliverables>

## Test plan
- [x] flutter analyze / test
- [x] aapt2 dump permissions (if mobile)
- [x] apksigner verify (if mobile)
- [x] adb install + golden-path manual test (screenshot attached)
- [x] backend curl evidence (paste below)
- [ ] Vercel preview deploy (auto-comment by Vercel bot)

## Backend smoke (curl)

<details>
<summary>POST /<endpoint> — three captures</summary>

```
(paste curl -i output)
```
</details>

## APK verification

<details>
<summary>aapt2 dump permissions</summary>

```
(paste output)
```
</details>

<details>
<summary>apksigner verify --verbose --print-certs</summary>

```
(paste output)
```
</details>

## Pre-merge manual action
<if any>

## Related
- Spec: `docs/superpowers/specs/<slug>-design.md`
- Plan: `docs/superpowers/plans/<slug>.md`
- ADR-NNNN (new in this PR)
- Roadmap: `docs/08-ROADMAP.md` "<section>"
- Checklist: `docs/M2-SLICE-CHECKLIST.md`
EOF
)"
```

Save the returned PR URL — it goes in the session log.

### Task <M+4>: Promotion PR `develop` → `main` + tag

<!--
After the feat PR merges. Slice 2's Task 40 is the template.
-->

### Task <M+5>: Session-end commit (single commit, three+ files)

<!--
Authors the session log via /session-end skill. Updates TODO.md, docs/sessions/0001-INDEX.md,
docs/10-CHANGELOG.md, and docs/08-ROADMAP.md (marking the slice ✅) in one commit.
-->

---

## Self-review

The plan author runs this checklist before declaring the plan complete.

**Spec coverage:** every section of the spec maps to one or more tasks.

- §Context → Task 0 (pre-flight read).
- §Decisions Q1 → Task <N>.
- §Decisions Q2 → Task <M>.
- §Goals (N-step golden path) → Task <release E2E task>.
- §Architecture → Tasks <range>.
- §Sub-slice plan (<2a–2e>) → Phases <N>–<M>.
- §Libraries table → Task 1 (+ amendment to ADR).
- §ADRs filed → Task <N>.
- §Risks → mitigations live inside the relevant tasks.
- §Accessibility → enforced inside Tasks <range>.
- §Test strategy → Task <final verification> + per-task TDD.
- §Verification gates → Tasks <release range>.

**Placeholder scan:** no `TBD`, no `TODO` in step bodies, no "implement later", no "similar to Task N" — code is repeated in full per the No-Placeholders rule.

**Type consistency:** controller method names, controller class names, page class names, schema type names, SharedPreferences keys are consistent across all tasks.

**Scope check:** single subsystem, single PR, single branch.

The plan is ready.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/<YYYY-MM-DD>-<slug>.md`. Two execution options:

**1. Subagent-Driven (recommended)** — A fresh subagent is dispatched per task. The agent reads the task, executes the steps, and returns. Eduardo reviews between tasks. Fast iteration; protects the main session context window from filling with implementation details.

**2. Inline Execution** — Tasks execute in the current session using `superpowers:executing-plans`. Batched with checkpoints for review. Higher token cost but no context handoff overhead.

Which approach?
