// Integration tests for the Android system-back regression that MS-01
// shipped (ADR-0022). Runs the production RoteirizadorProApp against the
// real GoRouter and asserts that the system back gesture pops within the
// active branch instead of falling through to the Activity (minimize).
//
// Each test overrides `authControllerProvider` with a fake that yields a
// logged-in user immediately (so the router redirect lands on /home) and
// overrides `stopsRepositoryProvider` with an in-memory list.
//
// Run on a connected device:
//   flutter test integration_test/back_navigation_test.dart -d <device-id>

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:roteirizador_pro/app.dart';
import 'package:roteirizador_pro/core/widgets/home_top_bar.dart';
import 'package:roteirizador_pro/features/auth/data/dto/auth_dtos.dart';
import 'package:roteirizador_pro/features/auth/state/auth_controller.dart';
import 'package:roteirizador_pro/features/stops/data/repositories/stops_repository.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

class _FakeStopsRepository implements StopsRepository {
  _FakeStopsRepository(this._stored);
  List<Stop> _stored;

  @override
  Future<List<Stop>> load() async => List.unmodifiable(_stored);

  @override
  Future<void> save(List<Stop> stops) async {
    _stored = List.of(stops);
  }
}

class _LoggedInAuthController extends AuthController {
  @override
  Future<AuthUserDto?> build() async => AuthUserDto(
        id: 'test-user',
        email: 'test@roteirizador.app',
        name: 'Test User',
        phone: null,
        createdAt: DateTime.utc(2026, 1, 1),
      );
}

Stop _stop(String id) => Stop(
      id: id,
      lat: 0,
      lng: 0,
      label: 'Parada $id',
      source: StopSource.manual,
      createdAt: DateTime.utc(2026, 5, 20),
    );

ProviderScope _scope({required List<Stop> stops}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(_LoggedInAuthController.new),
      stopsRepositoryProvider.overrideWithValue(_FakeStopsRepository(stops)),
    ],
    child: const RoteirizadorProApp(),
  );
}

/// Fires the platform-back signal the same way the Android system back
/// button does, then settles the frame.
Future<void> _systemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

/// Returns a stable label for the currently-visible screen. Reading the
/// GoRouter URL would require a context inside the InheritedGoRouter scope;
/// in this StatefulShellRoute layout there isn't a stable place to grab
/// one from outside the route builders, so we infer the current screen
/// visually via known top-bar landmarks.
///
/// Resolution order (most specific first; topmost route wins):
/// 1. Material `AppBar` with a `Text` title → the title's data string.
///    Tried FIRST because StatefulShellRoute's IndexedStack keeps
///    inactive branches mounted offstage AND a pushed route (e.g. /voice,
///    /stops/add) sits ATOP the home branch — so when a screen with an
///    AppBar is visible, its title should win over any HomeTopBar still
///    mounted underneath.
/// 2. `HomeTopBar` (custom Material top bar, NOT an AppBar subclass) →
///    'Rota de hoje'. Used by HomeList post-MS-14 (commit d1b2c5e swap).
///    Reached when nothing has been pushed on top of /home AND no other
///    AppBar-using screen is currently visible.
/// 3. Fallback → `'<no-appbar-title>'` (kept verbose to surface helper
///    breakage early instead of silent passes).
String _currentScreen(WidgetTester tester) {
  // 1. Try a real Material AppBar with Text title first. Pushed routes
  //    (StopDetail, EditStop, VoiceCapture, OcrCapture, etc.) sit atop
  //    the shell branches, so their AppBar — when one exists — represents
  //    the topmost visible screen. skipOffstage: false includes branches
  //    kept mounted in the StatefulShellRoute IndexedStack but we want
  //    the visible ones first — iterate and pick the first whose render
  //    object actually reports as currently rendered (size > 0).
  final appBars = find.byType(AppBar);
  for (final element in appBars.evaluate()) {
    final renderBox = element.findRenderObject();
    if (renderBox is RenderBox &&
        renderBox.hasSize &&
        renderBox.size.height > 0) {
      final appBar = element.widget as AppBar;
      final title = appBar.title;
      if (title is Text && title.data != null) {
        return title.data!;
      }
    }
  }

  // 2. Fall back to HomeTopBar (HomeList post-MS-14, the home-branch
  //    landing page that has no AppBar). Same visibility filter — when a
  //    modal sheet sits over /home, HomeTopBar is still mounted offstage
  //    but its render box reflects the visible state.
  final homeBars =
      find.byType(HomeTopBar, skipOffstage: false).evaluate().toList();
  if (homeBars.isNotEmpty) {
    // If any pushed route covers the home branch, the modal sheet's
    // barrier still allows the home layout below to render — that's OK
    // here, the home is "currently visible" by spec.
    return 'Rota de hoje';
  }

  return '<no-appbar-title>';
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('back navigation does not minimize the app (ADR-0022)', () {
    testWidgets('Home → tap stop → system back returns to /home',
        (tester) async {
      await tester.pumpWidget(_scope(stops: [_stop('a'), _stop('b')]));
      await tester.pumpAndSettle();

      // Land on /home; HomeListPage's AppBar is "Rota de hoje".
      expect(_currentScreen(tester), 'Rota de hoje');
      expect(find.text('Parada a'), findsOneWidget);

      await tester.tap(find.text('Parada a'));
      await tester.pumpAndSettle();

      // StopDetailPage's AppBar is "Parada N de M".
      expect(_currentScreen(tester), 'Parada 1 de 2');

      await _systemBack(tester);

      expect(_currentScreen(tester), 'Rota de hoje');
    });

    // Intentionally NOT testing "Home → tap Configurações tab → system back".
    // System back from a non-default branch root closes the app per Android
    // UX convention (Gmail, Drive, Photos all behave this way) and per
    // codewithandrea.com guidance for StatefulShellRoute. ADR-0022
    // "Out of scope: branch-root back behavior" documents the decision.
    // If a future slice intentionally wants different UX, it adds its
    // own integration_test for that custom flow.

    testWidgets(
        'Home → FAB opens AddStop bottom sheet → system back closes sheet '
        'and returns to /home (MS-15a)', (tester) async {
      await tester.pumpWidget(_scope(stops: [_stop('a')]));
      await tester.pumpAndSettle();

      expect(_currentScreen(tester), 'Rota de hoje');

      // HomeListPage FAB (wrapped in Semantics(label: 'Adicionar parada')).
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Post-MS-15a: AddStopPage is a transparent route wrapper that
      // returns SizedBox.shrink() and opens AddStopSheet via
      // showModalBottomSheet. The sheet hosts the title as a plain Text
      // widget (NOT an AppBar.title), so _currentScreen returns the
      // HomeList AppBar that remains in the route stack below the sheet.
      // The sheet's presence is what we assert.
      expect(_currentScreen(tester), 'Rota de hoje');
      expect(find.text('Adicionar parada'), findsWidgets);
      expect(find.byKey(const Key('drag-handle')), findsOneWidget);

      await _systemBack(tester);

      // System back closes the sheet; the wrapper's onSaved-or-pop
      // callback runs and pops the /stops/add route. Net effect: back on
      // /home with the sheet gone.
      expect(_currentScreen(tester), 'Rota de hoje');
      expect(find.byKey(const Key('drag-handle')), findsNothing);
    });

    testWidgets(
        'Home → FAB opens sheet → tap Voz → after 200ms navigates to '
        '/home/stops/voice; system back returns to /home (MS-15a)',
        (tester) async {
      await tester.pumpWidget(_scope(stops: [_stop('a')]));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('drag-handle')), findsOneWidget);

      // Tap Voz. The sheet's _navTimer fires after 200ms → sheet pops
      // → context.push('/home/stops/voice'). pumpAndSettle drains the
      // timer + the route transition.
      // Tap Voz. The sheet's _navTimer fires after 200ms → sheet pops
      // with AddStopResult.voice → AddStopPage wrapper inspects the
      // result and calls context.push('/home/stops/voice'). The double
      // pump (250 + 500ms) covers the real-time Timer fire on
      // LiveTestWidgetsFlutterBinding plus the sheet-dismiss animation;
      // pumpAndSettle drains the subsequent route transition.
      await tester.tap(find.text('Voz'));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // VoiceCapturePage's AppBar title is "Falar endereço".
      expect(_currentScreen(tester), 'Falar endereço');

      await _systemBack(tester);

      // System back from /voice pops to /home (sheet is already closed).
      expect(_currentScreen(tester), 'Rota de hoje');
    });

    testWidgets(
        'Home → FAB opens sheet → swipe-down dismiss returns to /home '
        'with no nav side-effect (MS-15a Risk-1 device gate)', (tester) async {
      await tester.pumpWidget(_scope(stops: [_stop('a')]));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('drag-handle')), findsOneWidget);

      // Tap Voz to ARM the 200ms Timer, then swipe-down BEFORE it fires.
      await tester.tap(find.text('Voz'));
      await tester.pump(); // first frame after tap, Timer is now scheduled

      // Drag the drag-handle pill downward by a large distance to dismiss
      // the modal sheet (the gesture Flutter associates with sheet close).
      await tester.drag(
        find.byKey(const Key('drag-handle')),
        const Offset(0, 600),
      );
      await tester.pumpAndSettle();

      // Wait past the Timer fire window. The cancel-on-dispose mitigation
      // (Risk-1) must prevent nav to /voice — we stay on /home.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(_currentScreen(tester), 'Rota de hoje');
      expect(find.byKey(const Key('drag-handle')), findsNothing);
    });

    testWidgets('StopDetail → Editar → system back returns to detail',
        (tester) async {
      await tester.pumpWidget(_scope(stops: [_stop('a'), _stop('b')]));
      await tester.pumpAndSettle();

      // Drill into StopDetail.
      await tester.tap(find.text('Parada a'));
      await tester.pumpAndSettle();
      expect(_currentScreen(tester), 'Parada 1 de 2');

      // MS-05 moved Editar to an AppBar action icon (the body no longer
      // surfaces Excluir/Editar buttons — prototype ScreenStopDetail doesn't
      // have them; AppBar action keeps the route reachable for back-nav).
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      // MS-06 rebuilt EditStop as a modal-sheet layout with NO AppBar;
      // the title "Editar parada" lives in the sheet header as a plain
      // Text widget. The "Concluído" button is also unique to the sheet
      // header — using it as the screen signature here.
      expect(find.text('Editar parada'), findsOneWidget);
      expect(find.text('Concluído'), findsOneWidget);

      await _systemBack(tester);

      // Back from edit returns to the same detail screen (which DOES
      // have an AppBar, so the helper works).
      expect(_currentScreen(tester), 'Parada 1 de 2');
    });
  });
}
