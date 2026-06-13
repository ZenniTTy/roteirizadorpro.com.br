// Tests for PackageCountRow — MS-A6 T13
//
// Spec: docs/superpowers/specs/2026-06-11-area6-edit-stop-design.md §F8/H3
// Contrato: stepper inline [− N +]; clamp 1..9999; '−' sempre ativo (H3);
// tap no número abre PackageCountDialog.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/package_count_row.dart';

// ---------------------------------------------------------------------------
// Host StatefulWidget — mantém count e repassa para PackageCountRow.
// Captura os valores recebidos em onChanged para inspeção nos testes.
// ---------------------------------------------------------------------------

class _RowHost extends StatefulWidget {
  const _RowHost({required this.initial});
  final int initial;

  @override
  State<_RowHost> createState() => _RowHostState();
}

class _RowHostState extends State<_RowHost> {
  late int count;
  final List<int> received = [];

  @override
  void initState() {
    super.initState();
    count = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: PackageCountRow(
          count: count,
          onChanged: (v) {
            received.add(v);
            setState(() => count = v);
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------------

void main() {
  // ── 1. Renderização inicial ──────────────────────────────────────────────

  testWidgets(
    '1 — renderiza label "Pacotes", o número atual e os botões − e +',
    (tester) async {
      await tester.pumpWidget(const _RowHost(initial: 3));

      // Label
      expect(find.text('Pacotes'), findsOneWidget);
      // Número atual
      expect(find.text('3'), findsOneWidget);
      // Botões por Semantics
      expect(
        find.bySemanticsIdentifier('edit_stop_packages_minus'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsIdentifier('edit_stop_packages_plus'),
        findsOneWidget,
      );
    },
  );

  // ── 2. Tap + incrementa / decrementa ─────────────────────────────────────

  testWidgets(
    '2 — tap "+" chama onChanged(count+1); tap "−" chama onChanged(count−1)',
    (tester) async {
      await tester.pumpWidget(const _RowHost(initial: 5));

      final host = tester.state<_RowHostState>(find.byType(_RowHost));

      await tester.tap(find.bySemanticsIdentifier('edit_stop_packages_plus'));
      await tester.pump();
      expect(host.received.last, 6);

      await tester.tap(find.bySemanticsIdentifier('edit_stop_packages_minus'));
      await tester.pump();
      expect(host.received.last, 5);
    },
  );

  // ── 3. H3 — botão − no mínimo 1: ativo e clamp ───────────────────────────

  testWidgets(
    '3 (H3) — com count==1, botão "−" está ativo e onChanged(1) é chamado '
    '(clamp em 1, sem disabled inventado)',
    (tester) async {
      await tester.pumpWidget(const _RowHost(initial: 1));

      final host = tester.state<_RowHostState>(find.byType(_RowHost));

      await tester.tap(find.bySemanticsIdentifier('edit_stop_packages_minus'));
      await tester.pump();

      // Deve ter chamado onChanged — ou com 1 (clamp) ou sem exceção.
      // O contrato H3 diz: sem disabled; o tap deve chamar onChanged(1).
      expect(
        host.received,
        isNotEmpty,
        reason: 'onChanged deve ter sido chamado mesmo no limite mínimo',
      );
      expect(
        host.received.last,
        1,
        reason: 'clamp em 1 — não pode ir para 0',
      );
      // count do host permanece 1
      expect(host.count, 1);
    },
  );

  // ── 4. Clamp máximo 9999 ─────────────────────────────────────────────────

  testWidgets(
    '4 — com count==9999, tap "+" mantém 9999 (clamp máximo)',
    (tester) async {
      await tester.pumpWidget(const _RowHost(initial: 9999));

      final host = tester.state<_RowHostState>(find.byType(_RowHost));

      await tester.tap(find.bySemanticsIdentifier('edit_stop_packages_plus'));
      await tester.pump();

      expect(
        host.received.last,
        9999,
        reason: 'onChanged deve clampar em 9999',
      );
    },
  );

  // ── 5. Tap no número abre PackageCountDialog ──────────────────────────────

  testWidgets(
    '5 — tap no número (Semantics "edit_stop_packages_value") abre '
    'PackageCountDialog (Dialog com TextField presente)',
    (tester) async {
      await tester.pumpWidget(const _RowHost(initial: 7));

      await tester.tap(
        find.bySemanticsIdentifier('edit_stop_packages_value'),
      );
      await tester.pumpAndSettle();

      // O dialog deve estar aberto: encontramos Dialog e TextField.
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    },
  );

  // ── 6. Tap no número abre dialog com hintText correto ────────────────────

  testWidgets(
    '6 — dialog aberto via tap no número exibe hintText "1" no TextField',
    (tester) async {
      await tester.pumpWidget(const _RowHost(initial: 1));

      await tester.tap(
        find.bySemanticsIdentifier('edit_stop_packages_value'),
      );
      await tester.pumpAndSettle();

      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(
        tf.decoration?.hintText,
        '1',
        reason: 'placeholder do dialog deve ser "1" conforme F8',
      );
    },
  );

  // ── 7. Commit-on-dismiss: dismiss → onChanged com valor digitado ──────────

  testWidgets(
    '7 — digitar "25" no dialog + dismiss by barrier → host.count == 25',
    (tester) async {
      await tester.pumpWidget(const _RowHost(initial: 1));

      final host = tester.state<_RowHostState>(find.byType(_RowHost));

      await tester.tap(
        find.bySemanticsIdentifier('edit_stop_packages_value'),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '25');
      await tester.pump();

      // Dismiss via barrier (tap fora do dialog).
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(
        host.count,
        25,
        reason: 'commit-on-dismiss deve aplicar "25" no host',
      );
    },
  );

  // ── 8. Sem botão OK no dialog ────────────────────────────────────────────

  testWidgets(
    '8 — dialog NÃO contém botão "OK" nem "Concluído" (commit-on-dismiss, F8)',
    (tester) async {
      await tester.pumpWidget(const _RowHost(initial: 3));

      await tester.tap(
        find.bySemanticsIdentifier('edit_stop_packages_value'),
      );
      await tester.pumpAndSettle();

      expect(find.text('OK'), findsNothing);
      expect(find.text('Concluído'), findsNothing);
    },
  );
}
