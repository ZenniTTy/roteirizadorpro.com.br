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
}
