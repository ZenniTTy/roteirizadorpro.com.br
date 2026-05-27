import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/group_routes_by_period.dart';
import '../../domain/route.dart' as domain;
import 'drawer_route_tile.dart';

/// Scrollable section of the [AppDrawer] showing routes grouped by period.
/// Bucket headers are only rendered for non-empty buckets, in the canonical
/// top→bottom order set by [domain.RoutePeriod] (Spoke parity §11.6).
class DrawerRouteList extends StatelessWidget {
  const DrawerRouteList({
    super.key,
    required this.routes,
    required this.activeRouteId,
    required this.onRouteTap,
    required this.onRouteKebab,
  });

  final List<domain.Route> routes;
  final String? activeRouteId;
  final void Function(domain.Route) onRouteTap;
  final void Function(domain.Route) onRouteKebab;

  @override
  Widget build(BuildContext context) {
    final grouped = groupRoutesByPeriod(routes, DateTime.now());

    if (grouped.isEmpty) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[];
    for (final entry in grouped.entries) {
      children.add(_SectionHeader(label: _labelFor(entry.key)));
      for (final route in entry.value) {
        children.add(
          DrawerRouteTile(
            route: route,
            activeRouteId: activeRouteId,
            onTap: () => onRouteTap(route),
            onKebab: () => onRouteKebab(route),
          ),
        );
      }
    }

    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      children: children,
    );
  }

  static String _labelFor(domain.RoutePeriod period) => switch (period) {
        domain.RoutePeriod.upcoming => 'Próximas',
        domain.RoutePeriod.today => 'Hoje',
        domain.RoutePeriod.thisWeek => 'Esta semana',
        domain.RoutePeriod.thisMonth => 'Este mês',
      };
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
