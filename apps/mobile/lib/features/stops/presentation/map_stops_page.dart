import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';
import '../state/stops_controller.dart';
import 'shared/map_attribution.dart';
import 'shared/stops_async_view.dart';

class MapStopsPage extends ConsumerStatefulWidget {
  const MapStopsPage({
    super.key,
    this.onBack,
    this.onAddStop,
    this.onStartNavigation,
  });

  /// Nullable so widget tests can assert taps without standing up a GoRouter.
  final void Function(BuildContext context)? onBack;
  final void Function(BuildContext context)? onAddStop;
  final void Function(BuildContext context)? onStartNavigation;

  @override
  ConsumerState<MapStopsPage> createState() => _MapStopsPageState();
}

class _MapStopsPageState extends ConsumerState<MapStopsPage> {
  // SP capital bbox matching ADR-0008's GraphHopper graph extent.
  static const _spBoundsSw = LatLng(-23.78, -46.83);
  static const _spBoundsNe = LatLng(-23.36, -46.40);
  static const _spCenter = LatLng(-23.55, -46.63);
  static const _defaultZoom = 13.0;

  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    final cam = _mapController.camera;
    _mapController.move(cam.center, math.min(cam.zoom + 1, 19));
  }

  void _zoomOut() {
    final cam = _mapController.camera;
    _mapController.move(cam.center, math.max(cam.zoom - 1, 10));
  }

  void _recenter(List<LatLng> points) {
    // TODO(slice-3): recenter on the user's live location once geolocator
    // is wired. For now, jump back to the first stop or SP center.
    final target = points.isEmpty ? _spCenter : points.first;
    _mapController.move(target, _defaultZoom);
  }

  void _handleBack() {
    (widget.onBack ??
        (ctx) => ctx.canPop() ? ctx.pop() : ctx.go('/home'))(context);
  }

  void _handleAdd() {
    (widget.onAddStop ?? (ctx) => ctx.push('/home/stops/add'))(context);
  }

  void _handleNavigate() {
    (widget.onStartNavigation ?? (ctx) => ctx.push('/home/navigate'))(context);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(stopsControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: stopsAsyncView(
        async,
        screenTag: 'MapStopsPage',
        data: (context, stops) {
          final geocoded =
              stops.where((s) => s.isGeocoded).toList(growable: false);
          if (geocoded.isEmpty) {
            return _EmptyHint(onBack: _handleBack, onAdd: _handleAdd);
          }
          final points = [for (final s in geocoded) LatLng(s.lat, s.lng)];
          return _MapStopsView(
            points: points,
            stopCount: geocoded.length,
            mapController: _mapController,
            spBoundsSw: _spBoundsSw,
            spBoundsNe: _spBoundsNe,
            onBack: _handleBack,
            onAdd: _handleAdd,
            onNavigate: _handleNavigate,
            onZoomIn: _zoomIn,
            onZoomOut: _zoomOut,
            onRecenter: () => _recenter(points),
            // TODO(slice-3): wire current-stop label from the navigation
            // state machine; for now show the first geocoded stop.
            currentLabel: geocoded.first.label ?? 'Próxima parada',
          );
        },
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.onBack, required this.onAdd});
  final VoidCallback onBack;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Voltar',
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar'),
                ),
              ],
            ),
          ),
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Adicione paradas com endereço geocodificado para vê-las no mapa.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapStopsView extends StatelessWidget {
  const _MapStopsView({
    required this.points,
    required this.stopCount,
    required this.mapController,
    required this.spBoundsSw,
    required this.spBoundsNe,
    required this.onBack,
    required this.onAdd,
    required this.onNavigate,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onRecenter,
    required this.currentLabel,
  });

  final List<LatLng> points;
  final int stopCount;
  final MapController mapController;
  final LatLng spBoundsSw;
  final LatLng spBoundsNe;
  final VoidCallback onBack;
  final VoidCallback onAdd;
  final VoidCallback onNavigate;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onRecenter;
  final String currentLabel;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: points.first,
              initialZoom: 13,
              minZoom: 10,
              maxZoom: 19,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(spBoundsSw, spBoundsNe),
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'br.com.roteirizadorpro.roteirizador_pro',
                retinaMode: RetinaMode.isHighDensity(context),
                maxNativeZoom: 19,
              ),
              if (points.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: points,
                      strokeWidth: 5,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  for (var i = 0; i < points.length; i++)
                    Marker(
                      point: points[i],
                      width: 60,
                      height: 60,
                      alignment: Alignment.bottomCenter,
                      // TODO(slice-4): drive the status (delivered / current /
                      // pending) from the delivery state machine instead of
                      // hardcoding "current" for index 0 and "pending" for
                      // the rest.
                      child: _StatusPin(
                        index: i + 1,
                        status:
                            i == 0 ? _PinStatus.current : _PinStatus.pending,
                      ),
                    ),
                ],
              ),
              osmAttribution(),
            ],
          ),
        ),
        Positioned(
          top: topPad + 12,
          left: 12,
          right: 12,
          child: _HeaderCard(
            stopCount: stopCount,
            onBack: onBack,
            onAdd: onAdd,
          ),
        ),
        Positioned(
          top: topPad + 76,
          right: 12,
          child: const _LiveChip(),
        ),
        Positioned(
          top: topPad + 130,
          right: 12,
          child: _MapControls(
            onZoomIn: onZoomIn,
            onZoomOut: onZoomOut,
            onRecenter: onRecenter,
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 16,
          // "Editar" intentionally aliases to the back handler — the prototype
          // (`screens-d.jsx:165` `goto('home-list')`) routes the panel's
          // Editar button to the same destination as the header back button:
          // the HomeList reorder view. Once a dedicated reorder flow lands
          // (slice-3), wire `onEdit` separately.
          child: _BottomActionPanel(
            currentLabel: currentLabel,
            onAdd: onAdd,
            onEdit: onBack,
            onNavigate: onNavigate,
          ),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.stopCount,
    required this.onBack,
    required this.onAdd,
  });

  final int stopCount;
  final VoidCallback onBack;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F1A1A2E),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: Material(
              color: AppColors.surface,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onBack,
                customBorder: const CircleBorder(),
                child: const Tooltip(
                  message: 'Voltar',
                  child: Icon(
                    Icons.arrow_back,
                    size: 18,
                    color: AppColors.text,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rota de hoje · $stopCount parada${stopCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                // TODO(slice-4): replace mock counts with delivery state.
                // Prototype line 89 shows the delivered count in success-green
                // w600 — for now, render the placeholder string in muted text.
                Text(
                  '0 entregues · $stopCount pendentes · ~14:30',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 36,
            child: FilledButton.icon(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Adicionar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveChip extends StatefulWidget {
  const _LiveChip();

  @override
  State<_LiveChip> createState() => _LiveChipState();
}

class _LiveChipState extends State<_LiveChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.neon,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80C6FF3D),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: 0.35, end: 1.0).animate(
              CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
            ),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.neonInk,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'AO VIVO',
            style: TextStyle(
              color: AppColors.neonInk,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapControls extends StatelessWidget {
  const _MapControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onRecenter,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onRecenter;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ControlButton(
          icon: Icons.add,
          tooltip: 'Aumentar zoom',
          onPressed: onZoomIn,
          keyValue: const Key('map-stops-zoom-in'),
        ),
        const SizedBox(height: 8),
        _ControlButton(
          icon: Icons.remove,
          tooltip: 'Diminuir zoom',
          onPressed: onZoomOut,
          keyValue: const Key('map-stops-zoom-out'),
        ),
        const SizedBox(height: 8),
        _ControlButton(
          icon: Icons.near_me_outlined,
          tooltip: 'Recentralizar',
          onPressed: onRecenter,
          iconColor: AppColors.primary,
          keyValue: const Key('map-stops-recenter'),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.iconColor,
    this.keyValue,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final Color? iconColor;
  final Key? keyValue;

  @override
  Widget build(BuildContext context) {
    // Shadow lives on the outer DecoratedBox so the Material/InkWell above
    // it doesn't clip the drop-shadow (D4 review caught this pattern).
    return SizedBox(
      width: 40,
      height: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x261A1A2E),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          key: keyValue,
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Tooltip(
              message: tooltip,
              child: Center(
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor ?? AppColors.text,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomActionPanel extends StatelessWidget {
  const _BottomActionPanel({
    required this.currentLabel,
    required this.onAdd,
    required this.onEdit,
    required this.onNavigate,
  });

  final String currentLabel;
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E1A1A2E),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // TODO(slice-4): drive the badge index + neon-ring color from
              // the delivery state machine (current stop index, not hardcoded 1).
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.neon,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x4DC6FF3D),
                      blurRadius: 0,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Text(
                  '1',
                  style: TextStyle(
                    color: AppColors.neonInk,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PRÓXIMA PARADA',
                      style: TextStyle(
                        color: AppColors.neonDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentLabel,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // TODO(slice-3): wire km/min from VRP-computed leg.
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '—',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '—',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PanelButton(
                  label: 'Adicionar',
                  icon: Icons.add,
                  background: AppColors.surface,
                  foreground: AppColors.text,
                  borderColor: AppColors.border,
                  onPressed: onAdd,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PanelButton(
                  label: 'Editar',
                  icon: Icons.drag_indicator,
                  background: AppColors.bg,
                  foreground: AppColors.primary,
                  borderColor: AppColors.primary,
                  onPressed: onEdit,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _PrimaryNavCta(onPressed: onNavigate),
        ],
      ),
    );
  }
}

class _PanelButton extends StatelessWidget {
  const _PanelButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.borderColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color borderColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.btn),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadii.btn),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 1.5),
              borderRadius: BorderRadius.circular(AppRadii.btn),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryNavCta extends StatelessWidget {
  const _PrimaryNavCta({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.btn),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadii.btn),
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.btn),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(AppRadii.btn),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x526C3FC5),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.navigation_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Iniciar navegação',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: 14,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.neon,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xE6C6FF3D),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _PinStatus { delivered, current, pending }

class _StatusPin extends StatelessWidget {
  const _StatusPin({required this.index, required this.status});

  final int index;
  final _PinStatus status;

  @override
  Widget build(BuildContext context) {
    final palette = switch (status) {
      _PinStatus.delivered => (
          bg: AppColors.success,
          ring: AppColors.successBg,
          ink: Colors.white,
        ),
      _PinStatus.pending => (
          bg: AppColors.primary,
          ring: AppColors.primaryLight,
          ink: Colors.white,
        ),
      _PinStatus.current => (
          bg: AppColors.neon,
          ring: const Color(0x59C6FF3D),
          ink: AppColors.neonInk,
        ),
    };

    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          if (status == _PinStatus.current)
            Positioned(
              top: 0,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: palette.ring,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          Transform.rotate(
            angle: -math.pi / 4,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: palette.bg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x4D1A1A2E),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Text(
                  '$index',
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
