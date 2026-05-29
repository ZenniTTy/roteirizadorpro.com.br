import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/domain/route.dart' as domain;
import 'package:roteirizador_pro/features/routes/domain/stop.dart';
import 'package:roteirizador_pro/features/routes/state/active_route_provider.dart';
import 'package:roteirizador_pro/features/routes/state/current_route_stops_provider.dart';
import 'package:roteirizador_pro/features/routes/state/routes_provider.dart';

class _FakeRoutes extends Routes {
  _FakeRoutes(this._seed);
  final List<domain.Route> _seed;
  @override
  List<domain.Route> build() => _seed;
}

class _FakeActiveRouteId extends ActiveRouteId {
  _FakeActiveRouteId(this._seed);
  final String? _seed;
  @override
  String? build() => _seed;
}

void main() {
  final stopA = Stop(lat: -23.5, lng: -46.6, streetName: 'A', fullAddress: 'A full');
  final stopB = Stop(lat: -23.5, lng: -46.6, streetName: 'B', fullAddress: 'B full');

  ProviderContainer makeContainer({
    String? activeId,
    List<domain.Route> routes = const [],
  }) {
    final c = ProviderContainer(overrides: [
      activeRouteIdProvider.overrideWith(() => _FakeActiveRouteId(activeId)),
      routesProvider.overrideWith(() => _FakeRoutes(routes)),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('returns empty when activeRouteId is null', () {
    final c = makeContainer(activeId: null);
    expect(c.read(currentRouteStopsProvider), isEmpty);
  });

  test('returns empty when activeRouteId does not match any route', () {
    final c = makeContainer(
      activeId: 'missing',
      routes: [
        domain.Route(id: 'r1', date: DateTime(2026, 6, 1), status: domain.RouteStatus.draft),
      ],
    );
    expect(c.read(currentRouteStopsProvider), isEmpty);
  });

  test('returns the active route\'s stops list', () {
    final c = makeContainer(
      activeId: 'r1',
      routes: [
        domain.Route(
          id: 'r1',
          date: DateTime(2026, 6, 1),
          status: domain.RouteStatus.draft,
          stops: [stopA, stopB],
        ),
      ],
    );
    final stops = c.read(currentRouteStopsProvider);
    expect(stops.length, 2);
    expect(stops.first.streetName, 'A');
  });
}
