import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/stops_controller.dart';
import 'shared/stop_list_item.dart';
import 'shared/stops_async_view.dart';

class ReorderPage extends ConsumerWidget {
  const ReorderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStops = ref.watch(stopsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reordenar paradas'),
        actions: [
          IconButton(
            tooltip: 'Concluir',
            icon: const Icon(Icons.check),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
          ),
        ],
      ),
      body: SafeArea(
        child: stopsAsyncView(
          asyncStops,
          screenTag: 'ReorderPage',
          data: (context, stops) {
            if (stops.isEmpty) {
              return const Center(
                child: Text('Nenhuma parada para reordenar.'),
              );
            }
            return ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              buildDefaultDragHandles: false,
              itemCount: stops.length,
              itemBuilder: (context, index) {
                final stop = stops[index];
                return StopListItem(
                  key: ValueKey(stop.id),
                  index: index,
                  stop: stop,
                  trailing: ReorderableDragStartListener(
                    index: index,
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(Icons.drag_handle),
                    ),
                  ),
                );
              },
              onReorder: (oldIndex, newIndex) => ref
                  .read(stopsControllerProvider.notifier)
                  .reorder(oldIndex, newIndex),
            );
          },
        ),
      ),
    );
  }
}
