import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/route.dart';

part 'routes_provider.g.dart';

/// In-memory seed of routes for Slice 2.
/// Real CRUD + backend persistence land in Slice 3 along with the wizard.
@Riverpod(keepAlive: true)
class Routes extends _$Routes {
  @override
  List<Route> build() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final lastWeek = today.subtract(const Duration(days: 9));

    return [
      Route(
        id: 'seed-today-1',
        date: today,
        status: RouteStatus.running,
        name: null,
      ),
      Route(
        id: 'seed-today-2',
        date: today,
        status: RouteStatus.draft,
        name: null,
      ),
      Route(
        id: 'seed-yesterday-1',
        date: yesterday,
        status: RouteStatus.completed,
        name: null,
      ),
      Route(
        id: 'seed-lastweek-1',
        date: lastWeek,
        status: RouteStatus.completed,
        name: null,
      ),
    ];
  }

  void addRoute(Route r) {
    state = [...state, r];
  }

  void removeRoute(String id) {
    state = state.where((r) => r.id != id).toList();
  }

  void duplicateRoute(String id) {
    final existing = state.firstWhere((r) => r.id == id);
    final duplicated = Route(
      id: 'dup-${DateTime.now().millisecondsSinceEpoch}',
      date: existing.date,
      status: RouteStatus.draft,
      name: '${existing.displayName()} (Cópia)',
    );
    state = [...state, duplicated];
  }
}
