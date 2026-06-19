import 'package:flutter/widgets.dart' show Color;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'stop.dart';

/// Pontos da polyline da rota otimizada: um `LatLng` por parada ATIVA, na ordem
/// da lista (que já é a ordem do solver). Paradas marcadas `pendingRemoval`
/// (G5 — saem na próxima otimização) não entram na linha. Client-side: retas
/// entre pontos (espelha o `markerPolylineFlow` do Spoke; curva de routing real
/// é Slice 3).
List<LatLng> routePolylinePoints(List<Stop> stops) => [
      for (final s in stops)
        if (!s.pendingRemoval) LatLng(s.lat, s.lng),
    ];

/// Monta a polyline da rota como DOIS traços sobrepostos: `route_outer`
/// (borda, mais espessa, atrás) + `route_inner` (preenchimento, mais fina, à
/// frente) — replica o efeito `borderBrandEmphasis` do Spoke (inner+outer).
/// Vazio com < 2 pontos (uma linha precisa de 2 pontas).
Set<Polyline> buildRoutePolylines(
  List<LatLng> points, {
  required Color fill,
  required Color border,
}) {
  if (points.length < 2) return const {};
  return {
    Polyline(
      polylineId: const PolylineId('route_outer'),
      points: points,
      color: border,
      width: 7,
      zIndex: 0,
    ),
    Polyline(
      polylineId: const PolylineId('route_inner'),
      points: points,
      color: fill,
      width: 4,
      zIndex: 1,
    ),
  };
}
