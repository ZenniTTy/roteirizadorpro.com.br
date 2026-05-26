import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/repositories/shared_prefs_stops_repository.dart';
import '../data/repositories/stops_repository.dart';
import '../domain/stop.dart';

part 'stops_controller.g.dart';

@riverpod
StopsRepository stopsRepository(Ref ref) {
  return SharedPrefsStopsRepository();
}

@riverpod
class StopsController extends _$StopsController {
  StopsRepository get _repo => ref.read(stopsRepositoryProvider);

  @override
  Future<List<Stop>> build() async {
    return _repo.load();
  }

  Future<void> add(Stop stop) async {
    final current = await future;
    final next = [...current, stop];
    state = AsyncData(next);
    await _repo.save(next);
  }

  Future<void> remove(String id) async {
    final current = await future;
    final next = current.where((s) => s.id != id).toList(growable: false);
    state = AsyncData(next);
    await _repo.save(next);
  }

  Future<void> updateStop(Stop stop) async {
    final current = await future;
    final next =
        current.map((s) => s.id == stop.id ? stop : s).toList(growable: false);
    state = AsyncData(next);
    await _repo.save(next);
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final current = [...await future];
    if (oldIndex < newIndex) newIndex -= 1;
    final moved = current.removeAt(oldIndex);
    current.insert(newIndex, moved);
    state = AsyncData(List.unmodifiable(current));
    await _repo.save(current);
  }

  Future<void> applyOptimizedOrder(List<int> order) async {
    final current = await future;
    final next = [for (final i in order) current[i]];
    state = AsyncData(List.unmodifiable(next));
    await _repo.save(next);
  }

  Future<void> clear() async {
    state = const AsyncData([]);
    await _repo.save(const []);
  }
}
