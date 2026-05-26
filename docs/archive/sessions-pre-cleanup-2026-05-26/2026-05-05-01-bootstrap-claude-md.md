# 2026-05-05-01 — Bootstrap CLAUDE.md

## Metadata

- **Date**: 2026-05-05 (America/Sao_Paulo)
- **Sequence**: 01
- **Agent**: Claude web (Opus 4.7)
- **Human**: Eduardo
- **Topic**: bootstrap-claude-md
- **Duration**: ~ongoing (multi-message planning session)
- **Related ADRs**: pending — to be authored next
- **Related TODO items**: M1 bootstrap (file does not yet exist)

## Goal of the Session

Establish the operational foundation of the repository before any product code is written: validate the technology stack against current documentation (Context7), author the canonical operating manual (`CLAUDE.md`), and create the supporting structure for session logs and decision records.

## What Was Done

- Reviewed the client brief and proposal (Roteirizador Pro, M1 + M2 milestones, BRL 4,000 total).
- Established legal positioning: functional fork of Circuit + 100% original visual identity (no copy of icons, colors, typography, microcopy).
- Confirmed mobile stack: Flutter + Riverpod 3 (codegen with `@riverpod`).
- Confirmed backend stack: Node.js + Fastify v5 + TypeBox + Prisma 7 (driver adapters) + PostgreSQL 16 + Redis 7.
- Validated stack via Context7:
  - Fastify v5: confirmed stable, TypeBox recommended as type provider.
  - Prisma 7.6.0: confirmed (was about to recommend v6 — corrected).
  - Riverpod 3.0.2: confirmed (was about to recommend v2 — corrected).
  - Efí Bank: documented at `/websites/dev_efipay_br` (88 snippets); no official Node SDK — direct HTTPS calls required.
  - GraphHopper: well-documented at `/graphhopper/graphhopper` (benchmark 92.7).
- Inspected the existing repository: branch `develop`, remote `https://github.com/ZenniTTy/-APP---Entrega-Smart.git`, only `Initial commit` present.
- Authored `CLAUDE.md` (root) — full operating manual covering: critical DON'Ts/DOs, project identity, locked stack table, single source of truth map, decision flow, Context7 protocol, filesystem protocol, Git protocol, session log protocol, TODO ownership, onboarding ritual, code style baseline, naming conventions, secrets handling, LGPD compliance section, self-update rules.
- Created `docs/sessions/` directory with `0000-template.md` and `0001-INDEX.md`.

## Decisions Made

1. **Functional-fork-only positioning** — Avoid all copyright/trade-dress risk by replicating only flows and behaviors of Circuit, never visual assets. To be formalized in ADR-0010.
2. **Language: English for docs and commits** — Better for handoff and aligned with industry standard. Conversation with Eduardo remains in Portuguese.
3. **Bootstrap commits go directly to `develop`** — While in scaffolding phase. Once product code starts, switch to branch-per-feature with PRs.
4. **TODO.md owned by Claude Code** — Living task list, read at session start, updated at session end.
5. **Session logs mandatory** — `docs/sessions/YYYY-MM-DD-NN-topic.md` at the end of each meaningful session, indexed in `0001-INDEX.md`.
6. **No code comments** — Clean code only. Explanations go in docs/ADRs.
7. **Context7 mandatory before any library proposal** — No exceptions for libraries within reach of the cutoff date.

## Open Questions Left

- [ ] Final domain registration of `roteirizadorpro.com.br` (Eduardo to confirm registrar and DNS provider).
- [ ] Whether to use Cloudflare or DigitalOcean Spaces for static assets.
- [ ] Sentry account ownership (Eduardo's existing or new for the project).
- [ ] When the partners' Efí accounts are fully approved (currently being opened by Eduardo and his partner).
- [ ] Whether the landing page needs PT/EN i18n (probably PT only initially).

## Files Changed

**Created**:
- `CLAUDE.md`
- `docs/sessions/0000-template.md`
- `docs/sessions/0001-INDEX.md`
- `docs/sessions/2026-05-05-01-bootstrap-claude-md.md` (this file)

**Modified**:
- none yet

**Deleted**:
- none

## Commits Pushed

To be filled when the commit is made at the end of this session.

## Hand-off Notes for Next Session

- **Current branch**: `develop`.
- **Working tree**: should be clean after the commits made in this session.
- **Next priorities** (per agreed roadmap):
  1. Author `README.md` (root) — repo entry point.
  2. Author `docs/01-PROJECT.md` — vision, scope, milestones.
  3. Author `docs/02-ARCHITECTURE.md` — technical architecture, flows, schema, contracts.
  4. Author `docs/03-CONVENTIONS.md` — code, commits, branches, PRs.
  5. Author `docs/04-ROADMAP.md` — M1 and M2 with concrete deliverables.
  6. Author `docs/05-DISASTER-RECOVERY.md`.
  7. Create all ADRs (`0001` through `0010`).
  8. Author `SECURITY.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`.
  9. Create `TODO.md` populated with M1 tasks.
  10. Create `.gitignore`, `.editorconfig`, `.github/pull_request_template.md`.
- **Context7 calls remaining for full validation** (use sparingly — 3 per turn cap):
  - GraphHopper detailed install/config when starting infra work.
  - `@fastify/jwt` for auth implementation.
  - `google_mlkit_text_recognition` for OCR feature.

## Reference Material Used

- Efí Bank Pix Split docs (web fetch): https://dev.efipay.com.br/docs/api-pix/split-de-pagamento-pix
- Context7 query: Fastify v5 — `/fastify/fastify`.
- Context7 query: Prisma 7 — `/prisma/skills` (note: `/prisma/skills` is an official Prisma-maintained collection of agent skills — recommended further reading).
- Context7 query: Riverpod 3 migration — `/rrousselgit/riverpod`.
- Context7 query: Efí Bank — `/websites/dev_efipay_br`.
- Context7 resolve: GraphHopper — `/graphhopper/graphhopper` (full query deferred to infra-work session).
