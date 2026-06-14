// test/features/routes/presentation/widgets/optimizing_progress_view_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/optimizing_progress_view.dart';
import 'package:roteirizador_pro/features/routes/state/optimization_controller.dart';

void main() {
  testWidgets('mostra o texto da fase corrente', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: OptimizingProgressView(phase: OptimizationPhase.sorting),
      ),
    ),);
    expect(find.text('Encontrando a melhor ordem...'), findsOneWidget);
  });

  testWidgets('cada fase tem seu texto', (tester) async {
    for (final entry in {
      OptimizationPhase.analysing: 'Analisando suas paradas...',
      OptimizationPhase.sorting: 'Encontrando a melhor ordem...',
      OptimizationPhase.traffic: 'Considerando o trânsito...',
      OptimizationPhase.creating: 'Criando sua rota...',
    }.entries) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: OptimizingProgressView(phase: entry.key)),
      ),);
      expect(find.text(entry.value), findsOneWidget);
    }
  });
}
