# Session 2026-05-08-04 — backend-auth-healthchecks

## Metadata

- **Date**: 2026-05-08 (America/Sao_Paulo)
- **Sequence**: 04
- **Agent**: Claude Code (Opus 4.7, 1M ctx)
- **Human**: Eduardo
- **Topic**: Backend auth + healthchecks (M1 Phase 2)
- **Duration**: ~1h30m
- **Related ADRs**: ADR-0006 (TypeBox), ADR-0004 (Prisma 7), ADR-0013 (API contract source-of-truth), ADR-0011 (Bun-as-package-manager)
- **Related TODO items**: Phase 2 — Backend auth, healthchecks, /routes/optimize placeholder, logging + rate limits

## Goal of the Session

Ship the four M1 backend auth endpoints (`/auth/register`, `/auth/login`, `/auth/refresh`, `/auth/me`), three healthchecks (`/health`, `/health/db`, `/health/graphhopper`), and the `POST /routes/optimize` placeholder — all on the just-codified ADR-0013 contract (TypeBox schemas as canonical source, Dart DTOs mirroring 1:1).

## What Was Done

### Research first (per the rule of consult-Context7-and-internet-before-codifying)

- `/fastify/fastify-type-provider-typebox` (Context7) — confirmed the canonical pattern: schemas in dedicated files, `Static<typeof Schema>` for types, `withTypeProvider<TypeBoxTypeProvider>()` once on the Fastify instance.
- `/fastify/fastify-jwt` (Context7) — confirmed the RS256 registration pattern, `fastify.decorate('authenticate', ...)` wrapped in `fastify-plugin`, `onRequest: [fastify.authenticate]` on protected routes.
- `/fastify/fastify-rate-limit` (Context7) — confirmed `config.rateLimit` per-route override; `config: { rateLimit: false }` to disable on `/health/*`.
- WebSearch — refresh token rotation (OWASP 2026): refresh = opaque random ≥ 64 bytes (NOT a JWT), stored as SHA-256 hash, rotated on each use, reuse of a revoked token revokes the entire session family.
- WebSearch — bcrypt cost 12 vs argon2id (OWASP 2026): argon2id is the new default; bcrypt cost 12 is still acceptable. Stayed with bcrypt for M1 (already in stack/ADRs); added a TODO discovery item for post-M1 argon2id review.

### Implementation

- **Prisma client move:** Prisma 7's `prisma-client` generator emits TypeScript files with `// @ts-nocheck` and extension-less internal imports. The generator output was at `apps/backend/generated/client/`, outside `tsconfig.rootDir`. Moved it to `apps/backend/src/generated/client/` (schema `output = "../src/generated/client"`); updated `.gitignore` accordingly; regenerated.
- **Runtime decision:** the same generator's extension-less imports break Node ESM at runtime. Standardized on `tsx src/index.ts` for both `dev` and `start` (no `tsc` emit). Promoted `tsx` from devDependency to dependency. `build` is now `tsc --noEmit` (pure typecheck — same as `typecheck`, kept for CI compatibility). Documented as a post-M1 revisit item.
- **Plugin layer (`apps/backend/src/plugins/`):**
  - `prisma.ts` — instantiates `PrismaClient` with `@prisma/adapter-pg`, decorates `app.prisma`, disconnects on close.
  - `auth.ts` — registers `@fastify/jwt` with RS256 keys (with a small `\n` → real-newline normalizer for env-loaded PEM strings), decorates `app.authenticate` that 401s on invalid/missing token. Uses `declare module 'fastify' { interface FastifyInstance { authenticate: ... } }` and `declare module '@fastify/jwt' { interface FastifyJWT { payload: { sub: string }; user: ... } }` to type both sides.
- **Auth feature (`apps/backend/src/auth/`):**
  - `schemas.ts` — TypeBox source of truth: `UserSchema`, `ErrorResponseSchema`, `RegisterRequest/ResponseSchema`, `LoginRequest/ResponseSchema`, `TokensSchema`, `RefreshRequest/ResponseSchema`, `MeResponseSchema`. All exported with their `Static<typeof X>` aliases (per ADR-0013).
  - `tokens.ts` — `generateRefreshToken()` returns 64 bytes of `crypto.randomBytes` as hex (128 chars on the wire), hashed with `crypto.createHash('sha256')` for the DB; `hashRefreshToken` for lookup-by-hash on `/auth/refresh`.
  - `handlers.ts` — `registerHandler` (409 on duplicate, bcrypt cost 12, normalize email to lowercase trim), `loginHandler` (401 on bad creds, mints access JWT + opaque refresh, persists hash + expiresAt), `refreshHandler` (rotates atomically inside `prisma.$transaction`; on `revokedAt !== null` triggers reuse-detection cascade revoking all of the user's active refresh tokens with a logged warning), `meHandler` (uses `request.user.sub`, returns 404 if user vanished). All handlers funnel Prisma rows through `toUserDto` to strip `passwordHash` / `updatedAt`.
  - `routes.ts` — registers four routes via `FastifyPluginAsyncTypebox` with full request/response schemas wired and per-endpoint `config.rateLimit` (`/login` 5/15min, `/register` 3/h, `/refresh` 10/min). `/me` is the only auth-required route via `onRequest: [app.authenticate]`.
- **Health feature (`apps/backend/src/health/`):**
  - `routes.ts` — `/` returns `{ status, uptimeSeconds }`; `/db` runs `prisma.$queryRaw\`SELECT 1\`` with latency; `/graphhopper` does a 2s-timeout `fetch('/health')` against `GRAPHHOPPER_BASE_URL`. All three opt out of the global rate limit.
- **Routes feature (`apps/backend/src/routes/`):**
  - `routes.ts` — `POST /optimize` (auth-gated) returns 501 `{ status: 'not_implemented', message }` until M2.
- **Server wiring (`server.ts`):** registers helmet → cors → rate-limit (global) → prisma plugin → auth plugin → root route → `/health/*` → `/auth/*` → `/routes/*`. Marked `/` (root) as `rateLimit: false`.
- **Mobile mirrors (per ADR-0013):** authored `apps/mobile/lib/features/auth/data/dto/auth_dtos.dart` containing `AuthUserDto`, `RegisterRequestDto`, `RegisterResponseDto`, `LoginRequestDto`, `LoginResponseDto`, `RefreshRequestDto`, `RefreshResponseDto`, `MeResponseDto`, `AuthErrorDto`. Each class has a `/// Mirror of:` header pointing to its TypeBox source. `flutter analyze --no-pub` clean.
- **Tooling:** added `scripts/generate-jwt-keys.sh` — generates a 2048-bit RSA pair to `apps/backend/certs/jwt_{private,public}.pem` (gitignored) and prints two env-var lines suitable for appending to `apps/backend/.env`. Used it once to bootstrap local dev. Updated `.env.example` to point at the script.
- **Migration:** `bunx prisma migrate dev --name init_auth_tables` produced `prisma/migrations/20260508075149_init_auth_tables/migration.sql`. Database in sync.

### Verification (round-trip smoke test against the live dev server)

| Step | Expected | Actual | Status |
|---|---|---|---|
| `GET /health` | 200 + `{status: ok}` | 200 + `{"status":"ok","uptimeSeconds":29}` | PASS |
| `GET /health/db` | 200 (prisma raw query OK) | 200 + `latencyMs:168` | PASS |
| `GET /health/graphhopper` | 503 (graphhopper not up locally — `routing` profile is opt-in) | 503 + `error:"fetch failed"` | PASS (expected degraded) |
| `POST /auth/register` | 201 + `user`, no `passwordHash` leak | 201 + correct shape | PASS |
| `POST /auth/login` | 200 + access(JWT 487 chars) + refresh(opaque 128 chars) + user | matches | PASS |
| `GET /auth/me` w/ token | 200 + user | matches | PASS |
| `GET /auth/me` no token | 401 unauthorized | 401 + correct error shape | PASS |
| `POST /auth/refresh` (valid) | 200 + new access + new refresh | matches | PASS |
| `POST /auth/refresh` w/ now-revoked old refresh | 401 + `token_reuse` + revoke all | 401 + correct shape + log warning | PASS |
| `POST /auth/refresh` w/ post-cascade rotated refresh | 401 + `token_reuse` (cascade reached it) | 401 + correct | PASS |
| Wrong password | 401 invalid_credentials | matches | PASS |
| Duplicate email | 409 email_taken | matches | PASS |
| Missing required field | 400 FST_ERR_VALIDATION (TypeBox) | matches | PASS |
| `/routes/optimize` no auth | 401 | matches | PASS |
| `/routes/optimize` w/ auth | 501 not_implemented | matches | PASS |

Database cleaned post-test (`DELETE FROM refresh_tokens; DELETE FROM users WHERE email='smoke@…'`).

## Decisions Made

1. **bcrypt cost 12 stays for M1; argon2id revisit post-M1.** OWASP 2026 prefers argon2id (GPU-resistant, configurable memory cost), but bcrypt cost 12 is still acceptable and is already locked in the stack/ADRs. Switching now would mean a new ADR + a "rehash on next login" migration. Filed as a discovery TODO with full rationale.
2. **Refresh token = opaque hex (`randomBytes(64).toString('hex')`), not a JWT.** Stored as SHA-256 hash in the DB. Avoids carrying claims in a refresh token (the access JWT does that), and lets the DB be the authoritative source for revocation state. Rotation is atomic via `prisma.$transaction`.
3. **Reuse detection revokes the entire user's refresh-token set, no `family_id` for M1.** Stricter than per-device family scoping, simpler to implement, and acceptable for M1 traffic profile. Filed `family_id` as a post-M1 enhancement.
4. **Backend runtime = `tsx src/index.ts` for both dev and prod.** Prisma 7's `prisma-client` generator emits TS-only with extension-less internal imports — incompatible with raw Node ESM. tsx handles the resolution. Documented as a post-M1 revisit item; not an ADR yet because the alternative (esbuild bundling) is genuinely deferred work, not a stack lock.
5. **Generated Prisma client lives at `apps/backend/src/generated/client/`.** The previous location `apps/backend/generated/` violated `tsconfig.rootDir`. Moving inside `src/` is the standard placement for the new `prisma-client` generator.

## Open Questions Left

- [ ] Whether to add an integration test suite (e.g. via `node:test` + supertest) that re-runs the smoke-test paths automatically on every commit. M1 doesn't strictly need it (manual smoke test passed) but auth is exactly the kind of code that grows regression risk; revisit before Phase 4 acceptance.
- [ ] Whether to add `@fastify/swagger` now (for `/docs` UI + OpenAPI export, foundation for post-M1 codegen) or wait until M2 endpoints are designed. Leaning wait — no value for two M1 endpoints.

## Files Changed

**Created (backend):**
- `apps/backend/src/plugins/prisma.ts`
- `apps/backend/src/plugins/auth.ts`
- `apps/backend/src/auth/schemas.ts`
- `apps/backend/src/auth/tokens.ts`
- `apps/backend/src/auth/handlers.ts`
- `apps/backend/src/auth/routes.ts`
- `apps/backend/src/health/schemas.ts`
- `apps/backend/src/health/routes.ts`
- `apps/backend/src/routes/schemas.ts`
- `apps/backend/src/routes/routes.ts`
- `apps/backend/prisma/migrations/20260508075149_init_auth_tables/migration.sql`
- `scripts/generate-jwt-keys.sh`

**Created (mobile):**
- `apps/mobile/lib/features/auth/data/dto/auth_dtos.dart`

**Modified:**
- `apps/backend/src/server.ts` (wires plugins + routes)
- `apps/backend/prisma/schema.prisma` (output path → `../src/generated/client`)
- `apps/backend/package.json` (start uses tsx; tsx → dependency; build is `tsc --noEmit`; main → `src/index.ts`; added `fastify-plugin`)
- `apps/backend/.env.example` (pointer to `scripts/generate-jwt-keys.sh`)
- `.gitignore` (`apps/backend/generated/` → `apps/backend/src/generated/`)
- `TODO.md` (Phase 2 backend tasks marked done; three post-M1 discovery items added; last-updated date)
- `docs/sessions/0001-INDEX.md` (this session)

**Deleted:**
- `apps/backend/generated/` (moved into `apps/backend/src/generated/`)

## Commits Pushed

```
<hash>  feat(backend): implement auth + healthchecks + routes/optimize placeholder
<hash>  feat(mobile): mirror auth typebox schemas as dart dtos (adr-0013)
<hash>  docs(sessions): record backend auth + healthchecks shipping
```

## Hand-off Notes for Next Session

- **Branch:** `develop`. No in-progress work.
- **Local dev:** `cd apps/backend && bun run dev`. Postgres + Redis must be up (`docker compose -f infra/docker-compose.yml up -d`). `.env` is gitignored — bootstrap with `scripts/generate-jwt-keys.sh >> apps/backend/.env` (one-time after copying `.env.example`).
- **Smoke test commands** (kept in this log for replay):
  - `curl http://127.0.0.1:3000/health`
  - `curl -X POST http://127.0.0.1:3000/auth/register -H 'Content-Type: application/json' -d '{"email":"a@b.c","password":"abcdefgh","name":"X"}'`
  - `curl -X POST http://127.0.0.1:3000/auth/login -H 'Content-Type: application/json' -d '{"email":"a@b.c","password":"abcdefgh"}'`
- **Next track:** mobile auth integration (Dio client + Bearer interceptor + auto-refresh on 401 + token storage in `flutter_secure_storage` + Riverpod `AuthNotifier`). All four M1 backend endpoints exist and return the exact shape the mobile DTOs already mirror.
- **Then:** GraphHopper SP graph + benchmark (technical-risk track for M1 acceptance criterion #3, p95 < 200ms).

## Reference Material Used

- Context7: `/fastify/fastify-type-provider-typebox` (consulted 2026-05-08).
- Context7: `/fastify/fastify-jwt` (consulted 2026-05-08).
- Context7: `/fastify/fastify-rate-limit` (consulted 2026-05-08).
- Context7: `/prisma/prisma` (Prisma 7 `prisma-client` generator behaviour, consulted 2026-05-08).
- Web: OWASP Cheat Sheet — Password Storage (bcrypt cost ≥ 10, argon2id default).
- Web: 2026 industry articles on JWT refresh-token rotation and reuse detection.
- Existing project docs: ADR-0006 (TypeBox), ADR-0013 (API contract source-of-truth), ADR-0011 (Bun-as-package-manager), `docs/02-ARCHITECTURE.md` Critical Flow 1.
