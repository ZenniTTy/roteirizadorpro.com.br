# Session 2026-05-19-14 — harness-wave-a

## Metadata

- **Date**: 2026-05-19 (America/Sao_Paulo)
- **Sequence**: 14
- **Agent**: Claude Code (Opus 4.7, 1M context)
- **Human**: Eduardo
- **Topic**: harness-wave-a
- **Duration**: ~1h30m
- **Related ADRs**: ADR-0018 (new), ADR-0012 (extended), ADR-0013 (mechanized)
- **Related TODO items**: harness modernization (cross-cutting, no specific TODO entry pre-session)

## Goal of the Session

Eduardo asked to modernize the `.claude/` harness with auto-validation practices, separation of agent responsibilities, and instrumentation of the spec-driven workflow. The agreed scope was Wave A only: in-loop sensors that catch drift at agent-turn boundary instead of waiting for Lefthook at commit time. Wave B (spec/plan templates + `/new-spec` `/new-plan` skills) deferred to a future session.

## What Was Done

- **Audited the existing harness end-to-end** before proposing anything: read every `.claude/agents/*.md`, every `.claude/hooks/*.sh`, every `.claude/skills/*/SKILL.md`, full `M2-SLICE-CHECKLIST.md`, `AGENTS.md`, `docs/03-CONVENTIONS.md`, and structural slices of the slice-2 plan/spec/TODO. First pass produced a 13-item plan; second pass against full evidence revised it to 7 items by reclassifying 4 as false positives, 3 as partial.
- **Filed ADR-0018** (`docs/decisions/0018-harness-auto-validation.md`) documenting the four options considered (do-nothing, per-edit blocking, Stop-batch non-blocking, Lefthook-only), the chosen Option C, and the boundary it extends from ADR-0012 (Claude hooks own intra-turn signal; Lefthook owns commit-boundary enforcement).
- **Authored three Stop-matcher hooks** under `.claude/hooks/`:
  - `analyze-changed-dart.sh` — runs `flutter analyze --no-pub` over `.dart` files edited this turn in `apps/mobile/lib/`.
  - `check-dto-mirror.sh` — materializes the ADR-0013 contract by grep'ing `// Mirror of:` headers in `apps/mobile/lib/features/**/data/dto/*.dart` against the edited `apps/backend/src/<feature>/schemas.ts` files.
  - `warn-adr-drift.sh` — when `pubspec.yaml`, any `package.json`, `prisma/schema.prisma`, or `infra/docker-compose.yml` was edited this turn, checks `git status --porcelain docs/decisions/` for a new/modified ADR and warns if none.
- All three hooks are **non-blocking** (exit 0 silent, exit 1 warn, never exit 2 — `block-env.sh` keeps the exclusive blocking-exit contract).
- **Bug found and fixed during validation**: macOS shipped bash 3.2.57 and the initial implementation used `mapfile` (bash-4 builtin). Refactored to `while IFS= read` + `xargs` + `grep -E` for portability. Confirmed `bash -n` clean on all three.
- **Authored the `/verify-slice` skill** (`.claude/skills/verify-slice/SKILL.md`) — read-only orchestrator that runs `flutter analyze`, `flutter test`, `bun typecheck`, dispatches `prototype-fidelity-checker` + `adr-guardian` as parallel subagents, and consolidates a single Markdown report. `allowed-tools:` allowlist enforces read-only at the harness level.
- **Wired the three hooks** under a new `Stop` matcher in `.claude/settings.json` with timeouts 30/10/10s.
- **Updated `CLAUDE.md`** with a new "In-Loop Auto-Validation (ADR-0018)" section under "Project-Specific Critical Rules" and a `/verify-slice` pointer in "Verify Your Work".
- **Smoke-tested all three hooks in six real scenarios** before any commit:
  - empty input → all exit 0 silent ✅
  - transcript with non-existent Dart path → all exit 0 silent ✅
  - transcript with real `optimize_route_page.dart` (the pre-existing untracked file) → analyze exit 1 + reported 3 real `info` issues (`prefer_const_constructors` ×2, `unnecessary_brace_in_string_interps` ×1) ✅
  - transcript with `pubspec.yaml` edit + ADR-0018 in working tree → warn-adr exit 0 ✅
  - transcript with `pubspec.yaml` edit + ADR-0018 temporarily hidden → warn-adr exit 1 + full warning message ✅
  - transcript with `apps/backend/src/routes/schemas.ts` edit → check-dto exit 1 + identified `apps/mobile/lib/features/stops/data/dto/stop_dto.dart` as the orphaned mirror ✅
- **Refined the transcript-only signal**: first iteration combined `transcript_path` events with `git diff --name-only HEAD` and `git ls-files --others` as fallback. Real testing showed that fallback was too aggressive — it caught the pre-existing untracked `optimize_route_page.dart` on every Stop, generating false positives. Final design: transcript is the only signal source; if `transcript_path` is missing or empty, exit 0 immediately. This is the right trade-off because the harness always provides `transcript_path` per Anthropic's hooks spec, and a missing one means we should not guess.
- **Landed three Conventional Commits**, all passing Lefthook + commitlint without `--no-verify`:
  - `f21b86d` — `docs(decisions): add adr-0018 harness auto-validation`
  - `b623d48` — `feat(claude): add stop hooks and verify-slice skill`
  - `f0bb080` — `docs(claude): wire adr-0018 stop hooks into operating manual`

## Decisions Made

1. **Wave-A only this session.** Wave B (spec/plan template extraction + `/new-spec` `/new-plan` skills) deferred. Reason: rolling both into one session risks scope drift and dilutes the ADR; harness signal is the higher-leverage change and benefits from landing before any spec workflow change.
2. **Stop matcher over PostToolUse for the new hooks.** Per-edit `flutter analyze` is 2-5s warm — across a 25-commit slice the cumulative latency in the agent's critical path would have been 2-3 minutes of wait. Stop matcher pays the cost once per turn at the natural pause where the human is reading output anyway. Documented in ADR-0018 §Options.
3. **Non-blocking by default.** Only `block-env.sh` keeps the `exit 2` blocking contract; the three new hooks use `exit 1` (warn) or `exit 0` (silent). A blocking warning creates pressure to `--no-verify` mentality; this repo already enforces hard rules at Lefthook and via `adr-guardian` pre-PR.
4. **Transcript-only signal, no working-tree fallback.** Discovered during smoke-test that `git ls-files --others` caught pre-existing untracked files (the `optimize_route_page.dart` from before the session). False positives every Stop would erode trust in the hooks. Trade-off: if Anthropic ever invokes a Stop hook without `transcript_path`, the hooks silently no-op — that's acceptable because the hooks are signal, not enforcement.
5. **`/verify-slice` is pure orchestration, not enforcement.** It does not commit, does not open PRs, does not propose fixes. Verdict is GO / GO WITH WARNINGS / NO-GO. The human owns the action. `allowed-tools:` allowlist enforces read-only at the harness level so future agents cannot violate this contract.

## Open Questions Left

- [ ] Should Wave B follow soon? Eduardo confirmed pause-and-await for Wave B; the materials are ready (spec and plan from slice 2 are exemplary candidates for template extraction).
- [ ] The `apps/mobile/lib/features/stops/presentation/optimize_route_page.dart` flagged by the analyze hook has 3 real `info` issues (`prefer_const_constructors` ×2, `unnecessary_brace_in_string_interps` ×1). This file was already untracked at session start (not authored by this session). Belongs to in-progress slice-2 sub 2d work; the implementer who lands the screen should fix or document.
- [ ] Should `analyze-changed-dart.sh` ever escalate from `info` to error level? Currently it surfaces all severity bands the same way. For slice-1 lessons (INTERNET permission) the relevant signal was `error`; for slice-2 it's `info`. Leaving uniform for now — re-evaluate after the next slice closes.

## Files Changed

**Created**:
- `docs/decisions/0018-harness-auto-validation.md`
- `.claude/hooks/analyze-changed-dart.sh`
- `.claude/hooks/check-dto-mirror.sh`
- `.claude/hooks/warn-adr-drift.sh`
- `.claude/skills/verify-slice/SKILL.md`
- `docs/sessions/2026-05-19-14-harness-wave-a.md` (this file)

**Modified**:
- `.claude/settings.json` — added Stop matcher with the three hooks (timeouts 30/10/10)
- `CLAUDE.md` — added "In-Loop Auto-Validation (ADR-0018)" section + `/verify-slice` pointer
- `docs/sessions/0001-INDEX.md` (in this session-end commit)
- `TODO.md` (in this session-end commit)

**Deleted**: none.

## Commits Pushed

```
f21b86d docs(decisions): add adr-0018 harness auto-validation
b623d48 feat(claude): add stop hooks and verify-slice skill
f0bb080 docs(claude): wire adr-0018 stop hooks into operating manual
<this commit> docs(sessions): harness-wave-a
```

Note: these were committed locally on `feat/m2-slice-2-telas-core` but **not pushed** during the session per the session-end protocol's default. Push happens deliberately by the human or in the slice-2 PR open step.

## Hand-off Notes for Next Session

- **Branch state**: `feat/m2-slice-2-telas-core` advanced from `7437917` (slice-2 sub-2d in-flight) by 4 commits — three feature/doc commits + this session-end. The slice-2 work itself is untouched; the harness additions are orthogonal.
- **The three new Stop-hooks are live for any new session in this repo.** They will fire automatically. If they emit unexpected warnings on the next session's first turn, investigate before silencing — they were validated against six real scenarios.
- **`/verify-slice` is callable** but not yet exercised end-to-end against a real slice. The first slice-2 PR open will be its first real run; if any sharp edges surface there, they'll be cheap to fix.
- **Wave B is the next harness piece** if Eduardo greenlights it. Scope: extract `docs/superpowers/specs/0000-template.md` and `docs/superpowers/plans/0000-template.md` from the exemplary slice-2 artifacts, add `/new-spec` and `/new-plan` skills. Estimated session: ~1h. The slice-2 spec (479 lines, 17 H2 sections) and plan (6127 lines, 42 tasks with TDD pattern) are excellent reverse-engineering candidates.
- **Slice-2 work itself**: per `TODO.md`, sub 2d (Optimization + Nav, Tasks 26-32) and sub 2e (Periféricos, Tasks 33-34) remain pending. The untracked `optimize_route_page.dart` belongs to Task 30 (ScreenOptimizeRoute) — its 3 analyzer infos are now flagged by the hook and should be fixed when that task closes.

## Reference Material Used

- ADR-0012 (Lefthook + Commitlint + Commitizen tooling boundary) — extended in ADR-0018.
- ADR-0013 (API contract source of truth — TypeBox → Dart mirror) — mechanized by `check-dto-mirror.sh`.
- `docs/M2-SLICE-CHECKLIST.md` §Verification — packaged into `/verify-slice`.
- `CLAUDE.md` → "Stack — Locked Versions" + "Any change requires a new ADR" — shadowed by `warn-adr-drift.sh`.
- Anthropic Claude Code hooks documentation (`https://code.claude.com/docs/en/hooks-guide`) — Stop matcher semantics, JSON stdin schema, exit-code conventions.
- Tech Lead's Club "Harness Engineering" framing — feedforward / action / feedback placement of new sensors.
- Existing project hooks (`block-env.sh`, `format-dart.sh`, `reinject-roadmap.sh`) — read in full for stylistic continuity. New hooks match their `set -euo pipefail` + `jq` + early-exit patterns.
- Existing project skills (`commit`, `session-end`, `new-flutter-feature`) — read in full to match the `disable-model-invocation: true` + `allowed-tools:` frontmatter convention.
