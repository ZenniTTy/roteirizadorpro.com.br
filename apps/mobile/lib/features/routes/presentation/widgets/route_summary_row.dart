import 'package:flutter/material.dart';

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

  String _duration() {
    if (durationMinutes < 60) return '$durationMinutes min';
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  String _stops() => stopsCount == 1 ? '1 parada' : '$stopsCount paradas';

  String _distance() {
    final km = distanceMeters / 1000;
    return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        '${_duration()} · ${_stops()} · ${_distance()}',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
