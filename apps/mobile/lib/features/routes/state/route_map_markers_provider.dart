import 'package:flutter/material.dart' show Colors, Offset;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/theme/app_theme.dart';
import '../presentation/widgets/stop_marker_bitmap.dart';
import 'active_route_provider.dart';
import 'routes_provider.dart';

part 'route_map_markers_provider.g.dart';

/// Cache persistente de bitmaps de marker por label (`keepAlive` — sobrevive às
/// invalidações de `routeMapMarkers`, que reroda a cada mudança de rota). Sem
/// isto, cada reotimização regeraria todos os PNGs no UI thread (perf-auditor
/// must-fix Á7 PR-B2). O label é a única dimensão que muda o pixel (cor é fixa
/// = AppColors.primary/white), então a chave é só o label.
@Riverpod(keepAlive: true)
class StopMarkerBitmapCache extends _$StopMarkerBitmapCache {
  @override
  Map<String, BitmapDescriptor> build() => {};

  Future<BitmapDescriptor> resolve(String label) async {
    // Chave = SÓ o label porque fill+textColor são fixos app-wide
    // (AppColors.primary/white). Se um sprint futuro introduzir cor por parada
    // (`StopColor` já existe no domínio), estender a chave p/ incluir a cor —
    // senão o cache serviria a cor errada para o mesmo label silenciosamente.
    final cached = state[label];
    if (cached != null) return cached;
    final bitmap = await stopMarkerBitmap(
      label: label,
      fill: AppColors.primary,
      textColor: Colors.white,
    );
    state = {...state, label: bitmap};
    return bitmap;
  }
}

/// `Set<Marker>` da rota ativa (um por parada ATIVA, na ordem). Cada marker usa
/// um bitmap desenhado via `dart:ui`, resolvido pelo cache persistente
/// `stopMarkerBitmapCache` (não regenera entre reotimizações) e gerado em
/// PARALELO (`Future.wait`). O label é a identificação da parada (`deliveryId`
/// ou índice 1..N) — NÃO a hora (ETA é Slice 3). Vazio quando não há rota ativa.
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

  // `.notifier` (estável, keepAlive) — NÃO observar o estado do cache senão
  // este provider rerodaria a cada bitmap novo cacheado (loop).
  final cache = ref.read(stopMarkerBitmapCacheProvider.notifier);
  final marked = await Future.wait([
    for (var i = 0; i < active.length; i++)
      () async {
        final s = active[i];
        final label = s.deliveryId ?? '${i + 1}';
        final icon = await cache.resolve(label);
        return Marker(
          markerId: MarkerId(s.id),
          position: LatLng(s.lat, s.lng),
          icon: icon,
          anchor: const Offset(0.5, 0.5),
        );
      }(),
  ]);
  return marked.toSet();
}
