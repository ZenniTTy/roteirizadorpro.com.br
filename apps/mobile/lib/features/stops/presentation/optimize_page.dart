import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../state/optimize_controller.dart';
import '../state/stops_controller.dart';

/// Loading / progress screen shown between the user's "Otimizar rota"
/// tap and the optimized result. Matches prototipo/screens-b.jsx:103-155:
/// logo, three labeled progress steps, indeterminate progress bar,
/// "Pular →" tertiary CTA. Auto-fires `OptimizeController.run()` on
/// init so the loading state is visible immediately; on success the
/// page routes to `/optimize/route`; on failure it shows an error
/// banner with retry/voltar options.
class OptimizePage extends ConsumerStatefulWidget {
  const OptimizePage({super.key, this.onSuccess, this.onSkip});

  /// Callback injection for widget tests; production routes via GoRouter.
  final void Function(BuildContext context)? onSuccess;
  final void Function(BuildContext context)? onSkip;

  @override
  ConsumerState<OptimizePage> createState() => _OptimizePageState();
}

class _OptimizePageState extends ConsumerState<OptimizePage> {
  bool _kicked = false;

  void _success(BuildContext context) =>
      (widget.onSuccess ?? (ctx) => ctx.go('/optimize/route'))(context);

  void _skip(BuildContext context) =>
      (widget.onSkip ?? (ctx) => ctx.go('/home'))(context);

  void _maybeKick() {
    if (_kicked) return;
    final stopsAsync = ref.read(stopsControllerProvider);
    final stops = stopsAsync.asData?.value;
    if (stops == null || stops.length < 2) return;
    _kicked = true;
    // Defer to after first build so ref.listen wires before the future
    // resolves (matters for the synchronous FakeDio path in tests).
    Future.microtask(() {
      if (!mounted) return;
      ref.read(optimizeControllerProvider.notifier).run().catchError((_) {
        // Error is already captured in the controller state; the
        // build listener surfaces it. catchError is here only to
        // swallow the rethrow so the microtask doesn't unhandled-throw.
        return const OptimizeResult(
          optimizedOrder: [],
          totalDistanceM: 0,
          totalDurationS: 0,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    _maybeKick();

    ref.listen<AsyncValue<OptimizeResult?>>(optimizeControllerProvider,
        (prev, next) {
      if (next is AsyncData<OptimizeResult?> && next.value != null) {
        _success(context);
      }
    });

    final optimizeAsync = ref.watch(optimizeControllerProvider);
    final stopsAsync = ref.watch(stopsControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.alt_route,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 40),
              if (optimizeAsync is AsyncError)
                _ErrorBlock(
                  message: optimizeAsync.error.toString(),
                  onRetry: () {
                    _kicked = false;
                    setState(_maybeKick);
                  },
                  onBack: () => _skip(context),
                )
              else ...[
                const _StepRow(
                  label: 'Analisando suas paradas...',
                  state: _StepState.done,
                ),
                const SizedBox(height: 16),
                const _StepRow(
                  label: 'Calculando tráfego...',
                  state: _StepState.done,
                ),
                const SizedBox(height: 16),
                const _StepRow(
                  label: 'Encontrando o melhor caminho...',
                  state: _StepState.active,
                ),
              ],
              const Spacer(),
              if (optimizeAsync is! AsyncError) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    stopsAsync.maybeWhen(
                      data: (stops) =>
                          'Estimando tempo de chegada... (${stops.length} paradas)',
                      orElse: () => 'Estimando tempo de chegada...',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => _skip(context),
                    child: const Text('Pular →'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _StepState { done, active }

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.state});

  final String label;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: state == _StepState.done
              ? const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 24,
                )
              : const _ActiveDot(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: state == _StepState.active
                  ? FontWeight.w600
                  : FontWeight.w500,
              color: state == _StepState.active
                  ? AppColors.text
                  : AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveDot extends StatelessWidget {
  const _ActiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: const Center(
        child: SizedBox(
          width: 8,
          height: 8,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
        const SizedBox(height: 16),
        Text(
          'Falha ao otimizar a rota',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style:
              theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Tentar novamente'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onBack,
          child: const Text('Voltar para a home'),
        ),
      ],
    );
  }
}
