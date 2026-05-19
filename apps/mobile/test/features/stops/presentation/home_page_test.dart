import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/features/stops/data/repositories/stops_repository.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/presentation/home_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

class _Repo implements StopsRepository {
  _Repo(this._initial);
  final List<Stop> _initial;

  @override
  Future<List<Stop>> load() async => List.unmodifiable(_initial);

  @override
  Future<void> save(List<Stop> stops) async {}
}

Stop _s(String id) => Stop(
      id: id,
      lat: 0,
      lng: 0,
      label: 'L-$id',
      source: StopSource.manual,
      createdAt: DateTime.utc(2026, 5, 13),
    );

void main() {
  testWidgets('HomeListPageOrEmpty shows empty page when no stops',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [stopsRepositoryProvider.overrideWithValue(_Repo(const []))],
        child: const MaterialApp(home: HomeListPageOrEmpty()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma entrega ainda'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Adicionar parada'),
      findsOneWidget,
    );
  });

  testWidgets('HomeListPageOrEmpty shows list page when stops exist',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stopsRepositoryProvider.overrideWithValue(_Repo([_s('a')])),
        ],
        child: const MaterialApp(home: HomeListPageOrEmpty()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('L-a'), findsOneWidget);
    expect(find.text('Nenhuma entrega ainda'), findsNothing);
  });
}
