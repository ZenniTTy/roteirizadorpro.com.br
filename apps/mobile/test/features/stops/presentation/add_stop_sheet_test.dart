import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/presentation/add_stop_sheet.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

import '../../../_support/phone_surface.dart';
import '../_helpers/fake_stops_repository.dart';

// ---------------------------------------------------------------------------
// Routing spy helper — wraps AddStopSheet in a GoRouter with two placeholder
// routes so context.push('/stops/add/voice' | '/stops/add/ocr') can be
// captured in a list without launching real pages.
// ---------------------------------------------------------------------------

/// Builds a [GoRouter] that hosts [AddStopSheet] directly at '/' and has
/// placeholder routes for '/stops/add/voice' and '/stops/add/ocr'.
/// The [navigatedRoutes] list accumulates every location pushed to the router.
GoRouter _buildRouter({
  required FakeStopsRepository repo,
  required List<String> navigatedRoutes,
  void Function(BuildContext)? onSaved,
}) {
  return GoRouter(
    initialLocation: '/',
    observers: [],
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: AddStopSheet(onSaved: onSaved),
        ),
      ),
      GoRoute(
        path: '/stops/add/voice',
        builder: (context, state) {
          navigatedRoutes.add('/stops/add/voice');
          return const Scaffold(body: Text('voice'));
        },
      ),
      GoRoute(
        path: '/stops/add/ocr',
        builder: (context, state) {
          navigatedRoutes.add('/stops/add/ocr');
          return const Scaffold(body: Text('ocr'));
        },
      ),
    ],
  );
}

/// Pumps the widget tree using the GoRouter spy above.
Future<void> _pumpSheet(
  WidgetTester tester,
  FakeStopsRepository repo,
  List<String> navigatedRoutes, {
  void Function(BuildContext)? onSaved,
}) async {
  await phoneSurface(tester);

  final router = _buildRouter(
    repo: repo,
    navigatedRoutes: navigatedRoutes,
    onSaved: onSaved,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [stopsRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(
        routerConfig: router,
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
      final nav = <String>[];

      await _pumpSheet(tester, repo, nav);

      // Drag handle pill: Container 40×4 with AppColors.border background.
      // We find it by its key assigned in the implementation.
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

      // CTA FilledButton — at least one 'Adicionar parada' text is under it
      expect(find.widgetWithText(FilledButton, 'Adicionar parada'),
          findsOneWidget);
    },
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Test 2: Tapping "Voz" selects it (selected styling applied)
  // ─────────────────────────────────────────────────────────────────────────
  testWidgets(
    'tapping Voz sets selected method to voice (selected styling applied)',
    (tester) async {
      final repo = FakeStopsRepository();
      final nav = <String>[];

      await _pumpSheet(tester, repo, nav);

      await tester.tap(find.text('Voz'));
      await tester.pump();

      // After selecting "Voz", the _MethodButton for Voz must carry the
      // selected key so assertions can pinpoint it.
      expect(
          find.byKey(const Key('method-btn-voice-selected')), findsOneWidget);
    },
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Test 3: Tapping "Voz" then pumping 250ms navigates to /stops/add/voice
  // ─────────────────────────────────────────────────────────────────────────
  testWidgets(
    'tapping Voz and waiting 250 ms navigates to /stops/add/voice',
    (tester) async {
      final repo = FakeStopsRepository();
      final nav = <String>[];

      await _pumpSheet(tester, repo, nav);

      await tester.tap(find.text('Voz'));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(nav, contains('/stops/add/voice'));
    },
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Test 4: Tapping "Câmera" then pumping 250ms navigates to /stops/add/ocr
  // ─────────────────────────────────────────────────────────────────────────
  testWidgets(
    'tapping Câmera and waiting 250 ms navigates to /stops/add/ocr',
    (tester) async {
      final repo = FakeStopsRepository();
      final nav = <String>[];

      await _pumpSheet(tester, repo, nav);

      await tester.tap(find.text('Câmera'));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(nav, contains('/stops/add/ocr'));
    },
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Test 5: Entering text + tapping CTA calls StopsController.add and
  //         dismisses the sheet (onSaved fires)
  // ─────────────────────────────────────────────────────────────────────────
  testWidgets(
    'entering text and tapping Adicionar parada calls add with expected fields and fires onSaved',
    (tester) async {
      final repo = FakeStopsRepository();
      final nav = <String>[];
      var savedFired = 0;

      await _pumpSheet(
        tester,
        repo,
        nav,
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

      // onSaved callback was invoked (sheet dismissed).
      expect(savedFired, 1);
    },
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Test 6: Tapping CTA with empty input does NOT call StopsController.add
  // ─────────────────────────────────────────────────────────────────────────
  testWidgets(
    'tapping Adicionar parada with empty input does not call add',
    (tester) async {
      final repo = FakeStopsRepository();
      final nav = <String>[];

      await _pumpSheet(tester, repo, nav);

      // Do NOT enter text — TextField is empty.
      await tester.tap(find.widgetWithText(FilledButton, 'Adicionar parada'));
      await tester.pumpAndSettle();

      expect(repo.saved, isEmpty);
    },
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Test 7: Risk-1 regression — tap Voice then immediately pop the sheet;
  //         the 200ms delayed callback must NOT navigate or throw after pop.
  // ─────────────────────────────────────────────────────────────────────────
  testWidgets(
    'tapping Voz then immediately closing the sheet causes no exception and no navigation',
    (tester) async {
      final repo = FakeStopsRepository();
      final nav = <String>[];

      await _pumpSheet(tester, repo, nav);

      // Tap "Voz" to start the 200ms delay.
      await tester.tap(find.text('Voz'));
      await tester.pump();

      // Immediately pop the route (simulates swipe-down / barrier tap).
      final NavigatorState navigator =
          tester.state(find.byType(Navigator).first);
      navigator.pop();
      await tester.pump();

      // Wait longer than the 200ms delayed callback.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // No navigation should have happened, no exception thrown.
      expect(nav, isEmpty);
    },
  );
}
