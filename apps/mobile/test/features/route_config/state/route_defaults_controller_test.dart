import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/route_config/data/route_defaults_repository.dart';
import 'package:roteirizador_pro/features/route_config/domain/route_config.dart';
import 'package:roteirizador_pro/features/route_config/domain/route_defaults.dart';
import 'package:roteirizador_pro/features/route_config/state/route_defaults_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

ProviderContainer _container() {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  final c = ProviderContainer(
    overrides: [
      routeDefaultsRepositoryProvider.overrideWithValue(
        RouteDefaultsRepository(SharedPreferencesAsync()),
      ),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('build()', () {
    test('returns RouteDefaults.empty() on empty store', () async {
      final c = _container();
      expect(
        await c.read(routeDefaultsControllerProvider.future),
        RouteDefaults.empty(),
      );
    });

    test('returns parsed envelope when one was previously persisted', () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final repo = RouteDefaultsRepository(SharedPreferencesAsync());
      const seeded = RouteDefaults(
        firstRoute: false,
        timeStart: TimeStart(time: TimeOfDay(hour: 9, minute: 0)),
      );
      await repo.write(seeded);
      final c = ProviderContainer(
        overrides: [
          routeDefaultsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(c.dispose);
      expect(await c.read(routeDefaultsControllerProvider.future), seeded);
    });
  });

  group('merge()', () {
    test('partial patch overrides only non-null fields + persists', () async {
      final c = _container();
      // ensure initial build resolved
      await c.read(routeDefaultsControllerProvider.future);

      const patch = RouteDefaults(
        firstRoute: false,
        timeStart: TimeStart(time: TimeOfDay(hour: 8, minute: 0)),
      );
      await c.read(routeDefaultsControllerProvider.notifier).merge(patch);

      final result = await c.read(routeDefaultsControllerProvider.future);
      expect(result.timeStart?.time.hour, 8);
      expect(result.firstRoute, isFalse);
      // Other fields stay empty.
      expect(result.startLocation, isNull);
      expect(result.destination, isNull);

      // And the repo has the same value persisted.
      final fromRepo = await c.read(routeDefaultsRepositoryProvider).read();
      expect(fromRepo.timeStart?.time.hour, 8);
      expect(fromRepo.firstRoute, isFalse);
    });

    test('patch with breaks replaces breaks list when non-empty', () async {
      final c = _container();
      await c.read(routeDefaultsControllerProvider.future);

      const patch = RouteDefaults(
        breaks: [
          BreakConfig(
            startTime: TimeOfDay(hour: 12, minute: 0),
            durationMinutes: 30,
          ),
        ],
      );
      await c.read(routeDefaultsControllerProvider.notifier).merge(patch);

      final result = await c.read(routeDefaultsControllerProvider.future);
      expect(result.breaks.length, 1);
      expect(result.breaks.first.durationMinutes, 30);
    });

    test('patch with empty breaks preserves existing breaks', () async {
      final c = _container();
      await c.read(routeDefaultsControllerProvider.future);

      const first = RouteDefaults(
        breaks: [
          BreakConfig(
            startTime: TimeOfDay(hour: 12, minute: 0),
            durationMinutes: 30,
          ),
        ],
      );
      await c.read(routeDefaultsControllerProvider.notifier).merge(first);
      // Patch that only sets timeStart, no breaks
      const second = RouteDefaults(
        timeStart: TimeStart(time: TimeOfDay(hour: 8, minute: 0)),
      );
      await c.read(routeDefaultsControllerProvider.notifier).merge(second);

      final result = await c.read(routeDefaultsControllerProvider.future);
      expect(result.breaks.length, 1);
      expect(result.timeStart?.time.hour, 8);
    });
  });

  group('markFirstRouteComplete()', () {
    test('flips firstRoute false and persists', () async {
      final c = _container();
      await c.read(routeDefaultsControllerProvider.future);

      expect(
        (await c.read(routeDefaultsControllerProvider.future)).firstRoute,
        isTrue,
      );
      await c
          .read(routeDefaultsControllerProvider.notifier)
          .markFirstRouteComplete();

      expect(
        (await c.read(routeDefaultsControllerProvider.future)).firstRoute,
        isFalse,
      );
      expect(
        (await c.read(routeDefaultsRepositoryProvider).read()).firstRoute,
        isFalse,
      );
    });

    test('is idempotent — second call no-ops', () async {
      final c = _container();
      await c.read(routeDefaultsControllerProvider.future);

      final notifier = c.read(routeDefaultsControllerProvider.notifier);
      await notifier.markFirstRouteComplete();
      await notifier.markFirstRouteComplete();
      expect(
        (await c.read(routeDefaultsControllerProvider.future)).firstRoute,
        isFalse,
      );
    });
  });
}
