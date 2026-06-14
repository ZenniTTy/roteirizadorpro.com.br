// Tests for IdEducationDialog — Á7 PR-B Task T6.
//
// Contrato (microcopy travada, ADR-0010 — texto ORIGINAL, não verbatim do Spoke):
//   - Título: "Como a numeração funciona"
//   - Corpo explica o esquema A1/A2/A3 com ajuste automático ao reordenar.
//   - Botão "Ajustar formato" (TextButton) → devolve IdEducationChoice.configure.
//   - Botão "Entendi" (FilledButton) → devolve IdEducationChoice.acknowledge.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/id_education_dialog.dart';

void main() {
  // Abre o diálogo capturando a escolha numa variável do escopo do teste — lida
  // DEPOIS do tap (o `choice` só resolve quando o diálogo popa). Mesmo padrão do
  // confirm_deferred_removal_dialog_test.dart (sibling que passa).
  Future<void> pumpHarness(
    WidgetTester tester,
    void Function(IdEducationChoice?) onResolved,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async =>
                onResolved(await showIdEducationDialog(context)),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'exibe título "Como a numeração funciona" e os dois botões',
    (tester) async {
      await pumpHarness(tester, (_) {});

      expect(find.text('Como a numeração funciona'), findsOneWidget);
      expect(find.text('Entendi'), findsOneWidget);
      expect(find.text('Ajustar formato'), findsOneWidget);
    },
  );

  testWidgets(
    'tap "Entendi" devolve IdEducationChoice.acknowledge',
    (tester) async {
      IdEducationChoice? choice;
      await pumpHarness(tester, (c) => choice = c);

      await tester.tap(find.text('Entendi'));
      await tester.pumpAndSettle();

      expect(choice, IdEducationChoice.acknowledge);
    },
  );

  testWidgets(
    'tap "Ajustar formato" devolve IdEducationChoice.configure',
    (tester) async {
      IdEducationChoice? choice;
      await pumpHarness(tester, (c) => choice = c);

      await tester.tap(find.text('Ajustar formato'));
      await tester.pumpAndSettle();

      expect(choice, IdEducationChoice.configure);
    },
  );
}
