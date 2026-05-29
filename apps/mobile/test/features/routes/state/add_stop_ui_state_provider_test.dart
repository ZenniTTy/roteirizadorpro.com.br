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
  Future<List<PlaceAutocompletePrediction>> build() async =>
      _seed.value ?? const [];
  @override
  void search(String query) {}
}

class _FakeSearchQuery extends SearchQuery {
  _FakeSearchQuery(this._seed);
  final String _seed;
  @override
  String build() => _seed;
}

ProviderContainer makeContainer({
  String query = '',
  AsyncValue<List<PlaceAutocompletePrediction>> predictions =
      const AsyncData<List<PlaceAutocompletePrediction>>([]),
  List<Stop> routeStops = const [],
}) {
  final c = ProviderContainer(
    overrides: [
      searchQueryProvider.overrideWith(() => _FakeSearchQuery(query)),
      placeAutocompleteProvider
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
    final s = c.read(addStopUiStateProvider);
    expect(s, isA<EmptyVariant>());
    expect((s as EmptyVariant).stopCount, 1);
  });

  test('query "Av" with empty predictions data → ZeroResults', () async {
    final c = makeContainer(query: 'Av');
    await c.read(placeAutocompleteProvider.future);
    expect(c.read(addStopUiStateProvider), isA<ZeroResults>());
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
            fullAddress: 'Av Paulista, 500'),
      ],
    );
    await c.read(placeAutocompleteProvider.future);
    final s = c.read(addStopUiStateProvider);
    expect(s, isA<WithResults>());
    final w = s as WithResults;
    expect(w.matchesInRoute.length, 1);
    expect(w.newCandidates.length, 1);
  });
}
