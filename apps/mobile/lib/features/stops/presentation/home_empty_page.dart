import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeEmptyPage extends ConsumerWidget {
  const HomeEmptyPage({super.key, this.onAddPressed});

  /// Optional override for the primary CTA's navigation. When null, the
  /// button navigates to `/stops/add` via go_router. Injected primarily so
  /// widget tests can assert taps without standing up a router.
  final void Function(BuildContext context)? onAddPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Rota de hoje')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 96,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Nenhuma entrega ainda',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Adicione sua primeira parada para começar a planejar a rota.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),
              Semantics(
                button: true,
                label: 'Adicionar parada',
                child: FilledButton.icon(
                  onPressed: () =>
                      (onAddPressed ?? (ctx) => ctx.go('/stops/add'))(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar parada'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
