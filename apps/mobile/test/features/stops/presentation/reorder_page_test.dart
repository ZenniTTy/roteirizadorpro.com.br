import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/presentation/reorder_page.dart';
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
  testWidgets('ReorderPage renders one row + drag handle per stop',
      (tester) async {
    final repo = FakeStopsRepository([_s('a'), _s('b'), _s('c')]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [stopsRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: ReorderPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('L-a'), findsOneWidget);
    expect(find.text('L-b'), findsOneWidget);
    expect(find.text('L-c'), findsOneWidget);
    expect(find.byIcon(Icons.drag_handle), findsNWidgets(3));
  });

  testWidgets('onReorder routes to the controller and persists',
      (tester) async {
    final repo = FakeStopsRepository([_s('a'), _s('b'), _s('c')]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [stopsRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: ReorderPage()),
      ),
    );
    await tester.pumpAndSettle();

    // Invoke the list's onReorder directly — gesture-driven drag through a
    // ReorderableDragStartListener is unreliable in widget tests. The
    // controller's reorder math is exercised by stops_controller_test.dart;
    // here we only assert the page wires the callback to the controller.
    final list = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    list.onReorder(0, 2);
    await tester.pumpAndSettle();

    expect(repo.saved.map((s) => s.id), ['b', 'a', 'c']);
  });
}
