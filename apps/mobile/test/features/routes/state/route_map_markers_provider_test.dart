import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';
import 'package:roteirizador_pro/features/routes/state/active_route_provider.dart';
import 'package:roteirizador_pro/features/routes/state/route_map_markers_provider.dart';
import 'package:roteirizador_pro/features/routes/state/routes_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Stop stop(String id) =>
      Stop(id: id, lat: -23.5, lng: -46.6, streetName: id, fullAddress: id);

  test('sem rota ativa => vazio', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final markers = await c.read(routeMapMarkersProvider.future);
    expect(markers, isEmpty);
  });

  test('rota ativa com N stops => N markers', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final notifier = c.read(routesProvider.notifier);
    final id = notifier.createRoute(date: DateTime(2026, 6, 14));
    notifier.addStop(id, stop('a'));
    notifier.addStop(id, stop('b'));
    c.read(activeRouteIdProvider.notifier).setActiveRoute(id);

    final markers = await c.read(routeMapMarkersProvider.future);
    expect(markers, hasLength(2));
  });

  test('ignora pendingRemoval', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final notifier = c.read(routesProvider.notifier);
    final id = notifier.createRoute(date: DateTime(2026, 6, 14));
    notifier.addStop(id, stop('a'));
    notifier.addStop(id, stop('b'));
    c.read(activeRouteIdProvider.notifier).setActiveRoute(id);
    notifier.markStopForDeferredRemoval(id, 'b');

    final markers = await c.read(routeMapMarkersProvider.future);
    expect(markers, hasLength(1));
  });

  test('StopMarkerBitmapCache.resolve cacheia por label (mesmo objeto)',
      () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final cache = c.read(stopMarkerBitmapCacheProvider.notifier);
    final a = await cache.resolve('A1');
    final b = await cache.resolve('A1');
    expect(identical(a, b), isTrue);
  });
}
