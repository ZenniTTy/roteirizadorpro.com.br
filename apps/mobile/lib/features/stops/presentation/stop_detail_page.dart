import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/stop.dart';
import '../state/stops_controller.dart';
import 'shared/stops_async_view.dart';

class StopDetailPage extends ConsumerWidget {
  const StopDetailPage({
    super.key,
    required this.id,
    this.onDeleted,
    this.onEditPressed,
  });

  final String id;

  /// Nullable so widget tests can assert taps without standing up a GoRouter;
  /// production falls through to `context.go('/home')`.
  final void Function(BuildContext context)? onDeleted;

  /// Same callback-injection pattern for Editar; route lands in Task 20.
  final void Function(BuildContext context)? onEditPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStops = ref.watch(stopsControllerProvider);

    final title = asyncStops.maybeWhen(
      data: (stops) {
        final index = stops.indexWhere((s) => s.id == id);
        if (index < 0) return 'Parada';
        return 'Parada ${index + 1} de ${stops.length}';
      },
      orElse: () => 'Parada',
    );

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: stopsAsyncView(
          asyncStops,
          screenTag: 'StopDetailPage',
          data: (context, stops) {
            final stop = stops.where((s) => s.id == id).firstOrNull;
            if (stop == null) {
              return const Center(child: Text('Parada não encontrada.'));
            }
            return _StopDetailBody(
              stop: stop,
              onDelete: () async {
                await ref
                    .read(stopsControllerProvider.notifier)
                    .remove(stop.id);
                if (!context.mounted) return;
                (onDeleted ?? (ctx) => ctx.go('/home'))(context);
              },
              onEdit: () {
                (onEditPressed ??
                    (ctx) => ctx.go('/stops/${stop.id}/edit'))(context);
              },
            );
          },
        ),
      ),
    );
  }
}

class _StopDetailBody extends StatelessWidget {
  const _StopDetailBody({
    required this.stop,
    required this.onDelete,
    required this.onEdit,
  });

  final Stop stop;
  final Future<void> Function() onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            stop.label ?? 'Sem endereço',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          if (stop.isGeocoded) ...[
            Text('Latitude: ${stop.lat}', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text('Longitude: ${stop.lng}', style: theme.textTheme.bodyMedium),
          ] else
            Text(
              'Aguardando geocodificação',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Excluir'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
