# CLAUDE.md

Operating manual for AI agents acting on this repository (Claude Code, Cursor, Claude web). Read this in full before any action.

> **Last updated:** 2026-05-08
> **Maintainer:** Eduardo Rodrigues — `eduardo@ianelli.tech`

## What This Project Is

**Roteirizador Pro** is an Android route-planning app for delivery riders, distributed as APK at `roteirizadorpro.com.br`. It is a **functional fork** of [Spoke/Circuit Route Planner](https://getcircuit.com): we replicate flows, behaviors, screen structure, and UX patterns — we do **not** replicate icons, colors, typography, illustrations, microcopy, or any other Circuit-specific visual asset. Identity is 100% original.

This positioning is non-negotiable. See `docs/decisions/0010-clone-positioning.md`.

## Current Focus: M1

The current milestone is **M1, deadline 2026-05-26**. Do not plan or build M2 work in this cycle. M2 scope will be reconfirmed with the client after M1 acceptance.

M1 plan: `docs/08-ROADMAP.md`.

## Onboarding Ritual

When you start a session in this repo, read in this order:

1. `README.md` — what the project is.
2. This file (`CLAUDE.md`) — how to operate.
3. `TODO.md` — current open M1 tasks.
4. `docs/08-ROADMAP.md` — M1 plan and acceptance criteria.
5. `docs/sessions/0001-INDEX.md` — last 3 session logs at minimum.

Skipping this ritual is not an option, even if the human seems eager to jump to code. **Five minutes of reading saves five hours of rework.**

## UI Source of Truth

The Claude Design prototype at `prototipo/` is the **canonical UI source** — client-approved on 2026-05-07. Visual identity, screens, gestures, and flows must match it 1:1 in implementation. The prototype's `tokens.js` is canonical for design tokens. `docs/05-SCREENS.md` and `docs/06-DESIGN-SYSTEM.md` mirror it; if they disagree with the prototype, the prototype wins.

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
| Routing | GraphHopper self-hosted | SP-only on M1 (1GB droplet); Sudeste post-M1 |
| Server | Ubuntu 24.04 on DigitalOcean (client's account) | 1GB on M1; resize to 8GB post-M1 escrow |
| Landing | Next.js 14 + Tailwind on Vercel | |
| Node package manager | Bun 1.3+ (install only) | Runtime stays Node 20 LTS — see ADR-0011. Use `bun install`, `bun run`, `bunx`. `bun.lock` is the lockfile of record; never commit `package-lock.json`. |
| Git hooks / commits | Lefthook 2.x + commitlint 20.x + commitizen | Per ADR-0012. `bun install` at the repo root sets `.git/hooks/{pre-commit,commit-msg}` automatically. Use `bun run commit` for an interactive Conventional Commit wizard. Pre-commit runs typecheck/lint/analyze for the changed app only — keep edits scoped. |

Any change requires a new ADR.

### Schema Source of Truth (ADR-0013)

The stack has three places where data shape can be defined; only one is canonical per layer.

| Layer | Source of truth | Lives at |
|---|---|---|
| Database | Prisma `schema.prisma` | `apps/backend/prisma/schema.prisma` — backend-internal; never on the wire |
| HTTP API | TypeBox schemas | `apps/backend/src/<feature>/schemas.ts` (separate file from handlers) |
| Mobile | Dart DTOs (manual mirror, M1) | `apps/mobile/lib/features/<feature>/data/dto/<name>_dto.dart` |

Rules (full text in `docs/03-CONVENTIONS.md` §8 and `docs/02-ARCHITECTURE.md` "API Contracts & Type Safety"):

1. Never return `@prisma/client` rows from a handler. Always whitelist via a TypeBox response schema.
2. Every Dart DTO file starts with `// Mirror of: apps/backend/src/<feature>/schemas.ts → <SchemaName>` and matches the TypeBox shape 1:1 (no renaming, no field skips).
3. A change to a TypeBox schema and its Dart mirror travel in the same commit.

Reference template: `apps/mobile/lib/features/auth/data/dto/_template.dart`. Post-M1 plan: replace the manual mirror with OpenAPI export (`@fastify/swagger`) + Dart codegen. See ADR-0013.

### Context7 Mandatory

Before proposing OR installing any external library/framework, query Context7 (`resolve-library-id` then `query-docs`). Training-data knowledge has a cutoff; Context7 has current docs. **No exceptions for libraries within reach of the cutoff date.** Stdlib and well-established APIs (HTTP, SQL) are exempt.

### Verify Your Work

Per Anthropic's official guidance, this is the single highest-leverage thing you can do.

- Provide tests, scripts, or screenshots that let you check yourself.
- Address root causes, not symptoms.
- If you can't verify it, don't ship it.

### Flutter Hot-Reload Discipline

Do **not** kill `flutter run` for changes inside `lib/**`. Three levels, cheapest first:

| Level | Trigger | Cost | When |
|---|---|---|---|
| Hot reload | `r` in the terminal where `flutter run` is attached, or VS Code save (with `dart.flutterHotReloadOnSave: always`) | sub-second, preserves state | Widget edit, color/copy change, method body edit. |
| Hot restart | `R` in the same terminal | ~2 s, loses state | New top-level provider, new route, change to `main()`. |
| Full restart (kill + `flutter run`) | terminate the process | 2–7 min (Gradle, install) | `pubspec.yaml` asset/dep change, native (Kotlin/Swift) code change, AndroidManifest change. |

When `flutter run` is alive in the background, an agent can trigger a hot reload over the Dart VM Service (URL printed at startup). Default behavior: prefer hot reload over restart over full relaunch. Codified in ADR-0012.

### Filesystem Protocol

Read first, edit second. Never edit a file without reading the current version. After editing critical files (schema, env, route registrations), re-read to confirm the change landed.

### Git Protocol (essentials)

- `git status` before any Git action.
- Conventional Commits — one logical change per commit.
- Never `git push --force` to `develop` or `main`.

Full Git workflow lives in `CONTRIBUTING.md`.

### Secrets

`.env*` (except `.env.example`) is gitignored. Never commit secrets — not even as placeholders. If a secret leaks, rotate it immediately and scrub history with `git filter-repo`.

## Session End Protocol

At the end of any meaningful session:

1. Update `TODO.md` (mark completed `[x]`, add discovered tasks `[ ]`).
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
- Features (canonical business rules) → `docs/04-FEATURES.md`
- Screens (prototype catalogue) → `docs/05-SCREENS.md`
- Design system → `docs/06-DESIGN-SYSTEM.md`
- Infrastructure → `docs/07-INFRA.md`
- M1 roadmap → `docs/08-ROADMAP.md`
- Disaster recovery → `docs/09-DISASTER-RECOVERY.md`
- Documentation changelog → `docs/10-CHANGELOG.md`
- All decisions and their rationale → `docs/decisions/`
- Git workflow detail → `CONTRIBUTING.md`
- Security policy → `SECURITY.md`

## Source Attribution

The four principles section above is drawn from:

- Andrej Karpathy — public observations on LLM coding behavior (March 2025 thread).
- Forrest Chang's `forrestchang/andrej-karpathy-skills` repository, which codified them as a CLAUDE.md.
- Anthropic's official "Best practices for Claude Code" — https://code.claude.com/docs/en/best-practices.

When in doubt, the source documents win over our interpretation.
