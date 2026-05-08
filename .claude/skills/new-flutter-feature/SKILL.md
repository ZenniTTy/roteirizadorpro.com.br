---
name: new-flutter-feature
description: Scaffold a new feature in apps/mobile/lib/features/<feature>/ using Riverpod 3 with @riverpod codegen and the project's conventions (strict lints, snake_case Dart files, no comments). Argument is the feature name in kebab-case (e.g. "route-list", "stop-detail"). Creates a presentation page and a Riverpod controller, optionally adds data/ and domain/ layers, registers the route in the go_router config, and prints the build_runner command. Use when starting a new screen or capability in the mobile app. Pre-requisite: feature name and a one-line description of what it does.
disable-model-invocation: true
---

# New Flutter Feature Scaffold

Creates a feature folder under `apps/mobile/lib/features/<feature>/` aligned with the project's stack:

- **Riverpod 3** via `@riverpod` annotation + `part '<file>.g.dart'` for codegen.
- **Existing core widgets** (`lib/core/widgets/rp_button.dart`, `rp_input.dart`, etc.) — reuse, do not re-create.
- **Strict lints** from `analysis_options.yaml`: `strict-casts`, `strict-inference`, `require_trailing_commas`, `prefer_const_constructors`. **No comments in production code** (`docs/03-CONVENTIONS.md`).
- **Snake_case Dart files** (matches existing repo: `register_page.dart`, `app_theme.dart`).

## Inputs

- `feature` — kebab-case, becomes `snake_case` for files and `PascalCase` for classes.
  - Example: `route-list` → folder `route_list/`, files `route_list_page.dart`, class `RouteListPage`.
- One-line description from the user. If missing, ask before scaffolding.

## Workflow

### 1. Validate

```bash
test -d "$CLAUDE_PROJECT_DIR/apps/mobile/lib/features" || exit 1
```

If `apps/mobile/lib/features/<feature>/` already exists, **stop** and ask whether to overwrite. Never silently overwrite.

### 2. Create structure (minimum viable)

```
apps/mobile/lib/features/<feature>/
├── application/<feature>_controller.dart
└── presentation/<feature>_page.dart
```

Add `data/<feature>_repository.dart` and `domain/<feature>_state.dart` **only when the feature needs them** — auth shells don't, a route list with API + state does.

### 3. Controller template (`application/<feature>_controller.dart`)

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '<feature>_controller.g.dart';

@riverpod
class <FeatureName>Controller extends _$<FeatureName>Controller {
  @override
  <ReturnType> build() {
    // initialize state here
  }
}
```

Notes:

- Use **class form** (`@riverpod class X extends _$X`) for stateful controllers. Use **function form** (`@riverpod Future<T> fetchX(Ref ref) async { ... }`) for read-only async queries.
- The `part` directive matches the `.g.dart` filename — `<feature>_controller.dart` → `<feature>_controller.g.dart`.
- The generated provider name is `<lowerCamelName>ControllerProvider`.

### 4. Page template (`presentation/<feature>_page.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/<feature>_controller.dart';

class <FeatureName>Page extends ConsumerWidget {
  const <FeatureName>Page({super.key});

  static const routePath = '/<feature-kebab>';
  static const routeName = '<feature-kebab>';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: SafeArea(
        child: Center(child: Text('<FeatureName>')),
      ),
    );
  }
}
```

Notes:

- `ConsumerWidget` is the default. Use `ConsumerStatefulWidget` only when local controllers (`TextEditingController`, `AnimationController`) demand it.
- `routePath` and `routeName` are constants on the page class so the router config imports them — avoids string drift.
- **No comments.** Per CLAUDE.md and `docs/03-CONVENTIONS.md`.

### 5. Optional data + domain layers

Add `domain/<feature>_state.dart` with a sealed state class only when the controller has more than `data` + `loading` + `error`. For simple async, return `AsyncValue<T>` directly from the controller.

Add `data/<feature>_repository.dart` only when the feature hits the network or local storage. Use `dio` (already a project dep) and inject via a Riverpod provider — never construct `Dio()` inside a widget.

### 6. Register the route

Find the `GoRouter` configuration (likely `lib/app.dart` or `lib/core/router.dart` — search if unsure). Add a `GoRoute` entry that imports `<FeatureName>Page` and uses its `routePath`. Do NOT inline the path string.

### 7. Run codegen

After files are written, **tell the user** to run one of:

```bash
cd apps/mobile && dart run build_runner build --delete-conflicting-outputs
# or, for a watch loop while developing:
cd apps/mobile && dart run build_runner watch --delete-conflicting-outputs
```

Do NOT run codegen automatically inside the skill — it touches generated files and the user may want to watch instead of one-shot.

### 8. Verify

```bash
cd "$CLAUDE_PROJECT_DIR/apps/mobile"
flutter analyze lib/features/<feature>/   # should pass
ls lib/features/<feature>/                # confirm structure
```

If `flutter analyze` reports `Target of URI hasn't been generated: '<feature>_controller.g.dart'`, the user just needs to run `build_runner` (step 7). That's expected before codegen.

## Anti-patterns to avoid

- **Don't create a `widgets/` subfolder for the feature unless 2+ widgets actually exist.** Single-use widgets stay inside `presentation/<feature>_page.dart`.
- **Don't import from `core/` with relative paths.** Use `package:roteirizador_pro/core/...` (matches `avoid_relative_lib_imports` lint).
- **Don't add a `barrel` file (`index.dart`).** `docs/03-CONVENTIONS.md` forbids them.
- **Don't add a test file as part of scaffold.** Tests follow the "where it hurts" principle — auth, payment, route optimization. A scaffolded screen doesn't need a test until it has logic.

## What this skill is NOT

- Not a state-machine generator. If you need a sealed state with `loading | data(T) | error(Failure)`, you author it.
- Not a UI generator. Page bodies are stubs; you fill them in by reading the relevant `prototipo/screens-*.jsx` (UI source of truth).
- Not a router refactor tool. It adds one route; restructuring the router is a separate task.
