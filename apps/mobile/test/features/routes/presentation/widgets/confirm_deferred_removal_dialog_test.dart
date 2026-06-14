// Tests for ConfirmDeferredRemovalDialog — Á7 T9 (remoção diferida).
//
// Contrato (microcopy travada ADR-0010 PT-BR original):
//   - Título: "Remover esta parada?"
//   - Corpo contém a label da parada interpolada + texto sobre "próxima" otimização.
//   - Botão "Cancelar" (TextButton) -> retorna false.
//   - Botão "Remover" (FilledButton) -> retorna true.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/confirm_deferred_removal_dialog.dart';

void main() {
  testWidgets(
      'abre com stopLabel A2 — corpo contém "próxima" — tap "Remover" retorna true',
      (tester) async {
    bool? confirmed;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              confirmed = await showConfirmDeferredRemovalDialog(
                context,
                stopLabel: 'A2',
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // título e corpo visíveis
    expect(find.text('Remover esta parada?'), findsOneWidget);
    expect(find.textContaining('próxima'), findsOneWidget);

    // label da parada interpolada no corpo
    expect(find.textContaining('A2'), findsOneWidget);

    // dois botões presentes
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Remover'), findsOneWidget);

    // tap no botão de confirmação -> retorna true
    await tester.tap(find.text('Remover'));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
  });

  testWidgets('tap "Cancelar" retorna false', (tester) async {
    bool? confirmed;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              confirmed = await showConfirmDeferredRemovalDialog(
                context,
                stopLabel: 'B3',
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(confirmed, isFalse);
  });
}
