import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/presentation/edit_stop_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

import '../_helpers/fake_stops_repository.dart';

Stop _stop({String label = 'R. Joaquim Floriano, 834'}) => Stop(
      id: 'abc',
      lat: 1,
      lng: 2,
      label: label,
      source: StopSource.manual,
      createdAt: DateTime.utc(2026, 5, 13),
    );

Future<void> _pump(
  WidgetTester tester, {
  required Stop stop,
  FakeStopsRepository? repo,
  void Function(BuildContext)? onSaved,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        stopsRepositoryProvider
            .overrideWithValue(repo ?? FakeStopsRepository([stop])),
      ],
      child: MaterialApp(
        home: EditStopPage(
          id: stop.id,
          onSaved: onSaved ?? (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Sheet header renders title + Concluído button', (tester) async {
    await _pump(tester, stop: _stop());
    expect(find.text('Editar parada'), findsOneWidget);
    expect(find.text('Concluído'), findsOneWidget);
  });

  testWidgets('Color tag pill renders "Laranja" with dot', (tester) async {
    await _pump(tester, stop: _stop());
    expect(find.text('Laranja'), findsOneWidget);
  });

  testWidgets('Address title shows the stop label', (tester) async {
    await _pump(tester, stop: _stop(label: 'R. Oscar Freire, 875'));
    expect(find.text('R. Oscar Freire, 875'), findsOneWidget);
  });

  testWidgets('Gate-code chip renders the code line', (tester) async {
    await _pump(tester, stop: _stop());
    expect(find.text('O código do portão é 1684'), findsOneWidget);
  });

  testWidgets('Six option rows are present', (tester) async {
    await _pump(tester, stop: _stop());
    expect(find.text('Localizador'), findsOneWidget);
    expect(find.text('Pacotes'), findsOneWidget);
    expect(find.text('Ordem'), findsOneWidget);
    expect(find.text('Tipo'), findsOneWidget);
    expect(find.text('Horário de chegada'), findsOneWidget);
    expect(find.text('Tempo na parada'), findsOneWidget);
  });

  testWidgets('Footer renders Mudar endereço and Duplicar parada',
      (tester) async {
    await _pump(tester, stop: _stop());
    expect(find.text('Mudar endereço'), findsOneWidget);
    expect(find.text('Duplicar parada'), findsOneWidget);
  });

  testWidgets('Concluído fires onSaved', (tester) async {
    var saves = 0;
    await _pump(
      tester,
      stop: _stop(),
      onSaved: (_) => saves++,
    );

    await tester.tap(find.text('Concluído'));
    await tester.pumpAndSettle();
    expect(saves, 1);
  });

  testWidgets('Mudar endereço opens dialog and persists new label',
      (tester) async {
    final repo = FakeStopsRepository([_stop(label: 'Old')]);
    await _pump(tester, stop: _stop(label: 'Old'), repo: repo);

    await tester.ensureVisible(find.text('Mudar endereço'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mudar endereço'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('input-address')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('input-address')), 'New');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(repo.saved, hasLength(1));
    expect(repo.saved.first.label, 'New');
    expect(repo.saved.first.id, 'abc');
    expect(repo.saved.first.lat, 1);
    expect(repo.saved.first.lng, 2);
  });

  testWidgets('Mudar endereço dialog Cancelar does not persist',
      (tester) async {
    final repo = FakeStopsRepository([_stop(label: 'Old')]);
    await _pump(tester, stop: _stop(label: 'Old'), repo: repo);

    await tester.ensureVisible(find.text('Mudar endereço'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mudar endereço'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('input-address')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('input-address')), 'New');
    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();

    expect(repo.saved, isEmpty);
  });

  testWidgets('Friendly message when stop id is missing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stopsRepositoryProvider.overrideWithValue(FakeStopsRepository([])),
        ],
        child: const MaterialApp(home: EditStopPage(id: 'missing')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Parada não encontrada.'), findsOneWidget);
  });
}
