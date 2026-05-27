---
description: Scaffold a new Spoke-aligned Flutter screen under apps/mobile/lib/features/ following Riverpod 3 codegen, DTO mirror, and test conventions.
---

# /new-screen `<feature-name>`

Scaffold a new Flutter screen for a slice-2 / slice-3 feature, Spoke-aligned by default.

## Pre-flight

1. Ask the operator for `<feature-name>` if not in the command argument. Kebab-case, e.g., `route-list`, `stop-detail`, `share-route`.

2. **If this feature has a Spoke equivalent** (most slice-2 flows do, per `docs/inventory/2026-05-26-spoke-vs-rotpro.md`):
   - Recommend running the `spoke-inspect` skill (`.agent/skills/spoke-inspect/`) FIRST. Pass it the equivalent Spoke flow.
   - Do not proceed with scaffolding until the operator confirms Spoke inspection has been done (or explicitly waives it).

3. Read the matching section of `docs/inventory/2026-05-26-spoke-vs-rotpro.md` to confirm the screen scope.

4. Read the existing canonical pattern: a small Spoke-aligned feature already in `apps/mobile/lib/features/`. Use it as the layout template — do not invent a new structure.

## Scaffold

Create this directory layout. Use `snake_case` for filenames, `PascalCase` for class names, `camelCase` for provider variables.

```
apps/mobile/lib/features/<feature_name>/
├── data/
│   └── dto/
│       └── <feature_name>_dto.dart        # Mirror header (see Rule 04)
├── domain/
│   └── <feature_name>.dart                # Domain model (immutable, no Freezed unless project already uses it)
├── application/
│   └── <feature_name>_controller.dart     # @riverpod controller, part '<feature_name>_controller.g.dart'
└── presentation/
    ├── <feature_name>_screen.dart         # Top-level screen widget
    └── widgets/
        └── .gitkeep
```

Plus tests:

```
apps/mobile/test/features/<feature_name>/
├── application/
│   └── <feature_name>_controller_test.dart   # Failing first per TDD
├── presentation/
│   └── <feature_name>_screen_test.dart       # Widget test, failing first
└── _helpers/
    └── fakes.dart                            # Manual fakes — mocktail only if verify/when is required
```

Plus the integration_test stub (only if this screen has navigation):

```
apps/mobile/integration_test/<feature_name>_flow_test.dart
```

## Wire-up steps

1. Add the route to `apps/mobile/lib/router/app_router.dart` following the existing go_router pattern.
2. Run codegen:
   ```bash
   cd apps/mobile && dart run build_runner build --delete-conflicting-outputs
   ```
3. Verify analyzer is clean:
   ```bash
   cd apps/mobile && flutter analyze
   ```
4. Run the new (failing) tests to confirm they fail for the right reason:
   ```bash
   cd apps/mobile && flutter test test/features/<feature_name>/
   ```

## TDD discipline

The controller, screen, and integration tests should fail on **assertion**, not on import. Use `throw UnimplementedError()` in stubs so the assertion is reached. Per `lesson_spec_as_implementation_license.md` in CLAUDE.md auto-memory: do not pre-populate stubs with trivial constants.

## Report

Print:
- Tree of created files.
- Output of `flutter analyze`.
- Output of `flutter test test/features/<feature_name>/` (expected: red).
- Next steps for the operator: "Implement the controller, then the screen, then the integration. Run `/verify-slice` before opening the PR."

## Never

- Scaffold without first checking `docs/inventory/2026-05-26-spoke-vs-rotpro.md` for the feature.
- Write production logic in the same call as scaffolding — scaffold is red-phase only.
- Skip the DTO mirror header (Rule 04).
- Add comments to production files (Rule 04).
