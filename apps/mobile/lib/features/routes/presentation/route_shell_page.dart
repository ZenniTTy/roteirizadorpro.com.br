import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import 'widgets/app_drawer.dart';

/// Shell that hosts the active route's map + sheet.
///
/// Layout per Spoke v3.65.1 live dump 2026-05-27 (bounds reference 1080×2400):
///   - Map full-screen behind everything
///   - Floating circular hamburger top-left (~24dp icon dentro de 48dp circle)
///     em `Positioned(top: safeTop+12, left: 16)` — abre [AppDrawer] como
///     modal bottom sheet
///   - 2 floating circular map controls direita (layer toggle + recenter)
///     stub visual; wiring real em Área 3
///   - Sheet collapsed no rodapé com search pill estilo input clicável
///     contendo OCR + Voice + kebab como suffix icons
class RouteShellPage extends ConsumerWidget {
  const RouteShellPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mq = MediaQuery.of(context);

    return Scaffold(
      // Sheet collapsed fica grudado ao bottom via bottomNavigationBar —
      // isso garante que ele respeita inset do system nav bar automaticamente
      // (não precisa de SafeArea manual).
      bottomNavigationBar: const _SheetCollapsed(),
      body: Stack(
        children: [
          const ColoredBox(
            color: AppColors.surface,
            child: SizedBox.expand(),
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
                  onTap: () {},
                  iconColor: AppColors.primary,
                ),
                const SizedBox(height: 12),
                _FloatingCircleButton(
                  semanticsLabel: 'Alternar para o mapa',
                  icon: LucideIcons.locateFixed,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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

/// Search pill collapsed at the bottom of the shell.
///
/// Per Spoke parity §10.5 live dump 2026-05-27: a single rounded container
/// presenting search icon + grey placeholder + OCR/Voice/Kebab suffix icons
/// (all inside the same pill, NOT separate buttons after).
class _SheetCollapsed extends StatelessWidget {
  const _SheetCollapsed();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Material(
          color: AppColors.bg,
          elevation: 6,
          shadowColor: const Color(0x296C3FC5),
          borderRadius: BorderRadius.circular(AppRadii.btn),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.btn),
            onTap: () {
              // TODO(Área 4): navegar pra "Adicionar parada" entry.
            },
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(AppRadii.btn),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.search,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Toque para adicionar',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  _SuffixIcon(
                    semanticsLabel: 'Ler etiqueta de endereço',
                    icon: LucideIcons.scanLine,
                    onTap: () {},
                  ),
                  const SizedBox(width: 4),
                  _SuffixIcon(
                    semanticsLabel: 'Dite o endereço',
                    icon: LucideIcons.mic,
                    onTap: () {},
                  ),
                  const SizedBox(width: 4),
                  _SuffixIcon(
                    semanticsLabel: 'Mais opções da rota',
                    icon: LucideIcons.ellipsisVertical,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
