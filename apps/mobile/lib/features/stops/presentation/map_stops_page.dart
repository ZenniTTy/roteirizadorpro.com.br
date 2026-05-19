import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../state/stops_controller.dart';
import 'shared/map_attribution.dart';
import 'shared/stops_async_view.dart';

class MapStopsPage extends ConsumerWidget {
  const MapStopsPage({super.key});

  // SP capital bbox matching ADR-0008's GraphHopper graph extent.
  static const _spBoundsSw = LatLng(-23.78, -46.83);
  static const _spBoundsNe = LatLng(-23.36, -46.40);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(stopsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa das paradas')),
      body: SafeArea(
        child: stopsAsyncView(
          async,
          screenTag: 'MapStopsPage',
          data: (context, stops) {
            final theme = Theme.of(context);
            final geocoded =
                stops.where((s) => s.isGeocoded).toList(growable: false);
            if (geocoded.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Adicione paradas com endereço geocodificado para vê-las no mapa.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              );
            }
            final points = [
              for (final s in geocoded) LatLng(s.lat, s.lng),
            ];
            return FlutterMap(
              options: MapOptions(
                initialCenter: points.first,
                initialZoom: 13,
                minZoom: 10,
                maxZoom: 19,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                cameraConstraint: CameraConstraint.contain(
                  bounds: LatLngBounds(_spBoundsSw, _spBoundsNe),
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                      'br.com.roteirizadorpro.roteirizador_pro',
                  retinaMode: RetinaMode.isHighDensity(context),
                  maxNativeZoom: 19,
                ),
                if (points.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: points,
                        strokeWidth: 4,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    for (var i = 0; i < geocoded.length; i++)
                      Marker(
                        point: points[i],
                        width: 32,
                        height: 32,
                        child: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                osmAttribution(),
              ],
            );
          },
        ),
      ),
    );
  }
}
