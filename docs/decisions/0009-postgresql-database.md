# ADR-0009: Use PostgreSQL 16 as Primary Database

- **Status:** Accepted
- **Date:** 2026-05-05
- **Deciders:** Eduardo

## Context

The application stores users, sessions, subscriptions, payments, routes, stops, and webhook events. Volume is small to moderate (thousands of users, daily transactions in the hundreds early on). Need: relational integrity, JSONB for flexible payloads (webhook events, geocoding cache), good Prisma support.

## Options Considered

### Option A — PostgreSQL 16

- Pros: Mature, free, ACID, native JSONB, full-text search, strong Prisma support, ubiquitous Brazilian dev knowledge, single dependency.
- Cons: None for this scale.

### Option B — MySQL / MariaDB

- Pros: Mature, free.
- Cons: JSON support weaker; Prisma support less polished than PG; less idiomatic for our use cases.

### Option C — SQLite

- Pros: Zero ops.
- Cons: Single-writer concurrency limit; not suitable for multi-tenant SaaS even at small scale.

### Option D — MongoDB

- Pros: Schema-flexible.
- Cons: Subscriptions and payments demand transactional integrity which is awkward in document stores.

## Decision

Use **PostgreSQL 16** in a Docker container, accessed via Prisma 7 + `@prisma/adapter-pg`.

## Consequences

- Positive: Solves all current and foreseeable data needs; single DB engine to back up and monitor; rich type system maps perfectly to Prisma.
- Negative: Operational responsibility for backups, vacuum, and migrations.
- Neutral: Connection pooling delegated to `pg` driver via Prisma's adapter.

## Implementation Notes

- Container: official `postgres:16-alpine`.
- Bound to `127.0.0.1:5432` only.
- Volume: `postgres-data` (persistent Docker volume).
- Daily `pg_dump` at 03:00 (see `docs/06-DISASTER-RECOVERY.md`).
- Strong randomly generated password, stored in server `.env`, never in Git.
- Migrations via Prisma (`prisma migrate dev` for local, `prisma migrate deploy` for prod).

## References

- `docs/02-ARCHITECTURE.md` (Database section).
- `docs/06-DISASTER-RECOVERY.md` (PostgreSQL backup procedure).
