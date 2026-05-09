# ADR-0004: Use Prisma 7 as ORM

- **Status:** Accepted
- **Date:** 2026-05-05
- **Deciders:** Eduardo

## Context

The backend needs an ORM that plays well with TypeScript strict mode, supports PostgreSQL fully (the chosen database), and offers a clean migrations workflow. The schema is small in M1 (users + refresh_tokens) but grows in M2 (subscriptions, payments, routes, stops, webhook_events).

## Options Considered

### Option A — Prisma 7

- Pros: Excellent TypeScript DX (auto-generated types); robust migrations; query API is type-safe; mature ecosystem; v7 introduces driver adapters which decouple Prisma from its client engine and allow connection pooling via `pg`.
- Cons: Generated client output path moved (now configurable, defaults to `./generated/client` in v7); breaking changes from v6 must be respected.

### Option B — Drizzle ORM

- Pros: Lightweight, SQL-first, no codegen runtime.
- Cons: Less mature; fewer adapters; the SQL-first style adds friction for the common 80% of CRUD work.

### Option C — TypeORM

- Pros: Active Record / Data Mapper hybrid; some users prefer the syntax.
- Cons: TypeScript types are weaker than Prisma's; project momentum decreased over the last years.

### Option D — Raw SQL via `pg`

- Pros: Maximum control.
- Cons: No type safety; manual migrations; we'd reimplement a partial ORM anyway.

## Decision

Use **Prisma 7** with the **`@prisma/adapter-pg` driver adapter** mandatory.

## Consequences

- Positive: End-to-end type safety from DB to API response (pair with TypeBox); minimal boilerplate; visual schema editor; good docs.
- Negative: Need to track Prisma 7 migration patterns — driver adapters are recent; `prisma.config.ts` is the new config home, not just `schema.prisma`.
- Neutral: Generated client lives under `apps/backend/generated/` — needs to be in `.gitignore` (already configured).

## Implementation Notes

- `schema.prisma` `generator` block uses `provider = "prisma-client"` (not `"prisma-client-js"` — that's pre-v7).
- `output` is set to `./generated/client`.
- Connection pooling via the `pg` driver adapter (the engine no longer manages the pool itself).
- `prisma.config.ts` at the root of `apps/backend/` configures schema location, migrations, and seed.
- Migrations stored under `apps/backend/prisma/migrations/`.
- Dev migrations created with `prisma migrate dev`. Production migrations applied with `prisma migrate deploy`.

## References

- Validation against Context7: `/prisma/skills` (official Prisma agent skills repo, v7.6.0 confirmed at time of decision).
- `docs/02-ARCHITECTURE.md` (Data Model section).
