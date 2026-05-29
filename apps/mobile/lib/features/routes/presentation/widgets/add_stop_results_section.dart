import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/place_autocomplete_prediction.dart';
import '../../domain/stop.dart';

/// Renders the with-results state of `AddStopPage`:
/// - Section A "Desta rota (N)" (conditional on `matchesInRoute.isNotEmpty`)
/// - Section B "Adicionar nova parada" (always when in this widget)
/// - Footer "Escolher no mapa" (always)
///
/// Spoke parity §10.21 amendment 3 + §11.4 amendment 2 (both 2026-05-28).
class AddStopResultsSection extends StatelessWidget {
  const AddStopResultsSection({
    super.key,
    required this.matchesInRoute,
    required this.newCandidates,
    required this.onSectionATap,
    required this.onSectionBTap,
  });

  final List<Stop> matchesInRoute;
  final List<PlaceAutocompletePrediction> newCandidates;
  final void Function(Stop stop) onSectionATap;
  final void Function(PlaceAutocompletePrediction p) onSectionBTap;

  static const _headerStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
    letterSpacing: 0.3,
  );

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (matchesInRoute.isNotEmpty) {
      children.add(_sectionHeader('Desta rota (${matchesInRoute.length})'));
      for (final stop in matchesInRoute) {
        children.add(
          ListTile(
            leading: const Icon(LucideIcons.mapPin, color: AppColors.primary),
            title: Text(stop.streetName),
            subtitle:
                stop.fullAddress.isNotEmpty ? Text(stop.fullAddress) : null,
            onTap: () => onSectionATap(stop),
          ),
        );
      }
    }

    children.add(_sectionHeader('Adicionar nova parada'));
    for (final p in newCandidates) {
      children.add(
        ListTile(
          title: Text(p.mainText),
          subtitle: p.secondaryText.isNotEmpty ? Text(p.secondaryText) : null,
          onTap: () => onSectionBTap(p),
        ),
      );
    }

    children.add(const Divider(height: 1));
    children.add(
      ListTile(
        title: const Text('Escolher no mapa'),
        onTap: () => context.push('/home/routes/add-stop/map'),
      ),
    );

    return ListView(
      padding: EdgeInsets.zero,
      children: children,
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(label, style: _headerStyle),
    );
  }
}
