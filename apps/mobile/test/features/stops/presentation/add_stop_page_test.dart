import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/features/stops/data/repositories/stops_repository.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/presentation/add_stop_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

class _Repo implements StopsRepository {
  final List<Stop> saved = [];

  @override
  Future<List<Stop>> load() async => const [];

  @override
  Future<void> save(List<Stop> stops) async {
    saved
      ..clear()
      ..addAll(stops);
  }
}

void main() {
  testWidgets('AddStopPage submits a valid stop into the controller',
      (tester) async {
    final repo = _Repo();
    var navigatedHome = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [stopsRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: AddStopPage(onSaved: (_) => navigatedHome++),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('input-address')),
      'Rua Haddock Lobo, 1500',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Adicionar parada'));
    await tester.pumpAndSettle();

    expect(repo.saved.length, 1);
    expect(repo.saved.first.label, 'Rua Haddock Lobo, 1500');
    expect(repo.saved.first.source, StopSource.manual);
    expect(repo.saved.first.lat, 0);
    expect(repo.saved.first.lng, 0);
    expect(navigatedHome, 1);
  });

  testWidgets('AddStopPage rejects an empty address', (tester) async {
    final repo = _Repo();
    var navigatedHome = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [stopsRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: AddStopPage(onSaved: (_) => navigatedHome++),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Adicionar parada'));
    await tester.pumpAndSettle();

    expect(find.text('Informe o endereço'), findsOneWidget);
    expect(repo.saved, isEmpty);
    expect(navigatedHome, 0);
  });
}
