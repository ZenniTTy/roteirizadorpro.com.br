import 'package:flutter/material.dart';

import '../../state/optimization_controller.dart';

/// Tela de progresso da otimização (4 fases). Microcopy PT-BR original
/// (ADR-0010), espelha as fases do Spoke (optimizing_analysing/sorting/
/// traffic/creating). Display-only — o avanço de fase é orquestrado pelo
/// `OptimizationController`.
class OptimizingProgressView extends StatelessWidget {
  const OptimizingProgressView({required this.phase, super.key});

  final OptimizationPhase phase;

  static const _labels = {
    OptimizationPhase.analysing: 'Analisando suas paradas...',
    OptimizationPhase.sorting: 'Encontrando a melhor ordem...',
    OptimizationPhase.traffic: 'Considerando o trânsito...',
    OptimizationPhase.creating: 'Criando sua rota...',
  };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(_labels[phase]!, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
