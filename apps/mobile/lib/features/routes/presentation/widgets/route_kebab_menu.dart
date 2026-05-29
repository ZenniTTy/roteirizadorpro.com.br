import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/route_action.dart';

/// Kebab popup menu attached to a route row in the drawer.
///
/// Spoke parity §10.2 dump 2026-05-27: `PopupMenuButton<RouteAction>` with
/// 3 plain-text items (no leading icons, no divider, no destructive
/// colour). Anchors below-and-left of the kebab trigger via Material default.
class RouteKebabMenu extends StatelessWidget {
  const RouteKebabMenu({super.key, required this.onSelected});

  final void Function(RouteAction action) onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Mais opções',
      button: true,
      child: PopupMenuButton<RouteAction>(
        icon: const Icon(LucideIcons.ellipsisVertical),
        color: AppColors.bg,
        tooltip: 'Mais opções',
        position: PopupMenuPosition.under,
        onSelected: onSelected,
        itemBuilder: (_) => const [
          PopupMenuItem<RouteAction>(
            value: RouteAction.editMeta,
            child: Text('Definir nome e data'),
          ),
          PopupMenuItem<RouteAction>(
            value: RouteAction.duplicate,
            child: Text('Duplicar rota'),
          ),
          PopupMenuItem<RouteAction>(
            value: RouteAction.delete,
            child: Text('Excluir rota'),
          ),
        ],
      ),
    );
  }
}
