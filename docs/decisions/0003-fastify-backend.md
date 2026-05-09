# ADR-0003: Use Fastify v5 for Backend (over Express, NestJS, FastAPI)

- **Status:** Accepted
- **Date:** 2026-05-05
- **Deciders:** Eduardo

## Context

The backend serves auth (M1) and full route/payment/admin features (M2). Project size is ~15-20 endpoints, single dev plus AI agents. The mobile client is Flutter (Dart) — symmetry of typed languages between client and server is desirable.

## Options Considered

### Option A — Node.js + Fastify v5 (TypeScript)

- Pros: Stable v5; native TypeScript support; built-in JSON Schema validation (now via TypeBox); 2-3x faster than Express; clean plugin ecosystem (auth, helmet, CORS, rate-limit available as plugins); huge npm package ecosystem; symmetric "shape of code" with Dart on mobile (async/await, strict types).
- Cons: Less opinionated than NestJS — requires us to impose conventions.

### Option B — Node.js + NestJS

- Pros: Highly structured (modules, services, controllers, DI); good for large teams.
- Cons: Decorator/DI overhead is overkill for ~20 endpoints; more boilerplate; performance below Fastify (NestJS can run on Fastify, but the decorators still cost something); higher learning curve.

### Option C — Node.js + Express

- Pros: Veteran, max community.
- Cons: No TypeScript-first design; no built-in validation; no schema-driven docs; considered legacy by 2026.

### Option D — Python + FastAPI

- Pros: Excellent Pydantic models; great for ML-heavy projects.
- Cons: Asymmetry with Flutter (different language/runtime/ecosystem); no official Efí Bank Node SDK avoids that asymmetry savings (Efí has no official SDK in any language); Brazilian dev pool slightly smaller for FastAPI vs Node.

## Decision

Use **Node.js 20 LTS + Fastify v5 + TypeScript (strict)** with **TypeBox** as the type provider for request/response validation.

## Consequences

- Positive: Type symmetry with Flutter; fast HTTP layer; minimal boilerplate; rich plugin ecosystem; TypeBox compiles JSON Schema and gives TypeScript types in one shot.
- Negative: Less guard-rails than NestJS — we must enforce structure ourselves via conventions and lint rules.
- Neutral: Fastify v5 has a behavioral change in schema validation (root must be `type: 'object'`) — handled by using TypeBox idioms.

## Implementation Notes

- `tsconfig.json` with `"strict": true`, `"noUncheckedIndexedAccess": true`.
- Plugins: `@fastify/jwt`, `@fastify/helmet`, `@fastify/cors`, `@fastify/rate-limit`, `@sinclair/typebox`, `pino`, `bcrypt`.
- Logger: Pino (Fastify default), JSON to stdout.
- Process management: Docker container with `restart: unless-stopped`.

## References

- Validation against Context7: `/fastify/fastify` (verified v5 stable, TypeBox recommended).
- `docs/02-ARCHITECTURE.md`
