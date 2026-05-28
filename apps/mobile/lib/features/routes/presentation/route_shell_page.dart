import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import 'widgets/app_drawer.dart';

/// Shell that hosts the active route's map + sheet.
///
/// Layout per Spoke v3.65.1 live dump 2026-05-27 (bounds reference 1080×2400):
///   - Map full-screen behind everything
///   - Floating circular hamburger top-left abre [AppDrawer]
///   - 2 floating circular map controls direita (layer toggle + recenter)
///     stub visual; wiring real em Área 3
///   - Sheet collapsed no rodapé com search pill estilo input clicável
///     contendo OCR + Voice + kebab como suffix icons
class RouteShellPage extends ConsumerStatefulWidget {
  const RouteShellPage({super.key});

  @override
  ConsumerState<RouteShellPage> createState() => _RouteShellPageState();
}

class _RouteShellPageState extends ConsumerState<RouteShellPage> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  double? _sheetPosition; // Tracks the DraggableScrollableSheet size

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(-23.550520, -46.633308), // São Paulo
    zoom: 13.0,
  );

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomPadding = mq.padding.bottom;

    // Ensure the sheet is tall enough to show the handle and search bar above the system nav bar
    final minHeightPx = 130.0 + bottomPadding;
    final minChildSize = (minHeightPx / mq.size.height).clamp(0.15, 0.35);

    _sheetPosition ??= minChildSize;

    // Convert sheet position to pixels and add margin to keep buttons above the sheet
    final sheetHeightPx = mq.size.height * _sheetPosition!;
    final buttonsBottom = sheetHeightPx + 48;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialPosition,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            myLocationButtonEnabled: false,
            compassEnabled: false,
          ),
          Positioned(
            top: mq.padding.top + 12,
            left: 16,
            child: _FloatingCircleButton(
              semanticsLabel: 'Abrir menu',
              icon: LucideIcons.menu,
              onTap: () => AppDrawer.show(context),
            ),
          ),
          Positioned(
            right: 16,
            bottom: buttonsBottom,
            child: Column(
              children: [
                _FloatingCircleButton(
                  semanticsLabel: 'Alternar modo de mapa',
                  icon: LucideIcons.layers,
                  onTap: () => _comingSoon(context, 'Alternar modo de mapa'),
                  iconColor: AppColors.primary,
                ),
                const SizedBox(height: 12),
                _FloatingCircleButton(
                  semanticsLabel: 'Alternar para o mapa',
                  icon: LucideIcons.locateFixed,
                  onTap: () => _comingSoon(context, 'Centrar no mapa'),
                ),
              ],
            ),
          ),
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              setState(() => _sheetPosition = notification.extent);
              return true;
            },
            child: _ActiveRouteSheet(minChildSize: minChildSize),
          ),
        ],
      ),
    );
  }
}

void _comingSoon(BuildContext context, String label) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$label — em breve')),
  );
}

class _FloatingCircleButton extends StatelessWidget {
  const _FloatingCircleButton({
    required this.semanticsLabel,
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  final String semanticsLabel;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: Material(
        color: AppColors.bg,
        shape: const CircleBorder(),
        elevation: 4,
        shadowColor: const Color(0x2E1A1A2E),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, size: 22, color: iconColor ?? AppColors.text),
          ),
        ),
      ),
    );
  }
}

class _ActiveRouteSheet extends StatelessWidget {
  const _ActiveRouteSheet({required this.minChildSize});

  final double minChildSize;

  @override
  Widget build(BuildContext context) {
    // Use a fixed small minChildSize so it snaps to Search Pill only
    final double smallSize =
        (110 / MediaQuery.sizeOf(context).height).clamp(0.12, 0.2);

    return DraggableScrollableSheet(
      initialChildSize: smallSize,
      minChildSize: smallSize,
      maxChildSize: 0.9,
      snap: true,
      snapSizes: [smallSize, 0.4, 0.9],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black26, blurRadius: 10, offset: Offset(0, -2))
            ],
          ),
          // CustomScrollView ao invés de ListView para que o gesto de arraste
          // na área vazia ABAIXO do conteúdo expanda o sheet (e não scrolle
          // conteúdo interno fantasma). O SliverFillRemaining no fim com
          // `hasScrollBody: false` faz o filler NÃO consumir o gesto — ele
          // chega no DraggableScrollableSheet pai, que arrasta o sheet.
          // Já o conteúdo real (handle, pílula, botões) está em
          // SliverToBoxAdapters — esses consomem o scroll só quando o sheet
          // já está expandido, replicando o feel do Spoke / Google Maps.
          // Referência: api.flutter.dev/flutter/widgets/SliverFillRemaining/
          //   hasScrollBody.html + flutter/flutter#35758.
          child: CustomScrollView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildSheetContent(context)),
              const SliverFillRemaining(
                hasScrollBody: false,
                fillOverscroll: true,
                child: SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Real content of the sheet — drag handle + search pill + 2 big buttons.
  /// Extraído para um método pra manter o `slivers:` legível e isolar a
  /// estrutura de gesto (CustomScrollView + SliverFillRemaining) do layout.
  Widget _buildSheetContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Drag Handle
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Top Action Row (Search Pill + Kebab)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Search Pill
              Expanded(
                child: InkWell(
                  onTap: () => context.push('/home/routes/add-stop'),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.only(left: 12, right: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.search,
                            color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Adicionar parada...',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _SearchInnerButton(
                          icon: LucideIcons.camera,
                          onTap: () => _comingSoon(context, 'Leitor OCR'),
                        ),
                        const SizedBox(width: 4),
                        _SearchInnerButton(
                          icon: LucideIcons.mic,
                          onTap: () => _comingSoon(context, 'Comando de Voz'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Kebab Menu
              _GradientCircleButton(
                icon: LucideIcons.moreVertical,
                semanticsLabel: 'Opções da rota',
                onTap: () => _comingSoon(context, 'Opções da Rota'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // 2 Big Buttons (Medium state content)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _SheetBigButton(
                icon: LucideIcons.plusCircle,
                label: 'Adicionar paradas',
                onTap: () => context.push('/home/routes/add-stop'),
              ),
              const SizedBox(height: 12),
              _SheetBigButton(
                icon: LucideIcons.copy,
                label: 'Copiar paradas de uma rota anterior',
                onTap: () => _comingSoon(context, 'Copiar paradas'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature em breve')),
    );
  }
}

class _SearchInnerButton extends StatelessWidget {
  const _SearchInnerButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
    );
  }
}

class _SheetBigButton extends StatelessWidget {
  const _SheetBigButton(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientCircleButton extends StatelessWidget {
  const _GradientCircleButton({
    required this.icon,
    required this.semanticsLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        elevation: 4,
        shadowColor: AppColors.primary.withValues(alpha: 0.3),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(icon, size: 22, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
