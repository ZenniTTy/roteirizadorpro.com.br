import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/id.dart';
import '../domain/stop.dart';
import '../state/stops_controller.dart';
import 'shared/stop_form.dart';

class AddStopPage extends ConsumerWidget {
  const AddStopPage({super.key, this.onSaved});

  /// Nullable so widget tests can assert taps without standing up a GoRouter;
  /// production falls through to `context.go('/home')`.
  final void Function(BuildContext context)? onSaved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar parada')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: StopForm(
            onSubmit: (value) async {
              final stop = Stop(
                id: newId(),
                lat: 0,
                lng: 0,
                label: value.label,
                source: StopSource.manual,
                createdAt: DateTime.now(),
              );
              await ref.read(stopsControllerProvider.notifier).add(stop);
              if (!context.mounted) return;
              (onSaved ?? (ctx) => ctx.go('/home'))(context);
            },
          ),
        ),
      ),
    );
  }
}
