import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/settings_repository.dart';

part 'settings_controller.g.dart';

/// Singleton repository binding. Override in tests to inject an
/// `InMemorySharedPreferencesAsync`-backed instance.
@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) {
  return SettingsRepository(SharedPreferencesAsync());
}

/// User's saved settings envelope. Singleton across the app — one user, one
/// envelope.
///
/// `keepAlive: true` matches the `routeDefaultsController` pattern: callers
/// read this asynchronously at navigation boundaries; dropping the provider
/// would re-read SharedPrefs on every navigation.
@Riverpod(keepAlive: true)
class SettingsController extends _$SettingsController {
  @override
  Future<Settings> build() async {
    final repo = ref.read(settingsRepositoryProvider);
    return repo.read();
  }

  /// Persists a new [defaultStopDuration] and updates the in-memory state.
  ///
  /// Write-then-state pattern mirrors [RouteDefaultsController.merge]:
  ///   1. write new value to the repository;
  ///   2. update [state] to `AsyncData(next)` so callers see the change
  ///      without a round-trip read.
  Future<void> setDefaultStopDuration(Duration d) async {
    final next = Settings(defaultStopDuration: d);
    await ref.read(settingsRepositoryProvider).write(next);
    state = AsyncData(next);
  }
}
