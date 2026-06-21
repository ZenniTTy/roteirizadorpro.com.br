import 'package:flutter/material.dart';

/// Formata a duração total como "Xh Ymin" (só "min" quando < 1h, só "h" quando
/// minutos == 0). Fiel ao overview do Spoke (`8h16min`).
String formatRouteDuration(int durationMinutes) {
  if (durationMinutes < 60) return '$durationMinutes min';
  final h = durationMinutes ~/ 60;
  final m = durationMinutes % 60;
  return m == 0 ? '${h}h' : '${h}h ${m}min';
}

/// "1 parada" / "N paradas" (singular/plural PT-BR).
String formatStopsCount(int stopsCount) =>
    stopsCount == 1 ? '1 parada' : '$stopsCount paradas';

/// Distância em km com vírgula decimal PT-BR ("Z,Z km").
String formatRouteDistance(double distanceMeters) {
  final km = distanceMeters / 1000;
  return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
}

/// Monta a linha 1 do summary do estado otimizado: "duração · N paradas ·
/// distância". Quando duração E distância vêm 0 (o `LocalRouteOptimizer` não
/// mede estrada — só a slice-3/GraphHopper traz o valor real), os segmentos de
/// duração/distância são OMITIDOS (mostra só "N paradas") pra não exibir
/// "0 min · 0,0 km", que parece bug. O formato volta inteiro quando o valor
/// real chega.
String formatOptimizedSummaryLine({
  required int durationMinutes,
  required int stopsCount,
  required double distanceMeters,
}) {
  final stops = formatStopsCount(stopsCount);
  if (durationMinutes == 0 && distanceMeters == 0) return stops;
  return '${formatRouteDuration(durationMinutes)} · $stops · '
      '${formatRouteDistance(distanceMeters)}';
}

/// Linha de resumo do PRE-CONFIRM: "Xh Ymin · N paradas · Z,Z km". DISPLAY puro
/// (G4) — NÃO é clicável (sem InkWell/GestureDetector/Semantics(button)). A
/// estrutura (tempo+paradas+distância) espelha o overview do Spoke.
class RouteSummaryRow extends StatelessWidget {
  const RouteSummaryRow({
    required this.durationMinutes,
    required this.stopsCount,
    required this.distanceMeters,
    super.key,
  });

  final int durationMinutes;
  final int stopsCount;
  final double distanceMeters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        '${formatRouteDuration(durationMinutes)} · '
        '${formatStopsCount(stopsCount)} · '
        '${formatRouteDistance(distanceMeters)}',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
