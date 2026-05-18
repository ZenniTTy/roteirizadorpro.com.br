---
name: commit
description: Create a Conventional Commits commit using the project's allowed scope-enum (commitlint.config.cjs). Use when the user asks to commit changes, says "commita", "commit", or has staged work ready to land. Never bypasses hooks (lefthook + commitlint must pass). Argument is optional — a hint about the change (e.g. "add reinject-roadmap hook"); without it, the skill infers the message from the diff and confirms before committing.
disable-model-invocation: true
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git commit:*), Bash(git restore:*)
---

# /commit — Conventional Commit, no TTY required

Replaces `bun run commit` (commitizen) for AI-driven sessions where no interactive TTY is available. Follows the same Conventional Commits + scope-enum contract enforced by `commitlint.config.cjs` and lefthook's `commit-msg` job.

## Inputs

- `$ARGUMENTS` (optional): a short hint about what changed. If absent, infer from `git diff --staged`.

## Workflow

### 1. Inspect state

```bash
git status --short
git diff --staged
```

If nothing is staged, look at the working-tree diff (`git diff`) and confirm with the user which files to stage. **Never `git add -A` or `git add .`** — list files explicitly to avoid sweeping in `.env*` or keystores (already blocked by `block-env.sh`, but defense in depth).

### 2. Choose type and scope

**Allowed types** (per `@commitlint/config-conventional`): `feat`, `fix`, `refactor`, `docs`, `chore`, `style`, `test`, `perf`, `build`, `ci`.

**Allowed scopes** (per `commitlint.config.cjs` `scope-enum`):

```
mobile, backend, landing, infra, auth, routes, stops, subscriptions, payments,
geocoding, graphhopper, paywall, ocr, voice, prototipo, docs, decisions,
sessions, claude, deps, tooling, ci, vscode, fix, chore,
pix, efi, webhook, lgpd, admin, map, release
```

If the change needs a scope not on this list, **stop and ask the user** whether to add it to `commitlint.config.cjs` in this commit (or a precursor commit). Don't invent scopes.

### 3. Write the message

Format:

```
<type>(<scope>): <subject in lowercase, imperative, ≤ 72 chars, no period>

<optional body explaining WHY, wrapped at 72 cols>
```

Examples grounded in this repo:

- `feat(mobile): add ScreenAddStop with text + voice entry`
- `chore(claude): add SessionStart compact hook for roadmap re-injection`
- `fix(backend): close pool on SIGTERM to avoid hanging deploys`
- `docs(sessions): m2-slice-2-foundation`

### 4. Stage and commit

```bash
git add <file> [<file> ...]   # explicit files only
git commit -m "$(cat <<'EOF'
<type>(<scope>): <subject>

<optional body>
EOF
)"
```

Use the HEREDOC form so multi-line bodies are preserved exactly.

### 5. Verify

```bash
git log -1 --stat
```

Confirm:
- `commit-msg` lefthook job passed (commitlint accepted scope + subject).
- `pre-commit` lefthook job passed (typecheck/lint/analyze for the changed app).
- File list matches what the user expected.

If a hook failed, **never** retry with `--no-verify`. Fix the underlying issue and create a NEW commit (per CLAUDE.md Git Protocol).

## Constraints

- **Never amend** an existing commit unless the user explicitly says "amend".
- **Never `git push`** from this skill — pushing is a separate, intentional step.
- **Never bundle `docs/sessions/`, `TODO.md`, and `docs/sessions/0001-INDEX.md`** into a non-session commit. Those three travel together via the `session-end` skill, per CLAUDE.md "Session End Protocol".
- **One logical change per commit.** If the staged diff covers two concerns, split before committing.

## Anti-patterns

- `git add -A` / `git add .` — too broad; sweeps secrets.
- Inventing a scope not in `scope-enum` — commitlint will reject, wasting the round-trip.
- `git commit --no-verify` — hooks are not advisory.
- Sentence case in the subject — `subject-case` rule is `lower-case`.
- Period at the end of the subject — Conventional Commits forbids.
