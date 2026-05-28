import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/state/auth_controller.dart';
import '../../domain/route_action.dart';
import '../../domain/route.dart' as rp_route;
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
                    onHelp: (action) => _handleHelpAction(context, ref, action),
                    onSettings: () => _comingSoon(context, 'Configurações'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: DrawerRouteList(
                scrollController: scrollController,
                routes: routes,
                activeRouteId: activeRouteId,
                headerSlot: DrawerHeaderCard(
                  user: user,
                  onSubscribe: () => _comingSoon(context, 'Assinar'),
                ),
                onRouteTap: (route) {
                  ref
                      .read(activeRouteIdProvider.notifier)
                      .setActiveRoute(route.id);
                  if (context.mounted) Navigator.of(context).pop();
                },
                onRouteKebabAction: (route, action) =>
                    _handleRouteKebabAction(context, ref, route, action),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/home/routes/create');
                  },
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

  Future<void> _handleHelpAction(
    BuildContext context,
    WidgetRef ref,
    _HelpAction action,
  ) async {
    switch (action) {
      case _HelpAction.support:
        _comingSoon(context, 'Ajuda e suporte');
      case _HelpAction.feedback:
        _comingSoon(context, 'Compartilhar feedback');
      case _HelpAction.signOut:
        // Temporary affordance until Settings (Área 10) lands a real Sair row.
        // Without this, after login the user has no path back to /login.
        await ref.read(authControllerProvider.notifier).signOut();
        if (context.mounted) Navigator.of(context).pop();
    }
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

  Future<void> _handleRouteKebabAction(
    BuildContext context,
    WidgetRef ref,
    rp_route.Route route,
    RouteAction action,
  ) async {
    switch (action) {
      case RouteAction.editMeta:
        // TODO: Pass route parameter to wizard when implemented
        _comingSoon(context, 'Definir nome e data');
      case RouteAction.duplicate:
        ref.read(routesProvider.notifier).duplicateRoute(route.id);
        if (context.mounted) Navigator.of(context).pop();
      case RouteAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.bg,
            title: const Text('Excluir esta rota?', style: TextStyle(color: AppColors.text)),
            content: const Text('Esta ação não pode ser desfeita.', style: TextStyle(color: AppColors.textMuted)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar', style: TextStyle(color: AppColors.text)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Excluir', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

        if (confirmed == true && context.mounted) {
          ref.read(routesProvider.notifier).removeRoute(route.id);
          // Auto-close drawer if deleting the active route etc
          Navigator.of(context).pop();
        }
    }
  }
}

enum _HelpAction { support, feedback, signOut }

class _TopActions extends StatelessWidget {
  const _TopActions({required this.onHelp, required this.onSettings});
  final void Function(_HelpAction) onHelp;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: 'Ajuda',
          button: true,
          child: PopupMenuButton<_HelpAction>(
            icon: const Icon(LucideIcons.circleHelp),
            color: AppColors.bg,
            tooltip: 'Ajuda',
            position: PopupMenuPosition.under,
            onSelected: onHelp,
            itemBuilder: (_) => const [
              PopupMenuItem<_HelpAction>(
                value: _HelpAction.support,
                child: Text('Ajuda e suporte'),
              ),
              PopupMenuItem<_HelpAction>(
                value: _HelpAction.feedback,
                child: Text('Compartilhar feedback'),
              ),
              // Temporary: until Configurações (Área 10) ships a Sair row,
              // expose logout from the Help menu so the user isn't trapped.
              PopupMenuDivider(),
              PopupMenuItem<_HelpAction>(
                value: _HelpAction.signOut,
                child: Text('Sair'),
              ),
            ],
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
