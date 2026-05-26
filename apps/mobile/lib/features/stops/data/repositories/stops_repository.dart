import '../../domain/stop.dart';

/// Persistence contract for the user's current stop list.
///
/// Slice 2 ships a SharedPreferences-backed impl
/// (`SharedPrefsStopsRepository`) for session restore. Slice 3 will
/// add `HttpStopsRepository` that reads/writes the backend `routes`
/// table; the controller swaps the impl via Riverpod override without
/// changing call sites.
abstract class StopsRepository {
  Future<List<Stop>> load();
  Future<void> save(List<Stop> stops);
}
