import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/route_config/domain/route_config.dart';
import 'package:roteirizador_pro/features/route_config/state/route_config_controller.dart';

ProviderContainer _container() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('initial state', () {
    test('build(routeId) returns RouteConfig.empty()', () {
      final c = _container();
      expect(c.read(routeConfigControllerProvider('r1')), RouteConfig.empty());
    });
  });

  group('mutations', () {
    test('setStartLocation mutates state', () {
      final c = _container();
      const value = StartLocation(
        address: 'R Augusta',
        lat: -23.5,
        lng: -46.6,
        isUserCurrentLocation: false,
      );
      c
          .read(routeConfigControllerProvider('r1').notifier)
          .setStartLocation(value);
      expect(c.read(routeConfigControllerProvider('r1')).startLocation, value);
    });

    test('setStartLocation(null) clears the field', () {
      final c = _container();
      const value = StartLocation(
        address: 'R Augusta',
        lat: -23.5,
        lng: -46.6,
        isUserCurrentLocation: false,
      );
      final notifier = c.read(routeConfigControllerProvider('r1').notifier)
        ..setStartLocation(value);
      expect(c.read(routeConfigControllerProvider('r1')).startLocation, value);
      notifier.setStartLocation(null);
      expect(
        c.read(routeConfigControllerProvider('r1')).startLocation,
        isNull,
      );
    });

    test('setTimeStart / setTimeEnd mutate state', () {
      final c = _container();
      final notifier = c.read(routeConfigControllerProvider('r1').notifier)
        ..setTimeStart(
          const TimeStart(time: TimeOfDay(hour: 8, minute: 0)),
        )
        ..setTimeEnd(
          const TimeEnd(time: TimeOfDay(hour: 18, minute: 0)),
        );
      final state = c.read(routeConfigControllerProvider('r1'));
      expect(state.timeStart?.time.hour, 8);
      expect(state.timeEnd?.time.hour, 18);
      // Touch notifier to avoid unused_local lint when no further mutations.
      expect(notifier, isNotNull);
    });

    test('setDestination cycles between variants', () {
      final c = _container();
      final notifier = c.read(routeConfigControllerProvider('r1').notifier)
        ..setDestination(const BackToStart());
      expect(
        c.read(routeConfigControllerProvider('r1')).destination,
        const BackToStart(),
      );
      notifier.setDestination(const RoundTrip());
      expect(
        c.read(routeConfigControllerProvider('r1')).destination,
        const RoundTrip(),
      );
      notifier.setDestination(null);
      expect(
        c.read(routeConfigControllerProvider('r1')).destination,
        isNull,
      );
    });

    test('addBreak appends to breaks list', () {
      final c = _container();
      final notifier = c.read(routeConfigControllerProvider('r1').notifier)
        ..addBreak(
          const BreakConfig(
            startTime: TimeOfDay(hour: 12, minute: 0),
            durationMinutes: 30,
          ),
        )
        ..addBreak(
          const BreakConfig(
            startTime: TimeOfDay(hour: 15, minute: 30),
            durationMinutes: 15,
          ),
        );
      expect(c.read(routeConfigControllerProvider('r1')).breaks.length, 2);
      expect(notifier, isNotNull);
    });

    test('updateBreak replaces entry at index', () {
      final c = _container();
      final notifier = c.read(routeConfigControllerProvider('r1').notifier)
        ..addBreak(
          const BreakConfig(
            startTime: TimeOfDay(hour: 12, minute: 0),
            durationMinutes: 30,
          ),
        );
      notifier.updateBreak(
        0,
        const BreakConfig(
          startTime: TimeOfDay(hour: 13, minute: 0),
          durationMinutes: 60,
        ),
      );
      final breaks = c.read(routeConfigControllerProvider('r1')).breaks;
      expect(breaks.length, 1);
      expect(breaks[0].startTime.hour, 13);
      expect(breaks[0].durationMinutes, 60);
    });

    test('removeBreak drops entry at index', () {
      final c = _container();
      final notifier = c.read(routeConfigControllerProvider('r1').notifier)
        ..addBreak(
          const BreakConfig(
            startTime: TimeOfDay(hour: 12, minute: 0),
            durationMinutes: 30,
          ),
        )
        ..addBreak(
          const BreakConfig(
            startTime: TimeOfDay(hour: 15, minute: 30),
            durationMinutes: 15,
          ),
        );
      notifier.removeBreak(0);
      final breaks = c.read(routeConfigControllerProvider('r1')).breaks;
      expect(breaks.length, 1);
      expect(breaks[0].startTime.hour, 15);
    });

    test('clear resets to RouteConfig.empty()', () {
      final c = _container();
      final notifier = c.read(routeConfigControllerProvider('r1').notifier)
        ..setTimeStart(const TimeStart(time: TimeOfDay(hour: 8, minute: 0)))
        ..setDestination(const RoundTrip())
        ..addBreak(
          const BreakConfig(
            startTime: TimeOfDay(hour: 12, minute: 0),
            durationMinutes: 30,
          ),
        );
      notifier.clear();
      expect(c.read(routeConfigControllerProvider('r1')), RouteConfig.empty());
    });
  });

  group('isolation by family key', () {
    test('different routeIds keep independent state', () {
      final c = _container();
      c.read(routeConfigControllerProvider('routeA').notifier).setTimeStart(
            const TimeStart(time: TimeOfDay(hour: 8, minute: 0)),
          );
      c.read(routeConfigControllerProvider('routeB').notifier).setTimeStart(
            const TimeStart(time: TimeOfDay(hour: 10, minute: 0)),
          );
      expect(
        c.read(routeConfigControllerProvider('routeA')).timeStart?.time.hour,
        8,
      );
      expect(
        c.read(routeConfigControllerProvider('routeB')).timeStart?.time.hour,
        10,
      );
    });
  });

  group('isRouteConfigValidProvider', () {
    test('false on empty config', () {
      final c = _container();
      expect(c.read(isRouteConfigValidProvider('r1')), isFalse);
    });

    test('true when timeEnd strictly after timeStart', () {
      final c = _container();
      c.read(routeConfigControllerProvider('r1').notifier)
        ..setTimeStart(const TimeStart(time: TimeOfDay(hour: 8, minute: 0)))
        ..setTimeEnd(const TimeEnd(time: TimeOfDay(hour: 18, minute: 0)));
      expect(c.read(isRouteConfigValidProvider('r1')), isTrue);
    });

    test('false when only one time set', () {
      final c = _container();
      c.read(routeConfigControllerProvider('r1').notifier).setTimeStart(
            const TimeStart(time: TimeOfDay(hour: 8, minute: 0)),
          );
      expect(c.read(isRouteConfigValidProvider('r1')), isFalse);
    });
  });
}
