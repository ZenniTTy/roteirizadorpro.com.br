# Session 2026-05-08-03 — schema-source-of-truth

## Metadata

- **Date**: 2026-05-08 (America/Sao_Paulo)
- **Sequence**: 03
- **Agent**: Claude Code (Opus 4.7, 1M ctx)
- **Human**: Eduardo
- **Topic**: Schema source-of-truth codification
- **Duration**: ~45min
- **Related ADRs**: ADR-0013 (new), ADR-0004, ADR-0006, ADR-0002
- **Related TODO items**: Phase 2 — Backend auth (gates the next track)

## Goal of the Session

Codify, before backend auth is written, which layer owns the canonical shape of each piece of data on the wire — so future agents (and a tired human at 3 AM) do not produce three definitions of "User" and replicate redundancy across Prisma, TypeBox, and Dart.

## What Was Done

- Confirmed the modern (2026) Fastify + TypeBox pattern via Context7 (`/fastify/fastify-type-provider-typebox`): schemas live in dedicated files, types flow into handlers via `Static<typeof Schema>`, never expose ORM types directly.
- Authored `docs/decisions/0013-api-contract-source-of-truth.md`. Six options considered (no rule, manual mirror, `prismabox` auto-gen, shared DSL, gRPC, OpenAPI codegen now); manual mirror chosen for M1, OpenAPI codegen explicitly deferred to post-M1.
- Added a new "API Contracts & Type Safety" section to `docs/02-ARCHITECTURE.md`, immediately above the existing "API Contracts" endpoint list. Includes the canonical-source table, four rules, a worked TS+Dart example, and a forward pointer to the post-M1 codegen plan.
- Added rule §8 to `docs/03-CONVENTIONS.md` ("Code Style Baseline") tying everything together with cross-references to ADR-0013, the architecture section, and the template file.
- Created `apps/mobile/lib/features/auth/data/dto/_template.dart` — a self-contained, analyzer-clean reference template demonstrating the `// Mirror of:` header convention plus an explicit `fromJson` / `toJson` for an example DTO. Verified with `flutter analyze --no-pub` (1 false-positive `unintended_html_in_doc_comment` from `<feature>` placeholders, fixed by wrapping in backticks).
- Added the new rule block to `CLAUDE.md` immediately before "Context7 Mandatory" so future agents see it during the onboarding ritual.
- Updated `TODO.md` (Done section + last-updated date) and `docs/10-CHANGELOG.md` (new 2026-05-08 entry).

## Decisions Made

1. **TypeBox is the API source of truth, not Prisma.** Prisma describes the database; the database is not the wire. A handler that returns `prisma.user.findUnique()` directly is a bug — `password_hash` and other internal columns must not leak. Codified in ADR-0013.
2. **Manual Dart mirror for M1, codegen post-M1.** Two M1 endpoints, ~four DTO shapes — does not justify the setup cost of `@fastify/swagger` + a Dart OpenAPI generator. The `// Mirror of:` comment makes drift grep-able and code-review-visible. Re-evaluate when M2 endpoints are designed.
3. **Reject `prismabox` (auto-gen TypeBox from Prisma).** The DB schema and the API schema are deliberately not the same shape. Auto-generation either over-exposes or requires per-field whitelisting longer than writing the TypeBox by hand.
4. **TypeBox schemas live in their own file** (`apps/backend/src/<feature>/schemas.ts`) separate from handlers — so they are importable by tests and (post-M1) by an OpenAPI exporter. ADR-0006 already implied this; ADR-0013 makes it explicit.

## Open Questions Left

- [ ] Whether to add a Lefthook check that flags TypeBox-schema commits without matching Dart-DTO changes. Probably overkill on M1 (low volume); revisit post-M1.
- [ ] Which Dart OpenAPI generator wins post-M1: `openapi_generator_cli`, `chopper_generator`, or hand-roll. To be decided when codegen lands, not now.

## Files Changed

**Created**:
- `docs/decisions/0013-api-contract-source-of-truth.md`
- `apps/mobile/lib/features/auth/data/dto/_template.dart`
- `docs/sessions/2026-05-08-03-schema-source-of-truth.md`

**Modified**:
- `CLAUDE.md` (added "Schema Source of Truth (ADR-0013)" block)
- `docs/02-ARCHITECTURE.md` (added "API Contracts & Type Safety" section)
- `docs/03-CONVENTIONS.md` (added rule §8)
- `docs/10-CHANGELOG.md` (added 2026-05-08 entry)
- `TODO.md` (Done entry + last-updated date)
- `docs/sessions/0001-INDEX.md` (new session entry)

## Commits Pushed

```
<hash>  docs(decisions): add ADR-0013 schema source-of-truth + dart dto template
<hash>  docs(sessions): record schema source-of-truth codification
```

(Two thematically-distinct commits to keep the docs/sessions split clean per CONTRIBUTING.md.)

## Hand-off Notes for Next Session

- **Branch:** `develop`. No in-progress work.
- **Next track per the previous session's recommendation:** backend auth. ADR-0013 now constrains how to organize the work: every endpoint declares schemas in `apps/backend/src/auth/schemas.ts`, handlers import `Static<typeof Schema>`, and any Dart DTOs the mobile app needs go to `apps/mobile/lib/features/auth/data/dto/<name>_dto.dart` with a `// Mirror of:` header. Use `_template.dart` as the copy-paste starting point.
- **No new dependencies** were added in this session — pure docs + one analyzer-clean Dart reference file.

## Reference Material Used

- Context7: `/fastify/fastify-type-provider-typebox` — schema-first pattern for Fastify v5 (consulted 2026-05-08).
- Context7: `/sinclairzx81/typebox` (catalog only — confirmed it has the highest snippet coverage and `Static<typeof Schema>` is the canonical inference contract).
- Existing project docs: ADR-0004 (Prisma), ADR-0006 (TypeBox), ADR-0012 (DX tooling), `docs/02-ARCHITECTURE.md` (current data model section).
