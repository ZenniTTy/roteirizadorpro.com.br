---
name: verify-slice
description: Run the M2-SLICE-CHECKLIST §Verification gate as one orchestrated command — flutter analyze, flutter test, bun typecheck across the modified apps, plus spoke-parity-checker (D4 closing dispatch, dump-only per ADR-0049 — skipped for Áreas 1/11 which have no Spoke baseline) and adr-guardian dispatched as parallel subagents. Produces a single consolidated Markdown report. Use before opening any M2 slice PR (per CLAUDE.md "Current Focus") or when the user says "verify slice", "verifica slice", "ready to PR", "ready to merge". Does not commit, push, or edit code. Pure read-only orchestration. (prototype-fidelity-checker is NOT part of this gate — it runs only in the final visual-polish pass per the roadmap.)
disable-model-invocation: true
allowed-tools: Bash(flutter analyze:*), Bash(flutter test:*), Bash(bun run:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git rev-parse:*), Bash(cd:*), Agent
---

## /verify-slice — pre-PR slice gate

Packages the manual ten-step ritual in [`docs/M2-SLICE-CHECKLIST.md`](../../../docs/M2-SLICE-CHECKLIST.md) §Verification into one orchestrated run. Does not change *what* is verified — only how the run is composed. ADR-0018.

## When to invoke

- Just before opening a slice PR (`feat/m2-slice-N-<topic>` → `develop`).
- The user says "verify slice", "verifica slice", "ready to PR", "ready to merge", "pre-PR check", or any close variant.
- After a major chunk of slice work lands locally and the human wants a single status read.

## When NOT to invoke

- Mid-task. Each task has its own per-task verification baked into the plan; that's where bugs are cheapest to find. `/verify-slice` is a *gate*, not a *poll*.
- For a non-slice branch (e.g. a one-off `docs/*` branch). The skill assumes a slice-shaped diff.
- When you only need one of the checks. Run that check directly (`flutter analyze`, `gh pr view`, etc.).

## Inputs

- `$ARGUMENTS` (optional): the slice number, e.g. `2`. If omitted, infer from the current branch name (`feat/m2-slice-N-…`). If neither yields a number, ask the user once and continue.

## Workflow

### 1. Pre-checks (sequential, fast)

```bash
cd "$CLAUDE_PROJECT_DIR"
git rev-parse --abbrev-ref HEAD       # confirm slice branch
git status --short                    # working tree state
git log --oneline origin/develop..HEAD 2>/dev/null | head -30
```

Capture the branch name and the commit count ahead of `origin/develop`. Both go into the final report header.

### 2. Local verification (parallel-friendly)

Run these as separate `Bash` tool calls **in parallel** in one assistant message — they have no shared state:

```bash
# A — Mobile static analysis
cd apps/mobile && flutter analyze

# B — Mobile tests
cd apps/mobile && flutter test

# C — Backend typecheck
cd apps/backend && bun run typecheck

# D — Landing lint (only if apps/landing/ files appear in `git diff origin/develop..HEAD --name-only`)
cd apps/landing && bun run lint
```

Capture exit code and last ~30 lines of output from each. If a command is not applicable to this slice (e.g. landing untouched), record "skipped — no diff in this app".

### 3. Subagent dispatch (parallel)

Dispatch both subagents in **one assistant message** with two `Agent` tool calls. Both are read-only — no risk of conflicting writes.

- `spoke-parity-checker` (D4 closing dispatch — **dump-only by default per ADR-0049**) — prompt: *"D4 closing dispatch for the flow(s) shipped on this branch (`<branch>`, diff vs `origin/develop`). Compare the shipped RotPro implementation against the static dump baseline (MASTER-TABLE rows + amendments, `~/spoke-dump/jadx-out` greps, and the area's `docs/superpowers/specs/*-design.md` if present). Dump-only: do NOT navigate the live Spoke app except for `Precisa-runtime` clicks explicitly listed in the design doc/table for this area. Report the standard punch list (must-fix / should-fix / nit)."*
  **Skip this dispatch** (record "skipped — no Spoke baseline") when the branch's diff is exclusively Área 1 (auth) or Área 11 (notifications) work — those have no Spoke equivalent per the roadmap.
- `adr-guardian` — prompt: *"Audit stack-affecting changes on this branch (`<branch>`) against `origin/develop`. Use the standard ADR Guardian report format."*

Wait for both to return.

> `prototype-fidelity-checker` is intentionally NOT dispatched here — visual-identity sweeps run only in the final polish pass (roadmap §"Polish visual final"); dispatching it per-slice was a pre-ADR-0045 drift, removed 2026-06-11.

### 4. Consolidate

Produce one Markdown report under this exact structure (no narration outside the fenced block):

```markdown
# Slice Verification Report — slice <N> (`<branch>`)

**Base:** `origin/develop` · **HEAD:** `<short-sha>` · **Commits ahead:** <N>
**Working tree:** <clean | dirty — files>

## Local verification

| Check | Result |
|---|---|
| `flutter analyze` (apps/mobile) | ✅ clean / ❌ <N> issues |
| `flutter test` (apps/mobile) | ✅ <N>/<N> / ❌ <N> failures |
| `bun run typecheck` (apps/backend) | ✅ clean / ❌ <N> errors |
| `bun run lint` (apps/landing) | ✅ clean / ⏭ skipped (no diff) / ❌ <N> issues |

<paste failing-output tails inline here, NOT in collapsibles — humans read top-down>

## Spoke parity (D4, dump-only)
<paste spoke-parity-checker output verbatim — or "skipped: no Spoke baseline (Á1/Á11)">

## ADR coverage
<paste adr-guardian output verbatim>

## Outstanding items from `docs/M2-SLICE-CHECKLIST.md` §Verification

These remain manual — `/verify-slice` does NOT cover them:

- [ ] `aapt2 dump permissions <built APK>` — Android permission audit (requires the built APK).
- [ ] `apksigner verify --verbose --print-certs <built APK>` — signature audit.
- [ ] Real-device E2E on Samsung Galaxy M54 (`RQCW401G33T`) — slice golden path with screenshots.
- [ ] Backend `curl -i` evidence for any new/changed endpoint — paste into PR body.
- [ ] Vercel preview deploy SUCCESS (auto-posted by Vercel bot after `gh pr create`).

## Verdict

<one of:>
- ✅ **GO** — every automated check is green; remaining manual items can run during PR review.
- 🟡 **GO WITH WARNINGS** — automated checks green but parity/ADR audit flagged should-fix/nit items; proceed if the human accepts the deferrals listed above. (A parity **must-fix** is NOT a warning — it forces NO-GO per the slice checklist.)
- ❌ **NO-GO** — at least one automated check failed. Fix the specific issues listed under "Local verification" before opening the PR. Do not bypass.
```

### 5. Hand-off

Print only the Markdown report. Do **not** offer to fix issues, open a PR, or run the manual steps — those are separate, deliberate actions the human chooses.

## Constraints

- **Read-only.** This skill never writes, edits, or commits anything. The `allowed-tools:` allowlist enforces it at the harness level.
- **No `gh` calls.** PR creation is a separate, intentional step. Reading PR state is fine but not in this skill's scope.
- **Never bypass.** If `flutter analyze` reports issues, the verdict is NO-GO regardless of severity. The human decides if a warning is shippable; this skill only reports.
- **Token budget.** The two subagents return their own reports — paste verbatim; do not re-summarize. Each is already concise.
- **Parallel where independent.** Steps 2 (A/B/C/D) and step 3 (both agents) run in single batched assistant messages. Step 1 is sequential because step 2 depends on knowing the branch and diff.

## Anti-patterns

- Inlining a "while I'm here" fix when a check fails. The skill is a *gate*, not a *workspace*. Fail the verdict; the human re-runs after fixing.
- Re-implementing what the subagents already do. If `spoke-parity-checker` reports clean, this skill takes that at face value.
- Skipping the manual outstanding-items list. Even on a green verdict, the human needs the reminder that APK/E2E/curl evidence are still on them.

## What this skill is NOT

- Not a PR opener. After a GO verdict, the human runs `gh pr create` (or `/commit-push-pr` if they have it).
- Not a CI replacement. CI runs the same checks against the PR; this is the *local* pre-PR gate.
- Not a slice planner. Plans live in `docs/superpowers/plans/` and are authored separately.
- Not an APK builder. `bash apps/mobile/scripts/build-release-apk.sh` owns that, per CLAUDE.md.
