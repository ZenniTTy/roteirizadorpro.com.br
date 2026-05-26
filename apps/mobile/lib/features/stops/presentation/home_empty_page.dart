import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/home_top_bar.dart';
import '../../../core/widgets/rp_fab.dart';
import 'shared/home_bottom_nav.dart';

class HomeEmptyPage extends StatelessWidget {
  const HomeEmptyPage({super.key, this.onAddPressed});

  /// Nullable so widget tests can assert taps without standing up a GoRouter;
  /// production falls through to `context.push('/home/stops/add')`.
  final void Function(BuildContext context)? onAddPressed;

  void _addStop(BuildContext context) =>
      (onAddPressed ?? (ctx) => ctx.push('/home/stops/add'))(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HomeTopBar(count: 0),
      floatingActionButton: RpFab(
        onPressed: () => _addStop(context),
        tooltip: 'Adicionar parada',
      ),
      bottomNavigationBar: HomeBottomNav(
        navigationShell: StatefulNavigationShell.maybeOf(context)?.widget,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.local_shipping_outlined,
                size: 96,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              const Text(
                'Nenhuma entrega ainda',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Adicione sua primeira parada para começar a planejar a rota.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
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
