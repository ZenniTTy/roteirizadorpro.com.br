import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/presentation/stop_detail_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

import '../_helpers/fake_stops_repository.dart';

Stop _geocoded() => Stop(
      id: 'abc',
      lat: -23.55,
      lng: -46.63,
      label: 'R. Oscar Freire, 875',
      source: StopSource.mapTap,
      createdAt: DateTime.utc(2026, 5, 13),
    );

Stop _ungeocoded() => Stop(
      id: 'abc',
      lat: 0,
      lng: 0,
      label: 'R. Oscar Freire, 875',
      source: StopSource.manual,
      createdAt: DateTime.utc(2026, 5, 13),
    );

Future<void> _pump(
  WidgetTester tester,
  Stop stop, {
  FakeStopsRepository? repo,
  void Function(BuildContext)? onDeleted,
  void Function(BuildContext)? onEditPressed,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        stopsRepositoryProvider
            .overrideWithValue(repo ?? FakeStopsRepository([stop])),
      ],
      child: MaterialApp(
        home: StopDetailPage(
          id: stop.id,
          onDeleted: onDeleted ?? (_) {},
          onEditPressed: onEditPressed ?? (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('AppBar shows "Parada N de M" title', (tester) async {
    await _pump(tester, _geocoded());
    expect(find.text('Parada 1 de 1'), findsOneWidget);
  });

  testWidgets('AppBar edit icon fires onEditPressed', (tester) async {
    var edits = 0;
    await _pump(tester, _geocoded(), onEditPressed: (_) => edits++);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    expect(edits, 1);
  });

  testWidgets(
      'AppBar overflow menu Excluir removes the stop and fires onDeleted',
      (tester) async {
    final repo = FakeStopsRepository([_geocoded()]);
    var deletes = 0;
    await _pump(
      tester,
      _geocoded(),
      repo: repo,
      onDeleted: (_) => deletes++,
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir parada'));
    await tester.pumpAndSettle();

    expect(repo.saved, isEmpty);
    expect(deletes, 1);
  });

  testWidgets('Address card renders the label and the "Entrega" badge',
      (tester) async {
    await _pump(tester, _geocoded());
    expect(find.text('R. Oscar Freire, 875'), findsOneWidget);
    expect(find.text('Entrega'), findsOneWidget);
  });

  testWidgets('Address card renders the three stat blocks', (tester) async {
    await _pump(tester, _geocoded());
    expect(find.text('DISTÂNCIA'), findsOneWidget);
    expect(find.text('TEMPO'), findsOneWidget);
    expect(find.text('CONTATO'), findsOneWidget);
  });

  testWidgets('Action row renders Entregue, Falhou, Próxima', (tester) async {
    await _pump(tester, _geocoded());
    expect(find.text('Entregue'), findsOneWidget);
    expect(find.text('Falhou'), findsOneWidget);
    expect(find.text('Próxima'), findsOneWidget);
  });

  testWidgets(
      'Locked nav section renders Iniciar navegação + Assine para navegar link',
      (tester) async {
    await _pump(tester, _geocoded());
    expect(find.text('Iniciar navegação'), findsOneWidget);
    expect(find.text('Assine para navegar →'), findsOneWidget);
  });

  testWidgets('Move-options card renders the three reorder rows',
      (tester) async {
    await _pump(tester, _geocoded());
    expect(find.text('Tornar próxima'), findsOneWidget);
    expect(find.text('Mover para o início'), findsOneWidget);
    expect(find.text('Mover para o final'), findsOneWidget);
  });

  testWidgets(
      'Ungeocoded stop shows the "Localização ainda não disponível" hint',
      (tester) async {
    await _pump(tester, _ungeocoded());
    expect(
      find.text('Localização ainda não disponível'),
      findsOneWidget,
    );
  });

  testWidgets('Stop not found shows the friendly message', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stopsRepositoryProvider.overrideWithValue(FakeStopsRepository([])),
        ],
        child: const MaterialApp(home: StopDetailPage(id: 'missing')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Parada não encontrada.'), findsOneWidget);
  });
}
