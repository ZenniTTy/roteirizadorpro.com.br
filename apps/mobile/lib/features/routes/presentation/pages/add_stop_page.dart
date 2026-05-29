import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
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

/// Spoke parity §10.21 + §11.4 (amended 2026-05-28).
/// Body branches on `addStopUiStateProvider` (sealed `AddStopUiState`).
/// Section A tap → SnackBar stub (Area 6 implements edit-stop sheet).
/// Section B tap → create Stop + `context.pop()` (Area 6 will replace with
/// inline DraggableScrollableSheet open per §11.4 BIG FIND).
/// Footer tap → push `/home/routes/add-stop/map` (existing stub).
class AddStopPage extends ConsumerWidget {
  const AddStopPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addStopUiStateProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const AddStopSearchBar(),
            Expanded(
              child: switch (state) {
                EmptyVariant(:final stopCount) =>
                  _EmptyState(stopCount: stopCount),
                Loading() => const Center(child: CircularProgressIndicator()),
                ErrorState(:final error) =>
                  Center(child: Text('Erro ao buscar endereços: $error')),
                ZeroResults() => const _ZeroResultsState(),
                WithResults(:final matchesInRoute, :final newCandidates) =>
                  AddStopResultsSection(
                    matchesInRoute: matchesInRoute,
                    newCandidates: newCandidates,
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
    // Area 6 will replace with: context.push('/home/routes/stops/${stop.id}/edit')
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Editar parada em breve')),
    );
  }

  Future<void> _onSectionBTap(
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
        messenger.showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.stopCount});
  final int stopCount;

  @override
  Widget build(BuildContext context) {
    final microcopy = stopCount == 0
        ? 'Adicione as primeiras paradas para começar a criar sua rota'
        : 'Adicione novas paradas ou encontre paradas na rota';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.plusCircle,
              size: 48, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            microcopy,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: AppColors.textMuted),
          ),
          const SizedBox(height: 48),
          const AddStopMethodButtons(),
        ],
      ),
    );
  }
}

class _ZeroResultsState extends StatelessWidget {
  const _ZeroResultsState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.searchX, size: 48, color: AppColors.textMuted),
          SizedBox(height: 16),
          Text(
            'Nenhum resultado encontrado',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.text),
          ),
          SizedBox(height: 8),
          Text(
            'Tente reformular a pesquisa',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
          SizedBox(height: 48),
          AddStopMethodButtons(),
        ],
      ),
    );
  }
}
