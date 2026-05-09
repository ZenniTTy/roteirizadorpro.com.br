# ADR-0013: TypeBox as the API Contract Source of Truth (with Manual Dart Mirror for M1)

- **Status:** Accepted
- **Date:** 2026-05-08
- **Deciders:** Eduardo
- **Related ADRs:** ADR-0004 (Prisma 7), ADR-0006 (TypeBox), ADR-0002 (Flutter)

## Context

The stack has three potential places where data shape is defined:

1. **Database schema** — Prisma 7 `schema.prisma` (`apps/backend/prisma/schema.prisma`).
2. **HTTP API contract** — TypeBox schemas inside the Fastify backend.
3. **Mobile DTOs** — Dart classes in `apps/mobile/lib/`.

Without an explicit, codified rule for which one is canonical for what, three concrete failure modes appear:

- **Drift between Prisma and the wire.** A handler returns `prisma.user.findUnique()` directly, leaking `password_hash`, `created_at`, internal columns, or future columns added in a later migration. The mobile app starts depending on those fields. A schema change becomes a breaking API change with no warning.
- **Drift between TypeBox and Dart.** The backend renames `home_address` to `homeLocation`; the mobile DTO still parses `home_address`; integration only fails at runtime against a real device.
- **Three writers, no readers.** A future agent (or a tired human at 3 AM) sees three definitions of "User" and edits the wrong one, or replicates redundancy by adding a fourth. This produces entropy — the exact failure mode the human owner is trying to prevent ("não alucinar e causar entropia no codigo replicando redundancia").

The project is at the moment of lowest cost to fix this: backend auth has not been written yet, and only two mobile screens (Login / Register, presentation layer only) ship UI without DTOs. Setting the rule before backend auth lands is the right time.

The 2026 industry consensus, reconfirmed against Context7 (`/fastify/fastify-type-provider-typebox`) and Fastify's own README, is:

- Define request/response with **TypeBox** in dedicated schema files.
- Infer TS handler types via `Static<typeof Schema>`.
- Never expose ORM types (Prisma, Drizzle) directly to the wire — always whitelist via a TypeBox response schema.
- For cross-language clients, export OpenAPI from the TypeBox schemas (`@fastify/swagger`) and run a codegen on the consumer side.

## Options Considered

### Option A — No formal rule (status quo)

- **Pros:** zero work today.
- **Cons:** the entropy this ADR is trying to prevent. Three potential sources of truth, no contract, drift accumulates silently.

### Option B — TypeBox as API source of truth + manual Dart mirror (this ADR, M1)

- **Pros:** matches Fastify's first-party recommendation; one canonical schema per layer; Prisma stays internal which is industry standard; Dart mirror with a `// Mirror of:` header is grep-able and enforceable in code review; OpenAPI export remains a one-line addition post-M1; zero new dependencies; nothing to learn beyond what's already in ADR-0006.
- **Cons:** Dart DTOs need to be edited by hand when the TypeBox schema changes; drift can still happen between commits if the discipline slips. Acceptable for two M1 endpoints; will not scale to 19 screens of M2.

### Option C — `prismabox` (or `prisma-typebox-generator`): auto-generate TypeBox from Prisma

- **Pros:** removes the Prisma → TypeBox manual step.
- **Cons:** the DB schema and the API schema are not the same shape and must not be the same shape. `password_hash`, `created_at`, soft-delete flags, internal foreign keys all live in Prisma but never go on the wire. Auto-generation either over-exposes (security risk) or requires per-field whitelisting that's longer than writing the TypeBox by hand. **Rejected.**

### Option D — Shared cross-language DSL (Zod / Effect Schema / typia + cross-platform codegen)

- **Pros:** single TS source generates both TS and Dart types via codegen.
- **Cons:** reverses ADR-0006 (TypeBox is the type provider; switching now is a stack break); none of these have first-class Dart codegen targets in 2026 — would require writing or adopting a custom generator. **Rejected for M1.**

### Option E — gRPC / Protobuf as the cross-language IDL

- **Pros:** truly cross-language, mature codegen for Dart and Node.
- **Cons:** breaks the REST decision, adds infra complexity (gRPC-Web proxy), changes auth and observability stories. Massive over-engineering for an Android delivery-rider app with two M1 endpoints. **Rejected.**

### Option F — OpenAPI export + Dart codegen, today

- **Pros:** single source of truth (TypeBox), automated Dart generation (no drift).
- **Cons:** requires `@fastify/swagger` + a Dart OpenAPI generator (`openapi_generator_cli` or `chopper_generator`) + CI step + a generated-files pattern in the mobile build. The two M1 endpoints don't justify the setup cost. **Deferred to post-M1.**

## Decision

For M1:

1. **Prisma is the source of truth for the database**, and only the database. Generated `@prisma/client` types are backend-internal and **must not** leave the backend over the wire. A handler that returns a Prisma row directly is a bug.

2. **TypeBox is the source of truth for HTTP API contracts.** Every endpoint declares its request body, query, params, and every response status code with a TypeBox schema. Schemas live in `apps/backend/src/<feature>/schemas.ts` (separate file from the route handler) so they are importable by tests and, post-M1, by an OpenAPI exporter. The handler imports `Static<typeof Schema>` for its TypeScript types.

3. **Mobile Dart DTOs mirror TypeBox schemas manually.** Each DTO file at `apps/mobile/lib/features/<feature>/data/dto/<name>_dto.dart` carries a header comment of the form `// Mirror of: apps/backend/src/<feature>/schemas.ts → <SchemaName>`. Fields and field types match 1:1; no renaming. `fromJson` / `toJson` are explicit until codegen lands.

4. **One PR changes both sides.** A change to a TypeBox schema and the change to its Dart mirror travel in the same commit. Lefthook does not yet enforce this, but commit hygiene + code review must.

For post-M1 (not in scope of this ADR):

5. **Add OpenAPI export and Dart codegen.** Wire `@fastify/swagger` + `@fastify/swagger-ui`, expose `/openapi.json`, generate Dart DTOs in CI from the OpenAPI schema. The `// Mirror of:` comments become docstrings on the generated files; the manual mirror disappears. To be revisited when M2 endpoints are designed.

## Consequences

- **Positive:** every shape on the wire has exactly one canonical declaration; the database can evolve without forcing API changes; mobile DTO drift is visible in code review (TypeBox file changed, Dart file did not — flag it); the OpenAPI / codegen path is open whenever we want it; future agents reading the codebase find one rule, not a debate.
- **Negative:** the discipline relies on humans/agents updating the mirror. M1 has only four endpoints and ~four DTO shapes — manageable; do not let this rule survive into M2 without codegen.
- **Neutral:** Prisma stays a backend-private dependency. This is what most production Node + Prisma codebases do anyway.

## Implementation Notes

### Backend file layout (M1)

```
apps/backend/src/
├── auth/
│   ├── schemas.ts        # TypeBox schemas — the source of truth
│   ├── handlers.ts       # imports schemas + Static<>, handles requests
│   └── routes.ts         # registers handlers with Fastify, wires schema → handler
└── server.ts             # withTypeProvider<TypeBoxTypeProvider>()
```

`schemas.ts` exports:

- The `Type.Object({...})` schema (named, e.g. `LoginRequestSchema`).
- The matching `Static<typeof LoginRequestSchema>` type alias (e.g. `LoginRequest`).
- Errors as a separate schema (`ErrorResponseSchema`) shared across endpoints.

`handlers.ts` imports the type aliases and the schemas. `routes.ts` does the Fastify wiring.

### Mobile file layout (M1)

```
apps/mobile/lib/features/auth/
├── presentation/         # already exists (login_page.dart, register_page.dart)
└── data/
    └── dto/
        ├── _template.dart        # convention reference (this ADR)
        └── <feature>_dto.dart    # written when the matching backend schema lands
```

Each DTO file follows the template: header comment with `Mirror of: <backend path> → <SchemaName>`, immutable fields (`final`), `fromJson` / `toJson` explicit.

### What the rule rejects

- `return prisma.user.findUnique(...)` from a handler — must go through a response schema.
- TypeBox schemas inlined inside route registration — must live in `schemas.ts`.
- A Dart DTO without a `// Mirror of:` header — fails review.
- Renaming a field in Dart for "convenience" (e.g. `homeAddress` → `home`) — must match TypeBox 1:1.

### Worked example (for the backend auth task)

```ts
// apps/backend/src/auth/schemas.ts
import { Type, Static } from '@sinclair/typebox'

export const UserSchema = Type.Object({
  id: Type.String({ format: 'uuid' }),
  email: Type.String({ format: 'email' }),
  name: Type.String(),
  phone: Type.Union([Type.String(), Type.Null()]),
  createdAt: Type.String({ format: 'date-time' })
})
export type User = Static<typeof UserSchema>

export const LoginRequestSchema = Type.Object({
  email: Type.String({ format: 'email' }),
  password: Type.String({ minLength: 8 })
})
export type LoginRequest = Static<typeof LoginRequestSchema>

export const LoginResponseSchema = Type.Object({
  access: Type.String(),
  refresh: Type.String(),
  user: UserSchema
})
export type LoginResponse = Static<typeof LoginResponseSchema>
```

```dart
// apps/mobile/lib/features/auth/data/dto/auth_user_dto.dart
// Mirror of: apps/backend/src/auth/schemas.ts → UserSchema
class AuthUserDto {
  const AuthUserDto({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String name;
  final String? phone;
  final DateTime createdAt;

  factory AuthUserDto.fromJson(Map<String, dynamic> json) {
    return AuthUserDto(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'phone': phone,
        'createdAt': createdAt.toIso8601String(),
      };
}
```

The template file at `apps/mobile/lib/features/auth/data/dto/_template.dart` (added in the same commit set as this ADR) shows the same pattern in self-contained, analyzer-clean form so the backend-auth task has a copy-paste starting point.

## References

- ADR-0006 — TypeBox as Fastify Type Provider.
- ADR-0004 — Prisma 7.
- Context7: `/fastify/fastify-type-provider-typebox` (consulted 2026-05-08) — first-party guidance on schema-first typing.
- Fastify v5 docs — Type Providers — https://fastify.dev/docs/v5.0.x/Reference/Type-Providers/
- TypeBox README — `Static<typeof Schema>` inference contract — https://github.com/sinclairzx81/typebox
