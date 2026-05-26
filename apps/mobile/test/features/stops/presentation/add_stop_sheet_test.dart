import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/presentation/add_stop_sheet.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

import '../../../_support/phone_surface.dart';
import '../_helpers/fake_stops_repository.dart';

// ---------------------------------------------------------------------------
// Test host helper. Two pump modes:
//
// `_pumpHostedSheet` — hosts AddStopSheet via showModalBottomSheet (matches
//   production AddStopPage wrapper). The future's AddStopResult is captured
//   so tests can assert the sheet returns the right intent on Voz/Câmera
//   tap and on submit.
//
// `_pumpDirectSheet` — pumps AddStopSheet directly under a Scaffold (for
//   widget-tree assertions that don't need the modal-host behavior).
// ---------------------------------------------------------------------------

Future<AddStopResult?> _capturedResult = Future.value(null);

Future<void> _pumpHostedSheet(
  WidgetTester tester,
  FakeStopsRepository repo, {
  void Function(BuildContext)? onSaved,
}) async {
  await phoneSurface(tester);

  late BuildContext savedCtx;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [stopsRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) {
              savedCtx = ctx;
              return const Center(child: Text('host'));
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  _capturedResult = showModalBottomSheet<AddStopResult>(
    context: savedCtx,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddStopSheet(onSaved: onSaved),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpDirectSheet(
  WidgetTester tester,
  FakeStopsRepository repo, {
  void Function(BuildContext)? onSaved,
}) async {
  await phoneSurface(tester);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [stopsRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        home: Scaffold(
          body: AddStopSheet(onSaved: onSaved),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // Test 1: Sheet renders all required chrome
  // ─────────────────────────────────────────────────────────────────────────
  testWidgets(
    'sheet renders drag handle, title, TextField, 3 method buttons, and CTA',
    (tester) async {
      final repo = FakeStopsRepository();

      await _pumpDirectSheet(tester, repo);

      // Drag handle pill: Container 40×4 with AppColors.border background.
      expect(find.byKey(const Key('drag-handle')), findsOneWidget);

      // Title
      expect(find.text('Adicionar parada'), findsWidgets);

      // TextField with hint
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              (w.decoration?.hintText ?? '') == 'Digite o endereço ou CEP...',
        ),
        findsOneWidget,
      );

      // 3 method buttons
      expect(find.text('Teclado'), findsOneWidget);
      expect(find.text('Voz'), findsOneWidget);
      expect(find.text('Câmera'), findsOneWidget);

      // CTA FilledButton
      expect(
        find.widgetWithText(FilledButton, 'Adicionar parada'),
        findsOneWidget,
      );
    },
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Test 2: Tapping "Voz" selects it (selected styling applied)
  // ─────────────────────────────────────────────────────────────────────────
  testWidgets(
    'tapping Voz sets selected method to voice (selected styling applied)',
    (tester) async {
      final repo = FakeStopsRepository();

      await _pumpDirectSheet(tester, repo);

      await tester.tap(find.text('Voz'));
      await tester.pump();

      expect(
        find.byKey(const Key('method-btn-voice-selected')),
        findsOneWidget,
      );
    },
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Test 3: Tapping "Voz" + waiting 250 ms closes the sheet with
  //         AddStopResult.voice (wrapper inspects this to decide the push).
  // ─────────────────────────────────────────────────────────────────────────
  testWidgets(
    'tapping Voz pops the sheet with AddStopResult.voice after 200ms',
    (tester) async {
      final repo = FakeStopsRepository();

      await _pumpHostedSheet(tester, repo);

      await tester.tap(find.text('Voz'));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      final result = await _capturedResult;
      expect(result, AddStopResult.voice);
    },
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Test 4: Tapping "Câmera" + waiting 250 ms closes the sheet with
  //         AddStopResult.camera.
  // ─────────────────────────────────────────────────────────────────────────
  testWidgets(
    'tapping Câmera pops the sheet with AddStopResult.camera after 200ms',
    (tester) async {
      final repo = FakeStopsRepository();

      await _pumpHostedSheet(tester, repo);

      await tester.tap(find.text('Câmera'));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      final result = await _capturedResult;
      expect(result, AddStopResult.camera);
    },
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Test 5: Entering text + tapping CTA calls StopsController.add and
  //         pops the sheet with AddStopResult.saved + fires onSaved.
  // ─────────────────────────────────────────────────────────────────────────
  testWidgets(
    'entering text and tapping Adicionar parada saves the stop and pops with AddStopResult.saved',
    (tester) async {
      final repo = FakeStopsRepository();
      var savedFired = 0;

      await _pumpHostedSheet(
        tester,
        repo,
        onSaved: (_) => savedFired++,
      );

      await tester.enterText(
        find.byWidgetPredicate((w) => w is TextField),
        'Rua X',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Adicionar parada'));
      await tester.pumpAndSettle();

      // One stop saved with the correct fields.
      expect(repo.saved.length, 1);
      expect(repo.saved.first.label, 'Rua X');
      expect(repo.saved.first.lat, 0.0);
      expect(repo.saved.first.lng, 0.0);
      expect(repo.saved.first.source, StopSource.manual);

      // Direct-pump test-path callback fired.
      expect(savedFired, 1);

      // Sheet popped with the right intent.
      final result = await _capturedResult;
      expect(result, AddStopResult.saved);
    },
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Test 6: Tapping CTA with empty input does NOT call StopsController.add
  // ─────────────────────────────────────────────────────────────────────────
  testWidgets(
    'tapping Adicionar parada with empty input does not call add',
    (tester) async {
      final repo = FakeStopsRepository();

      await _pumpDirectSheet(tester, repo);

      await tester.tap(find.widgetWithText(FilledButton, 'Adicionar parada'));
      await tester.pumpAndSettle();

      expect(repo.saved, isEmpty);
    },
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Test 7: Risk-1 regression — tap Voice then immediately replace the
  //         widget tree (simulates real dispose, the only way to verify
  //         the cancellable Timer in dispose actually fires). The 200ms
  //         delayed callback must NOT throw or navigate after dispose.
  // ─────────────────────────────────────────────────────────────────────────
  testWidgets(
    'tapping Voz then immediately disposing the sheet causes no exception and no late nav',
    (tester) async {
      final repo = FakeStopsRepository();

      await _pumpDirectSheet(tester, repo);

      // Tap "Voz" to start the 200ms delay.
      await tester.tap(find.text('Voz'));
      await tester.pump();

      // Simulate sheet dismissal by replacing the widget tree entirely —
      // triggers AddStopSheet.dispose(), which cancels the pending Timer
      // (Risk-1 mitigation). Using a navigator.pop here doesn't work
      // because the sheet IS the root route in _pumpDirectSheet setup.
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump();

      // Wait longer than the 200ms delayed callback.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Nothing thrown (asserted implicitly — test would fail on uncaught).
      // No nav happened (sheet is gone, no route push attempted from a
      // defunct widget — the cancelled Timer never fired).
    },
  );
}
