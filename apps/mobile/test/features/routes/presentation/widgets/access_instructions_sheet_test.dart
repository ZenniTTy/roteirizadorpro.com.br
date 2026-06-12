// Tests for AccessInstructionsSheet — MS-A6 T12.
//
// Spec: docs/superpowers/specs/2026-06-11-area6-edit-stop-design.md
// Contrato: F13, §13.C.3, H13, H18, H19.
//
// Setup: host StatefulWidget dentro de MaterialApp.router (GoRouter) para
// satisfazer useRootNavigator: true (H13). O host chama
// AccessInstructionsSheet.show() e exibe o resultado capturado via Text.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/access_instructions_sheet.dart';

// ---------------------------------------------------------------------------
// Host widget
// ---------------------------------------------------------------------------

/// Abre a sheet ao montar (via addPostFrameCallback) e exibe o resultado.
class _SheetHost extends StatefulWidget {
  const _SheetHost({this.initialText});
  final String? initialText;

  @override
  State<_SheetHost> createState() => _SheetHostState();
}

class _SheetHostState extends State<_SheetHost> {
  AccessInstructionsResult? _result;
  bool _opened = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            key: const Key('open_sheet'),
            onPressed: () async {
              final result = await AccessInstructionsSheet.show(
                context,
                initialText: widget.initialText,
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
            if (_result is AccessInstructionsSaved) ...[
              Text(
                'saved:${(_result as AccessInstructionsSaved).text}',
                key: const Key('result_text'),
              ),
              Text(
                'saveAsDefault:${(_result as AccessInstructionsSaved).saveAsDefault}',
                key: const Key('result_save_default'),
              ),
            ],
            if (_result is AccessInstructionsCleared)
              Text(
                'cleared:clearDefault=${(_result as AccessInstructionsCleared).clearDefault}',
                key: const Key('result_cleared'),
              ),
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

Widget _buildApp({String? initialText}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => _SheetHost(initialText: initialText),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

// ---------------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------------

void main() {
  // ── 1. Header ──────────────────────────────────────────────────────────────

  group('1 — Header', () {
    testWidgets(
        'sheet abre com header: TextButton "Limpar" à esquerda, '
        'título "Instruções de acesso" ao centro, TextButton "Salvar" à direita',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      expect(find.text('Limpar'), findsOneWidget);
      expect(find.text('Instruções de acesso'), findsAtLeastNWidgets(1));
      expect(find.text('Salvar'), findsOneWidget);
    });
  });

  // ── 2. TextField autofocado e pré-preenchido ───────────────────────────────

  group('2 — TextField autofocado e pré-preenchido', () {
    testWidgets(
        'TextField está presente e tem foco após pumpAndSettle (autofocus: true)',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      // Deve existir pelo menos um TextField dentro da sheet.
      expect(find.byType(TextField), findsAtLeastNWidgets(1));

      // O primeiro TextField deve estar focado após settle.
      final textField = tester.widget<TextField>(find.byType(TextField).first);
      expect(
        textField.focusNode?.hasFocus ?? textField.autofocus,
        isTrue,
        reason:
            'O TextField da sheet deve ter autofocus: true ou foco primário após abrir',
      );
    });

    testWidgets('TextField pré-preenchido com initialText quando fornecido',
        (tester) async {
      await tester.pumpWidget(_buildApp(initialText: 'portão azul'));
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      expect(find.text('portão azul'), findsAtLeastNWidgets(1));
    });

    testWidgets('TextField vazio quando initialText é null', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField).first);
      final text = textField.controller?.text ?? '';
      expect(text, isEmpty);
    });
  });

  // ── 3. Switch presente com label canônico ────────────────────────────────

  group('3 — Switch "Salvar como padrão para este endereço"', () {
    testWidgets(
        'Switch presente com label "Salvar como padrão para este endereço", '
        'padrão OFF', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      // Label do switch deve ser visível.
      expect(
        find.text('Salvar como padrão para este endereço'),
        findsOneWidget,
      );

      // Switch deve estar presente.
      expect(find.byType(Switch), findsOneWidget);

      // Default = OFF.
      final sw = tester.widget<Switch>(find.byType(Switch));
      expect(sw.value, isFalse, reason: 'Switch deve começar OFF por padrão');
    });
  });

  // ── 4. "Salvar" com switch OFF → AccessInstructionsSaved(saveAsDefault: false) ──

  group('4 — "Salvar" com switch OFF', () {
    testWidgets(
        '"Salvar" com texto digitado e switch OFF → resolve '
        'AccessInstructionsSaved(texto, saveAsDefault: false)', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'tocar campainha');
      await tester.pump();

      // Switch ainda OFF — não tocar.
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      // Sheet fechou, resultado exibido.
      expect(find.text('Instruções de acesso'), findsNothing);
      expect(find.byKey(const Key('result_text')), findsOneWidget);
      expect(
        (tester.widget<Text>(find.byKey(const Key('result_text')))).data,
        'saved:tocar campainha',
      );
      expect(
        (tester.widget<Text>(
          find.byKey(const Key('result_save_default')),
        )).data,
        'saveAsDefault:false',
      );
    });
  });

  // ── 5. "Salvar" com switch ON → saveAsDefault: true ──────────────────────

  group('5 — "Salvar" com switch ON', () {
    testWidgets(
        '"Salvar" com switch ON → resolve '
        'AccessInstructionsSaved(texto, saveAsDefault: true)', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).first,
        'entrar pelo fundos',
      );
      await tester.pump();

      // Liga o switch.
      await tester.tap(find.byType(Switch));
      await tester.pump();

      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(
        (tester.widget<Text>(
          find.byKey(const Key('result_save_default')),
        )).data,
        'saveAsDefault:true',
      );
      expect(
        (tester.widget<Text>(find.byKey(const Key('result_text')))).data,
        'saved:entrar pelo fundos',
      );
    });
  });

  // ── 6. "Limpar" → AccessInstructionsCleared ──────────────────────────────

  group('6 — "Limpar"', () {
    testWidgets(
        '"Limpar" com switch OFF → resolve '
        'AccessInstructionsCleared(clearDefault: false)', (tester) async {
      await tester.pumpWidget(_buildApp(initialText: 'código 1234'));
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      // Switch OFF (default) — não tocar.
      await tester.tap(find.text('Limpar'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('result_cleared')), findsOneWidget);
      expect(
        (tester.widget<Text>(find.byKey(const Key('result_cleared')))).data,
        'cleared:clearDefault=false',
      );
    });

    testWidgets(
        '"Limpar" com switch ON → resolve '
        'AccessInstructionsCleared(clearDefault: true)', (tester) async {
      await tester.pumpWidget(_buildApp(initialText: 'campainha 2x'));
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      // Liga o switch.
      await tester.tap(find.byType(Switch));
      await tester.pump();

      await tester.tap(find.text('Limpar'));
      await tester.pumpAndSettle();

      expect(
        (tester.widget<Text>(find.byKey(const Key('result_cleared')))).data,
        'cleared:clearDefault=true',
      );
    });
  });

  // ── 7. Dismiss (barrier) → null ──────────────────────────────────────────

  group('7 — Dismiss', () {
    testWidgets('tap na barrier (fora da sheet) → show() resolve null',
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
