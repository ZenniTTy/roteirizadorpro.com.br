// Tests for RefineRouteSheet — MS-A7 PR-B T7.
//
// Spec: MICROCOPY T7 (travada).
// Contrato:
//   - Sheet header: Text "Ajustar a rota".
//   - ListTile 1: title "Inverter a ordem", subtitle "Percorre as paradas de trás pra frente",
//     leading Icon(Icons.swap_vert) → popa RefineRouteChoice.invert.
//   - ListTile 2: title "Definir a ordem na mão", subtitle "Você arrasta as paradas na
//     sequência que quiser", leading Icon(Icons.gesture) → popa RefineRouteChoice.manualOrder.
//   - DISTINÇÃO CRÍTICA: esta sheet NÃO contém texto do ReoptimizeOptionsSheet (T8).
//     Assertar ausência de "Recalcular do zero" (e afins).
//
// Host: MaterialApp.router (GoRouter) — mesmo idiom dos demais testes de sheet.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/refine_route_sheet.dart';

// ---------------------------------------------------------------------------
// Host widget
// ---------------------------------------------------------------------------

class _SheetHost extends StatefulWidget {
  const _SheetHost();

  @override
  State<_SheetHost> createState() => _SheetHostState();
}

class _SheetHostState extends State<_SheetHost> {
  RefineRouteChoice? _choice;
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
              final result = await showRefineRouteSheet(context);
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
              'choice:${_choice?.name ?? 'null'}',
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
// Helper: monta host dentro de MaterialApp.router
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
  // ── 1. Conteúdo da sheet e ausência cruzada com T8 ───────────────────────

  group('1 — Conteúdo: itens presentes + ausência cruzada com T8', () {
    testWidgets(
        'sheet exibe "Inverter a ordem" e "Definir a ordem na mão"; '
        '"Recalcular do zero" está ausente (distinção T7 vs T8)',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      // Itens T7 presentes.
      expect(find.text('Inverter a ordem'), findsOneWidget);
      expect(find.text('Definir a ordem na mão'), findsOneWidget);

      // Texto exclusivo do T8 ausente (distinção crítica).
      expect(find.text('Recalcular do zero'), findsNothing);
    });

    testWidgets('sheet exibe título "Ajustar a rota"', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      expect(find.text('Ajustar a rota'), findsOneWidget);
    });

    testWidgets('sheet exibe subtítulos corretos para cada item',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      expect(
        find.text('Percorre as paradas de trás pra frente'),
        findsOneWidget,
      );
      expect(
        find.text('Você arrasta as paradas na sequência que quiser'),
        findsOneWidget,
      );
    });
  });

  // ── 2. Tap "Inverter a ordem" → choice == invert ─────────────────────────

  group('2 — Tap "Inverter a ordem" retorna RefineRouteChoice.invert', () {
    testWidgets('tap "Inverter a ordem" → showRefineRouteSheet resolve invert',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Inverter a ordem'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('result_choice')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('result_choice'))).data,
        'choice:invert',
      );
    });
  });

  // ── 3. Tap "Definir a ordem na mão" → choice == manualOrder ──────────────

  group(
      '3 — Tap "Definir a ordem na mão" retorna RefineRouteChoice.manualOrder',
      () {
    testWidgets(
        'tap "Definir a ordem na mão" → showRefineRouteSheet resolve manualOrder',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Definir a ordem na mão'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('result_choice')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('result_choice'))).data,
        'choice:manualOrder',
      );
    });
  });
}
