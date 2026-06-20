// Tests for IdLockDialog — Á7 PR-C (Fase R/P0, A7-D6).
//
// Contrato (microcopy original fiel ao significado do dump):
//   - Título avisa que a numeração trava.
//   - Corpo explica que o código de cada parada não muda após confirmar.
//   - "Continuar" (FilledButton) → true (segue a confirmação).
//   - "Cancelar" (TextButton) → false.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/id_lock_dialog.dart';

void main() {
  Future<void> pumpHarness(
    WidgetTester tester,
    void Function(bool?) onResolved,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async => onResolved(await showIdLockDialog(context)),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('exibe título de trava + os dois botões', (tester) async {
    await pumpHarness(tester, (_) {});

    expect(find.text('A numeração vai travar'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
  });

  testWidgets('tap "Continuar" devolve true', (tester) async {
    bool? choice;
    await pumpHarness(tester, (c) => choice = c);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(choice, isTrue);
  });

  testWidgets('tap "Cancelar" devolve false', (tester) async {
    bool? choice;
    await pumpHarness(tester, (c) => choice = c);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(choice, isFalse);
  });
}
