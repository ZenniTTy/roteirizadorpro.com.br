import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:roteirizador_pro/features/route_config/domain/route_config.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/delivery_id_chip.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/optimized_route_step_body.dart';

/// Corpo do estado "pronto para rodar" (A7-D5/D8) — a LISTA otimizada (mesma do
/// PRE-CONFIRM, Branch B plana) no MESMO shell. A moldura (alça + busca + drag)
/// vem do `_RouteSheetShell`; esta view é só o `body`, e o rodapé é o
/// [ReadyToRunFooter] (composto pelo shell).
///
/// Header = o summary à esquerda OU o banner "Otimização pendente" quando a rota
/// chegou aqui PULANDO a otimização ([hasPendingOptimization]). Abaixo da lista,
/// os dois botões-linha de features adiadas ("Compartilhar rota em tempo real" /
/// "Carregar veículo", fiéis à presença no Spoke).
class ReadyToRunView extends StatelessWidget {
  const ReadyToRunView({
    required this.stops,
    required this.durationMinutes,
    required this.distanceMeters,
    required this.hasPendingOptimization,
    required this.onComingSoon,
    required this.onReoptimize,
    this.routeName,
    this.startLocation,
    this.destination,
    super.key,
  });

  final List<Stop> stops;
  final String? routeName;
  final StartLocation? startLocation;
  final Destination? destination;
  final int durationMinutes;
  final double distanceMeters;

  /// Rota confirmada SEM otimizar (skip-path) → mostra o banner pendente.
  final bool hasPendingOptimization;

  /// Features adiadas ("Compartilhar rota em tempo real" / "Carregar veículo").
  final VoidCallback onComingSoon;

  /// Banner "Otimização pendente" → re-dispara o solver.
  final VoidCallback onReoptimize;

  @override
  Widget build(BuildContext context) {
    return OptimizedRouteStepBody(
      stops: stops,
      routeName: routeName,
      startLocation: startLocation,
      destination: destination,
      durationMinutes: durationMinutes,
      distanceMeters: distanceMeters,
      header: hasPendingOptimization
          ? _PendingOptimizationBanner(onTap: onReoptimize)
          : null,
      stopTrailingBuilder: (stop) =>
          DeliveryIdChip(deliveryId: stop.deliveryId),
      trailingBelowList: Column(
        children: [
          const Divider(height: 1),
          ListTile(
            leading: const Icon(LucideIcons.share2),
            title: const Text('Compartilhar rota em tempo real'),
            onTap: onComingSoon,
          ),
          ListTile(
            leading: const Icon(LucideIcons.truck),
            title: const Text('Carregar veículo'),
            onTap: onComingSoon,
          ),
        ],
      ),
    );
  }
}

/// Rodapé do Ready-to-Run: "Editar" (volta ao PRE-CONFIRM) + "Iniciar rota"
/// (gateway pro Modo Delivery — Á8).
class ReadyToRunFooter extends StatelessWidget {
  const ReadyToRunFooter({
    required this.onEdit,
    required this.onStart,
    super.key,
  });

  /// "Editar" — des-confirma e volta ao PRE-CONFIRM (G2).
  final VoidCallback onEdit;

  /// "Iniciar rota" — gateway pro Modo Delivery (Á8; honest-stub nesta área).
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onEdit,
                child: const Text('Editar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: onStart,
                child: const Text('Iniciar rota'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner do Ready-to-Run quando a otimização foi pulada (skip-path, A7-D8).
/// Toque re-dispara o solver. Microcopy original fiel a
/// `optimization_pending_button_title` ("Otimização pendente").
class _PendingOptimizationBanner extends StatelessWidget {
  const _PendingOptimizationBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                LucideIcons.circleAlert,
                size: 18,
                color: scheme.onErrorContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Otimização pendente',
                  style: TextStyle(
                    color: scheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                LucideIcons.refreshCw,
                size: 18,
                color: scheme.onErrorContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
