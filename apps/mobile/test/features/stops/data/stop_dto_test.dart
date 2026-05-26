import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/stops/data/dto/stop_dto.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';

void main() {
  group('StopDto', () {
    test('fromJson reads lat, lng and optional label', () {
      final dto = StopDto.fromJson({'lat': -23.5, 'lng': -46.6, 'label': 'X'});
      expect(dto.lat, -23.5);
      expect(dto.lng, -46.6);
      expect(dto.label, 'X');
    });

    test('fromJson tolerates a missing label', () {
      final dto = StopDto.fromJson({'lat': 0, 'lng': 0});
      expect(dto.label, isNull);
    });

    test('toJson includes label when present', () {
      const dto = StopDto(lat: 1, lng: 2, label: 'Y');
      expect(dto.toJson(), {'lat': 1.0, 'lng': 2.0, 'label': 'Y'});
    });

    test('toJson omits label when null', () {
      const dto = StopDto(lat: 1, lng: 2);
      expect(dto.toJson(), {'lat': 1.0, 'lng': 2.0});
    });

    test('Stop.toDto drops id/source/createdAt', () {
      final s = Stop(
        id: 'abc',
        lat: 10,
        lng: 20,
        label: 'Z',
        source: StopSource.voice,
        createdAt: DateTime.utc(2026, 5, 13),
      );
      final dto = s.toDto();
      expect(dto.toJson(), {'lat': 10.0, 'lng': 20.0, 'label': 'Z'});
    });

    test('Stop.fromDto injects a fresh id, manual source and now() timestamp',
        () {
      const dto = StopDto(lat: 1, lng: 2, label: 'L');
      final s = Stop.fromDto(dto, id: 'fresh', now: DateTime.utc(2026, 5, 13));
      expect(s.id, 'fresh');
      expect(s.source, StopSource.manual);
      expect(s.createdAt, DateTime.utc(2026, 5, 13));
      expect(s.lat, 1);
      expect(s.lng, 2);
      expect(s.label, 'L');
    });
  });
}
