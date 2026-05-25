# Spec — MS-15a · AddStop bottom sheet shell (UI only, no autocomplete)

> **Date:** 2026-05-25
> **Author:** Claude Code (with Eduardo)
> **Status:** Awaiting user review before invoking `writing-plans`
> **Branch:** `feat/m2-slice-2-telas-core` (already open; ahead of `origin/develop` by slice-2's accumulated commits; sub-microsprint of slice 2)
> **Source of truth:** `docs/08-ROADMAP.md` "Slice 2 — Telas Core" + `docs/superpowers/specs/2026-05-19-slice-2-fidelity-remediation-design.md` (slice-2 fidelity remediation parent spec). MS-15a is the 14th of 16 microsprints in that remediation. If this spec disagrees with either, the parent spec wins for fidelity remediation rules and the ROADMAP wins for scope ordering.

---

## Context

The AddStop screen in the current implementation (`apps/mobile/lib/features/stops/presentation/add_stop_page.dart`, 45 lines) is a plain full-page `Scaffold + AppBar + StopForm` that diverges sharply from the canonical UI source `prototipo/screens-a.jsx ScreenAddStop` (lines 279-364). The prototype is a bottom sheet over a dimmed home screen, with a drag-handle pill, title "Adicionar parada", a search input, three method-shortcut buttons (Teclado / Voz / Câmera), an autocomplete results list (4 mock items in the prototype mockup), and a primary "Adicionar parada" CTA.

`TODO.md` line 104 records this as Critical row 7 of the slice-2 fidelity audit: **C-1 (presentation: bottom-sheet vs full-page) + C-2 (3 method-selector tabs missing) + C-3 (results list absent)**. MS-15a closes C-1 and C-2 with the new shell. C-3 (the autocomplete results list) is **deferred to MS-15b** because the brainstorming session uncovered two hard constraints that make autocomplete-in-MS-15 impossible:

1. **OSMF Nominatim Usage Policy** (`https://operations.osmfoundation.org/policies/nominatim/`) explicitly states: *"Auto-complete search is not yet supported by Nominatim and you must not implement such a service on top of our service."* This blocks the obvious "hit the public Nominatim endpoint with debounced /search calls" approach.
2. **Self-hosted Nominatim costs:** the official recommendation (`mediagis/nominatim-docker`) is **20 GB RAM** for production, which on DigitalOcean translates to ~R$ 1,000–1,400/month — 5–7× over the M2 cost ceiling of BRL 200/month (`docs/M2-COST-MODEL.md`). A scoped-down **SP-Capital-only** instance fits in ~4 GB RAM (~R$ 120/month droplet), which aligns with the existing **SP-only on M1; Sudeste post-M1** decision in `docs/decisions/0015-m2-plan.md`. That setup is the right scope for autocomplete but is **infrastructure work in its own right** — droplet resize, Docker setup, `osmium extract --bbox` from the 805 MB Sudeste PBF, new ADR-0032 (geocoding strategy), secrets management for the server URL, OSM attribution surface. Splitting it from the UI shell keeps each PR auditable.

MS-15a therefore ships the **shell** (sheet presentation + 3 method buttons + free-text input + existing sentinel-stop creation behavior). MS-15b (the next microsprint) ships the **autocomplete integration** against a fresh Nominatim self-hosted SP-Capital instance.

## Decisions locked in this brainstorming session

| # | Question | Decision | Rationale |
|---|---|---|---|
| Q1 | Presentation: `showModalBottomSheet` OR full-page `Scaffold` styled to look like a sheet? | **`showModalBottomSheet` via route wrapper.** The route `/stops/add` keeps existing; the page becomes a transparent `addPostFrameCallback` wrapper that opens the sheet and pops the route when the sheet closes. | 1:1 prototype fidelity (native drag handle, swipe-down dismiss, native dimmed barrier). Preserves deep-linking + existing GoRouter wiring. Compatible with ADR-0022 StatefulShellRoute (sheet is overlay on home branch, never leaves the branch). Rejected alternative: have `HomeListPage` FAB bypass GoRouter and call `showModalBottomSheet` directly — would break deep-linking to `/stops/add`, break 3+ existing widget tests that pump `AddStopPage` via `MaterialApp.router`, and force a `HomeListPage` refactor. |
| Q2 | Method selector: 3 buttons inline OR `TabBar`? | **3 buttons inline (`_MethodButton` private widget).** Card-style buttons 56h × radius 14, `primaryLight` bg + `primary` border when selected, icon-above-label. Selecting Voice/Câmera triggers `Future.delayed(200ms)` then sheet-pop + `context.push('/stops/add/voice'\|'/stops/add/ocr')`. | Prototype's behavior is "Keyboard is the inline default; Voice and Câmera are shortcuts to other screens" — a `TabBar` would mislead users into expecting content-swap. The 200ms feedback delay mirrors prototype's `setTimeout(200)` pattern. `_MethodButton` stays private to `add_stop_sheet.dart` until a second consumer materializes (Karpathy §3 — no premature shared widgets). |
| Q3 | Autocomplete results list (the 4 mock items in prototype + first-highlighted style): stub now / skip / defer to slice 3 / build real? | **Defer to MS-15b** (next microsprint, scope = setup Nominatim self-hosted SP-Capital + integrate autocomplete + ADR-0032). | OSMF policy bans autocomplete-against-public-Nominatim; self-hosted full-Brazil busts the cost ceiling 5×; self-hosted SP-Capital fits the ceiling but is infrastructure work that warrants its own microsprint + ADR + PR. Stubbing 4 hardcoded mocks ("theater") was rejected because Spoke parity is the project's North Star (CLAUDE.md "What This Project Is") — the cliente would see a behavior that disappears when real autocomplete lands. Skipping silently was rejected because the audit row C-3 explicitly tracks it. Deferring with a named follow-up microsprint is the honest middle. |
| Q4 | Should `StopForm` widget be removed/inlined since `AddStopSheet` no longer uses it? | **No — preserve `StopForm` as-is.** `EditStopPage` still consumes it. Touching `StopForm` would expand MS-15a scope beyond what's necessary. Karpathy §3 ("Surgical Changes — touch only what you must"). | Removing `StopForm` from the consumer chain of `AddStopPage` is a side effect of the rewrite, not the goal. Leaving it for `EditStopPage` keeps the diff minimal and avoids a refactor that would have to be re-justified. |
| Q5 | Visual fidelity of "dimmed-blur home background" (prototype uses `filter: blur(2px)` + opacity 0.4 over the home content)? | **Accept Flutter's native `barrierColor` dimming; do NOT implement a blur effect on the home screen behind the sheet.** | `showModalBottomSheet` provides a darkened scrim (`Colors.black54` default) which gives the "dimmed" affordance. Implementing the prototype's CSS-style blur would require either `BackdropFilter(ImageFilter.blur)` (expensive — GPU-heavy on the Samsung A06 target device) or a screenshot-then-blur trick (complex + brittle). The visual delta is marginal; the perf cost is not. Documented as accepted gap in the commit body. |

## Goals (acceptance for this microsprint)

MS-15a is **closed** when all of the following hold:

1. Tapping the home FAB opens a bottom sheet matching `prototipo/screens-a.jsx ScreenAddStop` for: drag-handle pill, title "Adicionar parada" (18/w600), search input with prefix icon, row of 3 method buttons (Teclado/Voz/Câmera) with correct selected/unselected styling, PrimaryButton "Adicionar parada".
2. Tapping the "Voz" method button navigates to `/stops/add/voice` after a 200ms visual-feedback delay; tapping "Câmera" navigates to `/stops/add/ocr` analogously.
3. Tapping "Adicionar parada" with non-empty input creates a `Stop` via `StopsController.add` (sentinel `lat:0, lng:0` — unchanged from current behavior) and dismisses the sheet, popping back to `/home`.
4. Swipe-down on the sheet OR tap on the dimmed area dismisses the sheet and pops back to `/home` without creating a stop.
5. The route `/stops/add` continues to deep-link correctly (e.g. browser back/forward works the same as before).
6. `flutter test` suite is green: ~172-174 tests (was 165 pre-MS-15a; +7 new tests in `add_stop_sheet_test.dart` + 1-2 net-new in `add_stop_page_test.dart` for the wrapper open/dismiss behavior, others updated in-place).
7. `flutter analyze --no-pub` clean.
8. `flutter-perf-auditor` dispatch against `add_stop_sheet.dart` returns no Must-fix / Should-fix items (Nits acceptable, documented).
9. `prototype-fidelity-checker` dispatch against `screens-a.jsx → ScreenAddStop` returns at most one accepted-gap entry (the C-3 autocomplete list, with explicit reference to MS-15b).
10. `adr-guardian` dispatch returns GREEN with zero BLOCKING (MS-15a does not touch `pubspec.yaml` / `package.json` / `schema.prisma` / `infra/` / `docker-compose.yml`).
11. Commit body documents the two accepted gaps (Q5 blur deferral; C-3 autocomplete → MS-15b) so the next reader sees them without diff archaeology.

## Architecture

```
apps/mobile/lib/features/stops/presentation/
├── add_stop_page.dart          # MODIFIED — becomes route wrapper (~30 LOC, was 45)
│                               #   - ConsumerStatefulWidget
│                               #   - initState schedules WidgetsBinding.addPostFrameCallback(_openSheet)
│                               #   - build() returns const SizedBox.shrink()
│                               #   - _openSheet awaits showModalBottomSheet → on resolve, context.pop()
│                               #   - preserves optional `onSaved` param for test contract back-compat
│
└── add_stop_sheet.dart         # NEW — the actual sheet content (~120-150 LOC)
                                #   - ConsumerStatefulWidget
                                #   - local state: _selectedMethod ('keyboard'|'voice'|'camera'),
                                #     TextEditingController for the input
                                #   - build returns Material > Container(top-rounded, sheetTop shadow)
                                #     with: drag-handle pill, title, TextField (prefix Icons.search),
                                #     Row of 3 _MethodButton, PrimaryButton
                                #   - _MethodButton private inside this file (NOT shared/) per Karpathy §3
                                #   - Voice/Camera tap: setState(selected) → Future.delayed(200) →
                                #     Navigator.pop(sheetContext) → context.push('/stops/add/voice'|'/ocr')
                                #   - "Adicionar parada" tap: validate non-empty → StopsController.add
                                #     with sentinel lat:0, lng:0 → Navigator.pop(sheetContext)

apps/mobile/test/features/stops/presentation/
├── add_stop_page_test.dart     # UPDATED — verify wrapper opens sheet on mount, pop on dismiss
└── add_stop_sheet_test.dart    # NEW — 5+ widget tests for sheet behavior (see Test Strategy)
```

**Routing (unchanged):**

- `/stops/add` → `AddStopPage` (now the wrapper)
- `/stops/add/voice` → `VoiceCapturePage` (exists)
- `/stops/add/ocr` → `OcrCapturePage` (exists)

**Data flow:**

1. `HomeListPage` FAB onPressed → `context.push('/stops/add')` (unchanged from session 13).
2. GoRouter mounts `AddStopPage` → `initState` schedules `_openSheet` for next frame.
3. `_openSheet` awaits `showModalBottomSheet<void>(isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => AddStopSheet(onSaved: widget.onSaved))`.
4. Inside the sheet, user interacts:
   - **"Adicionar parada":** `ref.read(stopsControllerProvider.notifier).add(Stop(...))` (current sentinel behavior); `Navigator.pop(sheetContext)`.
   - **Voice/Camera:** `setState(_selectedMethod = ...)` for visual feedback; `Future.delayed(200ms, () { Navigator.pop(sheetContext); ctx.push('/stops/add/voice'|'/stops/add/ocr'); })`.
   - **Swipe-down / barrier tap:** sheet dismisses natively; future resolves with `null`.
5. Back in `AddStopPage._openSheet`: `if (context.mounted) (widget.onSaved ?? (ctx) => ctx.canPop() ? ctx.pop() : ctx.go('/home'))(context);` — preserves the existing onSaved-callback test contract verbatim.

## Libraries / dependencies

**None new.** All implementation uses existing packages: `flutter_riverpod`, `flutter`, `go_router`, plus the project's own `app_theme.dart` tokens (`AppColors.primary`, `AppColors.primaryLight`, `AppColors.surface`, `AppColors.border`, `AppShadows.sheetTop`) and Material `FilledButton` as the primary CTA (matches the existing convention in `voice_capture_page.dart:128` + `edit_stop_page.dart:107` — there is no custom `PrimaryButton` widget in the codebase, and inventing one in MS-15a violates Karpathy §3). No `pubspec.yaml` touch → no ADR-guardian BLOCKING.

## ADRs filed in this microsprint

**None.** MS-15a is pure UI restructuring within existing stack. MS-15b will file ADR-0032 (Nominatim self-hosted SP-Capital geocoding strategy).

## Risks

1. **The 200ms delay on Voice/Camera taps must be cancellable.** If the user taps Voice then immediately taps Cancel-on-sheet (swipe-down), the `Future.delayed` callback could fire after the sheet has popped, attempting `Navigator.pop(sheetContext)` on a defunct context. Mitigation: capture a `bool _disposed = false` flag in the sheet state, set in `dispose()`, check inside the delayed callback before any nav. Test: pump → tap Voice → immediately swipe-down → pump(300ms) → assert no exceptions + correct route state.
2. **Hot reload during sheet-open may double-mount the sheet.** `addPostFrameCallback` fires on first build only by design, but hot-reload semantics for `initState` are subtle. Mitigation: guard `_openSheet` with `bool _sheetOpened = false` flag. Test deferred to manual smoke (hot-reload is dev-time concern).
3. **Test wrapping is non-trivial:** widget tests need a real `Navigator` for `showModalBottomSheet` to work. Existing test helpers in `apps/mobile/test/_support/phone_surface.dart` already pump a `MaterialApp` — extend by ensuring tests wrap `AddStopPage` in a `MaterialApp.router` with a router stub that includes both `/stops/add` and `/stops/add/voice`+`/ocr` placeholder routes for nav assertions.
4. **Sheet height vs keyboard:** when user focuses the TextField, the on-screen keyboard pushes the sheet. `isScrollControlled: true` + the sheet's intrinsic height should handle this; verify with `tester.pumpWidget` and a manual `FocusScope` toggle in tests.

## Accessibility

- TextField has `decoration.hintText: 'Digite o endereço ou CEP...'` — readable by TalkBack.
- Each `_MethodButton` exposes a `Semantics(button: true, selected: _selected, label: opt.label)` wrapper.
- PrimaryButton has explicit `Text('Adicionar parada')` (no icon-only buttons).
- Drag handle is decorative (visual affordance only); native `showModalBottomSheet` provides the gesture announcement.

## Test strategy

`flutter-test-author` is dispatched first per ADR-0025/0031. Expected categories:

**Widget tests in `add_stop_sheet_test.dart` (NEW):**

1. Sheet renders all chrome: drag handle (find by Key or Container with width 40 height 4), title text 'Adicionar parada', TextField, 3 _MethodButton instances (find by ancestor + label), PrimaryButton 'Adicionar parada'.
2. Tapping "Voz" button toggles selected styling (verify via golden OR find Container with `primaryLight` bg).
3. Tapping "Voz" then `tester.pump(Duration(milliseconds: 250))` triggers navigation to `/stops/add/voice` (verify via router stub spy).
4. Tapping "Câmera" idem to `/stops/add/ocr`.
5. Entering text + tapping "Adicionar parada" calls `StopsController.add` (verify via `FakeStopsRepository` capture) with `lat: 0, lng: 0` and `source: StopSource.manual`, then sheet dismisses.
6. Tapping PrimaryButton with empty text does NOT call `add` (existing form-validation behavior — verify with `FakeStopsRepository.captures.isEmpty`).
7. (Risk-1 regression) Tap Voice → swipe-down before 200ms → pump(300ms) → no exception thrown, no nav happens.

**Widget tests in `add_stop_page_test.dart` (UPDATED):**

1. Mounting `AddStopPage` after first frame opens the sheet (find `AddStopSheet` widget).
2. Dismissing the sheet (programmatic `Navigator.pop`) causes `context.pop()` on the route (verify via router spy that current location is `/home`).
3. Existing `onSaved` callback test contract still passes verbatim (preserves back-compat for slice-2 sub-2a Task 15 tests).

**Optional golden (ADR-0029):** baseline `add_stop_sheet_keyboard.png` of the sheet in keyboard-selected default state, 400×900 surface. Recommended for a critical screen; pixel-flip gate validated during baseline creation. Skipped if it expands MS-15a beyond 1.5 days of work.

Target: suite goes from 165 → ~170 green.

## Verification gates (pre-PR)

In execution order:

1. `cd apps/mobile && flutter test` → all green.
2. `cd apps/mobile && flutter analyze --no-pub` → "No issues found".
3. Dispatch `flutter-perf-auditor` against `apps/mobile/lib/features/stops/presentation/add_stop_sheet.dart` + `add_stop_page.dart`. Expected: Must-fix empty, Should-fix empty, Nits OK if documented.
4. Dispatch `prototype-fidelity-checker` against `prototipo/screens-a.jsx → ScreenAddStop`. Expected: zero unaccepted divergences; the autocomplete-list gap (C-3) and blur-background gap (Q5) appear in the "Accepted gaps" section with justification + cross-ref (C-3 → MS-15b; Q5 → perf rationale).
5. Dispatch `adr-guardian` against the changed files. Expected: GREEN, zero BLOCKING (no infra/dep changes).
6. Manual smoke on Samsung A06 device: tap FAB → sheet rises → tap Voice → /voice route opens; back → tap Câmera → /ocr opens; back → type address + tap Adicionar parada → stop appears in HomeList; tap FAB → swipe-down sheet → no stop added.
7. `/verify-slice` skill for full orchestration (optional but recommended for any Critical-closing microsprint).

## References

- `prototipo/screens-a.jsx` lines 279-364 (canonical UI — ScreenAddStop).
- `apps/mobile/lib/features/stops/presentation/add_stop_page.dart` (current 45-line file being replaced).
- `apps/mobile/lib/features/stops/presentation/voice_capture_page.dart` + `ocr_capture_page.dart` (downstream navigation targets, untouched).
- `apps/mobile/test/_support/phone_surface.dart` (test surface helper, reused).
- `docs/decisions/0015-m2-plan.md` (SP-only on M1 stance — informs why MS-15b's Nominatim scope is SP-Capital).
- `docs/decisions/0017-external-nav.md` (external nav model — informs the 200ms feedback-then-navigate pattern).
- `docs/decisions/0022-stateful-shell-route.md` (branch semantics — informs why sheet is overlay-not-route).
- `docs/decisions/0025-flutter-test-author-subagent.md` + `docs/decisions/0031-flutter-test-author-refusal-hardening.md` (test-first dispatch pattern, validated session 25).
- `docs/decisions/0027-flutter-perf-auditor-subagent.md` (perf gate dispatch).
- `docs/decisions/0029-alchemist-golden-tests.md` (optional golden baseline pattern).
- `docs/sessions/2026-05-20-18-ms-01b-statefulshellroute.md` (microsprint D1→D4 pipeline canonical template).
- `docs/M2-SLICE-CHECKLIST.md` (the gates this spec satisfies — §Verification).
- `docs/M2-COST-MODEL.md` (cost ceiling that informed the MS-15a/MS-15b split).
- `https://operations.osmfoundation.org/policies/nominatim/` (OSMF policy that motivated the C-3 deferral).
- `https://github.com/mediagis/nominatim-docker` (Nominatim Docker image — MS-15b will use `mediagis/nominatim:5.3`).
- `https://download.geofabrik.de/south-america/brazil/sudeste.html` (805 MB Sudeste PBF source — MS-15b will `osmium extract --bbox` SP-Capital from this).
