// Tests for ReadyToRunView (body) + ReadyToRunFooter — Á7 PR-C / Á8 fidelity.
//
// Pós-ADR-0052: a ReadyToRunView deixou de ter moldura própria. Agora é só o
// BODY da lista otimizada (mesma do PRE-CONFIRM, Branch B plana) com o header =
// summary à esquerda OU o banner "Otimização pendente" (skip-path), seguido das
// linhas "Compartilhar rota em tempo real" / "Carregar veículo". O rodapé
// ("Editar" / "Iniciar rota") é o ReadyToRunFooter. A moldura (alça + busca +
// drag) vive no shell.
//
// Contrato:
//   - Sem pendência: header summary à esquerda + 2 botões-linha.
//   - Com pendência (skip-path): banner "Otimização pendente" no lugar do header.
//   - Callbacks: botões-linha→onComingSoon, banner→onReoptimize;
//     no footer: Editar→onEdit, Iniciar rota→onStart.

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
  Future<void> pumpBody(
    WidgetTester tester, {
    required bool pending,
    VoidCallback? onComingSoon,
    VoidCallback? onReoptimize,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReadyToRunView(
            stops: [_stop('A'), _stop('B')],
            routeName: 'Rota',
            durationMinutes: 25,
            distanceMeters: 4200,
            hasPendingOptimization: pending,
            onComingSoon: onComingSoon ?? () {},
            onReoptimize: onReoptimize ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('sem pendência: header summary à esquerda + 2 botões-linha',
      (tester) async {
    await pumpBody(tester, pending: false);

    expect(find.textContaining('25 min'), findsOneWidget); // summary header
    expect(find.text('Otimização pendente'), findsNothing);
    expect(find.text('Compartilhar rota em tempo real'), findsOneWidget);
    expect(find.text('Carregar veículo'), findsOneWidget);
  });

  testWidgets('com pendência: banner "Otimização pendente" no lugar do summary',
      (tester) async {
    await pumpBody(tester, pending: true);

    expect(find.text('Otimização pendente'), findsOneWidget);
    expect(find.textContaining('25 min'), findsNothing);
  });

  testWidgets('tap nos botões-linha → onComingSoon', (tester) async {
    var comingSoon = 0;
    await pumpBody(tester, pending: false, onComingSoon: () => comingSoon++);

    await tester.tap(find.text('Compartilhar rota em tempo real'));
    await tester.tap(find.text('Carregar veículo'));
    await tester.pump();

    expect(comingSoon, 2);
  });

  testWidgets('tap no banner pendente → onReoptimize', (tester) async {
    var reopt = 0;
    await pumpBody(tester, pending: true, onReoptimize: () => reopt++);

    await tester.tap(find.text('Otimização pendente'));
    await tester.pump();

    expect(reopt, 1);
  });

  testWidgets(
      'ReadyToRunFooter: Editar/Iniciar rota presentes; callbacks disparam',
      (tester) async {
    var edited = 0;
    var started = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReadyToRunFooter(
            onEdit: () => edited++,
            onStart: () => started++,
          ),
        ),
      ),
    );

    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Iniciar rota'), findsOneWidget);

    await tester.tap(find.text('Editar'));
    await tester.tap(find.text('Iniciar rota'));
    await tester.pump();

    expect(edited, 1);
    expect(started, 1);
  });
}
