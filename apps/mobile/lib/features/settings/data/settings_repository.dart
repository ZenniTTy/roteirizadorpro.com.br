import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal domain object for user-level settings.
///
/// Only [defaultStopDuration] is declared in this slice (F9). Área 10 will
/// expand this class with additional fields — the single-source-of-truth rule
/// (H14) means widgets NEVER re-declare the canonical fallback; they read it
/// from [Settings.fallbackStopDuration].
class Settings {
  const Settings({required this.defaultStopDuration});

  /// Canonical fallback per F9: Spoke default is 1 minute.
  /// Declared exactly once here — widgets never re-declare this value (H14).
  static const Duration fallbackStopDuration = Duration(minutes: 1);

  /// Returns a [Settings] instance pre-populated with canonical defaults.
  factory Settings.defaults() =>
      const Settings(defaultStopDuration: fallbackStopDuration);

  final Duration defaultStopDuration;

  /// Serialises this instance to a JSON-encodable map. Duration vai como
  /// total de SEGUNDOS — F9 exige precisão min+seg.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'defaultStopDurationSeconds': defaultStopDuration.inSeconds,
      };

  /// Deserialises from a JSON map produced by [toJson]. Valores ausentes ou
  /// de tipo errado caem no default canônico (H15).
  factory Settings.fromJson(Map<String, dynamic> json) {
    final seconds = json['defaultStopDurationSeconds'];
    return Settings(
      defaultStopDuration:
          seconds is int ? Duration(seconds: seconds) : fallbackStopDuration,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Settings &&
          runtimeType == other.runtimeType &&
          defaultStopDuration == other.defaultStopDuration;

  @override
  int get hashCode => defaultStopDuration.hashCode;
}

/// Persists the user's [Settings] envelope under a single string key in
/// `SharedPreferencesAsync`.
///
/// Stateless beyond the injected [SharedPreferencesAsync] instance — tests
/// substitute `InMemorySharedPreferencesAsync` via the platform interface to
/// avoid touching device storage.
///
/// Resilience contract (H15): corrupted or non-map payloads are caught here;
/// [read] always returns at least [Settings.defaults] — never throws.
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferencesAsync _prefs;

  /// Single SharedPreferences key. The `_v1` suffix gives a future-proof
  /// migration path: schema-version bump = also bump this key.
  static const String storageKey = 'settings_v1';

  /// Reads persisted settings. Returns [Settings.defaults] when the key is
  /// absent, JSON is malformed, or the top-level value is not a map (H15).
  Future<Settings> read() async {
    final raw = await _prefs.getString(storageKey);
    if (raw == null) return Settings.defaults();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return Settings.defaults();
      return Settings.fromJson(decoded);
    } catch (e) {
      debugPrint('[settings_repository] corrupted JSON: $e');
      return Settings.defaults();
    }
  }

  /// Persists [s] to SharedPreferences.
  Future<void> write(Settings s) async {
    await _prefs.setString(storageKey, jsonEncode(s.toJson()));
  }
}
