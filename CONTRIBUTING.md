# Contributing to Roteirizador Pro

> **Audience:** Eduardo and any AI agent acting on this repository (Claude Code, Cursor, Claude web). There are no external human contributors at this stage.

## Workflow

The project follows: **Research → Plan → Execute → Review → Ship.**

For non-trivial changes (anything beyond a typo or one-liner):

1. **Research.** Read relevant existing code and docs. Use Context7 for any external library question.
2. **Plan.** Write a brief plan in chat (or in plan mode if using Claude Code). State assumptions explicitly.
3. **Execute.** Implement the minimum code that satisfies the plan.
4. **Review.** Run linters, tests, and verify against the plan. For UI work, take a screenshot and compare to the spec.
5. **Ship.** Commit thematically and push.

For trivial changes (typo, log line, rename), skip planning and proceed directly.

## Branching

| Branch | Purpose | Protection |
|---|---|---|
| `main` | Production | Protected: only via PR from `develop` |
| `develop` | Integration | Default branch; bootstrap commits land here |
| `feat/<name>` | Feature work | Created when product code begins |
| `fix/<name>` | Bug fixes | Created when bug fix is non-trivial |
| `docs/<name>` | Doc-only changes | Optional — small doc tweaks may go to `develop` |

**Current phase:** during the bootstrap (docs and infra setup), commits go directly to `develop`. Once product code starts (Sprint 1 of M1), we switch to branch-per-feature with PRs into `develop`.

## Commit Messages

Conventional Commits format:

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

### Types

| Type | Use |
|---|---|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code change without changing behavior |
| `docs` | Documentation only |
| `chore` | Build, deps, repo housekeeping |
| `style` | Formatting, no logic change |
| `test` | Adding or fixing tests |
| `perf` | Performance improvement |
| `build` | Build system or external dependency change |
| `ci` | CI/CD configuration |

### Scopes

Match the affected area: `mobile`, `backend`, `infra`, `landing`, `admin`, `adr`, `deps`, `claude`, `sessions`, `lgpd`.

### Subject rules

- Imperative mood: `add`, not `added`.
- Lowercase first word.
- No trailing period.
- Max 72 characters.

### Examples

```
docs(adr): add ADR-0004 prisma 7 orm choice
feat(backend): add JWT auth middleware
fix(mobile): correct OCR regex for CEP extraction
chore(deps): bump fastify from 5.0.0 to 5.1.0
```

## Pre-commit Sequence

Before any commit, run in this order:

1. `git status` — know the actual state.
2. `git diff --stat` — review what changed at file-level.
3. `git diff` (selected paths) — read the actual changes.
4. Run linter and formatter on changed files.
5. Run relevant tests.
6. `git add <specific paths>` — never `git add .` blindly.
7. `git commit -m "<conventional message>"`.
8. `git push origin <branch>`.

## Mac Workflow (osascript)

All Git operations on the Mac are executed by AI agents via the `Control your Mac:osascript` tool. Never paste shell commands for the human to run manually.

```applescript
do shell script "cd '/Users/eduardorodrigues/Downloads/Elo Vision Digital/[EVD] - Meus Projetos/[APP] - Entrega Smart' && git status"
```

The repo path contains spaces and brackets. Always single-quote the path inside `do shell script`.

## Push Rules

- ❌ **Never `git push --force` to `develop` or `main`.**
- ✅ Force-push allowed only on personal feature branches that haven't been merged.
- ❌ Never amend or rebase commits already pushed and possibly on another machine.
- ❌ Never `git add .` without first checking `git status` for unintended files.
- ✅ When a secret is accidentally committed: rotate it immediately, scrub history with `git filter-repo`, force-push (the only acceptable force-push reason), and document the incident in a session log.

## Pull Requests (when product code begins)

- One vertical slice per PR (a tracer bullet that goes through all relevant layers).
- Title follows Conventional Commits format.
- Description includes: what changed, why, how to test, screenshots if UI.
- The PR template lives at `.github/pull_request_template.md`.

## Code Review (self-review)

Even working solo, every change deserves a fresh-eyes pass. The Anthropic-recommended pattern: after implementing, start a fresh AI session and ask it to review the diff. Fresh context catches what tunnel-vision misses.

## Issue Tracking

For now, all work is tracked in `TODO.md` at the repo root. After the GitHub repo is transferred to the client, GitHub Issues becomes the source of truth for backlog.

## Session Logs

Every meaningful AI session ends with a log in `docs/sessions/`. See `CLAUDE.md` for the protocol.

## Questions

When in doubt, **ask before acting**. Document the answer in the relevant doc or ADR so the question doesn't need to be asked again.
