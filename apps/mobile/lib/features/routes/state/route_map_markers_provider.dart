import 'package:flutter/material.dart' show Colors, Offset;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/theme/app_theme.dart';
import '../presentation/widgets/stop_marker_bitmap.dart';
import 'active_route_provider.dart';
import 'routes_provider.dart';

part 'route_map_markers_provider.g.dart';

/// `Set<Marker>` da rota ativa (um por parada ATIVA, na ordem). Cada marker usa
/// um bitmap desenhado via `dart:ui` (cacheado por label dentro de um build).
/// O label é a identificação da parada (`deliveryId` ou índice 1..N) — NÃO a
/// hora (ETA é Slice 3). Vazio quando não há rota ativa.
@riverpod
Future<Set<Marker>> routeMapMarkers(Ref ref) async {
  final id = ref.watch(activeRouteIdProvider);
  if (id == null) return const {};
  final route = ref.watch(routesProvider).where((r) => r.id == id).firstOrNull;
  if (route == null) return const {};

  final active = [
    for (final s in route.stops)
      if (!s.pendingRemoval) s,
  ];

  final cache = <String, BitmapDescriptor>{};
  final markers = <Marker>{};
  for (var i = 0; i < active.length; i++) {
    final s = active[i];
    final label = s.deliveryId ?? '${i + 1}';
    final icon = cache[label] ??= await stopMarkerBitmap(
      label: label,
      fill: AppColors.primary,
      textColor: Colors.white,
    );
    markers.add(
      Marker(
        markerId: MarkerId(s.id),
        position: LatLng(s.lat, s.lng),
        icon: icon,
        anchor: const Offset(0.5, 0.5),
      ),
    );
  }
  return markers;
}
