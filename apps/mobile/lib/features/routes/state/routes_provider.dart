import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/route.dart';
import '../domain/stop.dart';

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

  /// Cria uma nova rota draft com nome opcional + data e retorna o ID gerado.
  /// O caller usa o ID retornado pra navegar pra tela ativa da rota nova
  /// (Riverpod 3 idiomatic: notifier actions podem retornar valores).
  String createRoute({String? name, required DateTime date}) {
    final id = 'route-${DateTime.now().millisecondsSinceEpoch}';
    final route = Route(
      id: id,
      date: date,
      status: RouteStatus.draft,
      name: name,
    );
    state = [...state, route];
    return id;
  }

  /// Atualiza apenas metadata (nome + data) de uma rota existente.
  /// Usado pelo modo edit do wizard ("Definir nome e data" do popup 3-dot).
  /// NÃO toca em `stops` nem `status` — escopo limitado per inventário §10.3.
  ///
  /// `name: null` representa "rota volta a usar o nome auto-gerado pelo
  /// placeholder" — não pode usar `copyWith(name: null)` aqui porque o
  /// pattern `name ?? this.name` do copyWith faria o null preservar o nome
  /// atual em vez de limpá-lo. Construímos um Route novo manualmente.
  void updateRouteMeta(String id, {String? name, required DateTime date}) {
    state = state.map((r) {
      if (r.id != id) return r;
      return Route(
        id: r.id,
        date: date,
        status: r.status,
        name: name,
        stops: r.stops,
      );
    }).toList();
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

  void addStop(String routeId, Stop stop) {
    state = state.map((r) {
      if (r.id == routeId) {
        final newStops = [...r.stops, stop];
        return r.copyWith(stops: newStops);
      }
      return r;
    }).toList();
  }
}
