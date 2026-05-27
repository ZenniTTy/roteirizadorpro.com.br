# CLAUDE.md

Operating manual for AI agents acting on this repository (Claude Code, Cursor, Claude web). Read this in full before any action.

> **Last updated:** 2026-05-27 (ADR-0010 Amendments 1+2 — engineering artifacts da inspeção podem entrar no repo livremente; inspeção é escolha do operador. O que rege é apenas o **shipped product** ter identidade visual original per ADR-0035. Trava operacional removida — workflow do `spoke-parity-checker` simplificado, sem cleanup loops nem proibições de extração interna. Previous: ADR-0037 Maestro CLI 2.6 + Maestro MCP adotados como camada preferida; ROADMAP-v2 simplificado; estratégia firme **white-label do Spoke** (100% funcional/estrutural com nossa stack; polish visual no final). Foundational: ADR-0035 pivot + ADR-0036 parity gate.)
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
| `dart mcp-server --help` | Sanity-check that the Dart & Flutter MCP server is reachable. Server is registered in `.mcp.json` + allowlisted in `.claude/settings.json`; the assistant invokes it transparently. Requires Dart ≥ 3.9 (currently 3.11.5). See ADR-0023. |
| `MAESTRO_CLI_NO_ANALYTICS=1 maestro --version` | Sanity-check that the Maestro CLI (and therefore the Maestro MCP server) is reachable. Currently 2.6.0. Installed via `brew install mobile-dev-inc/tap/maestro --formula` (the plain cask install only ships the desktop app, no CLI). Server is registered in `.mcp.json` + allowlisted in `.claude/settings.json`. See ADR-0037. |
| `/mcp` (inside Claude Code) | List active MCP servers. `dart` AND `maestro` should appear ✅ connected. |

## What This Project Is

**Roteirizador Pro** is an Android route-planning app for delivery riders, distributed as APK at `roteirizadorpro.com.br`. It is a **functional fork** of [Spoke/Circuit Route Planner](https://getcircuit.com): we replicate flows, behaviors, screen structure, and UX patterns — we do **not** replicate icons, colors, typography, illustrations, microcopy, or any other Circuit-specific visual asset. Identity is 100% original.

This positioning is non-negotiable. See `docs/decisions/0010-clone-positioning.md`.

## Current Focus: M2 (slice 2 — Telas Core, RESET 2026-05-26)

M1 was delivered on 2026-05-09. Slice 1 of M2 (Distributable APK) shipped 2026-05-13 as `v1.0.0`. **M2 reset 2026-05-26**: branch `chore/m2-reset-to-zero` apagou todo o código slice-2 (29 stops + 1 settings + 1 share) + 37 tests + 12 ADRs específicas + 10 specs/plans + 36 sessions. Estratégia agora firme: **white-label do Spoke** — replicar 100% funcional/estrutural com nossa stack; polish visual no final. Locked order:

1. ✅ APK distribuível (`v1.0.0`).
2. 🟡 **Slice 2 — Telas Core Spoke-aligned** (em progresso pós-reset; lista de telas a replicar em [`docs/08-ROADMAP-v2.md`](./docs/08-ROADMAP-v2.md))
3. ⏳ Slice 3 — Backend real (solver in-process Node TS + Nominatim SP + status persistido + FCM + reset senha + Google Sign-In backend)
4. ⏳ Slice 4 — Stripe Pix paywall (Connect 50/50 split, R$ 25,90 grants 30 days; renewal is fresh manual Pix — ADR-0030 + `docs/BUSINESS-RULES.md`)
5. ⏳ Slice 5 — Sentido casa
6. ⏳ Slice 6 — LGPD
7. ⏳ Slice 7 — Painel admin

**The single source of truth for M2 is [`docs/08-ROADMAP-v2.md`](./docs/08-ROADMAP-v2.md)** (simplificado pós-reset). Slice-execution discipline lives in `docs/M2-SLICE-CHECKLIST.md`. Cost ceiling in `docs/M2-COST-MODEL.md` (≤ BRL 200/month total infrastructure while in beta). Catálogo autoritativo de paridade Spoke↔RotPro: `docs/inventory/2026-05-26-spoke-vs-rotpro.md`.

## Onboarding Ritual

When you start a session in this repo, read in this order:

1. `README.md` — what the project is.
2. This file (`CLAUDE.md`) — how to operate.
3. `docs/08-ROADMAP-v2.md` — **the canonical M2 plan; this is the file you act from** (v1 is archived at `docs/archive/2026-05-26-08-ROADMAP-v1-pre-pivot.md`).
4. `docs/M2-SLICE-CHECKLIST.md` — the per-slice execution checklist (verification steps, post-merge ritual).
5. `docs/M2-COST-MODEL.md` — the cost ceiling every architectural choice must respect.
6. `TODO.md` — current slice-by-slice state.
7. `docs/sessions/0001-INDEX.md` — last 5 session logs minimum.
8. The slice's section in `docs/08-ROADMAP-v2.md` (e.g. "Slice 2 — Spoke-aligned Telas Core"), the matching `prototipo/screens-*.jsx` files (for visual identity only), and the matching section of `docs/inventory/2026-05-26-spoke-vs-rotpro.md` (for functional/behavioral parity baseline).
9. The relevant ADRs (`docs/decisions/0015-*` for the M2 plan, `0016-*` for map/tiles, plus any slice-specific ADRs cross-referenced inside the slice section).
10. **Recent ADRs (one-time orientation):**
    - **0023–0026 (AI harness):** Dart MCP server (0023), `@riverpod` codegen hook (0024), `flutter-test-author` subagent (0025), `GH_DATA_DIR` infra override (0026). Wired into §"Verify Your Work" and §"In-Loop Auto-Validation" below.
    - **0030 (Stripe Pix):** slice 4 uses **Stripe Connect** with 50/50 split via Separate Charges and Transfers; **R$ 25,90 grants 30 days of access**, renewed via fresh manual Pix each cycle (no Stripe Billing, no Stripe Subscriptions API). Operational rules in `docs/BUSINESS-RULES.md`.
    - **0035 + 0036 (Spoke white-label):** Spoke is the canonical source for behavior/flows; `prototipo/` is canonical for visual identity only (cores, tokens, ícones Lucide); cliente Ueslei is tiebreaker. Dispatch `spoke-parity-checker` subagent upfront during brainstorming + closing at D4 for any slice-2/slice-3 microsprint. See §"Source-of-truth hierarchy" below.
    - **0037 (Maestro MCP inspection):** `spoke-parity-checker` now **prefers** Maestro MCP (`mcp__maestro__inspect_view_hierarchy`, `tap_on`, `back`, `launch_app`, `take_screenshot`, `list_devices`) for structural extraction. Bash + `adb shell uiautomator dump` remains the documented fallback. Both observe the same Android Accessibility surface, so ADR-0010 legal posture is unchanged. The subagent's report carries an `Inspection path:` line so every dispatch is auditable.

Skipping this ritual is not an option, even if the human seems eager to jump to code. **Five minutes of reading saves five hours of rework.**

## Source-of-truth hierarchy (ADR-0035)

Two artifacts, each authoritative only on what it actually governs. When in doubt, ask "is this a behavioral question or a visual question?" and consult the matching source.

1. **Spoke (ex-Circuit Route Planner)** — canonical for **behavior**: which screens exist, how navigation flows, what settings are present, which gestures map to which actions, what features the app has. The end-user is a delivery rider who already uses Spoke daily; functional parity with Spoke is the contract per ADR-0010 (functional fork). Default inspection is via runtime UX observation on Eduardo's licensed install (Samsung M54); other methods are operator's choice per ADR-0010 Amendment 2.
2. **`prototipo/` (Claude Design prototype, client-approved 2026-05-07)** — canonical for **visual identity only**: color tokens (`prototipo/tokens.js`), spacing scale, radii, shadows, typography pairing, icon family (Lucide), animation patterns, decorative creativity. The prototype is a creative reference, not a structural specification.
3. **Cliente Ueslei** — final tiebreaker on any conflict between the two layers above.

When `docs/06-DESIGN-SYSTEM.md` references "the prototype", read it as "the visual identity source"; functional flows and screen presence trace back to Spoke. `docs/inventory/2026-05-26-spoke-vs-rotpro.md` is the canonical Spoke→implementation mapping per slice.

### Spoke deep-dive default behavior (per ADR-0036, amended by ADR-0037 — 2026-05-26)

For any **slice-2 (Telas Core) or slice-3 (Real backend) microsprint** whose flow has a Spoke equivalent, the `spoke-parity-checker` subagent is dispatched **proactively and upfront during brainstorming** — BEFORE asking Eduardo UI/UX questions that Spoke already answers structurally. This is the default; do not offer alternatives ("inspect Spoke first or just ask the user?"). The inspection produces a structural baseline that informs the spec, and the same subagent is dispatched again at D4 closing for verification (the gate documented in ADR-0036 and `docs/M2-SLICE-CHECKLIST.md` §Verification).

**Inspection path (per ADR-0037):** the subagent prefers **Maestro MCP** (`mcp__maestro__inspect_view_hierarchy`, `tap_on`, `back`, `launch_app`, `take_screenshot`, `list_devices`) because the hierarchy output is structured (paste-verbatim into the inventory; no paraphrasing into existence) and Maestro auto-navigates state coverage that synchronous bash sessions made tedious. When Maestro is unavailable (CLI missing, MCP not connected, driver crash), the subagent falls back to `adb shell uiautomator dump` + `screencap` — same Android Accessibility surface, slower workflow. Per ADR-0010 Amendment 2, other inspection methods (APK inspection, decompilation, resource extraction) are operator's choice when faster than runtime — what matters is what the shipped APK contains, not how we got the information. The chosen path is recorded in every dispatch report's `Inspection path:` line.

Ask Eduardo only for:
- **(a)** Decisions Spoke doesn't cover (data migration paths, original RotPro features like ScreenShare/Pix paywall, scope cuts per `docs/inventory/2026-05-26-spoke-vs-rotpro.md` §7).
- **(b)** Directives that override Spoke (cliente preference per the 7 locked directives in inventory §7.1, e.g. no Apple/Facebook auth, no iOS).
- **(c)** A one-line confirmation that the device is connected (`adb devices` shows `RQCW401G33T device`, or `mcp__maestro__list_devices` returns it) and Spoke is logged-in before dispatch.

Out of scope for this rule: slices 4 (Stripe paywall — original RotPro), 5 (sentido casa — original RotPro), 6 (LGPD — legal-only), 7 (admin panel — original RotPro). Those have no Spoke equivalent to inspect.

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
| Routing | GraphHopper self-hosted | SP-Capital only (4GB droplet); expansion to Sudeste planejado pós-slice-3 |
| Server | Ubuntu 24.04 on DigitalOcean (client's account) | 4GB droplet pós-M1; resize quando volume justificar |
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
| Mobile | Dart DTOs (manual mirror) | `apps/mobile/lib/features/<feature>/data/dto/<name>_dto.dart` |

Rules (full text in `docs/03-CONVENTIONS.md` §8 and `docs/02-ARCHITECTURE.md` "API Contracts & Type Safety"):

1. Never return `@prisma/client` rows from a handler. Always whitelist via a TypeBox response schema.
2. Every Dart DTO file starts with `// Mirror of: apps/backend/src/<feature>/schemas.ts -> <SchemaName>` (single-DTO) or `... -> {Schema1, Schema2, ...}` (multi-DTO) and matches the TypeBox shape 1:1 (no renaming, no field skips). ASCII `->` only, no backticks.
3. A change to a TypeBox schema and its Dart mirror travel in the same commit.

Reference template: `apps/mobile/lib/features/auth/data/dto/_template.dart`. Plano futuro: substituir o mirror manual por OpenAPI export (`@fastify/swagger`) + Dart codegen quando o volume justificar (deferido — não bloqueante). See ADR-0013.

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
- Use `/verify-slice` as the pre-PR gate — it packages `M2-SLICE-CHECKLIST.md` §Verification (flutter analyze + test, bun typecheck, `adr-guardian` subagent) into one orchestrated report. See ADR-0018.
- **For mobile TDD (opcional pós-reset), dispatch the `flutter-test-author` subagent BEFORE implementing any new widget/provider/service in `apps/mobile/lib/`.** It writes the failing test first, creates a `throw UnimplementedError()` stub so the test fails on the assertion (not on import), and hands off to the implementer with the required API surface. It refuses to write production code itself — the bias-break is the point + um hook `block-test-author-impl.sh` em `.claude/hooks/` enforça mecanicamente. Mock library is `mocktail ^1.0.5` (no codegen); manual fakes under `test/<feature>/_helpers/` remain the default. See ADR-0025.
- **For mobile perf review, dispatch the `flutter-perf-auditor` subagent AFTER finishing a screen and BEFORE opening the slice PR.** Read-only, produces a Markdown punch-list categorized must-fix / should-fix / nit across 9 canonical checks (ListView.builder discipline, missing `const`, `ref.watch` granularity, UI-thread heavy work, RepaintBoundary, tile cache, list keys, image decoding, StatefulWidget overuse). It cannot edit code — the allowlist excludes Edit/Write/MultiEdit.

### In-Loop Auto-Validation (ADR-0018 + ADR-0024)

Four hooks run automatically around every assistant edit/turn — non-blocking, signal-only:

**Stop hooks** (fire once at end of turn, batched across all edits):

- `analyze-changed-dart.sh` — `flutter analyze --no-pub` over `.dart` files edited in `apps/mobile/lib/` this turn.
- `check-dto-mirror.sh` — warns when an `apps/backend/src/<feature>/schemas.ts` edit lacks its paired Dart DTO update (ADR-0013 contract).
- `warn-adr-drift.sh` — warns when `pubspec.yaml`/`package.json`/`schema.prisma`/`docker-compose.yml` was edited this turn but no ADR was added/modified.

**PostToolUse hook** (fires per Edit/Write/MultiEdit, debounced):

- `run-riverpod-codegen.sh` (ADR-0024) — when a `@riverpod`-annotated Dart file or any `part '*.g.dart'` host is edited, regenerates `.g.dart` via `dart run build_runner build --delete-conflicting-outputs`. Lock-file debounce (90s window) coalesces burst-edits so multiple provider edits in one turn run codegen only once. Sits next to the pre-existing `format-dart.sh` in the same matcher entry.

These are the agent-turn equivalent of Lefthook (which fires at `git commit`). They don't replace `adr-guardian` or the slice checklist — they surface drift earlier, while context is still hot. Full design in ADR-0018; PostToolUse extension rationale in ADR-0024; layered boundary in ADR-0012.

### Spec-Driven Workflow (opt-in pós-reset 2026-05-26)

Post-reset, specs/plans formais são **opcionais**. Templates ficam em `docs/superpowers/specs/0000-template.md` e `docs/superpowers/plans/0000-template.md` pra quem quiser usar — mas o caminho default agora é mais leve: brainstorm mental → implementa → commit. Use specs/plans formais só pra trabalho substancial onde a decisão arquitetural NÃO é óbvia do Spoke (slice 4 Stripe paywall, slice 7 admin panel — esses sim merecem spec). Slice 2 telas Spoke-aligned não merece spec por tela — Spoke é o spec.

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

## Session End Protocol (opcional pós-reset 2026-05-26)

Sessions são **opcionais** agora. Só vale criar uma quando o trabalho da sessão é não-óbvio do git log (decisão arquitetural relevante, débito técnico aceito, lição aprendida que outras sessões podem repetir). Commits bem-escritos cobrem a maior parte do "o que aconteceu". Para mexer em TODO/CHANGELOG: edit inline no mesmo commit do trabalho.

Se for criar session log:

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
- Screens (Spoke catalogue) → `docs/inventory/2026-05-26-spoke-vs-rotpro.md`
- Design system → `docs/06-DESIGN-SYSTEM.md`
- Infrastructure → `docs/07-INFRA.md`
- M2 roadmap → `docs/08-ROADMAP-v2.md` (v1 archived at `docs/archive/2026-05-26-08-ROADMAP-v1-pre-pivot.md`)
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
