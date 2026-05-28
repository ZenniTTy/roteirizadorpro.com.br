import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/stop.dart';
import '../../data/repositories/places_repository.dart';
import '../../state/active_route_provider.dart';
import '../../state/place_autocomplete_provider.dart';
import '../../state/routes_provider.dart';
import '../widgets/add_stop_method_buttons.dart';
import '../widgets/add_stop_search_bar.dart';

class AddStopPage extends ConsumerWidget {
  const AddStopPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictionsAsync = ref.watch(placeAutocompleteProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Content below the search bar
          Positioned.fill(
            top: 120, // Account for search bar height + padding
            child: predictionsAsync.when(
              data: (predictions) {
                if (predictions.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.plusCircle, size: 48, color: AppColors.textMuted),
                          SizedBox(height: 16),
                          Text(
                            'Adicione as primeiras paradas para começar a criar sua rota',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textMuted,
                            ),
                          ),
                          SizedBox(height: 48),
                          AddStopMethodButtons(),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: predictions.length,
                  itemBuilder: (context, index) {
                    final p = predictions[index];
                    return ListTile(
                      leading: const Icon(LucideIcons.mapPin, color: AppColors.textMuted),
                      title: Text(p.mainText),
                      subtitle: p.secondaryText.isNotEmpty ? Text(p.secondaryText) : null,
                      onTap: () async {
                        final activeRouteId = ref.read(activeRouteIdProvider);
                        if (activeRouteId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nenhuma rota ativa selecionada.')),
                          );
                          return;
                        }

                        // Show loading snackbar or indicator
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Adicionando parada...')),
                        );

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
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            context.pop();
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erro: $e')),
                            );
                          }
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Erro ao buscar endereços: $e')),
            ),
          ),

          // Search bar pinned at the top
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AddStopSearchBar(),
          ),
        ],
      ),
    );
  }
}
