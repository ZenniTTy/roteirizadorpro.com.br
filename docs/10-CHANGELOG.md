# 10 — Changelog (Documentation)

Tracks structural and scope changes to the documentation itself. Code changes go into git history; this file is for documentation reorganization milestones.

## 2026-05-08

- **Schema source of truth codified** ([ADR-0013](decisions/0013-api-contract-source-of-truth.md)): Prisma owns the DB, TypeBox owns the HTTP contract, Dart DTOs mirror TypeBox 1:1 via a `// Mirror of:` header. Rule added to `CLAUDE.md`, new "API Contracts & Type Safety" section in `02-ARCHITECTURE.md`, new §8 in `03-CONVENTIONS.md`. Reference template at `apps/mobile/lib/features/auth/data/dto/_template.dart`. OpenAPI export + codegen deferred to post-M1.

## 2026-05-07

- **Documentation reorganization:** removed redundant files (`agents.md`, `CODE_OF_CONDUCT.md`, `docs/DESIGN-PROMPT.md`), unified roadmap into a single M1-focused `docs/08-ROADMAP.md`, renumbered docs to contiguous 01–10.
- **Prototype as canonical UI source:** `prototipo/` (Claude Design output, client-approved) is now referenced from `docs/05-SCREENS.md` and `docs/06-DESIGN-SYSTEM.md`. Tokens (including `neon`) and 19-screen list synced.
- **Roadmap focused on M1 only.** M2 scope deferred until post-M1 client conversation.
- **Server titularity clarified:** DigitalOcean account is the client's. Eduardo has admin access.
- **1GB droplet workaround documented as the M1 reality.** 8GB resize + Sudeste reimport is post-M1 work.
