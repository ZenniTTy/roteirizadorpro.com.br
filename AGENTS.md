# AGENTS.md

Portable entry point for any agentic coding tool (OpenAI Codex, Cursor, Aider, Jules, GitHub Copilot, Devin, Warp, Zed, Gemini CLI, and others that respect the [AGENTS.md spec](https://agents.md/)). Stewarded by the Agentic AI Foundation under the Linux Foundation.

The full operating manual lives in [CLAUDE.md](./CLAUDE.md) — read it in full before acting. This file is intentionally a thin redirect so Claude Code and other tools converge on the same source of truth.

@CLAUDE.md

## Tool-agnostic quick facts

- **Project:** Roteirizador Pro — Android route-planner APK for Brazilian delivery riders.
- **Repo:** `https://github.com/ZenniTTy/-APP---Entrega-Smart`
- **Status:** M1 delivered 2026-05-09. M2 in progress — slice 1 (APK) shipped 2026-05-13 as `v1.0.0`. Six slices remain.
- **Single source of truth for M2:** [`docs/08-ROADMAP.md`](./docs/08-ROADMAP.md). When any other doc contradicts it, the roadmap wins.
- **UI source of truth:** [`prototipo/`](./prototipo/) (client-approved Claude Design prototype).
- **Stack lock:** Flutter + Riverpod 3 + Fastify v5 + Prisma 7 + Bun + PostgreSQL 16. See [`CLAUDE.md`](./CLAUDE.md) "Stack — Locked Versions" — any change requires a new ADR in [`docs/decisions/`](./docs/decisions/).

## Mandatory pre-action ritual

1. Read [`CLAUDE.md`](./CLAUDE.md) in full.
2. Read [`docs/08-ROADMAP.md`](./docs/08-ROADMAP.md).
3. Read [`docs/M2-SLICE-CHECKLIST.md`](./docs/M2-SLICE-CHECKLIST.md).
4. Read the last 5 entries in [`docs/sessions/0001-INDEX.md`](./docs/sessions/0001-INDEX.md).
5. Only then propose or write code.

## Non-negotiable rules (also in CLAUDE.md)

- **Verify your work.** Tests, screenshots, or curl evidence — never "trust me, it works."
- **Context7 before any new library.** Training-data cutoff lies; Context7 has current docs.
- **No stack change without an ADR.** New libs and version bumps get their own ADR in the same PR.
- **No comments in production code.** Names explain WHAT; ADRs/docs explain WHY.
- **`.env*` (except `.env.example`) and Android signing material (`*.jks`, `*.p12`, `key.properties`) are forbidden to edit.** The [`block-env.sh`](./.claude/hooks/block-env.sh) hook enforces this for Claude Code; other agents must respect it manually.
- **Self-modification by an AI without explicit human approval is forbidden.**

For everything else, [`CLAUDE.md`](./CLAUDE.md) is canonical.
