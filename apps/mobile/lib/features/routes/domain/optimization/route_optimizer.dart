import '../optimize_direction.dart';
import '../optimize_type.dart';
import '../stop.dart';

/// Ponto geográfico mínimo para o solver (evita acoplar a `LatLng` do
/// google_maps no domínio).
class GeoPoint {
  const GeoPoint(this.lat, this.lng);
  final double lat;
  final double lng;
}

/// Resultado de uma otimização: a ordem final das paradas (com `deliveryId`
/// já atribuído) + as métricas agregadas.
class RouteOptimizationResult {
  const RouteOptimizationResult({
    required this.orderedStops,
    required this.totalDurationMinutes,
    required this.totalDistanceMeters,
  });
  final List<Stop> orderedStops;
  final int totalDurationMinutes;
  final double totalDistanceMeters;
}

/// Fronteira do solver. A impl. do Slice 2 é `LocalRouteOptimizer` (on-device);
/// o Slice 3 injeta um `GraphHopperRouteOptimizer` sem tocar UI/estado.
abstract interface class RouteOptimizer {
  RouteOptimizationResult optimize({
    required GeoPoint start,
    GeoPoint? end,
    required List<Stop> stops,
    required OptimizeType type,
    OptimizeDirection? direction,
  });
}
