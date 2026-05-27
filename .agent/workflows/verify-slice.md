---
description: Pre-PR verification gate for an M2 slice. Runs flutter analyze + test, backend typecheck, ADR-drift check, and Riverpod codegen freshness.
---

# /verify-slice

Run the canonical pre-PR verification gate for the current M2 slice. Mirrors `M2-SLICE-CHECKLIST.md` §Verification + `/verify-slice` skill from `.claude/skills/`.

## Pre-flight

1. `git status` — confirm what changed since `main`.
2. Identify which apps were touched:
   - `apps/mobile/lib/**` or `apps/mobile/test/**` → run mobile checks
   - `apps/backend/src/**` → run backend checks
   - `apps/landing/**` → run landing checks

## Mobile checks (only if mobile was touched)

Run sequentially — stop and surface the first failure.

1. **Riverpod codegen freshness** (Claude Code's PostToolUse hook does not run here):
   ```bash
   cd apps/mobile && dart run build_runner build --delete-conflicting-outputs
   ```
   If `*.g.dart` files changed, stage them as part of the slice.

2. **Static analysis:**
   ```bash
   cd apps/mobile && flutter analyze
   ```
   Must report zero issues.

3. **Unit + widget tests:**
   ```bash
   cd apps/mobile && flutter test
   ```
   All green.

4. **Integration tests** (only if `app.dart`, navigation, or `lib/features/<x>/screens/` was touched — per slice-2 hard gate, see CLAUDE.md):
   ```bash
   cd apps/mobile && flutter test integration_test/ -d <device-id>
   ```
   Ask the operator for the device ID if unclear (`RQCW401G33T` is Eduardo's M54).

5. **Golden tests** (only if a screen with a baseline was touched):
   - If goldens drift intentionally, regenerate: `cd apps/mobile && flutter test --update-goldens`
   - Eyeball the new PNGs before staging.

## Backend checks (only if backend was touched)

1. **Typecheck:**
   ```bash
   cd apps/backend && bun run typecheck
   ```

2. **DTO mirror integrity** (Claude Code's `check-dto-mirror.sh` hook does not run here):
   - If `apps/backend/src/<feature>/schemas.ts` changed, confirm the matching `apps/mobile/lib/features/<feature>/data/dto/*_dto.dart` was updated in the same commit set, and its `// Mirror of:` header still names the right schema. Per ADR-0013.

## Landing checks (only if landing was touched)

```bash
cd apps/landing && bun run lint
```

## ADR drift check

If any of these were touched, confirm a new or updated ADR exists under `docs/decisions/` in the same commit set:

- `package.json` (any workspace)
- `pubspec.yaml`
- `apps/backend/prisma/schema.prisma`
- `docker-compose*.yml`
- Anything under `infra/`

Surface a warning if drift is detected.

## Spoke parity check (only for slice-2 / slice-3 microsprints with a Spoke equivalent)

Per ADR-0036, run the `spoke-inspect` skill (`.agent/skills/spoke-inspect/`) at D4 closing — BEFORE opening the PR. The skill produces a categorized punch-list (must-fix / should-fix / nit). Address must-fix items before merging.

## Report

A consolidated punch-list:

```
mobile/flutter analyze         : PASS / FAIL (N issues)
mobile/flutter test            : PASS / FAIL (N failing)
mobile/integration_test        : PASS / FAIL / SKIPPED (reason)
mobile/golden tests            : PASS / FAIL / SKIPPED (reason)
backend/bun typecheck          : PASS / FAIL / SKIPPED
backend/DTO mirror integrity   : PASS / FAIL / SKIPPED
landing/bun lint               : PASS / FAIL / SKIPPED
ADR drift                      : OK / DRIFT (list files)
Spoke parity (D4)              : OK / GAPS (must-fix N, should-fix N, nit N) / SKIPPED (reason)
```

Only after every applicable line is `PASS` / `OK` is the slice ready for PR.
