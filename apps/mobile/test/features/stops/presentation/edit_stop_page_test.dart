import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/features/stops/data/repositories/stops_repository.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/presentation/edit_stop_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

class _Repo implements StopsRepository {
  _Repo(this.initial);
  final List<Stop> initial;
  final List<Stop> saved = [];
  @override
  Future<List<Stop>> load() async => List.unmodifiable(initial);
  @override
  Future<void> save(List<Stop> stops) async {
    saved
      ..clear()
      ..addAll(stops);
  }
}

void main() {
  testWidgets('EditStopPage pre-populates and updates via controller',
      (tester) async {
    final stop = Stop(
      id: 'abc',
      lat: 1,
      lng: 2,
      label: 'Old',
      source: StopSource.manual,
      createdAt: DateTime.utc(2026, 5, 13),
    );
    final repo = _Repo([stop]);
    var savedFired = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [stopsRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: EditStopPage(id: 'abc', onSaved: (_) => savedFired++),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Old'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('input-address')), 'New');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar alterações'));
    await tester.pumpAndSettle();

    expect(repo.saved, hasLength(1));
    expect(repo.saved.first.label, 'New');
    expect(repo.saved.first.id, 'abc');
    expect(repo.saved.first.lat, 1);
    expect(repo.saved.first.lng, 2);
    expect(repo.saved.first.source, StopSource.manual);
    expect(savedFired, 1);
  });

  testWidgets('EditStopPage shows friendly message when id missing',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [stopsRepositoryProvider.overrideWithValue(_Repo([]))],
        child: const MaterialApp(home: EditStopPage(id: 'missing')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Parada não encontrada.'), findsOneWidget);
  });
}
