// Tests for PackageCountDialog — MS-A6 T13
//
// Spec: docs/superpowers/specs/2026-06-11-area6-edit-stop-design.md §F8/H3
// Contrato:
//   - TextField só-dígitos, max 4 chars.
//   - hintText '1' (placeholder).
//   - current > 1 → TextField pré-preenchido com o valor atual.
//   - current == 1 → campo vazio (só hint '1').
//   - Commit-on-dismiss SEM botão OK: dismiss da barrier aplica o digitado.
//   - Campo vazio ou valor ≤ 1 → retorna 1 (clamp).
//   - onSubmitted (Enter/done) também fecha e resolve.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/package_count_dialog.dart';

// ---------------------------------------------------------------------------
// Host: abre o dialog quando o botão é tocado e expõe o resultado.
// ---------------------------------------------------------------------------

class _DialogHost extends StatefulWidget {
  const _DialogHost({required this.current});
  final int current;

  @override
  State<_DialogHost> createState() => _DialogHostState();
}

class _DialogHostState extends State<_DialogHost> {
  int? result;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          // Builder: o context do showDialog precisa estar ABAIXO do
          // MaterialApp (MaterialLocalizations).
          child: Builder(
            builder: (innerContext) => ElevatedButton(
              onPressed: () async {
                final v = await PackageCountDialog.show(
                  innerContext,
                  current: widget.current,
                );
                setState(() => result = v);
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------------

void main() {
  // ── 6. Filtro só-dígitos e max 4 chars ───────────────────────────────────

  testWidgets(
    '6a — digitar "a1b2" resulta "12" (filtro só-dígitos)',
    (tester) async {
      await tester.pumpWidget(const _DialogHost(current: 1));

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'a1b2');
      await tester.pump();

      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(
        tf.controller?.text,
        '12',
        reason: 'filtro deve remover caracteres não-dígitos',
      );
    },
  );

  testWidgets(
    '6b — digitar "123456" resulta "1234" (max 4 chars)',
    (tester) async {
      await tester.pumpWidget(const _DialogHost(current: 1));

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();

      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(
        tf.controller?.text,
        '1234',
        reason: 'máximo de 4 caracteres',
      );
    },
  );

  // ── 7. Commit-on-dismiss (barrier) SEM botão OK ───────────────────────────

  testWidgets(
    '7a — digitar "25" + dismiss pela barrier → show() resolve 25',
    (tester) async {
      await tester.pumpWidget(const _DialogHost(current: 1));

      final host = tester.state<_DialogHostState>(find.byType(_DialogHost));

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '25');
      await tester.pump();

      // Dismiss via barrier.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(host.result, 25);
    },
  );

  testWidgets(
    '7b — NÃO existe botão "OK" nem "Concluído" no dialog (commit-on-dismiss, F8)',
    (tester) async {
      await tester.pumpWidget(const _DialogHost(current: 3));

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.text('OK'), findsNothing);
      expect(find.text('Concluído'), findsNothing);
    },
  );

  // ── 8. Clamp: "0" → 1; vazio → 1 ─────────────────────────────────────────

  testWidgets(
    '8a — digitar "0" + dismiss → show() resolve 1 (clamp ≤1 → 1, H3)',
    (tester) async {
      await tester.pumpWidget(const _DialogHost(current: 1));

      final host = tester.state<_DialogHostState>(find.byType(_DialogHost));

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '0');
      await tester.pump();

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(
        host.result,
        1,
        reason: '"0" deve ser clampado para 1',
      );
    },
  );

  testWidgets(
    '8b — campo vazio + dismiss → show() resolve 1 (placeholder semantics)',
    (tester) async {
      await tester.pumpWidget(const _DialogHost(current: 3));

      final host = tester.state<_DialogHostState>(find.byType(_DialogHost));

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      // Limpa o campo (current=3 → pré-preenchido com '3'; apagamos tudo).
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(
        host.result,
        1,
        reason: 'campo vazio deve resolver para 1 (placeholder semantics)',
      );
    },
  );

  // ── 9. Pré-preenchimento: current > 1 → texto; current == 1 → vazio + hint

  testWidgets(
    '9a — show(current: 7) → TextField pré-preenchido com "7"',
    (tester) async {
      await tester.pumpWidget(const _DialogHost(current: 7));

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(
        tf.controller?.text,
        '7',
        reason: 'current > 1 deve pré-preencher o campo para facilitar edição',
      );
    },
  );

  testWidgets(
    '9b — show(current: 1) → TextField vazio com hintText "1"',
    (tester) async {
      await tester.pumpWidget(const _DialogHost(current: 1));

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(
        tf.controller?.text,
        '',
        reason: 'current == 1 deve deixar o campo vazio (só hint)',
      );
      expect(
        tf.decoration?.hintText,
        '1',
        reason: 'placeholder "1" deve estar no hintText',
      );
    },
  );

  // ── 10. onSubmitted (Enter/done) fecha e resolve ──────────────────────────

  testWidgets(
    '10 — digitar "15" + pressionar Enter (onSubmitted) → show() resolve 15',
    (tester) async {
      await tester.pumpWidget(const _DialogHost(current: 1));

      final host = tester.state<_DialogHostState>(find.byType(_DialogHost));

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '15');
      await tester.pump();

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(
        host.result,
        15,
        reason: 'onSubmitted/done deve fechar e resolver o valor digitado',
      );
    },
  );
}
