// Tests for ReoptimizeOptionsSheet — Á7 PR-B T8.
//
// Spec: MICROCOPY TRAVADA T8 (comparada 1:1 com dump Spoke v3.65.1).
// Contrato:
//   - Função showReoptimizeOptionsSheet(BuildContext) -> Future<ReoptimizeChoice?>
//   - Título do sheet: "Como recalcular"
//   - Item 1: ListTile title "Ajustar o que mudou"
//             subtitle "Mantém a rota e reposiciona só as paradas novas"
//             icon Icons.update → pop ReoptimizeChoice.update
//   - Item 2: ListTile title "Recalcular do zero"
//             subtitle "Refaz a sequência inteira em busca da melhor ordem"
//             icon Icons.auto_awesome → pop ReoptimizeChoice.reoptimize
//   - Dismiss da barrier → null
//   - DISTINÇÃO CRÍTICA: este sheet NÃO contém strings do RefineRouteSheet (T7).
//     "Inverter a ordem" e "Definir a ordem na mão" devem ser findsNothing aqui.
//
// Host: MaterialApp.router (GoRouter) — idiom do access_instructions_sheet_test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/reoptimize_options_sheet.dart';

// ---------------------------------------------------------------------------
// Host widget
// ---------------------------------------------------------------------------

class _SheetHost extends StatefulWidget {
  const _SheetHost();

  @override
  State<_SheetHost> createState() => _SheetHostState();
}

class _SheetHostState extends State<_SheetHost> {
  ReoptimizeChoice? _choice;
  bool _opened = false;
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            key: const Key('open_sheet'),
            onPressed: () async {
              final result = await showReoptimizeOptionsSheet(context);
              if (!mounted) return;
              setState(() {
                _choice = result;
                _opened = true;
                _dismissed = result == null;
              });
            },
            child: const Text('Abrir'),
          ),
          if (_opened && !_dismissed)
            Text(
              'choice:${_choice?.name}',
              key: const Key('result_choice'),
            ),
          if (_opened && _dismissed)
            const Text('dismissed', key: Key('result_dismissed')),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper: monta host dentro de MaterialApp.router (useRootNavigator: true)
// ---------------------------------------------------------------------------

Widget _buildApp() {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const _SheetHost(),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

// ---------------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------------

void main() {
  // ── 1. Conteúdo do sheet ─────────────────────────────────────────────────

  group('1 — Conteúdo do sheet', () {
    testWidgets(
        '1a — sheet abre com título "Como recalcular" e os dois itens canônicos',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      expect(find.text('Como recalcular'), findsOneWidget);
      expect(find.text('Ajustar o que mudou'), findsOneWidget);
      expect(
        find.text('Mantém a rota e reposiciona só as paradas novas'),
        findsOneWidget,
      );
      expect(find.text('Recalcular do zero'), findsOneWidget);
      expect(
        find.text('Refaz a sequência inteira em busca da melhor ordem'),
        findsOneWidget,
      );
    });

    testWidgets(
        '1b — DISTINÇÃO CRÍTICA: strings do RefineRouteSheet (T7) NÃO aparecem '
        'neste sheet ("Inverter a ordem", "Definir a ordem na mão")',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      expect(find.text('Inverter a ordem'), findsNothing);
      expect(find.text('Definir a ordem na mão'), findsNothing);
      expect(find.text('Ajustar a rota'), findsNothing);
    });
  });

  // ── 2. Tap em "Recalcular do zero" → ReoptimizeChoice.reoptimize ─────────

  group('2 — Tap "Recalcular do zero" → choice == reoptimize', () {
    testWidgets(
        'tap em "Recalcular do zero" → showReoptimizeOptionsSheet() resolve '
        'ReoptimizeChoice.reoptimize', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Recalcular do zero'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('result_choice')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('result_choice'))).data,
        'choice:reoptimize',
      );
    });
  });

  // ── 3. Tap em "Ajustar o que mudou" → ReoptimizeChoice.update ────────────

  group('3 — Tap "Ajustar o que mudou" → choice == update', () {
    testWidgets(
        'tap em "Ajustar o que mudou" → showReoptimizeOptionsSheet() resolve '
        'ReoptimizeChoice.update', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ajustar o que mudou'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('result_choice')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('result_choice'))).data,
        'choice:update',
      );
    });
  });

  // ── 4. Dismiss (barrier) → null ──────────────────────────────────────────

  group('4 — Dismiss (barrier) → null', () {
    testWidgets('tap na barrier (fora da sheet) → resolve null (cancel)',
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
