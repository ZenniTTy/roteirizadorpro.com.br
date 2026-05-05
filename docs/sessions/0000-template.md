# Session Log Template

> Copy this file when starting a new session log. Rename to `YYYY-MM-DD-NN-<topic>.md`.

## Metadata

- **Date**: YYYY-MM-DD (America/Sao_Paulo)
- **Sequence**: NN (zero-padded within the day)
- **Agent**: <Claude web | Claude Code | Cursor | other>
- **Human**: Eduardo
- **Topic**: <2–4 word topic>
- **Duration**: ~<H>h<MM>m
- **Related ADRs**: <ADR-XXXX, ADR-YYYY> or `none`
- **Related TODO items**: <list> or `none`

## Goal of the Session

One short paragraph stating what the session set out to accomplish.

## What Was Done

Bullet list of concrete actions taken, in chronological order. Examples:

- Validated Library X via Context7, found version mismatch with my recommendation.
- Authored `docs/decisions/0004-prisma-7-orm.md`.
- Configured `.gitignore` for Node + Flutter.
- Implemented `POST /auth/login` with TypeBox validation.

## Decisions Made

Numbered list. Each item is a decision and its rationale in 1–2 lines. If the decision is significant, it should also become an ADR in `docs/decisions/`.

1. Decision X — Rationale.
2. Decision Y — Rationale.

## Open Questions Left

Things the AI did not resolve and need the human or the next session.

- [ ] Question 1
- [ ] Question 2

## Files Changed

List of files created or modified, by category:

**Created**:
- `path/to/file`

**Modified**:
- `path/to/file`

**Deleted**:
- `path/to/file`

## Commits Pushed

```
<hash> <conventional commit message>
<hash> <conventional commit message>
```

## Hand-off Notes for Next Session

What the next agent should know to pick up where this session ended. Include current branch, any in-progress work, blockers.

## Reference Material Used

- Context7 queries (library + topic).
- Web fetches (URL).
- Other docs read.
