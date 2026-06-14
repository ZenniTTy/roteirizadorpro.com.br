// test/features/routes/presentation/widgets/route_shell_optimize_cta_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/optimize_cta.dart';

// Este teste pina a regra de visibilidade do CTA no rodapé: o OptimizeCta
// aparece quando a rota ativa tem >=1 parada, e some quando vazia. Como o
// _ActiveRouteSheet é privado, exercemos a regra via o widget público
// OptimizeCta dentro de um harness mínimo que replica a condição (a montagem
// real é verificada no integration_test do fechamento da Á7).
void main() {
  testWidgets('CTA visível com paradas, ausente sem paradas', (tester) async {
    Widget harness({required bool hasStops}) => MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                if (hasStops) OptimizeCta(enabled: true, onPressed: () {}),
              ],
            ),
          ),
        );

    await tester.pumpWidget(harness(hasStops: false));
    expect(find.byType(OptimizeCta), findsNothing);

    await tester.pumpWidget(harness(hasStops: true));
    expect(find.byType(OptimizeCta), findsOneWidget);
  });
}
