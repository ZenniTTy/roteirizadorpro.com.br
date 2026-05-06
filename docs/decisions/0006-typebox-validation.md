# ADR-0006: Use TypeBox as Fastify Type Provider

- **Status:** Accepted
- **Date:** 2026-05-05
- **Deciders:** Eduardo

## Context

Fastify v5 validates request and response payloads using JSON Schema. Writing JSON Schema by hand is verbose and disconnected from TypeScript types — leading to drift between runtime validation and compile-time types. A "type provider" bridges this gap.

## Options Considered

### Option A — TypeBox (`@sinclair/typebox`)

- Pros: First-party recommended type provider for Fastify v5; defines schemas in TypeScript that compile to JSON Schema and infer TS types simultaneously; small runtime; no codegen step.
- Cons: Yet another DSL to learn (though small).

### Option B — JSON Schema written by hand

- Pros: Standard, portable, tool-agnostic.
- Cons: Verbose; types must be hand-maintained in parallel; constant drift risk.

### Option C — Zod with adapter

- Pros: Familiar to many TS devs; rich validation primitives.
- Cons: Not natively built for Fastify; uses an adapter; slower at runtime than TypeBox; doesn't compile to JSON Schema natively (loses Fastify's serialization optimization).

## Decision

Use **TypeBox** as the type provider for all Fastify routes.

## Consequences

- Positive: Single source of truth for shape (TS type + JSON Schema generated together); fast runtime validation; can be reused for OpenAPI generation.
- Negative: Slight learning curve for the TypeBox DSL.
- Neutral: All schemas live near the routes that use them, e.g. `apps/backend/src/routes/auth/schemas.ts`.

## Implementation Notes

- Install: `npm i @sinclair/typebox`.
- Register provider: `import { TypeBoxTypeProvider } from '@fastify/type-provider-typebox'` and pass to Fastify factory.
- Define schemas with `Type.Object({ ... })` and infer TS via `Static<typeof MySchema>`.

## References

- Validation against Context7: `/fastify/fastify` (TypeBox confirmed as recommended type provider for v5).
