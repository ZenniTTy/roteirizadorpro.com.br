import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/route_state.dart';
import 'active_route_provider.dart';
import 'routes_provider.dart';

part 'active_route_state_provider.g.dart';

/// `RouteState` da rota ativa (null quando não há rota ativa ou o id é obsoleto).
/// O shell observa ESTE provider via `.select` para alternar entre o sheet DRAFT
/// e a `PreConfirmView` sem reconstruir a cada mudança de stops. Espelha o Spoke,
/// onde o EditRouteFragment renderiza por estado (não por tela separada).
@riverpod
RouteState? activeRouteState(Ref ref) {
  final id = ref.watch(activeRouteIdProvider);
  if (id == null) return null;
  final routes = ref.watch(routesProvider);
  return routes.where((r) => r.id == id).firstOrNull?.routeState;
}
