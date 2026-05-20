import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/core/services/external_nav.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/presentation/navigate_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

import '../_helpers/fake_stops_repository.dart';
import '../../../core/_helpers/fake_external_nav.dart';

Stop _s(String id, {double lat = -23.55, double lng = -46.63}) => Stop(
      id: id,
      lat: lat,
      lng: lng,
      label: 'L-$id',
      source: StopSource.manual,
      createdAt: DateTime.utc(2026, 5, 19),
    );

void main() {
  testWidgets('NavigatePage renders one CheckboxListTile per stop',
      (tester) async {
    final stops = [_s('a'), _s('b'), _s('c')];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stopsRepositoryProvider.overrideWithValue(FakeStopsRepository(stops)),
          externalNavProvider.overrideWithValue(FakeExternalNav()),
        ],
        child: const MaterialApp(home: NavigatePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CheckboxListTile), findsNWidgets(3));
    expect(find.text('L-a'), findsOneWidget);
    expect(find.text('L-b'), findsOneWidget);
    expect(find.text('L-c'), findsOneWidget);
  });

  testWidgets('Próxima parada opens Waze for the next undone stop',
      (tester) async {
    final fakeNav = FakeExternalNav();
    final stops = [
      _s('a', lat: -23.55, lng: -46.63),
      _s('b', lat: -23.56, lng: -46.64),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stopsRepositoryProvider.overrideWithValue(FakeStopsRepository(stops)),
          externalNavProvider.overrideWithValue(fakeNav),
        ],
        child: const MaterialApp(home: NavigatePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Próxima parada'));
    await tester.pump();

    expect(fakeNav.wazeCalls, hasLength(1));
    expect(fakeNav.wazeCalls.first.id, 'a');
  });

  testWidgets('Marking a stop done advances Próxima parada to the next one',
      (tester) async {
    final fakeNav = FakeExternalNav();
    final stops = [_s('a'), _s('b'), _s('c')];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stopsRepositoryProvider.overrideWithValue(FakeStopsRepository(stops)),
          externalNavProvider.overrideWithValue(fakeNav),
        ],
        child: const MaterialApp(home: NavigatePage()),
      ),
    );
    await tester.pumpAndSettle();

    // Tick stop 'a' done.
    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Próxima parada'));
    await tester.pump();

    expect(fakeNav.wazeCalls.first.id, 'b');
  });

  testWidgets(
      'Concluir rota appears only when all stops are done and fires callback',
      (tester) async {
    var doneFired = 0;
    final stops = [_s('a'), _s('b')];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stopsRepositoryProvider.overrideWithValue(FakeStopsRepository(stops)),
          externalNavProvider.overrideWithValue(FakeExternalNav()),
        ],
        child: MaterialApp(
          home: NavigatePage(onRouteCompleted: (_) => doneFired++),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Concluir rota'), findsNothing);

    // Tick both stops.
    await tester.tap(find.byType(CheckboxListTile).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile).at(1));
    await tester.pumpAndSettle();

    expect(find.text('Concluir rota'), findsOneWidget);
    await tester.tap(find.text('Concluir rota'));
    await tester.pump();

    expect(doneFired, 1);
  });
}
