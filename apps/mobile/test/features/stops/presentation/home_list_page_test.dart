import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/core/widgets/home_top_bar.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/presentation/home_list_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

import '../_helpers/fake_stops_repository.dart';

Stop _s(String id) => Stop(
      id: id,
      lat: 0,
      lng: 0,
      label: 'L-$id',
      source: StopSource.manual,
      createdAt: DateTime.utc(2026, 5, 13),
    );

void main() {
  testWidgets('HomeListPage renders one tile per stop', (tester) async {
    final repo = FakeStopsRepository([_s('a'), _s('b'), _s('c')]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [stopsRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: HomeListPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('L-a'), findsOneWidget);
    expect(find.text('L-b'), findsOneWidget);
    expect(find.text('L-c'), findsOneWidget);
  });

  testWidgets('Swipe-to-delete removes a stop and calls save', (tester) async {
    final repo = FakeStopsRepository([_s('a'), _s('b')]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [stopsRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: HomeListPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.text('L-a'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('L-a'), findsNothing);
    expect(repo.saved.map((s) => s.id), ['b']);
  });

  testWidgets('HomeListPage renders HomeTopBar', (tester) async {
    final repo = FakeStopsRepository([_s('a')]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [stopsRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: HomeListPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeTopBar), findsOneWidget);
  });

  testWidgets('More menu -> Limpar rota -> confirm clears all stops',
      (tester) async {
    final repo = FakeStopsRepository([_s('a'), _s('b')]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [stopsRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: HomeListPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Mais opções'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Limpar rota'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Limpar'));
    await tester.pumpAndSettle();

    expect(find.text('L-a'), findsNothing);
    expect(find.text('L-b'), findsNothing);
    expect(repo.saved, isEmpty);
  });

  testWidgets('More menu -> Limpar rota -> Cancelar keeps stops',
      (tester) async {
    final repo = FakeStopsRepository([_s('a'), _s('b')]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [stopsRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: HomeListPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Mais opções'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Limpar rota'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('L-a'), findsOneWidget);
    expect(find.text('L-b'), findsOneWidget);
  });
}
