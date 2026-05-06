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

- [2026-05-05-03 — documentation-backbone](./2026-05-05-03-documentation-backbone.md) — Authored full documentation backbone: foundation files, README, TODO, SECURITY, CODE_OF_CONDUCT, PR template, ten ADRs, and 01-PROJECT / 02-ARCHITECTURE / 04-ROADMAP-M1 / 04-ROADMAP-M2 / 06-DISASTER-RECOVERY docs.
- [2026-05-05-02 — claude-md-rewrite](./2026-05-05-02-claude-md-rewrite.md) — Rewrote CLAUDE.md to comply with Karpathy's four principles and Anthropic's official Claude Code best practices; migrated detail-heavy sections into focused docs.
- [2026-05-05-01 — bootstrap-claude-md](./2026-05-05-01-bootstrap-claude-md.md) — Initial repo bootstrap: stack validation via Context7, CLAUDE.md authored, sessions and decisions structure created.
