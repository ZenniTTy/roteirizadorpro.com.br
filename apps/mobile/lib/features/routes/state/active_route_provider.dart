import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/active_route_repository.dart';
import 'routes_provider.dart';

part 'active_route_provider.g.dart';

/// Holds the id of the route whose shell is currently displayed.
/// `null` means unresolved — `resolveActiveRoute()` (called on shell boot)
/// guarantees a non-null id before the user can act, mirroring Spoke's
/// `ValidateActiveRoute` (which never leaves the editor without an active
/// route — persisted `activeRouteRef`, else most-recent, else create).
@Riverpod(keepAlive: true)
class ActiveRouteId extends _$ActiveRouteId {
  @override
  String? build() => null;

  /// Selects [id] as the active route AND persists it (fire-and-forget) so a
  /// restart restores the same route. Passing null clears both.
  void setActiveRoute(String? id) {
    state = id;
    // Fire-and-forget: the UI never blocks on the disk write; a failed write
    // only costs a wrong restore next launch (then the fallback kicks in).
    ref.read(activeRouteRepositoryProvider).write(id);
  }

  /// Boot resolver (Spoke `ValidateActiveRoute` parity). No-op when a route is
  /// already active (live selection wins). Otherwise: restore the persisted id
  /// if it still resolves; else pick the most-recent route by `date`; else
  /// create a fresh route. Always leaves [state] non-null when ≥1 route can
  /// exist. Writes the resolved id back so the next launch restores it.
  Future<void> resolveActiveRoute() async {
    if (state != null) return;

    final routes = ref.read(routesProvider);
    final persisted = await ref.read(activeRouteRepositoryProvider).read();

    if (persisted != null && routes.any((r) => r.id == persisted)) {
      setActiveRoute(persisted);
      return;
    }

    if (routes.isNotEmpty) {
      // Mais recente por `date`; no EMPATE de data, prefere a rota NÃO
      // completada (a que o motorista provavelmente está rodando) à
      // encerrada — senão, no 1º boot com 2 rotas do mesmo dia, o app cairia
      // numa rota concluída/vazia em vez da ativa. (Proxy de Slice 2: o Spoke
      // usa `lastEdited`; aqui usamos date + este desempate até o backend.)
      final mostRecent = routes.reduce((a, b) {
        if (a.date.isAfter(b.date)) return a;
        if (b.date.isAfter(a.date)) return b;
        // Datas iguais: a não-completada vence; se ambas iguais nesse critério,
        // mantém a primeira (determinístico).
        return b.routeState.completed && !a.routeState.completed ? a : b;
      });
      setActiveRoute(mostRecent.id);
      return;
    }

    // No routes at all → create one (auto-name = weekday placeholder, ADR-0010
    // original microcopy; NOT Spoke's "Minha primeira rota" verbatim).
    final newId =
        ref.read(routesProvider.notifier).createRoute(date: DateTime.now());
    setActiveRoute(newId);
  }
}
