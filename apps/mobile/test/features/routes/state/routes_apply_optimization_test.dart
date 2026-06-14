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
      _stop('A').copyWith(deliveryId: 'A2')
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
