import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:roteirizador_pro/core/theme/app_theme.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/delivery_id_chip.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/route_step_list.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/route_summary_row.dart';

/// Estado "pronto para rodar" do funil de otimização (A7-D5/D8).
///
/// Mostra a rota confirmada: o resumo (ou o banner "Otimização pendente" quando
/// a rota chegou aqui PULANDO a otimização — [hasPendingOptimization]), a lista
/// de paradas, os dois botões-linha de features adiadas ("Em breve", fiéis à
/// presença no Spoke) e o rodapé com "Editar" (volta ao PRE-CONFIRM) e
/// "Iniciar rota" (gateway pro Modo Delivery — Área 8).
class ReadyToRunView extends StatelessWidget {
  const ReadyToRunView({
    required this.stops,
    required this.durationMinutes,
    required this.distanceMeters,
    required this.hasPendingOptimization,
    required this.onEdit,
    required this.onStart,
    required this.onComingSoon,
    required this.onReoptimize,
    super.key,
  });

  final List<Stop> stops;
  final int durationMinutes;
  final double distanceMeters;

  /// Rota confirmada SEM otimizar (skip-path) → mostra o banner pendente.
  final bool hasPendingOptimization;

  /// "Editar" — des-confirma e volta ao PRE-CONFIRM (G2).
  final VoidCallback onEdit;

  /// "Iniciar rota" — gateway pro Modo Delivery (Á8; honest-stub nesta área).
  final VoidCallback onStart;

  /// Features adiadas ("Compartilhar rota em tempo real" / "Carregar veículo").
  final VoidCallback onComingSoon;

  /// Banner "Otimização pendente" → re-dispara o solver.
  final VoidCallback onReoptimize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (hasPendingOptimization)
          _PendingOptimizationBanner(onTap: onReoptimize)
        else
          RouteSummaryRow(
            durationMinutes: durationMinutes,
            stopsCount: stops.length,
            distanceMeters: distanceMeters,
          ),
        const Divider(height: 1),
        // A lista + os botões-linha ficam DENTRO da área rolável: só o rodapé é
        // fixo, evitando overflow quando o sheet está em altura reduzida.
        Expanded(
          child: ListView(
            children: [
              for (var i = 0; i < stops.length; i++)
                RouteStopStep(
                  key: ValueKey(stops[i].id),
                  position: stops[i].positionInRoute == null
                      ? null
                      : stops[i].positionInRoute! + 1,
                  etaTime: stops[i].estimatedArrival == null
                      ? null
                      : formatEta(stops[i].estimatedArrival!),
                  streetName: stops[i].streetName,
                  fullAddress: stops[i].fullAddress,
                  statusColor: AppColors.textMuted,
                  isFirst: i == 0,
                  isLast: i == stops.length - 1,
                  trailing: DeliveryIdChip(deliveryId: stops[i].deliveryId),
                ),
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
        ),
        SafeArea(
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
        ),
      ],
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
