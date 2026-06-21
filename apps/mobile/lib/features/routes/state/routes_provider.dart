import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../data/package_photo_store.dart';
import '../domain/optimization/route_optimizer.dart';
import '../domain/optimization_state.dart';
import '../domain/route.dart';
import '../domain/route_state.dart';
import '../domain/stop.dart';

part 'routes_provider.g.dart';

/// Store de fotos de pacote — overridável nos testes (T4/H16).
@Riverpod(keepAlive: true)
PackagePhotoStore packagePhotoStore(Ref ref) => PackagePhotoStore.production();

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
        routeState: const RouteState(
          optimization: OptimizationState.optimized,
          confirmed: true,
          started: true,
        ),
        name: null,
      ),
      Route(
        id: 'seed-today-2',
        date: today,
        name: null,
      ),
      Route(
        id: 'seed-yesterday-1',
        date: yesterday,
        routeState: const RouteState(completed: true),
        name: null,
      ),
      Route(
        id: 'seed-lastweek-1',
        date: lastWeek,
        routeState: const RouteState(completed: true),
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
        routeState: r.routeState,
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
      name: '${existing.displayName()} (Cópia)',
    );
    state = [...state, duplicated];
  }

  void addStop(String routeId, Stop stop) {
    state = state.map((r) {
      if (r.id == routeId) {
        final newStops = [...r.stops, stop];
        return r.copyWith(
          stops: newStops,
          routeState: _invalidateOptimizationOnEdit(r.routeState),
        );
      }
      return r;
    }).toList();
  }

  /// Substitui o stop POR ID na rota, preservando posição e demais stops (T4/H9).
  /// Stop inexistente → no-op.
  void updateStop(String routeId, Stop stop) {
    state = [
      for (final r in state)
        r.id == routeId
            ? r.copyWith(
                stops: [
                  for (final s in r.stops) s.id == stop.id ? stop : s,
                ],
                routeState: _invalidateOptimizationOnEdit(r.routeState),
              )
            : r,
    ];
  }

  /// Remove o stop e apaga suas fotos via PackagePhotoStore.deleteFor (T4).
  /// O delete de I/O é fire-and-forget — o estado nunca bloqueia em I/O;
  /// falhas degradam com debugPrint dentro do store (H15).
  void removeStop(String routeId, String stopId) {
    final route = state.where((r) => r.id == routeId).firstOrNull;
    if (route == null || !route.stops.any((s) => s.id == stopId)) return;
    state = [
      for (final r in state)
        r.id == routeId
            ? r.copyWith(
                stops: r.stops.where((s) => s.id != stopId).toList(),
                routeState: _invalidateOptimizationOnEdit(r.routeState),
              )
            : r,
    ];
    unawaited(ref.read(packagePhotoStoreProvider).deleteFor(routeId, stopId));
  }

  /// Aplica o resultado da otimização à rota: troca para o estado otimizado
  /// (PRE-CONFIRM), substitui os stops pela ordem do solver (com deliveryId já
  /// atribuído) e grava as métricas. Espelha o efeito de `optimise` no Spoke
  /// (RouteState → OPTIMIZED). Sem backend — Slice 2.
  void applyOptimization(String routeId, RouteOptimizationResult result) {
    final now = DateTime.now();
    // Crava o ETA absoluto por parada: horário da otimização + offset de viagem
    // acumulado (Slice 2, aproximação local — ver Stop.estimatedArrival). Sem
    // offsets (solver não computou) → ETA fica null (step list sem hora).
    final stamped = <Stop>[
      for (var i = 0; i < result.orderedStops.length; i++)
        result.orderedStops[i].copyWith(
          estimatedArrival: i < result.stopArrivalOffsets.length
              ? now.add(result.stopArrivalOffsets[i])
              : null,
        ),
    ];
    state = [
      for (final r in state)
        if (r.id == routeId)
          r.copyWith(
            routeState: r.routeState.copyWith(
              optimization: OptimizationState.optimized,
              optimizing: false,
              optimizedAt: now,
              optimizationAttemptedAt: now,
            ),
            stops: stamped,
            // Snapshot da versão otimizada — o "Descartar alterações" do PR-C
            // reverte os stops pra cá quando o usuário edita e desiste (G3).
            optimizedStopsSnapshot: stamped,
            totalDurationMinutes: result.totalDurationMinutes,
            totalDistanceMeters: result.totalDistanceMeters,
          )
        else
          r,
    ];
  }

  // ── PR-C lifecycle ────────────────────────────────────────────────────────

  /// "Confirmar" do PRE-CONFIRM → Ready-to-Run: confirmed:true,
  /// optimizationAcknowledged:true. No-op se [routeId] não existir.
  void confirmRoute(String routeId) {
    state = [
      for (final r in state)
        if (r.id == routeId)
          r.copyWith(
            routeState: r.routeState.copyWith(
              confirmed: true,
              optimizationAcknowledged: true,
            ),
          )
        else
          r,
    ];
  }

  /// "Editar" do Ready-to-Run → des-confirma (confirmed:false), preservando
  /// optimization e optimizationAcknowledged. Em rota otimizada volta ao
  /// PRE-CONFIRM; em rota skip (creating) volta ao DRAFT (G2).
  void editRoute(String routeId) {
    state = [
      for (final r in state)
        if (r.id == routeId)
          r.copyWith(
            routeState: r.routeState.copyWith(confirmed: false),
          )
        else
          r,
    ];
  }

  /// "Pular otimização" (diálogo de erro) → Ready-to-Run sem otimizar:
  /// confirmed:true, optimizationAcknowledged:true; optimization permanece
  /// creating. Resultado: isReadyToRun=true && hasPendingOptimization=true
  /// (banner "Otimização pendente").
  void skipOptimization(String routeId) {
    state = [
      for (final r in state)
        if (r.id == routeId)
          r.copyWith(
            routeState: r.routeState.copyWith(
              confirmed: true,
              optimizationAcknowledged: true,
            ),
          )
        else
          r,
    ];
  }

  /// "Descartar alterações" → reverte os stops pra última versão otimizada
  /// (optimizedStopsSnapshot) e volta optimization:optimized + optimizedAt.
  /// No-op (mantém stops atuais) se não houver snapshot.
  void discardOptimizationEdits(String routeId) {
    state = [
      for (final r in state)
        if (r.id == routeId)
          r.copyWith(
            stops: r.optimizedStopsSnapshot ?? r.stops,
            routeState: r.routeState.copyWith(
              optimization: OptimizationState.optimized,
              optimizedAt: DateTime.now(),
            ),
          )
        else
          r,
    ];
  }

  /// G3 — quando os stops mudam numa rota OTIMIZADA ainda não confirmada, a
  /// otimização é invalidada: entra em `editing` e zera `optimizedAt` (a métrica
  /// "X min" some até re-otimizar). Espelha o `UpdateRoute` do Spoke. Fora desse
  /// estado (DRAFT, confirmada, já editing) devolve o mesmo estado.
  RouteState _invalidateOptimizationOnEdit(RouteState s) {
    if (s.optimization == OptimizationState.optimized && !s.confirmed) {
      return s.copyWith(
        optimization: OptimizationState.editing,
        optimizedAt: null,
      );
    }
    return s;
  }

  /// G5 — marca a parada para remoção DEFERIDA (rota já otimizada): não remove
  /// agora; a parada some na próxima otimização (o solver exclui pendingRemoval).
  /// Em rota DRAFT a remoção continua imediata via removeStop (Área 6). No-op se
  /// a parada não existir.
  void markStopForDeferredRemoval(String routeId, String stopId) {
    state = [
      for (final r in state)
        if (r.id == routeId)
          r.copyWith(
            stops: [
              for (final s in r.stops)
                s.id == stopId ? s.copyWith(pendingRemoval: true) : s,
            ],
            routeState: _invalidateOptimizationOnEdit(r.routeState),
          )
        else
          r,
    ];
  }

  /// Duplica o stop: insere a cópia LOGO APÓS a original com id novo,
  /// status pendente e deliveryId/positionInRoute zerados; retorna o id novo
  /// sincronamente (o caller navega — H11). As fotos são copiadas em
  /// background (arquivos duplicados, paths nunca compartilhados — H16) e o
  /// state recebe o patch de photoPaths quando o copyAll terminar.
  /// Retorna null quando [stopId] não existe na rota.
  String? duplicateStop(String routeId, String stopId) {
    final route = state.where((r) => r.id == routeId).firstOrNull;
    if (route == null) return null;
    final stopIdx = route.stops.indexWhere((s) => s.id == stopId);
    if (stopIdx == -1) return null;

    final original = route.stops[stopIdx];
    final newId = const Uuid().v4();
    final duplicate = original.copyWith(
      id: newId,
      status: StopStatus.pending,
      deliveryId: null,
      positionInRoute: null,
      photoPaths: const [],
    );
    final newStops = [...route.stops]..insert(stopIdx + 1, duplicate);
    state = [
      for (final r in state) r.id == routeId ? r.copyWith(stops: newStops) : r,
    ];

    final store = ref.read(packagePhotoStoreProvider);
    unawaited(
      store.copyAll(routeId, stopId, newId).then((paths) {
        if (paths.isEmpty) return;
        final currentRoute = state.where((r) => r.id == routeId).firstOrNull;
        final currentDup =
            currentRoute?.stops.where((s) => s.id == newId).firstOrNull;
        // Duplicata removida na janela do copy → fotos órfãs aceitas (H16).
        if (currentDup == null) return;
        updateStop(routeId, currentDup.copyWith(photoPaths: paths));
      }),
    );
    return newId;
  }
}
