import 'package:flutter/material.dart';

/// Escolha do usuário no diálogo de falha de otimização.
enum OptimizationErrorChoice { retry, skip }

/// Falha de REDE/solver ao otimizar. Estrutura espelha
/// `optimization_failed_*` do Spoke (Tentar de novo / Pular
/// otimização). Distinto do `NotEnoughStopsDialog` (G1).
Future<OptimizationErrorChoice?> showOptimizationErrorDialog(
  BuildContext context,
) {
  return showDialog<OptimizationErrorChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Não foi possível otimizar'),
      content: const Text(
        'Confira sua conexão com a internet e tente de novo.',
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(OptimizationErrorChoice.skip),
          child: const Text('Pular otimização'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(OptimizationErrorChoice.retry),
          child: const Text('Tentar de novo'),
        ),
      ],
    ),
  );
}
