import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/services/id.dart';
import '../domain/stop.dart';
import '../state/stops_controller.dart';
import 'shared/map_attribution.dart';

class AddStopsMapPage extends ConsumerStatefulWidget {
  const AddStopsMapPage({super.key, this.onConfirmed});

  /// Nullable so widget tests can assert taps without standing up a GoRouter;
  /// production falls through to `context.pop()` (or `/home` if the page was deep-linked).
  final void Function(BuildContext context)? onConfirmed;

  @override
  ConsumerState<AddStopsMapPage> createState() => _AddStopsMapPageState();
}

class _AddStopsMapPageState extends ConsumerState<AddStopsMapPage> {
  static const _spCenter = LatLng(-23.55, -46.63);
  static const _spBoundsSw = LatLng(-23.78, -46.83);
  static const _spBoundsNe = LatLng(-23.36, -46.40);

  final List<LatLng> _pending = [];

  void _onTap(TapPosition _, LatLng point) {
    setState(() => _pending.add(point));
  }

  void _undo() {
    if (_pending.isEmpty) return;
    setState(() => _pending.removeLast());
  }

  Future<void> _confirm() async {
    if (_pending.isEmpty) return;
    final controller = ref.read(stopsControllerProvider.notifier);
    final now = DateTime.now();
    for (final p in _pending) {
      await controller.add(
        Stop(
          id: newId(),
          lat: p.latitude,
          lng: p.longitude,
          source: StopSource.mapTap,
          createdAt: now,
        ),
      );
    }
    if (!mounted) return;
    (widget.onConfirmed ??
        (ctx) => ctx.canPop() ? ctx.pop() : ctx.go('/home'))(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPending = _pending.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Toque no mapa para adicionar paradas'),
        actions: [
          IconButton(
            key: const Key('add-stops-map-undo'),
            tooltip: 'Desfazer última',
            onPressed: hasPending ? _undo : null,
            icon: const Icon(Icons.undo),
          ),
        ],
      ),
      body: SafeArea(
        child: FlutterMap(
          options: MapOptions(
            initialCenter: _spCenter,
            initialZoom: 13,
            minZoom: 10,
            maxZoom: 19,
            onTap: _onTap,
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
              userAgentPackageName: 'br.com.roteirizadorpro.roteirizador_pro',
              retinaMode: RetinaMode.isHighDensity(context),
              maxNativeZoom: 19,
            ),
            MarkerLayer(
              markers: [
                for (var i = 0; i < _pending.length; i++)
                  Marker(
                    point: _pending[i],
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
        ),
      ),
      floatingActionButton: hasPending
          ? FloatingActionButton.extended(
              key: const Key('add-stops-map-confirm'),
              onPressed: _confirm,
              icon: const Icon(Icons.check),
              label: Text('Adicionar ${_pending.length} parada'
                  '${_pending.length == 1 ? '' : 's'}'),
            )
          : null,
    );
  }
}
