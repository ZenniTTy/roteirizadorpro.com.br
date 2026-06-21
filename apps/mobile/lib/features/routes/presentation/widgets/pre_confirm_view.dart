import 'package:flutter/material.dart';
import 'package:roteirizador_pro/core/theme/app_theme.dart';
import 'package:roteirizador_pro/features/route_config/domain/route_config.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/delivery_id_chip.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/optimized_route_step_body.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/route_summary_row.dart';

/// Corpo do PRE-CONFIRM (G4) — a LISTA otimizada, fiel ao Spoke (Branch B,
/// plana, no MESMO shell do DRAFT). A moldura (alça + busca + drag) vem do
/// `_RouteSheetShell` do `route_shell_page.dart`; esta view é só o `body`, e o
/// rodapé é o [PreConfirmFooter] (composto pelo shell). Mantém o tipo
/// `PreConfirmView` na árvore pros testes de presença por estado.
///
/// Header (summary 2 linhas À ESQUERDA: linha 1 muted "duração · N paradas ·
/// distância"; linha 2 bold = nome da rota) → Sem pausa → Ponto de partida →
/// paradas (número zero-pad + ETA + chip A1) → Destino, tudo no mesmo trilho.
class PreConfirmView extends StatelessWidget {
  const PreConfirmView({
    required this.stops,
    required this.durationMinutes,
    required this.distanceMeters,
    required this.onStopTap,
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
  final void Function(String stopId) onStopTap;

  @override
  Widget build(BuildContext context) {
    return OptimizedRouteStepBody(
      stops: stops,
      routeName: routeName,
      startLocation: startLocation,
      destination: destination,
      durationMinutes: durationMinutes,
      distanceMeters: distanceMeters,
      stopTrailingBuilder: (stop) =>
          DeliveryIdChip(deliveryId: stop.deliveryId),
      onStopTap: onStopTap,
    );
  }
}

/// Rodapé do PRE-CONFIRM: duração total em VERDE à esquerda (quando há valor) +
/// "Refinar" (outline) + "Confirmar" (filled). Fiel ao Spoke (`8h16min` verde).
/// A duração é OMITIDA quando 0 (o valor real só chega na slice-3/GraphHopper —
/// não mostrar "0 min", que parece bug).
class PreConfirmFooter extends StatelessWidget {
  const PreConfirmFooter({
    required this.durationMinutes,
    required this.onRefine,
    required this.onConfirm,
    super.key,
  });

  final int durationMinutes;
  final VoidCallback onRefine;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (durationMinutes > 0) ...[
              Text(
                formatRouteDuration(durationMinutes),
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: OutlinedButton(
                onPressed: onRefine,
                child: const Text('Refinar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: onConfirm,
                child: const Text('Confirmar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
