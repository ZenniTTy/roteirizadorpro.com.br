import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/settings/data/settings_repository.dart';
import 'package:roteirizador_pro/features/settings/state/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Creates a fresh [ProviderContainer] backed by an in-memory prefs store.
/// Mirrors the `_container()` helper in route_defaults_controller_test.dart.
ProviderContainer _container() {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  final c = ProviderContainer(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(
        SettingsRepository(SharedPreferencesAsync()),
      ),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('build() — reads persisted value', () {
    test(
      'returns 5-minute defaultStopDuration when 5 min was seeded before build',
      () async {
        // Seed a non-default value (5 min ≠ 1 min fallback) so a green test
        // cannot be explained by reading an accidental default.
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.empty();
        final repo = SettingsRepository(SharedPreferencesAsync());
        await repo.write(
          const Settings(defaultStopDuration: Duration(minutes: 5)),
        );

        final c = ProviderContainer(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(repo),
          ],
        );
        addTearDown(c.dispose);

        final result = await c.read(settingsControllerProvider.future);

        expect(
          result.defaultStopDuration,
          const Duration(minutes: 5),
          reason:
              'build() must hydrate state from the repository, not hard-code a default',
        );
      },
    );
  });

  group('setDefaultStopDuration() — write-then-state pattern', () {
    test(
      'persists 90 s to repository AND updates in-memory state to AsyncData(90 s)',
      () async {
        final c = _container();
        // Hydrate initial build.
        await c.read(settingsControllerProvider.future);

        await c
            .read(settingsControllerProvider.notifier)
            .setDefaultStopDuration(const Duration(seconds: 90));

        // 1. In-memory state reflects new value immediately.
        final stateAfter = await c.read(settingsControllerProvider.future);
        expect(
          stateAfter.defaultStopDuration,
          const Duration(seconds: 90),
          reason:
              'state must be updated to AsyncData(90s) without a re-read round-trip',
        );

        // 2. Repository has the same value persisted — confirming write happened.
        final fromRepo = await c.read(settingsRepositoryProvider).read();
        expect(
          fromRepo.defaultStopDuration,
          const Duration(seconds: 90),
          reason:
              'setDefaultStopDuration must write to the repository (not just update in-memory state)',
        );
      },
    );
  });
}
