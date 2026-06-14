import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'optimization_ftue_repository.g.dart';

/// Production-backed repo (idiom de `settingsRepositoryProvider`).
@Riverpod(keepAlive: true)
OptimizationFtueRepository optimizationFtueRepository(Ref ref) =>
    OptimizationFtueRepository(SharedPreferencesAsync());

/// Persists FTUE (first-time user education) acknowledgement flags for the
/// optimization flow.
///
/// Stateless beyond the injected [SharedPreferencesAsync] instance.
class OptimizationFtueRepository {
  OptimizationFtueRepository(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const String _numberingKey = 'numbering_ftue_v1';

  /// Returns whether the user has acknowledged the stop-numbering explanation.
  Future<bool> isNumberingAcknowledged() async {
    return await _prefs.getBool(_numberingKey) ?? false;
  }

  /// Marks the stop-numbering explanation as acknowledged.
  Future<void> acknowledgeNumbering() {
    return _prefs.setBool(_numberingKey, true);
  }
}
