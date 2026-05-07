# Session 2026-05-07-04 — docs-cleanup

## Metadata

- **Date**: 2026-05-07 (America/Sao_Paulo)
- **Sequence**: 04
- **Agent**: Claude Code
- **Human**: Eduardo
- **Topic**: Documentation reorganization and M1 alignment
- **Duration**: ~3h
- **Related ADRs**: none new (deferred until M2 conversation)
- **Related TODO items**: M1 entire scope (this session unblocks it)

## Goal of the Session

Realign the entire documentation with three goals:
1. Remove ambiguities, duplications, and obsolete content from the docs.
2. Make the approved Claude Design prototype (`prototipo/`) the canonical UI source.
3. Focus the roadmap on M1 (deadline 2026-05-26) so the next concrete action is `flutter create apps/mobile/`.

## What Was Done

- Audited all 30 docs/markdown files in the repo. Identified ambiguities and outdated references.
- Wrote a design spec at `docs/superpowers/specs/2026-05-07-docs-cleanup-design.md` and got user approval.
- Wrote an implementation plan at `docs/superpowers/plans/2026-05-07-docs-cleanup.md`.
- Tracked the approved prototype in git (`prototipo/`).
- Renamed docs to contiguous numbering (`FEATURES.md` → `04-FEATURES.md`, etc.).
- Moved `logo.png` into `apps/landing/public/`.
- Created `docs/08-ROADMAP.md` (M1-focused) and `docs/10-CHANGELOG.md`.
- Rewrote `docs/05-SCREENS.md` to match the 19 prototype screens with M1/M2 tagging.
- Updated `docs/06-DESIGN-SYSTEM.md` with the `neon` token family from `prototipo/tokens.js`.
- Updated `docs/04-FEATURES.md` status column to mark M1 vs M2 (post-M1).
- Rewrote `TODO.md` as M1-only with 4 phases (Foundations, Features, Deploy, Acceptance).
- Rewrote `CLAUDE.md` to add a "Current Focus: M1" framing, drop osascript noise, and point to the new docs structure.
- Updated `docs/01-PROJECT.md`, `docs/02-ARCHITECTURE.md`, `docs/03-CONVENTIONS.md`, `docs/07-INFRA.md`, `README.md`, `CONTRIBUTING.md`, `SECURITY.md`.
- Deleted obsolete files: `agents.md`, `CODE_OF_CONDUCT.md`, `docs/DESIGN-PROMPT.md`, `docs/04-ROADMAP-M1.md`, `docs/04-ROADMAP-M2.md`, `apps/admin/`.

## Decisions Made

1. **M2 scope deferred until post-M1** — no ADR yet because the conversation with the client hasn't happened. ADR-0011 will be added when M2 scope is reconfirmed.
2. **Prototype is canonical** for visual identity, screens, gestures, flows. `prototipo/tokens.js` wins over `docs/06-DESIGN-SYSTEM.md` if they disagree.
3. **DO server titularity stays with the client** — Eduardo has admin access. Documentation no longer references "transfer" or "handoff" mechanics; those interactions stay outside docs.
4. **1GB droplet workaround is the M1 reality**, not a footnote. Resize + Sudeste reimport is post-M1.

## Open Questions Left

- [ ] Droplet IPv4 — Eduardo to fill in `docs/07-INFRA.md` once SSH'd in.
- [ ] Vercel project name and staging URL — Eduardo to fill in `docs/07-INFRA.md`.
- [ ] M2 scope conversation with client — happens after M1 acceptance.

## Files Changed

**Created**:
- `docs/superpowers/specs/2026-05-07-docs-cleanup-design.md`
- `docs/superpowers/plans/2026-05-07-docs-cleanup.md`
- `docs/08-ROADMAP.md`
- `docs/10-CHANGELOG.md`
- `docs/sessions/2026-05-07-04-docs-cleanup.md` (this file)

**Renamed**:
- `docs/FEATURES.md` → `docs/04-FEATURES.md`
- `docs/SCREENS.md` → `docs/05-SCREENS.md`
- `docs/DESIGN-SYSTEM.md` → `docs/06-DESIGN-SYSTEM.md`
- `docs/INFRA-ACCESS.md` → `docs/07-INFRA.md`
- `docs/06-DISASTER-RECOVERY.md` → `docs/09-DISASTER-RECOVERY.md`

**Modified**:
- `CLAUDE.md`, `TODO.md`, `README.md`, `CONTRIBUTING.md`, `SECURITY.md`
- `docs/01-PROJECT.md`, `docs/02-ARCHITECTURE.md`, `docs/03-CONVENTIONS.md`, `docs/04-FEATURES.md`, `docs/05-SCREENS.md`, `docs/06-DESIGN-SYSTEM.md`, `docs/07-INFRA.md`

**Moved**:
- `logo.png` → `apps/landing/public/logo.png`

**Deleted**:
- `agents.md`
- `CODE_OF_CONDUCT.md`
- `docs/DESIGN-PROMPT.md`
- `docs/04-ROADMAP-M1.md`
- `docs/04-ROADMAP-M2.md`
- `apps/admin/`

**Tracked (was untracked)**:
- `prototipo/` (entire directory)

## Commits Pushed

```
docs(spec): add M1-focused docs cleanup design spec
docs(plan): add docs cleanup implementation plan
docs(prototype): track approved Claude Design prototype as canonical UI source
docs(structure): renumber and rename for contiguous order
chore(landing): move logo to landing public assets
docs(roadmap): add M1-focused roadmap and changelog
docs(rewrite): align with approved prototype and M1 focus
docs(cleanup): remove obsolete files (agents.md, design-prompt, code-of-conduct, old roadmaps)
docs(sessions): add 2026-05-07-04 docs cleanup
```

## Hand-off Notes for Next Session

Next concrete action: **`flutter create apps/mobile/`** — the first task in `TODO.md` Phase 1. The repo is now clean and aligned for M1 development. Read `CLAUDE.md`, `TODO.md`, and `docs/08-ROADMAP.md` before starting.

## Reference Material Used

- The approved prototype: `prototipo/` (reviewed `Roteirizador Pro.html`, `tokens.js`, `screens-a.jsx` to extract the 19 screens and the design tokens).
- Workana proposal text and client conversation (provided by user during session) — confirmed scope: 30 days for M1, 1GB droplet workaround, server titularity with client, payment gateway switched to Efí Bank.
