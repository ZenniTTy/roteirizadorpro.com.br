# AGENTS.md

Portable entry point for any agentic coding tool (OpenAI Codex, Cursor, Aider, Jules, GitHub Copilot, Devin, Warp, Zed, Gemini CLI, and others that respect the [AGENTS.md spec](https://agents.md/)). Stewarded by the Agentic AI Foundation under the Linux Foundation.

The full operating manual lives in [CLAUDE.md](./CLAUDE.md) — read it in full before acting. This file is intentionally a thin redirect so Claude Code and other tools converge on the same source of truth.

@CLAUDE.md

## Tool-agnostic quick facts

- **Project:** Roteirizador Pro — Android route-planner APK for Brazilian delivery riders.
- **Repo:** `https://github.com/ZenniTTy/roteirizadorpro.com.br`
- **Status:** M1 delivered 2026-05-09. M2 in progress — slice 1 (APK) shipped 2026-05-13 as `v1.0.0`. Six slices remain.
- **Single source of truth for M2:** [`docs/08-ROADMAP-v2.md`](./docs/08-ROADMAP-v2.md). When any other doc contradicts it, the roadmap wins. (v1 archived at `docs/archive/2026-05-26-08-ROADMAP-v1-pre-pivot.md`.)
- **UI source of truth:** [`prototipo/`](./prototipo/) (client-approved Claude Design prototype).
- **Stack lock:** Flutter + Riverpod 3 + Fastify v5 + Prisma 7 + Bun + PostgreSQL 16. See [`CLAUDE.md`](./CLAUDE.md) "Stack — Locked Versions" — any change requires a new ADR in [`docs/decisions/`](./docs/decisions/).

## Mandatory pre-action ritual

1. Read [`CLAUDE.md`](./CLAUDE.md) in full.
2. Read [`docs/08-ROADMAP-v2.md`](./docs/08-ROADMAP-v2.md).
3. Read [`docs/M2-SLICE-CHECKLIST.md`](./docs/M2-SLICE-CHECKLIST.md).
4. Read the matching section of [`docs/inventory/2026-05-26-spoke-vs-rotpro.md`](./docs/inventory/2026-05-26-spoke-vs-rotpro.md) for the slice you are touching.
5. Read the last 5 entries in [`docs/sessions/0001-INDEX.md`](./docs/sessions/0001-INDEX.md).
6. Only then propose or write code.

## Non-negotiable rules (also in CLAUDE.md)

- **Verify your work.** Tests, screenshots, or curl evidence — never "trust me, it works."
- **Context7 before any new library.** Training-data cutoff lies; Context7 has current docs.
- **No stack change without an ADR.** New libs and version bumps get their own ADR in the same PR.
- **No comments in production code.** Names explain WHAT; ADRs/docs explain WHY.
- **`.env*` (except `.env.example`) and Android signing material (`*.jks`, `*.p12`, `key.properties`) are forbidden to edit.** The [`block-env.sh`](./.claude/hooks/block-env.sh) hook enforces this for Claude Code; other agents must respect it manually.
- **Self-modification by an AI without explicit human approval is forbidden.**

For everything else, [`CLAUDE.md`](./CLAUDE.md) is canonical.

## Per-tool harness directories

This repo ships two parallel harness layers; both honor `AGENTS.md` → `CLAUDE.md` as canonical.

- **[`.claude/`](./.claude/)** — Claude Code harness: subagents, hooks, skills, settings, MCP servers. Hooks enforce mechanically (`block-env.sh`, `analyze-changed-dart.sh`, `run-riverpod-codegen.sh`, `warn-adr-drift.sh`).
- **[`.agent/`](./.agent/)** — Google Antigravity harness: workspace Rules (passive guidelines), Workflows (`/` saved prompts), and Skills (reusable capabilities). Antigravity has no equivalent of Claude Code's `PreToolUse` hook — enforcement is via Rule text and Antigravity's terminal allowlist/denylist (configured in Settings, not in this repo).

Both are commit­ted intentionally so any operator (Eduardo, future collaborators, contracted agents) lands in the same operating environment regardless of which IDE they open.

If `~/.gemini/GEMINI.md` exists on the operator's machine, Antigravity gives it higher priority than this `AGENTS.md`. Verify no global rule conflicts with this project's `CLAUDE.md` before acting.
