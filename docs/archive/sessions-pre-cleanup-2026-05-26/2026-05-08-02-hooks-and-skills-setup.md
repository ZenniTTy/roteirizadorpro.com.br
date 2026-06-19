# Session Log

## Metadata

- **Date**: 2026-05-08 (America/Sao_Paulo)
- **Sequence**: 02
- **Agent**: Claude Code (Opus 4.7, VS Code extension)
- **Human**: Eduardo
- **Topic**: hooks-and-skills-setup
- **Duration**: ~2h
- **Related ADRs**: ADR-0011 (Bun — referenced by hook scripts)
- **Related TODO items**: discovered tasks added (stripe disable, lefthook reconciliation, naming convention mismatch).

## Goal of the Session

Run the `claude-automation-recommender` against the repo and implement the recommendations: Claude Code hooks, subagents, and skills tailored to the Roteirizador Pro stack (Flutter + Riverpod 3 + Fastify + Prisma + Next.js). Convert the rules in CLAUDE.md from "trust the agent to remember" to "enforced by tooling."

## What Was Done

- Verified the official Claude Code hooks JSON schema and event semantics via the `claude-code-guide` subagent (source: `https://code.claude.com/docs/en/hooks.md`). Switched my mental model from env-vars to JSON-on-stdin parsed with `jq`, and from "matcher only" to `matcher` plus optional `if` glob.
- Validated current Riverpod 3 + go_router patterns via Context7: `/rrousselgit/riverpod/riverpod-v3.0.2` and `/websites/pub_dev_packages_go_router`. Confirmed the `@riverpod` annotation + `part 'X.g.dart'` codegen pattern, the `Ref` parameter (no longer `XRef`), the class form (`extends _$Foo`) vs function form, and the `GoRoute(path:, builder:, routes:)` declarative shape.
- Authored `.claude/hooks/block-env.sh` (PreToolUse, exit 2 on `.env*` matches, exit 0 for `.env.example`). Tested with six cases (`.env`, `.env.example`, `.env.production`, regular `.ts`, missing input, format-dart on non-Dart).
- Authored `.claude/hooks/format-dart.sh` (PostToolUse, runs `dart format` only when the path is a `.dart` file inside `apps/mobile/`).
- Authored `.claude/settings.json` wiring both hooks under `PreToolUse` / `PostToolUse` with the `Edit|Write|MultiEdit` matcher, with explicit timeouts (5s and 10s).
- Authored `.claude/skills/session-end/SKILL.md` (`disable-model-invocation: true`) plus the `next-session-id.sh` helper that echoes `YYYY-MM-DD-NN` using `TZ=America/Sao_Paulo` and the next available sequence within today (verified: `2026-05-08-02`).
- Authored `.claude/skills/new-flutter-feature/SKILL.md` (`disable-model-invocation: true`) — scaffolds `apps/mobile/lib/features/<feature>/` with a Riverpod 3 controller and a `ConsumerWidget` page, aligned with the strict lints in `apps/mobile/analysis_options.yaml`.
- Authored `.claude/agents/prototype-fidelity-checker.md` — a read-only subagent that compares Flutter screens against `prototipo/tokens.js` and `prototipo/screens-*.jsx` (the canonical UI source per CLAUDE.md), reporting divergences as a punch list.
- Authored `.claude/agents/adr-guardian.md` — a read-only subagent that scans diffs for stack-affecting changes (`package.json`, `pubspec.yaml`, `schema.prisma`, `infra/`) and blocks PRs lacking a matching ADR in `docs/decisions/`.
- Detected `.claude/` blanket-ignored at `.gitignore:92`. Replaced with a granular pattern: `.claude/settings.local.json`, `.claude/state/`, `.claude/cache/` ignored; `settings.json`, `hooks/`, `agents/`, `skills/` versioned. Verified via `git check-ignore`.
- Disabled `firebase@claude-plugins-official` in `~/.claude/settings.json` (already shown as `false` after the first read). Attempted to disable `stripe` similarly; the harness blocked the edit as self-modification. Surfaced as a follow-up in `TODO.md`.
- Two-stage commit: `chore(claude): wire hooks, subagents, and skills for the team` for the automations + `.gitignore`, then this `docs(sessions): hooks-and-skills-setup` to close the protocol.

## Decisions Made

1. **Replaced post-edit typecheck with `dart format` only.** Running `tsc --noEmit` or `flutter analyze` on every edit costs 10–30 s and slows iteration. A manual `/verify` slash command (or Lefthook pre-commit per ADR-0012) is a better fit for full project checks. Hooks should be cheap.
2. **Replaced the blanket `.claude/` `.gitignore` rule with a granular pattern.** Without this, `.claude/settings.json`, `hooks/`, `agents/`, and `skills/` cannot reach the team — the value of "team-shared automations" requires version control. Per-user state still hides under `settings.local.json` and the optional `state/` and `cache/` subdirs.
3. **Marked `session-end` and `new-flutter-feature` as `disable-model-invocation: true`.** Both have side effects (commits, scaffolding) that should require explicit user intent rather than agent guess. The two new subagents stay model-invocable because they are read-only reviewers.
4. **Did not touch ADR-0012 or its lefthook/commitlint files (`bun.lock`, `lefthook.yml`, `commitlint.config.cjs`, root `package.json`).** They appeared untracked during this session but are a separate work stream; bundling them would have violated "Surgical Changes."

## Open Questions Left

- [ ] How should Claude Code hooks coexist with Lefthook pre-commit when ADR-0012 lands? Different scopes (Claude-only vs all contributors), but worth a short paragraph in CLAUDE.md or ADR-0012 to document the boundary.
- [ ] `docs/03-CONVENTIONS.md` table claims Dart files are kebab-case (`user-profile.dart`) but every actual file in the repo is snake_case (`register_page.dart`, `app_theme.dart`, `rp_button.dart`). Decide which is canonical and either rename files or update the table.
- [ ] Should the `new-flutter-feature` skill auto-generate `data/` and `domain/` layers, or leave them optional? Today the skill creates only `application/` and `presentation/`; usage in Phase 2 will tell.

## Files Changed

**Created**:
- `.claude/settings.json`
- `.claude/hooks/block-env.sh`
- `.claude/hooks/format-dart.sh`
- `.claude/skills/session-end/SKILL.md`
- `.claude/skills/session-end/next-session-id.sh`
- `.claude/skills/new-flutter-feature/SKILL.md`
- `.claude/agents/prototype-fidelity-checker.md`
- `.claude/agents/adr-guardian.md`
- `docs/sessions/2026-05-08-02-hooks-and-skills-setup.md` (this file)

**Modified**:
- `.gitignore` (Claude Code section: granular)
- `TODO.md` (Done entry + three discovered tasks + last-updated header)
- `docs/sessions/0001-INDEX.md` (new session entry at top)

**Deleted**:
- none

## Commits Pushed

```
bb868b7 chore(claude): wire hooks, subagents, and skills for the team
<this>  docs(sessions): hooks-and-skills-setup
```

(Local only — not pushed to `origin/develop` per CLAUDE.md.)

## Hand-off Notes for Next Session

- **Branch**: `develop`. After these two commits, four ahead of `origin/develop`.
- **Hooks are now active** for any Claude Code session in this repo. The next agent will see `.env*` edits blocked (except `.env.example`) and Dart files in `apps/mobile/` auto-formatted on save. Both behaviors are tested.
- **New subagents/skills are available** to invoke:
  - `prototype-fidelity-checker` — call before any UI-related PR.
  - `adr-guardian` — call before any PR that touches manifests or `infra/`.
  - `session-end` (user-only) — call at the end of any meaningful session; argument is a kebab-case topic.
  - `new-flutter-feature` (user-only) — call when scaffolding a new feature folder under `apps/mobile/lib/features/`.
- **Pending manual action**: open `~/.claude/settings.json` and set `"stripe@claude-plugins-official": false` (line 17). The in-session edit was blocked by the harness's self-modification guard. Tracked in TODO.
- **ADR-0012 (`docs/decisions/0012-dx-tooling.md`) plus `lefthook.yml`, `commitlint.config.cjs`, root `package.json`, `bun.lock`** were untracked at session start and remain untracked. They are a separate work stream proposing Lefthook + Commitlint + Commitizen + a shared VS Code workspace. Lefthook is already installed locally (its banner ran on the chore commit and commitlint validated the message), so the implementation files exist on disk but have not been committed.
- **Convention drift to resolve before Phase 2 deepens**: the Dart-file naming mismatch in `docs/03-CONVENTIONS.md`. Today the repo writes `register_page.dart` and the doc says `user-profile.dart`. Consensus expected before more `features/` folders land.

## Reference Material Used

- Anthropic — Claude Code hooks docs: `https://code.claude.com/docs/en/hooks.md` (queried via the `claude-code-guide` subagent for JSON schema, exit-code semantics, matcher syntax, env vars).
- Context7 — `/rrousselgit/riverpod/riverpod-v3.0.2`: `@riverpod` codegen, `Notifier` class form vs function form, `Ref` parameter.
- Context7 — `/websites/pub_dev_packages_go_router`: declarative `GoRoute` + nested `routes` shape (no `StatefulShellRoute` example needed for the skill).
- Repo files read for context: `CLAUDE.md`, `TODO.md`, `docs/03-CONVENTIONS.md`, `docs/sessions/0000-template.md`, `apps/mobile/analysis_options.yaml`, `apps/mobile/pubspec.yaml`, `apps/backend/package.json`, `prototipo/tokens.js`, `docs/decisions/0000-template.md`, `.gitignore`.
