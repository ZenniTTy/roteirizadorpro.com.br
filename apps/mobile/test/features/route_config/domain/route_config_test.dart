import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/route_config/domain/route_config.dart';

void main() {
  group('StartLocation', () {
    test('equality + props', () {
      const a = StartLocation(
        address: 'R Augusta, 100',
        lat: -23.5,
        lng: -46.6,
        isUserCurrentLocation: false,
      );
      const b = StartLocation(
        address: 'R Augusta, 100',
        lat: -23.5,
        lng: -46.6,
        isUserCurrentLocation: false,
      );
      const c = StartLocation(
        address: 'R Augusta, 100',
        lat: -23.5,
        lng: -46.6,
        isUserCurrentLocation: true,
      );
      expect(a, b);
      expect(a, isNot(c));
    });
  });

  group('TimeStart / TimeEnd', () {
    test('equality compares wrapped TimeOfDay', () {
      const t1 = TimeStart(time: TimeOfDay(hour: 8, minute: 0));
      const t2 = TimeStart(time: TimeOfDay(hour: 8, minute: 0));
      const t3 = TimeStart(time: TimeOfDay(hour: 9, minute: 0));
      expect(t1, t2);
      expect(t1, isNot(t3));

      const e1 = TimeEnd(time: TimeOfDay(hour: 18, minute: 0));
      const e2 = TimeEnd(time: TimeOfDay(hour: 18, minute: 0));
      expect(e1, e2);
      // TimeStart and TimeEnd at the same hh:mm are distinct types.
      expect(TimeStart(time: e1.time) == e1, isFalse);
    });
  });

  group('Destination sealed family', () {
    test('NoDestination has no fields and equals itself', () {
      const a = NoDestination();
      const b = NoDestination();
      expect(a, b);
    });

    test('SpecificAddress equality', () {
      const a = SpecificAddress(
        address: 'Av Paulista, 1000',
        lat: -23.56,
        lng: -46.65,
      );
      const b = SpecificAddress(
        address: 'Av Paulista, 1000',
        lat: -23.56,
        lng: -46.65,
      );
      const c = SpecificAddress(
        address: 'Av Paulista, 2000',
        lat: -23.56,
        lng: -46.65,
      );
      expect(a, b);
      expect(a, isNot(c));
    });

    test('RoundTrip distinct from NoDestination', () {
      expect(const RoundTrip() == const NoDestination(), isFalse);
      expect(const RoundTrip(), const RoundTrip());
    });

    test('exhaustive switch compiles for all 3 Spoke variants', () {
      String label(Destination d) => switch (d) {
            RoundTrip() => 'round',
            SpecificAddress() => 'specific',
            NoDestination() => 'none',
          };
      expect(label(const RoundTrip()), 'round');
      expect(
        label(const SpecificAddress(address: 'a', lat: 0, lng: 0)),
        'specific',
      );
      expect(label(const NoDestination()), 'none');
    });
  });

  group('BreakConfig (window: fromTime/toTime/durationMinutes — ADR-0044)', () {
    test('equality compares all three fields', () {
      const a = BreakConfig(
        fromTime: TimeOfDay(hour: 8, minute: 0),
        toTime: TimeOfDay(hour: 15, minute: 0),
        durationMinutes: 30,
      );
      const b = BreakConfig(
        fromTime: TimeOfDay(hour: 8, minute: 0),
        toTime: TimeOfDay(hour: 15, minute: 0),
        durationMinutes: 30,
      );
      const differentDuration = BreakConfig(
        fromTime: TimeOfDay(hour: 8, minute: 0),
        toTime: TimeOfDay(hour: 15, minute: 0),
        durationMinutes: 60,
      );
      expect(a, b);
      expect(a, isNot(differentDuration));
    });

    test('a different toTime makes two breaks unequal', () {
      const a = BreakConfig(
        fromTime: TimeOfDay(hour: 8, minute: 0),
        toTime: TimeOfDay(hour: 15, minute: 0),
        durationMinutes: 30,
      );
      const widerWindow = BreakConfig(
        fromTime: TimeOfDay(hour: 8, minute: 0),
        toTime: TimeOfDay(hour: 16, minute: 0),
        durationMinutes: 30,
      );
      expect(a, isNot(widerWindow));
      expect(a.hashCode, isNot(widerWindow.hashCode));
    });
  });

  group('RouteConfig', () {
    test(
        'empty() defaults destination to RoundTrip (Spoke parity); '
        'other fields null + breaks empty', () {
      final c = RouteConfig.empty();
      expect(c.startLocation, isNull);
      expect(c.timeStart, isNull);
      expect(c.timeEnd, isNull);
      // Spoke shows "Ida e volta" as the default mode on a brand-new route —
      // the domain must reflect that, not leave destination null and rely on
      // the presentation layer to mask it.
      expect(c.destination, const RoundTrip());
      expect(c.breaks, isEmpty);
    });

    test('equality compares every field including breaks list', () {
      const a = RouteConfig(
        startLocation: StartLocation(
          address: 'R Augusta',
          lat: 0,
          lng: 0,
          isUserCurrentLocation: false,
        ),
        timeStart: TimeStart(time: TimeOfDay(hour: 8, minute: 0)),
        timeEnd: TimeEnd(time: TimeOfDay(hour: 18, minute: 0)),
        destination: NoDestination(),
        breaks: [
          BreakConfig(
            fromTime: TimeOfDay(hour: 8, minute: 0),
            toTime: TimeOfDay(hour: 15, minute: 0),
            durationMinutes: 30,
          ),
        ],
      );
      const b = RouteConfig(
        startLocation: StartLocation(
          address: 'R Augusta',
          lat: 0,
          lng: 0,
          isUserCurrentLocation: false,
        ),
        timeStart: TimeStart(time: TimeOfDay(hour: 8, minute: 0)),
        timeEnd: TimeEnd(time: TimeOfDay(hour: 18, minute: 0)),
        destination: NoDestination(),
        breaks: [
          BreakConfig(
            fromTime: TimeOfDay(hour: 8, minute: 0),
            toTime: TimeOfDay(hour: 15, minute: 0),
            durationMinutes: 30,
          ),
        ],
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    group('isValid', () {
      test('false when both timeStart and timeEnd are null', () {
        expect(RouteConfig.empty().isValid, isFalse);
      });

      test('false when timeStart is null', () {
        final c = RouteConfig.empty().withTimeEnd(
          const TimeEnd(time: TimeOfDay(hour: 18, minute: 0)),
        );
        expect(c.isValid, isFalse);
      });

      test('false when timeEnd is null', () {
        final c = RouteConfig.empty().withTimeStart(
          const TimeStart(time: TimeOfDay(hour: 8, minute: 0)),
        );
        expect(c.isValid, isFalse);
      });

      test('false when timeEnd equals timeStart', () {
        final c = RouteConfig.empty()
            .withTimeStart(
              const TimeStart(time: TimeOfDay(hour: 8, minute: 0)),
            )
            .withTimeEnd(
              const TimeEnd(time: TimeOfDay(hour: 8, minute: 0)),
            );
        expect(c.isValid, isFalse);
      });

      test('false when timeEnd is before timeStart', () {
        final c = RouteConfig.empty()
            .withTimeStart(
              const TimeStart(time: TimeOfDay(hour: 18, minute: 0)),
            )
            .withTimeEnd(
              const TimeEnd(time: TimeOfDay(hour: 8, minute: 0)),
            );
        expect(c.isValid, isFalse);
      });

      test('true when timeEnd strictly after timeStart', () {
        final c = RouteConfig.empty()
            .withTimeStart(
              const TimeStart(time: TimeOfDay(hour: 8, minute: 0)),
            )
            .withTimeEnd(
              const TimeEnd(time: TimeOfDay(hour: 18, minute: 30)),
            );
        expect(c.isValid, isTrue);
      });
    });

    group('per-field updaters (nullable safe)', () {
      test('withStartLocation(null) clears the field', () {
        final filled = RouteConfig.empty().withStartLocation(
          const StartLocation(
            address: 'R Augusta',
            lat: 0,
            lng: 0,
            isUserCurrentLocation: false,
          ),
        );
        expect(filled.startLocation, isNotNull);
        final cleared = filled.withStartLocation(null);
        expect(cleared.startLocation, isNull);
      });

      test('withTimeStart(null) clears the field', () {
        final filled = RouteConfig.empty().withTimeStart(
          const TimeStart(time: TimeOfDay(hour: 8, minute: 0)),
        );
        expect(filled.withTimeStart(null).timeStart, isNull);
      });

      test('withTimeEnd(null) clears the field', () {
        final filled = RouteConfig.empty().withTimeEnd(
          const TimeEnd(time: TimeOfDay(hour: 18, minute: 0)),
        );
        expect(filled.withTimeEnd(null).timeEnd, isNull);
      });

      test('withDestination(null) clears the field', () {
        final filled =
            RouteConfig.empty().withDestination(const NoDestination());
        expect(filled.withDestination(null).destination, isNull);
      });

      test('withBreaks replaces the list (not append)', () {
        final filled = RouteConfig.empty().withBreaks(const [
          BreakConfig(
            fromTime: TimeOfDay(hour: 8, minute: 0),
            toTime: TimeOfDay(hour: 15, minute: 0),
            durationMinutes: 30,
          ),
        ]);
        expect(filled.breaks.length, 1);
        final replaced = filled.withBreaks(const []);
        expect(replaced.breaks, isEmpty);
      });

      test('updaters preserve untouched fields', () {
        final c = RouteConfig.empty()
            .withTimeStart(
              const TimeStart(time: TimeOfDay(hour: 8, minute: 0)),
            )
            .withDestination(const RoundTrip());
        expect(c.timeStart, isNotNull);
        expect(c.destination, const RoundTrip());
        expect(c.timeEnd, isNull);
        expect(c.startLocation, isNull);
        expect(c.breaks, isEmpty);
      });
    });
  });
}
