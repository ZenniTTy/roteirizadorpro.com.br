// test/features/routes/domain/optimization/local_route_optimizer_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/domain/optimize_direction.dart';
import 'package:roteirizador_pro/features/routes/domain/optimize_type.dart';
import 'package:roteirizador_pro/features/routes/domain/package_label_format.dart';
import 'package:roteirizador_pro/features/routes/domain/optimization/local_route_optimizer.dart';
import 'package:roteirizador_pro/features/routes/domain/optimization/route_optimizer.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';

// Distância de teste determinística: |Δlat| + |Δlng| (Manhattan em "graus"),
// 1 grau = 1000 m. Injetada para o teste não depender da Terra real.
double _fakeDistance(double aLat, double aLng, double bLat, double bLng) =>
    ((aLat - bLat).abs() + (aLng - bLng).abs()) * 1000;

Stop _stop(String id, double lat, double lng) =>
    Stop(id: id, lat: lat, lng: lng, streetName: id, fullAddress: id);

void main() {
  final optimizer = LocalRouteOptimizer(distanceMeters: _fakeDistance);

  test('reordena por vizinho mais próximo a partir do start', () async {
    // start em (0,0); paradas fora de ordem. A mais próxima do start é C(1,0).
    final result = await optimizer.optimize(
      start: const GeoPoint(0, 0),
      stops: [_stop('A', 5, 0), _stop('B', 3, 0), _stop('C', 1, 0)],
      type: OptimizeType.restartRoute,
    );
    expect(result.orderedStops.map((s) => s.id).toList(), ['C', 'B', 'A']);
  });

  test('atribui deliveryId Moderno na ordem final (A1, A2, A3)', () async {
    final result = await optimizer.optimize(
      start: const GeoPoint(0, 0),
      stops: [_stop('A', 5, 0), _stop('B', 3, 0), _stop('C', 1, 0)],
      type: OptimizeType.restartRoute,
    );
    expect(
      result.orderedStops.map((s) => s.deliveryId).toList(),
      ['A1', 'A2', 'A3'],
    );
  });

  test(
      'stopArrivalOffsets = tempo de viagem acumulado por parada (ordem final)',
      () async {
    // start(0,0) → C(1,0) → B(3,0) → A(5,0): legs de 1000, 2000, 2000 m.
    // velocidade default 400 m/min → 2.5, 5.0, 5.0 min → acumulado 2.5/7.5/12.5.
    final result = await optimizer.optimize(
      start: const GeoPoint(0, 0),
      stops: [_stop('A', 5, 0), _stop('B', 3, 0), _stop('C', 1, 0)],
      type: OptimizeType.restartRoute,
    );
    expect(result.orderedStops.map((s) => s.id).toList(), ['C', 'B', 'A']);
    expect(result.stopArrivalOffsets, hasLength(3));
    expect(result.stopArrivalOffsets[0], const Duration(seconds: 150));
    expect(result.stopArrivalOffsets[1], const Duration(seconds: 450));
    expect(result.stopArrivalOffsets[2], const Duration(seconds: 750));
  });

  test('direction reverse inverte a ordem otimizada', () async {
    final result = await optimizer.optimize(
      start: const GeoPoint(0, 0),
      stops: [_stop('A', 5, 0), _stop('B', 3, 0), _stop('C', 1, 0)],
      type: OptimizeType.reorderFlexible,
      direction: OptimizeDirection.reverse,
    );
    expect(result.orderedStops.map((s) => s.id).toList(), ['A', 'B', 'C']);
  });

  test('exclui paradas com pendingRemoval da ordem final (G5)', () async {
    final result = await optimizer.optimize(
      start: const GeoPoint(0, 0),
      stops: [
        _stop('A', 5, 0),
        _stop('B', 3, 0).copyWith(pendingRemoval: true),
        _stop('C', 1, 0),
      ],
      type: OptimizeType.restartRoute,
    );
    expect(result.orderedStops.map((s) => s.id).toList(), ['C', 'A']);
  });

  test('métricas: distância total > 0 e duração derivada da distância',
      () async {
    final result = await optimizer.optimize(
      start: const GeoPoint(0, 0),
      stops: [_stop('C', 1, 0)],
      type: OptimizeType.restartRoute,
    );
    expect(result.totalDistanceMeters, 1000);
    expect(result.totalDurationMinutes, 3);
  });

  test('inclui o leg final para end na distância total', () async {
    // start(0,0) → C(1,0) → end(2,0). Legs: 0→1 (1000m) + 1→2 (1000m) = 2000m.
    final result = await optimizer.optimize(
      start: const GeoPoint(0, 0),
      end: const GeoPoint(2, 0),
      stops: [_stop('C', 1, 0)],
      type: OptimizeType.restartRoute,
    );
    expect(result.totalDistanceMeters, 2000);
  });

  test('formato Clássico gera 1,2,3', () async {
    final classic = LocalRouteOptimizer(
      distanceMeters: _fakeDistance,
      labelFormat: PackageLabelFormat.classico,
    );
    final result = await classic.optimize(
      start: const GeoPoint(0, 0),
      stops: [_stop('A', 5, 0), _stop('B', 3, 0)],
      type: OptimizeType.restartRoute,
    );
    expect(result.orderedStops.map((s) => s.deliveryId).toList(), ['1', '2']);
  });
}
