import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/presentation/stop_detail_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

import '../_helpers/fake_stops_repository.dart';

void main() {
  testWidgets(
    'StopDetailPage shows the stop label, lat, and lng for a geocoded stop',
    (tester) async {
      final stop = Stop(
        id: 'abc',
        lat: -23.55,
        lng: -46.63,
        label: 'Av. Paulista',
        source: StopSource.mapTap,
        createdAt: DateTime.utc(2026, 5, 13),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            stopsRepositoryProvider
                .overrideWithValue(FakeStopsRepository([stop])),
          ],
          child: MaterialApp(
            home: StopDetailPage(
              id: 'abc',
              onDeleted: (_) {},
              onEditPressed: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Av. Paulista'), findsOneWidget);
      expect(find.textContaining('-23.55'), findsOneWidget);
      expect(find.textContaining('-46.63'), findsOneWidget);
      expect(find.text('Excluir'), findsOneWidget);
      expect(find.text('Editar'), findsOneWidget);
    },
  );

  testWidgets('Excluir removes the stop and fires onDeleted callback',
      (tester) async {
    final stop = Stop(
      id: 'abc',
      lat: 1,
      lng: 2,
      source: StopSource.manual,
      createdAt: DateTime.utc(2026, 5, 13),
    );
    final repo = FakeStopsRepository([stop]);
    var deletedFired = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [stopsRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: StopDetailPage(
            id: 'abc',
            onDeleted: (_) => deletedFired++,
            onEditPressed: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(repo.saved, isEmpty);
    expect(deletedFired, 1);
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

  testWidgets('Ungeocoded stop (lat=0,lng=0) hides coords and shows hint',
      (tester) async {
    final stop = Stop(
      id: 'abc',
      lat: 0,
      lng: 0,
      label: 'Av. Paulista',
      source: StopSource.manual,
      createdAt: DateTime.utc(2026, 5, 13),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stopsRepositoryProvider
              .overrideWithValue(FakeStopsRepository([stop])),
        ],
        child: MaterialApp(
          home: StopDetailPage(
            id: 'abc',
            onDeleted: (_) {},
            onEditPressed: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Av. Paulista'), findsOneWidget);
    expect(find.textContaining('Latitude'), findsNothing);
    expect(find.textContaining('Longitude'), findsNothing);
    expect(find.text('Aguardando geocodificação'), findsOneWidget);
  });
}
