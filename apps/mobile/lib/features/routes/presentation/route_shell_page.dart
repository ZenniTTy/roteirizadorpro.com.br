import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import 'widgets/app_drawer.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shell that hosts the active route's map + sheet.
///
/// Layout per Spoke v3.65.1 live dump 2026-05-27 (bounds reference 1080×2400):
///   - Map full-screen behind everything
///   - Floating circular hamburger top-left abre [AppDrawer]
///   - 2 floating circular map controls direita (layer toggle + recenter)
///     stub visual; wiring real em Área 3
///   - Sheet collapsed no rodapé com search pill estilo input clicável
///     contendo OCR + Voice + kebab como suffix icons
///
/// Todos os controles "stub Slice 2" disparam um SnackBar "em breve" pra
/// nunca dar a impressão de botão quebrado pro usuário (silent-failure
/// guard).
class RouteShellPage extends ConsumerWidget {
  const RouteShellPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mq = MediaQuery.of(context);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(-23.550520, -46.633308), // São Paulo
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'br.com.roteirizadorpro.roteirizador_pro',
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
                  ),
                ],
              ),
            ],
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
            bottom: 12,
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
          const _ActiveRouteSheet(),
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
  const _ActiveRouteSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.12,
      minChildSize: 0.12,
      maxChildSize: 0.9,
      snap: true,
      snapSizes: const [0.12, 0.5, 0.9],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Search Input Simulation
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.btn),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadii.btn),
                    onTap: () => _comingSoon(context, 'Adicionar parada'),
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(AppRadii.btn),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.search, color: AppColors.textMuted, size: 18),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Toque para adicionar',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 15),
                            ),
                          ),
                          _SuffixIcon(
                            semanticsLabel: 'Ler etiqueta de endereço',
                            icon: LucideIcons.scanLine,
                            onTap: () => _comingSoon(context, 'Ler etiqueta'),
                          ),
                          const SizedBox(width: 4),
                          _SuffixIcon(
                            semanticsLabel: 'Dite o endereço',
                            icon: LucideIcons.mic,
                            onTap: () => _comingSoon(context, 'Ditar endereço'),
                          ),
                          const SizedBox(width: 4),
                          _SuffixIcon(
                            semanticsLabel: 'Mais opções da rota',
                            icon: LucideIcons.ellipsisVertical,
                            onTap: () => _comingSoon(context, 'Opções da rota'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Divider(color: AppColors.border),
              // Empty List Area
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SizedBox(height: 32),
                    const Center(
                      child: Text(
                        'Nenhuma parada adicionada',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: () => _comingSoon(context, 'Importar planilha'),
                        icon: const Icon(LucideIcons.fileSpreadsheet, color: AppColors.primary),
                        label: const Text('Importar paradas', style: TextStyle(color: AppColors.primary)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SuffixIcon extends StatelessWidget {
  const _SuffixIcon({
    required this.semanticsLabel,
    required this.icon,
    required this.onTap,
  });

  final String semanticsLabel;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, color: AppColors.textMuted, size: 18),
        ),
      ),
    );
  }
}
