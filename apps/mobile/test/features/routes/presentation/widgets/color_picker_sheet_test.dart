// Tests for ColorPickerSheet — MS-A6 T10.
//
// Spec: docs/superpowers/specs/2026-06-11-area6-edit-stop-design.md
// Contrato: F10, H13, H19.
//
// Setup: host widget (StatefulWidget) que chama ColorPickerSheet.show() e
// captura o ColorPickerResult retornado. Wrapped com MaterialApp.router via
// GoRouter para satisfazer useRootNavigator: true (H13).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:roteirizador_pro/features/routes/domain/stop_color.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/color_picker_sheet.dart';

// ---------------------------------------------------------------------------
// Host widget (abre a sheet e captura o resultado)
// ---------------------------------------------------------------------------

/// Widget de teste que expõe um botão para abrir a [ColorPickerSheet] e
/// exibe o resultado capturado na superfície para asserção.
class _SheetHost extends StatefulWidget {
  const _SheetHost({this.current});
  final StopColor? current;

  @override
  State<_SheetHost> createState() => _SheetHostState();
}

class _SheetHostState extends State<_SheetHost> {
  ColorPickerResult? _result;
  bool _opened = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            key: const Key('open_sheet'),
            onPressed: () async {
              final result = await ColorPickerSheet.show(
                context,
                current: widget.current,
              );
              setState(() {
                _result = result;
                _opened = true;
              });
            },
            child: const Text('Abrir'),
          ),
          if (_opened) ...[
            if (_result is ColorPicked)
              Text('picked:${(_result as ColorPicked).color.name}'),
            if (_result is ColorCleared) const Text('cleared'),
            if (_result == null) const Text('dismissed'),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper: monta o host dentro de MaterialApp.router (para useRootNavigator)
// ---------------------------------------------------------------------------

Widget _buildApp({StopColor? current}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => _SheetHost(current: current),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

// ---------------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------------

void main() {
  // ── 1. Header da sheet ────────────────────────────────────────────────────

  group('Header', () {
    testWidgets(
        'sheet abre com header: texto "Limpar" à esquerda, '
        '"Cor" ao centro e "Concluído" à direita', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      expect(find.text('Limpar'), findsOneWidget);
      expect(find.text('Cor'), findsOneWidget);
      expect(find.text('Concluído'), findsOneWidget);
    });
  });

  // ── 2. Swatches — presença e ordem ────────────────────────────────────────

  group('Swatches', () {
    testWidgets(
        'exatamente 5 swatches na ordem blue/teal/purple/pink/orange (F10) '
        'com Semantics identifier edit_stop_color_<name> (H19)',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      // Todos os 5 Semantics identifiers devem existir.
      for (final color in StopColor.values) {
        expect(
          find.bySemanticsIdentifier('edit_stop_color_${color.name}'),
          findsOneWidget,
          reason: 'swatch ${color.name} ausente',
        );
      }

      // Ordem de posição horizontal: blue à esquerda de teal, teal de purple,
      // purple de pink, pink de orange.
      final swatchOrder = [
        StopColor.blue,
        StopColor.teal,
        StopColor.purple,
        StopColor.pink,
        StopColor.orange,
      ];
      for (var i = 0; i < swatchOrder.length - 1; i++) {
        final a = swatchOrder[i];
        final b = swatchOrder[i + 1];
        final dxA = tester
            .getCenter(
              find.bySemanticsIdentifier('edit_stop_color_${a.name}'),
            )
            .dx;
        final dxB = tester
            .getCenter(
              find.bySemanticsIdentifier('edit_stop_color_${b.name}'),
            )
            .dx;
        expect(
          dxA,
          lessThan(dxB),
          reason: '${a.name} deve estar à esquerda de ${b.name}',
        );
      }
    });
  });

  // ── 3. Check no swatch current ────────────────────────────────────────────

  group('Seleção inicial', () {
    testWidgets('swatch da cor current (teal) exibe 1 check; os outros não',
        (tester) async {
      await tester.pumpWidget(_buildApp(current: StopColor.teal));
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      // Deve haver exatamente 1 widget com Key('color_swatch_check').
      expect(find.byKey(const Key('color_swatch_check')), findsOneWidget);

      // O check deve estar posicionado sobre o swatch teal.
      final checkCenter = tester.getCenter(
        find.byKey(const Key('color_swatch_check')),
      );
      final tealCenter = tester.getCenter(
        find.bySemanticsIdentifier('edit_stop_color_teal'),
      );
      // O check está dentro do swatch teal (±40 px de margem para padding).
      expect(
        (checkCenter - tealCenter).distance,
        lessThan(40),
        reason: 'check deve estar posicionado no swatch teal',
      );
    });

    testWidgets('sem current, nenhum check exibido', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('color_swatch_check')), findsNothing);
    });
  });

  // ── 4. Tap num swatch muda seleção local (sem fechar) ────────────────────

  group('Seleção interativa', () {
    testWidgets(
        'tap em swatch orange migra o check para orange sem fechar a sheet',
        (tester) async {
      await tester.pumpWidget(_buildApp(current: StopColor.blue));
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      // Blue estava selecionado inicialmente.
      expect(find.byKey(const Key('color_swatch_check')), findsOneWidget);

      // Tap em orange.
      await tester.tap(
        find.bySemanticsIdentifier('edit_stop_color_orange'),
      );
      await tester.pump();

      // Sheet ainda está aberta (texto 'Concluído' visível).
      expect(find.text('Concluído'), findsOneWidget);

      // Check migrou para orange.
      final checkCenter = tester.getCenter(
        find.byKey(const Key('color_swatch_check')),
      );
      final orangeCenter = tester.getCenter(
        find.bySemanticsIdentifier('edit_stop_color_orange'),
      );
      expect(
        (checkCenter - orangeCenter).distance,
        lessThan(40),
        reason: 'check deve estar no swatch orange após o tap',
      );
    });
  });

  // ── 5. 'Concluído' → fecha e retorna ColorPicked ─────────────────────────

  group('Concluído', () {
    testWidgets(
        '"Concluído" fecha a sheet e show() resolve ColorPicked(corSelecionada)',
        (tester) async {
      await tester.pumpWidget(_buildApp(current: StopColor.purple));
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Concluído'));
      await tester.pumpAndSettle();

      // Sheet fechou (header 'Cor' não mais visível).
      expect(find.text('Cor'), findsNothing);

      // Host exibe o resultado capturado.
      expect(find.text('picked:purple'), findsOneWidget);
    });

    testWidgets('"Concluído" após mudar seleção retorna a nova cor',
        (tester) async {
      await tester.pumpWidget(_buildApp(current: StopColor.blue));
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      // Muda para pink.
      await tester.tap(
        find.bySemanticsIdentifier('edit_stop_color_pink'),
      );
      await tester.pump();

      await tester.tap(find.text('Concluído'));
      await tester.pumpAndSettle();

      expect(find.text('picked:pink'), findsOneWidget);
    });
  });

  // ── 6. 'Limpar' → fecha e retorna ColorCleared ───────────────────────────

  group('Limpar', () {
    testWidgets('"Limpar" fecha a sheet e show() resolve ColorCleared()',
        (tester) async {
      await tester.pumpWidget(_buildApp(current: StopColor.teal));
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Limpar'));
      await tester.pumpAndSettle();

      expect(find.text('Cor'), findsNothing);
      expect(find.text('cleared'), findsOneWidget);
    });
  });

  // ── 7. Dismiss (tap fora / barrier) → retorna null ───────────────────────

  group('Dismiss', () {
    testWidgets('tap na barrier (fora da sheet) resolve null', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      // Tap no canto superior esquerdo — fora da sheet.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('dismissed'), findsOneWidget);
    });
  });

  // ── 8. stopColorToken — 5 valores distintos ───────────────────────────────

  group('stopColorToken', () {
    test('cobre os 5 valores de StopColor e retorna 5 Colors DISTINTAS', () {
      final colors = StopColor.values.map(stopColorToken).toList();

      // Total de valores = 5.
      expect(colors.length, 5);

      // Todos distintos (sem duplicatas).
      final distinct = colors.toSet();
      expect(
        distinct.length,
        5,
        reason: 'stopColorToken deve retornar cores distintas para cada enum',
      );
    });
  });
}
