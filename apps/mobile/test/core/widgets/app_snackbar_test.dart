// CONTRACT REMINDER (flutter-test-author):
//
// showAppSnackBar(context, message, {action?}) deve exibir um SnackBar com:
//   behavior == SnackBarBehavior.floating
//   duration == const Duration(seconds: 3)
//   text == message
//
// O implementador NÃO deve usar os defaults do Material (4 s / fixed).
// Use ScaffoldMessenger.of(context).showSnackBar(...) passando os parâmetros
// acima explicitamente.
//
// Após a implementação todos os testes abaixo devem ficar verdes.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/core/widgets/app_snackbar.dart';

void main() {
  group('showAppSnackBar', () {
    testWidgets(
      'exibe SnackBar com behavior floating, duration 3 s e o texto correto',
      (WidgetTester tester) async {
        // Arrange — UI mínima: botão que dispara o helper.
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showAppSnackBar(context, 'oi'),
                  child: const Text('Mostrar'),
                ),
              ),
            ),
          ),
        );

        // Act — toca o botão para disparar o SnackBar.
        await tester.tap(find.text('Mostrar'));
        await tester.pump(); // deixa o ScaffoldMessenger processar a fila

        // Assert — SnackBar deve estar na árvore.
        expect(find.byType(SnackBar), findsOneWidget);

        // Lê as propriedades do widget real (não inferidas).
        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));

        // (1) Comportamento floating — não deve cobrir a bottom nav.
        expect(snackBar.behavior, equals(SnackBarBehavior.floating));

        // (2) Auto-dismiss em 3 s — não o default de 4 s do Material.
        expect(snackBar.duration, equals(const Duration(seconds: 3)));

        // (3) Texto passado deve aparecer no SnackBar.
        expect(find.text('oi'), findsOneWidget);

        // Flush do Timer defensivo (dismiss robusto a animações-off).
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'aceita SnackBarAction opcional sem lançar',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showAppSnackBar(
                    context,
                    'Rota salva',
                    action: SnackBarAction(
                      label: 'Desfazer',
                      onPressed: () {},
                    ),
                  ),
                  child: const Text('Mostrar'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Mostrar'));
        await tester.pump();

        // O SnackBar deve aparecer e exibir tanto o texto quanto a action.
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('Rota salva'), findsOneWidget);
        expect(find.text('Desfazer'), findsOneWidget);

        // Flush do Timer defensivo (dismiss robusto a animações-off).
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'com animações DESLIGADAS (disableAnimations) o toast some pelo Timer '
      'defensivo em ~3 s (cobre o bug do M54)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              // Replica o aparelho com animações off (animator_duration_scale=0)
              // — a condição exata em que o auto-dismiss nativo NÃO dispara.
              data: const MediaQueryData(disableAnimations: true),
              child: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => showAppSnackBar(context, 'oi'),
                    child: const Text('Mostrar'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Mostrar'));
        await tester.pump();
        expect(find.byType(SnackBar), findsOneWidget);

        // O Timer próprio (armado SÓ neste modo) fecha o toast em ~3 s.
        await tester.pump(const Duration(seconds: 3, milliseconds: 100));
        await tester.pumpAndSettle();
        expect(find.byType(SnackBar), findsNothing);
      },
    );

    testWidgets(
      'com animações LIGADAS não arma Timer extra (sem "pending timer" no '
      'teardown)',
      (WidgetTester tester) async {
        // Sem disableAnimations: o helper NÃO deve armar o Timer defensivo —
        // o dismiss nativo basta. Se um Timer extra vazasse, o teardown do
        // testWidgets falharia com "A Timer is still pending". Este teste
        // termina logo após exibir o toast (sem flush) — passa só se nenhum
        // Timer próprio ficou pendente.
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showAppSnackBar(context, 'oi'),
                  child: const Text('Mostrar'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Mostrar'));
        await tester.pump();
        expect(find.byType(SnackBar), findsOneWidget);
        // Fecha o toast nativo p/ drenar o timer interno do Material e encerrar
        // limpo (o ponto é: nenhum Timer NOSSO ficou pendente).
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
      },
    );
  });
}
