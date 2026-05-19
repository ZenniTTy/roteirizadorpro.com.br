import 'package:roteirizador_pro/features/stops/data/repositories/stops_repository.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';

class FakeStopsRepository implements StopsRepository {
  FakeStopsRepository([List<Stop> initial = const []])
      : _stored = List.of(initial);

  List<Stop> _stored;
  final List<Stop> saved = [];

  /// Replaces the in-memory list returned by [load] without invoking [save].
  /// Used by tests that need to seed state after the fake is constructed
  /// (e.g. the controller suite's `setUp` builds an empty fake and per-test
  /// seeds a starting list before reading the provider).
  void seed(List<Stop> stops) {
    _stored = List.of(stops);
  }

  @override
  Future<List<Stop>> load() async => List.unmodifiable(_stored);

  @override
  Future<void> save(List<Stop> stops) async {
    _stored = List.of(stops);
    saved
      ..clear()
      ..addAll(stops);
  }
}
