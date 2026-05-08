# Session Log Index

This is the chronological index of all AI session logs in this repository. Each entry links to a detailed log file.

## How to Read This Index

- Most recent at the top.
- Format: `YYYY-MM-DD-NN — <topic>` followed by a one-line summary.
- For full context on any session, open the linked file.

## How to Add an Entry

When ending a session, the AI agent appends one line under "Sessions" below, immediately after the heading (most recent first):

```
- [YYYY-MM-DD-NN — <topic>](./YYYY-MM-DD-NN-<topic>.md) — <one-line summary>
```

Then commits both the new session file AND this updated index in the same commit.

## Session Log Template

Every new session log file follows `0000-template.md` as its skeleton.

## Sessions

- [2026-05-08-02 — hooks-and-skills-setup](./2026-05-08-02-hooks-and-skills-setup.md) — Implemented the recommendations from `claude-automation-recommender`: Claude Code PreToolUse hook blocking `.env*` edits, PostToolUse hook auto-formatting Dart files in `apps/mobile/`, two read-only subagents (`prototype-fidelity-checker`, `adr-guardian`), two user-only skills (`session-end`, `new-flutter-feature`), and replaced the blanket `.claude/` rule in `.gitignore` with a granular pattern so team-shared automations are committed. Verified Riverpod 3 + go_router patterns via Context7; verified hook semantics via the `claude-code-guide` subagent.
- [2026-05-08-01 — phase-1-foundations](./2026-05-08-01-phase-1-foundations.md) — Executed Phase 1 of the M1 roadmap: backend (Fastify v5 + TypeBox + Prisma 7) skeleton, landing (Next.js 14 + Tailwind), mobile (Flutter source files; flutter create deferred), and `infra/docker-compose.yml` with postgres + redis healthy and graphhopper opt-in via `routing` profile. Adapted `/saas-project-blueprint` to synthesize Blueprint.md from existing ADRs; skipped `/saas-project-scaffold` due to stack collisions.
- [2026-05-07-04 — docs-cleanup](./2026-05-07-04-docs-cleanup.md) — Realigned the docs with the approved Claude Design prototype, focused the roadmap on M1 (deadline 2026-05-26), removed redundant/obsolete files, renumbered to contiguous order, established prototype as canonical UI source.
- [2026-05-05-03 — documentation-backbone](./2026-05-05-03-documentation-backbone.md) — Authored full documentation backbone: foundation files, README, TODO, SECURITY, CODE_OF_CONDUCT, PR template, ten ADRs, and 01-PROJECT / 02-ARCHITECTURE / 04-ROADMAP-M1 / 04-ROADMAP-M2 / 06-DISASTER-RECOVERY docs.
- [2026-05-05-02 — claude-md-rewrite](./2026-05-05-02-claude-md-rewrite.md) — Rewrote CLAUDE.md to comply with Karpathy's four principles and Anthropic's official Claude Code best practices; migrated detail-heavy sections into focused docs.
- [2026-05-05-01 — bootstrap-claude-md](./2026-05-05-01-bootstrap-claude-md.md) — Initial repo bootstrap: stack validation via Context7, CLAUDE.md authored, sessions and decisions structure created.
