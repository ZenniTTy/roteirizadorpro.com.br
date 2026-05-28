import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/group_routes_by_period.dart';
import '../../domain/route.dart' as domain;
import '../../domain/route_action.dart';
import 'drawer_route_tile.dart';

/// Single virtualised scrolling section of the [AppDrawer].
///
/// Renders, in order: an optional [headerSlot] (DrawerHeaderCard), a
/// divider, then one bucket header + route tiles per non-empty
/// [domain.RoutePeriod] (canonical top→bottom order set by the enum,
/// per Spoke parity §11.6).
///
/// Implemented as a single [ListView.builder] over a precomputed flat
/// row list so all tiles are virtualised (no nested ListViews, no
/// shrinkWrap). Important for Slice 3 when the route list grows past
/// the seed values.
class DrawerRouteList extends StatelessWidget {
  const DrawerRouteList({
    super.key,
    required this.routes,
    required this.activeRouteId,
    required this.onRouteTap,
    required this.onRouteKebabAction,
    this.headerSlot,
    this.scrollController,
  });

  final List<domain.Route> routes;
  final String? activeRouteId;
  final void Function(domain.Route) onRouteTap;
  final void Function(domain.Route, RouteAction) onRouteKebabAction;
  final Widget? headerSlot;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final grouped = groupRoutesByPeriod(routes, DateTime.now());
    final rows = _flatten(grouped);

    if (rows.isEmpty && headerSlot == null) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.zero,
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        return switch (row) {
          _HeaderSlot(:final child) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                child,
              ],
            ),
          _SectionHeaderRow(:final label) => _SectionHeader(label: label),
          _RouteRow(:final route) => DrawerRouteTile(
              route: route,
              activeRouteId: activeRouteId,
              onTap: () => onRouteTap(route),
              onKebabAction: (action) => onRouteKebabAction(route, action),
            ),
        };
      },
    );
  }

  List<_Row> _flatten(Map<domain.RoutePeriod, List<domain.Route>> grouped) {
    final rows = <_Row>[];
    if (headerSlot != null) {
      rows.add(_HeaderSlot(headerSlot!));
    }
    for (final entry in grouped.entries) {
      rows.add(_SectionHeaderRow(_labelFor(entry.key)));
      for (final route in entry.value) {
        rows.add(_RouteRow(route));
      }
    }
    return rows;
  }

  static String _labelFor(domain.RoutePeriod period) => switch (period) {
        domain.RoutePeriod.upcoming => 'Próximas',
        domain.RoutePeriod.today => 'Hoje',
        domain.RoutePeriod.thisWeek => 'Esta semana',
        domain.RoutePeriod.thisMonth => 'Este mês',
      };
}

sealed class _Row {
  const _Row();
}

class _HeaderSlot extends _Row {
  const _HeaderSlot(this.child);
  final Widget child;
}

class _SectionHeaderRow extends _Row {
  const _SectionHeaderRow(this.label);
  final String label;
}

class _RouteRow extends _Row {
  const _RouteRow(this.route);
  final domain.Route route;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Padding(
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
        ),
      ],
    );
  }
}
