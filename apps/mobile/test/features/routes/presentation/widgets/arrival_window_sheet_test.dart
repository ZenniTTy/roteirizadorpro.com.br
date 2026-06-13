// Tests for ArrivalWindowSheet — MS-A6 T15.
//
// Spec: docs/superpowers/plans/2026-06-11-area6-edit-stop-plan.md §T15
// Contrato: F7/H1/D8/H13/H19. Dump baseline: time_window_start_title /
// time_window_end_title / anytime strings (Spoke v3.65.1 jadx).
//
// Setup: host StatefulWidget dentro de MaterialApp.router (GoRouter) para
// satisfazer useRootNavigator: true (H13). O host exibe um botão que abre
// a ArrivalWindowSheet e exibe o resultado capturado via Text.
//
// Nota de tamanho de frame: títulos longos requerem Flexible no widget.
// Os testes que abrem o numpad (TimePickerSheet = segundo modal) usam um
// frame alto (1080×3200 / DPR 2.0) para que a sheet + numpad caibam sem
// overflow. Reset em addTearDown.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:roteirizador_pro/features/route_config/presentation/widgets/time_picker_sheet.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/arrival_window_sheet.dart';

// ---------------------------------------------------------------------------
// Host widget
// ---------------------------------------------------------------------------

class _SheetHost extends StatefulWidget {
  const _SheetHost({this.initialStart, this.initialEnd});
  final TimeOfDay? initialStart;
  final TimeOfDay? initialEnd;

  @override
  State<_SheetHost> createState() => _SheetHostState();
}

class _SheetHostState extends State<_SheetHost> {
  ArrivalWindow? _result;
  bool _opened = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            key: const Key('open_sheet'),
            onPressed: () async {
              final result = await ArrivalWindowSheet.show(
                context,
                initialStart: widget.initialStart,
                initialEnd: widget.initialEnd,
              );
              if (!mounted) return;
              setState(() {
                _result = result;
                _opened = true;
              });
            },
            child: const Text('Abrir'),
          ),
          if (_opened) ...[
            if (_result != null) ...[
              Text(
                'start:${_result!.start == null ? 'null' : '${_result!.start!.hour.toString().padLeft(2, '0')}:${_result!.start!.minute.toString().padLeft(2, '0')}'}',
                key: const Key('result_start'),
              ),
              Text(
                'end:${_result!.end == null ? 'null' : '${_result!.end!.hour.toString().padLeft(2, '0')}:${_result!.end!.minute.toString().padLeft(2, '0')}'}',
                key: const Key('result_end'),
              ),
            ],
            if (_result == null)
              const Text('dismissed', key: Key('result_dismissed')),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper: monta o host dentro de MaterialApp.router (para useRootNavigator)
// ---------------------------------------------------------------------------

Widget _buildApp({TimeOfDay? initialStart, TimeOfDay? initialEnd}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => _SheetHost(
          initialStart: initialStart,
          initialEnd: initialEnd,
        ),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void _useTallFrame(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 3200);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

// ---------------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------------

void main() {
  // ── 1. Header ──────────────────────────────────────────────────────────────

  group('1 — Header', () {
    testWidgets(
        'sheet abre com header: TextButton "Limpar" à esquerda, '
        'título "Horário de chegada" ao centro, TextButton "Concluído" à direita',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      expect(find.text('Limpar'), findsOneWidget);
      expect(find.text('Horário de chegada'), findsAtLeastNWidgets(1));
      expect(find.text('Concluído'), findsOneWidget);
    });
  });

  // ── 2. Rows com strings verbatim do dump ──────────────────────────────────

  group('2 — Rows com strings verbatim do dump (time_window_start/end_title)',
      () {
    testWidgets(
        'sheet exibe row "Chegar entre" e row "E" '
        '(time_window_start_title / time_window_end_title do dump v3.65.1)',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      expect(find.text('Chegar entre'), findsOneWidget);
      expect(find.text('E'), findsOneWidget);
    });

    testWidgets(
        'row sem valor exibe "Qualquer momento" (string anytime do dump)',
        (tester) async {
      // Ambos null → ambas as rows devem exibir 'Qualquer momento'.
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      // Duas ocorrências: uma em cada row.
      expect(find.text('Qualquer momento'), findsNWidgets(2));
    });

    testWidgets(
        'row "Chegar entre" com initialStart=09:30 exibe "09:30" '
        '(formato 24h HH:MM com zero-pad — NÃO TimeOfDay.format/locale)',
        (tester) async {
      await tester.pumpWidget(
        _buildApp(initialStart: const TimeOfDay(hour: 9, minute: 30)),
      );
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      // Row start deve exibir '09:30' (zero-pad).
      expect(find.text('09:30'), findsOneWidget);
      // A row end ainda deve ser 'Qualquer momento'.
      expect(find.text('Qualquer momento'), findsOneWidget);
    });

    testWidgets('row "E" com initialEnd=18:00 exibe "18:00" (formato 24h)',
        (tester) async {
      await tester.pumpWidget(
        _buildApp(initialEnd: const TimeOfDay(hour: 18, minute: 0)),
      );
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      expect(find.text('18:00'), findsOneWidget);
      // A row start ainda deve ser 'Qualquer momento'.
      expect(find.text('Qualquer momento'), findsOneWidget);
    });

    testWidgets(
        'com ambos os lados definidos (09:30/18:00) '
        'nenhuma row exibe "Qualquer momento"', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          initialStart: const TimeOfDay(hour: 9, minute: 30),
          initialEnd: const TimeOfDay(hour: 18, minute: 0),
        ),
      );
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      expect(find.text('09:30'), findsOneWidget);
      expect(find.text('18:00'), findsOneWidget);
      expect(find.text('Qualquer momento'), findsNothing);
    });
  });

  // ── 3. Semantics H19 ──────────────────────────────────────────────────────

  group('3 — Semantics H19', () {
    testWidgets(
        'rows expõem identifiers "edit_stop_window_start" e '
        '"edit_stop_window_end" (H19)', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsIdentifier('edit_stop_window_start'),
        findsOneWidget,
        reason:
            'Row "Chegar entre" deve expor identifier edit_stop_window_start',
      );
      expect(
        find.bySemanticsIdentifier('edit_stop_window_end'),
        findsOneWidget,
        reason: 'Row "E" deve expor identifier edit_stop_window_end',
      );
    });
  });

  // ── 4. Tap na row abre o numpad TimePickerSheet ───────────────────────────

  group('4 — Tap em row abre TimePickerSheet (numpad)', () {
    testWidgets(
        'tap na row "Chegar entre" (edit_stop_window_start) → '
        'find.byType(TimePickerSheet) aparece (segundo modal)', (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsIdentifier('edit_stop_window_start'));
      await tester.pumpAndSettle();

      expect(
        find.byType(TimePickerSheet),
        findsOneWidget,
        reason: 'Tap em "Chegar entre" deve abrir o TimePickerSheet (numpad)',
      );
    });

    testWidgets(
        'tap na row "E" (edit_stop_window_end) → '
        'find.byType(TimePickerSheet) aparece', (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsIdentifier('edit_stop_window_end'));
      await tester.pumpAndSettle();

      expect(
        find.byType(TimePickerSheet),
        findsOneWidget,
        reason: 'Tap em "E" deve abrir o TimePickerSheet (numpad)',
      );
    });

    testWidgets(
        'digitar 9 → :30 → confirmar no numpad → row "Chegar entre" '
        'passa a exibir "09:30" (estado local, sem commit ainda)',
        (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      // Abre numpad para 'Chegar entre'.
      await tester.tap(find.bySemanticsIdentifier('edit_stop_window_start'));
      await tester.pumpAndSettle();

      // Digita '9' no numpad.
      await tester.tap(find.bySemanticsIdentifier('time_picker_digit_9'));
      await tester.pump();

      // Toca ':30' (shortcut — 1 dígito no buffer → habilita).
      await tester.tap(find.bySemanticsIdentifier('time_picker_shortcut_30'));
      await tester.pump();

      // Confirma.
      await tester.tap(find.bySemanticsIdentifier('time_picker_confirm'));
      await tester.pumpAndSettle();

      // O numpad fechou; a sheet principal ainda está aberta.
      expect(find.byType(TimePickerSheet), findsNothing);
      // 'Horário de chegada' ainda visível (a própria sheet).
      expect(find.text('Horário de chegada'), findsAtLeastNWidgets(1));

      // A row start agora exibe '09:30'.
      expect(find.text('09:30'), findsOneWidget);
      // A row end continua 'Qualquer momento'.
      expect(find.text('Qualquer momento'), findsOneWidget);
    });
  });

  // ── 5. 'Concluído' popa o estado atual ───────────────────────────────────

  group('5 — "Concluído" popa o registro atual', () {
    testWidgets(
        '"Concluído" com ambos null → show() resolve '
        '(start: null, end: null)', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Concluído'));
      await tester.pumpAndSettle();

      // Sheet fechou.
      expect(find.text('Horário de chegada'), findsNothing);

      // Resultado: record non-null, mas start e end null.
      expect(find.byKey(const Key('result_start')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('result_start'))).data,
        'start:null',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('result_end'))).data,
        'end:null',
      );
    });

    testWidgets(
        '"Concluído" com initialStart=09:30 → show() resolve '
        '(start: 09:30, end: null) (H1: um lado só é válido)', (tester) async {
      await tester.pumpWidget(
        _buildApp(initialStart: const TimeOfDay(hour: 9, minute: 30)),
      );
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Concluído'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<Text>(find.byKey(const Key('result_start'))).data,
        'start:09:30',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('result_end'))).data,
        'end:null',
      );
    });

    testWidgets(
        '"Concluído" com initialStart=09:30 / initialEnd=18:00 → '
        'show() resolve (start: 09:30, end: 18:00)', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          initialStart: const TimeOfDay(hour: 9, minute: 30),
          initialEnd: const TimeOfDay(hour: 18, minute: 0),
        ),
      );
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Concluído'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<Text>(find.byKey(const Key('result_start'))).data,
        'start:09:30',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('result_end'))).data,
        'end:18:00',
      );
    });
  });

  // ── 6. 'Limpar' popa (start: null, end: null) ────────────────────────────

  group('6 — "Limpar" popa (start: null, end: null)', () {
    testWidgets(
        '"Limpar" com initialStart+initialEnd definidos → show() resolve '
        '(start: null, end: null) = limpar a janela', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          initialStart: const TimeOfDay(hour: 9, minute: 30),
          initialEnd: const TimeOfDay(hour: 18, minute: 0),
        ),
      );
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Limpar'));
      await tester.pumpAndSettle();

      // Sheet fechou.
      expect(find.text('Horário de chegada'), findsNothing);

      // Record retornado com ambos null.
      expect(
        tester.widget<Text>(find.byKey(const Key('result_start'))).data,
        'start:null',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('result_end'))).data,
        'end:null',
      );
    });

    testWidgets(
        '"Limpar" com ambos os lados null → show() resolve '
        '(start: null, end: null)', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Limpar'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<Text>(find.byKey(const Key('result_start'))).data,
        'start:null',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('result_end'))).data,
        'end:null',
      );
    });
  });

  // ── 7. Barrier dismiss → Future resolve null (cancel) ────────────────────

  group('7 — Dismiss (barrier) → Future resolve null', () {
    testWidgets('tap na barrier (fora da sheet) → show() resolve null (cancel)',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      // Tap no canto superior esquerdo — fora da sheet.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('result_dismissed')), findsOneWidget);
    });
  });
}
