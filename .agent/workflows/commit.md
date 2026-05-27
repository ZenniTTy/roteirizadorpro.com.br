---
description: Create a Conventional Commit for staged changes in this repo, following the project's commit style and Lefthook gates.
---

# /commit

Create a new Conventional Commit for the work currently staged (or about to be staged). Never amend; never `--no-verify`.

## Steps

1. Run these in parallel:
   - `git status` (never `-uall` — large repo)
   - `git diff` (staged + unstaged)
   - `git log -n 10 --oneline` (style reference)

2. Read the diff carefully. Determine:
   - **Type**: `feat` | `fix` | `docs` | `chore` | `refactor` | `test` | `perf` | `build` | `ci`
     - `feat` = wholly new feature
     - `fix` = bug fix
     - `chore` = housekeeping (deps, config, repo plumbing)
     - `refactor` = behavior-preserving restructure
   - **Scope** (optional): `mobile`, `backend`, `landing`, `infra`, `docs`, `sessions`, `decisions`, etc.
   - **Subject**: imperative, ≤ 72 chars, no trailing period.

3. **Safety checks before staging:**
   - Refuse to stage `.env*` (except `.env.example`), `*.jks`, `*.p12`, `*.pem`, `key.properties`, `google-services.json`, `GoogleService-Info.plist`.
   - If any of those are in the diff, surface it and ask the user to remove them.
   - If `pubspec.yaml`, `package.json`, `apps/backend/prisma/schema.prisma`, `docker-compose*.yml`, or any file under `infra/` is changed but no new ADR exists under `docs/decisions/`, surface this and ask the user to confirm (per ADR-0012 and the `warn-adr-drift.sh` hook that Claude Code runs).

4. Stage explicitly — by filename. Never `git add -A` or `git add .`.

5. Draft the message. Body should explain the WHY in 1–2 sentences. Use HEREDOC for multi-line:

   ```
   git commit -m "$(cat <<'EOF'
   <type>(<scope>): <subject>

   <body explaining why, not what>
   EOF
   )"
   ```

6. Run `git commit`. Lefthook will run typecheck/lint/analyze on the changed app.

7. If the commit fails due to the pre-commit hook:
   - **DO NOT use `--amend`.** The commit didn't happen; amending would modify the PREVIOUS commit.
   - Fix the issue, re-stage, create a NEW commit.

8. After success: `git status` to confirm clean tree.

## Report

Print:
- The commit SHA (short).
- The commit message.
- Output of post-commit `git status`.

## Never

- Skip hooks (`--no-verify`).
- Bypass signing (`--no-gpg-sign`).
- Push (`git push`) unless the user explicitly asks.
- Create empty commits.
