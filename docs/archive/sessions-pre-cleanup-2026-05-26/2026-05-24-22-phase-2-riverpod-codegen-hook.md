# Session 22 — M2-AI Phase 2: Riverpod codegen PostToolUse hook

## Metadata

- **Date**: 2026-05-24 (America/Sao_Paulo)
- **Sequence**: 22
- **Agent**: Claude Code (Opus 4.7)
- **Human**: Eduardo
- **Topic**: Phase 2 — PostToolUse Riverpod codegen automation
- **Duration**: ~45m
- **Related ADRs**: ADR-0024 (new), ADR-0018 (extended), ADR-0023 (uses Dart MCP for cross-validation)
- **Related TODO items**: Sprint M2-AI Phase 2

## Goal of the Session

Continue the M2-AI Harness sprint after `/compact`. First, correct the SPRINT-MD + CLAUDE.md handoff language to reflect the new topology decision (Phases 2–7 stay on `feat/m2-ai-harness` and feed PR #8, instead of spawning a new branch off `develop`). Then execute Phase 2: a PostToolUse hook that auto-regenerates `*.g.dart` whenever a `@riverpod`-annotated Dart file is edited.

## What Was Done

- Read SPRINT-MD §"Sprint pause & handoff" and CLAUDE.md header — both said "Phases 2–7 resume on a new branch off `develop`" (stale; superseded by user's last decision pre-`/compact`).
- Rewrote SPRINT-MD status line + handoff section to reflect: stay on `feat/m2-ai-harness`, all new commits feed PR #8 against `feat/m2-slice-2-telas-core`, merge PR #8 only after Phase 7. Updated phase status table (Phase 2 now "próxima", rest enumerated with planned ADRs).
- Updated CLAUDE.md "Last updated" footer to match.
- Committed (`7b973bd`) — `docs(harness): keep M2-AI sprint on feat/m2-ai-harness through phase 7`.
- Read `.claude/hooks/format-dart.sh` (closest analog — also PostToolUse, also `tool_input.file_path` stdin contract) to copy the file-path extraction pattern.
- Authored `.claude/hooks/run-riverpod-codegen.sh`:
  - Stdin JSON → `jq` extracts `tool_input.file_path`.
  - Filter chain: `.dart`, absolute path contains `/apps/mobile/lib/`, not a `.g.dart`, file exists.
  - `grep -E '^@[Rr]iverpod|^part .+\.g\.dart'` — only files participating in codegen qualify.
  - Lock-file debounce (90s window) under `${TMPDIR}` — coalesces burst-edits.
  - Runs `dart run build_runner build --delete-conflicting-outputs` from `apps/mobile`.
  - Non-blocking: exit 0 silent on every path; exit 1 only if `build_runner` itself errors, with last 30 lines of output to stderr.
- `chmod +x` + `bash -n` syntax check ✅.
- Registered in `.claude/settings.json` under `hooks.PostToolUse` (same matcher entry as `format-dart.sh`, timeout 120).
- Three-path smoke test:
  - **Plain Dart** (`apps/mobile/lib/main.dart`): exit 0 silent, no lock file. ✅
  - **`@riverpod` file** (`apps/mobile/lib/core/providers/api_providers.dart`): codegen ran ~60s, `auth_controller.g.dart` mtime bumped, lock file written, exit 0. ✅
  - **Debounce** (same `@riverpod` file again immediately): exit 0 in 0.04s. ✅
- `cd apps/mobile && flutter analyze --no-pub` → "No issues found!" (7.3s).
- Authored `docs/decisions/0024-postuse-riverpod-codegen-hook.md`: 3-option analysis (Stop / PreToolUse / PostToolUse), Decision (Option C), consequences, rollback, verification steps from smoke test.
- Updated CLAUDE.md §"In-Loop Auto-Validation" — retitled to "(ADR-0018 + ADR-0024)", split into Stop hooks (3) + PostToolUse hook (1, this one), added rationale link.
- Updated TODO.md Phase 2 checkbox to `[x]` with summary.
- Updated SPRINT-MD Fase 2 status block to "✅ entregue".

## Decisions Made

1. **Hook event = PostToolUse, not Stop** — codified in ADR-0024. Stop would race against the existing `analyze-changed-dart.sh` Stop hook (codegen could run after analyze, leaving false positives in the analyze report).
2. **Lock-file debounce, 90s window** — not in the original sprint text, added during implementation. A turn that edits 5 providers should not spawn 5 concurrent `build_runner` processes; first qualifying edit runs codegen, subsequent ones within the window skip silently.
3. **Absolute-path requirement** — matches `format-dart.sh`'s existing pattern (`*"/apps/mobile/"*`). Claude Code emits absolute paths in `tool_input.file_path`; relative-path edge cases (manual hook invocation, scripted tests) are accepted as non-firing.

## Open Questions Left

- [ ] None for this phase. Phase 3 (`flutter-test-author` subagent) is next; the mock-library choice (`mocktail` vs `mockito`) still pends an inspection of `apps/mobile/pubspec.yaml` at the start of that phase.

## Files Changed

**Created**:
- `.claude/hooks/run-riverpod-codegen.sh`
- `docs/decisions/0024-postuse-riverpod-codegen-hook.md`
- `docs/sessions/2026-05-24-22-phase-2-riverpod-codegen-hook.md` (this file)

**Modified**:
- `.claude/settings.json` — second entry in `PostToolUse` matcher block.
- `CLAUDE.md` — header "Last updated" + §"In-Loop Auto-Validation" rewrite.
- `docs/sprints/2026-05-24-m2-ai-harness.md` — status line, handoff section, Phase 2 status block, phase table.
- `TODO.md` — Phase 2 checkbox done.

## Cross-References

- ADR-0018 (Stop-hook family) — this PostToolUse hook is the first non-Stop addition to the harness's in-loop validation surface; ADR-0024 explicitly extends ADR-0018.
- ADR-0023 (Dart MCP) — Phase 1 prerequisite; the MCP doesn't run codegen, this hook does.
- ADR-0012 (lefthook layered boundary) — clarifies hook-vs-lefthook responsibility: codegen at the agent-turn boundary now, lefthook still catches the regression case (commit with stale `.g.dart`).
- docs/sprints/2026-05-24-m2-ai-harness.md §Fase 2 — task list this session executed against.
