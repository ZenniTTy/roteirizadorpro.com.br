import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/route_defaults.dart';

/// Persists the user's [RouteDefaults] envelope under a single string key in
/// `SharedPreferencesAsync`.
///
/// Stateless beyond the injected [SharedPreferencesAsync] instance — tests
/// substitute `InMemorySharedPreferencesAsync` via the platform interface to
/// avoid touching the device storage.
///
/// Forward-compat: schema mismatches and malformed payloads return
/// [RouteDefaults.empty] (the parsing layer in [RouteDefaults.fromJson]
/// already absorbs every value-level error); top-level decode failures are
/// caught here.
class RouteDefaultsRepository {
  RouteDefaultsRepository(this._prefs);

  final SharedPreferencesAsync _prefs;

  /// Single SharedPreferences key. The `_v1` suffix gives us a future-proof
  /// migration path: schemaVersion-bump strategy = also bump the key.
  static const String storageKey = 'route_defaults_v1';

  Future<RouteDefaults> read() async {
    final raw = await _prefs.getString(storageKey);
    if (raw == null) return RouteDefaults.empty();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return RouteDefaults.empty();
      return RouteDefaults.fromJson(decoded);
    } catch (e) {
      debugPrint('[route_defaults_repository] corrupted JSON: $e');
      return RouteDefaults.empty();
    }
  }

  Future<void> write(RouteDefaults defaults) async {
    final encoded = jsonEncode(defaults.toJson());
    await _prefs.setString(storageKey, encoded);
  }
}
