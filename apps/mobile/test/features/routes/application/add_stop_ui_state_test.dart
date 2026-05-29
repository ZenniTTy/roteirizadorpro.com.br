import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/application/add_stop_ui_state.dart';
import 'package:roteirizador_pro/features/routes/domain/place_autocomplete_prediction.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';

void main() {
  group('AddStopUiState sealed hierarchy', () {
    test('EmptyVariant carries stopCount', () {
      const s = EmptyVariant(stopCount: 3);
      expect(s.stopCount, 3);
    });

    test('ZeroResults is a const value (no payload)', () {
      const a = ZeroResults();
      const b = ZeroResults();
      expect(
        identical(a, b),
        isTrue,
        reason: 'const-equal sentinels should share instance',
      );
    });

    test('Loading is a const value (no payload)', () {
      const a = Loading();
      const b = Loading();
      expect(
        identical(a, b),
        isTrue,
        reason: 'const-equal sentinels should share instance',
      );
    });

    test('WithResults carries both result sections independently', () {
      const prediction = PlaceAutocompletePrediction(
        placeId: 'p1',
        description: 'd',
        mainText: 'm',
        secondaryText: 's',
      );
      final stop = Stop(lat: 0, lng: 0, streetName: 's', fullAddress: 'a');
      final s =
          WithResults(matchesInRoute: [stop], newCandidates: [prediction]);
      expect(s.matchesInRoute, [stop]);
      expect(s.newCandidates, [prediction]);
    });

    test('ErrorState exposes error payload', () {
      final err = Exception('boom');
      final s = ErrorState(err);
      expect(s.error, err);
    });
  });

  group('AddStopUiState.from derivation', () {
    Stop stop(String addr) =>
        Stop(lat: -23.5, lng: -46.6, streetName: addr, fullAddress: addr);
    const pred = PlaceAutocompletePrediction(
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
        predictions: const AsyncData([pred]),
        routeStops: [stop('a'), stop('b'), stop('c')],
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
        predictions: const AsyncError('boom', StackTrace.empty),
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

    test(
      'non-empty query with predictions but no route matches → WithResults(matchesInRoute=[], newCandidates=[1])',
      () {
        final s = AddStopUiState.from(
          query: 'Av',
          predictions: const AsyncData([pred]),
          routeStops: [stop('Rua das Flores')],
        );
        expect(s, isA<WithResults>());
        final w = s as WithResults;
        expect(w.matchesInRoute, isEmpty);
        expect(w.newCandidates.length, 1);
      },
    );

    test('case-insensitive substring match populates matchesInRoute', () {
      final s = AddStopUiState.from(
        query: 'PAULISTA',
        predictions: const AsyncData([pred]),
        routeStops: [stop('Av Paulista, 500'), stop('Rua das Flores')],
      );
      expect(s, isA<WithResults>());
      final w = s as WithResults;
      expect(w.matchesInRoute.length, 1);
      expect(w.matchesInRoute.first.streetName, 'Av Paulista, 500');
    });
  });
}
