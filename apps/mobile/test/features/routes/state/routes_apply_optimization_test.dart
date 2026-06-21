// test/features/routes/state/routes_apply_optimization_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roteirizador_pro/features/routes/domain/optimization_state.dart';
import 'package:roteirizador_pro/features/routes/domain/optimization/route_optimizer.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';
import 'package:roteirizador_pro/features/routes/state/routes_provider.dart';

Stop _stop(String id, {bool pendingRemoval = false}) => Stop(
      id: id,
      lat: 0,
      lng: 0,
      streetName: id,
      fullAddress: id,
      pendingRemoval: pendingRemoval,
    );

void main() {
  test(
      'applyOptimization grava routeState=optimized + stops reordenados + métricas',
      () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final notifier = c.read(routesProvider.notifier);
    final id = notifier.createRoute(date: DateTime(2026, 6, 14));
    notifier.addStop(id, _stop('A'));
    notifier.addStop(id, _stop('B'));

    final ordered = [
      _stop('B').copyWith(deliveryId: 'A1'),
      _stop('A').copyWith(deliveryId: 'A2'),
    ];
    notifier.applyOptimization(
      id,
      RouteOptimizationResult(
        orderedStops: ordered,
        totalDurationMinutes: 18,
        totalDistanceMeters: 5200,
      ),
    );

    final route = c.read(routesProvider).firstWhere((r) => r.id == id);
    expect(route.routeState.optimization, OptimizationState.optimized);
    expect(route.routeState.isPreConfirm, isTrue);
    expect(route.totalDurationMinutes, 18);
    expect(route.totalDistanceMeters, 5200);
    expect(route.stops.map((s) => s.id).toList(), ['B', 'A']);
    expect(route.stops.first.deliveryId, 'A1');
  });

  test(
      'applyOptimization crava estimatedArrival = horário + offset por parada '
      '(ETA local da step list)', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final notifier = c.read(routesProvider.notifier);
    final id = notifier.createRoute(date: DateTime(2026, 6, 14));
    notifier.addStop(id, _stop('A'));
    notifier.addStop(id, _stop('B'));

    final before = DateTime.now();
    notifier.applyOptimization(
      id,
      RouteOptimizationResult(
        orderedStops: [_stop('A'), _stop('B')],
        totalDurationMinutes: 18,
        totalDistanceMeters: 5200,
        stopArrivalOffsets: const [
          Duration(minutes: 5),
          Duration(minutes: 12),
        ],
      ),
    );
    final after = DateTime.now();

    final route = c.read(routesProvider).firstWhere((r) => r.id == id);
    final etaA = route.stops[0].estimatedArrival!;
    final etaB = route.stops[1].estimatedArrival!;
    // ETA = horário da otimização (entre before e after) + offset da parada.
    expect(etaA.isAfter(before.add(const Duration(minutes: 5, seconds: -1))),
        isTrue);
    expect(etaA.isBefore(after.add(const Duration(minutes: 5, seconds: 1))),
        isTrue);
    // B chega 7 min depois de A (12 − 5), monotônico crescente.
    expect(etaB.difference(etaA), const Duration(minutes: 7));
    // O snapshot otimizado carrega o mesmo ETA (revert do "Descartar" é fiel).
    expect(route.optimizedStopsSnapshot![1].estimatedArrival, etaB);
  });

  test('applyOptimization sem offsets deixa estimatedArrival null (degrada)',
      () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final notifier = c.read(routesProvider.notifier);
    final id = notifier.createRoute(date: DateTime(2026, 6, 14));
    notifier.addStop(id, _stop('A'));
    notifier.applyOptimization(
      id,
      RouteOptimizationResult(
        orderedStops: [_stop('A')],
        totalDurationMinutes: 5,
        totalDistanceMeters: 1000,
      ),
    );
    final route = c.read(routesProvider).firstWhere((r) => r.id == id);
    expect(route.stops.first.estimatedArrival, isNull);
  });

  test('markStopForDeferredRemoval marca pendingRemoval sem remover (G5)', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final notifier = c.read(routesProvider.notifier);
    final id = notifier.createRoute(date: DateTime(2026, 6, 14));
    notifier.addStop(id, _stop('A'));
    notifier.markStopForDeferredRemoval(id, 'A');

    final route = c.read(routesProvider).firstWhere((r) => r.id == id);
    expect(route.stops, hasLength(1));
    expect(route.stops.first.pendingRemoval, isTrue);
  });
}
