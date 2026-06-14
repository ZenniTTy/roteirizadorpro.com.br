// Tests for OptimizationErrorDialog — MS-A7 Task 9 (erro de rede/otimização).
//
// Contrato (dump Spoke v3.65.1 — optimization_error alert):
//   - Exibe botão "Tentar de novo" → retorna OptimizationErrorChoice.retry.
//   - Exibe botão "Pular otimização" → retorna OptimizationErrorChoice.skip.
//   - Os dois botões estão presentes simultaneamente.
//   - NÃO exibe "Adicione mais paradas" (exclusivo do NotEnoughStopsDialog).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/optimization_error_dialog.dart';

void main() {
  testWidgets('erro de rede: "Tentar de novo" + "Pular otimização"',
      (tester) async {
    OptimizationErrorChoice? choice;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async =>
              choice = await showOptimizationErrorDialog(context),
          child: const Text('open'),
        ),
      ),
    ),);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Tentar de novo'), findsOneWidget);
    expect(find.text('Pular otimização'), findsOneWidget);

    await tester.tap(find.text('Pular otimização'));
    await tester.pumpAndSettle();

    expect(choice, OptimizationErrorChoice.skip);
  });
}
