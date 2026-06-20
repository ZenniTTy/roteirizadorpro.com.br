// Tests for ReadyToRunView — Á7 PR-C (Fase R/P0, A7-D5/A7-D8).
//
// Contrato:
//   - Sem pendência: mostra o resumo (RouteSummaryRow) + 2 botões-linha
//     ("Compartilhar rota em tempo real" / "Carregar veículo") + "Editar" /
//     "Iniciar rota".
//   - Com pendência (skip-path): mostra o banner "Otimização pendente" no lugar
//     do resumo.
//   - Callbacks: Editar→onEdit, Iniciar rota→onStart, botões-linha→onComingSoon,
//     banner→onReoptimize.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/ready_to_run_view.dart';

Stop _stop(String id) => Stop(
      id: id,
      lat: -23.5,
      lng: -46.6,
      streetName: 'Rua $id',
      fullAddress: 'Rua $id, 1 — SP',
    );

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required bool pending,
    VoidCallback? onEdit,
    VoidCallback? onStart,
    VoidCallback? onComingSoon,
    VoidCallback? onReoptimize,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReadyToRunView(
            stops: [_stop('A'), _stop('B')],
            durationMinutes: 25,
            distanceMeters: 4200,
            hasPendingOptimization: pending,
            onEdit: onEdit ?? () {},
            onStart: onStart ?? () {},
            onComingSoon: onComingSoon ?? () {},
            onReoptimize: onReoptimize ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('sem pendência: resumo + 2 botões-linha + Editar/Iniciar rota',
      (tester) async {
    await pump(tester, pending: false);

    expect(find.textContaining('25 min'), findsOneWidget); // RouteSummaryRow
    expect(find.text('Otimização pendente'), findsNothing);
    expect(find.text('Compartilhar rota em tempo real'), findsOneWidget);
    expect(find.text('Carregar veículo'), findsOneWidget);
    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Iniciar rota'), findsOneWidget);
  });

  testWidgets('com pendência: banner "Otimização pendente" no lugar do resumo',
      (tester) async {
    await pump(tester, pending: true);

    expect(find.text('Otimização pendente'), findsOneWidget);
    expect(find.textContaining('25 min'), findsNothing);
    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Iniciar rota'), findsOneWidget);
  });

  testWidgets('tap "Editar" → onEdit; tap "Iniciar rota" → onStart',
      (tester) async {
    var edited = 0;
    var started = 0;
    await pump(
      tester,
      pending: false,
      onEdit: () => edited++,
      onStart: () => started++,
    );

    await tester.tap(find.text('Editar'));
    await tester.tap(find.text('Iniciar rota'));
    await tester.pump();

    expect(edited, 1);
    expect(started, 1);
  });

  testWidgets('tap nos botões-linha → onComingSoon', (tester) async {
    var comingSoon = 0;
    await pump(tester, pending: false, onComingSoon: () => comingSoon++);

    await tester.tap(find.text('Compartilhar rota em tempo real'));
    await tester.tap(find.text('Carregar veículo'));
    await tester.pump();

    expect(comingSoon, 2);
  });

  testWidgets('tap no banner pendente → onReoptimize', (tester) async {
    var reopt = 0;
    await pump(tester, pending: true, onReoptimize: () => reopt++);

    await tester.tap(find.text('Otimização pendente'));
    await tester.pump();

    expect(reopt, 1);
  });
}
