import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/route_config/state/picker_mode.dart';
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
  Future<List<PlaceAutocompletePrediction>> build(PickerMode mode) async =>
      _seed.value ?? const [];
  @override
  void search(String query) {}
}

class _FakeSearchQuery extends SearchQuery {
  _FakeSearchQuery(this._seed);
  final String _seed;
  @override
  String build(PickerMode mode) => _seed;
}

ProviderContainer makeContainer({
  PickerMode mode = PickerMode.addStop,
  String query = '',
  AsyncValue<List<PlaceAutocompletePrediction>> predictions =
      const AsyncData<List<PlaceAutocompletePrediction>>([]),
  List<Stop> routeStops = const [],
}) {
  final c = ProviderContainer(
    overrides: [
      searchQueryProvider(mode).overrideWith(() => _FakeSearchQuery(query)),
      placeAutocompleteProvider(mode)
          .overrideWith(() => _FakePlaceAutocomplete(predictions)),
      currentRouteStopsProvider.overrideWith((ref) => routeStops),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('empty query → EmptyVariant with stopCount from currentRouteStops', () {
    final c = makeContainer(
      routeStops: [
        Stop(lat: 0, lng: 0, streetName: 'a', fullAddress: 'a'),
      ],
    );
    final s = c.read(addStopUiStateProvider(PickerMode.addStop));
    expect(s, isA<EmptyVariant>());
    expect((s as EmptyVariant).stopCount, 1);
  });

  test('query "Av" with empty predictions data → ZeroResults', () async {
    final c = makeContainer(query: 'Av');
    await c.read(placeAutocompleteProvider(PickerMode.addStop).future);
    expect(
      c.read(addStopUiStateProvider(PickerMode.addStop)),
      isA<ZeroResults>(),
    );
  });

  test(
      'query "Av" with matches → WithResults (Section A populated by substring)',
      () async {
    const pred = PlaceAutocompletePrediction(
      placeId: 'p',
      description: 'd',
      mainText: 'Av Paulista',
      secondaryText: 'SP',
    );
    final c = makeContainer(
      query: 'paul',
      predictions: const AsyncData([pred]),
      routeStops: [
        Stop(
          lat: 0,
          lng: 0,
          streetName: 'Av Paulista, 500',
          fullAddress: 'Av Paulista, 500',
        ),
      ],
    );
    await c.read(placeAutocompleteProvider(PickerMode.addStop).future);
    final s = c.read(addStopUiStateProvider(PickerMode.addStop));
    expect(s, isA<WithResults>());
    final w = s as WithResults;
    expect(w.matchesInRoute.length, 1);
    expect(w.newCandidates.length, 1);
  });

  // Regression: MS3 cleanup 2026-06-02 — startLocation and addStop modes
  // derive separate `AddStopUiState`s from their own family-keyed inputs.
  test('startLocation mode reads its own typed text + predictions', () async {
    const predStart = PlaceAutocompletePrediction(
      placeId: 'ps',
      description: 'd',
      mainText: 'Av Brigadeiro',
      secondaryText: 'SP',
    );
    final c = ProviderContainer(
      overrides: [
        searchQueryProvider(PickerMode.startLocation)
            .overrideWith(() => _FakeSearchQuery('brig')),
        placeAutocompleteProvider(PickerMode.startLocation).overrideWith(
          () => _FakePlaceAutocomplete(const AsyncData([predStart])),
        ),
        // addStop intentionally untouched — empty query + empty predictions.
        currentRouteStopsProvider.overrideWith((ref) => const []),
      ],
    );
    addTearDown(c.dispose);
    await c.read(placeAutocompleteProvider(PickerMode.startLocation).future);

    final startState = c.read(addStopUiStateProvider(PickerMode.startLocation));
    final addStopState = c.read(addStopUiStateProvider(PickerMode.addStop));
    expect(startState, isA<WithResults>());
    expect(addStopState, isA<EmptyVariant>());
  });
}
