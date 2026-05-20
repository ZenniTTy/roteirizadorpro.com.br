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

/// Returns the title text of the AppBar currently on top of the
/// navigator. Reading the GoRouter URL would require a context inside
/// the InheritedGoRouter scope; in this StatefulShellRoute layout there
/// isn't a stable place to grab one from outside the route builders, so
/// we infer the current screen visually via its AppBar title.
String _currentScreen(WidgetTester tester) {
  // AppBar exposes its `title` as a child Text widget. Pick the first
  // visible one — `findsOneWidget` would be too strict because the
  // IndexedStack keeps inactive branches mounted offstage; we want the
  // first AppBar in render order, which is the currently-visible route.
  final appBars = find.byType(AppBar);
  for (final element in appBars.evaluate()) {
    final appBar = element.widget as AppBar;
    final title = appBar.title;
    if (title is Text && title.data != null) {
      return title.data!;
    }
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

    testWidgets('Home → FAB push to AddStop → system back returns to /home',
        (tester) async {
      await tester.pumpWidget(_scope(stops: [_stop('a')]));
      await tester.pumpAndSettle();

      expect(_currentScreen(tester), 'Rota de hoje');

      // HomeListPage FAB (wrapped in Semantics(label: 'Adicionar parada')).
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // AddStopPage's AppBar is "Adicionar parada".
      expect(_currentScreen(tester), 'Adicionar parada');

      await _systemBack(tester);

      expect(_currentScreen(tester), 'Rota de hoje');
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

      // EditStopPage's AppBar is "Editar parada".
      expect(_currentScreen(tester), 'Editar parada');

      await _systemBack(tester);

      // Back from edit returns to the same detail screen.
      expect(_currentScreen(tester), 'Parada 1 de 2');
    });
  });
}
