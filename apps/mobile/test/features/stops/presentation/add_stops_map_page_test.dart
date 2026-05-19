import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/features/stops/presentation/add_stops_map_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

import '../_helpers/fake_stops_repository.dart';

void main() {
  testWidgets('AddStopsMapPage renders AppBar title and prompt copy',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stopsRepositoryProvider.overrideWithValue(FakeStopsRepository()),
        ],
        child: const MaterialApp(home: AddStopsMapPage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Toque no mapa para adicionar paradas'), findsOneWidget);
  });

  testWidgets('AddStopsMapPage hides confirm FAB when no pins are pending',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stopsRepositoryProvider.overrideWithValue(FakeStopsRepository()),
        ],
        child: const MaterialApp(home: AddStopsMapPage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(const Key('add-stops-map-confirm')), findsNothing);
  });
}
