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
        timeStart: TimeStart(time: TimeOfDay(hour: 8, minute: 0)),
      );
      await c.read(routeDefaultsControllerProvider.notifier).merge(patch);

      final result = await c.read(routeDefaultsControllerProvider.future);
      expect(result.timeStart?.time.hour, 8);
      // Other fields stay empty.
      expect(result.startLocation, isNull);
      expect(result.destination, isNull);

      // And the repo has the same value persisted.
      final fromRepo = await c.read(routeDefaultsRepositoryProvider).read();
      expect(fromRepo.timeStart?.time.hour, 8);
    });

    test(
      'merge() does NOT clobber firstRoute back to true (regression)',
      () async {
        // Reproduces the MS1 review must-fix: a partial patch built via the
        // default RouteDefaults constructor carries firstRoute=true by default,
        // which used to flip the persisted firstRoute=false back to true on
        // every Concluido save — breaking the MS8 FTUE flag.
        final c = _container();
        await c.read(routeDefaultsControllerProvider.future);

        // Mark first-route done first (MS8 will call this on initial save).
        await c
            .read(routeDefaultsControllerProvider.notifier)
            .markFirstRouteComplete();
        expect(
          (await c.read(routeDefaultsControllerProvider.future)).firstRoute,
          isFalse,
        );

        // Now a downstream MS8-style partial-patch save (only timeStart).
        // The patch carries firstRoute=true (ctor default) — must NOT clobber.
        const patch = RouteDefaults(
          timeStart: TimeStart(time: TimeOfDay(hour: 8, minute: 0)),
        );
        await c.read(routeDefaultsControllerProvider.notifier).merge(patch);

        final state = await c.read(routeDefaultsControllerProvider.future);
        expect(
          state.firstRoute,
          isFalse,
          reason: 'merge() preserves prior firstRoute=false',
        );
        expect(state.timeStart?.time.hour, 8);

        // Also persisted to the repo.
        final fromRepo = await c.read(routeDefaultsRepositoryProvider).read();
        expect(fromRepo.firstRoute, isFalse);
      },
    );

    test(
      'merge() does NOT downgrade schemaVersion from a future-state envelope',
      () async {
        // The schemaVersion field is preserved from the current envelope
        // across merges. A patch built via the default ctor (schemaVersion=1)
        // must not pin nor mutate the persisted version. (We can only assert
        // it stays at 1 in MS1 since v2 doesn't exist yet — but the
        // pre-fix code would have read patch.schemaVersion unconditionally.)
        final c = _container();
        await c.read(routeDefaultsControllerProvider.future);

        const patch = RouteDefaults(
          timeStart: TimeStart(time: TimeOfDay(hour: 8, minute: 0)),
        );
        await c.read(routeDefaultsControllerProvider.notifier).merge(patch);

        final state = await c.read(routeDefaultsControllerProvider.future);
        expect(state.schemaVersion, 1);
      },
    );

    test('patch with breaks replaces breaks list when non-empty', () async {
      final c = _container();
      await c.read(routeDefaultsControllerProvider.future);

      const patch = RouteDefaults(
        breaks: [
          BreakConfig(
            fromTime: TimeOfDay(hour: 8, minute: 0),
            toTime: TimeOfDay(hour: 15, minute: 0),
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
            fromTime: TimeOfDay(hour: 8, minute: 0),
            toTime: TimeOfDay(hour: 15, minute: 0),
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
