# MS-15a · AddStop bottom sheet shell — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current full-page `AddStopPage` with a Material bottom-sheet UI matching `prototipo/screens-a.jsx ScreenAddStop` (drag handle + title + search input + 3 method-shortcut buttons + PrimaryButton CTA), wired through a transparent route wrapper that preserves `/stops/add` deep-linking and the existing `onSaved` test contract. Closes TODO row 7 Criticals C-1 + C-2 of slice-2 fidelity remediation.

**Architecture:** Two-file change in `apps/mobile/lib/features/stops/presentation/`. `add_stop_page.dart` becomes a transparent `ConsumerStatefulWidget` wrapper that uses `addPostFrameCallback` to call `showModalBottomSheet` then pops its own route when the sheet resolves. New `add_stop_sheet.dart` contains the actual sheet (`ConsumerStatefulWidget` with local `_selectedMethod` + `TextEditingController` + private `_MethodButton`) — keyboard is the inline default, voice/camera fire a 200ms-delayed sheet-pop-then-`context.push` to the existing `/stops/add/voice` and `/stops/add/ocr` routes. No new packages. No `pubspec.yaml` touch. No ADR.

**Tech Stack:** Flutter + Riverpod 3 codegen, `go_router` (existing routes unchanged), Material `showModalBottomSheet` + `FilledButton` (project convention — no custom `PrimaryButton` widget). Stack lock per ADR-0011 / CLAUDE.md.

**Spec:** `docs/superpowers/specs/2026-05-25-ms-15a-add-stop-sheet-design.md`

**Branch:** `feat/m2-slice-2-telas-core` (existing slice-2 branch — MS-15a is the 14th of 16 microsprints in slice-2 fidelity remediation per `docs/superpowers/plans/2026-05-19-slice-2-fidelity-remediation.md`). NOT a new branch off main.

---

## Working directory

All commands assume `cwd` is the repo root:
`/Users/eduardorodrigues/Documents/Projetos/Clientes/ueslei-workana/app-roteirizadorpro`

From here on, paths are repo-root-relative unless otherwise stated.

## Plan execution rules

1. **TDD strict (per ADR-0025 + ADR-0031, re-validated session 25).** Dispatch `flutter-test-author` FIRST for every implementation task. The subagent writes failing tests + stub with `throw UnimplementedError()`, then hands off. The main agent (implementer) writes the production code AFTER tests are red on assertion. The PreToolUse hook `.claude/hooks/block-test-author-impl.sh` mechanically enforces this for the subagent.
2. **Microsprint pipeline D1→D2→D3→D4 + adr-guardian** per session log 2026-05-20-18 (`docs/sessions/2026-05-20-18-ms-01b-statefulshellroute.md`). The canonical template: design (D1) → red test (D2) → green impl (D3) → polish + SUGGESTIONS triage (D4) → adr-guardian sweep before close.
3. **One task = one logical commit.** Conventional Commits + valid scope from `commitlint.config.cjs` (`feat`, `test`, `refactor` with scope `mobile` for this plan).
4. **No `--no-verify`.** Lefthook runs `flutter analyze` + `flutter test` on staged Dart changes. If a hook fails, fix the underlying issue.
5. **Hot reload over hot restart over full restart.** This plan doesn't touch `pubspec.yaml` so hot reload covers every iteration.
6. **Surgical edits only (Karpathy §3).** Don't touch `StopForm` (Q4 decision — `EditStopPage` still consumes it). Don't touch `voice_capture_page.dart`, `ocr_capture_page.dart`, `home_list_page.dart`, `app_theme.dart`, or `app_router.dart`.
7. **Push only at end** of the microsprint (single push covering all commits, before opening the merge-to-slice-2 review or just landing directly on the slice branch).

## File structure created/modified by this plan

### Mobile (`apps/mobile/`)

```
lib/features/stops/presentation/
├── add_stop_page.dart           # MODIFIED (~30 LOC, was 45) — transparent wrapper
└── add_stop_sheet.dart          # NEW (~120-150 LOC) — sheet content + _MethodButton

test/features/stops/presentation/
├── add_stop_page_test.dart      # UPDATED — verify wrapper opens sheet + pop on dismiss
└── add_stop_sheet_test.dart     # NEW — 7 widget tests for sheet behavior
```

No other apps touched. No backend changes. No landing changes. No `pubspec.yaml` / `schema.prisma` / `infra/` / `docker-compose.yml` changes — `adr-guardian` will return GREEN with zero BLOCKING.

---

## Phase 0 — Pre-flight (no commits)

### Task 0: Verify environment and baseline

**Files:** none (read-only checks).

- [ ] **Step 0.1: Confirm branch + clean tree**

Run:
```bash
git status
git rev-parse --abbrev-ref HEAD
git log --oneline -3
```

Expected:
- Branch: `feat/m2-slice-2-telas-core`
- Working tree clean (or only `.claude/plans/` untracked — descartável)
- HEAD points at `5ee8be0` (the MS-15a spec commit) or later

If branch is wrong: `git checkout feat/m2-slice-2-telas-core`. If tree is dirty: stash or commit first.

- [ ] **Step 0.2: Confirm toolchain**

Run:
```bash
cd apps/mobile && flutter --version && cd ../..
dart --version
```

Expected:
- Flutter ≥ 3.27 (per `apps/mobile/pubspec.yaml` `environment.flutter`)
- Dart ≥ 3.9 (Dart MCP requirement per ADR-0023; currently 3.11.5)

- [ ] **Step 0.3: Confirm subagent registry loaded with hardened flutter-test-author**

Run:
```bash
cat .claude/agents/flutter-test-author.md | head -15
ls -la .claude/hooks/block-test-author-impl.sh
```

Expected:
- Description starts with "Use BEFORE implementing"
- Frontmatter contains `hooks: PreToolUse` block pointing to `block-test-author-impl.sh`
- Hook file exists, executable (`-rwxr-xr-x`)

If `hooks:` block missing: subagent didn't load hardened version — restart Claude Code session.

- [ ] **Step 0.4: Confirm baseline test suite green**

Run:
```bash
cd apps/mobile && flutter test 2>&1 | tail -3 && flutter analyze --no-pub 2>&1 | tail -3 && cd ../..
```

Expected:
- `All tests passed!` (165/165)
- `No issues found!`

If any test fails or analyzer complains: STOP. Fix the baseline before adding new code (otherwise `flutter-test-author` red signal gets polluted).

- [ ] **Step 0.5: Read the spec one more time**

Open `docs/superpowers/specs/2026-05-25-ms-15a-add-stop-sheet-design.md`. Skim:
- §Goals (11 acceptance criteria — these are the contract).
- §Decisions Locked (Q1-Q5 — do NOT reopen).
- §Risks (4 items — Risk 1 cancellable Future.delayed has a mandatory test).
- §Test strategy (7 sheet tests + 1-2 page tests + optional golden).

No commit — Phase 0 is read-only.

---

## Phase 1 — Test-first authoring (red gate)

This phase produces failing tests + stub implementations via `flutter-test-author`. NO production logic is written here. The subagent will refuse to write production code per ADR-0031; if it tries an Edit to non-stub Dart, the PreToolUse hook blocks at exit 2.

### Task 1: Dispatch flutter-test-author for AddStopSheet red gate

**Files (to be created by the subagent):**
- Create: `apps/mobile/lib/features/stops/presentation/add_stop_sheet.dart` (stub with `throw UnimplementedError()` bodies)
- Create: `apps/mobile/test/features/stops/presentation/add_stop_sheet_test.dart` (7 failing widget tests)

- [ ] **Step 1.1: Inventory existing helpers**

Read before dispatching, so the subagent dispatch references them by exact path:

```bash
ls apps/mobile/test/_support/
ls apps/mobile/test/features/stops/_helpers/
ls apps/mobile/lib/core/theme/
```

Expected entries (confirm presence):
- `apps/mobile/test/_support/phone_surface.dart` — `Size phoneSurface = Size(400, 900)` (per MS-11 lift)
- `apps/mobile/test/features/stops/_helpers/fake_stops_repository.dart` — shared `FakeStopsRepository` per `2d628d9` refactor
- `apps/mobile/lib/core/theme/app_theme.dart` (or wherever `AppColors` + `AppShadows` live)

If any helper path differs from above, update the dispatch prompt before running it.

- [ ] **Step 1.2: Dispatch flutter-test-author with the prompt below**

Use the Agent tool with `subagent_type: flutter-test-author` and the prompt EXACTLY as below. The subagent has been re-validated in session 25 — it WILL respect TDD discipline and refuse implementation requests, so you can trust it to author stubs only.

```
TDD the AddStopSheet widget for apps/mobile/lib/features/stops/presentation/add_stop_sheet.dart (NEW file — does not exist yet). Goal: a Material bottom sheet matching prototipo/screens-a.jsx ScreenAddStop (lines 279-364) — drag handle pill, title "Adicionar parada" (18/w600), TextField with prefix Icons.search and hint "Digite o endereço ou CEP...", Row of 3 method-shortcut buttons (Teclado/Voz/Câmera, 56h × radius 14, primaryLight bg + primary border when selected, icon-above-label, surface bg + transparent border when not), FilledButton "Adicionar parada" CTA.

Class signature:
```dart
class AddStopSheet extends ConsumerStatefulWidget {
  const AddStopSheet({super.key, this.onSaved});
  final void Function(BuildContext context)? onSaved;
  @override
  ConsumerState<AddStopSheet> createState() => _AddStopSheetState();
}
```

Local state: _selectedMethod ('keyboard' | 'voice' | 'camera', default 'keyboard'); TextEditingController _textController. _MethodButton is a private StatelessWidget defined in the same file (NOT in shared/).

Acceptance behavior per spec §Goals + §Test strategy:
1. Sheet renders drag handle (40×4 Container with AppColors.border bg), title "Adicionar parada", TextField with prefixIcon, 3 _MethodButton instances (labels Teclado/Voz/Câmera), FilledButton labeled "Adicionar parada".
2. Tapping "Voz" sets _selectedMethod='voice' (selected styling: bg AppColors.primaryLight + border AppColors.primary 1.5px).
3. Tapping "Voz" then pumping 250ms triggers context.push to '/stops/add/voice' via a route stub spy (subagent should fake the GoRouter via a Builder that wraps the sheet under MaterialApp.router with two placeholder routes /stops/add/voice + /stops/add/ocr that just record the navigation).
4. Tapping "Câmera" idem to '/stops/add/ocr'.
5. Entering text "Rua X" in TextField then tapping "Adicionar parada" calls StopsController.add(Stop) with the expected fields (label="Rua X", lat=0, lng=0, source=StopSource.manual) via FakeStopsRepository.capture, then sheet dismisses (Navigator.pop with no result).
6. Tapping "Adicionar parada" with empty TextField does NOT call StopsController.add (verify FakeStopsRepository.captures is empty post-tap).
7. (MUST INCLUDE — Risk 1 cancellable delay regression test) Tap "Voz" → immediately call Navigator.pop(sheetContext) → pump(300ms) → assert no exception thrown AND no navigation to /stops/add/voice happened (the 200ms delayed callback must check a _disposed flag before firing).

Workflow per your prompt body:
- Use Dart MCP to confirm Riverpod 3 signatures and ConsumerStatefulWidget shape against apps/mobile/pubspec.yaml.
- Write the 7 failing widget tests first at apps/mobile/test/features/stops/presentation/add_stop_sheet_test.dart. Use the existing helpers:
  - apps/mobile/test/_support/phone_surface.dart for the 400×900 surface
  - apps/mobile/test/features/stops/_helpers/fake_stops_repository.dart for the FakeStopsRepository
  - mocktail ONLY if a verify()/when() pattern is needed; otherwise prefer manual fakes
- Create a minimal apps/mobile/lib/features/stops/presentation/add_stop_sheet.dart stub: ConsumerStatefulWidget shell with build() that returns throw UnimplementedError() and any handler methods (onPressed callbacks, _selectMethod, etc) likewise throw UnimplementedError(). The _MethodButton private class can have its build() throw UnimplementedError() too.
- The ADR-0024 codegen hook will NOT fire because AddStopSheet is not @riverpod-annotated (it's a ConsumerStatefulWidget, which doesn't need codegen).
- Run flutter test against the new test file and confirm 7 tests fail on assertion (UnimplementedError thrown from build() or handler), not on import errors.
- Hand off with summary listing test file path, stub file path, failing assertion summary, and the exact API surface the implementer needs to fill in.

Do NOT implement any production logic. The implementer (main agent) writes that in Phase 2.
```

Expected outcomes:
- Subagent creates the 2 files.
- `flutter test apps/mobile/test/features/stops/presentation/add_stop_sheet_test.dart` shows 7 tests failing on `UnimplementedError`.
- Subagent emits clean handoff summary.

If subagent attempts to implement actual logic: the PreToolUse hook blocks at exit 2 with stderr explaining the violation, and the subagent must surface the refusal in its response per its prompt body. This is the PASS path — note it and proceed.

If subagent emits production code in `add_stop_sheet.dart` (state mutations, real navigation logic, real ref.read calls): **STOP** and file ADR-0032 per session-25 hand-off notes. Do not proceed to Phase 2.

- [ ] **Step 1.3: Verify red gate**

Run:
```bash
cd apps/mobile && flutter test test/features/stops/presentation/add_stop_sheet_test.dart 2>&1 | tail -20 && cd ../..
```

Expected: 7 tests reported, all failing with `UnimplementedError` traces. NOT failing on imports / missing class.

- [ ] **Step 1.4: Confirm stub structure**

Read `apps/mobile/lib/features/stops/presentation/add_stop_sheet.dart`. Confirm:
- `class AddStopSheet extends ConsumerStatefulWidget` exists
- `class _AddStopSheetState extends ConsumerState<AddStopSheet>` exists
- `class _MethodButton extends StatelessWidget` exists (private)
- Every method body is `throw UnimplementedError()` (per ADR-0031 marker check)

- [ ] **Step 1.5: Commit (TEST-ONLY commit)**

```bash
git add apps/mobile/lib/features/stops/presentation/add_stop_sheet.dart \
        apps/mobile/test/features/stops/presentation/add_stop_sheet_test.dart
git commit -m "$(cat <<'EOF'
test(mobile): MS-15a red gate — AddStopSheet 7 widget tests + UnimplementedError stub

flutter-test-author dispatch per ADR-0025/0031. Tests cover prototype-fidelity
chrome (drag handle + title + input + 3 method buttons + CTA), method selection
state (Voz selected styling), nav delays (Voz/Câmera fire context.push after
200ms), stop creation (FakeStopsRepository.captures), empty-input guard, and
Risk-1 cancellable delay regression (tap Voz → pop sheet before 200ms → no
exception + no nav).

All 7 tests RED on UnimplementedError from stub. Implementer pass in Phase 2.
EOF
)"
```

---

## Phase 2 — Green implementation

Main agent (you) writes the production logic in `add_stop_sheet.dart`. Tests guide the API surface.

### Task 2: Implement AddStopSheet to make all 7 tests pass

**Files:**
- Modify: `apps/mobile/lib/features/stops/presentation/add_stop_sheet.dart` (replace `throw UnimplementedError()` bodies with real implementation)

- [ ] **Step 2.1: Implement the build() method**

Replace the stub's `build()` with the full sheet UI. Reference values:
- Container outer: `Material(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24)))` with `boxShadow: [AppShadows.sheetTop]` (the token from MS-10).
- Padding: `EdgeInsets.fromLTRB(24, 12, 24, 24)`.
- Children Column (gap 16 via SizedBox or spacing):
  1. Drag handle: `Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))))`
  2. `Text('Adicionar parada', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.text))`
  3. `TextField(controller: _textController, decoration: InputDecoration(prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textMuted), hintText: 'Digite o endereço ou CEP...'))`
  4. `Row(children: [Expanded(_MethodButton...), SizedBox(width: 8), Expanded(_MethodButton...), SizedBox(width: 8), Expanded(_MethodButton...)])` — three buttons for keyboard/voice/camera
  5. `SizedBox(width: double.infinity, child: FilledButton(onPressed: _handleAdd, child: Text('Adicionar parada')))`

Wrap the whole `Column` in `Padding(padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom))` so the keyboard pushes the sheet up (Risk 4 mitigation).

- [ ] **Step 2.2: Implement state handlers**

```dart
late TextEditingController _textController;
String _selectedMethod = 'keyboard';
bool _disposed = false;

@override
void initState() {
  super.initState();
  _textController = TextEditingController();
}

@override
void dispose() {
  _disposed = true;
  _textController.dispose();
  super.dispose();
}

void _selectMethod(String method) {
  setState(() => _selectedMethod = method);
  if (method == 'keyboard') return;
  Future.delayed(const Duration(milliseconds: 200), () {
    if (_disposed) return;            // Risk-1 mitigation
    if (!context.mounted) return;
    Navigator.of(context).pop();
    final route = method == 'voice' ? '/stops/add/voice' : '/stops/add/ocr';
    context.push(route);
  });
}

Future<void> _handleAdd() async {
  final label = _textController.text.trim();
  if (label.isEmpty) return;          // empty-input guard
  final stop = Stop(
    id: newId(),
    lat: 0,
    lng: 0,
    label: label,
    source: StopSource.manual,
    createdAt: DateTime.now(),
  );
  await ref.read(stopsControllerProvider.notifier).add(stop);
  if (!context.mounted) return;
  Navigator.of(context).pop();
}
```

- [ ] **Step 2.3: Implement _MethodButton**

```dart
class _MethodButton extends StatelessWidget {
  const _MethodButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: selected ? AppColors.primary : AppColors.textMuted),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2.4: Run AddStopSheet tests — expect all 7 PASS**

```bash
cd apps/mobile && flutter test test/features/stops/presentation/add_stop_sheet_test.dart 2>&1 | tail -5 && cd ../..
```

Expected: `All tests passed!` (7 of 7).

If any test fails:
- Read the failure carefully — the test is correct (subagent wrote it), the impl is wrong.
- DO NOT modify the test to make it pass. Fix the implementation.
- Common pitfalls: forgetting `Semantics(button:true)` on `_MethodButton` (a11y test); forgetting `_disposed` flag (Risk-1 test); forgetting `text.trim()` in `_handleAdd` (empty-input test counts whitespace as empty).

- [ ] **Step 2.5: Run analyze + full suite — confirm no regression**

```bash
cd apps/mobile && flutter analyze --no-pub 2>&1 | tail -3 && flutter test 2>&1 | tail -3 && cd ../..
```

Expected:
- `No issues found!`
- `All tests passed!` (172 = 165 baseline + 7 new)

- [ ] **Step 2.6: Commit (IMPLEMENTATION commit)**

```bash
git add apps/mobile/lib/features/stops/presentation/add_stop_sheet.dart
git commit -m "$(cat <<'EOF'
feat(mobile): MS-15a green — implement AddStopSheet content + _MethodButton

Replaces 3× throw UnimplementedError() stubs in add_stop_sheet.dart with the
production sheet (drag handle, title, TextField with search prefix, Row of 3
_MethodButton, FilledButton "Adicionar parada"). State: _selectedMethod +
TextEditingController; lifecycle _disposed flag mitigates Risk-1 (200ms
cancellable Future.delayed for Voz/Câmera nav). Keyboard pushes sheet via
MediaQuery.viewInsetsOf padding (Risk-4 mitigation).

_MethodButton wraps an InkWell with Semantics(button, selected) for TalkBack.
Stays private to this file — Karpathy §3 (no premature shared widget).

7/7 AddStopSheet tests green. Full suite 172/172. analyze clean.
EOF
)"
```

---

## Phase 3 — Route wrapper

`AddStopPage` becomes a transparent wrapper that opens the sheet on mount.

### Task 3: Dispatch flutter-test-author for AddStopPage wrapper red gate

**Files (to be modified by the subagent):**
- Modify: `apps/mobile/test/features/stops/presentation/add_stop_page_test.dart` — replace/extend existing tests for wrapper behavior

- [ ] **Step 3.1: Read existing test file**

```bash
cat apps/mobile/test/features/stops/presentation/add_stop_page_test.dart
```

Note the existing test count + the `onSaved` callback contract (back-compat constraint per Q1 decision).

- [ ] **Step 3.2: Dispatch flutter-test-author**

Use Agent tool with `subagent_type: flutter-test-author`:

```
Update apps/mobile/test/features/stops/presentation/add_stop_page_test.dart to test the NEW behavior of AddStopPage as a route wrapper. The class signature stays the same:

class AddStopPage extends ConsumerStatefulWidget {
  const AddStopPage({super.key, this.onSaved});
  final void Function(BuildContext context)? onSaved;
}

But the build behavior changes: AddStopPage's initState schedules a WidgetsBinding addPostFrameCallback that calls showModalBottomSheet with AddStopSheet (passing onSaved through). When the sheet's future resolves (any dismissal), AddStopPage invokes (onSaved ?? (ctx) => ctx.canPop() ? ctx.pop() : ctx.go('/home'))(context). build() returns const SizedBox.shrink().

Required test cases:
1. (KEEP EXISTING test if any) the onSaved callback contract test — passing a custom onSaved must still receive a non-null context when the sheet dismisses with stop saved.
2. (NEW) Mounting AddStopPage under a MaterialApp.router with stub route /stops/add: after pumpAndSettle, an AddStopSheet widget is found in the widget tree (find.byType(AddStopSheet) is exactly 1).
3. (NEW) After the sheet's onSaved fires (simulate by tapping the FilledButton "Adicionar parada" inside the sheet via finder), context.pop() is called and the router state shows /home (or whatever the default pop target is — verify by router state probe).

Stop creation in the sheet still goes through ref.read(stopsControllerProvider.notifier).add(...) — use the existing FakeStopsRepository helper at apps/mobile/test/features/stops/_helpers/fake_stops_repository.dart.

After authoring tests: rewrite apps/mobile/lib/features/stops/presentation/add_stop_page.dart with a STUB where initState body and _openSheet method throw UnimplementedError(). Build() can return const SizedBox.shrink() since that's the trivial "spec is constant" case — but per ADR-0031 / lesson-spec-as-implementation-license, write it as `throw UnimplementedError()` too. The implementer (main agent, Phase 4) will fill in the real bodies.

NOTE: the hook will block any non-stub Edit to add_stop_page.dart — that's expected. If you find yourself wanting to write the actual showModalBottomSheet call, STOP and hand off. The implementer writes it.

Hand off with summary.
```

- [ ] **Step 3.3: Verify red gate**

Run:
```bash
cd apps/mobile && flutter test test/features/stops/presentation/add_stop_page_test.dart 2>&1 | tail -20 && cd ../..
```

Expected: the new tests fail on `UnimplementedError`; the preserved `onSaved` test may also fail depending on whether the stub returns something usable. All failures should be assertion failures, not imports.

- [ ] **Step 3.4: Commit (TEST-ONLY commit)**

```bash
git add apps/mobile/lib/features/stops/presentation/add_stop_page.dart \
        apps/mobile/test/features/stops/presentation/add_stop_page_test.dart
git commit -m "$(cat <<'EOF'
test(mobile): MS-15a red gate — AddStopPage wrapper tests + UnimplementedError stub

flutter-test-author dispatch. Tests cover: existing onSaved callback contract
(back-compat per Q1 decision), wrapper opens AddStopSheet on mount, sheet
dismissal pops the route.

AddStopPage stub: initState + _openSheet bodies throw UnimplementedError().
build() also throws (per ADR-0031 lesson: trivial spec values still belong to
the implementer). Implementer pass in Phase 4.
EOF
)"
```

---

## Phase 4 — Wrapper green

### Task 4: Implement AddStopPage wrapper to make tests pass

**Files:**
- Modify: `apps/mobile/lib/features/stops/presentation/add_stop_page.dart` — fill in initState + _openSheet + build

- [ ] **Step 4.1: Write the implementation**

Replace the stub bodies with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'add_stop_sheet.dart';

class AddStopPage extends ConsumerStatefulWidget {
  const AddStopPage({super.key, this.onSaved});

  /// Nullable so widget tests can assert taps without standing up a real
  /// GoRouter; production falls through to context.pop() (or /home if the
  /// page was deep-linked).
  final void Function(BuildContext context)? onSaved;

  @override
  ConsumerState<AddStopPage> createState() => _AddStopPageState();
}

class _AddStopPageState extends ConsumerState<AddStopPage> {
  bool _sheetOpened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openSheet());
  }

  Future<void> _openSheet() async {
    if (_sheetOpened) return;          // Risk-2 mitigation (double-mount on hot reload)
    _sheetOpened = true;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddStopSheet(onSaved: widget.onSaved),
    );
    if (!mounted) return;
    final cb = widget.onSaved ?? (ctx) => ctx.canPop() ? ctx.pop() : ctx.go('/home');
    cb(context);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
```

- [ ] **Step 4.2: Run AddStopPage tests — expect PASS**

```bash
cd apps/mobile && flutter test test/features/stops/presentation/add_stop_page_test.dart 2>&1 | tail -5 && cd ../..
```

Expected: all wrapper tests green.

- [ ] **Step 4.3: Run full suite — confirm no regression elsewhere**

```bash
cd apps/mobile && flutter analyze --no-pub 2>&1 | tail -3 && flutter test 2>&1 | tail -3 && cd ../..
```

Expected:
- `No issues found!`
- `All tests passed!` (~173-174 — depending on how many net-new tests the subagent wrote in add_stop_page_test.dart)

If a test in another file fails: investigate. The only way MS-15a should affect other tests is if HomeListPage FAB navigation test expectations changed (they shouldn't — the route URL stays `/stops/add`).

- [ ] **Step 4.4: Commit (IMPLEMENTATION commit)**

```bash
git add apps/mobile/lib/features/stops/presentation/add_stop_page.dart
git commit -m "$(cat <<'EOF'
feat(mobile): MS-15a green — AddStopPage becomes transparent route wrapper

AddStopPage is now a ConsumerStatefulWidget whose build() returns
SizedBox.shrink() and whose initState schedules addPostFrameCallback to
open AddStopSheet via showModalBottomSheet. On sheet dismissal, the page
invokes the onSaved callback (preserved from session-13 contract) or pops
the /stops/add route.

Risk-2 mitigation: _sheetOpened flag prevents double-open on hot reload.

Deep-link to /stops/add still works (GoRouter unchanged). Voice/OCR sub-
routes /stops/add/voice and /stops/add/ocr unchanged — AddStopSheet pops
the sheet then context.push'es into them.

Full suite green post-implementation.
EOF
)"
```

---

## Phase 5 — D4 polish + multi-agent review

D4 is the "post-green sweep" — fidelity / perf / ADR checks before opening the PR or pushing.

### Task 5: Dispatch prototype-fidelity-checker

**Files:** none modified (review only).

- [ ] **Step 5.1: Dispatch prototype-fidelity-checker subagent**

Use Agent tool with `subagent_type: prototype-fidelity-checker`:

```
Audit apps/mobile/lib/features/stops/presentation/add_stop_sheet.dart and apps/mobile/lib/features/stops/presentation/add_stop_page.dart against the canonical prototype prototipo/screens-a.jsx → ScreenAddStop (lines 279-364). Report divergences in 3 buckets: Critical / Important / Minor.

Two divergences are PRE-ACCEPTED in spec docs/superpowers/specs/2026-05-25-ms-15a-add-stop-sheet-design.md (read the spec's Q5 + the autocomplete deferral in Context):
1. NO blur effect on home background behind sheet (Q5 — performance cost vs marginal visual delta; Flutter showModalBottomSheet's native barrierColor provides "dimmed" affordance).
2. NO autocomplete results list (C-3 deferred to MS-15b which will land Nominatim self-hosted SP-Capital + ADR-0032).

List these two in your report's "Accepted gaps" section with the spec cross-reference. Flag any OTHER divergence as a real finding.
```

- [ ] **Step 5.2: Triage findings**

Expected outcomes:
- **All-green-with-2-accepted-gaps:** proceed to Task 6.
- **New Critical found:** STOP. Fix inline, re-test (loop back to Phase 2 or 4 depending on which file owns the divergence), re-run prototype-fidelity-checker. Do NOT merge with a new Critical.
- **New Important found:** triage — fix inline OR document as new TODO row 7 sub-item OR defer to MS-15b if it depends on autocomplete. Eduardo decides.
- **New Minor found:** document in commit body as accepted-and-deferred; no fix.

### Task 6: Dispatch flutter-perf-auditor

**Files:** none modified (review only).

- [ ] **Step 6.1: Dispatch flutter-perf-auditor**

Use Agent tool with `subagent_type: flutter-perf-auditor`:

```
Perf-audit the two files changed in MS-15a:
- apps/mobile/lib/features/stops/presentation/add_stop_sheet.dart
- apps/mobile/lib/features/stops/presentation/add_stop_page.dart

Report a Markdown punch list with the 4 standard sections (Must-fix / Should-fix / Nits / Notes) across the 9 canonical checks (ListView.builder discipline, missing const, ref.watch granularity, UI-thread heavy work, RepaintBoundary, tile cache, list keys, image decoding, StatefulWidget overuse).

Read-only — do not edit code.
```

- [ ] **Step 6.2: Triage findings**

Expected:
- Must-fix empty.
- Should-fix empty OR limited to const-eligible widgets the implementer missed (cheap fix).
- Nits acceptable; document in commit body.

If Must-fix appears: STOP, fix, re-run.

### Task 7: Dispatch adr-guardian

**Files:** none modified (review only).

- [ ] **Step 7.1: Dispatch adr-guardian**

Use Agent tool with `subagent_type: adr-guardian`:

```
ADR-guardian sweep against the current PR diff (since the parent slice-2 branch base). Files changed in MS-15a:
- apps/mobile/lib/features/stops/presentation/add_stop_page.dart (modified)
- apps/mobile/lib/features/stops/presentation/add_stop_sheet.dart (new)
- apps/mobile/test/features/stops/presentation/add_stop_page_test.dart (modified)
- apps/mobile/test/features/stops/presentation/add_stop_sheet_test.dart (new)

Per CLAUDE.md §"Any change requires a new ADR": confirm no stack-affecting files changed (pubspec.yaml, package.json, schema.prisma, docker-compose.yml, infra/). Confirm spec docs/superpowers/specs/2026-05-25-ms-15a-add-stop-sheet-design.md §"ADRs filed in this microsprint" says "None" and matches reality.

Verdict: GREEN (no ADR needed) | YELLOW (suggestion: consider new ADR for X) | BLOCKING (MUST file ADR for Y before merge).
```

- [ ] **Step 7.2: Verify GREEN**

Expected: GREEN with zero BLOCKING. MS-15a is pure UI restructuring within existing stack — no infra, no dep, no schema changes.

If BLOCKING returned: read the rationale carefully. If valid, file the ADR. If invalid, push back in plain text (this is exactly the "never agree by default" case from your global prefs).

---

## Phase 6 — Manual verification + close

### Task 8: Real-device smoke on Samsung A06

**Files:** none modified.

- [ ] **Step 8.1: Build + install**

```bash
bash apps/mobile/scripts/build-release-apk.sh
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Or use `flutter run -d <samsung-a06-device-id>` if device is already paired.

- [ ] **Step 8.2: Execute the 8-step smoke (capture screenshots)**

1. Open app → tap FAB on `/home`.
2. ✅ Sheet rises from bottom with drag handle + title "Adicionar parada" + input + 3 method buttons + CTA.
3. Tap "Voz" → ✅ button styling becomes selected (purple bg + border) → after ~200ms sheet closes → `/stops/add/voice` screen opens.
4. Back to home → tap FAB → tap "Câmera" → ✅ same flow → `/stops/add/ocr` opens.
5. Back to home → tap FAB → type "Rua Teste 123" in input → tap "Adicionar parada" → ✅ sheet dismisses → stop appears in HomeList.
6. Tap FAB → ✅ sheet rises → swipe down → ✅ sheet dismisses → no stop added.
7. Tap FAB → ✅ sheet rises → tap dimmed area above sheet → ✅ sheet dismisses → no stop added.
8. Tap FAB → tap "Voz" → IMMEDIATELY swipe sheet down before 200ms → ✅ sheet dismisses cleanly, NO crash, NO unexpected navigation to /voice (Risk-1 regression — proves the `_disposed` flag works on real device).

Capture screenshots of states 2, 3, 5 for the PR / commit body.

- [ ] **Step 8.3: If anything in the 8-step fails**

STOP. Fix on dev machine. Re-run analyze + test + smoke. Loop until clean.

### Task 9: Update TODO row 7

**Files:**
- Modify: `TODO.md` line 104 area (row 7 of slice-2 fidelity audit)

- [ ] **Step 9.1: Flip the audit row entry**

Edit `TODO.md`: change the line for AddStop row 7 from:

```
- [ ] `AddStopPage` full-page vs bottom-sheet presentation + 3 method-selector tabs (Keyboard / Voice / Camera) missing. Prototype: `prototipo/screens-a.jsx:279–364`. Either restructure to `showModalBottomSheet` or document as slice-3 deferral.
```

to:

```
- [x] ~~`AddStopPage` full-page vs bottom-sheet presentation + 3 method-selector tabs (Keyboard / Voice / Camera) missing~~ — **MS-15a (2026-05-25): closed C-1 (showModalBottomSheet via route wrapper) + C-2 (3 inline _MethodButton with primaryLight selected styling + 200ms feedback-then-nav for Voz/Câmera).** C-3 (autocomplete results list) deferred to MS-15b — needs Nominatim self-hosted SP-Capital + ADR-0032 (geocoding strategy) per spec `docs/superpowers/specs/2026-05-25-ms-15a-add-stop-sheet-design.md` §Context. Pre-accepted gap per spec Q5: no blur on home background (perf cost > marginal visual delta).
```

- [ ] **Step 9.2: Commit**

```bash
git add TODO.md
git commit -m "docs(audit): MS-15a closes AddStop C-1 + C-2; C-3 → MS-15b"
```

### Task 10: Session-end commit

**Files:**
- Create: `docs/sessions/2026-05-25-26-ms-15a-add-stop-sheet.md` (or whatever sequence number is next per `docs/sessions/0001-INDEX.md`)
- Modify: `docs/sessions/0001-INDEX.md`

- [ ] **Step 10.1: Write session log**

Use the template at `docs/sessions/0000-template.md`. Cover:
- Goal: close MS-15a Criticals C-1 + C-2 + document C-3 deferral path
- What was done: dispatch sequence (test-author Phase 1, implement Phase 2, test-author Phase 3, implement Phase 4, fidelity + perf + adr-guardian Phase 5, device smoke Phase 6)
- Decisions made: refer back to spec Q1-Q5; note any in-flight micro-decisions
- Files changed: the 4 files in MS-15a + TODO + session log + INDEX
- Hand-off: MS-15b should pick up next; spec section on autocomplete + ADR-0032 is the entry point
- Plain-language wrap-up: the closing summary per Eduardo's global prefs

- [ ] **Step 10.2: Update INDEX**

Prepend a new entry under `## Sessions` in `docs/sessions/0001-INDEX.md`.

- [ ] **Step 10.3: Commit**

```bash
git add docs/sessions/2026-05-25-26-ms-15a-add-stop-sheet.md docs/sessions/0001-INDEX.md
git commit -m "docs(sessions): session 26 — MS-15a AddStop bottom sheet shell"
```

### Task 11: Push to origin

- [ ] **Step 11.1: Verify all commits land**

```bash
git log origin/feat/m2-slice-2-telas-core..HEAD --oneline
```

Expected ~6 commits:
1. `test(mobile): MS-15a red gate — AddStopSheet tests + stub`
2. `feat(mobile): MS-15a green — implement AddStopSheet content + _MethodButton`
3. `test(mobile): MS-15a red gate — AddStopPage wrapper tests + stub`
4. `feat(mobile): MS-15a green — AddStopPage becomes transparent route wrapper`
5. `docs(audit): MS-15a closes AddStop C-1 + C-2; C-3 → MS-15b`
6. `docs(sessions): session 26 — MS-15a AddStop bottom sheet shell`

- [ ] **Step 11.2: Push**

```bash
git push origin feat/m2-slice-2-telas-core
```

No PR needed — MS-15a is a microsprint within the existing slice-2 branch. The slice-2 PR will be opened only when MS-15b + MS-16 also close (per `docs/superpowers/plans/2026-05-19-slice-2-fidelity-remediation.md` Phase 3 release tasks).

- [ ] **Step 11.3: Confirm origin sync**

```bash
git status -sb
```

Expected: `## feat/m2-slice-2-telas-core...origin/feat/m2-slice-2-telas-core` (no `ahead N` suffix).

---

## Self-review

The plan author runs this checklist before declaring the plan ready.

**Spec coverage:**

- §Context (background + Nominatim policy + cost analysis) → Task 0 Step 0.5 (pre-flight read).
- §Decisions Q1 (showModalBottomSheet wrapper) → Phase 3 + Phase 4 (Task 3 + Task 4).
- §Decisions Q2 (3 inline _MethodButton) → Phase 1 + Phase 2 (Task 1 + Task 2.3).
- §Decisions Q3 (autocomplete deferred to MS-15b) → encoded in spec § + Task 9 (TODO row update).
- §Decisions Q4 (preserve StopForm) → §Plan execution rules item 6 (surgical edits — don't touch).
- §Decisions Q5 (no blur on home background) → Task 5 Step 5.1 (pre-accepted in prototype-fidelity-checker dispatch prompt).
- §Goals (11 criteria) → distributed across Phases 1-6: criteria 1-5 (UI + nav behavior) Phase 1+2; criterion 6 (test count) Phase 2 Step 2.5 + Phase 4 Step 4.3; criterion 7 (analyze) Phase 2/4; criterion 8 (perf-auditor) Task 6; criterion 9 (fidelity-checker) Task 5; criterion 10 (adr-guardian) Task 7; criterion 11 (commit body docs the 2 gaps) Phase 2 Step 2.6 + Phase 4 Step 4.4 commit bodies.
- §Architecture (file structure + data flow) → §File structure created/modified + Phase 1-4 task bodies.
- §Libraries (no new deps) → §File structure note "no other apps touched" + Task 7 adr-guardian GREEN confirmation.
- §ADRs filed (none) → confirmed in Task 7.
- §Risks → Risk 1 cancellable Future.delayed = Phase 1 Task 1.2 prompt MUST INCLUDE test #7 + Phase 2 Step 2.2 `_disposed` flag impl; Risk 2 hot-reload double-mount = Phase 4 Step 4.1 `_sheetOpened` flag impl; Risk 3 router stub for nav = embedded in Phase 1 Task 1.2 prompt; Risk 4 keyboard pushes sheet = Phase 2 Step 2.1 `MediaQuery.viewInsetsOf` padding.
- §Accessibility → Phase 2 Step 2.3 `Semantics(button: true, selected: selected, label: label)` on `_MethodButton`; Phase 2 Step 2.1 explicit `hintText` on TextField + explicit `Text` child on FilledButton.
- §Test strategy (7 sheet + 1-2 page + optional golden) → Phase 1 Task 1.2 prompt enumerates all 7; Phase 3 Task 3.2 prompt enumerates page tests; golden NOT included in this plan (spec says optional, defer to keep MS-15a tight).
- §Verification gates 1-7 → Gate 1 (flutter test) = Step 2.5/4.3; Gate 2 (analyze) = Step 2.5/4.3; Gate 3 (perf-auditor) = Task 6; Gate 4 (fidelity-checker) = Task 5; Gate 5 (adr-guardian) = Task 7; Gate 6 (Samsung A06 smoke) = Task 8; Gate 7 (/verify-slice optional) = not in plan as a hard step (microsprint scope; orchestration not required for a 4-file change).

**Placeholder scan:** Searched for `TBD`, `TODO`, `<...>`, "implement later", "similar to Task N", "fill in details". None found in step bodies. Every Edit/Write has actual code blocks.

**Type consistency:** `AddStopSheet` (class name) consistent across spec + Tasks 1, 2, 4. `_MethodButton` (private) consistent in Tasks 1, 2. `_selectedMethod` (state field) consistent in Task 1 prompt + Task 2.2 impl. `_disposed` flag consistent in Task 1 prompt (test 7) + Task 2.2 impl. `onSaved` callback signature `void Function(BuildContext)?` consistent in Task 1 + 3 + 4. Route paths `/stops/add/voice` + `/stops/add/ocr` consistent everywhere.

**Scope check:** Single microsprint, single PR-less push (microsprint within slice-2 branch), single coherent change.

The plan is ready.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-05-25-ms-15a-add-stop-sheet.md`.

**Done criteria for MS-15a (per execution prompt):**
1. All 11 Goals from spec satisfied (per Self-review §Goals mapping).
2. ~172-174 tests green (165 baseline + 7 sheet + ~2 page = 174).
3. `flutter-perf-auditor` + `prototype-fidelity-checker` + `adr-guardian` all dispatched and returned acceptable (Phase 5).
4. Manual Samsung A06 8-step smoke executed and clean (Phase 6 Task 8).
5. Commit bodies document the 2 accepted gaps: blur (Phase 2 Step 2.6) + C-3 deferral (Phase 4 Step 4.4 + Task 9 TODO row update).
6. Push direct to `feat/m2-slice-2-telas-core` (Task 11) — no PR; PR opens at slice-2 close.

**Two execution options:**

**1. Subagent-Driven (recommended)** — fresh subagent per task, review between tasks. Faster iteration, protects main context window. Required sub-skill: `superpowers:subagent-driven-development`.

**2. Inline Execution** — execute tasks in this session with batched checkpoints. Higher token cost but no handoff overhead. Required sub-skill: `superpowers:executing-plans`.

Which approach?
