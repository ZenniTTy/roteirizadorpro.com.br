# Plan — M2 Slice 2 fidelity remediation

> **Date:** 2026-05-19
> **Author:** Claude Code (with Eduardo)
> **Status:** Approved
> **Spec:** `docs/superpowers/specs/2026-05-19-slice-2-fidelity-remediation-design.md`
> **ADR:** `docs/decisions/0021-slice-2-fidelity-remediation.md`
> **Branch:** `feat/m2-slice-2-telas-core`

This plan implements the spec above. Three phases, executed strictly in order. Microsprints inside Phase 2 are strictly serial.

---

## Phase 1 — Audit catalog (read-only)

**Goal:** produce an authoritative list of every Critical / Important / Minor fidelity divergence across all 18 slice-1+2 screens, appended to `TODO.md`.

**Duration estimate:** 3–4 hours wall-time, one sequential agent run.

### Task 1.1 — Pre-flight: confirm canonical sources are loadable

- [ ] Verify `prototipo/tokens.js`, `prototipo/ui.jsx`, `prototipo/screens-{a,b,c,d,e}.jsx` are all readable and parse (no syntax issues from in-flight edits).
- [ ] Verify all 18 Dart presentation files still compile (`flutter analyze --no-pub` clean before audit).
- [ ] Record the audit's starting SHA: `git rev-parse HEAD`.

### Task 1.2 — Dispatch `prototype-fidelity-checker` (sequential single-agent)

Prompt (verbatim — copy into the Agent dispatch):

```
You are the prototype-fidelity-checker for Roteirizador Pro. Audit ALL 18 slice-1+2 screens
of the Flutter mobile app against the canonical prototype at prototipo/.

Canonical sources (load once, keep in context):
- prototipo/tokens.js         — design tokens (colors, radii, shadows, font)
- prototipo/ui.jsx            — shared primitives (Input, PrimaryButton, FAB, BottomNav, StopCard, HomeTopBar, TopBar, FlexibleBottomSheet, Phone)
- prototipo/screens-a.jsx     — ScreenLogin, ScreenRegister, ScreenHomeEmpty, ScreenHomeList,
                                 ScreenAddStop, ScreenVoice
- prototipo/screens-b.jsx     — ScreenOCR, ScreenAddStopsMap, ScreenOptimize, ScreenOptimizeRoute,
                                 ScreenStopDetail, ScreenPaywall (SKIP — slice 4),
                                 ScreenNavigate
- prototipo/screens-c.jsx     — ScreenMapStops
- prototipo/screens-d.jsx     — ScreenSettings, ScreenVoice (continued), ScreenShare
- prototipo/screens-e.jsx     — ScreenEditStop, ScreenReorder, ScreenRouteComplete

Audit pairs (Dart file ↔ prototype function):
  1.  apps/mobile/lib/features/auth/presentation/login_page.dart           ↔ ScreenLogin
  2.  apps/mobile/lib/features/auth/presentation/register_page.dart        ↔ ScreenRegister
  3.  apps/mobile/lib/features/stops/presentation/home_empty_page.dart     ↔ ScreenHomeEmpty
  4.  apps/mobile/lib/features/stops/presentation/home_list_page.dart      ↔ ScreenHomeList
  5.  apps/mobile/lib/features/stops/presentation/stop_detail_page.dart    ↔ ScreenStopDetail
  6.  apps/mobile/lib/features/stops/presentation/edit_stop_page.dart      ↔ ScreenEditStop
  7.  apps/mobile/lib/features/stops/presentation/add_stop_page.dart       ↔ ScreenAddStop
  8.  apps/mobile/lib/features/stops/presentation/voice_capture_page.dart  ↔ ScreenVoice
  9.  apps/mobile/lib/features/stops/presentation/ocr_capture_page.dart    ↔ ScreenOCR
  10. apps/mobile/lib/features/stops/presentation/add_stops_map_page.dart  ↔ ScreenAddStopsMap
  11. apps/mobile/lib/features/stops/presentation/map_stops_page.dart      ↔ ScreenMapStops
  12. apps/mobile/lib/features/stops/presentation/optimize_page.dart       ↔ ScreenOptimize
  13. apps/mobile/lib/features/stops/presentation/optimize_route_page.dart ↔ ScreenOptimizeRoute
  14. apps/mobile/lib/features/stops/presentation/navigate_page.dart       ↔ ScreenNavigate
  15. apps/mobile/lib/features/stops/presentation/reorder_page.dart        ↔ ScreenReorder
  16. apps/mobile/lib/features/stops/presentation/route_complete_page.dart ↔ ScreenRouteComplete
  17. apps/mobile/lib/features/settings/presentation/settings_page.dart    ↔ ScreenSettings
  18. apps/mobile/lib/features/share/presentation/share_sheet.dart         ↔ ScreenShare

Also audit:
  - apps/mobile/lib/app.dart — router (Critical if `context.go` is used where push semantics
    are required — i.e., anywhere the prototype wires onBack: () => goto(parent)).
  - apps/mobile/lib/core/theme/app_theme.dart — token drift vs prototipo/tokens.js
    (Critical if any color/radius/shadow value diverges from the prototype's token).

Severity rubric:
  - Critical: user-visible structural/behavioral divergence (wrong widget type, missing core
    UI element, broken navigation). Blocks slice tag.
  - Important: visible but not blocking (wrong title, missing back-arrow on a screen the user
    can leave another way, accessibility miss). Fix in the same microsprint if behavior-affecting;
    else dated debt.
  - Minor: <2dp drift, single-pixel border, harmless extra padding. Always debt.

Output format (one big markdown block, copy-pasteable into TODO.md):

  ## Slice 2 fidelity audit — findings (2026-05-19)

  ### <pair number>. <Dart file> ↔ <Screen* function>
  Status: ✅ FIEL  |  🟡 IMPORTANT-ONLY  |  🔴 HAS CRITICAL

  - **C-N (Critical):** <one-line> — prototype: `prototipo/screens-X.jsx:LINE-LINE` —
    current: `apps/mobile/lib/.../FILE.dart:LINE-LINE` — fix: <brief proposed change>
  - **I-N (Important):** <…>
  - **M-N (Minor):** <…>

Do NOT edit any code. Read-only audit. End your turn with a summary count:
  "Audit complete: X Criticals across Y screens; Z Importants; W Minors."
```

### Task 1.3 — Append catalog to `TODO.md` and commit

- [x] Catalog appended to `TODO.md` under `## Slice 2 fidelity audit — findings (2026-05-19, ADR-0021 Phase 1)` (lines 313–431). Commit `80efa67`.

### Task 1.4 — Triage decision gate

**Audit returned 22 Criticals (21 actionable; NavigatePage C-1 is pre-scoped by ADR-0017).** Threshold of 20 exceeded → triage gate escalated to Eduardo on 2026-05-20. **Decision: full remediation (option a)** — proceed to Phase 2 with all 21 microsprints. No timeline constraint per Eduardo (memory: time estimates are not constraints).

---

## Phase 2 — Microsprint correction loop

**Goal:** every Critical from the Phase 1 catalog ends with `→ FIXED (commit <sha>)`.

**Execution rule:** microsprints run **strictly serial** — no two in flight at once. Each one fully completes (including commit) before the next starts. This keeps `git log` linear, avoids cross-Critical interference, and makes per-microsprint rollback trivial.

**Microsprint ordering (blast-radius first):** router → shared widgets that screens consume → structural screen rebuilds → widget-level screen fixes. Token theme is ✅ fiel — no microsprint needed.

### Master microsprint table

| # | Slug | Closes Criticals | Touches | Class |
|---|---|---|---|---|
| MS-01 | `router-back-nav-push` | A-1 (router cross-cutting) + the back-nav portions of AddStop C-4, Voice C-1, OCR back, Edit back | `apps/mobile/lib/app.dart` + callers in HomeList/HomeEmpty/StopDetail/AddStop/EditStop pages | cross-cutting |
| MS-01b | `router-stateful-shell` | re-opens MS-01: device smoke proved flat-routes + `push` still minimizes app on Android back for sibling top-level routes. Restructure to `StatefulShellRoute.indexedStack` per ADR-0022 + add `integration_test/back_navigation_test.dart` as new harness gate. | `apps/mobile/lib/app.dart` (rewrite) + 10 callers' navigation calls + NEW `apps/mobile/integration_test/back_navigation_test.dart` + `M2-SLICE-CHECKLIST.md` (add gate) + memory entry | cross-cutting |
| MS-02 | `widget-home-top-bar` | shared primitive needed by MS-13 + MS-14 | NEW `core/widgets/home_top_bar.dart` | shared widget |
| MS-03 | `widget-rp-fab` | shared primitive needed by MS-13 (HomeEmpty C-2) | NEW `core/widgets/rp_fab.dart` | shared widget |
| MS-04 | `widget-rp-mini-pin` | shared primitive needed by MS-08 (AddStopsMap C-3) | NEW `core/widgets/rp_mini_pin.dart` | shared widget |
| MS-05 | `stop-detail-rebuild` | StopDetail C-1 (structural — 5 sections) | `stop_detail_page.dart` | structural |
| MS-06 | `edit-stop-modal-rebuild` | EditStop C-1 (structural — modal sheet + 6 option rows) | `edit_stop_page.dart` | structural |
| MS-07 | `ocr-dark-viewfinder` | OCR C-1 (structural — dark camera UI) | `ocr_capture_page.dart` | structural |
| MS-08 | `add-stops-map-floating-ui` | AddStopsMap C-1 + C-2 + C-3 | `add_stops_map_page.dart` (uses MS-04 RpMiniPin) | structural |
| MS-09 | `map-stops-full-screen` | MapStops C-1 (structural — floating header + neon chip + bottom panel) | `map_stops_page.dart` | structural |
| MS-10 | `optimize-route-split-layout` | OptimizeRoute C-1 + C-2 | `optimize_route_page.dart` | structural |
| MS-11 | `reorder-full-map-lasso` | Reorder C-1 (structural — full-map + lasso group selection) | `reorder_page.dart` | structural |
| MS-12 | `share-named-channels` | ShareSheet C-1 (named channel cards: WhatsApp + Copy + QR) | `share_sheet.dart` | structural |
| MS-13 | `home-empty-top-bar-and-fab` | HomeEmpty C-1 + C-2 (consumes MS-02 + MS-03) | `home_empty_page.dart` | widget-level |
| MS-14 | `home-list-top-bar` | HomeList C-1 (consumes MS-02) | `home_list_page.dart` | widget-level |
| MS-15 | `add-stop-sheet-chips-suggestions` | AddStop C-1 + C-2 + C-3 (back-nav C-4 already closed by MS-01) | `add_stop_page.dart` | structural |
| MS-16 | `voice-pulsing-mic` | Voice C-1 + C-2 + C-3 (back C-1 partial via MS-01) | `voice_capture_page.dart` | structural |

**Total: 16 microsprints (the 21 actionable Criticals collapse into 16 because some screens have multiple Criticals fixed together, and the router fix closes 5 back-nav Criticals at once).**

### Universal microsprint pipeline (applies to every MS below)

Each microsprint, regardless of slug, runs these 7 numbered phases. The per-MS sections below provide only the **MS-specific inputs** to these phases — the structure itself is constant.

```
[1] PRE-FLIGHT — controller reads sources, states delta in commit-msg draft, confirms GO/NO-GO.
[2] D1 prototype-fidelity-checker (single-screen, read-only) — confirms Criticals + produces delta spec.
[3] D2 implementer (claude subagent, isolated context) — implements delta, runs analyze + test, outputs diff.
[4] D3 prototype-fidelity-checker (re-audit, single-screen) — confirms Criticals closed + no regressions.
[5] D4 pr-review-toolkit:code-reviewer — Karpathy 4 + CLAUDE.md + ADR-0010 review.
[6] COMMIT — lefthook + commitlint + stop-hooks gate.
[7] CHECKPOINT — update TODO.md catalog row + (if structural) rebuild APK + reinstall A06 + smoke-test.
```

If D3 or D4 returns NO-GO → loop back to D2 with feedback. **Never** advance to the next MS until the current one commits and CHECKPOINT closes.

### Universal D1 prompt template

```
You are prototype-fidelity-checker auditing ONE screen for microsprint <MS-NN>.

Canonical sources (load once):
  - prototipo/tokens.js
  - prototipo/ui.jsx
  - <prototype file> (see MS section)

Pair: <Dart file> ↔ <prototype function name>
Prototype line range: <L-L>
Current implementation: read <Dart file> in full.

Catalog Criticals to confirm (from TODO.md lines 313-431):
<paste Criticals for this screen>

Output:
  1. Confirm each Critical is still present (or note if already fixed).
  2. Produce a numbered delta spec — exact widget tree changes to close each Critical.
  3. Cite prototype lines for each change.
  4. End with "Delta spec ready for implementer."

Read-only. Do NOT edit code.
```

### Universal D2 prompt template

```
You are implementing microsprint <MS-NN> in isolation. Read these in order:
  1. <Dart file> (current state)
  2. <prototype file>:<L-L> (the target structure)
  3. prototipo/tokens.js (any color/radius/shadow you reference)
  4. prototipo/ui.jsx (any shared primitive you reference)
  5. Delta spec from D1 (paste below)

Hard constraints:
  - Karpathy §1 (Think Before): if delta is ambiguous, stop and report; do not infer.
  - Karpathy §2 (Simplicity First): no flexibility, no extra abstractions beyond the delta.
  - Karpathy §3 (Surgical Changes): touch ONLY the lines the delta requires.
    Do not "improve" comments, formatting, or adjacent code.
  - Karpathy §4 (Goal-Driven): success = all delta items implemented + analyze clean + tests green.

Workflow:
  1. Implement the delta in <Dart file>.
  2. Run `flutter analyze --no-pub` (from apps/mobile/). Must report "No issues found".
  3. Run `flutter test test/<path-matching-this-screen>`. Must be all green.
     If existing test assertions break because the widget tree changed, update the test
     assertions in the same edit — do NOT skip tests or mark them as expected-fail.
  4. Output: the diff (unified format). Do NOT commit yet.

Delta spec (from D1):
<paste D1 output>

Files allowed to modify:
  - <list of file paths>

Files NOT allowed to modify (Karpathy §3 enforcement):
  - any file outside the allowed list, even if it "would be nice".
```

### Universal D3 prompt template

Identical to D1 but with the new state of `<Dart file>`. Expected: "✅ All Criticals closed. No new Criticals introduced." If new Criticals → loop back to D2.

### Universal D4 prompt template

```
You are pr-review-toolkit:code-reviewer reviewing microsprint <MS-NN>.

Diff to review:
<paste D2 diff>

Review against (in order of priority):
  1. Karpathy 4 principles (Think Before, Simplicity First, Surgical Changes, Goal-Driven).
  2. CLAUDE.md conventions (no comments unless WHY is non-obvious; no half-finished; no
     backwards-compat shims; no over-abstraction).
  3. ADR-0010 (prototype is canonical — every visual choice must trace to prototipo/).
  4. ADR-0013 (only if DTOs touched — UI remediation typically does not touch them).
  5. Lefthook + commitlint compliance (scope-enum, conventional commit format).

Severity tags:
  - BLOCKER: must fix before commit.
  - IMPORTANT: should fix before commit; if rejected, must be documented in TODO.md.
  - SUGGESTION: optional polish, eligible for dated debt.

Output:
  - List findings by severity.
  - End with one of: "APPROVED" | "REVIEW REQUIRED" | "BLOCKER FOUND".
```

### Universal COMMIT format

```
fix(mobile): <screen-slug> — <one-line summary>

Closes catalog Criticals: <C-N list> (TODO.md "Slice 2 fidelity audit").

Prototype: prototipo/screens-X.jsx:LINE-LINE.
Verified by prototype-fidelity-checker (re-audit) and pr-review-toolkit:code-reviewer.

[optional: brief implementation note if behavior or test surface changed]
```

For shared-widget microsprints (MS-02/03/04), use `feat(mobile): <widget-slug> — …` since these introduce new files. For the router microsprint (MS-01), use `refactor(mobile): router — push semantics for sheet/detail routes`.

### Universal CHECKPOINT

- Update `TODO.md` catalog: append `→ FIXED (commit <sha>)` to every closed Critical row.
- Tick the MS's `[ ]` in the master table at the top of this Phase 2 section.
- **If MS is `structural` class or `cross-cutting` class**: rebuild APK via `bash apps/mobile/scripts/build-release-apk.sh`, reinstall on A06 via `adb install -r`, smoke-test the changed screen visually, screenshot to `docs/sessions/2026-05-19-17-slice-2-fidelity-audit/screenshots/MS-NN-<slug>.png`.
- **If MS is `shared widget` class**: no rebuild needed (the widget has no caller yet); the consuming MS will rebuild.
- **If MS is `widget-level` class**: defer rebuild to MS-16 or to Phase 3.

---

### MS-01 — `router-back-nav-push` (cross-cutting)

**Closes:** A-1 + back-nav portions of (StopDetail "back to home"), (AddStop C-4), (Voice C-1 back), (OCR back), (Edit back), (ShareSheet I-1), (Reorder M-1 "Concluir" back).

**D1 inputs:**
- Pair: `apps/mobile/lib/app.dart` ↔ router meta (no single prototype function — cross-screen pattern)
- Catalog rows: `### A. apps/mobile/lib/app.dart (router cross-cutting)` (TODO.md ~line 416)
- Additional rows to scan: any "back-nav" or "context.go" mention in `### 7, ### 8, ### 9, ### 14, ### 15, ### 18`.

**Delta scope:**
1. In `app.dart`, the `GoRoute` declarations stay as-is (`go_router` supports both push and go on the same route). The fix is at the **caller** site.
2. Identify each `context.go(<path>)` call where the path corresponds to a screen the prototype wires as a stack-push (parent → detail/sheet). Replace with `context.push(<path>)`.
3. For the back-buttons inside those pushed screens, replace `context.go(<parent>)` with `context.pop()`.
4. For `predictive back` (Android 14+ `enableOnBackInvokedCallback`), `pop` flows correctly with the system back gesture; `go` does not.

**Caller sites to inspect (from catalog A-1 cite):**
- `home_list_page.dart` — tap on stop row, FAB, "Otimizar rota" CTA.
- `home_empty_page.dart` — FAB, "Como funciona?" pill.
- `stop_detail_page.dart` — "Editar" button.
- `add_stop_page.dart` — after submit (where to return).
- `edit_stop_page.dart` — back arrow + after-save.
- `voice_capture_page.dart` — back arrow + after-submit.
- `ocr_capture_page.dart` — back arrow + after-confirm.
- `share_sheet.dart` — back arrow.
- `reorder_page.dart` — "Concluir" checkmark.
- `optimize_route_page.dart` — close button.

**Rule of thumb for go vs push:**
- Sibling auth screens (login ↔ register), bottom-nav destinations (home ↔ settings), or auth-redirect targets → `context.go`.
- Push-and-return flows (home → detail, detail → edit, addStop → voice/ocr) → `context.push` + `context.pop`.

**D2 file allowlist:** the 10 caller files above + `app.dart` (no actual route table change expected; allowed in case a new `GoRoute` variant is needed for typed args).

**Test surface:** existing widget tests pass `onAddPressed`/`onSaved` callbacks instead of asserting `context.go`, so the router-fix should not break them. Verify after D2.

**Smoke test on A06 after CHECKPOINT:** add a stop, tap Android back — must return to home (not minimize). Open a stop → Editar → back — must return to detail (not home).

---

### MS-01b — `router-stateful-shell` (cross-cutting; amends MS-01)

**Why it exists:** MS-01 (commit `2124b7f`) passed all four pipeline gates (analyze + 91 tests + fidelity re-audit + code review) and shipped a release APK that still minimized the app on Android system back in two real flows (Home → tap stop → back; Settings → back). The smoke test on Galaxy A06 with USB install surfaced the regression. Root cause confirmed by Context7 (`/websites/pub_dev_packages_go_router`) + WebSearch (flutter/flutter#145198, codewithandrea Go-vs-Push, csells/go_router docs): `context.push` on flat sibling top-level routes does not produce a back-poppable stack; on Android 14+ with `enableOnBackInvokedCallback="true"` the system back resolves to "pop the Activity" → minimize. The fix is architectural — switch to `StatefulShellRoute.indexedStack` with hierarchical sub-routes per ADR-0022.

**Closes:** A-1 (re-open from MS-01) + the device-confirmed regression. Adds a new harness gate (`integration_test`) that future microsprints rely on.

**D1 inputs:**

- ADR-0022 (`docs/decisions/0022-router-stateful-shell-route.md`) is the normative reference.
- Context7 corpus loaded: `/websites/pub_dev_packages_go_router` for `StatefulShellRoute.indexedStack`, `StatefulNavigationShell.goBranch`, branch-scoped navigators, push semantics inside branches.
- Current file: `apps/mobile/lib/app.dart` (111 lines).
- Current callers (from the MS-01 grep map): `home_list_page.dart`, `home_empty_page.dart`, `stop_detail_page.dart`, `edit_stop_page.dart`, `add_stop_page.dart`, `voice_capture_page.dart`, `ocr_capture_page.dart`, `add_stops_map_page.dart`, `reorder_page.dart`, `settings_page.dart`, `share_sheet.dart`, `home_bottom_nav.dart`, `login_page.dart`, `register_page.dart`.

**Delta scope:**

1. **Rewrite `apps/mobile/lib/app.dart`** to declare:
   - Top-level routes (outside the shell): `/login`, `/register`.
   - One `StatefulShellRoute.indexedStack` containing two `StatefulShellBranch` instances:
     - **Branch 0** — root path `/home` with these sub-routes: `stops/add`, `stops/voice`, `stops/ocr`, `stops/map`, `stops/add-map`, `stops/reorder`, `stops/:id` (with child route `edit`), `optimize` (with child route `route`), `navigate`, `route-complete`.
     - **Branch 1** — root path `/settings` with sub-route `share`.
   - The shell's `builder` returns a Scaffold containing the active branch's navigator (`navigationShell` parameter) as body. The shell's Scaffold does NOT include the bottom nav widget — the `HomeBottomNav` stays in `HomeEmptyPage`/`HomeListPage`/`SettingsPage` because the prototype shows the bottom nav as part of the individual screen, not the shell. The shell only provides the indexed-stack navigator infrastructure.
   - URL surface stays identical: `/stops/<id>`, `/settings/share`, etc. — go_router's URL-to-route resolver handles nested paths transparently.
   - The `redirect` callback's auth logic is preserved verbatim; only the routes list changes.
   - The `_AuthListenable` class is preserved verbatim.

2. **Update `home_bottom_nav.dart`** to accept a `navigationShell: StatefulNavigationShell` parameter (passed from each consuming screen) and call `navigationShell.goBranch(index)` on tab tap instead of `context.go(...)`. Active-tab detection becomes `navigationShell.currentIndex == index` instead of the page-supplied `active` prop. Each page (`HomeEmptyPage`, `HomeListPage`, `SettingsPage`) reads the shell from `StatefulNavigationShell.of(context)` and passes it to `HomeBottomNav`.

3. **Update the 10 callers** to use branch-relative paths or branch-local push:
   - Inside Branch 0: `context.push('/home/stops/add')` style — the full URL form still works thanks to go_router's path matching; or use named routes if cleaner. The implementer chooses the style that keeps test assertions simplest.
   - Inside Branch 1: `context.push('/settings/share')` for the Indicar tile.
   - Auth siblings (`login_page.dart`, `register_page.dart`): KEEP `context.go` — those are outside the shell.

4. **Add `apps/mobile/integration_test/back_navigation_test.dart`** asserting:
   - Test 1: launch app, login, tap a stop on HomeList, fire `await tester.runAsync(() => SystemChannels.platform.invokeMethod('SystemNavigator.pop'))` (or use `tester.binding.handlePopRoute()` if cleaner), assert the current route is `/home` and the app's Navigator is non-empty.
   - Test 2: launch app, tap Configurações bottom-nav tab, fire system back, assert Branch 0 is active again OR the test framework still reports the app as foreground (no `SystemNavigator.pop` was reached).
   - Test 3: launch app, tap FAB → AddStop, fire system back, assert current route is `/home`.
   - Use `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` and `MaterialApp.router` setup matching production.

5. **Add `pubspec.yaml` dev dependency** `integration_test:` from Flutter SDK (it ships with Flutter — declare with `sdk: flutter`). Verify with Context7 before adding if the resolved version differs from Flutter SDK's bundled.

6. **Update `M2-SLICE-CHECKLIST.md`** §Verification: add a hard-gate bullet "**`flutter test integration_test/` must pass on a connected Android device before tag**, for any slice that touches `apps/mobile/lib/app.dart` or modifies a navigation expression." Cite ADR-0022.

7. **File a memory entry** at `~/.claude/projects/-Users-eduardorodrigues-Downloads-Elo-Vision-Digital--EVD----Meus-Projetos--APP----Entrega-Smart/memory/go_router-flat-routes-back-button.md` (type: feedback) capturing the anti-pattern and the fix, plus a link to ADR-0022 and the flutter/flutter issue.

**D2 file allowlist:**
- `apps/mobile/lib/app.dart` (rewrite)
- `apps/mobile/lib/features/stops/presentation/shared/home_bottom_nav.dart` (refactor to take shell)
- `apps/mobile/lib/features/stops/presentation/home_empty_page.dart` (pass shell to nav)
- `apps/mobile/lib/features/stops/presentation/home_list_page.dart` (pass shell to nav)
- `apps/mobile/lib/features/settings/presentation/settings_page.dart` (pass shell to nav + update Indicar tile push call)
- Any of the 10 caller files where a `context.push`/`context.go` argument needs to become a branch-relative path. Surgical edits — touch the exact lines.
- NEW `apps/mobile/integration_test/back_navigation_test.dart`
- `apps/mobile/pubspec.yaml` (only if `integration_test:` dev_dependency is missing; verify first)
- `docs/M2-SLICE-CHECKLIST.md` (one new bullet)

**Files NOT to touch:**
- Auth pages (`login_page.dart`, `register_page.dart`) — sibling-nav stays `go`.
- Existing 91 widget tests — they inject custom callbacks, won't break under the refactor.
- Visual code (any Scaffold body, any widget tree) — D3 fidelity re-audit catches drift.

**Test surface:**
- 91 existing widget tests must stay green (callback injection means they don't touch the router).
- 1 new integration test file with ≥3 scenarios passes on the Galaxy A06 via `flutter test integration_test/back_navigation_test.dart -d <device-id>`.
- `flutter analyze --no-pub` clean.

**Smoke test on A06 after CHECKPOINT (USB install required):**
- 4 cases — Home tap stop → back returns to Home; Settings tab → back returns to Home or stays in app (no minimize); FAB → AddStop → back returns to Home; StopDetail → Editar → back returns to StopDetail.
- All four must pass before MS-01b is considered closed.

**Pipeline override for MS-01b:** the **D2 step now mandates running `flutter test integration_test/` on the connected device before declaring done** — this is the new gate the ADR introduces. D3 and D4 still run after D2 with their standard prompts.

---

### MS-02 — `widget-home-top-bar` (shared widget, NEW file)

**Closes:** prerequisite for MS-13 + MS-14. No direct Critical closure (those happen in MS-13/14 when they consume this widget).

**D1 inputs:**
- Source-of-truth: `prototipo/ui.jsx` lines wrapping `HomeTopBar` (search "function HomeTopBar"). Also referenced in `prototipo/screens-a.jsx:160-193` (same function).
- New file path: `apps/mobile/lib/core/widgets/home_top_bar.dart`.

**Delta scope:**
- Create `HomeTopBar` as a `StatelessWidget` matching the prototype 1:1:
  - `Container` with `padding: EdgeInsets.fromLTRB(16, 8, 16, 12)`, `color: Colors.white`.
  - `Row` with `crossAxisAlignment: CrossAxisAlignment.center`, `mainAxisAlignment` left-to-right.
  - Title `'Rota de hoje'` (`fontSize: 22, fontWeight: w600, letterSpacing: -0.3`), `Expanded`.
  - ETA chip: `eta` nullable param; if null → `'--:--'` text + muted color; if non-null → highlight with `AppColors.primaryLight` bg + `AppColors.primary` text + `Icons.access_time_outlined` 14px.
  - Count chip: `Container` height 30, `padding` h 10, `AppColors.surface` bg + `AppColors.border` 1px + `Icons.place_outlined` 14px + count text.
  - Optional `showMore` param: if true, append a 36×36 transparent `IconButton(Icons.more_vert)` with `AppColors.text` color.

**Constructor signature:**
```dart
class HomeTopBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeTopBar({super.key, this.eta, required this.count, this.showMore = false});
  final String? eta;
  final int count;
  final bool showMore;
  @override Size get preferredSize => const Size.fromHeight(56);
  // ...
}
```

The `PreferredSizeWidget` implementation allows it to be used as `appBar:` in a Scaffold (cleaner than wrapping a custom widget in `PreferredSize`).

**D2 file allowlist:** new file `core/widgets/home_top_bar.dart` ONLY.

**Test surface:** create `test/core/widgets/home_top_bar_test.dart` with:
1. Renders title "Rota de hoje" with correct font weight + size.
2. ETA chip null state shows '--:--' with muted styling.
3. ETA chip non-null state shows the value with primary styling.
4. Count chip shows the count number.
5. `showMore: true` renders the more-vert icon; `false` does not.

**No rebuild** — widget has no callers yet.

---

### MS-03 — `widget-rp-fab` (shared widget, NEW file)

**Closes:** prerequisite for MS-13 (HomeEmpty C-2). HomeList currently doesn't have a FAB (uses persistent CTA) so this widget will have one caller until VRP/Navigate sites grow more.

**D1 inputs:**
- Source-of-truth: `prototipo/ui.jsx` `function FAB` (search "function FAB"). Also visible at `prototipo/screens-a.jsx:153` + `:272`.
- New file path: `apps/mobile/lib/core/widgets/rp_fab.dart`.

**Delta scope:**
- Create `RpFab` as a `StatelessWidget`:
  - 56×56 circular `Container` with `BoxDecoration`:
    - `shape: BoxShape.circle`
    - `gradient: LinearGradient(begin: topLeft, end: bottomRight, colors: [AppColors.accent, AppColors.primary])` (matches `linear-gradient(135deg, accent 0%, primary 100%)`)
    - `boxShadow: AppShadows.fab` — verify this token exists in `app_theme.dart`; if not, add it: `[BoxShadow(color: Color(0x526C3FC5), blurRadius: 24, offset: Offset(0, 8)), BoxShadow(color: Color(0x2E6C3FC5), blurRadius: 6, offset: Offset(0, 2))]` matching `fabShadow: '0 8px 24px rgba(108,63,197,0.32), 0 2px 6px rgba(108,63,197,0.18)'`.
  - `Material(type: transparency)` wrapping `InkWell(borderRadius: BorderRadius.circular(28))` for the splash.
  - `Center(child: Icon(Icons.add, color: Colors.white, size: 24))`.
- Position concern: in the prototype the FAB is `position: absolute, right: 20, bottom: 88` inside the screen frame, **above** the BottomNav. In Flutter, that's `Scaffold.floatingActionButton: RpFab(onPressed: …)` + `Scaffold.floatingActionButtonLocation: FloatingActionButtonLocation.endFloat` — Material's default placement is close enough; if the BottomNav overlap looks wrong on A06, switch to `FloatingActionButtonLocation.endTop` or use a custom location later. The MS-13 smoke test will validate.

**Constructor signature:**
```dart
class RpFab extends StatelessWidget {
  const RpFab({super.key, required this.onPressed, this.tooltip});
  final VoidCallback onPressed;
  final String? tooltip;
}
```

**Decision: Material FAB API vs custom.** A `FloatingActionButton.large` cannot accept a gradient via `backgroundColor`. The cleanest path is custom: wrap our container in a `Semantics(button: true, label: tooltip)` + `Tooltip(message: tooltip ?? '')` for accessibility parity with Material FAB.

**D2 file allowlist:** new file `core/widgets/rp_fab.dart` + (only if needed) `core/theme/app_theme.dart` to add `AppShadows.fab` const. If `app_theme.dart` is touched, the catalog row B "✅ FIEL" stays — we're adding a token, not changing existing.

**Test surface:** create `test/core/widgets/rp_fab_test.dart`:
1. Tap fires `onPressed`.
2. Tooltip is announced via Semantics when provided.

**No rebuild** — widget has one caller landing in MS-13.

---

### MS-04 — `widget-rp-mini-pin` (shared widget, NEW file)

**Closes:** prerequisite for MS-08 (AddStopsMap C-3). MS-09 (MapStops) also benefits; consume there too if scope-easy.

**D1 inputs:**
- Source-of-truth: `prototipo/screens-e.jsx:33-58` (MiniPin function — search "function MiniPin" in that file).
- New file path: `apps/mobile/lib/core/widgets/rp_mini_pin.dart`.

**Delta scope:**
- Create `RpMiniPin` as a `StatelessWidget`:
  - 22 wide × 26 tall body + a diamond tail at bottom-center (3-pixel triangle).
  - `selected: true` → `AppColors.primary` background, white text.
  - `selected: false` → white background, `AppColors.primary` text + 1px `AppColors.primary` border.
  - `BorderRadius.circular(6)` on the main rectangle.
  - Centered `Text(index.toString(), fontSize: 12, fontWeight: w700)`.
- The diamond tail is a `CustomPaint` extension; for surgical scope, draw with `Transform.rotate(45° → square)` clipped to a triangle path via `ClipPath`. Sketch:
  ```dart
  CustomPaint(painter: _PinTailPainter(color: …))
  ```
- Tooltip via Semantics (`'Parada $index'`).

**Constructor:**
```dart
class RpMiniPin extends StatelessWidget {
  const RpMiniPin({super.key, required this.index, this.selected = false});
  final int index;
  final bool selected;
}
```

**D2 file allowlist:** new file `core/widgets/rp_mini_pin.dart` only.

**Test surface:** create `test/core/widgets/rp_mini_pin_test.dart`:
1. Renders index number in body.
2. Selected state has primary background.
3. Unselected state has white background + primary border.

**No rebuild** — consumed by MS-08.

---

### MS-05 — `stop-detail-rebuild` (structural)

**Closes:** StopDetail C-1.

**D1 inputs:**
- Prototype: `prototipo/screens-b.jsx:158-214` (function `ScreenStopDetail`).
- Dart file: `apps/mobile/lib/features/stops/presentation/stop_detail_page.dart`.
- Catalog row: TODO.md "### 5. stop_detail_page.dart …"

**Delta scope (5 sections to add, in order):**
1. **MapPlaceholder** (top, 180dp height): use existing flutter_map `FlutterMap` widget with `MapOptions(initialCenter: LatLng(stop.lat, stop.lng), initialZoom: 16)`, a single `MarkerLayer` with one marker at the stop, and `TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'br.com.roteirizadorpro.roteirizador_pro')` + `RichAttributionWidget` per ADR-0016. Wrap in `ClipRRect(borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)))` so it visually anchors as a top section.
2. **Address + metadata card**: white `Container` with `AppColors.border` 1px + `AppRadii.card` + 16dp padding. Inside: `stop.label` as `headlineSmall` w600, then a `Row` of 3 muted-text items (`Icons.directions_walk` "1.2 km", `Icons.access_time` "5 min", `Icons.phone` "Contato" or blank if absent).
3. **ActionBtn row** (3 buttons): horizontal `Row` with 3 `_ActionBtn` widgets ("Entregue" green, "Falhou" red, "Próxima" purple). Each is a `Material+InkWell` with icon-above-label layout, ~80dp wide, `AppRadii.card`, distinct colors per state. Wire `onPressed` to placeholder `Navigator.of(context).pop()` for now (full state machine = slice 4 paywall scope).
4. **Locked PrimaryButton "Iniciar Navegação"**: use `RpButton(locked: true, label: 'Iniciar navegação')` (RpButton already supports `locked` per audit C catalog). Below it, `TextButton(child: Text('Assine para navegar →'), style: TextStyle(color: AppColors.primary))` linking to `/paywall` (not yet a route; use `onPressed: null` with `Tooltip(message: 'Disponível no slice 4')`).
5. **Move-options card**: white `Container` with `AppColors.border` 1px + `AppRadii.card`. Inside, 3 `ListTile`-style rows: "Tornar próxima parada" / "Mover para o início" / "Mover para o final", each with a leading icon (`Icons.arrow_upward`, `Icons.first_page`, `Icons.last_page`) and `onTap` calling `ref.read(stopsControllerProvider.notifier).reorder(stop.id, target_index)`.

The "Parada N de M" title (already implemented in earlier session) **stays** in the AppBar; the AppBar itself is acceptable here per the prototype's `TopBar` shape (back arrow + title + nothing else), but since the rest of the screen scrolls, swap `AppBar` for `SliverAppBar(pinned: true)` if scrolling looks odd — leave as `AppBar` unless D3 flags it.

**D2 file allowlist:**
- `apps/mobile/lib/features/stops/presentation/stop_detail_page.dart` (full rewrite)
- `test/features/stops/presentation/stop_detail_page_test.dart` (rewrite assertions)
- No new files beyond inline private widget classes inside the page file.

**Test surface:** existing test asserts the old detail body (label headline, lat/lng rows, Excluir/Editar buttons). Rewrite assertions:
1. Renders the map at top.
2. Renders address card with label as headline.
3. Renders 3 ActionBtn row.
4. Renders locked PrimaryButton + "Assine para navegar →" link.
5. Renders 3 move-option rows.

**Smoke test on A06 after CHECKPOINT:** open a stop from HomeList → see map + cards + buttons matching the prototype layout. Move-option taps update stop order (verify by going back to HomeList).

---

### MS-06 — `edit-stop-modal-rebuild` (structural)

**Closes:** EditStop C-1.

**D1 inputs:**
- Prototype: `prototipo/screens-e.jsx:471-627` (function `ScreenEditStop`).
- Dart file: `apps/mobile/lib/features/stops/presentation/edit_stop_page.dart`.

**Delta scope:**
1. **Switch from `Scaffold` to a modal sheet pattern.** Wrap the body in `DraggableScrollableSheet(initialChildSize: 0.85, minChildSize: 0.5, maxChildSize: 0.95)` over a faded background (`Container(color: AppColors.text.withOpacity(0.4))`). The page is still a route (not a `showModalBottomSheet`) so we keep deep-link compatibility, but the visual mimics a sheet.
2. **Drag handle** at the top of the sheet (40 wide × 4 tall pill, `AppColors.border` color).
3. **Header bar**: "Editar parada" left-aligned (fontSize 18 w600), "Concluído" right-aligned button — `TextButton(child: Text('Concluído', color: AppColors.primary))` that triggers save + pop.
4. **Color tag pill** (mock for now): chip with 4 swatches the user could pick from. Implement as a `Wrap` of 4 `_ColorSwatch` widgets, each a 32×32 circle (`AppColors.primary`/`accent`/`neon`/`success`). The selected swatch has a 2px white ring inside a 2px primary outer ring.
5. **Address title** (large): `stop.label` as `headlineSmall` w700.
6. **Gate-code chip**: small chip "Portão / Condomínio" with edit icon.
7. **Freetext note**: `TextFormField` multi-line, label "Observação", `border: OutlineInputBorder(borderRadius: AppRadii.input)`.
8. **6 option rows** (each a `RowItem`-style `ListTile`):
   - Localizador (leading `Icons.gps_fixed`, trailing chevron)
   - Pacotes (leading `Icons.inventory_2`, trailing stepper -1 / count / +1)
   - Ordem (leading `Icons.format_list_numbered`, trailing `SegmentedButton<int>` mock)
   - Tipo (leading `Icons.category`, trailing `SegmentedButton<String>` mock — Residência/Comércio/Devolução)
   - Horário de chegada (leading `Icons.schedule`, trailing time picker chip)
   - Tempo na parada (leading `Icons.timer_outlined`, trailing `'5 min'` chip)
9. **Action footer**: two `GhostButton` rows — "Mudar endereço" + "Duplicar parada".

The implementation can leave row interactivity as stubs (`onTap: () {}`) — the structural skeleton is what closes C-1; functional wiring becomes slice-3 polish.

**D2 file allowlist:**
- `apps/mobile/lib/features/stops/presentation/edit_stop_page.dart` (full rewrite)
- `test/features/stops/presentation/edit_stop_page_test.dart` (rewrite assertions)

**Test surface:** assert presence of: drag handle, header "Editar parada" + "Concluído" button, address title, 6 named option rows, 2 footer ghost buttons.

**Smoke test on A06:** open StopDetail → tap "Editar" → see modal sheet with all 6 rows; tap "Concluído" → returns to detail.

---

### MS-07 — `ocr-dark-viewfinder` (structural)

**Closes:** OCR C-1.

**D1 inputs:**
- Prototype: `prototipo/screens-b.jsx:4-100` (function `ScreenOCR`).
- Dart file: `apps/mobile/lib/features/stops/presentation/ocr_capture_page.dart`.

**Delta scope:**
1. **Dark scaffold**: `Scaffold(backgroundColor: Color(0xFF0E0E1A))` (matches prototype `#0E0E1A`). No `AppBar`.
2. **Frosted-glass close button** (top-left): `Positioned(top: MediaQuery.padding.top + 12, left: 12)` containing a 40×40 circle with `BackdropFilter(filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12))` + semi-transparent fill (`Colors.white.withOpacity(0.15)`) + `Icons.close, color: Colors.white`. Tap pops the route (MS-01 made this stack-push from AddStop).
3. **Mock package label** (centered viewfinder area): a `Container` with a fake address text mock-up, slightly offset to feel like a real label being scanned. Used only when no live camera preview is wired (which it isn't in slice 2 per spec non-goals).
4. **Dashed scan frame + 4 corner brackets**: a `Stack` over the viewfinder with a `CustomPaint(painter: _ScanFramePainter(accent: AppColors.accent))` drawing a dashed rectangle + 4 L-shaped corner accents in `AppColors.accent` (`#9B6DFF`).
5. **76×76 white capture button** (bottom-center): `Positioned(bottom: MediaQuery.padding.bottom + 32)` + outer ring 76 (white border 4px) + inner 60 white-filled circle. Tap triggers the existing `image_picker` flow (`pickImage(source: ImageSource.camera)`).
6. **Result card** (conditional state): when `_stage == OcrStage.result`, render a sheet at the bottom containing the recognized text + two buttons (Editar / Confirmar). The existing implementation already calls ML Kit per slice-2 scope; preserve the recognition logic, just rewrap the result UI in this card.

**D2 file allowlist:**
- `apps/mobile/lib/features/stops/presentation/ocr_capture_page.dart` (full rewrite)
- `test/features/stops/presentation/ocr_capture_page_test.dart` (rewrite assertions)

**Test surface:** assert dark background, close button, scan frame, capture button rendered; result card appears when state is `result`.

**Smoke test on A06:** AddStop → "Câmera" chip → see dark viewfinder; tap capture → camera permission prompt → photograph an address label → see result card; tap Confirmar → stop added, return to HomeList.

---

### MS-08 — `add-stops-map-floating-ui` (structural)

**Closes:** AddStopsMap C-1 + C-2 + C-3 (consumes MS-04 RpMiniPin).

**D1 inputs:**
- Prototype: `prototipo/screens-e.jsx:62-154` (function `ScreenAddStopsMap`).
- Dart file: `apps/mobile/lib/features/stops/presentation/add_stops_map_page.dart`.

**Delta scope:**
1. **Remove the Material `AppBar`.** Switch to `Scaffold(extendBodyBehindAppBar: true, body: Stack(...))`.
2. **Floating top header** (`Positioned(top: MediaQuery.padding.top + 12, left: 12, right: 12)`): `Row` with a 40×40 circular back button (`Material+InkWell`, white bg, `Icons.arrow_back`) + `Expanded` containing a search bar pill (`Container` height 40, white bg, `AppRadii.card`, `Icons.search` 18 + placeholder "Buscar endereço…" + soft `boxShadow`).
3. **Pin layer**: replace `CircleAvatar` markers with `RpMiniPin(index: i, selected: i == _selectedIndex)` from MS-04.
4. **Bottom sheet** (`Positioned(bottom: 0, left: 0, right: 0)`): a `Container` with `BoxDecoration(color: white, borderRadius: BorderRadius.vertical(top: AppRadii.sheet), boxShadow: AppShadows.sheet)`. Inside:
   - Drag handle (40×4 pill).
   - Selected pin's address text + a small `IconButton(Icons.edit)` for "Editar antes de adicionar".
   - `RpButton(label: 'Adicionar parada', neon: false)` (full-width).
   - `RpGhostButton(label: 'Adicionar e editar')` — tapping pushes `/stops/:id/edit` after adding the stop.
5. **Conditional rendering**: when no pin is selected, show only the floating header + map; when a pin exists, show the bottom sheet. Animate sheet appearance with `AnimatedSwitcher` or `AnimatedSlide` (250ms).

**D2 file allowlist:**
- `apps/mobile/lib/features/stops/presentation/add_stops_map_page.dart` (full rewrite)
- `test/features/stops/presentation/add_stops_map_page_test.dart` (rewrite)

**Test surface:** floating header + search bar present at all times; bottom sheet absent when no pin; bottom sheet present with Adicionar/Editar buttons when a pin exists.

**Smoke test on A06:** AddStop → "Mapa" or wherever this is reached (TBD — see MS-15) → tap map → pin appears with bottom sheet → tap Adicionar → stop count goes up; tap "Adicionar e editar" → routes to EditStop with the new stop.

---

### MS-09 — `map-stops-full-screen` (structural)

**Closes:** MapStops C-1.

**D1 inputs:**
- Prototype: `prototipo/screens-c.jsx:3-197` (function `ScreenMapStops`).
- Dart file: `apps/mobile/lib/features/stops/presentation/map_stops_page.dart`.

**Delta scope:**
1. Remove `AppBar`. Full-screen `FlutterMap`.
2. **Floating top header card** (`Positioned(top: padding.top + 12)`): back arrow + "Rota de hoje · N paradas" title (where N = `stops.length`) + a small stats row + "Adicionar" button routing to `/stops/add-map`.
3. **"AO VIVO" neon chip** (`Positioned(top: padding.top + 12, right: 12)`): `Container` with `AppColors.neon` background, `AppColors.neonInk` text, 8dp padding, `AppRadii.card`, "AO VIVO" label + pulsing dot animation. Use `AnimationController` with a `Tween<double>` driving opacity 0.4 ↔ 1.0 at 1Hz.
4. **Map controls column** (`Positioned(right: 12, top: 50% center)`): vertical stack of 3 buttons — zoom +, zoom −, recenter. Each is a 40×40 white circle with shadow. Wire to FlutterMap controller (`mapController.move(...)` for zoom; `mapController.move(currentLocation, currentZoom)` for recenter).
5. **Bottom action panel** (`Positioned(bottom: 0)`): floating card with the current-stop preview at top, Adicionar + Editar buttons mid, and a gradient "Iniciar navegação" CTA (use `RpButton(neon: true, icon: Icons.navigation, label: 'Iniciar navegação')`). The "Iniciar navegação" tap routes to `/navigate` (existing route).

**D2 file allowlist:**
- `apps/mobile/lib/features/stops/presentation/map_stops_page.dart` (full rewrite)
- `test/features/stops/presentation/map_stops_page_test.dart` (likely create — verify if exists)

**Test surface:** floating header rendered; AO VIVO chip rendered with pulse; map controls rendered; bottom action panel rendered with Iniciar navegação CTA.

**Smoke test on A06:** HomeList → some entry point to MapStops (TBD — verify routing) → see full-screen map with all overlays matching prototype.

---

### MS-10 — `optimize-route-split-layout` (structural)

**Closes:** OptimizeRoute C-1 + C-2.

**D1 inputs:**
- Prototype: `prototipo/screens-e.jsx:157-297` (function `ScreenOptimizeRoute`).
- Dart file: `apps/mobile/lib/features/stops/presentation/optimize_route_page.dart`.

**Delta scope:**
1. Remove `AppBar`. Use `Stack` with `extendBodyBehindAppBar: true`.
2. **Top map area** (`Positioned(top: 0, left: 0, right: 0, height: 460)`): full-bleed `FlutterMap` with optimized route polyline + `RpMiniPin` markers numbered 1..N.
3. **Close button** (`Positioned(top: padding.top + 12, left: 12)`): 40×40 white circle + `Icons.arrow_back` calling `context.pop()`.
4. **"ROTA OTIMIZADA" neon badge** (`Positioned(top: padding.top + 12, right: 12)`): `Container` with `AppColors.neon` background, `AppColors.neonInk` text, "ROTA OTIMIZADA" label.
5. **Overlapping bottom sheet** (`Positioned(bottom: 0, top: 420)` — 40dp overlap with map): `Container(decoration: …borderRadius vertical top, AppShadows.sheet)`. Inside:
   - Drag handle.
   - Search bar (filter stops).
   - Title "São Paulo · 27 paradas" — replace literal with `'<city> · ${stops.length} paradas'`. City TBD; for now, hardcode "São Paulo" since slice 1 ADR-0015 §3 locked SP-only.
   - Action chips: "Compartilhar rota" + "Carregar veículo" — `OutlinedButton.icon` row. "Compartilhar rota" pushes `/share`. "Carregar veículo" stub (slice-3 polish).
   - `ListView.builder` of stops with ETA column on the right (mock ETA for now — slice 3 VRP supplies real values).
6. **Bottom CTA**: keep the existing `RpButton(neon: true, label: 'Iniciar rota', icon: Icons.navigation)` *inside* the sheet (not floating below). Wire it to existing nav-provider chunking logic (already implemented).

The existing `_MetricsRow` widget (distance/duration) can be repurposed inside the sheet header row (above the action chips) or removed if it duplicates the new title row.

**D2 file allowlist:**
- `apps/mobile/lib/features/stops/presentation/optimize_route_page.dart` (significant rewrite — keep navigation provider chunking logic verbatim, restructure rest)
- `test/features/stops/presentation/optimize_route_page_test.dart` (rewrite assertions)

**Test surface:** map area + close button + neon badge + overlapping sheet with title/chips/stops + Iniciar rota CTA.

**Smoke test on A06:** Add 5+ stops → Otimizar rota → arrive at OptimizeRoute screen → verify visual match with prototype. Tap Compartilhar rota → routes to /share.

---

### MS-11 — `reorder-full-map-lasso` (structural)

**Closes:** Reorder C-1.

**D1 inputs:**
- Prototype: `prototipo/screens-e.jsx:630-737` (function `ScreenReorder`).
- Dart file: `apps/mobile/lib/features/stops/presentation/reorder_page.dart`.

**Delta scope:**
1. Remove `AppBar`. Full-screen `Stack` over `FlutterMap`.
2. **Route polyline** + numbered `RpMiniPin` markers (1..N).
3. **Lasso ellipse**: a `CustomPaint(painter: _LassoPainter(points: _draggedPoints, color: AppColors.error))` — dashed red stroke. The painter renders the convex hull of `_draggedPoints` as an ellipse with a dashed stroke.
4. **Gesture detection**: `GestureDetector(onPanUpdate: …)` accumulating points into `_draggedPoints`. When the user releases (`onPanEnd`), compute which stops fall inside the lasso (point-in-polygon test on map coordinates) and mark them as `_selectedGroup`.
5. **Floating dispatcher card** (`Positioned(top: padding.top + 12)`): a small notification-style card explaining the lasso interaction ("Desenhe um círculo ao redor das paradas que deseja agrupar"). Dismiss-able.
6. **Undo pill button** (`Positioned(left: 12, centerVertical)`): vertical button "Desfazer" with `Icons.undo`. Reverts the last reorder action.
7. **Bottom panel** (`Positioned(bottom: 0)`): drag handle + `'<count> paradas selecionadas'` label + `RpGhostButton(label: 'Desenhar o grupo seguinte')` + `RpButton(neon: true, label: 'Reotimizar rota')`. The neon button triggers re-optimization (calls existing optimize flow).
8. **Drag-and-drop reorder fallback**: if the lasso interaction is too complex for slice-2 polish, ship the lasso skeleton (visual only) and keep the existing `ReorderableListView.builder` behavior accessible via a "Modo lista" toggle in the bottom panel. **Decision deferred to D2 implementer** — D1 should flag this and D4 reviewer should weigh complexity vs delivery.

**D2 file allowlist:**
- `apps/mobile/lib/features/stops/presentation/reorder_page.dart` (significant rewrite)
- `test/features/stops/presentation/reorder_page_test.dart` (rewrite)

**Test surface:** map rendered with route polyline; floating notification card; bottom panel with Reotimizar button; pan gesture on map registers lasso points.

**Smoke test on A06:** OptimizeRoute → reorder entry point → draw a circle around 3 stops → see them highlighted → tap Reotimizar.

---

### MS-12 — `share-named-channels` (structural)

**Closes:** ShareSheet C-1.

**D1 inputs:**
- Prototype: `prototipo/screens-b.jsx:394-451` (function `ScreenShare`).
- Dart file: `apps/mobile/lib/features/share/presentation/share_sheet.dart`.

**Delta scope:**
1. **Replace the single `Card` of selectable route text** with 3 named channel cards in a `Column`:
2. **Card 1 — WhatsApp**: white `Container` with `AppColors.border` 1px + `AppRadii.card` + `AppShadows.card`. Inside: 48×48 green circle (`Color(0xFF25D366)`) with `Icons.share` (substitute for WhatsApp icon if no asset; or use `FaIcon(FontAwesomeIcons.whatsapp)` if `font_awesome_flutter` is available — verify via Context7 before adding the dep). Title "WhatsApp" + subtitle "Compartilhar via app". Trailing `Icons.chevron_right`. Tap calls `SharePlus.instance.share(ShareParams(text: buildRouteText(stops), subject: 'Minha rota'))` with `text/plain` mime — system selects WhatsApp from the share menu.
3. **Card 2 — Copiar link de download**: same chrome. Inside: `Icons.link` 48×48 in `AppColors.primaryLight` circle. Title "Copiar link de download" + subtitle showing the URL `'roteirizadorpro.com.br/download'`. Trailing `IconButton(Icons.copy)` calling `Clipboard.setData(ClipboardData(text: 'https://roteirizadorpro.com.br/download'))` + a `ScaffoldMessenger.showSnackBar(SnackBar(content: Text('Link copiado!')))` confirmation.
4. **Card 3 — Mostrar QR Code**: same chrome. Inside: `Icons.qr_code_2` 48×48. Title "Mostrar QR Code" + subtitle "Escaneie para baixar". Tap expands the card to show a generated QR pointing at `https://roteirizadorpro.com.br/download` (use `qr_flutter` — Context7 first before adding the dep; if rejected, ship as a placeholder `Container(child: Icon(Icons.qr_code_2, size: 200))` with a TODO comment naming the dep).
5. **Keep the existing route text dump** as a secondary section at the bottom, marked as "Pré-visualização do texto" — useful for debugging.

**Decision on `font_awesome_flutter` and `qr_flutter`:** Context7 those packages before adding. They are eligible per ADR-0015 cost ceiling (both are free, on-device, no per-request cost). If rejected, fall back to Material icon + placeholder QR.

**D2 file allowlist:**
- `apps/mobile/lib/features/share/presentation/share_sheet.dart` (significant rewrite)
- `test/features/share/share_sheet_test.dart` (rewrite assertions)
- `apps/mobile/pubspec.yaml` IF a new dep is added (Context7-validated, with version pin)
- `docs/decisions/0015-m2-plan-and-libraries.md` IF a new dep is added (amend the table)

**Test surface:** 3 cards rendered; WhatsApp card tap fires `SharePlus.instance.share` (mock injection); Copy card tap writes to `Clipboard` (mock); QR card tap expands.

**Smoke test on A06:** Settings → Indicações → Indicar para um amigo → ShareSheet → see 3 cards; tap WhatsApp → system share dialog; tap Copy → snackbar; tap QR → see code.

---

### MS-13 — `home-empty-top-bar-and-fab`

**Closes:** HomeEmpty C-1 + C-2 (consumes MS-02 + MS-03).

**D1 inputs:**
- Prototype: `prototipo/screens-a.jsx:133-156` (function `ScreenHomeEmpty`).
- Dart file: `apps/mobile/lib/features/stops/presentation/home_empty_page.dart`.

**Delta scope:**
1. Replace `AppBar(title: const Text('Rota de hoje'))` with `HomeTopBar(eta: null, count: 0)` from MS-02. The `PreferredSizeWidget` interface lets it slot directly into `Scaffold.appBar:`.
2. Replace `FloatingActionButton(onPressed: …, child: Icon(Icons.add))` with `RpFab(onPressed: () => _addStop(context), tooltip: 'Adicionar parada')` from MS-03.
3. Optional Important I-1 (custom `EmptyIllustration` SVG): leave `Icon(Icons.local_shipping_outlined)` as-is for now; this is not a Critical and the SVG would require an additional asset import. Marked as slice-3 polish debt in TODO.md.

**D2 file allowlist:** `home_empty_page.dart` + `test/features/stops/presentation/home_empty_page_test.dart` (update if assertions reference AppBar by type).

**Smoke test on A06:** Fresh install → see HomeEmpty with the new top bar (chips visible) + gradient FAB.

---

### MS-14 — `home-list-top-bar`

**Closes:** HomeList C-1 (consumes MS-02).

**D1 inputs:**
- Prototype: `prototipo/screens-a.jsx:257-276` (function `ScreenHomeList`).
- Dart file: `apps/mobile/lib/features/stops/presentation/home_list_page.dart`.

**Delta scope:**
1. Replace `AppBar(title: const Text('Rota de hoje'), actions: …Chip(count)…)` with `HomeTopBar(eta: <computed ETA or '~14:30' placeholder>, count: stops.length, showMore: true)` from MS-02. ETA computation TBD (slice 3 VRP supplies); for now, pass a hardcoded placeholder or `null`.
2. Wire the `showMore: true` IconButton (MoreVertical) to a `PopupMenuButton` with options like "Limpar rota" (calls `ref.read(stopsControllerProvider.notifier).clear()`).

**D2 file allowlist:** `home_list_page.dart` + `test/features/stops/presentation/home_list_page_test.dart`.

**Smoke test on A06:** Add 3 stops → HomeList shows new top bar with ETA chip (placeholder OK) + count chip + more menu.

---

### MS-15 — `add-stop-sheet-chips-suggestions` (structural)

**Closes:** AddStop C-1 + C-2 + C-3 (C-4 already closed by MS-01).

**D1 inputs:**
- Prototype: `prototipo/screens-a.jsx:279-364` (function `ScreenAddStop`).
- Dart file: `apps/mobile/lib/features/stops/presentation/add_stop_page.dart`.

**Delta scope:**
1. **Switch from full-screen `Scaffold` to a modal bottom sheet route.** Two options:
   - (a) Keep AddStop as a route (`/stops/add`) and render its body as a `DraggableScrollableSheet` with a dark scrim background (like MS-06 EditStop pattern).
   - (b) Convert to `showModalBottomSheet` invoked from HomeList's FAB tap.
   - **Recommendation in D1: (a)** — keeps deep-link compat with router + matches MS-06 pattern. D2 implementer follows (a).
2. **Drag handle** at top of the sheet (40 wide × 4 tall, `AppColors.border`).
3. **Title "Adicionar parada"** (fontSize 18 w600, left-aligned).
4. **Address input** (`RpInput` widget already exists): focused state, prefix `Icons.search`, placeholder "Digite o endereço ou CEP...". When the input has ≥3 chars, show the suggestions list (item 6 below).
5. **3 method chips** (Teclado / Voz / Câmera): horizontal `Row` of 3 equal-width chips, each 56dp tall with `AppRadii.input` radius. Selected = `AppColors.primaryLight` bg + `AppColors.primary` 1.5px border + `AppColors.primary` text/icon. Default selected = "Teclado". Tap behavior:
   - "Teclado" → no nav (current state).
   - "Voz" → `context.push('/stops/voice')` (push semantics from MS-01).
   - "Câmera" → `context.push('/stops/ocr')` (push semantics from MS-01).
6. **Suggestions list** (when input ≥3 chars): a `Column` of 4 mock results in a `Container` with `AppColors.border` 1px + `AppRadii.card`. First result highlighted with `AppColors.primaryLight` bg + `AppColors.primary` text. Each row: `Icons.place_outlined` 18 + truncated address text. Real geocoding (Nominatim) is **slice-3 polish per spec non-goal** — these are hardcoded mocks for slice 2: `['Rua Haddock Lobo, 1500 · São Paulo', 'Rua Haddock Lobo, 150 · São Paulo', 'Av. Henrique Lobo, 200 · São Paulo', 'Rua Hadid Lobo, 15 · Guarulhos']`. Tap a suggestion → populate input + ready to submit.
7. **Add button** at the bottom (inside the sheet): `RpButton(neon: false, label: 'Adicionar parada')`. Tap calls existing `StopsController.add(...)` flow then `context.pop()`.

**D2 file allowlist:**
- `apps/mobile/lib/features/stops/presentation/add_stop_page.dart` (full rewrite)
- `test/features/stops/presentation/add_stop_page_test.dart` (rewrite assertions)
- Possibly `apps/mobile/lib/app.dart` if the route needs `routePushOverlay: true` style; expected: not needed since we render the scrim inside the page widget.

**Test surface:** drag handle + 3 chips + suggestions list (when input has text) + Add button. Chip tap on Voz/Câmera fires `context.push` to correct routes.

**Smoke test on A06:** HomeEmpty → tap FAB → see modal sheet over blurred home; tap chip Voz → ScreenVoice; back → still on AddStop sheet; type address → see suggestions; tap a suggestion → input populated; tap Adicionar parada → stop count goes up, returns to HomeList.

---

### MS-16 — `voice-pulsing-mic` (structural)

**Closes:** Voice C-1 + C-2 + C-3 (C-1 back portion was MS-01).

**D1 inputs:**
- Prototype: `prototipo/screens-a.jsx:367-411` (function `ScreenVoice`).
- Dart file: `apps/mobile/lib/features/stops/presentation/voice_capture_page.dart`.

**Delta scope:**
1. **Switch from Material `AppBar` to a flat `TopBar`** — create a small private `_FlatTopBar` widget in the file or use a simple `Row` at the top of the body with a back IconButton + title text. The back action calls `context.pop()` (push-stack now thanks to MS-01).
2. **Pulsing mic (centerpiece)**: a 200×200 `Stack` widget centered in the body. Inside:
   - **3 pulse rings** (`Positioned.fill`): each is a `AnimatedContainer` (or use `TweenAnimationBuilder<double>` for opacity/scale) with `AppColors.primaryLight` background, decoration `BoxShape.circle`. Drive `scale: 0.8 → 1.4` and `opacity: 0.7 → 0` over 1.6s, staggered with 0.5s offsets between rings. The animations match `@keyframes rpPulse` from `Roteirizador Pro.html:13-19` and `rpPulseDot` from `:17-19`.
   - **100×100 gradient mic circle** (centered): `Container` with `LinearGradient(begin: topLeft, end: bottomRight, colors: [AppColors.accent, AppColors.primary])` (matches `accent → primary` gradient) + `Icon(Icons.mic, size: 42, color: Colors.white)`.
3. **Transcript area** (below the mic): a `Container` with `AppColors.surface` background + `AppColors.border` 1px border + `AppRadii.card`. Inside, the live transcript text (from `speech_to_text` package, already wired) styled `italic` + `AppColors.text`. When no transcript yet, show muted placeholder "Aguardando você falar…".
4. **Two-button bottom row** (replace single CTA): `Row` of:
   - `RpGhostButton(label: 'Parar')` — stops the `speech_to_text` listener.
   - `TextButton(label: 'Tentar novamente')` — resets the transcript and restarts the listener.
5. **Confirm action**: after the listener stops with a non-empty transcript, an additional `RpButton(label: 'Adicionar parada')` appears at the very bottom that adds the stop via `StopsController.add(...)` then `context.pop()`. This replaces the implicit single CTA that was there before.

**D2 file allowlist:**
- `apps/mobile/lib/features/stops/presentation/voice_capture_page.dart` (full rewrite)
- `test/features/stops/presentation/voice_capture_page_test.dart` (rewrite assertions — likely already has `MockSpeechToText` style fakes; keep the existing test substrate but assert the new widget tree)

**Test surface:** flat top bar with back arrow; centered pulsing-mic widget (assert via `find.byKey(const Key('voice-mic-pulse'))` or by widget type); transcript container; Parar + Tentar novamente row; conditional Adicionar parada button.

**Smoke test on A06:** AddStop sheet → Voz chip → ScreenVoice opens with pulsing mic animation; speak an address ("Rua Augusta cinco mil"); transcript appears; tap Parar; tap Adicionar parada → stop count goes up.

---

### Phase 2 end of microsprints

After MS-16 commits and CHECKPOINT closes, Phase 2 is complete. Verify:

- [ ] All 16 MS rows in the master table at the top of Phase 2 have `[x]`.
- [ ] All 21 Criticals (22 minus NavigatePage C-1) in TODO.md catalog have `→ FIXED (commit <sha>)`.
- [ ] `flutter analyze --no-pub` 0 issues.
- [ ] `flutter test` all green.
- [ ] `bun run typecheck` clean.

Then advance to Phase 3.

---

## Phase 3 — Re-audit + device E2E

**Goal:** prove every Critical closed, every gate passes, the slice is ready for tag `v1.1.0`.

**Duration estimate:** 4–8h.

### Task 3.1 — Final fidelity sweep

- [ ] Dispatch `prototype-fidelity-checker` over all 18 screens **sequentially** (same prompt format as Phase 1).
- [ ] Expected output: "Audit complete: 0 Criticals across 0 screens; ..." (Importants/Minors may remain as documented debt).
- [ ] If any Critical resurfaces, return to Phase 2 with a new microsprint.

### Task 3.2 — Final build + install

- [ ] `bash apps/mobile/scripts/build-release-apk.sh` — full clean rebuild.
- [ ] `aapt2 dump permissions build/app/outputs/flutter-apk/app-release.apk` — must list INTERNET + ACCESS_FINE_LOCATION + RECORD_AUDIO + CAMERA.
- [ ] `apksigner verify --print-certs` — cert SHA-256 must match `D9:C9:61:D6:…:14:31` (ADR-0014).
- [ ] `adb -s <A06> uninstall br.com.roteirizadorpro.roteirizador_pro && adb -s <A06> install build/app/outputs/flutter-apk/app-release.apk`.

### Task 3.3 — Device E2E 14-step golden path

Execute on the Galaxy A06 (Android 16). Screenshot each step into `docs/sessions/2026-05-19-17-slice-2-fidelity-audit/`. Steps:

1. Open app → ScreenHomeEmpty.
2. Tap FAB → ScreenAddStop (bottom sheet over blurred home).
3. Add stop via Teclado chip + type address.
4. Tap chip "Voz" → ScreenVoice → speak address (Brazilian pt-BR locale; mic permission prompt).
5. Tap chip "Câmera" → ScreenOCR → photograph an address label.
6. Add a 4th stop via map tap → ScreenAddStopsMap.
7. Return to ScreenHomeList (now showing 4 stops with index circles).
8. Tap a stop → ScreenStopDetail (title shows "Parada N de 4").
9. Tap "Editar" → ScreenEditStop → change label → save → return to ScreenStopDetail.
10. Long-press to reorder → ScreenReorder → drag stop 4 to position 2 → save.
11. Tap "Otimizar rota" → ScreenOptimize (auto-fires) → ScreenOptimizeRoute (map + metrics).
12. Tap "Iniciar rota" → opens Waze (default) → return to app via task switcher → ScreenNavigate.
13. Tick all stops as concluded → ScreenRouteComplete (2-layer box-shadow card).
14. Open ScreenSettings → toggle nav provider to Google Maps → verify persistence (kill app, reopen, toggle still on Maps). Tap "Indicações" → ScreenShare → tap "Compartilhar" → verify native share sheet opens.

Every step must visually match the prototype's corresponding `Screen*` function. Screenshots vs prototype thumbnails side-by-side.

### Task 3.4 — `/verify-slice` skill

- [ ] Run `/verify-slice` from Claude Code.
- [ ] Expected: all sub-checks green (flutter analyze, flutter test, bun typecheck, prototype-fidelity-checker, adr-guardian).

### Task 3.5 — Process fix: update `M2-SLICE-CHECKLIST.md`

- [ ] Add a new mandatory bullet under §Verification:
  > **Device E2E golden-path on physical Android (not emulator) before tag.** Capture screenshots into the session-log directory. Validate every UI step matches the prototype's corresponding `Screen*` function.
- [ ] Commit: `docs(checklist): add device-e2e gate (adr-0021)`.

### Task 3.6 — Session-end commit

- [ ] Write `docs/sessions/2026-05-19-17-slice-2-fidelity-audit.md` from the template.
- [ ] Update `docs/sessions/0001-INDEX.md`.
- [ ] Update `TODO.md` reflecting the post-remediation state (every Critical closed, debt items dated).
- [ ] Commit: `docs(sessions): 2026-05-19-17-slice-2-fidelity-audit`.

### Task 3.7 — Promote slice

- [ ] Open PR `feat/m2-slice-2-telas-core` → `develop`.
- [ ] After CI green + ADR-0021 referenced in PR body, merge.
- [ ] Open PR `develop` → `main`.
- [ ] After merge, tag `v1.1.0` and republish APK (Task 38 from the old plan resumes here).

---

## Execution log

(Filled in as phases complete.)

- **2026-05-19 23:XX** — Phase 0 (spec/plan/ADR) committed at SHA `<…>`.
- **2026-05-19 23:XX** — Phase 1 audit catalog committed at SHA `<…>`. Found `<X>` Criticals across `<Y>` screens; `<Z>` Importants; `<W>` Minors.
- **2026-05-XX HH:MM** — Phase 2 complete; last microsprint commit `<…>`.
- **2026-05-XX HH:MM** — Phase 3 complete; v1.1.0 tagged.
