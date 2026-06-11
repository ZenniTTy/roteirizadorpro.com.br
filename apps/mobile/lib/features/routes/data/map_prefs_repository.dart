import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's map-layer preference (`normal` <-> `satellite`) under a
/// single string key in `SharedPreferencesAsync`.
///
/// Only the [MapType] is persisted — the follow-my-location mode is ephemeral
/// (see [MapControlsState]). Stateless beyond the injected
/// [SharedPreferencesAsync]; tests substitute `InMemorySharedPreferencesAsync`
/// via the platform interface.
class MapPrefsRepository {
  MapPrefsRepository(this._prefs);

  final SharedPreferencesAsync _prefs;

  /// `_v1` suffix mirrors `route_defaults_v1` — a schemaVersion-bump migration
  /// path is a key bump.
  static const String mapTypeKey = 'map_type_v1';

  static const String _normal = 'normal';
  static const String _satellite = 'satellite';

  Future<MapType> readMapType() async {
    final raw = await _prefs.getString(mapTypeKey);
    return switch (raw) {
      _satellite => MapType.satellite,
      // null (unset) or any unexpected value degrades to the Spoke default.
      _ => MapType.normal,
    };
  }

  Future<void> writeMapType(MapType type) async {
    // The toggle only ever produces normal/satellite; any other MapType is a
    // programming error, so we coerce to the safe default and log.
    if (type != MapType.normal && type != MapType.satellite) {
      debugPrint('[map_prefs_repository] unexpected MapType $type -> normal');
    }
    final value = type == MapType.satellite ? _satellite : _normal;
    await _prefs.setString(mapTypeKey, value);
  }
}
