import 'package:flutter/material.dart';

import '../../state/optimization_controller.dart';

/// Tela de progresso da otimização (4 fases). A ESTRUTURA (4 fases sequenciais)
/// espelha o Spoke (`optimizing_analysing/sorting/traffic/creating`), mas o
/// TEXTO é microcopy PT-BR ORIGINAL (ADR-0010) — deliberadamente reformulado,
/// nunca verbatim das strings traduzidas do Spoke/Circuit. Display-only — o
/// avanço de fase é orquestrado pelo `OptimizationController`.
class OptimizingProgressView extends StatelessWidget {
  const OptimizingProgressView({required this.phase, super.key});

  final OptimizationPhase phase;

  static const _labels = {
    OptimizationPhase.analysing: 'Conferindo suas entregas...',
    OptimizationPhase.sorting: 'Montando a melhor sequência...',
    OptimizationPhase.traffic: 'Avaliando o trânsito na região...',
    OptimizationPhase.creating: 'Finalizando sua rota...',
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
