import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import 'shared/home_bottom_nav.dart';

class HomeEmptyPage extends StatelessWidget {
  const HomeEmptyPage({super.key, this.onAddPressed});

  /// Nullable so widget tests can assert taps without standing up a GoRouter;
  /// production falls through to `context.go('/stops/add')`.
  final void Function(BuildContext context)? onAddPressed;

  void _addStop(BuildContext context) =>
      (onAddPressed ?? (ctx) => ctx.go('/stops/add'))(context);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Rota de hoje')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addStop(context),
        tooltip: 'Adicionar parada',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const HomeBottomNav(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
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
              _HowItWorksPill(onPressed: () => _addStop(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HowItWorksPill extends StatelessWidget {
  const _HowItWorksPill({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Como funciona',
      child: Material(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 40,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Como funciona?',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
