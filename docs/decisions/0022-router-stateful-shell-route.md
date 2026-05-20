# ADR-0022: Router uses StatefulShellRoute + hierarchical sub-routes (supersedes flat top-level routes)

- **Status:** Accepted
- **Date:** 2026-05-20
- **Deciders:** Eduardo
- **Supersedes:** none (amends ADR-0021's MS-01 decision in-flight)
- **Related ADRs:** ADR-0002 (Flutter mobile), ADR-0015 (M2 plan), ADR-0017 (external nav), ADR-0021 (slice-2 fidelity remediation)

## Context

MS-01 of the slice-2 fidelity remediation (commit `2124b7f`) migrated 10 caller files from `context.go` to `context.push` plus a `canPop() ? pop() : go(parent)` fallback pattern. All four pipeline gates approved the change:

- `flutter analyze --no-pub`: 0 issues.
- `flutter test`: 91/91 widget tests green.
- `prototype-fidelity-checker` D3 re-audit: ✅ all Criticals closed.
- `pr-review-toolkit:code-reviewer` D4: APPROVED.

The release APK (`build/app/outputs/flutter-apk/app-release.apk`, 69 MB, MS-01 code verified by `strings | grep canPop` → 8 hits) was installed on the Galaxy A06 (Android 16) via USB. Manual smoke test surfaced **two regressions still present**:

1. **Home → tap a stop → StopDetail → Android system back** → minimizes the app instead of returning to Home.
2. **Bottom nav tap "Configurações" → Android system back** → minimizes the app instead of returning to Home.

Two cases passed: FAB → AddStop → back works; StopDetail → Editar → back works.

### Why every pipeline gate missed this

- `flutter analyze` validates types and imports, not runtime navigator behavior.
- `flutter test` widget tests instantiate screens inside `MaterialApp` (not `MaterialApp.router`), so the `go_router` Router API is never exercised. The 91 tests cover widget shape and callbacks via dependency injection, never the production router stack.
- `prototype-fidelity-checker` is a static visual audit — it does not simulate clicks or system back gestures.
- `pr-review-toolkit:code-reviewer` is a static code review — same blind spot.

The pipeline had a structural gap: **no gate exercised the production `go_router` instance on a Flutter runtime against a real or simulated Android back gesture.** This ADR closes that gap.

### Why `push` alone is insufficient

The Flutter team's `go_router` documentation and community knowledge (Context7 query `/websites/pub_dev_packages_go_router`, WebSearch flutter/flutter issue #145198 "GoRouter not popping on Android 14 with android back button", codewithandrea.com "Go vs Push") converge on the following invariant:

> `context.push(<route>)` adds the destination on top of the existing navigation stack **only when the route hierarchy makes that stack semantically valid.** For sibling top-level routes — which is what `apps/mobile/lib/app.dart:57-94` declares — `push` empilha but the resulting stack is treated as ambiguous by Flutter's Navigator + Android 14's `OnBackInvokedCallback`. The system back then resolves to "pop the Activity" → minimize the app, because there is no `pop`-able route relationship.

The correct pattern for bottom-navigation apps with detail-screen pushes is **`StatefulShellRoute.indexedStack`** (introduced in go_router 7.1.0; current pinned version is 14.6.0 per `pubspec.yaml`). It gives each bottom-nav branch its own independent `Navigator` widget, and child routes declared under the branch produce hierarchical pushes whose back-gesture handling is unambiguous.

## Options Considered

### Option A — Switch the bottom-nav callers to `goBranch(index)` only, keep flat routes (cheap)

- Pros: minimal diff (~5 lines in `home_bottom_nav.dart` + minor adjustments).
- Cons: doesn't fix the StopDetail bug. The push-from-Home-into-Detail flow still uses flat sibling routes whose back behavior is broken. **Rejected.**

### Option B (this ADR) — Restructure `app.dart` with `StatefulShellRoute.indexedStack` + nest detail routes hierarchically

- Pros: aligns with the Flutter team's documented pattern for bottom-nav apps (Context7 confirmation). Each tab has its own stack; `push` works as expected within a tab. Detail screens become children of their owning branch, so back-gesture pops within the tab. Settings → back returns to Home (or stays in app), Home → tap stop → back returns to Home.
- Cons: larger refactor — `app.dart` doubles in size; ~10 callers update; `home_bottom_nav.dart` uses `StatefulNavigationShell.goBranch`. Higher implementation effort but the right architectural shape going forward.

### Option C — Replace `go_router` with a different routing package (e.g. `auto_route`, `beamer`)

- Pros: alternative implementations may have cleaner ergonomics for this pattern.
- Cons: ADR-0015 locked `go_router` for M2; replacement would be a stack change requiring its own ADR + dependency migration. The actual issue isn't `go_router` — it's our flat-routes configuration. **Rejected.**

### Option D — Replace `enableOnBackInvokedCallback="true"` with `false` to revert to legacy back-handling

- Pros: legacy Android back behavior ignores predictive-back semantics, which might mask the bug.
- Cons: `enableOnBackInvokedCallback="true"` is mandated by Android 14+ and is the project's documented direction (slice-2 task 4). Reverting is a regression to Android 13 era. **Rejected.**

## Decision

**Adopt Option B.** Restructure `apps/mobile/lib/app.dart` to use `StatefulShellRoute.indexedStack` with two branches:

```
StatefulShellRoute.indexedStack
├── Branch 0 (Rota tab)
│   GoRoute('/home')
│     └── GoRoute('stops/add')
│     └── GoRoute('stops/voice')
│     └── GoRoute('stops/ocr')
│     └── GoRoute('stops/map')
│     └── GoRoute('stops/add-map')
│     └── GoRoute('stops/reorder')
│     └── GoRoute('stops/:id')
│          └── GoRoute('edit')
│     └── GoRoute('optimize')
│          └── GoRoute('route')
│     └── GoRoute('navigate')
│     └── GoRoute('route-complete')
└── Branch 1 (Configurações tab)
    GoRoute('/settings')
      └── GoRoute('share')

Top-level (outside shell):
  GoRoute('/login')
  GoRoute('/register')
```

Each detail/sheet screen is a **sub-route of its parent branch**. `push` within a branch creates a legitimate hierarchical stack that pops correctly. Branch switching uses `StatefulNavigationShell.goBranch(index)` from `home_bottom_nav.dart`, preserving each branch's independent stack across tab switches.

### Navigation calls — the new rules

| Origin | Destination | Call | Why |
|---|---|---|---|
| Sibling auth screen | another auth screen | `context.go('/login' \| '/register')` | Auth screens live outside the shell; replace semantics are correct. |
| Bottom nav | another tab | `StatefulNavigationShell.of(context).goBranch(targetIndex)` | Switches branches; preserves each branch's stack. |
| Inside a branch | child detail / sheet route | `context.push('child-relative-path')` | Hierarchical push inside the branch's navigator. |
| Child detail/sheet | parent (back) | `context.pop()` | Always — `canPop()` is true within a branch's stack. The `canPop ? pop : go` fallback added in MS-01 stays as defense-in-depth for deep-link entries. |

### Closes the pipeline gap

A new gate is mandated by this ADR: **`integration_test` for back-navigation flows.** The `integration_test` package (Flutter team's official end-to-end testing surface) runs against the real `MaterialApp.router` instance on a connected Android device or emulator. One test file at `apps/mobile/integration_test/back_navigation_test.dart` will assert:

1. From `/home`, tapping a stop, then firing system back, returns to `/home` (current route equals `/home`, app not minimized).
2. From `/home`, switching to Configurações tab, then firing system back, returns to `/home` (or stays in app — either is acceptable; what matters is no minimize).
3. From `/home`, FAB push to `/home/stops/add`, then system back, returns to `/home`.

The test runs in Phase 3 of ADR-0021 and is added to `M2-SLICE-CHECKLIST.md` §Verification as a hard gate for every slice that touches routing or navigation.

## Consequences

- **Positive:** back-navigation behaves correctly on Android 14+ across the entire app; bottom-nav tabs preserve independent stacks; the pipeline gap that let MS-01 ship a regression closes via `integration_test`.
- **Negative:** `app.dart` grows from 111 lines to ~180 lines (the shell + nested route declarations); the route paths visible to URL/deep-link logic remain the same (`/stops/<id>`, `/settings/share`, etc. — the URL surface is preserved even though internal hierarchy nests).
- **Process change (mandatory):** `M2-SLICE-CHECKLIST.md` §Verification adds **`flutter test integration_test/` (or equivalent `flutter drive`) must pass before tag** for any slice that touches `apps/mobile/lib/app.dart` or any caller's navigation expression. This is a hard gate, equal in force to the existing `flutter analyze` gate.
- **Memory:** a memory entry (`go_router-flat-routes-back-button.md`) under `~/.claude/projects/.../memory/` captures the anti-pattern so future sessions don't re-introduce flat sibling routes for detail/sheet flows.

## Implementation notes

The migration happens inside **microsprint MS-01b** of the ADR-0021 plan — it amends MS-01 in-flight rather than reverting and re-doing. The MS-01 commit (`2124b7f`) stays in history as a partial-fix milestone; the MS-01b commit will land on top with the architectural restructure.

The pipeline for MS-01b runs the standard 7 phases (PRE-FLIGHT → D1 → D2 → D3 → D4 → COMMIT → CHECKPOINT) plus one new step **inside D2**: the implementer must add `apps/mobile/integration_test/back_navigation_test.dart` covering the three scenarios above and confirm the test passes on a connected Android device before declaring D2 complete.

## References

- Flutter team's `go_router` documentation: `StatefulShellRoute` introduced in 7.1.0 specifically for "separate navigators for child routes and preserve state in each navigation tree" (Context7 changelog).
- flutter/flutter issue #145198 — "GoRouter not popping on Android 14 with android back button" — community confirmation of the flat-routes failure mode.
- codewithandrea.com "Flutter Navigation with GoRouter: Go vs Push" — community guide.
- `apps/mobile/lib/app.dart` (pre-refactor at commit `2124b7f`; post-refactor at the MS-01b commit).
- `apps/mobile/integration_test/back_navigation_test.dart` (new in MS-01b — the gate).
- ADR-0021 §Phase 2 microsprint table — MS-01b will be appended as row 16.5 in the next plan amendment.
- Memory: `~/.claude/projects/.../memory/go_router-flat-routes-back-button.md` (filed in MS-01b CHECKPOINT).
