import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:roteirizador_pro/features/routes/data/active_route_repository.dart';
import 'package:roteirizador_pro/features/routes/domain/route.dart';
import 'package:roteirizador_pro/features/routes/domain/route_state.dart';
import 'package:roteirizador_pro/features/routes/state/active_route_provider.dart';
import 'package:roteirizador_pro/features/routes/state/routes_provider.dart';

class _MockRepo extends Mock implements ActiveRouteRepository {}

/// Routes notifier seeded with an explicit list (overrides the in-memory seed).
class _SeededRoutes extends Routes {
  _SeededRoutes(this._seed);
  final List<Route> _seed;
  @override
  List<Route> build() => _seed;
}

ProviderContainer _container({
  required List<Route> routes,
  required ActiveRouteRepository repo,
}) {
  final c = ProviderContainer(
    overrides: [
      routesProvider.overrideWith(() => _SeededRoutes(routes)),
      activeRouteRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  setUpAll(() => registerFallbackValue('x'));

  test('setActiveRoute persists the id', () async {
    final repo = _MockRepo();
    when(() => repo.write(any())).thenAnswer((_) async {});
    final c = _container(routes: const [], repo: repo);

    c.read(activeRouteIdProvider.notifier).setActiveRoute('route-9');

    expect(c.read(activeRouteIdProvider), 'route-9');
    await Future<void>.delayed(Duration.zero);
    verify(() => repo.write('route-9')).called(1);
  });

  test('resolveActiveRoute restores a still-existing persisted id', () async {
    final repo = _MockRepo();
    when(() => repo.read()).thenAnswer((_) async => 'r-old');
    when(() => repo.write(any())).thenAnswer((_) async {});
    final c = _container(
      routes: [
        Route(id: 'r-old', date: DateTime(2026, 6, 1)),
        Route(id: 'r-new', date: DateTime(2026, 6, 10)),
      ],
      repo: repo,
    );

    await c.read(activeRouteIdProvider.notifier).resolveActiveRoute();

    expect(c.read(activeRouteIdProvider), 'r-old');
  });

  test(
      'resolveActiveRoute falls back to the most-recent route by date '
      'when the persisted id no longer exists', () async {
    final repo = _MockRepo();
    when(() => repo.read()).thenAnswer((_) async => 'gone');
    when(() => repo.write(any())).thenAnswer((_) async {});
    final c = _container(
      routes: [
        Route(id: 'r-old', date: DateTime(2026, 6, 1)),
        Route(id: 'r-new', date: DateTime(2026, 6, 10)),
      ],
      repo: repo,
    );

    await c.read(activeRouteIdProvider.notifier).resolveActiveRoute();

    expect(c.read(activeRouteIdProvider), 'r-new');
  });

  test('resolveActiveRoute creates a route when there are none', () async {
    final repo = _MockRepo();
    when(() => repo.read()).thenAnswer((_) async => null);
    when(() => repo.write(any())).thenAnswer((_) async {});
    final c = _container(routes: const [], repo: repo);

    await c.read(activeRouteIdProvider.notifier).resolveActiveRoute();

    final id = c.read(activeRouteIdProvider);
    expect(id, isNotNull);
    // The created route exists in routesProvider.
    expect(c.read(routesProvider).where((r) => r.id == id), isNotEmpty);
  });

  test('resolveActiveRoute is a no-op when a route is already active',
      () async {
    final repo = _MockRepo();
    when(() => repo.read()).thenAnswer((_) async => 'r-new');
    when(() => repo.write(any())).thenAnswer((_) async {});
    final c = _container(
      routes: [Route(id: 'r-keep', date: DateTime(2026, 6, 1))],
      repo: repo,
    );
    c.read(activeRouteIdProvider.notifier).setActiveRoute('r-keep');

    await c.read(activeRouteIdProvider.notifier).resolveActiveRoute();

    // Did not switch to the persisted 'r-new' — kept the live selection.
    expect(c.read(activeRouteIdProvider), 'r-keep');
    verifyNever(() => repo.read());
  });

  test(
      'resolveActiveRoute breaks a same-date tie by preferring the '
      'non-completed route (the one the driver is likely mid-run)', () async {
    final repo = _MockRepo();
    when(() => repo.read()).thenAnswer((_) async => null);
    when(() => repo.write(any())).thenAnswer((_) async {});
    // Two routes on the SAME date: one completed, one still active. The
    // active one must win the tie (não a completada/encerrada).
    final c = _container(
      routes: [
        Route(
          id: 'r-done',
          date: DateTime(2026, 6, 10),
          routeState: const RouteState(completed: true),
        ),
        Route(id: 'r-active', date: DateTime(2026, 6, 10)),
      ],
      repo: repo,
    );

    await c.read(activeRouteIdProvider.notifier).resolveActiveRoute();

    expect(c.read(activeRouteIdProvider), 'r-active');
  });
}
