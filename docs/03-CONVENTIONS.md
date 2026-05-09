# 03 — Conventions

Code style, naming, and structural conventions for this repository.

> **Note:** Most code style enforcement is delegated to **linters and formatters** (ESLint, Prettier, Biome, `dart format`) — not to AI agents. This document captures conventions that need human (or AI) judgment.

## Naming

| Element | Convention | Example |
|---|---|---|
| TypeScript files (general) | kebab-case | `route-optimizer.ts`, `user-profile.tsx` |
| Dart files (Effective Dart) | snake_case (`lowercase_with_underscores`) | `register_page.dart`, `app_theme.dart`, `rp_button.dart` |
| TypeScript folders | kebab-case | `src/auth-middleware/` |
| Dart folders | snake_case (`lowercase_with_underscores`) | `lib/features/auth/presentation/`, `lib/core/widgets/` |
| TypeScript variables/functions | camelCase | `optimizeRoute`, `userId` |
| TypeScript classes/types/interfaces | PascalCase | `RouteOptimizer`, `UserProfile` |
| TypeScript constants | SCREAMING_SNAKE_CASE | `MAX_STOPS_PER_ROUTE` |
| Dart variables/functions | camelCase | `optimizeRoute`, `userId` |
| Dart classes/enums | PascalCase | `RouteOptimizer`, `UserProfile` |
| Dart private members | leading underscore | `_internalCache` |
| Database tables | snake_case plural | `users`, `webhook_events` |
| Database columns | snake_case | `created_at`, `home_address` |
| Environment variables | SCREAMING_SNAKE_CASE | `DATABASE_URL`, `EFI_CLIENT_ID` |
| Git branches | kebab-case | `feat/jwt-auth`, `docs/architecture-update` |
| Conventional Commit scopes | flat lowercase (enforced) | `feat(mobile):`, `chore(tooling):` — see `commitlint.config.cjs` `scope-enum` |

## Code Style Baseline

These are the few non-obvious rules. Everything else: trust the linter.

1. **No comments in production code.** If a piece of code needs explanation, the function name should explain it, or the explanation goes to docs/ADRs. Linter rule will warn on `//` and `/*` outside of JSDoc.
2. **TypeScript `strict: true`.** No `any`, no implicit `undefined`. If you genuinely need to escape, use `unknown` and narrow it.
3. **Dart null-safety on.** No `!` (bang) operator unless there's a comment-free reason already documented in the function name.
4. **Functions ≤ 50 lines, ≤ 4 parameters.** If you cross either threshold, refactor.
5. **No barrel files (`index.ts` re-exporting everything).** They hurt tree-shaking and create circular import risks. Import from the source file.
6. **Imports are absolute when project paths exist** (e.g. `@/auth/jwt` over `../../auth/jwt`). Configure tsconfig path aliases.
7. **One default export per file is allowed but not required.** Named exports preferred for refactor-friendliness.
8. **One source of truth per data layer (ADR-0013).** Prisma describes the **database**; TypeBox describes the **HTTP API**; Dart DTOs **mirror** TypeBox. Never return `@prisma/client` rows from a handler — always go through a TypeBox response schema. Every Dart DTO file in `apps/mobile/lib/features/<feature>/data/dto/` starts with `// Mirror of: apps/backend/src/<feature>/schemas.ts → <SchemaName>` and matches the TypeBox shape 1:1 (no renaming, no field skips). When a TypeBox schema changes, its Dart mirror changes in the same commit. See `docs/02-ARCHITECTURE.md` (API Contracts & Type Safety) and the reference at `apps/mobile/lib/features/auth/data/dto/_template.dart`.

## Directory Layout (high level)

```
[APP] - Entrega Smart/
├── apps/
│   ├── mobile/        # Flutter app
│   ├── backend/       # Fastify API
│   └── landing/       # roteirizadorpro.com.br
├── infra/             # docker-compose, server provisioning, GraphHopper
├── docs/              # documentation (this folder)
├── prototipo/         # canonical UI source (Claude Design prototype, client-approved) — referenced, never imported
└── scripts/           # repo-level utility scripts
```

This structure materializes incrementally as we build. We don't pre-create empty folders.

## Testing Convention

- Test files live next to the code they test: `route-optimizer.ts` → `route-optimizer.test.ts`.
- Integration tests live in `apps/<app>/test/integration/`.
- E2E tests for the API live in `apps/backend/test/e2e/`.
- The bar: **tests where it hurts** (payment, route optimization, paywall, OCR, auth). Not on getters.
- A bug fix without a regression test is incomplete.

## Commit Conventions

See **CONTRIBUTING.md** for the full Git workflow. Quick reference:

```
<type>(<scope>): <subject>
```

- Types: `feat`, `fix`, `refactor`, `docs`, `chore`, `style`, `test`, `perf`, `build`, `ci`.
- Subject: imperative mood, lowercase, no period, ≤ 72 chars.
- One logical change per commit.

## Documentation Convention

- All docs in `/docs/` use a numbered prefix to enforce reading order: `01-PROJECT.md`, `02-ARCHITECTURE.md`, etc.
- ADRs (Architecture Decision Records) live in `/docs/decisions/` with format `NNNN-kebab-title.md`. They follow Michael Nygard's format (Context → Decision → Consequences).
- Session logs live in `/docs/sessions/YYYY-MM-DD-NN-topic.md`. Indexed in `0001-INDEX.md`.

## When in doubt

If a convention is missing here and you can't decide, **ask the human owner before establishing a precedent**. Conventions accrete — once a pattern is in the codebase, others follow it.
