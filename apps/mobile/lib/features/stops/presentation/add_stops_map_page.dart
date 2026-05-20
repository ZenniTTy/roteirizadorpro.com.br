import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/services/id.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/rp_button.dart';
import '../../../core/widgets/rp_ghost_button.dart';
import '../../../core/widgets/rp_mini_pin.dart';
import '../domain/stop.dart';
import '../state/stops_controller.dart';
import 'shared/map_attribution.dart';

class AddStopsMapPage extends ConsumerStatefulWidget {
  const AddStopsMapPage({
    super.key,
    this.onConfirmed,
    this.onEditAfterAdd,
    this.onBack,
    this.initialPending,
  });

  /// Nullable so widget tests can assert taps without standing up a GoRouter;
  /// production falls through to `context.pop()` (or `/home` if deep-linked).
  final void Function(BuildContext context)? onConfirmed;

  /// Called when the user taps "Adicionar e editar" — production pushes the
  /// EditStop route for the just-added stop; tests can intercept.
  final void Function(BuildContext context, String stopId)? onEditAfterAdd;

  /// Symmetric back callback; production falls through to pop/go('/home').
  final void Function(BuildContext context)? onBack;

  /// Seeds the pending-pin list and selects the last entry. Lets widget
  /// tests exercise the bottom-sheet branch without simulating a map tap
  /// (flutter_map swallows synthetic pointer events at the layer level).
  @visibleForTesting
  final List<LatLng>? initialPending;

  @override
  ConsumerState<AddStopsMapPage> createState() => _AddStopsMapPageState();
}

class _AddStopsMapPageState extends ConsumerState<AddStopsMapPage> {
  static const _spCenter = LatLng(-23.55, -46.63);
  static const _spBoundsSw = LatLng(-23.78, -46.83);
  static const _spBoundsNe = LatLng(-23.36, -46.40);

  // TODO(slice-5): replace this hardcoded "home" coordinate with the
  // sentido-casa value from settings once that lands.
  static const _homePoint = LatLng(-23.561, -46.625);

  final List<LatLng> _pending = [];
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialPending;
    if (seed != null && seed.isNotEmpty) {
      _pending.addAll(seed);
      _selectedIndex = seed.length - 1;
    }
  }

  LatLng? get _selected {
    final i = _selectedIndex;
    if (i == null || i < 0 || i >= _pending.length) return null;
    return _pending[i];
  }

  void _onTap(TapPosition _, LatLng point) {
    setState(() {
      _pending.add(point);
      _selectedIndex = _pending.length - 1;
    });
  }

  void _selectPin(int index) {
    setState(() => _selectedIndex = index);
  }

  void _undo() {
    if (_pending.isEmpty) return;
    setState(() {
      _pending.removeLast();
      _selectedIndex = _pending.isEmpty ? null : _pending.length - 1;
    });
  }

  Future<List<String>> _persistPending() async {
    final controller = ref.read(stopsControllerProvider.notifier);
    final now = DateTime.now();
    final ids = <String>[];
    for (final p in _pending) {
      final id = newId();
      await controller.add(
        Stop(
          id: id,
          lat: p.latitude,
          lng: p.longitude,
          source: StopSource.mapTap,
          createdAt: now,
        ),
      );
      ids.add(id);
    }
    return ids;
  }

  Future<void> _confirm() async {
    if (_pending.isEmpty) return;
    await _persistPending();
    if (!mounted) return;
    (widget.onConfirmed ??
        (ctx) => ctx.canPop() ? ctx.pop() : ctx.go('/home'))(context);
  }

  Future<void> _addAndEdit() async {
    if (_pending.isEmpty) return;
    // Capture which pin the user currently sees in the bottom sheet BEFORE
    // persisting — `_persistPending` returns ids in `_pending` order, so the
    // selected pin's new id is `ids[selectedIndex]`. Routing to `ids.last`
    // would silently send the user to whatever they tapped most recently,
    // not what's actually open in the sheet (D4 I1 fix).
    final targetIndex = _selectedIndex ?? _pending.length - 1;
    final ids = await _persistPending();
    if (!mounted) return;
    final targetId = ids[targetIndex];
    (widget.onEditAfterAdd ?? (ctx, id) => ctx.push('/home/stops/$id/edit'))(
      context,
      targetId,
    );
  }

  void _handleBack() {
    (widget.onBack ??
        (ctx) => ctx.canPop() ? ctx.pop() : ctx.go('/home'))(context);
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final selected = _selected;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
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
                  userAgentPackageName:
                      'br.com.roteirizadorpro.roteirizador_pro',
                  retinaMode: RetinaMode.isHighDensity(context),
                  maxNativeZoom: 19,
                ),
                if (selected != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: selected,
                        width: 60,
                        height: 60,
                        alignment: Alignment.bottomCenter,
                        child: const _SelectionHalo(),
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    const Marker(
                      point: _homePoint,
                      width: 30,
                      height: 30,
                      alignment: Alignment.bottomCenter,
                      child: IgnorePointer(child: _HomePin()),
                    ),
                    for (var i = 0; i < _pending.length; i++)
                      Marker(
                        point: _pending[i],
                        width: 32,
                        height: 32,
                        alignment: Alignment.bottomCenter,
                        child: RpMiniPin(
                          index: i + 1,
                          selected: i == _selectedIndex,
                          onPressed: () => _selectPin(i),
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
            child: _FloatingHeader(
              onBack: _handleBack,
              onUndo: _pending.isNotEmpty ? _undo : null,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) => SlideTransition(
                position: animation.drive(
                  Tween(begin: const Offset(0, 1), end: Offset.zero)
                      .chain(CurveTween(curve: Curves.easeOut)),
                ),
                child: child,
              ),
              child: selected != null
                  ? _SelectedSheet(
                      key: const ValueKey('sheet'),
                      selected: selected,
                      index: _selectedIndex! + 1,
                      onAdd: _confirm,
                      onAddAndEdit: _addAndEdit,
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingHeader extends StatelessWidget {
  const _FloatingHeader({required this.onBack, this.onUndo});
  final VoidCallback onBack;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(
          icon: Icons.arrow_back,
          tooltip: 'Voltar',
          onPressed: onBack,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: const BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.all(Radius.circular(20)),
              boxShadow: AppShadows.floatingCircle,
            ),
            child: const Row(
              children: [
                Icon(Icons.search, size: 16, color: AppColors.textMuted),
                SizedBox(width: 8),
                Text(
                  'Buscar endereço…',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (onUndo != null) ...[
          const SizedBox(width: 8),
          _CircleButton(
            icon: Icons.undo,
            tooltip: 'Desfazer última',
            onPressed: onUndo,
            keyValue: const Key('add-stops-map-undo'),
          ),
        ],
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.keyValue,
  });
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Key? keyValue;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        key: keyValue,
        color: AppColors.bg,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Tooltip(
            message: tooltip,
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: AppShadows.floatingCircle,
              ),
              child: Icon(
                icon,
                size: 18,
                color: onPressed == null ? AppColors.textMuted : AppColors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomePin extends StatelessWidget {
  const _HomePin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x804E2D91),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.home, size: 14, color: Colors.white),
    );
  }
}

class _SelectionHalo extends StatelessWidget {
  const _SelectionHalo();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _SelectedSheet extends StatelessWidget {
  const _SelectedSheet({
    super.key,
    required this.selected,
    required this.index,
    required this.onAdd,
    required this.onAddAndEdit,
  });

  final LatLng selected;
  final int index;
  final VoidCallback onAdd;
  final VoidCallback onAddAndEdit;

  @override
  Widget build(BuildContext context) {
    final coords =
        '${selected.latitude.toStringAsFixed(5)}, ${selected.longitude.toStringAsFixed(5)}';
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x296C3FC5),
              blurRadius: 32,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Parada $index',
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // TODO(slice-3): replace lat/lng with the
                          // Nominatim-resolved address once geocoding lands.
                          Text(
                            coords,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Inline edit icon — same action as the ghost button at
                    // the bottom of the sheet. The prototype intentionally
                    // shows both affordances (`prototipo/screens-e.jsx:139-145`
                    // and :149); do NOT collapse to a single button.
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: Material(
                        color: AppColors.bg,
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(
                            color: AppColors.border,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: InkWell(
                          onTap: onAddAndEdit,
                          borderRadius: BorderRadius.circular(18),
                          child: const Tooltip(
                            message: 'Adicionar e editar',
                            child: Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                RpButton(
                  key: const Key('add-stops-map-confirm'),
                  label: 'Adicionar parada',
                  icon: const Icon(Icons.add),
                  onPressed: onAdd,
                ),
                const SizedBox(height: 8),
                RpGhostButton(
                  label: 'Adicionar e editar',
                  onPressed: onAddAndEdit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
