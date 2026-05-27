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
}
