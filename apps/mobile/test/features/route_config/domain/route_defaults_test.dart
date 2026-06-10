import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/route_config/domain/route_config.dart';
import 'package:roteirizador_pro/features/route_config/domain/route_defaults.dart';

void main() {
  group('RouteDefaults.empty()', () {
    test('has firstRoute=true and all sub-defaults null/empty', () {
      final d = RouteDefaults.empty();
      expect(d.schemaVersion, 1);
      expect(d.firstRoute, isTrue);
      expect(d.startLocation, isNull);
      expect(d.timeStart, isNull);
      expect(d.timeEnd, isNull);
      expect(d.destination, isNull);
      expect(d.breaks, isEmpty);
    });
  });

  group('JSON roundtrip', () {
    test('empty() roundtrip', () {
      final original = RouteDefaults.empty();
      final restored = RouteDefaults.fromJson(original.toJson());
      expect(restored, original);
    });

    test('fully-filled with NoDestination destination roundtrip', () {
      const original = RouteDefaults(
        firstRoute: false,
        startLocation: StartLocation(
          address: 'R Augusta, 100',
          lat: -23.5,
          lng: -46.6,
          isUserCurrentLocation: false,
        ),
        timeStart: TimeStart(time: TimeOfDay(hour: 8, minute: 0)),
        timeEnd: TimeEnd(time: TimeOfDay(hour: 18, minute: 30)),
        destination: NoDestination(),
        breaks: [
          BreakConfig(
            fromTime: TimeOfDay(hour: 8, minute: 0),
            toTime: TimeOfDay(hour: 15, minute: 0),
            durationMinutes: 30,
          ),
        ],
      );
      final restored = RouteDefaults.fromJson(original.toJson());
      expect(restored, original);
    });

    test('NoDestination destination roundtrip', () {
      final original = RouteDefaults.empty().copyWith(
        destination: const NoDestination(),
      );
      final restored = RouteDefaults.fromJson(original.toJson());
      expect(restored.destination, const NoDestination());
    });

    test('SpecificAddress destination roundtrip', () {
      final original = RouteDefaults.empty().copyWith(
        destination: const SpecificAddress(
          address: 'Av Paulista, 1000',
          lat: -23.56,
          lng: -46.65,
        ),
      );
      final restored = RouteDefaults.fromJson(original.toJson());
      expect(
        restored.destination,
        const SpecificAddress(
          address: 'Av Paulista, 1000',
          lat: -23.56,
          lng: -46.65,
        ),
      );
    });

    test('RoundTrip destination roundtrip', () {
      final original = RouteDefaults.empty().copyWith(
        destination: const RoundTrip(),
      );
      final restored = RouteDefaults.fromJson(original.toJson());
      expect(restored.destination, const RoundTrip());
    });

    test('multiple breaks preserve order', () {
      final original = RouteDefaults.empty().copyWith(
        breaks: const [
          BreakConfig(
            fromTime: TimeOfDay(hour: 8, minute: 0),
            toTime: TimeOfDay(hour: 11, minute: 0),
            durationMinutes: 15,
          ),
          BreakConfig(
            fromTime: TimeOfDay(hour: 12, minute: 0),
            toTime: TimeOfDay(hour: 15, minute: 30),
            durationMinutes: 60,
          ),
        ],
      );
      final restored = RouteDefaults.fromJson(original.toJson());
      expect(restored.breaks.length, 2);
      expect(restored.breaks[0].durationMinutes, 15);
      expect(restored.breaks[1].durationMinutes, 60);
      // Window endpoints survive the round-trip (ADR-0044).
      expect(restored.breaks[0].fromTime, const TimeOfDay(hour: 8, minute: 0));
      expect(restored.breaks[1].toTime, const TimeOfDay(hour: 15, minute: 30));
    });
  });

  group('fromJson fallback to empty()', () {
    test('missing schemaVersion → empty()', () {
      final restored = RouteDefaults.fromJson({'firstRoute': false});
      expect(restored, RouteDefaults.empty());
    });

    test('schemaVersion 2 (forward incompat) → empty()', () {
      final restored = RouteDefaults.fromJson({
        'schemaVersion': 2,
        'firstRoute': false,
      });
      expect(restored, RouteDefaults.empty());
    });

    test('schemaVersion wrong type → empty()', () {
      final restored = RouteDefaults.fromJson({
        'schemaVersion': 'one',
        'firstRoute': false,
      });
      expect(restored, RouteDefaults.empty());
    });

    test('firstRoute wrong type → empty()', () {
      final restored = RouteDefaults.fromJson({
        'schemaVersion': 1,
        'firstRoute': 'yes',
      });
      expect(restored, RouteDefaults.empty());
    });

    test('corrupted timeStart string → empty()', () {
      final restored = RouteDefaults.fromJson({
        'schemaVersion': 1,
        'firstRoute': true,
        'timeStart': 'not-a-time',
      });
      expect(restored, RouteDefaults.empty());
    });

    test('unknown destination type → empty()', () {
      final restored = RouteDefaults.fromJson({
        'schemaVersion': 1,
        'firstRoute': true,
        'destination': {'type': 'teleport'},
      });
      expect(restored, RouteDefaults.empty());
    });

    test('legacy backToStart tag (removed per ADR-0043) → empty()', () {
      // BackToStart was dropped from the domain in MS5. A hand-edited or
      // corrupted envelope carrying the old tag is no longer a known type,
      // so it falls through the unknown-type arm and degrades to empty().
      final restored = RouteDefaults.fromJson({
        'schemaVersion': 1,
        'firstRoute': true,
        'destination': {'type': 'backToStart'},
      });
      expect(restored, RouteDefaults.empty());
    });

    test('legacy break shape {startTime} (pre-ADR-0044) → empty()', () {
      // ADR-0044 changed the break entry from {startTime, durationMinutes} to
      // {fromTime, toTime, durationMinutes}. A pre-change envelope is missing
      // fromTime/toTime, so _breaksFromJson's shape guard throws and the whole
      // envelope degrades to empty() (with a debugPrint, anti-pattern #11) —
      // it must NOT silently accept or mis-parse the old shape. This guards the
      // shape check at route_defaults.dart so a future refactor can't quietly
      // start swallowing legacy data.
      final restored = RouteDefaults.fromJson({
        'schemaVersion': 1,
        'firstRoute': true,
        'breaks': [
          {'startTime': '08:00', 'durationMinutes': 30},
        ],
      });
      expect(restored, RouteDefaults.empty());
    });
  });

  group('copyWith semantics', () {
    test('copyWith with no args returns equal instance', () {
      final d = RouteDefaults.empty();
      expect(d.copyWith(), d);
    });

    test('copyWith flips firstRoute', () {
      final d = RouteDefaults.empty();
      expect(d.copyWith(firstRoute: false).firstRoute, isFalse);
      expect(d.firstRoute, isTrue); // original untouched
    });

    test(
        '_omit sentinel: copyWith(startLocation: null) CLEARS, '
        'copyWith() PRESERVES (pins the clear-path merge() cannot reach)', () {
      const populated = RouteDefaults(
        startLocation: StartLocation(
          address: 'Av Paulista, 1000',
          lat: -23.561,
          lng: -46.656,
          isUserCurrentLocation: false,
        ),
      );

      // Explicit null clears the field (sentinel distinguishes omit vs null).
      expect(populated.copyWith(startLocation: null).startLocation, isNull);
      // Omitting the arg preserves it.
      expect(populated.copyWith().startLocation, isNotNull);
    });
  });
}
