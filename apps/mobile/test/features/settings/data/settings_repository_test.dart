import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/settings/data/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('read() — absent key → canonical default', () {
    test(
      'returns defaultStopDuration == 1 min when key has never been written (F9)',
      () async {
        final repo = SettingsRepository(SharedPreferencesAsync());

        final result = await repo.read();

        // Must equal 60 seconds — NOT zero. If this passes before
        // Settings.defaults() is implemented, the implementation is returning
        // a wrong zero-value.
        expect(
          result.defaultStopDuration,
          const Duration(minutes: 1),
          reason: 'F9: Spoke default stop duration is 1 minute',
        );
      },
    );
  });

  group('roundtrip — write then read preserves second-precision (F9)', () {
    test(
      'write(2 min 30 s) then read() == Duration(seconds: 150)',
      () async {
        final prefs = SharedPreferencesAsync();
        final repo = SettingsRepository(prefs);
        const toWrite =
            Settings(defaultStopDuration: Duration(minutes: 2, seconds: 30));

        await repo.write(toWrite);
        final result = await repo.read();

        expect(
          result.defaultStopDuration,
          const Duration(seconds: 150),
          reason: 'F9: stop duration persists with full second precision',
        );
      },
    );
  });

  group('read() — corrupted envelope → default without throwing (H15)', () {
    test(
      'malformed JSON string → returns 1 min default, no exception',
      () async {
        final prefs = SharedPreferencesAsync();
        await prefs.setString(
          SettingsRepository.storageKey,
          '{{{not-json',
        );
        final repo = SettingsRepository(prefs);

        // Must not throw — H15 resilience contract.
        final result = await repo.read();

        expect(
          result.defaultStopDuration,
          const Duration(minutes: 1),
          reason: 'H15: corrupted payload falls back to canonical default',
        );
      },
    );

    test(
      'valid JSON but not a map (bare integer) → returns 1 min default',
      () async {
        final prefs = SharedPreferencesAsync();
        await prefs.setString(
          SettingsRepository.storageKey,
          jsonEncode(42),
        );
        final repo = SettingsRepository(prefs);

        final result = await repo.read();

        expect(
          result.defaultStopDuration,
          const Duration(minutes: 1),
          reason: 'H15: non-map JSON payload falls back to canonical default',
        );
      },
    );
  });
}
