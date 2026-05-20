import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../state/optimize_controller.dart';
import '../state/stops_controller.dart';
import 'shared/stops_async_view.dart';

/// Celebration screen at the end of a route per prototipo/screens-e.jsx:740-843.
/// Slice 2 ships the central card + check circle + stop count + the
/// distance/duration metrics the OptimizeController already produced.
/// The "Você economizou" banner needs a baseline (unoptimized comparison)
/// that arrives only with slice 3's real solver and is tracked as a
/// pre-PR Important in TODO.md.
class RouteCompletePage extends ConsumerWidget {
  const RouteCompletePage({super.key, this.onNewRoute, this.onShare});

  /// Callback injection for widget tests; production routes via GoRouter.
  final void Function(BuildContext context)? onNewRoute;
  final void Function(BuildContext context)? onShare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stopsAsync = ref.watch(stopsControllerProvider);
    final optimizeAsync = ref.watch(optimizeControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: stopsAsyncView(
          stopsAsync,
          screenTag: 'RouteCompletePage',
          data: (context, stops) => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _CelebrationCard(
                stopCount: stops.length,
                metrics: optimizeAsync.asData?.value,
                onNewRoute: () async {
                  await ref.read(stopsControllerProvider.notifier).clear();
                  if (!context.mounted) return;
                  (onNewRoute ?? (ctx) => ctx.go('/home'))(context);
                },
                onShare: () => (onShare ?? (ctx) => ctx.go('/share'))(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CelebrationCard extends StatelessWidget {
  const _CelebrationCard({
    required this.stopCount,
    required this.metrics,
    required this.onNewRoute,
    required this.onShare,
  });

  final int stopCount;
  final OptimizeResult? metrics;
  final VoidCallback onNewRoute;
  final VoidCallback onShare;

  String _durationLabel(double seconds) {
    final totalMin = (seconds / 60).round();
    if (totalMin < 60) return '$totalMin min';
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMetrics = metrics != null && metrics!.totalDurationS > 0;

    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E6C3FC5),
            blurRadius: 48,
            offset: Offset(0, 24),
          ),
          BoxShadow(
            color: Color(0x141A1A2E),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _CheckCircle(),
          const SizedBox(height: 16),
          Text(
            'Rota concluída!',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasMetrics
                ? '$stopCount paradas em ${_durationLabel(metrics!.totalDurationS)}'
                : '$stopCount paradas concluídas',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  value: '$stopCount',
                  label: 'Entregues',
                  highlight: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  value: hasMetrics
                      ? '${(metrics!.totalDistanceM / 1000).toStringAsFixed(1)} km'
                      : '— km',
                  label: 'Percorridos',
                  highlight: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: onNewRoute,
              icon: const Icon(Icons.refresh),
              label: const Text('Nova rota'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.share, size: 16),
            label: const Text('Compartilhar'),
          ),
        ],
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.success, Color(0xFF15803D)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x6622C55E),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(Icons.check, color: Colors.white, size: 36),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.highlight,
  });

  final String value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final bg = highlight ? AppColors.primaryLight : AppColors.surface;
    final fg = highlight ? AppColors.primary : AppColors.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: highlight ? AppColors.primary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
