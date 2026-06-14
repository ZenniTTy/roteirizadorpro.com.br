// test/features/routes/state/optimization_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roteirizador_pro/features/routes/domain/optimize_direction.dart';
import 'package:roteirizador_pro/features/routes/domain/optimize_type.dart';
import 'package:roteirizador_pro/features/routes/domain/optimization/route_optimizer.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';
import 'package:roteirizador_pro/features/routes/state/optimization_controller.dart';

// Fake solver determinístico: devolve as paradas na ordem recebida.
class _FakeOptimizer implements RouteOptimizer {
  @override
  RouteOptimizationResult optimize({
    required GeoPoint start,
    GeoPoint? end,
    required List<Stop> stops,
    required OptimizeType type,
    OptimizeDirection? direction,
  }) =>
      RouteOptimizationResult(
        orderedStops: stops,
        totalDurationMinutes: 18,
        totalDistanceMeters: 5200,
      );
}

Stop _stop(String id) =>
    Stop(id: id, lat: 0, lng: 0, streetName: id, fullAddress: id);

ProviderContainer _container() => ProviderContainer(overrides: [
      routeOptimizerProvider.overrideWithValue(_FakeOptimizer()),
    ]);

void main() {
  test(
      'guard de mínimo: < 1 parada => OptimizationOutcome.notEnoughStops, solver não roda',
      () async {
    final c = _container();
    addTearDown(c.dispose);
    final outcome =
        await c.read(optimizationControllerProvider.notifier).optimize(
              start: const GeoPoint(0, 0),
              stops: const [],
              type: OptimizeType.restartRoute,
            );
    expect(outcome, isA<NotEnoughStops>());
  });

  test('com paradas suficientes => OptimizationOutcome.success com métricas',
      () async {
    final c = _container();
    addTearDown(c.dispose);
    final outcome =
        await c.read(optimizationControllerProvider.notifier).optimize(
              start: const GeoPoint(0, 0),
              stops: [_stop('A'), _stop('B')],
              type: OptimizeType.restartRoute,
            );
    expect(outcome, isA<OptimizationSuccess>());
    final success = outcome as OptimizationSuccess;
    expect(success.result.totalDurationMinutes, 18);
    expect(success.result.orderedStops.length, 2);
  });
}
