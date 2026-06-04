import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../route_config/domain/route_config.dart';
import '../../../route_config/state/picker_mode.dart';
import '../../application/add_stop_ui_state.dart';
import '../../data/repositories/places_repository.dart';
import '../../domain/place_autocomplete_prediction.dart';
import '../../domain/stop.dart';
import '../../state/active_route_provider.dart';
import '../../state/add_stop_ui_state_provider.dart';
import '../../state/routes_provider.dart';
import '../widgets/add_stop_method_buttons.dart';
import '../widgets/add_stop_results_section.dart';
import '../widgets/add_stop_search_bar.dart';

/// Search-driven address picker. Three operating modes, all expressed via
/// [PickerMode]:
///
/// 1. **Add-stop flow** (`mode == PickerMode.addStop`, the default) —
///    Spoke parity §10.21 + §11.4 (amended 2026-05-28). Body branches on
///    `addStopUiStateProvider` (sealed `AddStopUiState`). Section A tap →
///    SnackBar stub (Area 6 implements edit-stop sheet). Section B tap →
///    create Stop + `context.pop()`. Footer tap → push
///    `/home/routes/add-stop/map`.
///
/// 2. **Partida sub-picker** (`mode == PickerMode.startLocation`) —
///    pushed by Detalhes da rota's Partida row. Empty body (no method
///    buttons), single results section, no map footer; selecting a row
///    pops with a [StartLocation] for the caller to persist via
///    `routeConfigController.setStartLocation`.
///
/// 3. **Destino sub-picker** (`mode == PickerMode.endLocation`) — reuses
///    the same shell and pops a [SpecificAddress] on selection. The Destino
///    sheet's "Destino em outro endereço" card pushes this route; the parent
///    (Detalhes da rota) awaits the address and persists it via
///    `routeConfigController.setDestination`. ADR-0043.
///
/// [PickerMode] also keys the search-state providers
/// (`searchQueryProvider`, `placeAutocompleteProvider`,
/// `addStopUiStateProvider`), so each mode keeps its own typed text and
/// autocomplete results — switching modes mid-flow cannot leak state from
/// one picker into another.
class AddStopPage extends ConsumerWidget {
  const AddStopPage({super.key, this.mode = PickerMode.addStop});

  /// Defaults to [PickerMode.addStop] for the legacy add-stop call site.
  /// Detalhes da rota's Partida/Destino row taps push the page with
  /// [PickerMode.startLocation] / [PickerMode.endLocation] explicitly.
  final PickerMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addStopUiStateProvider(mode));
    final m = mode;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            AddStopSearchBar(mode: m, hintText: m.hintText),
            Expanded(
              child: switch (state) {
                EmptyVariant(:final stopCount) => _EmptyState(
                    stopCount: stopCount,
                    showMethodButtons: m.showMethodButtonsOnEmpty,
                    showMicrocopy: m.showMicrocopyOnEmpty,
                  ),
                Loading() => const Center(child: CircularProgressIndicator()),
                ErrorState(:final error) =>
                  Center(child: Text('Erro ao buscar endereços: $error')),
                ZeroResults() => _ZeroResultsState(
                    showMethodButtons: m.showMethodButtonsOnEmpty,
                  ),
                WithResults(:final matchesInRoute, :final newCandidates) =>
                  AddStopResultsSection(
                    matchesInRoute: matchesInRoute,
                    newCandidates: newCandidates,
                    sectionBHeader: m.resultsSectionHeader,
                    showExistingStopsSection: m.showExistingStopsSection,
                    showChooseOnMapFooter: m.showChooseOnMapFooter,
                    onSectionATap: (s) => _onSectionATap(context, s),
                    onSectionBTap: (p) => _onSectionBTap(context, ref, p),
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onSectionATap(BuildContext context, Stop stop) {
    // Section A is only rendered in add-stop mode (Partida picker omits the
    // existing-stops list). Area 6 will replace this with a push to the
    // edit-stop sheet.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Editar parada em breve')),
    );
  }

  Future<void> _onSectionBTap(
    BuildContext context,
    WidgetRef ref,
    PlaceAutocompletePrediction p,
  ) async {
    switch (mode) {
      case PickerMode.addStop:
        await _addStopFromPrediction(context, ref, p);
      case PickerMode.startLocation:
        await _popWithStartLocation(context, ref, p);
      case PickerMode.endLocation:
        await _popWithEndLocation(context, ref, p);
    }
  }

  /// Legacy add-stop path: resolve place details, build a [Stop], append it
  /// to the active route via `routesProvider`, and pop the picker.
  Future<void> _addStopFromPrediction(
    BuildContext context,
    WidgetRef ref,
    PlaceAutocompletePrediction p,
  ) async {
    final activeRouteId = ref.read(activeRouteIdProvider);
    if (activeRouteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma rota ativa selecionada.')),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger
        .showSnackBar(const SnackBar(content: Text('Adicionando parada...')));

    try {
      final repo = ref.read(placesRepositoryProvider);
      final details = await repo.getPlaceDetails(p.placeId);
      if (details == null) {
        throw Exception('Não foi possível obter os detalhes do endereço.');
      }
      final newStop = Stop(
        lat: details.lat,
        lng: details.lng,
        streetName: p.mainText,
        fullAddress: details.formattedAddress,
      );
      ref.read(routesProvider.notifier).addStop(activeRouteId, newStop);
      if (context.mounted) {
        messenger.hideCurrentSnackBar();
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  /// Partida sub-picker path: resolve place details and, on success, pop a
  /// [StartLocation]. On null details this HARD-FAILS — it surfaces a SnackBar
  /// and returns without popping, rather than popping zero coordinates that
  /// would later break start anchoring (see the inline comment below). The
  /// caller (Detalhes da rota → Partida row) awaits the [StartLocation] and
  /// writes it through `routeConfigControllerProvider.setStartLocation`.
  Future<void> _popWithStartLocation(
    BuildContext context,
    WidgetRef ref,
    PlaceAutocompletePrediction p,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    StartLocation? selected;
    try {
      final repo = ref.read(placesRepositoryProvider);
      final details = await repo.getPlaceDetails(p.placeId);
      if (details == null) {
        // Repository returned null (place not found) — treat as a hard
        // failure rather than silently popping with zeros that would later
        // break route start anchoring.
        throw Exception('Não foi possível obter os detalhes do endereço.');
      }
      selected = StartLocation(
        address: p.mainText,
        lat: details.lat,
        lng: details.lng,
        isUserCurrentLocation: false,
      );
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
      return;
    }

    if (context.mounted) {
      context.pop<StartLocation>(selected);
    }
  }

  /// Destino sub-picker path: symmetric counterpart of [_popWithStartLocation]
  /// for the "Destino em outro endereço" card (ADR-0043). Resolves the place
  /// details and pops a [SpecificAddress] for the caller (Detalhes da rota →
  /// Destino sheet → parent push) to persist via
  /// `routeConfigControllerProvider.setDestination`.
  Future<void> _popWithEndLocation(
    BuildContext context,
    WidgetRef ref,
    PlaceAutocompletePrediction p,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    SpecificAddress? selected;
    try {
      final repo = ref.read(placesRepositoryProvider);
      final details = await repo.getPlaceDetails(p.placeId);
      if (details == null) {
        // Repository returned null (place not found) — treat as a hard
        // failure rather than silently popping with zeros that would later
        // break destination anchoring.
        throw Exception('Não foi possível obter os detalhes do endereço.');
      }
      selected = SpecificAddress(
        address: p.mainText,
        lat: details.lat,
        lng: details.lng,
      );
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
      return;
    }

    if (context.mounted) {
      context.pop<SpecificAddress>(selected);
    }
  }
}

/// Empty-state body shown when the search field is empty.
///
/// Add-stop flow (`showMethodButtons = true`, `showMicrocopy = true`) is the
/// Spoke parity §10.21 default. Partida sub-picker turns BOTH flags off so
/// the body is a bare empty area, matching Spoke's Partida baseline
/// (captured 2026-06-02).
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.stopCount,
    required this.showMethodButtons,
    required this.showMicrocopy,
  });

  final int stopCount;
  final bool showMethodButtons;
  final bool showMicrocopy;

  @override
  Widget build(BuildContext context) {
    if (!showMicrocopy && !showMethodButtons) {
      // Spoke's Partida picker shows an entirely empty body — no
      // illustration, no microcopy, no shortcut buttons.
      return const SizedBox.shrink();
    }
    final microcopy = stopCount == 0
        ? 'Adicione as primeiras paradas para começar a criar sua rota'
        : 'Adicione novas paradas ou encontre paradas na rota';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.plusCircle,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          if (showMicrocopy)
            Text(
              microcopy,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppColors.textMuted),
            ),
          if (showMethodButtons) ...[
            const SizedBox(height: 48),
            const AddStopMethodButtons(),
          ],
        ],
      ),
    );
  }
}

class _ZeroResultsState extends StatelessWidget {
  const _ZeroResultsState({required this.showMethodButtons});

  final bool showMethodButtons;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.searchX, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 16),
          const Text(
            'Nenhum resultado encontrado',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.text),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tente reformular a pesquisa',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
          if (showMethodButtons) ...[
            const SizedBox(height: 48),
            const AddStopMethodButtons(),
          ],
        ],
      ),
    );
  }
}
