# CLAUDE.md

Operating manual for AI agents acting on this repository (Claude Code, Cursor, Claude web). Read this in full before any action.

> **Last updated:** 2026-05-24 (M2-AI harness sprint shipped, ADRs 0023–0029; retrospective + playbook: `docs/sprints/2026-05-24-m2-ai-harness.md`; two deferred smoke dispatches in ADR-0025 + ADR-0027 §Verification. Same day: **ADR-0030** migrated the Pix gateway from Efí Bank to Stripe + 30-day access pass model — supersedes ADR-0007. Operational rules in `docs/BUSINESS-RULES.md`.)
> **Maintainer:** Eduardo Rodrigues — `eduardo@ianelli.tech`

## Executable Commands (the ones you actually run)

| Command | When |
|---|---|
| `bun install` | First clone and after any `package.json` change. Wires lefthook hooks automatically. |
| `bun run commit` | Interactive Conventional Commit wizard. Use `/commit` skill from Claude Code for non-interactive flow. |
| `cd apps/mobile && flutter analyze` | Before every mobile commit. Lefthook also runs this on `*.dart` changes. |
| `cd apps/mobile && flutter test` | Before merging any mobile slice. |
| `cd apps/mobile && dart run build_runner build --delete-conflicting-outputs` | After editing any `@riverpod`-annotated file. |
| `cd apps/backend && bun run typecheck` | Before every backend commit. Lefthook enforces. |
| `cd apps/landing && bun run lint` | Before every landing commit. Lefthook enforces. |
| `bash apps/mobile/scripts/build-release-apk.sh` | Cuts a signed release APK. ADR-0014. |
| `aapt2 dump permissions <apk>` | Verifies Android permissions on the built APK — slice 1 lesson. |
| `dart mcp-server --help` | Sanity-check that the Dart & Flutter MCP server is reachable. Server is registered in `.mcp.json` + allowlisted in `.claude/settings.json`; the assistant invokes it transparently. Requires Dart ≥ 3.9 (currently 3.11.5). ADR-0023. |
| `/mcp` (inside Claude Code) | List active MCP servers. `dart` should appear ✅ connected after a session restart following Phase 1 of the M2-AI sprint. |
| `cd apps/mobile && flutter test --tags golden` | Run only the alchemist golden tests (ADR-0029). Add `--update-goldens` to regenerate baselines after an intentional visual change; review the PNG diff in the PR. |

## What This Project Is

**Roteirizador Pro** is an Android route-planning app for delivery riders, distributed as APK at `roteirizadorpro.com.br`. It is a **functional fork** of [Spoke/Circuit Route Planner](https://getcircuit.com): we replicate flows, behaviors, screen structure, and UX patterns — we do **not** replicate icons, colors, typography, illustrations, microcopy, or any other Circuit-specific visual asset. Identity is 100% original.

This positioning is non-negotiable. See `docs/decisions/0010-clone-positioning.md`.

## Current Focus: M2 (slice 2 — Telas Core, IN PROGRESS)

M1 was delivered on 2026-05-09. Slice 1 of M2 (Distributable APK) shipped 2026-05-13 as `v1.0.0`. **M2 is in progress.** The locked order is:

1. ✅ APK distribuível (`v1.0.0`).
2. 🟡 **Telas Core — IN PROGRESS** (13/16 fidelity microsprints done as of 2026-05-23 / MS-14; 7 Criticals remain — MS-15 AddStop, MS-16 Voice, Navigate C-1 ADR-0017-scoped). On parallel branch `feat/m2-ai-harness` the **M2-AI Harness sprint shipped (2026-05-24) — ADRs 0023–0029**; PR #8 against `feat/m2-slice-2-telas-core` ready to merge before slice 2's own microsprints resume.
3. ⏳ VRP real (in-process Node TS solver + GraphHopper matrix).
4. ⏳ Stripe Pix paywall (Stripe Connect 50/50 split, R$ 25,90 grants 30 days of access; renewal is a fresh manual Pix payment, not Stripe Billing — ADR-0030 + `docs/BUSINESS-RULES.md`).
5. ⏳ Sentido casa.
6. ⏳ LGPD.
7. ⏳ Painel admin.

**The single source of truth for M2 is `docs/08-ROADMAP.md`.** When any other doc contradicts it, the roadmap wins and you fix the contradiction in the same PR. Slice-execution discipline lives in `docs/M2-SLICE-CHECKLIST.md`. Cost ceiling in `docs/M2-COST-MODEL.md` (≤ BRL 200/month total infrastructure while in beta).

## Onboarding Ritual

When you start a session in this repo, read in this order:

1. `README.md` — what the project is.
2. This file (`CLAUDE.md`) — how to operate.
3. `docs/08-ROADMAP.md` — **the canonical M2 plan; this is the file you act from**.
4. `docs/M2-SLICE-CHECKLIST.md` — the per-slice execution checklist (verification steps, post-merge ritual).
5. `docs/M2-COST-MODEL.md` — the cost ceiling every architectural choice must respect.
6. `TODO.md` — current slice-by-slice state.
7. `docs/sessions/0001-INDEX.md` — last 5 session logs minimum.
8. The slice's section in `docs/08-ROADMAP.md` (e.g. "Slice 2 — Telas Core") and the `prototipo/screens-*.jsx` files matching it.
9. The relevant ADRs (`docs/decisions/0015-*` for the M2 plan, `0016-*` for map/tiles, plus any slice-specific ADRs cross-referenced inside the slice section).
10. **Recent ADRs (post-M1, one-time orientation):**
    - **0023–0029 (AI harness):** Dart MCP server, Riverpod codegen hook, two project-scoped subagents (`flutter-test-author`, `flutter-perf-auditor`), `mocktail` + `alchemist` dev_deps, `mcp_flutter` rejection, `GH_DATA_DIR` infra. Playbook + retrospective at `docs/sprints/2026-05-24-m2-ai-harness.md`. Already wired into §"Verify Your Work" and §"In-Loop Auto-Validation" below.
    - **0030 (Stripe Pix migration, supersedes 0007):** slice 4 uses **Stripe Connect** with 50/50 split via Separate Charges and Transfers; **R$ 25,90 grants 30 days of access**, renewed via fresh manual Pix each cycle (no Stripe Billing, no Stripe Subscriptions API). Operational rules in `docs/BUSINESS-RULES.md`.

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
2. Every Dart DTO file starts with `// Mirror of: apps/backend/src/<feature>/schemas.ts -> <SchemaName>` (single-DTO) or `... -> {Schema1, Schema2, ...}` (multi-DTO) and matches the TypeBox shape 1:1 (no renaming, no field skips). ASCII `->` only, no backticks. See ADR-0020 for the normative grammar.
3. A change to a TypeBox schema and its Dart mirror travel in the same commit.

Reference template: `apps/mobile/lib/features/auth/data/dto/_template.dart`. Post-M1 plan: replace the manual mirror with OpenAPI export (`@fastify/swagger`) + Dart codegen. See ADR-0013.

### Context7 Mandatory

Before proposing OR installing any external library/framework, query Context7 (`resolve-library-id` then `query-docs`). Training-data knowledge has a cutoff; Context7 has current docs. **No exceptions for libraries within reach of the cutoff date.** Stdlib and well-established APIs (HTTP, SQL) are exempt.

**Precedence after ADR-0023 (Dart & Flutter MCP server adopted):**

1. **Dart MCP first** — for any symbol, class, or method from a Dart/Flutter package **already installed** in `apps/mobile/pubspec.yaml` (i.e. resolvable from local `.pub-cache/`), use the Dart MCP tools (`resolve_symbol`, `analyze`, etc.) instead of `Read`ing pub-cache files or hitting Context7. The MCP returns the real signature from the local analyzer — zero hallucination, zero token spent on file traversal.
2. **Context7 second** — for any library not yet installed, or to confirm the current pub.dev version before adding a dependency, or for any non-Dart library (Fastify, Prisma, TypeBox, Next.js, etc.). Context7 stays mandatory there.
3. **Training-data answers third (rarely)** — only for stdlib and stable APIs (HTTP verbs, SQL syntax) where the answer hasn't changed in years.

If the Dart MCP is unavailable (process crash, Dart < 3.9, `dart` not in `/mcp` list), fall back to Context7 + `Read` — but say so explicitly in the turn so the human can re-establish the MCP.

### Verify Your Work

Per Anthropic's official guidance, this is the single highest-leverage thing you can do.

- Provide tests, scripts, or screenshots that let you check yourself.
- Address root causes, not symptoms.
- If you can't verify it, don't ship it.
- Use `/verify-slice` as the pre-PR gate — it packages `M2-SLICE-CHECKLIST.md` §Verification (flutter analyze + test, bun typecheck, `prototype-fidelity-checker` + `adr-guardian` subagents) into one orchestrated report. See ADR-0018.
- **For mobile TDD, dispatch the `flutter-test-author` subagent BEFORE implementing any new widget/provider/service in `apps/mobile/lib/`.** It writes the failing test first, creates a `throw UnimplementedError()` stub so the test fails on the assertion (not on import), and hands off to the implementer with the required API surface. It refuses to write production code itself — the bias-break is the point. Mock library is `mocktail ^1.0.5` (no codegen); manual fakes under `test/<feature>/_helpers/` remain the default. See ADR-0025.
- **For mobile perf review, dispatch the `flutter-perf-auditor` subagent AFTER finishing a screen and BEFORE opening the slice PR.** Read-only, produces a Markdown punch-list categorized must-fix / should-fix / nit across 9 canonical checks (ListView.builder discipline, missing `const`, `ref.watch` granularity, UI-thread heavy work, RepaintBoundary, tile cache, list keys, image decoding, StatefulWidget overuse). It cannot edit code — the allowlist excludes Edit/Write/MultiEdit. Now part of `M2-SLICE-CHECKLIST.md` §Verification. See ADR-0027.

### In-Loop Auto-Validation (ADR-0018 + ADR-0024)

Four hooks run automatically around every assistant edit/turn — non-blocking, signal-only:

**Stop hooks** (fire once at end of turn, batched across all edits):

- `analyze-changed-dart.sh` — `flutter analyze --no-pub` over `.dart` files edited in `apps/mobile/lib/` this turn.
- `check-dto-mirror.sh` — warns when an `apps/backend/src/<feature>/schemas.ts` edit lacks its paired Dart DTO update (ADR-0013 contract).
- `warn-adr-drift.sh` — warns when `pubspec.yaml`/`package.json`/`schema.prisma`/`docker-compose.yml` was edited this turn but no ADR was added/modified.

**PostToolUse hook** (fires per Edit/Write/MultiEdit, debounced):

- `run-riverpod-codegen.sh` (ADR-0024) — when a `@riverpod`-annotated Dart file or any `part '*.g.dart'` host is edited, regenerates `.g.dart` via `dart run build_runner build --delete-conflicting-outputs`. Lock-file debounce (90s window) coalesces burst-edits so multiple provider edits in one turn run codegen only once. Sits next to the pre-existing `format-dart.sh` in the same matcher entry.

These are the agent-turn equivalent of Lefthook (which fires at `git commit`). They don't replace `adr-guardian` or the slice checklist — they surface drift earlier, while context is still hot. Full design in ADR-0018; PostToolUse extension rationale in ADR-0024; layered boundary in ADR-0012.

### Spec-Driven Workflow (ADR-0019)

Every new slice or large feature starts from the canonical templates extracted from the slice-2 artifacts:

- `docs/superpowers/specs/0000-template.md` — the 13 H2 sections (Context, Decisions Locked, Goals, Architecture, Data flow, Sub-slice plan, Libraries, ADRs filed, Risks, Accessibility, Test strategy, Verification gates, References).
- `docs/superpowers/plans/0000-template.md` — the Phase / Task / Step hierarchy with TDD pattern, Self-Review checklist, and Execution Handoff.

Two skills enforce the brainstorming-first discipline:

- `/new-spec <slug>` — scaffolds the spec header and stops; the human invokes `superpowers:brainstorming` to lock the Q1/Q2/Q3-style decisions before authoring §Context onward.
- `/new-plan <slug>` — scaffolds the plan header + back-reference to the matching spec and stops; the human invokes `superpowers:writing-plans` to decompose tasks.

Skipping these and copying a previous spec/plan invariably introduces drift. Use the skills.

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
- Forrest Chang's [`forrestchang/andrej-karpathy-skills`](https://github.com/forrestchang/andrej-karpathy-skills) repository, which codified them as a CLAUDE.md.
- Anthropic's official [Best practices for Claude Code](https://code.claude.com/docs/en/best-practices), [Subagents](https://code.claude.com/docs/en/sub-agents), [Skills](https://code.claude.com/docs/en/skills), and [Hooks](https://code.claude.com/docs/en/hooks-guide) docs.

When in doubt, the source documents win over our interpretation.
