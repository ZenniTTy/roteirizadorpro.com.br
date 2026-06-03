import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/place_autocomplete_prediction.dart';
import '../../domain/stop.dart';

/// Renders the with-results state of `AddStopPage`:
/// - Section A "Desta rota (N)" (conditional on `matchesInRoute.isNotEmpty`
///   AND `showExistingStopsSection`)
/// - Section B (header label provided by the caller — default
///   "Adicionar nova parada"; Partida/Destino pickers pass
///   "Escolha o novo endereço")
/// - Footer "Escolher no mapa" (conditional on `showChooseOnMapFooter`)
///
/// Spoke parity §10.21 amendment 3 + §11.4 amendment 2 (both 2026-05-28).
class AddStopResultsSection extends StatelessWidget {
  const AddStopResultsSection({
    super.key,
    required this.matchesInRoute,
    required this.newCandidates,
    required this.onSectionATap,
    required this.onSectionBTap,
    this.sectionBHeader = 'Adicionar nova parada',
    this.showExistingStopsSection = true,
    this.showChooseOnMapFooter = true,
  });

  final List<Stop> matchesInRoute;
  final List<PlaceAutocompletePrediction> newCandidates;
  final void Function(Stop stop) onSectionATap;
  final void Function(PlaceAutocompletePrediction p) onSectionBTap;

  /// Header above the new-candidates list. Spoke uses
  /// `Adicionar nova parada` for the add-stop flow and
  /// `Escolha o novo endereço` for the Partida/Destino location pickers.
  final String sectionBHeader;

  /// When `false`, the "Desta rota (N)" section is omitted entirely
  /// (header + tiles). Partida/Destino pickers set this `false` because
  /// they don't surface existing route stops.
  final bool showExistingStopsSection;

  /// When `false`, the "Escolher no mapa" footer row is omitted.
  /// Partida/Destino pickers don't expose map-based selection.
  final bool showChooseOnMapFooter;

  static const _headerStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
    letterSpacing: 0.3,
  );

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (showExistingStopsSection && matchesInRoute.isNotEmpty) {
      children.add(_sectionHeader('Desta rota (${matchesInRoute.length})'));
      for (final stop in matchesInRoute) {
        children.add(
          ListTile(
            leading: const Icon(LucideIcons.mapPin, color: AppColors.primary),
            title: Text(stop.streetName),
            subtitle:
                stop.fullAddress.isNotEmpty ? Text(stop.fullAddress) : null,
            trailing: const Icon(
              LucideIcons.pencil,
              size: 16,
              color: AppColors.textMuted,
            ),
            onTap: () => onSectionATap(stop),
          ),
        );
      }
    }

    children.add(_sectionHeader(sectionBHeader));
    for (final p in newCandidates) {
      children.add(
        ListTile(
          leading:
              const Icon(LucideIcons.plusCircle, color: AppColors.textMuted),
          title: Text(p.mainText),
          subtitle: p.secondaryText.isNotEmpty ? Text(p.secondaryText) : null,
          onTap: () => onSectionBTap(p),
        ),
      );
    }

    if (showChooseOnMapFooter) {
      children.add(const Divider(height: 1));
      children.add(
        ListTile(
          leading: const Icon(LucideIcons.mapPinned, color: AppColors.primary),
          title: const Text('Escolher no mapa'),
          trailing:
              const Icon(LucideIcons.chevronRight, color: AppColors.textMuted),
          onTap: () => context.push('/home/routes/add-stop/map'),
        ),
      );
    }

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
