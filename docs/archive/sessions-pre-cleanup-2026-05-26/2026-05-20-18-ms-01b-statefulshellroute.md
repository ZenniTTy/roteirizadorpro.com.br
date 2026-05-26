# Session 2026-05-20-18 — MS-01b StatefulShellRoute

## Metadata

- **Date**: 2026-05-20 (America/Sao_Paulo)
- **Sequence**: 18
- **Agent**: Claude Code (Opus 4.7)
- **Human**: Eduardo
- **Topic**: ms-01b statefulshellroute
- **Duration**: ~6h (across context-compaction boundary)
- **Related ADRs**: ADR-0021 (slice-2 fidelity remediation), ADR-0022 (router uses StatefulShellRoute — amends MS-01)
- **Related TODO items**: Slice 2 audit catalog row A-1 (router cross-cutting), MS-01, MS-01b

## Goal of the Session

Close the Android system-back regression that MS-01 (commit `2124b7f`) only partially fixed. Device smoke after MS-01 showed back still minimizing the app on multiple flows. Root-cause it, apply the canonical Flutter team pattern, add a hard regression gate, and document so the same false fix is never re-attempted.

## What Was Done

In chronological order:

1. **Device smoke after MS-01** on Galaxy A06 reproduced the regression: tapping a stop → system back exited the app instead of returning to `/home`. The `context.push` swap in MS-01 was insufficient because `/stops/:id` was a flat sibling route of `/home`, so the push was actually a `go` semantically.
2. **Context7 + WebSearch + WebFetch validation** before touching code. Queried `/websites/pub_dev_packages_go_router` and codewithandrea ("Flutter Bottom Navigation Bar with Stateful Nested Routes using GoRouter") for the canonical pattern. Confirmed the fix is `StatefulShellRoute.indexedStack` + hierarchical sub-routes under each branch root, with one `GlobalKey<NavigatorState>` per branch.
3. **Authored ADR-0022** documenting the restructure: route tree with two `StatefulShellBranch`es (`/home` and `/settings`), per-branch `navigatorKey`, pass-through shell builder (each branch's Scaffold renders its own AppBar + BottomNav), all `/stops/*` and `/optimize/*` routes nested under `/home` as children.
4. **Restructured `apps/mobile/lib/app.dart`** to match ADR-0022. Login and Register stay outside the shell (top-level routes; `context.go` for swap semantics). The 13 stop/optimize/navigate/route-complete routes become children of `/home`. The 1 share route becomes a child of `/settings`.
5. **Refactored `HomeBottomNav`** to accept an optional `StatefulNavigationShell` and dispatch tab taps via `shell.goBranch(index)` when present. A test-only fallback to `context.go('/home' | '/settings')` is kept for widget tests that mount the nav in isolation.
6. **Touched 13 caller files** that referenced removed flat routes — every `context.go('/stops/...')` became `context.go('/home/stops/...')`; every push went through the same prefix. `AppBar` back-arrow `onPressed` overrides removed where the default (`Navigator.pop`) suffices.
7. **Added `integration_test/back_navigation_test.dart`** as the new hard gate. Three cases on real device: (A) Home → tap stop → system back returns to `/home`; (B) Home → FAB → AddStop → system back returns to `/home`; (C) StopDetail → Editar → system back returns to detail. Helper inspects `AppBar.title` text because `GoRouter.of(context)` requires a context inside the `InheritedGoRouter` scope (see memory `go-router-stateful-shell-test-context.md`).
8. **Added `integration_test: { sdk: flutter }`** to `apps/mobile/pubspec.yaml` dev_dependencies.
9. **Updated `docs/M2-SLICE-CHECKLIST.md`** with a new hard-gate row: any slice touching `app.dart` or navigation expressions must run `flutter test integration_test/` on a connected Android device before merge.
10. **Three failed PopScope iterations** during the false-alarm investigation of "Settings → back exits app":
    - v1: `context.push` everywhere — back from Settings still exited.
    - v2: `PopScope` in shell builder with dynamic `canPop` via `branchKey.currentState?.canPop()` — `NavigatorState.canPop()` returns true for branch root initial route, so canPop resolved wrong.
    - v3: `PopScope` always intercepts + runtime decision via `GoRouter.canPop()` inside `onPopInvokedWithResult` — callback never fired because pop dispatch resolves to the leaf Scaffold first; the shell-level scope sits below it in dispatch.
11. **Recognized the false alarm.** Re-read codewithandrea and Eduardo manually compared against Gmail, Drive, Photos — all exit when back is pressed from a bottom-nav root tab with no sub-routes pushed. This is documented expected behavior, not a bug. Reverted all three PopScope iterations to a plain pass-through `builder: (_, __, navigationShell) => navigationShell`.
12. **Added §"Out of scope: branch-root back behavior"** to ADR-0022 documenting the platform UX convention and citing codewithandrea verbatim.
13. **Rewrote memory `popscope-statefulshellroute-android-back.md`** (the file existed from an earlier wrong-direction note; rewritten with the correct answer: do not intercept branch-root back; the three v1/v2/v3 attempts and why each failed).
14. **Created memory `subagent-foreground-long-commands.md`** after a D2 implementer subagent (`a9579819f57270127`) emitted "Still building. Will wait for notification." and ended its turn without surfacing gate output. Rule captured: subagents dispatched to run >2min verification commands must be instructed explicitly to run foreground with explicit timeout, never background.
15. **Created memory `go-router-stateful-shell-test-context.md`** documenting that integration tests reading the current URL must resolve a `BuildContext` from above the shell (`find.byType(MaterialApp)`); `find.byType(Scaffold).last` is unreliable because `IndexedStack` keeps every branch's Scaffold mounted simultaneously.
16. **Gate verification on Galaxy A06** (USB after Wi-Fi adb dropped during 69 MB APK transfer): `flutter analyze --no-pub` 0 issues, `flutter test` 91/91 widget tests, `flutter test integration_test/back_navigation_test.dart -d R9QY30134RD` 3/3 PASSED. Manual smoke: cases A (FAB→AddStop→back), C (tap stop→detail→back), D (detail→Editar→back) all green. Eduardo confirmed: "tudo OK".
17. **Dispatched D3 prototype-fidelity-checker** and **D4 pr-review-toolkit:code-reviewer** subagents — both APPROVED.
18. **Two D4 follow-up edits** before commit: stale comment in `app.dart` rewritten to describe the actual final state (pass-through builder + ADR-0022 reference); test count mismatch fixed (ADR said 3 integration_test cases, file had 2 — added the StopDetail → Editar → back case).
19. **Two commits landed**: `16718e1` (architectural fix — refactor(mobile): adopt statefulshellroute + nested routes (ms-01b)) and `45ffc66` (TODO checkpoint — docs(docs): ms-01b checkpoint — close router catalog row a-1 with right sha). Lefthook + commitlint passed both without `--no-verify`.

## Decisions Made

1. **Restructure router with `StatefulShellRoute.indexedStack` + hierarchical sub-routes** — Filed as ADR-0022. Canonical Flutter team pattern for bottom-nav apps with independent stacks per tab; closes the back-nav regression at the architecture level rather than patching push semantics.
2. **Per-branch `GlobalKey<NavigatorState>`** — required for branch-stack isolation. `_routeBranchKey` and `_settingsBranchKey` declared at module top of `app.dart`.
3. **Pass-through shell builder** — `builder: (context, state, navigationShell) => navigationShell` with no additional chrome. Each branch's Scaffold renders its own AppBar + BottomNav. Avoids double-chrome and keeps the existing per-page top bars intact.
4. **Branch-root back = exit app is correct UX, do not intercept** — codified in ADR-0022 §"Out of scope: branch-root back behavior". Cites codewithandrea + Gmail/Drive/Photos. Reverses three v1/v2/v3 PopScope attempts.
5. **`integration_test` as hard gate for navigation changes** — added to `M2-SLICE-CHECKLIST.md`. Widget tests, analyzer, and static fidelity check would not have caught this regression; only an on-device test can validate Android system-back behavior.
6. **`AppBar.title` text as test signal** — `_currentScreen(tester)` helper inspects the first visible `AppBar`'s `Text.data`. Cleaner than fighting `GoRouter.of` context resolution inside `StatefulShellRoute`, where `IndexedStack` keeps every branch's Scaffold mounted simultaneously.
7. **Subagent verification commands must run foreground** — captured as memory `subagent-foreground-long-commands.md`. Subagents that background long commands lose the completion notification because their sessions close on `end_turn`. Future D2 subagent prompts must mandate foreground + explicit timeout for any command >2min.

## Open Questions Left

- [ ] MS-02..MS-16 microsprints still pending — slice-2 fidelity remediation is 2/16 done after this session (MS-01 + MS-01b count as one combined effort toward A-1).
- [ ] F3 re-audit + rebuild APK + 14-step E2E + `/verify-slice` still pending after MS-16.
- [ ] PR `develop → main` + tag `v1.1.0` only after F3 closes.

## Files Changed

**Created**:
- `apps/mobile/integration_test/back_navigation_test.dart` (170 lines, 3 test cases)
- `docs/decisions/0022-router-stateful-shell-route.md`
- `docs/superpowers/plans/2026-05-19-slice-2-fidelity-remediation.md` (microsprint catalog already partially authored under ADR-0021; this session added MS-01/MS-01b execution log rows)
- `~/.claude/projects/.../memory/subagent-foreground-long-commands.md`
- `~/.claude/projects/.../memory/go-router-stateful-shell-test-context.md`

**Modified**:
- `apps/mobile/lib/app.dart` (router restructure to StatefulShellRoute)
- `apps/mobile/lib/features/stops/presentation/shared/home_bottom_nav.dart` (accept `StatefulNavigationShell`, dispatch via `goBranch`)
- 13 caller files updating route literals to the `/home/...` hierarchy:
  - `apps/mobile/lib/features/settings/presentation/settings_page.dart`
  - `apps/mobile/lib/features/stops/presentation/add_stop_page.dart`
  - `apps/mobile/lib/features/stops/presentation/add_stops_map_page.dart`
  - `apps/mobile/lib/features/stops/presentation/edit_stop_page.dart`
  - `apps/mobile/lib/features/stops/presentation/home_empty_page.dart`
  - `apps/mobile/lib/features/stops/presentation/home_list_page.dart`
  - `apps/mobile/lib/features/stops/presentation/navigate_page.dart`
  - `apps/mobile/lib/features/stops/presentation/ocr_capture_page.dart`
  - `apps/mobile/lib/features/stops/presentation/optimize_page.dart`
  - `apps/mobile/lib/features/stops/presentation/optimize_route_page.dart`
  - `apps/mobile/lib/features/stops/presentation/reorder_page.dart`
  - `apps/mobile/lib/features/stops/presentation/route_complete_page.dart`
  - `apps/mobile/lib/features/stops/presentation/stop_detail_page.dart`
  - `apps/mobile/lib/features/stops/presentation/voice_capture_page.dart`
- `apps/mobile/pubspec.yaml` + `pubspec.lock` (add `integration_test: { sdk: flutter }`)
- `docs/M2-SLICE-CHECKLIST.md` (new integration_test hard-gate row)
- `TODO.md` (catalog row A-1 closed, MS-01/MS-01b log rows)
- `~/.claude/projects/.../memory/popscope-statefulshellroute-android-back.md` (rewritten — was wrong; now documents that branch-root exit is platform UX)

## Commits Pushed

```
2124b7f refactor(mobile): router — push semantics for sheet/detail routes (ms-01)
54e105e docs(docs): ms-01 checkpoint — close router back-nav catalog rows
cd3044c docs(decisions): adr-0022 router uses statefulshellroute (amends ms-01)
16718e1 refactor(mobile): adopt statefulshellroute + nested routes (ms-01b)
45ffc66 docs(docs): ms-01b checkpoint — close router catalog row a-1 with right sha
```

Branch `feat/m2-slice-2-telas-core` advanced from `f0bb080` to `45ffc66` (5 new commits, 2 ahead of `origin/feat/m2-slice-2-telas-core`).

## Hand-off Notes for Next Session

- **Branch**: `feat/m2-slice-2-telas-core` at `45ffc66`. `git status` clean. 2 commits ahead of origin — push when ready.
- **Slice-2 fidelity remediation**: 2/16 microsprints done. **MS-02 widget-home-top-bar** is next: shared widget new file `apps/mobile/lib/core/widgets/home_top_bar.dart` replicating `prototipo/ui.jsx:160-193` (fontSize 22 w600, ETA chip with clock icon, count chip with mappin, optional MoreVertical button). It's a prerequisite for MS-13 (HomeEmpty rebuild) and MS-14 (HomeList rebuild).
- **MS-02 pipeline plan**: PRE-FLIGHT (read `prototipo/ui.jsx:160-193` HomeTopBar + `prototipo/tokens.js`) → D1 N/A (new widget, no existing audit failure) → D2 implementer creates the widget + unit test at `test/core/widgets/home_top_bar_test.dart` → D3 prototype-fidelity-checker → D4 pr-review-toolkit:code-reviewer → COMMIT → CHECKPOINT (no rebuild needed; MS-13/14 will consume).
- **Gates baseline before MS-02**: `flutter analyze` clean, `flutter test` 91/91 green, integration_test 3/3 green on Galaxy A06.
- **Memory entries created/updated this session** (all loaded automatically on next session start):
  - `go-router-stateful-shell-test-context.md` — how to read URL/screen in StatefulShellRoute integration tests.
  - `subagent-foreground-long-commands.md` — D2 subagent verification commands must run foreground.
  - `popscope-statefulshellroute-android-back.md` (rewritten) — branch-root back is platform UX; do not intercept.
- **Standing rule on subagent dispatch**: when invoking D2 implementers for microsprints whose gates include `flutter test integration_test/`, `flutter build apk`, or anything else >2min, mandate foreground + explicit timeout (600s for integration_test, 600s for build, 300s for full test, 60s for analyze) in the prompt.

## Reference Material Used

- Context7 — `/websites/pub_dev_packages_go_router` (changelog 14.6.1 + 14.8.1 confirming PopScope fix in root routes and `StatefulShellRoute` semantics).
- codewithandrea — "Flutter Bottom Navigation Bar with Stateful Nested Routes using GoRouter" (canonical reference for branch-root back UX expectation).
- go_router 14.8.1 source — `lib/src/route.dart:1518-1530` (IndexedStack mounts all branches simultaneously).
- Anthropic best practices — "verify before claim done" (`aapt2 dump permissions`-style discipline applied here as `flutter test integration_test/` on real device).
- Memory: `flutter-android-release-internet-permission.md` (precedent for "validate on real device, not just simulator/analyzer").
