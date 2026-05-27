<!--
Activation: Always On (intended). Confirm in Antigravity UI:
  Customizations → Rules → this file → set "Always On".
Source-of-truth note: this rule POINTS to AGENTS.md → CLAUDE.md. Canonical text lives there.
-->

# Pre-Action Ritual

Before proposing or writing code in any Antigravity session for this repo, read in this order:

1. `AGENTS.md` — entry point, redirects to CLAUDE.md.
2. `CLAUDE.md` — full operating manual (24KB; read in full, not skimmed).
3. `docs/08-ROADMAP-v2.md` — canonical M2 plan post 2026-05-26 reset.
4. `docs/M2-SLICE-CHECKLIST.md` — per-slice verification gates.
5. `docs/inventory/2026-05-26-spoke-vs-rotpro.md` — Spoke parity baseline for slices 2 and 3.
6. Last 5 entries in `docs/sessions/0001-INDEX.md`.
7. The ADRs cross-referenced by the slice you are about to touch (`docs/decisions/`).

Skipping this ritual is not an option, even if the human seems eager to jump to code. Five minutes of reading saves five hours of rework.

## Precedence trap — read this

Antigravity precedence is `GEMINI.md (highest) > AGENTS.md (lower)`. **If `~/.gemini/GEMINI.md` exists on this machine, it silently overrides `AGENTS.md` and therefore `CLAUDE.md`.** Before acting:

- Verify no `~/.gemini/GEMINI.md` exists on the operator's machine, OR
- If it exists, confirm with the operator that no rule there conflicts with this project's CLAUDE.md.

This project's CLAUDE.md is the canonical operating manual. If any conflict surfaces, CLAUDE.md wins for this repo.

## TDD-via-subagent is Claude-only

The `flutter-test-author` subagent (with mechanical `block-test-author-impl.sh` hook) lives in `.claude/agents/` and only runs in Claude Code. In Antigravity, follow TDD manually: write the failing test in `apps/mobile/test/` first, see it fail, then implement under `apps/mobile/lib/`. Do not skip the red phase.
