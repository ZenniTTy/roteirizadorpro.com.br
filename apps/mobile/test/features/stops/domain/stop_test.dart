import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';

void main() {
  group('Stop', () {
    final createdAt = DateTime.utc(2026, 5, 13, 12, 0, 0);

    test('constructor preserves all fields', () {
      final s = Stop(
        id: 'abc-123',
        lat: -23.55,
        lng: -46.63,
        label: 'Av. Paulista',
        source: StopSource.mapTap,
        createdAt: createdAt,
      );

      expect(s.id, 'abc-123');
      expect(s.lat, -23.55);
      expect(s.lng, -46.63);
      expect(s.label, 'Av. Paulista');
      expect(s.source, StopSource.mapTap);
      expect(s.createdAt, createdAt);
    });

    test('copyWith overrides only the given fields', () {
      final original = Stop(
        id: 'abc',
        lat: 0,
        lng: 0,
        label: 'origin',
        source: StopSource.manual,
        createdAt: createdAt,
      );

      final updated = original.copyWith(lat: 10, lng: 20, label: 'moved');

      expect(updated.id, 'abc');
      expect(updated.lat, 10);
      expect(updated.lng, 20);
      expect(updated.label, 'moved');
      expect(updated.source, StopSource.manual);
      expect(updated.createdAt, createdAt);
    });

    test('equality is value-based on all fields', () {
      final a = Stop(
        id: '1',
        lat: 1,
        lng: 2,
        label: 'x',
        source: StopSource.voice,
        createdAt: createdAt,
      );
      final b = Stop(
        id: '1',
        lat: 1,
        lng: 2,
        label: 'x',
        source: StopSource.voice,
        createdAt: createdAt,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('toJson and fromJson roundtrip preserves all fields including source',
        () {
      final original = Stop(
        id: 'abc',
        lat: -23.55,
        lng: -46.63,
        label: 'Av. Paulista',
        source: StopSource.ocr,
        createdAt: createdAt,
      );

      final json = original.toJson();
      final restored = Stop.fromJson(json);

      expect(restored, equals(original));
    });

    test('toJson omits a null label', () {
      final original = Stop(
        id: 'abc',
        lat: 0,
        lng: 0,
        label: null,
        source: StopSource.manual,
        createdAt: createdAt,
      );
      final json = original.toJson();

      expect(json.containsKey('label'), isFalse);
    });
  });
}
