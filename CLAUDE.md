# CLAUDE.md

Operating manual for AI agents acting on this repository (Claude Code, Cursor, Claude web). Read this in full before any action.

> **Last updated:** 2026-05-05
> **Maintainer:** Eduardo Rodrigues — `eduardo@ianelli.tech`

## What This Project Is

**Roteirizador Pro** is an Android route-planning app for delivery riders, distributed as APK at `roteirizadorpro.com.br`. It is a **functional fork** of [Circuit Route Planner](https://getcircuit.com): we replicate flows, behaviors, screen structure, and UX patterns — we do **not** replicate icons, colors, typography, illustrations, microcopy, or any other Circuit-specific visual asset. Identity is 100% original.

This positioning is non-negotiable. See `docs/decisions/0010-clone-positioning.md` once authored.

## Onboarding Ritual

When you start a session in this repo, read in this order:

1. `README.md` — what the project is.
2. This file (`CLAUDE.md`) — how to operate.
3. `TODO.md` — current open tasks.
4. `docs/sessions/0001-INDEX.md` — last 3 session logs at minimum.

Skipping this ritual is not an option, even if the human seems eager to jump to code. **Five minutes of reading saves five hours of rework.**

## Karpathy's Four Principles (canonical)

These four principles are the canonical guidance for LLM coding behavior, originally compiled at [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) from Andrej Karpathy's observations. They apply to every action you take in this repo.

### 1. Think Before Coding

> Don't assume. Don't hide confusion. Surface tradeoffs.

Before implementing: state assumptions explicitly; if multiple interpretations exist, present them; if a simpler approach exists, say so; if anything is unclear, stop and ask.

### 2. Simplicity First

> Minimum code that solves the problem. Nothing speculative.

No features beyond what was asked. No abstractions for single-use code. No "flexibility" that wasn't requested. No error handling for impossible scenarios. If you write 200 lines and it could be 50, rewrite it.

### 3. Surgical Changes

> Touch only what you must. Clean up only your own mess.

Don't "improve" adjacent code, comments, or formatting. Don't refactor things that aren't broken. Match existing style even if you'd write it differently. Mention unrelated dead code — don't delete it. **Every changed line should trace directly to the user's request.**

### 4. Goal-Driven Execution

> Define success criteria. Loop until verified.

Transform "add validation" → "write tests for invalid inputs, then make them pass." Transform "fix the bug" → "write a test that reproduces it, then make it pass." Strong success criteria let you loop independently; weak criteria require constant clarification.

## Project-Specific Critical Rules

These rules can't be inferred from code. They are enforced by you, the agent.

### Stack — Locked Versions

| Layer | Tech | Notes |
|---|---|---|
| Mobile | Flutter + Riverpod 3 (`@riverpod` codegen) | |
| Backend | Node.js 20 LTS + Fastify v5 + TypeBox | TypeBox is the type provider |
| ORM | Prisma 7 + `@prisma/adapter-pg` | Driver adapters mandatory |
| DB / Cache | PostgreSQL 16 / Redis 7 | |
| Routing | GraphHopper self-hosted | Sudeste Brasil, motorcycle profile |
| Payment | Efí Bank API Pix v2 (mTLS) | No official Node SDK — use direct HTTPS |
| Server | Ubuntu 24.04 on DigitalOcean 8GB | |

Any change requires a new ADR.

### Context7 Mandatory

Before proposing OR installing any external library/framework, query Context7 (`resolve-library-id` then `query-docs`). Training-data knowledge has a cutoff; Context7 has current docs. **No exceptions for libraries within reach of the cutoff date.** Stdlib and well-established APIs (HTTP, SQL) are exempt.

### Verify Your Work

Per Anthropic's official guidance, this is the single highest-leverage thing you can do.

- Provide tests, scripts, or screenshots that let you check yourself.
- Address root causes, not symptoms.
- If you can't verify it, don't ship it.

### Filesystem Protocol

Read first, edit second. Never edit a file without reading the current version. After editing critical files (schema, env, route registrations), re-read to confirm the change landed.

### Git Protocol (essentials)

- All Git operations on Mac via `osascript` — never paste commands for the human.
- `git status` before any Git action.
- Conventional Commits, one logical change per commit.
- Never `git push --force` to `develop` or `main`.

Full Git workflow lives in `CONTRIBUTING.md`.

### Secrets

`.env*` (except `.env.example`) is gitignored. Never commit secrets — not even as placeholders. If a secret leaks, rotate it immediately and scrub history with `git filter-repo`.

## Session End Protocol

At the end of any meaningful session:

1. Update `TODO.md` (mark completed, add discovered tasks).
2. Create `docs/sessions/YYYY-MM-DD-NN-<topic>.md` from the template at `0000-template.md`.
3. Append the new session to `docs/sessions/0001-INDEX.md`.
4. Commit all three together with `docs(sessions): <session topic>`.

## When You Disagree With This File

This file is itself versioned. If a rule here is wrong or outdated:

1. Raise it with the human owner.
2. If approved, edit this file with `docs(claude): <what changed>` and bump the date at the top.
3. If the change affects an ADR, update the ADR in the same commit set.

**Self-modification by an AI without human approval is forbidden.**

## References (deeper context, on demand)

The detail lives elsewhere. Read these only when the topic is relevant to your current task:

- Project vision, scope, milestones → `docs/01-PROJECT.md`
- Architecture, flows, schemas, contracts → `docs/02-ARCHITECTURE.md`
- Naming, code style, directory layout → `docs/03-CONVENTIONS.md`
- Roadmap (M1, M2 deliverables) → `docs/04-ROADMAP.md`
- LGPD compliance map → `docs/05-LGPD.md`
- Disaster recovery → `docs/06-DISASTER-RECOVERY.md`
- All decisions and their rationale → `docs/decisions/`
- Git workflow detail → `CONTRIBUTING.md`
- Security policy → `SECURITY.md`

## Source Attribution

The four principles section above is drawn from:

- Andrej Karpathy — public observations on LLM coding behavior (March 2025 thread).
- Forrest Chang's `forrestchang/andrej-karpathy-skills` repository, which codified them as a CLAUDE.md.
- Anthropic's official "Best practices for Claude Code" — https://code.claude.com/docs/en/best-practices.

When in doubt, the source documents win over our interpretation.
