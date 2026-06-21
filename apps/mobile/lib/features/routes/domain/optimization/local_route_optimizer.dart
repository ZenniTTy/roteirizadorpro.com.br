import 'package:geolocator/geolocator.dart';

import '../optimize_direction.dart';
import '../optimize_type.dart';
import '../package_label_format.dart';
import '../stop.dart';
import 'route_optimizer.dart';

/// Solver on-device (stand-in do GraphHopper até o Slice 3). Nearest-neighbor
/// a partir do `start` + refinamento 2-opt; distância via `geolocator`
/// (injetável para teste). Atribui `deliveryId` pela [labelFormat]. Velocidade
/// urbana constante converte distância em duração (o tempo com trânsito real
/// vem do GraphHopper no Slice 3).
class LocalRouteOptimizer implements RouteOptimizer {
  LocalRouteOptimizer({
    double Function(double, double, double, double)? distanceMeters,
    this.labelFormat = PackageLabelFormat.moderno,
    this.urbanSpeedMetersPerMinute = 400, // ~24 km/h
  }) : _distance = distanceMeters ?? Geolocator.distanceBetween;

  final double Function(double, double, double, double) _distance;
  final PackageLabelFormat labelFormat;
  final double urbanSpeedMetersPerMinute;

  @override
  Future<RouteOptimizationResult> optimize({
    required GeoPoint start,
    GeoPoint? end,
    required List<Stop> stops,
    required OptimizeType type,
    OptimizeDirection? direction,
  }) async {
    // `type` não altera o algoritmo no solver on-device (Slice 2): restart e
    // reorder reotimizam igual aqui. A distinção do Spoke entre "Reotimizar"
    // (recalcula do zero) e "Atualizar" (preserva a estrutura) é semântica do
    // backend real (GraphHopper, Slice 3); a interface já carrega `type` para
    // o swap não mexer na assinatura. O controller é quem mapeia cada ação ao
    // type — ver OptimizationController (Task 8).
    // G5: paradas marcadas para remoção deferida saem aqui.
    final active = stops.where((s) => !s.pendingRemoval).toList();

    // Nearest-neighbor a partir do start.
    var ordered = _nearestNeighbor(start, active);
    // Refina com 2-opt (cap de iterações para O(n²) ficar barato).
    ordered = _twoOpt(start, ordered, end);

    if (direction == OptimizeDirection.reverse) {
      ordered = ordered.reversed.toList();
    }

    // Atribui deliveryId + posição na ordem final.
    final labeled = <Stop>[
      for (var i = 0; i < ordered.length; i++)
        ordered[i].copyWith(
          deliveryId: labelFormat.labelFor(i),
          positionInRoute: i,
        ),
    ];

    final distance = _totalDistance(start, labeled, end);
    return RouteOptimizationResult(
      orderedStops: labeled,
      totalDistanceMeters: distance,
      totalDurationMinutes: (distance / urbanSpeedMetersPerMinute).round(),
      stopArrivalOffsets: _arrivalOffsets(start, labeled),
    );
  }

  /// Tempo de viagem acumulado do [start] até a chegada em cada parada, na ordem
  /// final. Só deslocamento (sem tempo de serviço na parada) — a velocidade
  /// urbana constante converte a distância acumulada em minutos. O provider
  /// soma cada offset ao horário da otimização para obter o ETA absoluto.
  List<Duration> _arrivalOffsets(GeoPoint start, List<Stop> ordered) {
    final offsets = <Duration>[];
    var cumulativeMeters = 0.0;
    var prevLat = start.lat;
    var prevLng = start.lng;
    for (final s in ordered) {
      cumulativeMeters += _distance(prevLat, prevLng, s.lat, s.lng);
      final minutes = cumulativeMeters / urbanSpeedMetersPerMinute;
      offsets.add(Duration(seconds: (minutes * 60).round()));
      prevLat = s.lat;
      prevLng = s.lng;
    }
    return offsets;
  }

  List<Stop> _nearestNeighbor(GeoPoint start, List<Stop> stops) {
    final remaining = [...stops];
    final result = <Stop>[];
    var curLat = start.lat;
    var curLng = start.lng;
    while (remaining.isNotEmpty) {
      var bestIdx = 0;
      var bestDist = double.infinity;
      for (var i = 0; i < remaining.length; i++) {
        final d = _distance(curLat, curLng, remaining[i].lat, remaining[i].lng);
        if (d < bestDist) {
          bestDist = d;
          bestIdx = i;
        }
      }
      final next = remaining.removeAt(bestIdx);
      result.add(next);
      curLat = next.lat;
      curLng = next.lng;
    }
    return result;
  }

  List<Stop> _twoOpt(GeoPoint start, List<Stop> route, GeoPoint? end) {
    if (route.length < 3) return route;
    var best = [...route];
    var bestDist = _totalDistance(start, best, end);
    var improved = true;
    var guard = 0;
    while (improved && guard < 50) {
      improved = false;
      guard++;
      for (var i = 0; i < best.length - 1; i++) {
        for (var j = i + 1; j < best.length; j++) {
          final candidate = [
            ...best.sublist(0, i),
            ...best.sublist(i, j + 1).reversed,
            ...best.sublist(j + 1),
          ];
          final candidateDist = _totalDistance(start, candidate, end);
          if (candidateDist < bestDist) {
            best = candidate;
            bestDist = candidateDist;
            improved = true;
          }
        }
      }
    }
    return best;
  }

  double _totalDistance(GeoPoint start, List<Stop> stops, GeoPoint? end) {
    if (stops.isEmpty) return 0;
    var total =
        _distance(start.lat, start.lng, stops.first.lat, stops.first.lng);
    for (var i = 0; i < stops.length - 1; i++) {
      total += _distance(
        stops[i].lat,
        stops[i].lng,
        stops[i + 1].lat,
        stops[i + 1].lng,
      );
    }
    if (end != null) {
      total += _distance(stops.last.lat, stops.last.lng, end.lat, end.lng);
    }
    return total;
  }
}
