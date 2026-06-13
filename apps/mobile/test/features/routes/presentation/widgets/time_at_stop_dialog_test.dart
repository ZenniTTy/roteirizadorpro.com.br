// Tests for TimeAtStopDialog — MS-A6 T16.
//
// Spec: docs/superpowers/plans/2026-06-11-area6-edit-stop-plan.md §T16 / F9/H14.
// Contrato (dump Spoke v3.65.1 — minutes_selection_title / seconds_selection_title):
//   - Título 'Tempo na parada'.
//   - Dois TextFields: label/hint 'Minutos' e 'Segundos'.
//   - Filtro só-dígitos + max 5 chars em ambos.
//   - Hints = componentes de defaultDuration (ex.: 1 min → '1'/'0').
//   - Pré-preenchimento: current != null → minutos/segundos preenchidos;
//     current == null → ambos vazios.
//   - Commit-on-dismiss SEM botão OK (PopScope canPop:false — mesmo padrão do
//     PackageCountDialog): barrier + back popam com valor.
//   - Ambos vazios ou total zero → resolve (duration: null) (herda default).
//   - SEM botão 'OK' / 'Concluído' no dialog.
//
// Host: StatefulWidget dentro de MaterialApp (Builder/innerContext para
// MaterialLocalizations, mesma estrutura do package_count_dialog_test.dart).
// Os 2 TextFields distinguidos por índice (at(0) = Minutos, at(1) = Segundos).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/time_at_stop_dialog.dart';

// ---------------------------------------------------------------------------
// Host
// ---------------------------------------------------------------------------

class _DialogHost extends StatefulWidget {
  const _DialogHost({required this.current, required this.defaultDuration});
  final Duration? current;
  final Duration defaultDuration;

  @override
  State<_DialogHost> createState() => _DialogHostState();
}

class _DialogHostState extends State<_DialogHost> {
  ({Duration? duration})? result;
  bool opened = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (innerContext) => ElevatedButton(
              onPressed: () async {
                final v = await TimeAtStopDialog.show(
                  innerContext,
                  current: widget.current,
                  defaultDuration: widget.defaultDuration,
                );
                setState(() {
                  result = v;
                  opened = true;
                });
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
  // ── 1. Título e labels dos campos ─────────────────────────────────────────

  group('1 — Título e labels (dump strings verbatim)', () {
    testWidgets('1a — dialog exibe título "Tempo na parada"', (tester) async {
      await tester.pumpWidget(
        const _DialogHost(
          current: null,
          defaultDuration: Duration(minutes: 1),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Tempo na parada'), findsOneWidget);
    });

    testWidgets(
        '1b — dialog exibe label/hint "Minutos" '
        '(minutes_selection_title do dump v3.65.1)', (tester) async {
      await tester.pumpWidget(
        const _DialogHost(
          current: null,
          defaultDuration: Duration(minutes: 1),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Minutos'), findsAtLeastNWidgets(1));
    });

    testWidgets(
        '1c — dialog exibe label/hint "Segundos" '
        '(seconds_selection_title do dump v3.65.1)', (tester) async {
      await tester.pumpWidget(
        const _DialogHost(
          current: null,
          defaultDuration: Duration(minutes: 1),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Segundos'), findsAtLeastNWidgets(1));
    });
  });

  // ── 2. Filtro só-dígitos e max 5 chars ────────────────────────────────────

  group('2 — Filtro de entrada', () {
    testWidgets(
        '2a — digitar "a1b2" no campo Minutos resulta "12" (filtro só-dígitos)',
        (tester) async {
      await tester.pumpWidget(
        const _DialogHost(
          current: null,
          defaultDuration: Duration(minutes: 1),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'a1b2');
      await tester.pump();

      final tf = tester.widget<TextField>(find.byType(TextField).at(0));
      expect(
        tf.controller?.text,
        '12',
        reason: 'filtro deve remover caracteres não-dígitos no campo Minutos',
      );
    });

    testWidgets(
        '2b — digitar "a1b2" no campo Segundos resulta "12" (filtro só-dígitos)',
        (tester) async {
      await tester.pumpWidget(
        const _DialogHost(
          current: null,
          defaultDuration: Duration(minutes: 1),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(1), 'a1b2');
      await tester.pump();

      final tf = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(
        tf.controller?.text,
        '12',
        reason: 'filtro deve remover caracteres não-dígitos no campo Segundos',
      );
    });

    testWidgets(
        '2c — digitar "123456" no campo Minutos resulta "12345" (max 5 chars)',
        (tester) async {
      await tester.pumpWidget(
        const _DialogHost(
          current: null,
          defaultDuration: Duration(minutes: 1),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), '123456');
      await tester.pump();

      final tf = tester.widget<TextField>(find.byType(TextField).at(0));
      expect(
        tf.controller?.text,
        '12345',
        reason: 'max 5 chars no campo Minutos',
      );
    });

    testWidgets(
        '2d — digitar "123456" no campo Segundos resulta "12345" (max 5 chars)',
        (tester) async {
      await tester.pumpWidget(
        const _DialogHost(
          current: null,
          defaultDuration: Duration(minutes: 1),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(1), '123456');
      await tester.pump();

      final tf = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(
        tf.controller?.text,
        '12345',
        reason: 'max 5 chars no campo Segundos',
      );
    });
  });

  // ── 3. Hints = componentes de defaultDuration ─────────────────────────────

  group('3 — Hints derivados de defaultDuration', () {
    testWidgets(
        '3a — defaultDuration=1min → hintText Minutos="1", Segundos="0"',
        (tester) async {
      await tester.pumpWidget(
        const _DialogHost(
          current: null,
          defaultDuration: Duration(minutes: 1),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      final tfMin = tester.widget<TextField>(find.byType(TextField).at(0));
      final tfSec = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(
        tfMin.decoration?.hintText,
        '1',
        reason: 'hint Minutos deve ser "1" para defaultDuration=1min',
      );
      expect(
        tfSec.decoration?.hintText,
        '0',
        reason: 'hint Segundos deve ser "0" para defaultDuration=1min',
      );
    });

    testWidgets(
        '3b — defaultDuration=90s (1min30s) → hintText Minutos="1", Segundos="30"',
        (tester) async {
      await tester.pumpWidget(
        const _DialogHost(
          current: null,
          defaultDuration: Duration(minutes: 1, seconds: 30),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      final tfMin = tester.widget<TextField>(find.byType(TextField).at(0));
      final tfSec = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(
        tfMin.decoration?.hintText,
        '1',
        reason: 'hint Minutos deve ser "1" para defaultDuration=90s',
      );
      expect(
        tfSec.decoration?.hintText,
        '30',
        reason: 'hint Segundos deve ser "30" para defaultDuration=90s',
      );
    });
  });

  // ── 4. Pré-preenchimento conforme current ─────────────────────────────────

  group('4 — Pré-preenchimento', () {
    testWidgets('4a — current == null → ambos os campos vazios (herda default)',
        (tester) async {
      await tester.pumpWidget(
        const _DialogHost(
          current: null,
          defaultDuration: Duration(minutes: 1),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      final tfMin = tester.widget<TextField>(find.byType(TextField).at(0));
      final tfSec = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(
        tfMin.controller?.text,
        '',
        reason: 'current==null: campo Minutos deve estar vazio',
      );
      expect(
        tfSec.controller?.text,
        '',
        reason: 'current==null: campo Segundos deve estar vazio',
      );
    });

    testWidgets(
        '4b — current=Duration(minutes:2, seconds:30) → Minutos="2", Segundos="30"',
        (tester) async {
      await tester.pumpWidget(
        const _DialogHost(
          current: Duration(minutes: 2, seconds: 30),
          defaultDuration: Duration(minutes: 1),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      final tfMin = tester.widget<TextField>(find.byType(TextField).at(0));
      final tfSec = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(
        tfMin.controller?.text,
        '2',
        reason: 'current=2m30s: campo Minutos deve conter "2"',
      );
      expect(
        tfSec.controller?.text,
        '30',
        reason: 'current=2m30s: campo Segundos deve conter "30"',
      );
    });

    testWidgets('4c — current=Duration(minutes:5) → Minutos="5", Segundos="0"',
        (tester) async {
      await tester.pumpWidget(
        const _DialogHost(
          current: Duration(minutes: 5),
          defaultDuration: Duration(minutes: 1),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      final tfMin = tester.widget<TextField>(find.byType(TextField).at(0));
      final tfSec = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(
        tfMin.controller?.text,
        '5',
        reason: 'current=5min: campo Minutos deve conter "5"',
      );
      expect(
        tfSec.controller?.text,
        '0',
        reason: 'current=5min: campo Segundos deve conter "0"',
      );
    });
  });

  // ── 5. Sem botão OK/Concluído ─────────────────────────────────────────────

  group('5 — SEM botão OK/Concluído no dialog (commit-on-dismiss)', () {
    testWidgets('5 — NÃO existe botão "OK" nem "Concluído" no dialog',
        (tester) async {
      await tester.pumpWidget(
        const _DialogHost(
          current: null,
          defaultDuration: Duration(minutes: 1),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.text('OK'), findsNothing);
      expect(find.text('Concluído'), findsNothing);
    });
  });

  // ── 6. Commit-on-dismiss (barrier) ────────────────────────────────────────

  group('6 — Commit-on-dismiss via barrier', () {
    testWidgets(
        '6a — Minutos="5" + barrier dismiss → show() resolve (duration: 5min)',
        (tester) async {
      await tester.pumpWidget(
        const _DialogHost(
          current: null,
          defaultDuration: Duration(minutes: 1),
        ),
      );
      final host = tester.state<_DialogHostState>(find.byType(_DialogHost));

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), '5');
      await tester.pump();

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(
        host.result?.duration,
        const Duration(minutes: 5),
        reason: 'Minutos="5" + Segundos vazio → Duration(minutes:5)',
      );
    });

    testWidgets(
        '6b — Minutos vazio + Segundos="30" + barrier dismiss → '
        'show() resolve (duration: 30s)', (tester) async {
      await tester.pumpWidget(
        const _DialogHost(
          current: null,
          defaultDuration: Duration(minutes: 1),
        ),
      );
      final host = tester.state<_DialogHostState>(find.byType(_DialogHost));

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(1), '30');
      await tester.pump();

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(
        host.result?.duration,
        const Duration(seconds: 30),
        reason: 'Minutos vazio + Segundos="30" → Duration(seconds:30)',
      );
    });
  });

  // ── 7. Ambos vazios ou total zero → (duration: null) ──────────────────────

  group('7 — Vazios/zero resolve (duration: null)', () {
    testWidgets(
        '7a — ambos os campos vazios + dismiss → show() resolve (duration: null)',
        (tester) async {
      await tester.pumpWidget(
        const _DialogHost(
          current: null,
          defaultDuration: Duration(minutes: 1),
        ),
      );
      final host = tester.state<_DialogHostState>(find.byType(_DialogHost));

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      // Não digita nada — campos vazios.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(
        host.result?.duration,
        isNull,
        reason: 'ambos vazios → (duration: null) = herda default',
      );
    });

    testWidgets(
        '7b — Minutos="0" + Segundos="0" + dismiss → show() resolve (duration: null)',
        (tester) async {
      await tester.pumpWidget(
        const _DialogHost(
          current: null,
          defaultDuration: Duration(minutes: 1),
        ),
      );
      final host = tester.state<_DialogHostState>(find.byType(_DialogHost));

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), '0');
      await tester.enterText(find.byType(TextField).at(1), '0');
      await tester.pump();

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(
        host.result?.duration,
        isNull,
        reason: 'total zero → (duration: null)',
      );
    });

    testWidgets(
        '7c — Minutos="0" + Segundos vazio + dismiss → show() resolve (duration: null)',
        (tester) async {
      await tester.pumpWidget(
        const _DialogHost(
          current: null,
          defaultDuration: Duration(minutes: 1),
        ),
      );
      final host = tester.state<_DialogHostState>(find.byType(_DialogHost));

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), '0');
      await tester.pump();

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(
        host.result?.duration,
        isNull,
        reason: '"0" minutos e segundos vazio → total zero → (duration: null)',
      );
    });
  });
}
