import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/stops_controller.dart';
import 'shared/stop_list_item.dart';

class HomeListPage extends ConsumerWidget {
  const HomeListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStops = ref.watch(stopsControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rota de hoje'),
        actions: [
          asyncStops.maybeWhen(
            data: (stops) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Chip(
                  avatar: const Icon(Icons.place_outlined, size: 16),
                  label: Text('${stops.length}'),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      floatingActionButton: Semantics(
        button: true,
        label: 'Adicionar parada',
        child: FloatingActionButton(
          onPressed: () => context.go('/stops/add'),
          child: const Icon(Icons.add),
        ),
      ),
      body: SafeArea(
        child: asyncStops.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) {
            debugPrint('HomeListPage stops error: $e');
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Não conseguimos carregar suas paradas. Tente reabrir o app.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            );
          },
          data: (stops) {
            if (stops.isEmpty) {
              return const Center(
                child: Text('Nenhuma parada ainda. Toque em Adicionar.'),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: stops.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final stop = stops[index];
                return Dismissible(
                  key: ValueKey(stop.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: theme.colorScheme.errorContainer,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                  onDismissed: (_) => ref
                      .read(stopsControllerProvider.notifier)
                      .remove(stop.id),
                  child: StopListItem(
                    index: index,
                    stop: stop,
                    onTap: () => context.go('/stops/${stop.id}'),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
