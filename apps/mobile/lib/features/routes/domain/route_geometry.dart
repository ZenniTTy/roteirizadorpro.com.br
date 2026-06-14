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
