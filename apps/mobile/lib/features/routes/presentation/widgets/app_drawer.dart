import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/route_action.dart';
import '../../state/active_route_provider.dart';
import '../../state/current_user_provider.dart';
import '../../state/routes_provider.dart';
import 'drawer_header_card.dart';
import 'drawer_route_list.dart';

/// Bottom-sheet surface listing all the user's routes, opened by tapping
/// the floating hamburger on the [RouteShellPage]. Per Spoke v3.65.1 ao vivo
/// (dump 2026-05-27): is a modal bottom sheet covering nearly the full
/// screen with an X close at the top-left, draggable to dismiss.
///
/// Composes: top icons (X close + Help PopupMenu + Settings) + header card
/// (avatar/name/email/plan/subscribe) + grouped route list + "Criar rota"
/// CTA pinned to bottom — always above the system nav bar via SafeArea.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  /// Opens this surface as a modal bottom sheet. `useSafeArea: true` keeps
  /// the body away from the status bar / camera notch; the CTA at the
  /// bottom of the body wraps in [SafeArea] to clear the system gesture
  /// inset.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: AppColors.bg,
      barrierColor: Colors.black54,
      // Material clamps `isScrollControlled` to ~95% by default; combined
      // with `useSafeArea: true` this guarantees we never overlap the
      // status bar nor the gesture inset.
      constraints: const BoxConstraints(maxWidth: double.infinity),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.sheet),
        ),
      ),
      builder: (_) => const AppDrawer(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final routes = ref.watch(routesProvider);
    final activeRouteId = ref.watch(activeRouteIdProvider);

    return DraggableScrollableSheet(
      initialChildSize: 1.0,
      minChildSize: 0.5,
      maxChildSize: 1.0,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Top bar: X close on the left; Help (PopupMenu) and Settings
            // on the right. Spoke parity §10.1 amendment 2026-05-27.
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Semantics(
                    label: 'Fechar',
                    button: true,
                    child: IconButton(
                      icon: const Icon(LucideIcons.x),
                      color: AppColors.text,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  _TopActions(
                    onHelp: () => _showHelpMenu(context),
                    onSettings: () => _comingSoon(context, 'Configurações'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeaderCard(
                    user: user,
                    onHelp: () {},
                    onSettings: () {},
                    onSubscribe: () => _comingSoon(context, 'Assinar'),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  DrawerRouteList(
                    routes: routes,
                    activeRouteId: activeRouteId,
                    onRouteTap: (route) {
                      ref
                          .read(activeRouteIdProvider.notifier)
                          .setActiveRoute(route.id);
                      Navigator.of(context).pop();
                    },
                    onRouteKebabAction: (route, action) =>
                        _comingSoon(context, _kebabActionLabel(action)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            // CTA "Criar rota" — pinned to bottom, always above system
            // gesture inset thanks to SafeArea(top: false).
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: FilledButton.icon(
                  onPressed: () => _comingSoon(context, 'Criar rota'),
                  icon: const Icon(LucideIcons.plus),
                  label: const Text('Criar rota'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.btn),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showHelpMenu(BuildContext context) {
    final overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromLTRB(
      overlay.size.width - 220,
      88,
      8,
      overlay.size.height,
    );
    showMenu<String>(
      context: context,
      position: position,
      items: const [
        PopupMenuItem(value: 'support', child: Text('Ajuda e suporte')),
        PopupMenuItem(value: 'feedback', child: Text('Compartilhar feedback')),
      ],
    ).then((value) {
      if (value != null && context.mounted) {
        _comingSoon(
          context,
          value == 'support' ? 'Ajuda e suporte' : 'Compartilhar feedback',
        );
      }
    });
  }

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — em breve')),
    );
  }

  String _kebabActionLabel(RouteAction action) => switch (action) {
        RouteAction.editMeta => 'Definir nome e data',
        RouteAction.duplicate => 'Duplicar rota',
        RouteAction.delete => 'Excluir rota',
      };
}

class _TopActions extends StatelessWidget {
  const _TopActions({required this.onHelp, required this.onSettings});
  final VoidCallback onHelp;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: 'Ajuda',
          button: true,
          child: IconButton(
            icon: const Icon(LucideIcons.circleHelp),
            color: AppColors.textMuted,
            onPressed: onHelp,
          ),
        ),
        Semantics(
          label: 'Configurações',
          button: true,
          child: IconButton(
            icon: const Icon(LucideIcons.settings),
            color: AppColors.textMuted,
            onPressed: onSettings,
          ),
        ),
      ],
    );
  }
}
