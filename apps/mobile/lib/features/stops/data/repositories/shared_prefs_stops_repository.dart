import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/stop.dart';
import 'stops_repository.dart';

/// SharedPreferencesAsync-backed implementation of [StopsRepository].
///
/// Per spec §Persistence (and the modern-API rule in §Risks), uses the
/// async-first SharedPreferencesAsync (shared_preferences 2.3+), not
/// the deprecated SharedPreferences.getInstance().
///
/// The persisted JSON has a `_v: 1` envelope so slice 3's
/// HttpStopsRepository can recognize and drain it on first hydrate.
class SharedPrefsStopsRepository implements StopsRepository {
  SharedPrefsStopsRepository({SharedPreferencesAsync? prefs})
      : _prefs = prefs ?? SharedPreferencesAsync();

  static const storageKey = 'stops.current_session';
  static const _schemaVersion = 1;

  final SharedPreferencesAsync _prefs;

  @override
  Future<List<Stop>> load() async {
    final raw = await _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      if (decoded['_v'] != _schemaVersion) return const [];

      final list = decoded['stops'] as List<dynamic>;
      return list
          .map((e) => Stop.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } catch (_) {
      // Corrupt payload: prefer an empty session over a crash.
      return const [];
    }
  }

  @override
  Future<void> save(List<Stop> stops) async {
    final payload = {
      '_v': _schemaVersion,
      'stops': stops.map((s) => s.toJson()).toList(),
    };
    await _prefs.setString(storageKey, jsonEncode(payload));
  }
}
