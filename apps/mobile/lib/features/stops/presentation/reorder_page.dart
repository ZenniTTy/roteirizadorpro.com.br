import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/rp_button.dart';
import '../../../core/widgets/rp_ghost_button.dart';
import '../../../core/widgets/rp_mini_pin.dart';
import '../domain/stop.dart';
import '../state/stops_controller.dart';
import 'shared/map_attribution.dart';
import 'shared/stops_async_view.dart';

/// Full-screen reorder/lasso view per prototipo/screens-e.jsx:629-737.
///
/// Layout: a full-bleed `FlutterMap` carries the route polyline and numbered
/// RpMiniPin markers; a translucent gesture overlay above the map captures
/// freeform pan strokes (the raw "lasso"); selection runs a screen-space
/// point-in-polygon test against each stop's projected position. The
/// dispatcher card, lasso badge, undo pill and bottom dispatcher panel are
/// stacked on top.
///
/// Slice-2 scope: the lasso is visual + count-only. "Reotimizar rota" simply
/// routes back to the optimize-route screen; wiring the selection into a
/// real reorder operation is a slice-3 follow-up.
class ReorderPage extends ConsumerStatefulWidget {
  const ReorderPage({
    super.key,
    this.onReoptimize,
    this.onDismiss,
  });

  /// Callback injection for tests; production default pops or routes to
  /// `/home/optimize/route`.
  final void Function(BuildContext context)? onReoptimize;

  /// Callback injection for the dispatcher card close affordance. Production
  /// default just hides the card locally (see `_dismissCard`).
  final void Function(BuildContext context)? onDismiss;

  @override
  ConsumerState<ReorderPage> createState() => _ReorderPageState();
}

class _ReorderPageState extends ConsumerState<ReorderPage> {
  // SP capital bbox matching ADR-0008's GraphHopper graph extent — same
  // values as OptimizeRoutePage/MapStopsPage.
  static const _spBoundsSw = LatLng(-23.78, -46.83);
  static const _spBoundsNe = LatLng(-23.36, -46.40);
  static const _spCenter = LatLng(-23.55, -46.63);

  final MapController _mapController = MapController();

  List<Offset> _draggedPoints = const [];
  List<String> _selectedStopIds = const [];
  bool _cardDismissed = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _onReoptimize() {
    // TODO(slice-3): route to the VRP rerun once GraphHopper + the solver
    // are wired; the current fallback just bounces back to the optimize
    // route screen which itself shows mock data.
    (widget.onReoptimize ??
        (ctx) => ctx.canPop() ? ctx.pop() : ctx.go('/home/optimize/route'))(
      context,
    );
  }

  void _dismissCard() {
    if (widget.onDismiss != null) {
      widget.onDismiss!(context);
      return;
    }
    setState(() => _cardDismissed = true);
  }

  void _onPanStart(Offset position) {
    setState(() {
      if (!_cardDismissed) _cardDismissed = true;
      _draggedPoints = [position];
    });
  }

  void _onPanUpdate(Offset position) {
    setState(() => _draggedPoints = [..._draggedPoints, position]);
  }

  void _onPanEnd(List<Stop> geocoded) {
    _computeSelection(geocoded);
  }

  void _clearLasso() {
    setState(() {
      _draggedPoints = const [];
      _selectedStopIds = const [];
    });
  }

  void _computeSelection(List<Stop> geocoded) {
    if (_draggedPoints.length < 3) {
      setState(() => _selectedStopIds = const []);
      return;
    }
    // TODO(slice-3): once the VRP solver lands, feed `_selectedStopIds`
    // back into `stopsControllerProvider.notifier.reorder(...)` so the
    // lasso group can be moved as a block. Slice 2 keeps the selection
    // visual + count-only.
    final camera = _mapController.camera;
    final polygon = _draggedPoints;
    final selected = <String>[];
    for (final stop in geocoded) {
      final screenPos = camera.latLngToScreenOffset(LatLng(stop.lat, stop.lng));
      if (pointInPolygon(screenPos, polygon)) {
        selected.add(stop.id);
      }
    }
    setState(() => _selectedStopIds = selected);
  }

  Offset _polygonCentroid(List<Offset> points) {
    if (points.isEmpty) return Offset.zero;
    var sx = 0.0;
    var sy = 0.0;
    for (final p in points) {
      sx += p.dx;
      sy += p.dy;
    }
    return Offset(sx / points.length, sy / points.length);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(stopsControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: stopsAsyncView(
        async,
        screenTag: 'ReorderPage',
        data: (context, stops) {
          if (stops.isEmpty) {
            return const Center(
              child: Text('Nenhuma parada para reordenar.'),
            );
          }
          final geocoded =
              stops.where((s) => s.isGeocoded).toList(growable: false);
          final points = [for (final s in geocoded) LatLng(s.lat, s.lng)];
          final topPad = MediaQuery.of(context).padding.top;
          final lassoCentroid = _draggedPoints.isEmpty
              ? Offset.zero
              : _polygonCentroid(_draggedPoints);

          return Stack(
            children: [
              Positioned.fill(
                child: _MapLayer(
                  mapController: _mapController,
                  points: points,
                  spBoundsSw: _spBoundsSw,
                  spBoundsNe: _spBoundsNe,
                  spCenter: _spCenter,
                  geocoded: geocoded,
                ),
              ),
              Positioned.fill(
                child: _LassoOverlay(
                  points: _draggedPoints,
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: () => _onPanEnd(geocoded),
                ),
              ),
              if (!_cardDismissed)
                Positioned(
                  top: topPad + 12,
                  left: 12,
                  right: 12,
                  child: _DispatcherCard(onClose: _dismissCard),
                ),
              if (_selectedStopIds.isNotEmpty && _draggedPoints.isNotEmpty)
                Positioned(
                  left: lassoCentroid.dx - 14,
                  top: lassoCentroid.dy - 14,
                  child: _LassoBadge(count: _selectedStopIds.length),
                ),
              if (_draggedPoints.isNotEmpty)
                Positioned(
                  left: 14,
                  bottom: 220,
                  child: _UndoPill(onPressed: _clearLasso),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _BottomPanel(
                  selectedCount: _selectedStopIds.length,
                  onClearGroup: _clearLasso,
                  onReoptimize: _onReoptimize,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Full-screen FlutterMap layer: OSM tiles, straight-line route polyline
/// (slice-3 swaps for GraphHopper geometry), numbered RpMiniPin markers
/// anchored bottom-center on each stop.
class _MapLayer extends StatelessWidget {
  const _MapLayer({
    required this.mapController,
    required this.points,
    required this.spBoundsSw,
    required this.spBoundsNe,
    required this.spCenter,
    required this.geocoded,
  });

  final MapController mapController;
  final List<LatLng> points;
  final LatLng spBoundsSw;
  final LatLng spBoundsNe;
  final LatLng spCenter;
  final List<Stop> geocoded;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: points.isEmpty ? spCenter : points.first,
        initialZoom: 13,
        minZoom: 10,
        maxZoom: 19,
        interactionOptions: const InteractionOptions(
          // Disable map gestures so the lasso overlay above receives the
          // pan events unambiguously. Slice-3 may reintroduce a toggle.
          flags: InteractiveFlag.none,
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
                strokeWidth: 4,
                color: AppColors.primary,
                strokeCap: StrokeCap.round,
                strokeJoin: StrokeJoin.round,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            for (var i = 0; i < geocoded.length; i++)
              Marker(
                point: LatLng(geocoded[i].lat, geocoded[i].lng),
                width: 32,
                height: 30,
                alignment: Alignment.bottomCenter,
                child: RpMiniPin(index: i + 1),
              ),
          ],
        ),
        osmAttribution(),
      ],
    );
  }
}

/// Gesture-capturing overlay that records freeform pan strokes and paints
/// them as a red stroke (solid while panning, switched to dashed once the
/// stroke settles to match the prototype's static lasso state).
class _LassoOverlay extends StatefulWidget {
  const _LassoOverlay({
    required this.points,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  final List<Offset> points;
  final void Function(Offset position) onPanStart;
  final void Function(Offset position) onPanUpdate;
  final VoidCallback onPanEnd;

  @override
  State<_LassoOverlay> createState() => _LassoOverlayState();
}

class _LassoOverlayState extends State<_LassoOverlay> {
  bool _settled = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (d) {
        setState(() => _settled = false);
        widget.onPanStart(d.localPosition);
      },
      onPanUpdate: (d) {
        widget.onPanUpdate(d.localPosition);
      },
      onPanEnd: (_) {
        setState(() => _settled = true);
        widget.onPanEnd();
      },
      child: IgnorePointer(
        ignoring: true,
        child: CustomPaint(
          painter: _LassoPainter(points: widget.points, dashed: _settled),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _LassoPainter extends CustomPainter {
  _LassoPainter({required this.points, required this.dashed});

  final List<Offset> points;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = AppColors.error
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = ui.Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    if (!dashed) {
      canvas.drawPath(path, paint);
      return;
    }

    // Dashed render: walk the path metrics in 8-on/6-off chunks.
    const dashOn = 8.0;
    const dashOff = 6.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashOn;
        final segment = metric.extractPath(
          distance,
          next.clamp(0.0, metric.length),
        );
        canvas.drawPath(segment, paint);
        distance = next + dashOff;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LassoPainter old) =>
      old.points != points || old.dashed != dashed;
}

/// Translucent dispatcher card pinned near the top with persona avatar,
/// title, body and timestamp + close button. Mirrors prototype lines
/// 650-671.
class _DispatcherCard extends StatelessWidget {
  const _DispatcherCard({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    // Outer shadow lives on a DecoratedBox so the ClipRRect/BackdropFilter
    // inside doesn't clip it — same pattern map_stops_page.dart established
    // for floating controls. Prototype: prototipo/screens-e.jsx:654.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E1A1A2E),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            color: Colors.white.withValues(alpha: 0.95),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'D',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Despachante',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Spacer(),
                          Text(
                            '8:46',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1),
                      Text(
                        'Pode ir para Vila Nova Conceição primeiro?',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkResponse(
                  onTap: onClose,
                  radius: 16,
                  child: const Tooltip(
                    message: 'Fechar',
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.textMuted,
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

/// Small red circular badge with the selected count, sitting at the lasso
/// centroid. Mirrors prototype lines 696-702.
class _LassoBadge extends StatelessWidget {
  const _LassoBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: AppColors.error,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x80EF4444),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// White stadium pill bottom-left to undo the current lasso stroke. Mirrors
/// prototype lines 705-713.
class _UndoPill extends StatelessWidget {
  const _UndoPill({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(19),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          child: SizedBox(
            height: 38,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.refresh,
                  size: 14,
                  color: AppColors.text,
                ),
                SizedBox(width: 6),
                Text(
                  'Desfazer',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
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

/// Dispatcher panel pinned at the bottom: drag handle, count text, ghost
/// "Desenhar o grupo seguinte" CTA and neon "Reotimizar rota" CTA. Mirrors
/// prototype lines 716-732.
class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.selectedCount,
    required this.onClearGroup,
    required this.onReoptimize,
  });

  final int selectedCount;
  final VoidCallback onClearGroup;
  final VoidCallback onReoptimize;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x296C3FC5),
            blurRadius: 24,
            offset: Offset(0, -8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
              children: [
                TextSpan(
                  text: '$selectedCount paradas',
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ' selecionadas no grupo'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Prototype overrides ghost button height to 44 (screens-e.jsx:726)
          // instead of the RpGhostButton default of 52. Sized wrapper keeps
          // the shared widget unchanged.
          SizedBox(
            height: 44,
            child: RpGhostButton(
              label: 'Desenhar o grupo seguinte',
              icon: const Icon(
                Icons.show_chart,
                size: 18,
                color: AppColors.text,
              ),
              onPressed: onClearGroup,
            ),
          ),
          const SizedBox(height: 8),
          RpButton(
            label: 'Reotimizar rota',
            icon: const Icon(Icons.auto_awesome, size: 18),
            neon: true,
            onPressed: onReoptimize,
          ),
        ],
      ),
    );
  }
}

/// Standard ray-casting point-in-polygon test in screen space.
///
/// Extracted as a top-level `@visibleForTesting` helper because
/// `MapCamera.latLngToScreenOffset` requires a fully laid-out FlutterMap,
/// which the widget-test harness can't deterministically produce; pure-
/// function unit tests cover the geometry directly.
@visibleForTesting
bool pointInPolygon(Offset point, List<Offset> polygon) {
  var inside = false;
  final n = polygon.length;
  for (var i = 0, j = n - 1; i < n; j = i++) {
    final pi = polygon[i];
    final pj = polygon[j];
    // The `+ 1e-12` epsilon avoids a divide-by-zero when the polygon
    // contains a perfectly horizontal edge (pj.dy == pi.dy).
    final intersect = ((pi.dy > point.dy) != (pj.dy > point.dy)) &&
        (point.dx <
            (pj.dx - pi.dx) * (point.dy - pi.dy) / ((pj.dy - pi.dy) + 1e-12) +
                pi.dx);
    if (intersect) inside = !inside;
  }
  return inside;
}
