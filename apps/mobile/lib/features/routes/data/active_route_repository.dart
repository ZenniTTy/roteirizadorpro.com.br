import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'active_route_repository.g.dart';

/// Production-backed repo (idiom de `optimizationFtueRepositoryProvider`).
@Riverpod(keepAlive: true)
ActiveRouteRepository activeRouteRepository(Ref ref) =>
    ActiveRouteRepository(SharedPreferencesAsync());

/// Persists the id of the active route so the shell can restore it across
/// app restarts. Mirrors Spoke's persisted `User.activeRouteRef` (Firestore)
/// — here the equivalent is a local SharedPreferences string. Stateless
/// beyond the injected [SharedPreferencesAsync].
class ActiveRouteRepository {
  ActiveRouteRepository(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const String _key = 'active_route_id_v1';

  /// The persisted active-route id, or null if none was ever stored.
  Future<String?> read() => _prefs.getString(_key);

  /// Persists [id], or removes the key entirely when [id] is null (so a
  /// cleared active route never leaves an orphan id on disk).
  Future<void> write(String? id) {
    if (id == null) return _prefs.remove(_key);
    return _prefs.setString(_key, id);
  }
}
