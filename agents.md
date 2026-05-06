# agents.md — Agent-Specific Rules

Extends `CLAUDE.md`. Read `CLAUDE.md` first, then this file.

## Claude Code

**Startup ritual (mandatory):**
1. Read `CLAUDE.md` → `TODO.md` → `docs/sessions/0001-INDEX.md` (last 3 sessions).
2. Run `git status` before any file operation.
3. Announce the current TODO.md task you are about to work on.

**During a session:**
- Work on one TODO item at a time. Complete it, verify it, commit it, then move to the next.
- Do not batch unrelated work into one commit.
- Run the relevant linter/tests after every change.
- If a change touches the database schema (`schema.prisma`), always run `prisma migrate dev` locally and include the migration file in the same commit.
- If a change touches `infra/docker-compose.yml`, verify the stack comes up cleanly before committing.

**Context7 triggers (non-negotiable):**
Call Context7 before using any of the following for the first time in a session:
- Any `@fastify/*` plugin.
- Any Prisma client method that seems unfamiliar.
- Any `riverpod_generator` annotation.
- GraphHopper API parameters.
- Efi Bank API endpoints.

**Commit format reminder:**
```
<type>(<scope>): <subject in imperative, lowercase, no period, 72 chars max>
```
Scope maps to the affected app: `mobile`, `backend`, `landing`, `infra`, `admin`, `docs`, `adr`, `deps`.

**End of session (mandatory):**
1. Update `TODO.md`: mark completed `[x]`, add discovered tasks `[ ]`.
2. Write session log in `docs/sessions/YYYY-MM-DD-NN-<topic>.md`.
3. Update `docs/sessions/0001-INDEX.md` with a one-line entry.
4. Commit session log + index + updated TODO in one commit: `docs(sessions): <topic>`.
5. Push.

## Cursor

Same rules as Claude Code above. Additionally:

- Do not use Cursor's apply-diff on files you haven't read first.
- Do not auto-accept suggestions that add dependencies not in the locked stack table in `CLAUDE.md` without a Context7 validation first.
- If Cursor proposes a refactor beyond the scope of the current task, decline and add it as a `[ ]` in `TODO.md` for later.

## Claude Web (this interface)

Used for planning, reviewing, and documenting — not primary coding.

- Planning decisions made here must be committed to a doc (ADR, ROADMAP update, or session log) before Claude Code acts on them.
- Do not start coding work in Claude Web that will be continued in Claude Code without a session log handoff note.

## Inter-Agent Handoff Protocol

When the baton passes from one agent to another (or one session to another):

1. The outgoing agent writes the session log with a Hand-off Notes section.
2. The incoming agent reads the last session log before starting.
3. No verbal summaries — always the written log. Chat context is not shared between sessions.

## Forbidden Actions (all agents)

- `git push --force` to `develop` or `main`.
- Committing any file matching `.env*` (except `.env.example`), `*.pem`, `*.p12`, `certs/`.
- Running `prisma migrate reset` on a production database.
- Deleting a migration file from `prisma/migrations/`.
- Installing a package not in the locked stack without an ADR and Context7 validation.
- Generating co-authored-by or attribution metadata in commits.
