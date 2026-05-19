## ADR-0018: Harness Auto-Validation Sensors (Wave A)

- **Status:** Accepted
- **Date:** 2026-05-19
- **Deciders:** Eduardo
- **Related ADRs:** ADR-0012 (DX tooling — Lefthook + Commitlint), ADR-0013 (API contract source of truth — TypeBox → Dart mirror)

## Context

The `.claude/` harness this repo carries today already does the cheap, mandatory things well: `block-env.sh` refuses writes to `.env*` and Android keystore material; `format-dart.sh` keeps Dart files canonically formatted after every agent edit; `reinject-roadmap.sh` rehydrates the M2 roadmap head into context after compaction. Lefthook then catches everything else at commit time. The CLAUDE.md "Karpathy's Four Principles" + the `prototype-fidelity-checker` and `adr-guardian` subagents close the loop on quality.

Three real failure modes survived this design and surfaced during M2 slice 2 (sessions 12–13):

1. **Late discovery of Flutter analyzer warnings.** Agent edits land via `Edit`/`Write`; `format-dart.sh` formats but does not analyze. The first signal is `flutter analyze` at `git commit` time via Lefthook — by then the agent has already moved 3–5 edits ahead and rewinding is expensive. Slice 2 burned cycles on `prefer_const_constructors` and `require_trailing_commas` warnings that would have been one-line fixes if seen on the editing turn.
2. **DTO mirror drift (ADR-0013).** When a TypeBox schema in `apps/backend/src/<feature>/schemas.ts` changes, the contract obliges the matching Dart DTO file at `apps/mobile/lib/features/<feature>/data/dto/*.dart` to change in the same commit. Today nothing mechanically enforces this — `adr-guardian` only fires when invoked, and the catch is the next `flutter analyze` after the DTO field is referenced from a screen. Slice 2 task 5 (evolving `OptimizeResponseSchema`) and task 8 (`StopDto`) shipped paired manually; the second time the contract is violated it will be by accident.
3. **Stack drift without an ADR.** CLAUDE.md mandates "Any change requires a new ADR" and `adr-guardian` enforces it pre-PR. But the agent only discovers the gap when it runs the guardian — and by then `pubspec.yaml` has shifted, `bun.lock` has been regenerated, and the ADR has to be backfilled. A loud-but-non-blocking warning at the moment of the manifest edit would catch this on the same turn, while context is still hot.

A fourth, related friction: the M2-SLICE-CHECKLIST §Verification has ~10 manual steps the human (or session-principal agent) runs sequentially before opening any slice PR. It works, but it's not packaged — every slice rediscovers the order.

The shared property of these four is that the answer is **already in the repo** (the ADR template, the `// Mirror of:` header convention, the analyze command, the checklist). What's missing is a sensor that runs them at the right moment without the agent having to remember.

This is the next iteration the Tech Lead's Club "harness" framing labels *feedforward → action → feedback*: we have feedforward (AGENTS.md, CLAUDE.md, M2-SLICE-CHECKLIST) and we have post-action feedback at the commit boundary (Lefthook). What's thin is **in-loop feedback**: the sensor that fires while the agent is still on the same turn that introduced the drift.

## Options Considered

### Option A — Do nothing; rely on Lefthook + agent discipline

- Pros: Zero new moving parts; Lefthook already catches everything before history lands; the existing subagents (`adr-guardian`, `prototype-fidelity-checker`) cover the pre-PR window.
- Cons: Late feedback is expensive feedback. Each rewind to fix a 2026-trivial analyzer warning costs ~30 s of agent time + context churn. The DTO mirror contract is *only* enforced socially — the first slip will be silent. ADR drift is only caught when the agent remembers to invoke `adr-guardian`, which is a discipline tax.

### Option B — Pre-commit-style PostToolUse hook, blocking, per edit

- Pros: Fastest possible feedback; nothing slips by.
- Cons: `flutter analyze --no-pub <file>` is 2–5 s warm and longer cold. Running it on every Dart `Edit` in a 25-commit slice means ~2–3 min of accumulated wait *per slice*, all of it in the agent's critical path. Blocking on a warning also creates pressure to skip the hook (`--no-verify` mindset bleeds in even though Lefthook is the one that respects `--no-verify`). Wrong place to put the sensor.

### Option C — Stop-hook batch (this ADR)

A `Stop` hook fires once per agent stop (per Anthropic hooks docs — "when the model has finished responding"). It scans the set of files edited since the last stop, runs `flutter analyze` once over the changed files in `apps/mobile/lib/`, runs the DTO-mirror grep over edited `schemas.ts` files, and emits a non-blocking warning summary. Cost: one analyze invocation per agent turn (not per edit) — typically 3–8 s, paid at the natural pause where the human is reading output anyway. ADR drift warning is also batched.

A separate skill (`/verify-slice`) packages the M2-SLICE-CHECKLIST §Verification: runs `flutter analyze`, `flutter test`, `bun typecheck`, dispatches `prototype-fidelity-checker` + `adr-guardian` in parallel, consolidates to one report. Human-invoked at the natural moment (before the slice PR), not on every edit.

- Pros: Sensor fires at the moment when latency is invisible (the agent stopped anyway); single execution per turn instead of N per N edits; non-blocking so the workflow never stalls on a warning; `/verify-slice` consolidates the manual checklist without changing what it checks.
- Cons: Slightly looser feedback than per-edit (the agent can chain three edits before the first analyze). For Dart that's still fine because `flutter analyze` is fast at file scope.

### Option D — Move everything to Lefthook (pre-push)

- Pros: One enforcement system; familiar to humans.
- Cons: Pre-push is too late for agent feedback (the agent has already committed). Lefthook is the cross-tool enforcement; the Claude Code hooks are the *intra-turn* feedback. ADR-0012 already drew this boundary explicitly: "If a check belongs at 'any commit by anyone', it goes to Lefthook. If a check belongs at 'any agent action', it goes to `.claude/hooks/`." This ADR is the natural extension of that rule.

## Decision

Adopt **Option C** — Stop-hook batch + `/verify-slice` skill.

Three new Claude Code hooks, all wired in `.claude/settings.json`:

| Hook | Trigger | What it does | Failure mode |
|---|---|---|---|
| `analyze-changed-dart.sh` | `Stop` | Collects `.dart` files edited since the last Stop that live under `apps/mobile/lib/`, runs `flutter analyze --no-pub` once over that set, prints issues. | `exit 0` (silent) when clean; `exit 1` + stderr when issues found. Never blocks. |
| `check-dto-mirror.sh` | `Stop` | For each `apps/backend/src/<feature>/schemas.ts` edited since the last Stop, greps `apps/mobile/lib/features/<feature>/data/dto/*.dart` for a `// Mirror of:` header that references the changed file; warns when the mirror file exists but was NOT edited in the same turn. | `exit 0` clean; `exit 1` warn. |
| `warn-adr-drift.sh` | `Stop` | When `pubspec.yaml`, any `package.json`, `prisma/schema.prisma`, or `infra/docker-compose.yml` was edited since the last Stop, checks the working tree for a new/modified `docs/decisions/*.md`; warns if none. | `exit 0` clean; `exit 1` warn. |

One new local skill:

- **`/verify-slice`** — wraps the M2-SLICE-CHECKLIST §Verification. Dispatches `prototype-fidelity-checker` + `adr-guardian` as parallel subagents, runs `flutter analyze`, `flutter test`, `bun --filter './apps/backend' run typecheck` locally, aggregates the output into a single Markdown report. Pure orchestration — does not change what is verified.

Scope discipline:

- All three new hooks operate **only on the explicit path globs above**. They are no-ops outside them. No surprise re-analysis of `apps/landing/` or `apps/backend/`.
- All three are **non-blocking** (exit 0 silent, exit 1 warn). The existing `block-env.sh` is the only hook in this repo that uses `exit 2` (blocking), and that distinction is preserved by design.
- The `Stop` matcher (vs `PostToolUse`) is the load-bearing change: per-edit hooks burn latency on every edit; per-Stop hooks pay the cost once per turn.

`CLAUDE.md` gains a short pointer to this ADR under "Project-Specific Critical Rules"; nothing about the rules themselves changes.

## Consequences

- **Positive:** analyzer warnings, DTO mirror drift, and ADR-less stack changes surface inside the same turn that introduced them. The slice closing ritual (`/verify-slice`) is one command instead of nine manual steps. The Lefthook + commitlint + agent-discipline trio still owns enforcement; the new hooks own *signal*. Latency is paid where it's invisible.
- **Negative:** four new files in `.claude/` to keep working. A `Stop` hook that errors loudly will pollute every turn until fixed — the hooks are intentionally `set -euo pipefail` + `exit 0` on any unexpected `jq` failure (defensive) so that a malformed transcript can never wedge an agent session.
- **Neutral:** the M2-SLICE-CHECKLIST stays the source of truth for *what* gets verified; `/verify-slice` is just an executable wrapper. If the checklist changes, the skill follows.

## Implementation Notes

- The `Stop` hook reads the JSON transcript Anthropic passes on stdin. We extract edited file paths from the `transcript_path` file by parsing the events (`Edit`, `Write`, `MultiEdit` tool calls since the last `Stop` event). When transcript parsing is unavailable (older harness), we fall back to `git diff --name-only HEAD` which captures the working-tree state — slightly broader but never wrong.
- `analyze-changed-dart.sh` invokes `flutter analyze --no-pub <files>` from `apps/mobile/`. The `--no-pub` flag skips dependency resolution, keeping the run fast (typically 3–6 s for a small file set).
- `check-dto-mirror.sh` uses the convention codified in ADR-0013 and normalized by ADR-0020: every Dart DTO file starts with `// Mirror of: apps/backend/src/<feature>/schemas.ts -> <SchemaName>` (single-DTO) or `... -> {Schema1, Schema2, ...}` (multi-DTO), ASCII `->` only. The grep matches both forms via the shared `-> ` prefix; ADR-0020 tightens the hook to an anchored regex.
- `warn-adr-drift.sh` runs `git status --porcelain docs/decisions/` to detect new/modified ADRs in the working tree. If none, it emits the warning naming the stack-affecting file that triggered it.
- `/verify-slice` is `disable-model-invocation: true` (human-triggered only) and has an `allowed-tools:` allowlist matching the read-only commands it runs.
- The three hooks register under `Stop` in `.claude/settings.json` with `timeout: 30` (analyze is the long pole; 30 s is generous and we observed 3–8 s in practice).
- No new package dependencies. `jq` is already used by `block-env.sh` and `format-dart.sh`. `flutter` and `git` are project requirements.

## Boundary: hooks vs Lefthook vs subagents (extends ADR-0012)

| Layer | Fires when | Owns |
|---|---|---|
| Claude Code agent hooks (`.claude/hooks/*.sh`) | Agent tool calls (`PreToolUse`, `PostToolUse`) and agent stop (`Stop`) | Intra-turn signal: format, refuse secret writes, surface drift |
| Subagents (`.claude/agents/*.md`) | Human or agent invocation | Auditing depth: ADR coverage, prototype fidelity, slice-level review |
| Lefthook hooks (`lefthook.yml`) | `git commit` / `git push` | Enforcement at the history boundary: typecheck, lint, commit-msg format |
| Skills (`.claude/skills/*/SKILL.md`) | Human invocation via slash command | Procedural orchestration: commit, session-end, scaffold a feature, verify a slice |

The Wave-A additions sit entirely in the first and fourth row. ADR-0012's rule ("never duplicate logic across the two") extends naturally: a sensor that warns at agent-stop time does not duplicate a Lefthook check that enforces at commit time — they are at different points in the loop and serve different feedback windows.

## References

- ADR-0012 — Lefthook + Commitlint + Commitizen tooling boundary that this ADR extends.
- ADR-0013 — Schema source of truth: TypeBox → Dart DTO mirror contract that `check-dto-mirror.sh` materializes.
- CLAUDE.md → "Stack — Locked Versions" + "Any change requires a new ADR" — the rule `warn-adr-drift.sh` shadows.
- `docs/M2-SLICE-CHECKLIST.md` §Verification — the manual checklist `/verify-slice` packages.
- Anthropic Claude Code hooks documentation — `https://code.claude.com/docs/en/hooks-guide` (Stop matcher semantics, JSON stdin schema, exit-code conventions).
- Tech Lead's Club — "Harness Engineering" framing of feedforward / action / feedback that motivated the placement of the new sensors.
