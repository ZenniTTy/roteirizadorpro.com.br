import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/route_defaults_repository.dart';
import '../domain/route_defaults.dart';

part 'route_defaults_controller.g.dart';

/// Singleton repository binding. Override in tests to inject an
/// `InMemorySharedPreferencesAsync`-backed instance.
@Riverpod(keepAlive: true)
RouteDefaultsRepository routeDefaultsRepository(Ref ref) {
  return RouteDefaultsRepository(SharedPreferencesAsync());
}

/// User's saved route defaults envelope. Singleton across the app — there is
/// only one user, only one envelope.
///
/// `keepAlive: true` because callers (wizard, route-details screen) read this
/// asynchronously at navigation boundaries; dropping it would re-read
/// SharedPrefs every time.
@Riverpod(keepAlive: true)
class RouteDefaultsController extends _$RouteDefaultsController {
  @override
  Future<RouteDefaults> build() async {
    final repo = ref.read(routeDefaultsRepositoryProvider);
    return repo.read();
  }

  /// Merges [patch] into the current state — only non-null sub-states from
  /// [patch] override; `firstRoute` and `schemaVersion` always come from
  /// [patch]. Persists the result through the repository.
  Future<void> merge(RouteDefaults patch) async {
    final current = await future;
    final next = current.copyWith(
      firstRoute: patch.firstRoute,
      schemaVersion: patch.schemaVersion,
      startLocation: patch.startLocation ?? current.startLocation,
      timeStart: patch.timeStart ?? current.timeStart,
      timeEnd: patch.timeEnd ?? current.timeEnd,
      destination: patch.destination ?? current.destination,
      breaks: patch.breaks.isNotEmpty ? patch.breaks : current.breaks,
    );
    await ref.read(routeDefaultsRepositoryProvider).write(next);
    state = AsyncData(next);
  }

  /// Flips [RouteDefaults.firstRoute] off and persists. Idempotent.
  Future<void> markFirstRouteComplete() async {
    final current = await future;
    if (!current.firstRoute) return;
    final next = current.copyWith(firstRoute: false);
    await ref.read(routeDefaultsRepositoryProvider).write(next);
    state = AsyncData(next);
  }
}
