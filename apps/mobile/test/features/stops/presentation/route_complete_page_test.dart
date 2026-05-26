import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/presentation/route_complete_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

import '../_helpers/fake_stops_repository.dart';

Stop _s(String id) => Stop(
      id: id,
      lat: 0,
      lng: 0,
      label: 'L-$id',
      source: StopSource.manual,
      createdAt: DateTime.utc(2026, 5, 19),
    );

void main() {
  testWidgets('RouteCompletePage shows the celebration card with stop count',
      (tester) async {
    final stops = List.generate(5, (i) => _s('$i'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stopsRepositoryProvider.overrideWithValue(FakeStopsRepository(stops)),
        ],
        child: const MaterialApp(home: RouteCompletePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rota concluída!'), findsOneWidget);
    expect(find.textContaining('5'), findsWidgets);
    expect(find.text('Nova rota'), findsOneWidget);
    expect(find.text('Compartilhar'), findsOneWidget);
  });

  testWidgets('Nova rota clears the controller and fires onNewRoute callback',
      (tester) async {
    var newRouteFired = 0;
    final repo = FakeStopsRepository([_s('a'), _s('b')]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stopsRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          home: RouteCompletePage(onNewRoute: (_) => newRouteFired++),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nova rota'));
    await tester.pumpAndSettle();

    expect(repo.saved, isEmpty);
    expect(newRouteFired, 1);
  });

  testWidgets('Compartilhar fires onShare callback', (tester) async {
    var shareFired = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stopsRepositoryProvider.overrideWithValue(
            FakeStopsRepository([_s('a')]),
          ),
        ],
        child: MaterialApp(
          home: RouteCompletePage(onShare: (_) => shareFired++),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Compartilhar'));
    await tester.pump();

    expect(shareFired, 1);
  });
}
