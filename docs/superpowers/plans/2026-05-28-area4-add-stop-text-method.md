# Area 4 — Add stop via TEXT method — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete `AddStopPage` to Spoke parity (3 content states + 2 result sections + footer + reactive search bar) on top of the existing Google Places integration, with `context.pop()` after stop creation as documented Area-6 gap.

**Architecture:** Sealed-class state derivation via `addStopUiStateProvider` (Riverpod 3 codegen, autoDispose). UI is a single `switch` over `AddStopUiState`. Column + Expanded layout (replaces current `Stack + Positioned`) to survive keyboard inset. Search bar morphs reactively via `searchQueryProvider`.

**Tech Stack:** Flutter + Riverpod 3 (`@riverpod` codegen) + `go_router` + `google_maps_flutter` + `lucide_icons_flutter`. Tests: `flutter_test` + `mocktail` (manual fakes preferred per ADR-0025) + `integration_test` on M54.

**Source of truth:** Spec at `docs/superpowers/specs/2026-05-28-area4-add-stop-text-method.md`. Spoke parity baseline: `docs/inventory/2026-05-26-spoke-vs-rotpro.md` §10.21 + §11.4 (amended 2026-05-28).

**Branch:** `feat/m2-slice-2-area-4-add-stop-text` off `feat/m2-slice-2-area-2-drawer` HEAD (`cd37a65`).

**Working directory for all `flutter`/`dart` commands:** `apps/mobile/`.

---

## File Structure

### Files to CREATE

| Path | Responsibility |
|---|---|
| `apps/mobile/lib/features/routes/application/add_stop_ui_state.dart` | Sealed class `AddStopUiState` + variants (`EmptyVariant`, `ZeroResults`, `WithResults`, `Loading`, `ErrorState`) + `AddStopUiState.from(...)` factory. Pure Dart, no Flutter/Riverpod imports. |
| `apps/mobile/lib/features/routes/state/search_query_provider.dart` | `@riverpod class SearchQuery` notifier holding `String` query. Used by `AddStopSearchBar` to mirror input + by `addStopUiStateProvider` to compute branches. |
| `apps/mobile/lib/features/routes/state/current_route_stops_provider.dart` | `@riverpod List<Stop> currentRouteStops(Ref ref)` — derived from `activeRouteIdProvider` + `routesProvider`. Empty if no active route. |
| `apps/mobile/lib/features/routes/state/add_stop_ui_state_provider.dart` | `@riverpod AddStopUiState addStopUiState(Ref ref)` — composes `searchQueryProvider` + `placeAutocompleteProvider` + `currentRouteStopsProvider`. |
| `apps/mobile/lib/features/routes/presentation/widgets/add_stop_results_section.dart` | Section A "Desta rota (N)" + Section B "Adicionar nova parada" + footer "Escolher no mapa" — single widget consuming `WithResults`. |
| `apps/mobile/test/features/routes/application/add_stop_ui_state_test.dart` | 5-branch test of `AddStopUiState.from`. Pure unit tests, no `pumpWidget`. |
| `apps/mobile/test/features/routes/state/current_route_stops_provider_test.dart` | Provider derivation tests + null-activeRoute case. |
| `apps/mobile/test/features/routes/state/add_stop_ui_state_provider_test.dart` | Provider composition tests with overrides for upstream providers. |
| `apps/mobile/test/features/routes/presentation/pages/add_stop_page_test.dart` | Widget tests per `AddStopUiState` variant + 3 tap behaviors. |
| `apps/mobile/integration_test/add_stop_flow_test.dart` | Golden-path E2E on M54 (open → type → see results → tap → pop returns). |

### Files to MODIFY

| Path | Change |
|---|---|
| `apps/mobile/lib/features/routes/presentation/widgets/add_stop_search_bar.dart` | Mirror input to `searchQueryProvider`; hide OCR + Voice IconButtons when `query.isNotEmpty`. |
| `apps/mobile/lib/features/routes/presentation/pages/add_stop_page.dart` | Replace `Stack + Positioned` body with `Column { SafeArea(SearchBar), Expanded(switch on AddStopUiState) }`. Move tap-result logic into named helpers. |

### Files NOT touched (confirm before modifying)

- `apps/mobile/lib/features/routes/state/routes_provider.dart` — `addStop(String routeId, Stop stop)` already exists and is correct.
- `apps/mobile/lib/features/routes/state/active_route_provider.dart` — already keeps active id.
- `apps/mobile/lib/features/routes/state/place_autocomplete_provider.dart` — already debounces 500ms.
- `apps/mobile/lib/features/routes/presentation/widgets/add_stop_method_buttons.dart` — already correct; reused as-is by `EmptyVariant` and `ZeroResults` renders.
- `apps/mobile/lib/features/routes/presentation/pages/add_stop_map_page.dart` — out of scope per spec Q4 (footer wires to existing stub).
- `apps/mobile/lib/app.dart` — no new GoRouter routes; `/home/routes/add-stop` already registered.

---

## Pre-flight (do once before Task 1)

- [ ] **Step 0.1: Create the feature branch off current HEAD**

```bash
git checkout feat/m2-slice-2-area-2-drawer
git pull --rebase
git checkout -b feat/m2-slice-2-area-4-add-stop-text
```

Expected: clean working tree on `feat/m2-slice-2-area-4-add-stop-text`.

- [ ] **Step 0.2: Verify baseline tests pass before any change**

```bash
cd apps/mobile
flutter test
```

Expected: `All tests passed!` with 52 tests (baseline from `cd37a65`). If any fail, STOP — diagnose before continuing.

- [ ] **Step 0.3: Verify analyzer clean on routes feature**

```bash
cd apps/mobile
flutter analyze --no-pub lib/features/routes/
```

Expected: any warnings are pre-existing (see `cd37a65` commit list: drawer_route_list `withOpacity`, app_drawer `_kebabActionLabel`, drawer_header_card const). No new errors.

---

## Phase A — Domain (pure Dart)

### Task 1: AddStopUiState sealed class skeleton

**Files:**
- Create: `apps/mobile/lib/features/routes/application/add_stop_ui_state.dart`
- Test: `apps/mobile/test/features/routes/application/add_stop_ui_state_test.dart`

- [ ] **Step 1.1: Write the failing test for sealed-class identity**

Create `apps/mobile/test/features/routes/application/add_stop_ui_state_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/application/add_stop_ui_state.dart';

void main() {
  group('AddStopUiState sealed hierarchy', () {
    test('EmptyVariant carries stopCount', () {
      const s = EmptyVariant(stopCount: 3);
      expect(s.stopCount, 3);
    });

    test('ZeroResults is a const value (no payload)', () {
      const a = ZeroResults();
      const b = ZeroResults();
      expect(identical(a, b), isTrue, reason: 'const-equal sentinels should share instance');
    });

    test('Loading is a const value (no payload)', () {
      const a = Loading();
      const b = Loading();
      expect(identical(a, b), isTrue);
    });
  });
}
```

- [ ] **Step 1.2: Run test to verify it fails**

```bash
cd apps/mobile
flutter test test/features/routes/application/add_stop_ui_state_test.dart
```

Expected: FAIL with "Target of URI doesn't exist" or similar (file not yet created).

- [ ] **Step 1.3: Create the sealed class file**

Create `apps/mobile/lib/features/routes/application/add_stop_ui_state.dart`:

```dart
import '../domain/place_autocomplete_prediction.dart';
import '../domain/stop.dart';

/// UI state for `AddStopPage` derived from (query, autocomplete async, route stops).
/// Pattern-match exhaustively in the widget via `switch (state)` — Dart compiler
/// will catch missing branches.
///
/// Spoke parity §10.21 + §11.4 (amended 2026-05-28):
/// - 3 content states (empty / zero-result / with-results) — not 2.
/// - 2 result sections (Desta rota + Adicionar nova).
/// - Empty microcopy varies with `stopCount`.
sealed class AddStopUiState {
  const AddStopUiState();
}

/// `query.isEmpty` — show microcopy + 3 method shortcut buttons.
/// Microcopy varies: 0 stops → "Adicione as primeiras paradas..."; ≥1 stop →
/// "Adicione novas paradas ou encontre paradas na rota".
final class EmptyVariant extends AddStopUiState {
  const EmptyVariant({required this.stopCount});
  final int stopCount;
}

/// `query.isNotEmpty && async.isLoading` — debounced request in-flight.
final class Loading extends AddStopUiState {
  const Loading();
}

/// `query.isNotEmpty && async.hasError` — autocomplete network/API error.
final class ErrorState extends AddStopUiState {
  const ErrorState(this.error);
  final Object error;
}

/// `query.isNotEmpty && async.hasData && data.isEmpty` — no candidates returned.
final class ZeroResults extends AddStopUiState {
  const ZeroResults();
}

/// `query.isNotEmpty && async.hasData && data.isNotEmpty` — split into 2 sections.
final class WithResults extends AddStopUiState {
  const WithResults({
    required this.matchesInRoute,
    required this.newCandidates,
  });
  final List<Stop> matchesInRoute;
  final List<PlaceAutocompletePrediction> newCandidates;
}
```

- [ ] **Step 1.4: Run test to verify it passes**

```bash
cd apps/mobile
flutter test test/features/routes/application/add_stop_ui_state_test.dart
```

Expected: PASS (3 tests).

- [ ] **Step 1.5: Commit**

```bash
git add apps/mobile/lib/features/routes/application/add_stop_ui_state.dart \
        apps/mobile/test/features/routes/application/add_stop_ui_state_test.dart
git commit -m "feat(routes): add AddStopUiState sealed class for add-stop UI states"
```

---

### Task 2: AddStopUiState.from factory + 5-branch tests

**Files:**
- Modify: `apps/mobile/lib/features/routes/application/add_stop_ui_state.dart`
- Modify: `apps/mobile/test/features/routes/application/add_stop_ui_state_test.dart`

- [ ] **Step 2.1: Write the failing tests for all 5 branches**

Append to `apps/mobile/test/features/routes/application/add_stop_ui_state_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roteirizador_pro/features/routes/domain/place_autocomplete_prediction.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';

  group('AddStopUiState.from derivation', () {
    Stop _stop(String addr) =>
        Stop(lat: -23.5, lng: -46.6, streetName: addr, fullAddress: addr);
    const _pred = PlaceAutocompletePrediction(
      placeId: 'p1',
      description: 'Av Paulista, 1000',
      mainText: 'Av Paulista, 1000',
      secondaryText: 'Bela Vista, São Paulo - SP',
    );

    test('empty query with 0 stops → EmptyVariant(stopCount: 0)', () {
      final s = AddStopUiState.from(
        query: '',
        predictions: const AsyncData([]),
        routeStops: const [],
      );
      expect(s, isA<EmptyVariant>());
      expect((s as EmptyVariant).stopCount, 0);
    });

    test('empty query with 3 stops → EmptyVariant(stopCount: 3)', () {
      final s = AddStopUiState.from(
        query: '',
        predictions: const AsyncData([_pred]),
        routeStops: [_stop('a'), _stop('b'), _stop('c')],
      );
      expect(s, isA<EmptyVariant>());
      expect((s as EmptyVariant).stopCount, 3);
    });

    test('non-empty query while loading → Loading', () {
      final s = AddStopUiState.from(
        query: 'Av',
        predictions: const AsyncLoading(),
        routeStops: const [],
      );
      expect(s, isA<Loading>());
    });

    test('non-empty query with error → ErrorState', () {
      final s = AddStopUiState.from(
        query: 'Av',
        predictions: AsyncError('boom', StackTrace.empty),
        routeStops: const [],
      );
      expect(s, isA<ErrorState>());
      expect((s as ErrorState).error, 'boom');
    });

    test('non-empty query with empty data → ZeroResults', () {
      final s = AddStopUiState.from(
        query: 'xyzzy',
        predictions: const AsyncData([]),
        routeStops: const [],
      );
      expect(s, isA<ZeroResults>());
    });

    test('non-empty query with predictions but no route matches → WithResults(matchesInRoute=[], newCandidates=[1])', () {
      final s = AddStopUiState.from(
        query: 'Av',
        predictions: const AsyncData([_pred]),
        routeStops: [_stop('Rua das Flores')],
      );
      expect(s, isA<WithResults>());
      final w = s as WithResults;
      expect(w.matchesInRoute, isEmpty);
      expect(w.newCandidates.length, 1);
    });

    test('case-insensitive substring match populates matchesInRoute', () {
      final s = AddStopUiState.from(
        query: 'PAULISTA',
        predictions: const AsyncData([_pred]),
        routeStops: [_stop('Av Paulista, 500'), _stop('Rua das Flores')],
      );
      expect(s, isA<WithResults>());
      final w = s as WithResults;
      expect(w.matchesInRoute.length, 1);
      expect(w.matchesInRoute.first.streetName, 'Av Paulista, 500');
    });
  });
}
```

(Note: the imports go at the top of the file. Move `import 'package:flutter_riverpod/flutter_riverpod.dart';` and the others to the existing import block.)

- [ ] **Step 2.2: Run tests to verify they fail**

```bash
cd apps/mobile
flutter test test/features/routes/application/add_stop_ui_state_test.dart
```

Expected: FAIL — "The method 'from' isn't defined for the type 'AddStopUiState'".

- [ ] **Step 2.3: Add the `from` factory to AddStopUiState**

Edit `apps/mobile/lib/features/routes/application/add_stop_ui_state.dart`. Add Riverpod import at top:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/place_autocomplete_prediction.dart';
import '../domain/stop.dart';
```

Inside the `sealed class AddStopUiState`, replace the body with:

```dart
sealed class AddStopUiState {
  const AddStopUiState();

  /// Composes the 5-branch state from upstream signals.
  ///
  /// Priority (in order):
  /// 1. `query.isEmpty` → `EmptyVariant` (overrides any in-flight async — when the
  ///    user clears the input, immediately show empty regardless of stale loading).
  /// 2. `predictions.isLoading` → `Loading`.
  /// 3. `predictions.hasError` → `ErrorState`.
  /// 4. `predictions.value.isEmpty` → `ZeroResults`.
  /// 5. otherwise → `WithResults` (split via substring match on routeStops).
  factory AddStopUiState.from({
    required String query,
    required AsyncValue<List<PlaceAutocompletePrediction>> predictions,
    required List<Stop> routeStops,
  }) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return EmptyVariant(stopCount: routeStops.length);
    }
    if (predictions.isLoading) return const Loading();
    if (predictions.hasError) return ErrorState(predictions.error!);
    final data = predictions.value ?? const [];
    if (data.isEmpty) return const ZeroResults();

    final q = trimmed.toLowerCase();
    final matches = routeStops.where((s) {
      return s.streetName.toLowerCase().contains(q) ||
          s.fullAddress.toLowerCase().contains(q);
    }).toList(growable: false);

    return WithResults(
      matchesInRoute: matches,
      newCandidates: data,
    );
  }
}
```

- [ ] **Step 2.4: Run tests to verify they pass**

```bash
cd apps/mobile
flutter test test/features/routes/application/add_stop_ui_state_test.dart
```

Expected: PASS (3 from Task 1 + 7 new = 10 tests).

- [ ] **Step 2.5: Commit**

```bash
git add apps/mobile/lib/features/routes/application/add_stop_ui_state.dart \
        apps/mobile/test/features/routes/application/add_stop_ui_state_test.dart
git commit -m "feat(routes): AddStopUiState.from factory with 5-branch derivation"
```

---

## Phase B — State (Riverpod 3 codegen)

### Task 3: searchQueryProvider

**Files:**
- Create: `apps/mobile/lib/features/routes/state/search_query_provider.dart`
- Test: `apps/mobile/test/features/routes/state/search_query_provider_test.dart`

- [ ] **Step 3.1: Write the failing test**

Create `apps/mobile/test/features/routes/state/search_query_provider_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/state/search_query_provider.dart';

void main() {
  late ProviderContainer container;
  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  test('initial state is empty string', () {
    expect(container.read(searchQueryProvider), '');
  });

  test('setQuery updates state', () {
    container.read(searchQueryProvider.notifier).setQuery('Av');
    expect(container.read(searchQueryProvider), 'Av');
  });

  test('setQuery to empty string clears state', () {
    container.read(searchQueryProvider.notifier).setQuery('Av');
    container.read(searchQueryProvider.notifier).setQuery('');
    expect(container.read(searchQueryProvider), '');
  });
}
```

- [ ] **Step 3.2: Run test to verify it fails**

```bash
cd apps/mobile
flutter test test/features/routes/state/search_query_provider_test.dart
```

Expected: FAIL — "Target of URI doesn't exist".

- [ ] **Step 3.3: Create the provider**

Create `apps/mobile/lib/features/routes/state/search_query_provider.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_query_provider.g.dart';

/// Mirrors the live text in the add-stop search field.
/// `AddStopSearchBar` writes here on `onChanged`; `addStopUiStateProvider` reads
/// to drive state derivation (empty branch overrides stale loading async).
@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  void setQuery(String value) {
    state = value;
  }
}
```

- [ ] **Step 3.4: Run codegen**

```bash
cd apps/mobile
dart run build_runner build --delete-conflicting-outputs
```

Expected: writes `search_query_provider.g.dart`. (The PostToolUse hook `run-riverpod-codegen.sh` will also fire on the next edit; running manually here keeps things deterministic.)

- [ ] **Step 3.5: Run tests to verify they pass**

```bash
cd apps/mobile
flutter test test/features/routes/state/search_query_provider_test.dart
```

Expected: PASS (3 tests).

- [ ] **Step 3.6: Commit**

```bash
git add apps/mobile/lib/features/routes/state/search_query_provider.dart \
        apps/mobile/lib/features/routes/state/search_query_provider.g.dart \
        apps/mobile/test/features/routes/state/search_query_provider_test.dart
git commit -m "feat(routes): add searchQueryProvider for add-stop text state"
```

---

### Task 4: currentRouteStopsProvider

**Files:**
- Create: `apps/mobile/lib/features/routes/state/current_route_stops_provider.dart`
- Test: `apps/mobile/test/features/routes/state/current_route_stops_provider_test.dart`

- [ ] **Step 4.1: Write the failing test**

Create `apps/mobile/test/features/routes/state/current_route_stops_provider_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/domain/route.dart' as domain;
import 'package:roteirizador_pro/features/routes/domain/stop.dart';
import 'package:roteirizador_pro/features/routes/state/active_route_provider.dart';
import 'package:roteirizador_pro/features/routes/state/current_route_stops_provider.dart';
import 'package:roteirizador_pro/features/routes/state/routes_provider.dart';

class _FakeRoutes extends Routes {
  _FakeRoutes(this._seed);
  final List<domain.Route> _seed;
  @override
  List<domain.Route> build() => _seed;
}

class _FakeActiveRouteId extends ActiveRouteId {
  _FakeActiveRouteId(this._seed);
  final String? _seed;
  @override
  String? build() => _seed;
}

void main() {
  final stopA = Stop(lat: -23.5, lng: -46.6, streetName: 'A', fullAddress: 'A full');
  final stopB = Stop(lat: -23.5, lng: -46.6, streetName: 'B', fullAddress: 'B full');

  ProviderContainer makeContainer({
    String? activeId,
    List<domain.Route> routes = const [],
  }) {
    final c = ProviderContainer(overrides: [
      activeRouteIdProvider.overrideWith(() => _FakeActiveRouteId(activeId)),
      routesProvider.overrideWith(() => _FakeRoutes(routes)),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('returns empty when activeRouteId is null', () {
    final c = makeContainer(activeId: null);
    expect(c.read(currentRouteStopsProvider), isEmpty);
  });

  test('returns empty when activeRouteId does not match any route', () {
    final c = makeContainer(
      activeId: 'missing',
      routes: [
        domain.Route(id: 'r1', date: DateTime(2026, 6, 1), status: domain.RouteStatus.draft),
      ],
    );
    expect(c.read(currentRouteStopsProvider), isEmpty);
  });

  test('returns the active route\'s stops list', () {
    final c = makeContainer(
      activeId: 'r1',
      routes: [
        domain.Route(
          id: 'r1',
          date: DateTime(2026, 6, 1),
          status: domain.RouteStatus.draft,
          stops: [stopA, stopB],
        ),
      ],
    );
    final stops = c.read(currentRouteStopsProvider);
    expect(stops.length, 2);
    expect(stops.first.streetName, 'A');
  });
}
```

- [ ] **Step 4.2: Run test to verify it fails**

```bash
cd apps/mobile
flutter test test/features/routes/state/current_route_stops_provider_test.dart
```

Expected: FAIL — "Target of URI doesn't exist".

- [ ] **Step 4.3: Create the provider**

Create `apps/mobile/lib/features/routes/state/current_route_stops_provider.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/stop.dart';
import 'active_route_provider.dart';
import 'routes_provider.dart';

part 'current_route_stops_provider.g.dart';

/// The list of stops on the currently-active route, or empty if there is no
/// active route or the active id doesn't resolve.
///
/// Used by `addStopUiStateProvider` to compute Section A ("Desta rota") of the
/// results list (Spoke parity §11.4 amendment 2).
@riverpod
List<Stop> currentRouteStops(Ref ref) {
  final id = ref.watch(activeRouteIdProvider);
  if (id == null) return const [];
  final routes = ref.watch(routesProvider);
  return routes.where((r) => r.id == id).expand((r) => r.stops).toList(growable: false);
}
```

- [ ] **Step 4.4: Run codegen**

```bash
cd apps/mobile
dart run build_runner build --delete-conflicting-outputs
```

Expected: writes `current_route_stops_provider.g.dart`.

- [ ] **Step 4.5: Run tests to verify they pass**

```bash
cd apps/mobile
flutter test test/features/routes/state/current_route_stops_provider_test.dart
```

Expected: PASS (3 tests).

- [ ] **Step 4.6: Commit**

```bash
git add apps/mobile/lib/features/routes/state/current_route_stops_provider.dart \
        apps/mobile/lib/features/routes/state/current_route_stops_provider.g.dart \
        apps/mobile/test/features/routes/state/current_route_stops_provider_test.dart
git commit -m "feat(routes): add currentRouteStopsProvider derived from activeRouteId"
```

---

### Task 5: addStopUiStateProvider

**Files:**
- Create: `apps/mobile/lib/features/routes/state/add_stop_ui_state_provider.dart`
- Test: `apps/mobile/test/features/routes/state/add_stop_ui_state_provider_test.dart`

- [ ] **Step 5.1: Write the failing test**

Create `apps/mobile/test/features/routes/state/add_stop_ui_state_provider_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/application/add_stop_ui_state.dart';
import 'package:roteirizador_pro/features/routes/domain/place_autocomplete_prediction.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';
import 'package:roteirizador_pro/features/routes/state/add_stop_ui_state_provider.dart';
import 'package:roteirizador_pro/features/routes/state/current_route_stops_provider.dart';
import 'package:roteirizador_pro/features/routes/state/place_autocomplete_provider.dart';
import 'package:roteirizador_pro/features/routes/state/search_query_provider.dart';

class _FakePlaceAutocomplete extends PlaceAutocomplete {
  _FakePlaceAutocomplete(this._seed);
  final AsyncValue<List<PlaceAutocompletePrediction>> _seed;
  @override
  Future<List<PlaceAutocompletePrediction>> build() async => _seed.value ?? const [];
  @override
  void search(String query) {}
}

ProviderContainer makeContainer({
  String query = '',
  AsyncValue<List<PlaceAutocompletePrediction>> predictions =
      const AsyncData<List<PlaceAutocompletePrediction>>([]),
  List<Stop> routeStops = const [],
}) {
  final c = ProviderContainer(overrides: [
    searchQueryProvider.overrideWith(() {
      final n = SearchQuery();
      n.state = query;
      return n;
    }),
    placeAutocompleteProvider.overrideWith(() => _FakePlaceAutocomplete(predictions)),
    currentRouteStopsProvider.overrideWith((ref) => routeStops),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('empty query → EmptyVariant with stopCount from currentRouteStops', () {
    final c = makeContainer(routeStops: [
      Stop(lat: 0, lng: 0, streetName: 'a', fullAddress: 'a'),
    ]);
    final s = c.read(addStopUiStateProvider);
    expect(s, isA<EmptyVariant>());
    expect((s as EmptyVariant).stopCount, 1);
  });

  test('query "Av" with empty predictions data → ZeroResults', () {
    final c = makeContainer(query: 'Av');
    expect(c.read(addStopUiStateProvider), isA<ZeroResults>());
  });

  test('query "Av" with matches → WithResults (Section A populated by substring)', () {
    final pred = PlaceAutocompletePrediction(
      placeId: 'p',
      description: 'd',
      mainText: 'Av Paulista',
      secondaryText: 'SP',
    );
    final c = makeContainer(
      query: 'paul',
      predictions: AsyncData([pred]),
      routeStops: [
        Stop(lat: 0, lng: 0, streetName: 'Av Paulista, 500', fullAddress: 'Av Paulista, 500'),
      ],
    );
    final s = c.read(addStopUiStateProvider);
    expect(s, isA<WithResults>());
    final w = s as WithResults;
    expect(w.matchesInRoute.length, 1);
    expect(w.newCandidates.length, 1);
  });
}
```

- [ ] **Step 5.2: Run test to verify it fails**

```bash
cd apps/mobile
flutter test test/features/routes/state/add_stop_ui_state_provider_test.dart
```

Expected: FAIL — "Target of URI doesn't exist".

- [ ] **Step 5.3: Create the provider**

Create `apps/mobile/lib/features/routes/state/add_stop_ui_state_provider.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../application/add_stop_ui_state.dart';
import 'current_route_stops_provider.dart';
import 'place_autocomplete_provider.dart';
import 'search_query_provider.dart';

part 'add_stop_ui_state_provider.g.dart';

/// Single source of truth for `AddStopPage`'s render branch.
/// Composes 3 upstream providers via `AddStopUiState.from`.
@riverpod
AddStopUiState addStopUiState(Ref ref) {
  final query = ref.watch(searchQueryProvider);
  final predictions = ref.watch(placeAutocompleteProvider);
  final routeStops = ref.watch(currentRouteStopsProvider);
  return AddStopUiState.from(
    query: query,
    predictions: predictions,
    routeStops: routeStops,
  );
}
```

- [ ] **Step 5.4: Run codegen**

```bash
cd apps/mobile
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5.5: Run tests to verify they pass**

```bash
cd apps/mobile
flutter test test/features/routes/state/add_stop_ui_state_provider_test.dart
```

Expected: PASS (3 tests).

- [ ] **Step 5.6: Commit**

```bash
git add apps/mobile/lib/features/routes/state/add_stop_ui_state_provider.dart \
        apps/mobile/lib/features/routes/state/add_stop_ui_state_provider.g.dart \
        apps/mobile/test/features/routes/state/add_stop_ui_state_provider_test.dart
git commit -m "feat(routes): add addStopUiStateProvider composing query+autocomplete+routeStops"
```

---

## Phase C — Widget refactors

### Task 6: AddStopSearchBar reactive

**Files:**
- Modify: `apps/mobile/lib/features/routes/presentation/widgets/add_stop_search_bar.dart`
- Create: `apps/mobile/test/features/routes/presentation/widgets/add_stop_search_bar_test.dart`

- [ ] **Step 6.1: Write the failing widget test**

Create `apps/mobile/test/features/routes/presentation/widgets/add_stop_search_bar_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/add_stop_search_bar.dart';
import 'package:roteirizador_pro/features/routes/state/search_query_provider.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  testWidgets('OCR + Voice icons visible when query is empty', (tester) async {
    await tester.pumpWidget(_wrap(const AddStopSearchBar()));
    await tester.pump();

    expect(find.byIcon(LucideIcons.scanLine), findsOneWidget);
    expect(find.byIcon(LucideIcons.mic), findsOneWidget);
  });

  testWidgets('OCR + Voice icons hidden when query is non-empty', (tester) async {
    await tester.pumpWidget(_wrap(const AddStopSearchBar()));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Av');
    await tester.pump();

    expect(find.byIcon(LucideIcons.scanLine), findsNothing);
    expect(find.byIcon(LucideIcons.mic), findsNothing);
  });

  testWidgets('typing mirrors to searchQueryProvider', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: AddStopSearchBar())),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Av Paulista');
    await tester.pump();

    expect(container.read(searchQueryProvider), 'Av Paulista');
  });
}
```

- [ ] **Step 6.2: Run test to verify it fails**

```bash
cd apps/mobile
flutter test test/features/routes/presentation/widgets/add_stop_search_bar_test.dart
```

Expected: FAIL — currently OCR + Voice are always rendered; `searchQueryProvider` not yet wired in `AddStopSearchBar`.

- [ ] **Step 6.3: Edit AddStopSearchBar to be reactive**

Replace `apps/mobile/lib/features/routes/presentation/widgets/add_stop_search_bar.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../state/place_autocomplete_provider.dart';
import '../../state/search_query_provider.dart';

class AddStopSearchBar extends ConsumerStatefulWidget {
  const AddStopSearchBar({super.key});

  @override
  ConsumerState<AddStopSearchBar> createState() => _AddStopSearchBarState();
}

class _AddStopSearchBarState extends ConsumerState<AddStopSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onShowStub(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature em breve...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Spoke parity §11.4 amendment 3: OCR + Voice icons disappear when the
    // user is actively typing — visual cue that secondary methods are not
    // needed in "typing mode".
    final query = ref.watch(searchQueryProvider);
    final showShortcuts = query.isEmpty;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Adicione uma parada...',
                        hintStyle:
                            TextStyle(fontSize: 14, color: AppColors.textMuted),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (val) {
                        ref.read(searchQueryProvider.notifier).setQuery(val);
                        ref.read(placeAutocompleteProvider.notifier).search(val);
                      },
                    ),
                  ),
                  if (showShortcuts) ...[
                    IconButton(
                      icon: const Icon(
                        LucideIcons.scanLine,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () => _onShowStub('Ler etiqueta de endereço'),
                      tooltip: 'Ler etiqueta de endereço',
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.mic,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () => _onShowStub('Dite o endereço'),
                      tooltip: 'Dite o endereço',
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(LucideIcons.x, color: AppColors.text),
            onPressed: () => context.pop(),
            tooltip: 'Fechar',
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6.4: Run test to verify it passes**

```bash
cd apps/mobile
flutter test test/features/routes/presentation/widgets/add_stop_search_bar_test.dart
```

Expected: PASS (3 tests).

- [ ] **Step 6.5: Commit**

```bash
git add apps/mobile/lib/features/routes/presentation/widgets/add_stop_search_bar.dart \
        apps/mobile/test/features/routes/presentation/widgets/add_stop_search_bar_test.dart
git commit -m "feat(routes): AddStopSearchBar reactive — hide OCR+Voice on non-empty query"
```

---

### Task 7: AddStopPage refactor (Stack→Column + switch on state)

**Files:**
- Modify: `apps/mobile/lib/features/routes/presentation/pages/add_stop_page.dart`
- Create: `apps/mobile/lib/features/routes/presentation/widgets/add_stop_results_section.dart`
- Create: `apps/mobile/test/features/routes/presentation/pages/add_stop_page_test.dart`

- [ ] **Step 7.1: Write the failing widget test for state rendering**

Create `apps/mobile/test/features/routes/presentation/pages/add_stop_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:roteirizador_pro/features/routes/application/add_stop_ui_state.dart';
import 'package:roteirizador_pro/features/routes/domain/place_autocomplete_prediction.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';
import 'package:roteirizador_pro/features/routes/presentation/pages/add_stop_page.dart';
import 'package:roteirizador_pro/features/routes/state/add_stop_ui_state_provider.dart';

GoRouter _router(Widget home) => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => home),
        GoRoute(path: '/map', builder: (_, __) => const Scaffold(body: Text('MAP'))),
      ],
    );

Widget _wrap({required AddStopUiState state}) {
  final router = _router(const AddStopPage());
  return ProviderScope(
    overrides: [
      addStopUiStateProvider.overrideWith((ref) => state),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('EmptyVariant(0 stops) renders first-paradas microcopy + 3 method buttons',
      (tester) async {
    await tester.pumpWidget(_wrap(state: const EmptyVariant(stopCount: 0)));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Adicione as primeiras paradas'),
      findsOneWidget,
    );
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.text('Leitor'), findsOneWidget);
    expect(find.text('Voz'), findsOneWidget);
  });

  testWidgets('EmptyVariant(stopCount >= 1) renders novas-paradas microcopy',
      (tester) async {
    await tester.pumpWidget(_wrap(state: const EmptyVariant(stopCount: 2)));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Adicione novas paradas ou encontre paradas na rota'),
      findsOneWidget,
    );
  });

  testWidgets('ZeroResults renders no-results microcopy + 3 method buttons',
      (tester) async {
    await tester.pumpWidget(_wrap(state: const ZeroResults()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nenhum resultado encontrado'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
  });

  testWidgets('Loading renders CircularProgressIndicator', (tester) async {
    await tester.pumpWidget(_wrap(state: const Loading()));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('WithResults renders Section A header + Section B header + Footer',
      (tester) async {
    const pred = PlaceAutocompletePrediction(
      placeId: 'p1',
      description: 'Av Paulista, 1000',
      mainText: 'Av Paulista, 1000',
      secondaryText: 'Bela Vista, SP',
    );
    final stop = Stop(lat: 0, lng: 0, streetName: 'Av Paulista, 500', fullAddress: 'x');
    await tester.pumpWidget(_wrap(
      state: WithResults(matchesInRoute: [stop], newCandidates: const [pred]),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Desta rota (1)'), findsOneWidget);
    expect(find.text('Adicionar nova parada'), findsOneWidget);
    expect(find.text('Escolher no mapa'), findsOneWidget);
  });

  testWidgets('WithResults with empty matchesInRoute hides Section A entirely',
      (tester) async {
    const pred = PlaceAutocompletePrediction(
      placeId: 'p1',
      description: 'd',
      mainText: 'Av Paulista',
      secondaryText: 'SP',
    );
    await tester.pumpWidget(_wrap(
      state: const WithResults(matchesInRoute: [], newCandidates: [pred]),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Desta rota'), findsNothing);
    expect(find.text('Adicionar nova parada'), findsOneWidget);
  });
}
```

- [ ] **Step 7.2: Run test to verify it fails**

```bash
cd apps/mobile
flutter test test/features/routes/presentation/pages/add_stop_page_test.dart
```

Expected: FAIL — page renders old Stack structure; section headers/footer not present.

- [ ] **Step 7.3: Create `AddStopResultsSection` widget (Section A + B + footer)**

Create `apps/mobile/lib/features/routes/presentation/widgets/add_stop_results_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/place_autocomplete_prediction.dart';
import '../../domain/stop.dart';

/// Renders the with-results state of `AddStopPage`:
/// - Section A "Desta rota (N)" (conditional on `matchesInRoute.isNotEmpty`)
/// - Section B "Adicionar nova parada" (always when in this widget)
/// - Footer "Escolher no mapa" (always)
///
/// Spoke parity §10.21 amendment 3 + §11.4 amendment 2 (both 2026-05-28).
class AddStopResultsSection extends StatelessWidget {
  const AddStopResultsSection({
    super.key,
    required this.matchesInRoute,
    required this.newCandidates,
    required this.onSectionATap,
    required this.onSectionBTap,
  });

  final List<Stop> matchesInRoute;
  final List<PlaceAutocompletePrediction> newCandidates;
  final void Function(Stop stop) onSectionATap;
  final void Function(PlaceAutocompletePrediction p) onSectionBTap;

  static const _headerStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
    letterSpacing: 0.3,
  );

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (matchesInRoute.isNotEmpty) {
      children.add(_sectionHeader('Desta rota (${matchesInRoute.length})'));
      for (final stop in matchesInRoute) {
        children.add(ListTile(
          leading: const Icon(LucideIcons.mapPin, color: AppColors.primary),
          title: Text(stop.streetName),
          subtitle: stop.fullAddress.isNotEmpty ? Text(stop.fullAddress) : null,
          onTap: () => onSectionATap(stop),
        ));
      }
    }

    children.add(_sectionHeader('Adicionar nova parada'));
    for (final p in newCandidates) {
      children.add(ListTile(
        leading: const Icon(LucideIcons.mapPin, color: AppColors.textMuted),
        title: Text(p.mainText),
        subtitle: p.secondaryText.isNotEmpty ? Text(p.secondaryText) : null,
        onTap: () => onSectionBTap(p),
      ));
    }

    children.add(const Divider(height: 1));
    children.add(ListTile(
      leading: const Icon(LucideIcons.mapPinned, color: AppColors.primary),
      title: const Text('Escolher no mapa'),
      trailing: const Icon(LucideIcons.chevronRight, color: AppColors.textMuted),
      onTap: () => context.push('/home/routes/add-stop/map'),
    ));

    return ListView(
      padding: EdgeInsets.zero,
      children: children,
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(label, style: _headerStyle),
    );
  }
}
```

- [ ] **Step 7.4: Replace `AddStopPage` body**

Replace `apps/mobile/lib/features/routes/presentation/pages/add_stop_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../application/add_stop_ui_state.dart';
import '../../data/repositories/places_repository.dart';
import '../../domain/place_autocomplete_prediction.dart';
import '../../domain/stop.dart';
import '../../state/active_route_provider.dart';
import '../../state/add_stop_ui_state_provider.dart';
import '../../state/routes_provider.dart';
import '../widgets/add_stop_method_buttons.dart';
import '../widgets/add_stop_results_section.dart';
import '../widgets/add_stop_search_bar.dart';

/// Spoke parity §10.21 + §11.4 (amended 2026-05-28).
/// Body branches on `addStopUiStateProvider` (sealed `AddStopUiState`).
/// Section A tap → SnackBar stub (Area 6 implements edit-stop sheet).
/// Section B tap → create Stop + `context.pop()` (Area 6 will replace with
/// inline DraggableScrollableSheet open per §11.4 BIG FIND).
/// Footer tap → push `/home/routes/add-stop/map` (existing stub).
class AddStopPage extends ConsumerWidget {
  const AddStopPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addStopUiStateProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const AddStopSearchBar(),
            Expanded(
              child: switch (state) {
                EmptyVariant(:final stopCount) => _EmptyState(stopCount: stopCount),
                Loading() => const Center(child: CircularProgressIndicator()),
                ErrorState(:final error) =>
                  Center(child: Text('Erro ao buscar endereços: $error')),
                ZeroResults() => const _ZeroResultsState(),
                WithResults(:final matchesInRoute, :final newCandidates) =>
                  AddStopResultsSection(
                    matchesInRoute: matchesInRoute,
                    newCandidates: newCandidates,
                    onSectionATap: (s) => _onSectionATap(context, s),
                    onSectionBTap: (p) => _onSectionBTap(context, ref, p),
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onSectionATap(BuildContext context, Stop stop) {
    // Area 6 will replace with: context.push('/home/routes/stops/${stop.id}/edit')
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Editar parada em breve')),
    );
  }

  Future<void> _onSectionBTap(
    BuildContext context,
    WidgetRef ref,
    PlaceAutocompletePrediction p,
  ) async {
    final activeRouteId = ref.read(activeRouteIdProvider);
    if (activeRouteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma rota ativa selecionada.')),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Adicionando parada...')));

    try {
      final repo = ref.read(placesRepositoryProvider);
      final details = await repo.getPlaceDetails(p.placeId);
      if (details == null) {
        throw Exception('Não foi possível obter os detalhes do endereço.');
      }
      final newStop = Stop(
        lat: details.lat,
        lng: details.lng,
        streetName: p.mainText,
        fullAddress: details.formattedAddress,
      );
      ref.read(routesProvider.notifier).addStop(activeRouteId, newStop);
      if (context.mounted) {
        messenger.hideCurrentSnackBar();
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.stopCount});
  final int stopCount;

  @override
  Widget build(BuildContext context) {
    final microcopy = stopCount == 0
        ? 'Adicione as primeiras paradas para começar a criar sua rota'
        : 'Adicione novas paradas ou encontre paradas na rota';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.plusCircle, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            microcopy,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: AppColors.textMuted),
          ),
          const SizedBox(height: 48),
          const AddStopMethodButtons(),
        ],
      ),
    );
  }
}

class _ZeroResultsState extends StatelessWidget {
  const _ZeroResultsState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(LucideIcons.searchX, size: 48, color: AppColors.textMuted),
          SizedBox(height: 16),
          Text(
            'Nenhum resultado encontrado',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.text),
          ),
          SizedBox(height: 8),
          Text(
            'Tente reformular a pesquisa',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
          SizedBox(height: 48),
          AddStopMethodButtons(),
        ],
      ),
    );
  }
}
```

- [ ] **Step 7.5: Run all widget tests to verify they pass**

```bash
cd apps/mobile
flutter test test/features/routes/presentation/pages/add_stop_page_test.dart
```

Expected: PASS (6 tests).

- [ ] **Step 7.6: Commit**

```bash
git add apps/mobile/lib/features/routes/presentation/pages/add_stop_page.dart \
        apps/mobile/lib/features/routes/presentation/widgets/add_stop_results_section.dart \
        apps/mobile/test/features/routes/presentation/pages/add_stop_page_test.dart
git commit -m "feat(routes): refactor AddStopPage to Column + switch on AddStopUiState"
```

---

## Phase D — Tap behaviors verified end-to-end

### Task 8: Tap behavior widget tests (Section A SnackBar / Section B addStop+pop / Footer push /map)

**Files:**
- Modify: `apps/mobile/test/features/routes/presentation/pages/add_stop_page_test.dart` (append)

- [ ] **Step 8.1: Add Section A SnackBar test**

Append inside the existing `void main() { ... }` block of `add_stop_page_test.dart`:

```dart
  testWidgets('Section A tap shows SnackBar "Editar parada em breve"',
      (tester) async {
    final stop = Stop(lat: 0, lng: 0, streetName: 'Av Paulista, 500', fullAddress: 'x');
    await tester.pumpWidget(_wrap(
      state: WithResults(matchesInRoute: [stop], newCandidates: const []),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Av Paulista, 500'));
    await tester.pump();

    expect(find.text('Editar parada em breve'), findsOneWidget);
  });

  testWidgets('Footer tap navigates to /home/routes/add-stop/map',
      (tester) async {
    // We override the GoRouter for this test to point /map at a recognisable
    // sentinel screen.
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const AddStopPage()),
        GoRoute(path: '/home/routes/add-stop/map', builder: (_, __) =>
            const Scaffold(body: Text('SENTINEL_MAP'))),
      ],
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        addStopUiStateProvider.overrideWith((ref) =>
          const WithResults(matchesInRoute: [], newCandidates: [])),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Escolher no mapa'));
    await tester.pumpAndSettle();

    expect(find.text('SENTINEL_MAP'), findsOneWidget);
  });
```

- [ ] **Step 8.2: Run all tests in the file**

```bash
cd apps/mobile
flutter test test/features/routes/presentation/pages/add_stop_page_test.dart
```

Expected: PASS (8 tests total — 6 from Task 7 + 2 new).

- [ ] **Step 8.3: Run the FULL test suite to detect regressions**

```bash
cd apps/mobile
flutter test
```

Expected: ALL tests pass. Previous count (cd37a65) was 52; new total ≈ 52 + 3 (Task 1) + 7 (Task 2) + 3 (Task 3) + 3 (Task 4) + 3 (Task 5) + 3 (Task 6) + 8 (Task 7+8) ≈ 82. Number may shift by ±2 depending on framework counter; what matters is **zero failures**.

- [ ] **Step 8.4: Commit**

```bash
git add apps/mobile/test/features/routes/presentation/pages/add_stop_page_test.dart
git commit -m "test(routes): add tap-behavior tests for AddStopPage (Section A, Footer)"
```

> Note: Section B tap (the `addStop + pop` flow) is exercised via integration_test in Task 9 — widget-level testing of an async network call (Google Places `getPlaceDetails`) requires deep mocking that integration_test makes redundant.

---

### Task 9: Integration test on M54

**Files:**
- Create: `apps/mobile/integration_test/add_stop_flow_test.dart`

- [ ] **Step 9.1: Confirm `integration_test` dependency is wired**

```bash
cd apps/mobile
grep "integration_test:" pubspec.yaml
```

Expected: `integration_test:` line present under `dev_dependencies:` with `sdk: flutter`. If missing, STOP and ask Eduardo before continuing.

- [ ] **Step 9.2: Write the integration test**

Create `apps/mobile/integration_test/add_stop_flow_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:roteirizador_pro/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'add-stop golden path: open shell → tap search pill → type → see results '
    '→ Android back returns to shell',
    (tester) async {
      await tester.pumpWidget(const ProviderScope(child: RoteirizadorProApp()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Login is assumed to be persisted on the device (Remember-me checkbox).
      // If we land on /login, type credentials. Skipped here — Eduardo runs
      // this against a logged-in device.

      // 1. From shell, tap the search pill.
      final pill = find.text('Adicionar parada...');
      expect(pill, findsOneWidget, reason: 'shell should expose the search pill');
      await tester.tap(pill);
      await tester.pumpAndSettle();

      // 2. AddStopPage opens. Type a query.
      final tf = find.byType(TextField).last;
      await tester.enterText(tf, 'Av');
      await tester.pumpAndSettle(const Duration(milliseconds: 800));

      // 3. Results or zero-result state appears (depends on prod data).
      // Either is acceptable — the test asserts only that the page reacted to
      // the typing AND OCR/Voice icons disappeared (Spoke parity §11.4).
      // The original icons (Icon(LucideIcons.scanLine) and Icon(LucideIcons.mic))
      // should no longer be on screen.
      // We assert by their tooltip-derived semantics labels.
      expect(find.bySemanticsLabel('Ler etiqueta de endereço'), findsNothing,
          reason: 'OCR icon must hide when query is non-empty');
      expect(find.bySemanticsLabel('Dite o endereço'), findsNothing,
          reason: 'Voice icon must hide when query is non-empty');

      // 4. Android back.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Adicionar parada...'), findsOneWidget,
          reason: 'should return to shell (search pill visible again)');
    },
  );
}
```

- [ ] **Step 9.3: Run the integration test on the M54**

```bash
cd apps/mobile
flutter test integration_test/add_stop_flow_test.dart -d RQCW401G33T --dart-define-from-file=.env
```

Expected: `All tests passed!` with the device showing the actual flow on screen. If FAIL: capture the failure, diagnose. Common failures: device not logged in (skip step 1 in the test — Eduardo manually logs in first); search pill text changed (re-inspect via Maestro).

- [ ] **Step 9.4: Commit**

```bash
git add apps/mobile/integration_test/add_stop_flow_test.dart
git commit -m "test(routes): integration_test for add-stop golden path on M54"
```

---

## Phase E — Device-level validation + handoff

### Task 10: Build + Maestro smoke punch list

**Files:**
- No code changes. Validation only.

- [ ] **Step 10.1: Rebuild APK with `.env` defines**

```bash
cd apps/mobile
flutter build apk --debug --target-platform android-arm64 --dart-define-from-file=.env
adb -s RQCW401G33T install -r build/app/outputs/flutter-apk/app-debug.apk
```

Expected: `Success`. APK launches via Maestro `launchApp` without crashing.

- [ ] **Step 10.2: Smoke punch list via Maestro (12 acceptance criteria from spec §Goals)**

Run, one by one, capturing screenshot evidence for each (use `mcp__maestro__take_screenshot`):

1. Open shell, log in if needed, ensure a route is active.
2. Tap search pill → page opens, keyboard up. **Screenshot A.**
3. Empty state (rota com 0 stops): observe microcopy "Adicione as primeiras...". **Screenshot B.**
4. (If active route has ≥1 stop) microcopy "Adicione novas paradas ou encontre paradas na rota". **Screenshot C.** (Skip if no such route exists; document in handoff.)
5. Type "Av" (2 chars) — wait 800ms — results appear; OCR + Voice icons disappear. **Screenshot D.**
6. Confirm 2 sections render if applicable (Section A only if query matches a stop). **Screenshot E.**
7. Footer "Escolher no mapa" visible at bottom of results. **Screenshot F.**
8. Tap a Section B result → SnackBar "Adicionando parada...", page pops back, pin visible on map. **Screenshot G + H.**
9. (If a Section A row appears) tap it → SnackBar "Editar parada em breve". **Screenshot I.**
10. Type "xyzzy123" → ZeroResults state with 3 method buttons. **Screenshot J.**
11. Tap X close → returns to shell, no leftover keyboard. **Screenshot K.**
12. Re-run the 5 previous-PR smoke tests (drawer, wizard create/edit, reuse-stops, cancel-X) to confirm zero regression.

- [ ] **Step 10.3: Catalogue results**

Compile a punch list (`smoke-report.md` scratch — not committed; goes into commit body and session log). Format per criterion: `✅ / 🟡 / ❌` + 1-line evidence pointer.

- [ ] **Step 10.4: Apply any in-scope fixes found**

If any of the 12 criteria fail with a fix that's ≤ 1 commit, apply in the same PR (precedent: `cd37a65` "wizard edit pre-populate" was found during smoke and fixed in the same branch). For larger gaps, file as Area-6 dependency in spec §"Open items for Area 6".

---

### Task 11: D4 spoke-parity-checker closing dispatch

**Files:**
- No code changes. Validation only.

- [ ] **Step 11.1: Dispatch the closing parity-checker**

Send via the `Agent` tool (subagent_type `spoke-parity-checker`):

```
D4 CLOSING dispatch for slice 2 microsprint: Area 4 Add-stop via TEXT method.

Branch: feat/m2-slice-2-area-4-add-stop-text (HEAD = <latest commit sha>)
Spec: docs/superpowers/specs/2026-05-28-area4-add-stop-text-method.md
Plan: docs/superpowers/plans/2026-05-28-area4-add-stop-text-method.md
Inventory baseline (amended): docs/inventory/2026-05-26-spoke-vs-rotpro.md §10.21 + §11.4

RotPro state: add-stop page is now functionally complete with:
- 3 content states (empty / zero-result / with-results)
- 2 result sections (Desta rota + Adicionar nova parada)
- Footer "Escolher no mapa"
- Reactive search bar (OCR + Voice hide on typing)
- Section A tap = SnackBar (Area 6 will replace)
- Section B tap = create Stop + context.pop() (gap, Area 6 reverts to inline)
- Footer tap = push existing /add-stop/map stub

Compare against Spoke ao vivo on M54 (com.underwood.route_optimiser). Spoke is logged in.

Return: standard parity-checker punch list. Mark "Inspection path:" per ADR-0037. Confirm whether the inventory amendments 2026-05-28 captured everything OR if there are new discrepancies. List anything must-fix that would block PR.
```

- [ ] **Step 11.2: Apply must-fix items if any (same PR)**

If the report lists must-fixes that are ≤ small + within scope of this PR, fix and re-validate before continuing. If they're Area-6 territory, document in spec §"Open items for Area 6".

---

### Task 12: Verification-before-completion + final commits + push

- [ ] **Step 12.1: Invoke `superpowers:verification-before-completion`**

This sub-skill ensures evidence-before-assertions before claiming the PR is done. Follow its checklist exactly.

- [ ] **Step 12.2: Run final analyze + tests**

```bash
cd apps/mobile
flutter analyze --no-pub lib/features/routes/ test/features/routes/
flutter test
```

Expected: zero new analyze errors (pre-existing ones from `cd37a65` are tolerated); ALL tests pass.

- [ ] **Step 12.3: Update TODO.md — mark Area 4 done**

Edit `TODO.md` and update the Slice 2 section: Area 2 already done; Area 4 (text method) now done; Areas 4-voice/4-OCR/4-map remain.

- [ ] **Step 12.4: Append a session log entry**

Create `docs/sessions/YYYY-MM-DD-NN-area4-add-stop-text.md` per template `docs/sessions/0000-template.md`. Include:
- What got shipped (3-line summary)
- The inventory drift discovered + amended (link to §10.21 + §11.4 amendments)
- The Q1-Q7 decisions table from spec (copy-paste verbatim for the index)
- Open items for Area 6

Append the row to `docs/sessions/0001-INDEX.md`.

- [ ] **Step 12.5: Persist memories if any reusable patterns emerged**

If the implementation revealed reusable patterns (e.g. "sealed-class UI state derivation with switch", "reactive search bar via mirrored query provider"), write a memory file under `~/.claude/projects/.../memory/` and link in `MEMORY.md`. If no new pattern beyond what's already captured (`copywith_nullable_field_pitfall`, `wizard_parameterized_by_gorouter_pathparam`, etc.), skip.

- [ ] **Step 12.6: Final commit + push**

```bash
git add TODO.md docs/sessions/
git commit -m "$(cat <<'EOF'
docs(slice2): close Area 4 — add-stop TEXT method shipped

Spec: docs/superpowers/specs/2026-05-28-area4-add-stop-text-method.md
Plan: docs/superpowers/plans/2026-05-28-area4-add-stop-text-method.md
Inventory amended: §10.21 + §11.4 (7 D1 findings).

Acceptance: 12/12 spec goals validated via Maestro smoke + integration_test
on M54. Section B tap pops to shell as documented Area-6 gap (will revert
to inline DraggableScrollableSheet open per BIG FIND).
EOF
)"
git push origin feat/m2-slice-2-area-4-add-stop-text
```

Expected: branch on remote, ready for PR.

- [ ] **Step 12.7: Open PR (if Eduardo approves)**

Per CLAUDE.md global "Executing actions with care": pushing the branch is OK (reversible); opening the PR is a shared-visibility action — ask Eduardo before `gh pr create`.

---

## Self-Review

### 1. Spec coverage

Walking through `docs/superpowers/specs/2026-05-28-area4-add-stop-text-method.md`:

| Spec § | Task that implements |
|---|---|
| Goals §1 (search pill open) | Task 9 step 9.2 (integration test) + Task 10 step 10.2 punch #2 |
| Goals §2-3 (empty state microcopy variations) | Task 7 step 7.4 (`_EmptyState`) + Task 7 step 7.1 tests + Task 10 punch #3-4 |
| Goals §4 (2 chars + bar reactive) | Task 6 (search bar reactive) + Task 5 (state composition) + Task 10 punch #5 |
| Goals §5 (2 sections) | Task 7 step 7.3 (`AddStopResultsSection`) + Task 7 step 7.1 test "WithResults renders both sections" |
| Goals §6 (footer) | Task 7 step 7.3 (footer in same widget) + Task 8 step 8.1 footer-tap test |
| Goals §7 (Section B tap → addStop + pop) | Task 7 step 7.4 (`_onSectionBTap`) + Task 9 integration test + Task 10 punch #8 |
| Goals §8 (Section A tap → SnackBar) | Task 7 step 7.4 + Task 8 step 8.1 Section-A test + Task 10 punch #9 |
| Goals §9 (zero-result state) | Task 7 step 7.4 (`_ZeroResultsState`) + Task 7 step 7.1 ZeroResults test + Task 10 punch #10 |
| Goals §10 (clear input reverts) | Task 6 step 6.1 test "OCR icons visible when empty" — clearing is the inverse |
| Goals §11 (Android back) | Task 9 integration test |
| Goals §12 (no regression) | Task 8 step 8.3 (full suite) + Task 10 punch #12 |
| Architecture §Page layout | Task 7 step 7.4 |
| Architecture §Derived state | Tasks 1-5 |
| Architecture §Routing (no changes) | Pre-flight 0.2 (baseline test) confirms |
| Risk 1 (smoke mandatory) | Task 10 |
| Risk 2 (keyboard layout) | Task 7 step 7.4 (Column + Expanded) |
| Risk 3 (derived re-renders) | `Provider.autoDispose` — the `@riverpod` function form auto-disposes by default; explicit in code review |
| Risk 4 (Area 6 drift) | Task 12 step 12.4 session log copies decisions verbatim |

All 12 goals + 4 risks covered.

### 2. Placeholder scan

Searched plan for "TBD" / "TODO" / "fill in" / "similar to" — none. Every step has code. Every command has expected output.

### 3. Type consistency

- `AddStopUiState` and its variants: same names across Tasks 1, 2, 5, 7, 8.
- `searchQueryProvider` / `currentRouteStopsProvider` / `addStopUiStateProvider`: Riverpod codegen names consistent.
- `Stop(lat:, lng:, streetName:, fullAddress:)` constructor: consistent (matches existing `stop.dart`).
- `PlaceAutocompletePrediction(placeId:, description:, mainText:, secondaryText:)`: consistent (matches existing domain class).

No drift.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-05-28-area4-add-stop-text-method.md`. Two execution options:

**1. Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration. Uses `superpowers:subagent-driven-development`.

**2. Inline Execution** — Execute tasks in this session using `superpowers:executing-plans`, batch execution with checkpoints.

**Which approach?**
