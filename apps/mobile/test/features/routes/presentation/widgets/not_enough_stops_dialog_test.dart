// Tests for NotEnoughStopsDialog — MS-A7 Task 9 (G1 — poucas paradas).
//
// Contrato (dump Spoke v3.65.1 — estrutura equivalente ao alert "poucos stops"):
//   - Exibe título/corpo "Adicione mais paradas".
//   - Único botão de ação: "Ok" (fecha o dialog).
//   - NÃO exibe "Pular otimização" (botão exclusivo do diálogo de erro de rede).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/not_enough_stops_dialog.dart';

void main() {
  testWidgets('mostra título "Adicione mais paradas" + único botão "Ok"',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showNotEnoughStopsDialog(context),
          child: const Text('open'),
        ),
      ),
    ),);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Adicione mais paradas'), findsOneWidget);
    expect(find.text('Ok'), findsOneWidget);
    // Distinto do erro de rede: NÃO tem "Pular otimização".
    expect(find.text('Pular otimização'), findsNothing);
  });
}
