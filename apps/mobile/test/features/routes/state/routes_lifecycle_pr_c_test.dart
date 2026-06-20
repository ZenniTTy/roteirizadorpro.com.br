// test/features/routes/state/routes_lifecycle_pr_c_test.dart
//
// TDD red — PR-C sub-unidade 1: novos métodos de lifecycle no provider Routes
// e modificação de applyOptimization.
//
// Comportamentos pinados:
//  1. confirmRoute(id) → confirmed:true, optimizationAcknowledged:true (demais preservados)
//  2. confirmRoute(id) com id inexistente → no-op
//  3. editRoute(id) → confirmed:false (preserva optimization e optimizationAcknowledged)
//  4. skipOptimization(id) → confirmed:true, optimizationAcknowledged:true,
//     optimization permanece creating → isReadyToRun=true && hasPendingOptimization=true
//  5. discardOptimizationEdits(id) → restaura stops do snapshot + optimization=optimized
//     + optimizedAt não-nulo
//  6. applyOptimization modifica: grava optimizedStopsSnapshot + optimizedAt não-nulo
//  7. mutators (addStop/removeStop/updateStop/markStopForDeferredRemoval) numa rota
//     optimization=optimized + !confirmed → vira editing + optimizedAt=null (G3)
//  8. mutators em rota DRAFT → não transitam para editing
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/domain/optimization/route_optimizer.dart';
import 'package:roteirizador_pro/features/routes/domain/optimization_state.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';
import 'package:roteirizador_pro/features/routes/state/routes_provider.dart';
import '../_helpers/fake_package_photo_store.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Stop _stop(String id) => Stop(
      id: id,
      lat: -23.5,
      lng: -46.6,
      streetName: 'Rua $id',
      fullAddress: 'Rua $id, 1 — SP',
    );

ProviderContainer _container() {
  final c = ProviderContainer(
    overrides: [
      packagePhotoStoreProvider.overrideWithValue(FakePackagePhotoStore()),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

/// Cria rota, adiciona stops e aplica otimização — põe a rota em PRE-CONFIRM.
String _setupOptimizedRoute(
  ProviderContainer c, {
  List<Stop> stops = const [],
}) {
  final n = c.read(routesProvider.notifier);
  final id = n.createRoute(date: DateTime(2026, 6, 20));
  for (final s in stops) {
    n.addStop(id, s);
  }
  if (stops.isNotEmpty) {
    n.applyOptimization(
      id,
      RouteOptimizationResult(
        orderedStops: stops,
        totalDurationMinutes: 10,
        totalDistanceMeters: 1000,
      ),
    );
  }
  return id;
}

// ---------------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------------

void main() {
  // ─── 1. confirmRoute ───────────────────────────────────────────────────────
  group('confirmRoute (PR-C)', () {
    test(
      'confirmed=true e optimizationAcknowledged=true após confirmRoute',
      () {
        final c = _container();
        final n = c.read(routesProvider.notifier);
        final id = _setupOptimizedRoute(
          c,
          stops: [_stop('A'), _stop('B')],
        );

        n.confirmRoute(id);

        final route = c.read(routesProvider).firstWhere((r) => r.id == id);
        expect(route.routeState.confirmed, isTrue);
        expect(route.routeState.optimizationAcknowledged, isTrue);
      },
    );

    test(
      'confirmRoute preserva optimization e outros flags (não reseta)',
      () {
        final c = _container();
        final n = c.read(routesProvider.notifier);
        final id = _setupOptimizedRoute(
          c,
          stops: [_stop('A')],
        );
        // rota deve estar optimized após applyOptimization
        final before = c.read(routesProvider).firstWhere((r) => r.id == id);
        expect(before.routeState.optimization, OptimizationState.optimized);

        n.confirmRoute(id);

        final after = c.read(routesProvider).firstWhere((r) => r.id == id);
        expect(after.routeState.optimization, OptimizationState.optimized);
        expect(after.routeState.started, isFalse);
        expect(after.routeState.completed, isFalse);
      },
    );

    test(
      'confirmRoute com id inexistente é no-op — state inalterado',
      () {
        final c = _container();
        final before = c.read(routesProvider);
        c.read(routesProvider.notifier).confirmRoute('id-fantasma');
        final after = c.read(routesProvider);
        expect(after.length, before.length);
      },
    );

    test(
      'após confirmRoute a rota tem isReadyToRun=true',
      () {
        final c = _container();
        final n = c.read(routesProvider.notifier);
        final id = _setupOptimizedRoute(
          c,
          stops: [_stop('A'), _stop('B')],
        );
        n.confirmRoute(id);
        final route = c.read(routesProvider).firstWhere((r) => r.id == id);
        expect(route.routeState.isReadyToRun, isTrue);
      },
    );
  });

  // ─── 2. editRoute ──────────────────────────────────────────────────────────
  group('editRoute (PR-C)', () {
    test(
      'editRoute seta confirmed=false (des-confirma — G2)',
      () {
        final c = _container();
        final n = c.read(routesProvider.notifier);
        final id = _setupOptimizedRoute(
          c,
          stops: [_stop('A'), _stop('B')],
        );
        n.confirmRoute(id);
        // sanity: confirmado
        expect(
          c
              .read(routesProvider)
              .firstWhere((r) => r.id == id)
              .routeState
              .confirmed,
          isTrue,
        );

        n.editRoute(id);

        final after = c.read(routesProvider).firstWhere((r) => r.id == id);
        expect(after.routeState.confirmed, isFalse);
      },
    );

    test(
      'editRoute preserva optimization e optimizationAcknowledged',
      () {
        final c = _container();
        final n = c.read(routesProvider.notifier);
        final id = _setupOptimizedRoute(
          c,
          stops: [_stop('A')],
        );
        n.confirmRoute(id);
        n.editRoute(id);

        final after = c.read(routesProvider).firstWhere((r) => r.id == id);
        expect(after.routeState.optimization, OptimizationState.optimized);
        expect(after.routeState.optimizationAcknowledged, isTrue);
      },
    );

    test(
      'após editRoute a rota volta ao estado PRE-CONFIRM (isPreConfirm=true)',
      () {
        final c = _container();
        final n = c.read(routesProvider.notifier);
        final id = _setupOptimizedRoute(
          c,
          stops: [_stop('A'), _stop('B')],
        );
        n.confirmRoute(id);
        n.editRoute(id);

        final after = c.read(routesProvider).firstWhere((r) => r.id == id);
        expect(after.routeState.isPreConfirm, isTrue);
      },
    );
  });

  // ─── 3. skipOptimization ───────────────────────────────────────────────────
  group('skipOptimization (PR-C)', () {
    test(
      'skipOptimization confirma a rota mas mantém optimization=creating',
      () {
        final c = _container();
        final n = c.read(routesProvider.notifier);
        final id = n.createRoute(date: DateTime(2026, 6, 20));

        n.skipOptimization(id);

        final route = c.read(routesProvider).firstWhere((r) => r.id == id);
        expect(route.routeState.confirmed, isTrue);
        expect(route.routeState.optimizationAcknowledged, isTrue);
        expect(route.routeState.optimization, OptimizationState.creating);
      },
    );

    test(
      'após skipOptimization: isReadyToRun=true E hasPendingOptimization=true '
      '(skip-path — banner "Otimização pendente" deve aparecer)',
      () {
        final c = _container();
        final n = c.read(routesProvider.notifier);
        final id = n.createRoute(date: DateTime(2026, 6, 20));

        n.skipOptimization(id);

        final route = c.read(routesProvider).firstWhere((r) => r.id == id);
        expect(route.routeState.isReadyToRun, isTrue);
        expect(route.routeState.hasPendingOptimization, isTrue);
      },
    );
  });

  // ─── 4. discardOptimizationEdits ───────────────────────────────────────────
  group('discardOptimizationEdits (PR-C)', () {
    test(
      'restaura stops do snapshot, optimization=optimized e optimizedAt não-nulo',
      () {
        final c = _container();
        final n = c.read(routesProvider.notifier);
        final snapshotStops = [_stop('A'), _stop('B'), _stop('C')];
        // Cria rota e otimiza (snapshot=[A,B,C])
        final id = _setupOptimizedRoute(c, stops: snapshotStops);

        // Simula edição: adiciona stop D → entra em editing
        n.addStop(id, _stop('D'));
        // Neste ponto a rota deve estar editing (G3) — não testamos isso aqui,
        // esse comportamento é testado no grupo de mutators abaixo.

        // Descarta as alterações
        n.discardOptimizationEdits(id);

        final route = c.read(routesProvider).firstWhere((r) => r.id == id);
        // stops voltam ao snapshot [A,B,C]
        expect(
          route.stops.map((s) => s.id).toList(),
          ['A', 'B', 'C'],
        );
        // optimization volta optimized
        expect(route.routeState.optimization, OptimizationState.optimized);
        // optimizedAt deve ser não-nulo (métricas recuperadas do snapshot)
        expect(route.routeState.optimizedAt, isNotNull);
      },
    );
  });

  // ─── 5. applyOptimization grava snapshot e optimizedAt ────────────────────
  group('applyOptimization — modificação PR-C', () {
    test(
      'applyOptimization grava optimizedStopsSnapshot com os stops ordenados',
      () {
        final c = _container();
        final n = c.read(routesProvider.notifier);
        final id = n.createRoute(date: DateTime(2026, 6, 20));
        n.addStop(id, _stop('X'));
        n.addStop(id, _stop('Y'));

        final ordered = [
          _stop('Y').copyWith(deliveryId: 'A1'),
          _stop('X').copyWith(deliveryId: 'A2'),
        ];
        n.applyOptimization(
          id,
          RouteOptimizationResult(
            orderedStops: ordered,
            totalDurationMinutes: 12,
            totalDistanceMeters: 3000,
          ),
        );

        final route = c.read(routesProvider).firstWhere((r) => r.id == id);
        expect(route.optimizedStopsSnapshot, isNotNull);
        expect(
          route.optimizedStopsSnapshot!.map((s) => s.id).toList(),
          ['Y', 'X'],
        );
      },
    );

    test(
      'applyOptimization grava optimizedAt não-nulo',
      () {
        final c = _container();
        final n = c.read(routesProvider.notifier);
        final id = n.createRoute(date: DateTime(2026, 6, 20));
        n.addStop(id, _stop('P'));

        n.applyOptimization(
          id,
          RouteOptimizationResult(
            orderedStops: [_stop('P').copyWith(deliveryId: 'A1')],
            totalDurationMinutes: 5,
            totalDistanceMeters: 500,
          ),
        );

        final route = c.read(routesProvider).firstWhere((r) => r.id == id);
        expect(route.routeState.optimizedAt, isNotNull);
      },
    );
  });

  // ─── 6. Transição editing via mutators (G3) ────────────────────────────────
  group('mutators → editing quando rota optimized+!confirmed (G3) (PR-C)', () {
    test(
      'addStop em rota optimized+!confirmed → optimization=editing + optimizedAt=null',
      () {
        final c = _container();
        final n = c.read(routesProvider.notifier);
        final id = _setupOptimizedRoute(
          c,
          stops: [_stop('A'), _stop('B')],
        );
        // sanity: em PRE-CONFIRM (optimized, !confirmed)
        final pre = c.read(routesProvider).firstWhere((r) => r.id == id);
        expect(pre.routeState.optimization, OptimizationState.optimized);
        expect(pre.routeState.confirmed, isFalse);

        n.addStop(id, _stop('C'));

        final after = c.read(routesProvider).firstWhere((r) => r.id == id);
        expect(after.routeState.optimization, OptimizationState.editing);
        expect(after.routeState.optimizedAt, isNull);
      },
    );

    test(
      'removeStop em rota optimized+!confirmed → optimization=editing + optimizedAt=null',
      () {
        final c = _container();
        final n = c.read(routesProvider.notifier);
        final id = _setupOptimizedRoute(
          c,
          stops: [_stop('A'), _stop('B')],
        );

        n.removeStop(id, 'A');

        final after = c.read(routesProvider).firstWhere((r) => r.id == id);
        expect(after.routeState.optimization, OptimizationState.editing);
        expect(after.routeState.optimizedAt, isNull);
      },
    );

    test(
      'updateStop em rota optimized+!confirmed → optimization=editing + optimizedAt=null',
      () {
        final c = _container();
        final n = c.read(routesProvider.notifier);
        final id = _setupOptimizedRoute(
          c,
          stops: [_stop('A'), _stop('B')],
        );

        n.updateStop(id, _stop('A').copyWith(notes: 'editado'));

        final after = c.read(routesProvider).firstWhere((r) => r.id == id);
        expect(after.routeState.optimization, OptimizationState.editing);
        expect(after.routeState.optimizedAt, isNull);
      },
    );

    test(
      'markStopForDeferredRemoval em rota optimized+!confirmed → optimization=editing',
      () {
        final c = _container();
        final n = c.read(routesProvider.notifier);
        final id = _setupOptimizedRoute(
          c,
          stops: [_stop('A'), _stop('B')],
        );

        n.markStopForDeferredRemoval(id, 'A');

        final after = c.read(routesProvider).firstWhere((r) => r.id == id);
        expect(after.routeState.optimization, OptimizationState.editing);
        expect(after.routeState.optimizedAt, isNull);
      },
    );

    test(
      'addStop em rota DRAFT (creating) NÃO transita para editing — '
      'mutator normal sem mudança de optimization',
      () {
        final c = _container();
        final n = c.read(routesProvider.notifier);
        final id = n.createRoute(date: DateTime(2026, 6, 20));
        // rota draft, sem otimizar

        n.addStop(id, _stop('A'));

        final after = c.read(routesProvider).firstWhere((r) => r.id == id);
        expect(after.routeState.optimization, OptimizationState.creating);
        expect(after.routeState.isDraft, isTrue);
      },
    );

    test(
      'isEditing=true após addStop em rota optimized (getter derivado)',
      () {
        final c = _container();
        final n = c.read(routesProvider.notifier);
        final id = _setupOptimizedRoute(
          c,
          stops: [_stop('A'), _stop('B')],
        );

        n.addStop(id, _stop('C'));

        final after = c.read(routesProvider).firstWhere((r) => r.id == id);
        expect(after.routeState.isEditing, isTrue);
      },
    );
  });
}
