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
    this.stopArrivalOffsets = const [],
  });
  final List<Stop> orderedStops;
  final int totalDurationMinutes;
  final double totalDistanceMeters;

  /// Deslocamento de tempo do INÍCIO da rota até a chegada em cada parada, na
  /// mesma ordem (e tamanho) de [orderedStops]. O provider soma cada offset ao
  /// horário da otimização para cravar o `Stop.estimatedArrival` (ETA absoluto
  /// exibido na step list). Vazio quando o solver não computa ETA — a step list
  /// degrada para "sem hora" sem quebrar. No Slice 2 é só tempo de viagem
  /// acumulado; o GraphHopper (Slice 3) traz ETA real com trânsito + serviço.
  final List<Duration> stopArrivalOffsets;
}

/// Fronteira do solver. A impl. do Slice 2 é `LocalRouteOptimizer` (on-device);
/// o Slice 3 injeta um `GraphHopperRouteOptimizer` sem tocar UI/estado.
///
/// `optimize` é `Future` por design: o Spoke otimiza num solver de BACKEND
/// (`OptimizationRoutingSolver{GOOGLE_MAPS, GRAPH_HOPPER}` — operação de rede,
/// assíncrona por natureza). O `LocalRouteOptimizer` síncrono do Slice 2 é só o
/// stand-in por trás desta fronteira async; manter a assinatura `Future` agora
/// evita um breaking change na interface quando o GraphHopper (I/O) entrar no
/// Slice 3.
abstract interface class RouteOptimizer {
  Future<RouteOptimizationResult> optimize({
    required GeoPoint start,
    GeoPoint? end,
    required List<Stop> stops,
    required OptimizeType type,
    OptimizeDirection? direction,
  });
}
