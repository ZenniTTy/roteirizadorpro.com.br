import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/presentation/add_stop_page.dart';
import 'package:roteirizador_pro/features/stops/presentation/add_stop_sheet.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

import '../_helpers/fake_stops_repository.dart';

void main() {
  testWidgets(
      'AddStopPage mounts AddStopSheet via showModalBottomSheet after first frame',
      (tester) async {
    final repo = FakeStopsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [stopsRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          home: AddStopPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AddStopSheet), findsOneWidget);
  });

  testWidgets(
      'AddStopPage submits a valid stop via the sheet and invokes onSaved',
      (tester) async {
    final repo = FakeStopsRepository();
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

    // Sheet is now open — find the TextField by its hint text inside AddStopSheet.
    final textFieldFinder = find.byWidgetPredicate(
      (w) =>
          w is TextField &&
          (w.decoration?.hintText ?? '') == 'Digite o endereço ou CEP...',
    );
    expect(textFieldFinder, findsOneWidget);

    await tester.enterText(textFieldFinder, 'Rua Haddock Lobo, 1500');
    await tester.tap(find.widgetWithText(FilledButton, 'Adicionar parada'));
    await tester.pumpAndSettle();

    expect(repo.saved.length, 1);
    expect(repo.saved.first.label, 'Rua Haddock Lobo, 1500');
    expect(repo.saved.first.lat, 0);
    expect(repo.saved.first.lng, 0);
    expect(repo.saved.first.source, StopSource.manual);
    expect(navigatedHome, 1);
  });

  testWidgets(
      'AddStopPage onSaved fires when the sheet is dismissed without saving',
      (tester) async {
    final repo = FakeStopsRepository();
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

    // Sheet is open. Dismiss via barrier tap (top-left corner is outside the sheet).
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // No stop was submitted.
    expect(repo.saved, isEmpty);
    // AddStopPage wrapper fires onSaved unconditionally when the sheet resolves.
    expect(navigatedHome, 1);
  });
}
