# ADR-0024: PostToolUse hook to auto-run Riverpod `build_runner` codegen

- **Status:** Accepted
- **Date:** 2026-05-24
- **Deciders:** Eduardo
- **Supersedes:** none
- **Related ADRs:** ADR-0018 (in-loop auto-validation hooks family), ADR-0012 (lefthook layered boundary), ADR-0023 (Dart & Flutter MCP server)
- **Sprint:** M2-AI Harness — Phase 2 (see `SPRINT-M2-AI-HARNESS.md`)

## Context

The mobile app uses **Riverpod 3 with codegen** (`@riverpod` annotations + `part 'X.g.dart'`). Every time the assistant edits a provider, the matching `*.g.dart` must be regenerated via:

```
cd apps/mobile && dart run build_runner build --delete-conflicting-outputs
```

This command already lives in CLAUDE.md §Executable Commands. The recurring failure mode: the assistant edits a provider, forgets to regenerate, then `flutter analyze` errors on stale `.g.dart` — caught either by ADR-0018's `analyze-changed-dart.sh` Stop hook (best case) or by lefthook at commit (still annoying), or by the human at runtime (worst case). The MCP server (ADR-0023) removes hallucination about *which* methods exist; it does not run codegen for us.

Phase 2 of the M2-AI sprint closes this gap with a hook that regenerates `.g.dart` automatically as a side effect of editing a Riverpod-annotated file.

## Options Considered

### Option A — `Stop` hook (same family as ADR-0018's three existing hooks)

Run once per agent turn, after the assistant is done.

- Pros: batches multiple edits into a single codegen run; matches the existing hook family pattern.
- Cons: `flutter analyze` (also a Stop hook) runs in the same Stop event and would race against codegen — if analyze fires first, it sees stale `.g.dart` and reports false positives. Ordering between Stop hooks is not guaranteed in Claude Code's spec.
- **Rejected** — race condition with `analyze-changed-dart.sh` is the exact problem this hook should prevent.

### Option B — `PreToolUse` on the next tool (defensive)

Regenerate right before the next assistant action, on the theory that codegen output is only consumed by subsequent reads/edits.

- Pros: latest possible moment to run.
- Cons: imposes a 30–90s wait at the *start* of the next turn instead of the end of the current one. Worse UX: the assistant appears to hang. Also matcher would have to be very broad (`*` or `Read|Edit|Write|Bash`) to catch all consumers.
- **Rejected** — wrong end of the turn.

### Option C (this ADR) — `PostToolUse` on `Edit|Write|MultiEdit`, filtered by file content

Fire immediately after each edit, but only if the edited file actually has `@riverpod` or a `part '*.g.dart'` directive. Debounce via lock file to coalesce burst-edits.

- Pros: latency hidden inside the same turn (the assistant has already moved on to the next tool call); only fires when needed; debounce prevents N parallel `build_runner` invocations on a multi-provider turn.
- Cons: `dart run build_runner build` is **slow** (~30–90s cold, 5–15s warm) — running it inline as a hook stretches the turn. Mitigated by the lock-file debounce (only the first qualifying edit in a 90s window runs codegen; subsequent ones skip).
- **Accepted.**

## Decision

**Adopt Option C.** Add `.claude/hooks/run-riverpod-codegen.sh` and register it under `hooks.PostToolUse` with matcher `Edit|Write|MultiEdit`, timeout 120s, alongside the existing `format-dart.sh`.

### Implementation details

The hook:

1. Reads `tool_input.file_path` from stdin JSON (PostToolUse contract).
2. Filters: file must end in `.dart`, must live under an absolute path containing `/apps/mobile/lib/`, must not itself be a `.g.dart` file, must exist on disk.
3. Greps the file for `^@[Rr]iverpod` OR `^part .+\.g\.dart` — only files participating in codegen qualify.
4. Debounce: checks `${TMPDIR}/roteirizador-riverpod-codegen.lock`; if last-run timestamp is < 90s ago, exits 0 silently. Otherwise writes current timestamp.
5. Runs `dart run build_runner build --delete-conflicting-outputs` from `apps/mobile/`.
6. On success, exit 0 silent. On failure, dumps the last 30 lines of `build_runner` output to stderr and exits 1 (non-blocking — Claude Code surfaces stderr to the assistant for it to act on).

## Consequences

### Positive

- **Stale `.g.dart` errors disappear from the analyze hook's surface area.** ADR-0018's `analyze-changed-dart.sh` Stop hook stops false-flagging codegen drift.
- **One less command for the assistant to remember.** `CLAUDE.md` §Executable Commands no longer needs to be consulted on every provider edit.
- **Naturally scoped.** Only triggers when an annotated file changes — non-Riverpod Dart edits remain free (verified by smoke test).
- **Coalesced bursts.** Lock-file debounce ensures a turn that edits 5 providers does not spawn 5 concurrent `build_runner` processes.

### Negative

- **Up to ~60s of inline latency** on the first qualifying edit of a turn. Trade-off accepted because (a) it would have to happen anyway and (b) the human would otherwise wait for the analyze hook to fail, then prompt the assistant to regenerate.
- **Lock file is per-OS-user, not per-repo.** If two clones of this repo were edited simultaneously the lock would inappropriately debounce one of them. Considered fine — multi-clone concurrent editing is not a real workflow here.
- **Hooks fire in arbitrary order within the same PostToolUse matcher entry.** `format-dart.sh` and `run-riverpod-codegen.sh` are both registered; codegen does not depend on the file being formatted, so order is irrelevant.

### Neutral

- The `tool_input.file_path` contract is shared with `format-dart.sh` — same JSON shape, same `jq` extraction. Symmetric with the existing pattern.

## Rollback

If the hook proves disruptive (e.g. `build_runner` becomes flaky, lock file collides with concurrent dev workflow, or the latency cost outweighs the benefit):

1. Remove the `run-riverpod-codegen.sh` entry from `.claude/settings.json` under `hooks.PostToolUse`.
2. Delete the hook file.
3. Revert the CLAUDE.md "In-Loop Auto-Validation" section to its three-hook form.

Total revert is a 3-file diff, no codebase impact. The fallback is the status quo before this ADR: assistant must remember to run codegen manually, and stale `.g.dart` is caught by the analyze Stop hook one turn later.

## Verification (smoke test executed at adoption — sprint Phase 2 commit)

1. Edit a `lib/main.dart` (plain Dart, no `@riverpod`) → hook exits 0 silent, no lock file written, no codegen runs. ✅
2. Edit `lib/core/providers/api_providers.dart` (`@riverpod`-annotated) → hook runs `build_runner` for ~60s, `.g.dart` files refreshed (`features/auth/state/auth_controller.g.dart` mtime bumped), lock file written, exit 0. ✅
3. Second edit to a `@riverpod` file within 90s → hook exits 0 in ~0.04s (debounced). ✅
4. `cd apps/mobile && flutter analyze` clean after codegen. ✅

## References

- `SPRINT-M2-AI-HARNESS.md` §Fase 2.
- ADR-0018 — Stop-hook family (analyze, dto-mirror, adr-drift) that this PostToolUse hook complements.
- ADR-0012 — lefthook + Conventional Commits; clarifies that hooks at the agent-turn boundary are distinct from hooks at the git-commit boundary.
- Claude Code hooks docs — `code.claude.com/docs/en/hooks-guide` (PostToolUse contract).
- Riverpod codegen docs — `riverpod.dev/docs/concepts/about_code_generation`.
