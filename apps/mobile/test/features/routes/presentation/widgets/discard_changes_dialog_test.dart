// Tests for DiscardChangesDialog — Á7 PR-C (Fase R/P0, A7-D7).
//
// Contrato (microcopy original fiel ao significado do dump):
//   - Título pergunta se descarta as alterações.
//   - Corpo avisa que a rota volta à última versão otimizada.
//   - "Descartar" (FilledButton) → true (descarta as edições).
//   - "Continuar editando" (TextButton) → false (mantém a edição).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/discard_changes_dialog.dart';

void main() {
  Future<void> pumpHarness(
    WidgetTester tester,
    void Function(bool?) onResolved,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async =>
                onResolved(await showDiscardChangesDialog(context)),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('exibe título + os dois botões', (tester) async {
    await pumpHarness(tester, (_) {});

    expect(find.text('Descartar as alterações?'), findsOneWidget);
    expect(find.text('Descartar'), findsOneWidget);
    expect(find.text('Continuar editando'), findsOneWidget);
  });

  testWidgets('tap "Descartar" devolve true', (tester) async {
    bool? choice;
    await pumpHarness(tester, (c) => choice = c);

    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();

    expect(choice, isTrue);
  });

  testWidgets('tap "Continuar editando" devolve false', (tester) async {
    bool? choice;
    await pumpHarness(tester, (c) => choice = c);

    await tester.tap(find.text('Continuar editando'));
    await tester.pumpAndSettle();

    expect(choice, isFalse);
  });
}
