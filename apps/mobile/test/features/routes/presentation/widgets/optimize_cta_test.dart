// test/features/routes/presentation/widgets/optimize_cta_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/optimize_cta.dart';

void main() {
  testWidgets('habilitado dispara onPressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OptimizeCta(enabled: true, onPressed: () => tapped = true),
        ),
      ),
    );
    expect(find.text('Otimizar rota'), findsOneWidget);
    await tester.tap(find.text('Otimizar rota'));
    expect(tapped, isTrue);
  });

  testWidgets('desabilitado (abaixo do mínimo) não dispara', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OptimizeCta(enabled: false, onPressed: () => tapped = true),
        ),
      ),
    );
    await tester.tap(find.text('Otimizar rota'));
    expect(tapped, isFalse);
  });

  testWidgets('tem Semantics de botão com o label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: OptimizeCta(enabled: true, onPressed: () {})),
      ),
    );
    expect(
      tester.getSemantics(find.text('Otimizar rota')),
      matchesSemantics(
        label: 'Otimizar rota',
        isButton: true,
        isEnabled: true,
        hasEnabledState: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
      ),
    );
  });
}
