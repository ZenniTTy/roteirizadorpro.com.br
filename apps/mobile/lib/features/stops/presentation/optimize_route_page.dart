import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/external_nav.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/rp_button.dart';
import '../../../core/widgets/rp_mini_pin.dart';
import '../domain/stop.dart';
import '../state/stops_controller.dart';
import 'shared/map_attribution.dart';
import 'shared/stops_async_view.dart';

/// Post-optimize preview screen per prototipo/screens-e.jsx:157-297.
/// Split layout: top map (numbered RpMiniPin markers + origin dot +
/// straight-line polyline — real road geometry arrives with GraphHopper in
/// slice 3) overlaid by a floating close button and an "ROTA OTIMIZADA"
/// pulsing badge, plus a bottom sheet with search bar, title, action chips,
/// optional ungeocoded banner, stops list and the "Iniciar navegação" CTA
/// that delegates to ExternalNav per ADR-0017 (Waze default, Google Maps
/// chunked for >10 stops).
class OptimizeRoutePage extends ConsumerStatefulWidget {
  const OptimizeRoutePage({
    super.key,
    this.onNavigateStarted,
    this.onClose,
  });

  /// Callback injection for widget tests; production routes via GoRouter.
  final void Function(BuildContext context)? onNavigateStarted;

  /// Callback injection for the floating close button. Production default:
  /// pop when possible, otherwise go home.
  final void Function(BuildContext context)? onClose;

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

  void _handleClose() {
    (widget.onClose ??
        (ctx) => ctx.canPop() ? ctx.pop() : ctx.go('/home'))(context);
  }

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
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: stopsAsyncView(
        async,
        screenTag: 'OptimizeRoutePage',
        data: (context, stops) {
          final geocoded = stops.where((s) => s.isGeocoded).toList();
          final ungeocodedCount = stops.length - geocoded.length;
          final points = [for (final s in geocoded) LatLng(s.lat, s.lng)];
          final topPad = MediaQuery.of(context).padding.top;

          return Stack(
            children: [
              _MapLayer(
                points: points,
                spBoundsSw: _spBoundsSw,
                spBoundsNe: _spBoundsNe,
              ),
              _BottomSheet(
                stops: stops,
                geocoded: geocoded,
                ungeocodedCount: ungeocodedCount,
                onStart: () => _start(geocoded),
              ),
              Positioned(
                top: topPad + 12,
                left: 12,
                child: _CloseButton(onPressed: _handleClose),
              ),
              Positioned(
                top: topPad + 12,
                right: 12,
                child: const _OptimizedBadge(),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Top-half map (height 460) — numbered RpMiniPin markers, straight-line
/// polyline (slice-3 will swap for GraphHopper geometry), origin dot at
/// `geocoded[0]`. SP bbox + OSM attribution preserved verbatim from the
/// previous implementation.
class _MapLayer extends StatelessWidget {
  const _MapLayer({
    required this.points,
    required this.spBoundsSw,
    required this.spBoundsNe,
  });

  final List<LatLng> points;
  final LatLng spBoundsSw;
  final LatLng spBoundsNe;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 460,
      child: FlutterMap(
        options: MapOptions(
          initialCenter:
              points.isEmpty ? const LatLng(-23.5505, -46.6333) : points.first,
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
          // TODO(slice-3): end flag pin at geocoded.last (prototipo/screens-e.jsx:192-199)
          MarkerLayer(
            markers: [
              if (points.isNotEmpty)
                Marker(
                  point: points.first,
                  width: 22,
                  height: 22,
                  child: const _OriginDot(),
                ),
              for (var i = 0; i < points.length; i++)
                Marker(
                  point: points[i],
                  width: 32,
                  height: 32,
                  alignment: Alignment.bottomCenter,
                  child: RpMiniPin(index: i + 1),
                ),
            ],
          ),
          osmAttribution(),
        ],
      ),
    );
  }
}

/// Floating close button (40x40 white circle) overlaying the map. Mirrors
/// `prototipo/screens-e.jsx:213-220`.
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          shape: BoxShape.circle,
          boxShadow: AppShadows.floatingCircle,
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: const Tooltip(
              message: 'Fechar',
              child: Icon(
                Icons.arrow_back,
                size: 20,
                color: AppColors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "ROTA OTIMIZADA" pill badge with a pulsing dot. Mirrors
/// `prototipo/screens-e.jsx:222-240`.
class _OptimizedBadge extends StatelessWidget {
  const _OptimizedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.neon,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80C6FF3D),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingDot(),
          SizedBox(width: 6),
          Text(
            'ROTA OTIMIZADA',
            style: TextStyle(
              color: AppColors.neonInk,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// 1s repeating pulsing dot (opacity 0.35 <-> 1.0). Reuses the animation
/// shape from `_LiveChipState` in `map_stops_page.dart:399-471`.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
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
    return FadeTransition(
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
    );
  }
}

/// Origin marker — 16x16 primary disc with 3px white border, drop shadow.
/// Mirrors prototype line 189.
class _OriginDot extends StatelessWidget {
  const _OriginDot();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: Center(
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x806C3FC5),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet (top:420 bottom:0) — drag handle, fake search bar, title
/// "São Paulo · N paradas", action chips, optional ungeocoded banner, list
/// of stops, "Iniciar navegação" CTA. Mirrors `prototipo/screens-e.jsx:
/// 242-296`.
class _BottomSheet extends StatelessWidget {
  const _BottomSheet({
    required this.stops,
    required this.geocoded,
    required this.ungeocodedCount,
    required this.onStart,
  });

  final List<Stop> stops;
  final List<Stop> geocoded;
  final int ungeocodedCount;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 420,
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadii.sheet),
            topRight: Radius.circular(AppRadii.sheet),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x296C3FC5),
              blurRadius: 32,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _SearchBar(),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'São Paulo · ${stops.length} paradas',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _ActionChips(),
            ),
            if (ungeocodedCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(AppRadii.input),
                  ),
                  child: Text(
                    '$ungeocodedCount paradas sem geocodificação ficam '
                    'fora da navegação até o slice 3 (Nominatim).',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: stops.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.border),
                itemBuilder: (context, i) =>
                    _StopRow(index: i + 1, stop: stops[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Semantics(
                button: true,
                label: 'Iniciar navegação',
                child: RpButton(
                  label: 'Iniciar navegação',
                  icon: const Icon(Icons.navigation_outlined),
                  neon: true,
                  onPressed: geocoded.isEmpty ? null : onStart,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Static (non-functional) search bar matching `prototipo/screens-e.jsx:
/// 245-252`. Wiring search comes with slice-3.
class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    // TODO(slice-3): wire fuzzy search across the optimized stops list.
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.search, size: 16, color: AppColors.textMuted),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Adicione ou busque',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.camera_alt_outlined, size: 16, color: AppColors.textMuted),
          SizedBox(width: 8),
          Icon(Icons.mic_none, size: 16, color: AppColors.textMuted),
          SizedBox(width: 8),
          Icon(Icons.more_vert, size: 16, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

/// Two stadium-shaped chips: "Compartilhar rota" (active) and "Carregar
/// veículo" (disabled — placeholder for the cargo-loading flow that arrives
/// in a later slice). Mirrors `prototipo/screens-e.jsx:254-272`.
class _ActionChips extends StatelessWidget {
  const _ActionChips();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // TODO(slice-3): wire share intent (text + deep link) for the
        // optimized route. Placeholder onPressed keeps the chip active so
        // the prototype's visual hierarchy holds.
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.border, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size.fromHeight(36),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            icon: const Icon(Icons.ios_share, size: 16),
            label: const Text('Compartilhar rota'),
          ),
        ),
        const SizedBox(width: 8),
        // TODO(slice-later): cargo-loading screen.
        Expanded(
          child: OutlinedButton.icon(
            onPressed: null,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textMuted,
              side: const BorderSide(color: AppColors.border, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size.fromHeight(36),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            icon: const Icon(Icons.inventory_2_outlined, size: 16),
            label: const Text('Carregar veículo'),
          ),
        ),
      ],
    );
  }
}

/// List row — leading 28x28 numbered circle (white bg, 1.5px primary
/// border, primary digit), home-row indicator for index 1, title=label or
/// fallback, subtitle=coords-or-status, trailing ETA placeholder. Mirrors
/// `prototipo/screens-e.jsx:274-292`.
class _StopRow extends StatelessWidget {
  const _StopRow({required this.index, required this.stop});

  final int index;
  final Stop stop;

  @override
  Widget build(BuildContext context) {
    final isHome = index == 1;
    final title = stop.label ?? 'Sem endereço';
    // TODO(slice-3): subtitle from reverse-geocoded complement.
    final subtitle = stop.isGeocoded
        ? '${stop.lat.toStringAsFixed(5)}, ${stop.lng.toStringAsFixed(5)}'
        : 'Sem geocodificação';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isHome)
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.home_outlined,
                size: 14,
                color: AppColors.primary,
              ),
            )
          else
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                '${index - 1}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // TODO(slice-3): wire ETA per stop from GraphHopper leg duration.
          if (stop.isGeocoded)
            const Text(
              '—',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            const Icon(
              Icons.location_off,
              size: 18,
              color: AppColors.textMuted,
            ),
        ],
      ),
    );
  }
}
