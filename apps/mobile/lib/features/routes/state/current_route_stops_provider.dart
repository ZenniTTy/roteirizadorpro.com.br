import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/stop.dart';
import 'active_route_provider.dart';
import 'routes_provider.dart';

part 'current_route_stops_provider.g.dart';

/// The list of stops on the currently-active route, or empty if there is no
/// active route or the active id doesn't resolve.
///
/// Used by `addStopUiStateProvider` to compute Section A ("Desta rota") of the
/// results list (Spoke parity §11.4 amendment 2).
@riverpod
List<Stop> currentRouteStops(Ref ref) {
  final id = ref.watch(activeRouteIdProvider);
  if (id == null) return const [];
  final routes = ref.watch(routesProvider);
  return routes
      .where((r) => r.id == id)
      .expand((r) => r.stops)
      .toList(growable: false);
}
