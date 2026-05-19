## ADR-0020: Canonical Format for the `// Mirror of:` DTO Header (amends ADR-0013)

- **Status:** Accepted
- **Date:** 2026-05-19
- **Deciders:** Eduardo
- **Amends:** ADR-0013 (TypeBox as the API Contract Source of Truth)
- **Related ADRs:** ADR-0018 (Wave A in-loop hooks — the consumer of this format), ADR-0019 (Wave B spec/plan templates — propagator)

## Context

ADR-0013 introduced the `// Mirror of:` header as the visible side of the TypeBox → Dart DTO contract. The header was specified *by example* — five different inline mentions across the ADR (lines 40, 71, 117, 123, 157) plus a worked example using `→` (Unicode arrow U+2192), no formal grammar. The matching reference template at `apps/mobile/lib/features/auth/data/dto/_template.dart` (the file ADR-0013 §Implementation Notes cites as canonical) instead documented the convention with ASCII `->`.

When `check-dto-mirror.sh` shipped under ADR-0018 (Wave A), this looseness produced concrete drift detectable in seven places:

| Location | Glyph / form used |
|---|---|
| ADR-0013 L71, L117, L157 | `→` (Unicode) |
| CLAUDE.md L123 | `→` |
| `docs/03-CONVENTIONS.md` L38 | `→` |
| `docs/02-ARCHITECTURE.md` L341, L362 | `→` |
| `docs/M2-SLICE-CHECKLIST.md` L25 | `→` |
| `docs/08-ROADMAP.md` L90 | `→` |
| `_template.dart` L8 (the cited reference) | `->` (ASCII) |
| `stop_dto.dart` L1 (real DTO, ships in production) | `->` |
| `auth_dtos.dart` L1 (real DTO, ships in production) | `` `apps/backend/src/auth/schemas.ts` `` (backticks, no arrow, no `<SchemaName>` on L1) |
| Slice-2 plan L946 (Task 8 worked example) | `->` |

The hook's substring grep (`grep -l "Mirror of: apps/backend/src/<...>/schemas.ts"`) catches the `→` and `->` variants because they share the prefix, but **silently fails** on the backtick form — meaning `auth_dtos.dart` is invisible to ADR-0013 enforcement.

A second ambiguity surfaced when auditing the two real DTOs:

- `stop_dto.dart` ships **one** DTO mirroring `StopSchema` — single-DTO file form.
- `auth_dtos.dart` ships **nine** DTOs (`AuthUserDto`, `RegisterRequestDto`, `RegisterResponseDto`, `LoginRequestDto`, `LoginResponseDto`, `RefreshRequestDto`, `RefreshResponseDto`, `MeResponseDto`, `AuthErrorDto`) bundled in one file because the auth feature has multiple cohesive schemas with shared base types. The Dart class names diverge slightly from the TypeBox export names (e.g. `AuthUserDto` mirrors `UserSchema`, `AuthErrorDto` mirrors `ErrorResponseSchema`) — the Dart side prefixes/suffixes for clarity in mobile call sites while the TypeBox side stays unprefixed in its feature scope.

ADR-0013 §Implementation Notes only shows the single-DTO form. It is silent on whether the multi-DTO bundle is canonical or an anti-pattern. The codebase contains both because both reflect the **shape of the source TypeBox file**: `routes/schemas.ts` exports one user-facing schema; `auth/schemas.ts` exports nine.

This ADR resolves both ambiguities by giving the header a single normative format that accommodates both file shapes, and by aligning docs to the reality the templates and DTOs already implement.

## Options Considered

### Option A — Force Unicode `→` everywhere

- **Pros:** five documentation files already use `→`; preserves visual intent of "mirror".
- **Cons:** the canonical reference template (`_template.dart`) and both real DTOs use ASCII `->`. The slice-2 plan (already in git history) uses `->`. Forcing `→` requires editing committed plan content, two DTO files in production, and one template — five files in code + history vs five files in docs. The discipline tax is the same either way, but the code-side change is irreversible (touches a production-shipped DTO). ASCII also avoids any `LC_ALL` / UTF-8-grep gotcha on minimal CI environments. **Rejected.**

### Option B — Force ASCII `->` everywhere and accept ONLY single-DTO files

- **Pros:** simplest possible regex (`-> <SchemaName>` always present); aligns with `_template.dart` glyph.
- **Cons:** would require splitting `auth_dtos.dart` into nine files (`user_dto.dart`, `register_request_dto.dart`, …) plus their tests and import updates. ~10 file moves, no functional gain, and the post-M1 OpenAPI codegen (already deferred by ADR-0013 §5) will impose its own file-per-schema-or-bundle decision when it lands. Work would be discarded. **Rejected.**

### Option C — Force ASCII `->` everywhere AND formally recognize the multi-DTO bundle (this ADR)

Define one header grammar that covers both real cases:

- **Single-DTO file** (`stop_dto.dart`): `// Mirror of: apps/backend/src/<feature>/schemas.ts -> <SchemaName>`
- **Multi-DTO file** (`auth_dtos.dart`): `// Mirror of: apps/backend/src/<feature>/schemas.ts -> {Schema1, Schema2, ...}`, with `/// Mirror of: <SchemaName>` per class.

Both forms ASCII-only, line 1, no backticks. The hook regex matches both via the prefix `^// Mirror of: apps/backend/src/[^/]+/schemas\.ts -> `.

- **Pros:** preserves both real DTO files with a one-line header edit each (only `auth_dtos.dart` actually needs editing — `stop_dto.dart` is already compliant). Honors the intent of the file naming convention already in the codebase (`stop_dto.dart` singular, `auth_dtos.dart` plural — chosen on 2026-05-08 by the original author). Hook regex stays simple. Avoids work that the post-M1 codegen will undo.
- **Cons:** the multi-DTO L1 header line can grow long when a feature has many schemas (today's worst case is 9). Acceptable: it's a single comment line in a docstring-style location, never executed code.

### Option D — Auto-derive the canonical format from TypeBox via OpenAPI codegen, now

- **Pros:** removes the human-discipline tax permanently.
- **Cons:** ADR-0013 §5 already commits to this for post-M1 with explicit deferral reasoning. M1 has shipped (`v1.0.0`); M2 slice 2 is mid-flight. Pulling the codegen forward into the middle of slice 2 is scope creep. **Rejected for now — explicitly the same deferral ADR-0013 §5 made.**

## Decision

**Adopt Option C.**

### Canonical L1 header grammar (normative)

The first non-empty line of every Dart DTO file under `apps/mobile/lib/features/<feature>/data/dto/<name>.dart` is a single line matching exactly one of two productions:

**Single-DTO form:**
```
// Mirror of: apps/backend/src/<feature>/schemas.ts -> <SchemaName>
```

**Multi-DTO form:**
```
// Mirror of: apps/backend/src/<feature>/schemas.ts -> {<Schema1>, <Schema2>, ...}
```

Constraints common to both:

- **ASCII `->`** (hyphen-minus + greater-than). Never `→` (Unicode arrow). Never `:` or `=>`.
- **No backticks** around the path, the schema name, or the brace list.
- **Path** is the project-relative repo-rooted path, lowercase except where Dart `<feature>` already uses snake_case.
- **Schema names** are PascalCase ending in `Schema` (mirrors the TypeBox export name, e.g. `UserSchema`, `LoginRequestSchema`).
- **Multi-DTO brace list** is comma-space separated, contains every schema this file mirrors from the named TypeBox file, in source order.
- **Line 1 only.** Subsequent header lines (rationale, ADR pointer, per-class `///` markers) are free-form documentation.

### Per-class marker (multi-DTO form, normative)

When the file mirrors multiple schemas, **every public DTO class** carries a Dartdoc `///` marker immediately above the class declaration:

```
/// Mirror of: <SchemaName>
class FooDto { ... }
```

Where `<SchemaName>` is the exact TypeBox export name. The class itself follows ADR-0013's field-by-field 1:1 rule unchanged. Single-DTO files MAY omit the per-class marker (the L1 header already pins the schema), but if present must use the same `///` grammar.

**Optional clarifying note.** When the TypeBox schema is composed (e.g. `Type.Intersect([TokensSchema, ...])`) or is an alias, the marker MAY carry a parenthesized note **after** the schema name to record the structural relationship:

```
/// Mirror of: LoginResponseSchema (intersection of TokensSchema + { user })
/// Mirror of: RefreshResponseSchema (alias of TokensSchema)
```

The schema name itself remains PascalCase and unbracketed; the note is human-readable prose and is NOT consumed by tooling. Tools that match per-class markers anchor on `^/// Mirror of: [A-Z][A-Za-z0-9]+(\b|$)` and ignore anything after.

### Regex (for tooling)

The L1 header is matched by:

```
^// Mirror of: apps/backend/src/[a-z0-9_-]+/schemas\.ts -> ([A-Z][A-Za-z0-9]+Schema|\{[A-Z][A-Za-z0-9, ]+\})$
```

The per-class `///` marker is matched by (note prefix only, allowing optional parenthesized clarifying note after):

```
^/// Mirror of: [A-Z][A-Za-z0-9]+(\s|$)
```

Tools (`check-dto-mirror.sh`, future codegen verifier) consume these regexes; humans consume the worked examples below.

### Worked examples

**Single-DTO** (`apps/mobile/lib/features/stops/data/dto/stop_dto.dart`):
```dart
// Mirror of: apps/backend/src/routes/schemas.ts -> StopSchema

class StopDto { ... }
```

**Multi-DTO** (`apps/mobile/lib/features/auth/data/dto/auth_dtos.dart`):
```dart
// Mirror of: apps/backend/src/auth/schemas.ts -> {UserSchema, RegisterRequestSchema, RegisterResponseSchema, LoginRequestSchema, LoginResponseSchema, RefreshRequestSchema, RefreshResponseSchema, MeResponseSchema, ErrorResponseSchema}

/// Mirror of: UserSchema
class AuthUserDto { ... }

/// Mirror of: RegisterRequestSchema
class RegisterRequestDto { ... }
```

The brace list contains the TypeBox export names verbatim. Dart class names MAY differ (e.g. `AuthUserDto` mirrors `UserSchema`, `AuthErrorDto` mirrors `ErrorResponseSchema`) — the per-class `///` marker carries the TypeBox name, the class declaration carries the Dart name.

### What the rule rejects (additions to ADR-0013 §What the rule rejects)

- Unicode `→` in any DTO header — fails the regex; agents/humans must use `->`.
- Backticks around the TypeBox path or schema name in L1 — fails the regex.
- Multi-DTO file without the L1 brace list — fails the regex; the bundle MUST be declared on L1.
- Per-class `///` marker missing in a multi-DTO file — fails review (regex passes but ADR-0013's "Dart DTO without a Mirror-of header — fails review" extends to per-class markers in multi-DTO bundles).
- Schema name in the L1 list that the file does NOT actually mirror — fails review (the L1 list is a manifest, not a wish list).

## Consequences

- **Positive:** one normative grammar instead of seven approximations; `check-dto-mirror.sh` becomes deterministic (no silent false-negatives like the one auth_dtos.dart produced); `_template.dart` (the cited canonical reference) is now actually canonical without further amendment; future agents reading any of the seven prior locations see the same ASCII `->` form; multi-DTO files have explicit blessing instead of de-facto tolerance.
- **Negative:** five documentation files need a one-glyph substitution (`→` → `->`) plus a back-reference to this ADR. One DTO (`auth_dtos.dart`) needs its L1 header rewritten and per-class `///` markers verified/added. Mechanical changes, no logic touched.
- **Neutral:** ADR-0013 §5 (post-M1 OpenAPI codegen path) is unaffected — the codegen will produce headers that match this ADR's grammar trivially because its template generator can be a one-liner.

## Implementation Notes

### Files updated in the same commit set as this ADR

| File | Edit |
|---|---|
| `apps/mobile/lib/features/auth/data/dto/auth_dtos.dart` | Rewrite L1 to multi-DTO form; ensure each class has a `/// Mirror of: <SchemaName>` marker (some already do — audit). |
| `apps/mobile/lib/features/auth/data/dto/_template.dart` | Add reference to ADR-0020 in the convention block; format itself already uses `->` and stays canonical. |
| `apps/mobile/lib/features/stops/data/dto/stop_dto.dart` | No change needed (already L1-canonical). |
| `CLAUDE.md` L123 | Replace `→` with `->`; add reference to ADR-0020 in the same line. |
| `docs/03-CONVENTIONS.md` L38 | Replace `→` with `->`. |
| `docs/02-ARCHITECTURE.md` L341, L362 | Replace `→` with `->`. |
| `docs/M2-SLICE-CHECKLIST.md` L25 | Replace `→` with `->`. |
| `docs/08-ROADMAP.md` L90 | Replace `→` with `->` (mirror file map comment). |
| `docs/decisions/0013-api-contract-source-of-truth.md` L71, L117, L157 | Replace `→` with `->` AND add a `> **Note (2026-05-19):**` line at the head of the ADR pointing to ADR-0020 for the normative grammar. |
| `.claude/hooks/check-dto-mirror.sh` | Tighten grep to the regex above (`grep -lE`) instead of substring match. |
| `docs/superpowers/plans/0000-template.md` Plan Execution Rules §7 | Quote the L1 header grammar verbatim and reference ADR-0020. |
| `docs/superpowers/specs/0000-template.md` (no edit) | The spec template's §Architecture cross-references ADR-0013 + mirror contract; that statement now transitively pulls ADR-0020. No change needed. |

### Files explicitly NOT updated

- The slice-2 plan and spec (`docs/superpowers/{specs,plans}/2026-05-13-m2-slice-2-telas-core*`) are historical artifacts of an in-flight slice and may legitimately contain the older form. Do not rewrite history that already shipped to git. The templates (the future-facing artifacts) carry the new rule.
- Session logs `docs/sessions/2026-05-08-03-*.md`, `2026-05-08-04-*.md`, `2026-05-18-12-*.md` — historical records of what was decided/done at the time; do not amend.
- The slice-2 plan TASK 8 worked example (L946) — uses ASCII `->` already; was always correct.

### Tooling alignment

After this ADR lands, `check-dto-mirror.sh` regex covers both single-DTO and multi-DTO forms. The hook still answers ONE question — "did the schema file change without the mirror file changing in the same turn?" — but does so without the silent miss on backtick variants.

The `adr-guardian` subagent (per `.claude/agents/adr-guardian.md`) continues to focus on stack changes; auditing `Mirror of:` header compliance remains the hook's job pre-commit and human review's job pre-PR. No new subagent.

### Why this ADR amends ADR-0013 instead of superseding it

ADR-0013's decision (TypeBox as API source of truth; manual Dart mirror; OpenAPI codegen deferred post-M1) is unchanged. Only the **visible syntactic shape** of the mirror header is normalized. Superseding would imply re-deciding the architectural choice, which was correct and remains correct. Amendment is the right granularity per the Michael Nygard format ADRs in this repo follow.

## References

- ADR-0013 — TypeBox as the API Contract Source of Truth (this amendment normalizes its header form).
- ADR-0018 — Wave A in-loop hooks; `check-dto-mirror.sh` is the primary mechanical consumer of this grammar.
- ADR-0019 — Wave B spec/plan templates; plan-template §Rule 7 propagates the grammar to future slices.
- `apps/mobile/lib/features/auth/data/dto/_template.dart` — the reference template that already used `->` and informed the choice of Option C.
- `apps/mobile/lib/features/stops/data/dto/stop_dto.dart` — the production-shipped single-DTO file that is L1-compliant unchanged.
- `apps/mobile/lib/features/auth/data/dto/auth_dtos.dart` — the production-shipped multi-DTO file that gets a one-line L1 header rewrite + per-class `///` audit.
- Session 16 QA audit (this session) — documented the seven divergent header forms across docs and code that motivated this ADR.
