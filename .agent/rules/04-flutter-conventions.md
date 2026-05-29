---
trigger: glob
---

<!--
Activation: Glob (intended) — pattern: apps/mobile/**/*.dart
Confirm in Antigravity UI: Customizations → Rules → this file → set "Glob" with the pattern above.
-->

# Flutter Conventions for `apps/mobile/`

## No comments in production code

Names explain WHAT. ADRs and `docs/` explain WHY. Production Dart code under `apps/mobile/lib/` has no comments — including no docstring-style `///` on private members, no `// TODO`, no `// FIXME`.

Exception: license headers on third-party-derived files (none currently exist).

Test code under `apps/mobile/test/` and `apps/mobile/integration_test/` MAY have comments for golden-image rationale or for `// arrange / act / assert` structural markers when the test body is long.

## Riverpod codegen is mandatory after `@riverpod` edits

In Claude Code, a PostToolUse hook (`.claude/hooks/run-riverpod-codegen.sh`, ADR-0024) auto-runs `dart run build_runner build --delete-conflicting-outputs` after any edit to a `@riverpod`-annotated file. **Antigravity has no equivalent.**

After editing any file with `@riverpod` or `part '*.g.dart';`:

```bash
cd apps/mobile && dart run build_runner build --delete-conflicting-outputs
```

Commit the regenerated `*.g.dart` files together with the source edit. If you skip this, `flutter analyze` will fail at the pre-commit Lefthook hook.

## DTO mirror header is mandatory

Every Dart DTO file under `apps/mobile/lib/features/<feature>/data/dto/` MUST start with:

```dart
// Mirror of: apps/backend/src/<feature>/schemas.ts -> <SchemaName>
```

(Single-DTO) or:

```dart
// Mirror of: apps/backend/src/<feature>/schemas.ts -> {Schema1, Schema2, ...}
```

(Multi-DTO). ASCII `->` only, no backticks. Reference template: `apps/mobile/lib/features/auth/data/dto/_template.dart`. See ADR-0013.

A change to a TypeBox schema and its Dart mirror travel in the **same commit**.

## Hot-reload discipline

Do not kill `flutter run` for changes inside `lib/**`. Three levels, cheapest first:

| Level        | Trigger                          | Cost                        | When                                                        |
| ------------ | -------------------------------- | --------------------------- | ----------------------------------------------------------- |
| Hot reload   | `r` in terminal, or VS Code save | sub-second, preserves state | Widget edit, color/copy, method body                        |
| Hot restart  | `R` in terminal                  | ~2s, loses state            | New top-level provider, new route, change to `main()`       |
| Full restart | kill + `flutter run`             | 2–7 min                     | `pubspec.yaml` deps, native (Kotlin/Swift), AndroidManifest |

If `flutter run` is alive, prefer hot reload over restart over full relaunch. Codified in ADR-0012.

## Slice-1 release lesson — `--dart-define` required on physical device

If asked to run the release build directly on the M54 (not the emulator), the command MUST include:

```bash
flutter run --release \
  --dart-define=API_BASE_URL=https://api.roteirizadorpro.com.br \
  --dart-define=APP_ENV=production
```

Default is `10.0.2.2` (emulator loopback) which fails silently on devices. Prefer `bash apps/mobile/scripts/build-release-apk.sh` which already wires these correctly.

## Performance defaults

Use `ListView.builder` (never `ListView` with a hardcoded children list) for any list > 10 items. Add `const` constructors everywhere the analyzer suggests. Wrap heavy subtrees with `RepaintBoundary` only when profiling shows repaints. Default to `ref.watch` granularity at the leaf widget, not the top of the build method.

For pre-PR perf audit, use the `perf-audit` skill in `.agent/skills/perf-audit/`.
