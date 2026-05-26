# 2026-05-05-02 — CLAUDE.md Rewrite (Karpathy + Anthropic primary sources)

## Metadata

- **Date**: 2026-05-05 (America/Sao_Paulo)
- **Sequence**: 02
- **Agent**: Claude web (Opus 4.7)
- **Human**: Eduardo
- **Topic**: claude-md-rewrite
- **Duration**: ~1 turn cycle
- **Related ADRs**: pending — 0010 (positioning) will reference this work
- **Related TODO items**: M1 bootstrap

## Goal of the Session

Rewrite the initial `CLAUDE.md` (407 lines, written from memory) to comply with primary-source guidance from Andrej Karpathy and Anthropic's official Claude Code documentation. Migrate detail-heavy sections out of the root file into focused documents that get loaded only when relevant.

## What Was Done

- Searched for and fetched Andrej Karpathy's canonical four LLM coding principles from `forrestchang/andrej-karpathy-skills` (official CLAUDE.md template that codified Karpathy's March 2025 observations).
- Fetched Anthropic's official "Best practices for Claude Code" (https://code.claude.com/docs/en/best-practices) — most authoritative reference on CLAUDE.md design.
- Audited the previous `CLAUDE.md` against both sources and identified anti-patterns:
  - 407 lines vs Anthropic's recommended < 300 (HumanLayer reports < 60 ideal).
  - Included code style and naming conventions — Anthropic explicitly says these belong outside `CLAUDE.md` (linter's job).
  - Did not cite primary sources for the Karpathy-inspired principles.
  - Lacked "verify your work" mandate — Anthropic's "single highest-leverage thing".
  - Lacked the canonical Karpathy 4 principles (Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution).
  - Did not use `@path` imports — instead inlined everything.
- Rewrote `CLAUDE.md` to **141 lines**, structured around:
  - Project identity (1 paragraph).
  - Onboarding ritual (4 items, was 8).
  - Karpathy's 4 canonical principles (cited verbatim with attribution).
  - Project-specific critical rules (only what an agent can't infer from code).
  - Session end protocol.
  - References to detail docs (loaded on demand).
  - Source attribution.
- Created `docs/03-CONVENTIONS.md` (81 lines) — naming, code style baseline, directory layout, testing convention. Migrated from CLAUDE.md.
- Created `docs/05-LGPD.md` (74 lines) — full LGPD compliance map. Migrated from CLAUDE.md.
- Created `CONTRIBUTING.md` (130 lines) — full Git workflow, branching, commit format, PR rules, Mac osascript pattern. Migrated from CLAUDE.md.

## Decisions Made

1. **CLAUDE.md is for guidance that needs judgment, not deterministic rules** — Anti-patterns moved out: code style → linter, naming → 03-CONVENTIONS, full LGPD → 05-LGPD, full Git workflow → CONTRIBUTING.
2. **Cite Karpathy's 4 principles verbatim** — Reformulating risked degrading precision. The principles are short enough to quote, and attribution is clear.
3. **Use `@path` references for detail docs** — Anthropic's recommended pattern. CLAUDE.md becomes a hub, not a textbook.
4. **Add explicit "Verify your work" section** — Anthropic calls this "the single highest-leverage thing".
5. **Keep onboarding ritual to 4 mandatory items** — Was 8. Per Anthropic: "Bloated CLAUDE.md files cause Claude to ignore your actual instructions."

## Open Questions Left

- [ ] When to author `docs/01-PROJECT.md`, `docs/02-ARCHITECTURE.md`, `docs/04-ROADMAP.md`, `docs/06-DISASTER-RECOVERY.md` — they are referenced but don't exist yet. Will produce 404-like reads if an agent follows the link. Plan: create them in subsequent sessions before any agent needs them.
- [ ] Whether `SECURITY.md` and the ADRs (0001-0010) need to be authored before product code begins — likely yes. Track in TODO.md.
- [ ] `.gitignore` and `.editorconfig` not yet created — needed before any code lands.

## Files Changed

**Created**:
- `docs/03-CONVENTIONS.md`
- `docs/05-LGPD.md`
- `CONTRIBUTING.md`
- `docs/sessions/2026-05-05-02-claude-md-rewrite.md` (this file)

**Modified**:
- `CLAUDE.md` (rewritten in full: 407 → 141 lines)
- `docs/sessions/0001-INDEX.md` (new entry)

**Deleted**:
- none

## Commits Pushed

To be filled at end of session.

## Hand-off Notes for Next Session

- **Current branch**: `develop`.
- **Working tree**: clean after session commits.
- **CLAUDE.md is now the canonical entry**. Any agent starting fresh reads it and follows imports as needed.
- **Next priorities** (revised based on the new modular structure):
  1. Create `TODO.md` at root — populated with M1 bootstrap tasks (the agreed action list).
  2. Author `docs/01-PROJECT.md` — vision, scope, milestones (the next document Eduardo wants).
  3. Author `docs/02-ARCHITECTURE.md`.
  4. Author `docs/04-ROADMAP.md`.
  5. Author `docs/06-DISASTER-RECOVERY.md`.
  6. Create all ADRs (0001 through 0010).
  7. Author `SECURITY.md`, `CODE_OF_CONDUCT.md`.
  8. Create `.gitignore`, `.editorconfig`, `.github/pull_request_template.md`.
- **Reference doc URLs not yet inlined** — the 4 principles section in CLAUDE.md cites the GitHub repo; the next agent should consider whether to also vendor a copy of `forrestchang/andrej-karpathy-skills/CLAUDE.md` into `docs/references/` for offline access. Defer this decision until needed.

## Reference Material Used

- **Primary**: https://raw.githubusercontent.com/forrestchang/andrej-karpathy-skills/main/CLAUDE.md — canonical Karpathy four-principles file (fetched in full).
- **Primary**: https://code.claude.com/docs/en/best-practices — Anthropic official Claude Code best practices (fetched in full).
- **Secondary**: https://pyshine.com/Andrej-Karpathy-Skills-LLM-Coding-Guidelines/ — extended commentary on the four principles with examples.
- **Secondary**: https://www.humanlayer.dev/blog/writing-a-good-claude-md — practitioner consensus on CLAUDE.md length and content.
