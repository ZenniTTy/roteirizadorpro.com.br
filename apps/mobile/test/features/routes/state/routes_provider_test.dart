import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/domain/route.dart' as domain;
import 'package:roteirizador_pro/features/routes/state/routes_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  test('build() returns a non-empty list of routes', () {
    final routes = container.read(routesProvider);
    expect(routes, isNotEmpty);
  });

  test('all routes have unique ids', () {
    final routes = container.read(routesProvider);
    final ids = routes.map((r) => r.id).toList();
    expect(ids.toSet().length, equals(ids.length));
  });

  test('all items are Route instances', () {
    final routes = container.read(routesProvider);
    expect(routes, everyElement(isA<domain.Route>()));
  });

  group('createRoute', () {
    test('appends a new draft route with the returned id', () {
      final notifier = container.read(routesProvider.notifier);
      final initialCount = container.read(routesProvider).length;
      final date = DateTime(2026, 6, 1);

      final id = notifier.createRoute(name: 'Minha rota', date: date);

      final after = container.read(routesProvider);
      expect(after.length, initialCount + 1);
      final created = after.firstWhere((r) => r.id == id);
      expect(created.name, 'Minha rota');
      expect(created.date, date);
      expect(created.status, domain.RouteStatus.draft);
      expect(created.stops, isEmpty);
    });

    test('null name leaves the route nameless (placeholder used downstream)',
        () {
      final notifier = container.read(routesProvider.notifier);
      final id = notifier.createRoute(name: null, date: DateTime(2026, 6, 2));
      final created =
          container.read(routesProvider).firstWhere((r) => r.id == id);
      expect(created.name, isNull);
    });

    test('generates distinct ids across consecutive calls', () async {
      final notifier = container.read(routesProvider.notifier);
      final id1 = notifier.createRoute(date: DateTime(2026, 6, 3));
      await Future<void>.delayed(const Duration(milliseconds: 2));
      final id2 = notifier.createRoute(date: DateTime(2026, 6, 4));
      expect(id1, isNot(equals(id2)));
    });
  });

  group('updateRouteMeta', () {
    test('updates name and date but preserves stops + status', () {
      final notifier = container.read(routesProvider.notifier);
      final id = notifier.createRoute(
        name: 'Original',
        date: DateTime(2026, 6, 5),
      );
      final original =
          container.read(routesProvider).firstWhere((r) => r.id == id);
      final newDate = DateTime(2026, 6, 10);
      notifier.updateRouteMeta(id, name: 'Editado', date: newDate);

      final updated =
          container.read(routesProvider).firstWhere((r) => r.id == id);
      expect(updated.name, 'Editado');
      expect(updated.date, newDate);
      expect(updated.status, original.status);
      expect(updated.stops, original.stops);
    });

    test(
        'null name actually clears the saved name (regression: must NOT '
        'preserve via copyWith null-fallback)', () {
      final notifier = container.read(routesProvider.notifier);
      final id = notifier.createRoute(
        name: 'Original',
        date: DateTime(2026, 6, 6),
      );
      notifier.updateRouteMeta(id, name: null, date: DateTime(2026, 6, 6));
      final updated =
          container.read(routesProvider).firstWhere((r) => r.id == id);
      expect(updated.name, isNull);
    });

    test('no-op when id does not match any route', () {
      final notifier = container.read(routesProvider.notifier);
      final before = container.read(routesProvider);
      notifier.updateRouteMeta(
        'nonexistent-id',
        name: 'whatever',
        date: DateTime(2026, 6, 7),
      );
      final after = container.read(routesProvider);
      expect(after, equals(before));
    });
  });
}
