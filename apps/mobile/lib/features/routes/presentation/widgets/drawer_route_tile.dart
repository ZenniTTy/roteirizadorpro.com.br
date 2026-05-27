import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/route.dart' as domain;

/// A single row in the drawer route list.
/// Shows abbreviated date + display name + kebab. Active-state colour is
/// driven by [activeRouteId] matching [route.id] (Spoke parity §10.1).
class DrawerRouteTile extends StatelessWidget {
  const DrawerRouteTile({
    super.key,
    required this.route,
    required this.activeRouteId,
    required this.onTap,
    required this.onKebab,
  });

  final domain.Route route;
  final String? activeRouteId;
  final VoidCallback onTap;
  final VoidCallback onKebab;

  @override
  Widget build(BuildContext context) {
    final isActive = route.id == activeRouteId;
    final nameColor = isActive ? AppColors.primary : AppColors.text;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(
                _abbreviatedDatePtBr(route.date),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                route.displayName(),
                style: TextStyle(
                  fontSize: 15,
                  color: nameColor,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Semantics(
              label: 'Mais opções',
              button: true,
              child: IconButton(
                icon: const Icon(LucideIcons.ellipsisVertical),
                color: AppColors.textMuted,
                onPressed: onKebab,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _kMonthAbbrPtBr = <String>[
  '',
  'jan.',
  'fev.',
  'mar.',
  'abr.',
  'mai.',
  'jun.',
  'jul.',
  'ago.',
  'set.',
  'out.',
  'nov.',
  'dez.',
];

/// Returns the abbreviated date format used in the drawer rows (Spoke
/// parity §10.1), e.g. "27 de mai." for 2026-05-27.
String _abbreviatedDatePtBr(DateTime d) =>
    '${d.day} de ${_kMonthAbbrPtBr[d.month]}';
