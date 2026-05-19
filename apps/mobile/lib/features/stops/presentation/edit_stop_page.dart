import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/stops_controller.dart';
import 'shared/stop_form.dart';
import 'shared/stops_async_view.dart';

class EditStopPage extends ConsumerWidget {
  const EditStopPage({super.key, required this.id, this.onSaved});

  final String id;

  /// Nullable so widget tests can assert taps without standing up a GoRouter;
  /// production falls through to `context.go('/stops/$id')`.
  final void Function(BuildContext context)? onSaved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(stopsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Editar parada')),
      body: SafeArea(
        child: stopsAsyncView(
          async,
          screenTag: 'EditStopPage',
          data: (context, stops) {
            final stop = stops.where((s) => s.id == id).firstOrNull;
            if (stop == null) {
              return const Center(child: Text('Parada não encontrada.'));
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: StopForm(
                initial: stop,
                submitLabel: 'Salvar alterações',
                onSubmit: (value) async {
                  final updated = stop.copyWith(label: value.label);
                  await ref
                      .read(stopsControllerProvider.notifier)
                      .updateStop(updated);
                  if (!context.mounted) return;
                  (onSaved ?? (ctx) => ctx.go('/stops/${stop.id}'))(context);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
