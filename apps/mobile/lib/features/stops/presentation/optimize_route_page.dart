import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/external_nav.dart';
import '../domain/stop.dart';
import '../state/optimize_controller.dart';
import '../state/stops_controller.dart';
import 'shared/map_attribution.dart';
import 'shared/stops_async_view.dart';

/// Post-optimize preview screen per prototipo/screens-e.jsx:157-297.
/// Slice 2 ships a simplified version: top map (numbered markers +
/// straight-line polyline, real road geometry arrives with GraphHopper
/// in slice 3), bottom list of stops, "Iniciar navegação" CTA that
/// delegates to ExternalNav per ADR-0017 (Waze default, Google Maps
/// chunked for >10 stops).
class OptimizeRoutePage extends ConsumerStatefulWidget {
  const OptimizeRoutePage({super.key, this.onNavigateStarted});

  /// Callback injection for widget tests; production routes via GoRouter.
  final void Function(BuildContext context)? onNavigateStarted;

  @override
  ConsumerState<OptimizeRoutePage> createState() => _OptimizeRoutePageState();
}

class _OptimizeRoutePageState extends ConsumerState<OptimizeRoutePage> {
  static const _spBoundsSw = LatLng(-23.78, -46.83);
  static const _spBoundsNe = LatLng(-23.36, -46.40);

  /// ADR-0017 makes Waze the default when the pref key is absent.
  Future<NavProvider> _readProvider() async {
    final raw = await SharedPreferencesAsync().getString(kNavProviderPrefKey);
    return raw == 'googleMaps' ? NavProvider.googleMaps : NavProvider.waze;
  }

  void _onNavigateStarted(BuildContext context) =>
      (widget.onNavigateStarted ?? (ctx) => ctx.go('/home/navigate'))(context);

  Future<void> _start(List<Stop> geocoded) async {
    if (geocoded.isEmpty) return;

    final nav = ref.read(externalNavProvider);
    final provider = await _readProvider();
    if (!mounted) return;

    if (provider == NavProvider.googleMaps) {
      final chunks = ExternalNav.googleMapsUriChunks(geocoded);
      // Open the first chunk; ScreenNavigate owns the chunked flow.
      final firstChunkSize = geocoded.length > kGoogleMapsMaxStopsPerUri
          ? kGoogleMapsMaxStopsPerUri
          : geocoded.length;
      await nav.openInGoogleMaps(geocoded.sublist(0, firstChunkSize));
      if (!mounted) return;
      if (chunks.length > 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Google Maps suporta $kGoogleMapsMaxStopsPerUri paradas '
              'por vez. Vamos abrir a próxima parte quando você terminar.',
            ),
          ),
        );
      }
      _onNavigateStarted(context);
    } else {
      if (geocoded.length > 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Waze não suporta múltiplas paradas; vamos abrir uma de cada vez.',
            ),
          ),
        );
      }
      await nav.openInWaze(geocoded.first);
      if (!mounted) return;
      _onNavigateStarted(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(stopsControllerProvider);
    final optimizeAsync = ref.watch(optimizeControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rota otimizada'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: _MetricsRow(
            stopsAsync: async,
            optimizeAsync: optimizeAsync,
          ),
        ),
      ),
      body: SafeArea(
        child: stopsAsyncView(
          async,
          screenTag: 'OptimizeRoutePage',
          data: (context, stops) {
            final geocoded = stops.where((s) => s.isGeocoded).toList();
            final ungeocodedCount = stops.length - geocoded.length;
            final points = [for (final s in geocoded) LatLng(s.lat, s.lng)];

            return Column(
              children: [
                SizedBox(
                  height: 280,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: points.isEmpty
                          ? const LatLng(-23.5505, -46.6333)
                          : points.first,
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
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          for (var i = 0; i < geocoded.length; i++)
                            Marker(
                              point: LatLng(
                                geocoded[i].lat,
                                geocoded[i].lng,
                              ),
                              width: 32,
                              height: 32,
                              child: CircleAvatar(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                      osmAttribution(),
                    ],
                  ),
                ),
                if (ungeocodedCount > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Text(
                      '$ungeocodedCount paradas sem geocodificação ficam '
                      'fora da navegação até o slice 3 (Nominatim).',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontSize: 12,
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    itemCount: stops.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final s = stops[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: s.isGeocoded
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).disabledColor,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          s.label ??
                              '${s.lat.toStringAsFixed(5)}, ${s.lng.toStringAsFixed(5)}',
                        ),
                        trailing: s.isGeocoded
                            ? null
                            : const Icon(Icons.location_off, size: 18),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: Semantics(
                      button: true,
                      label: 'Iniciar navegação',
                      child: FilledButton.icon(
                        onPressed:
                            geocoded.isEmpty ? null : () => _start(geocoded),
                        icon: const Icon(Icons.navigation),
                        label: const Text('Iniciar navegação'),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Compact metrics row shown under the AppBar title — count of stops,
/// total distance (km) and total duration (min) when the
/// `OptimizeController` has produced a result. Per prototipo/screens-e.jsx:254
/// the prototype puts a similar "Cidade · 27 paradas" line; ETA per stop
/// arrives with slice 3 (GraphHopper leg durations).
class _MetricsRow extends StatelessWidget {
  const _MetricsRow({
    required this.stopsAsync,
    required this.optimizeAsync,
  });

  final AsyncValue<List<Stop>> stopsAsync;
  final AsyncValue<OptimizeResult?> optimizeAsync;

  String _format(int count, double? distanceM, double? durationS) {
    final parts = <String>['$count paradas'];
    if (distanceM != null && distanceM > 0) {
      parts.add('${(distanceM / 1000).toStringAsFixed(1)} km');
    }
    if (durationS != null && durationS > 0) {
      parts.add('~${(durationS / 60).round()} min');
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final count = stopsAsync.asData?.value.length ?? 0;
    final result = optimizeAsync.asData?.value;
    return SizedBox(
      height: 28,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _format(count, result?.totalDistanceM, result?.totalDurationS),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ),
    );
  }
}
