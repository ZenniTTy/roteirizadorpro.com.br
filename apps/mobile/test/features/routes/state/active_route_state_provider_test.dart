// test/features/routes/state/active_route_state_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roteirizador_pro/features/routes/domain/optimization/route_optimizer.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';
import 'package:roteirizador_pro/features/routes/state/active_route_provider.dart';
import 'package:roteirizador_pro/features/routes/state/active_route_state_provider.dart';
import 'package:roteirizador_pro/features/routes/state/routes_provider.dart';

import '../../../_helpers/shared_prefs_async.dart';

Stop _stop(String id) =>
    Stop(id: id, lat: 0, lng: 0, streetName: id, fullAddress: id);

void main() {
  // setActiveRoute persists via activeRouteRepositoryProvider
  // (SharedPreferencesAsync) — back it in-memory.
  useInMemorySharedPreferencesAsync();

  test('sem rota ativa => null', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(activeRouteStateProvider), isNull);
  });

  test('com rota ativa DRAFT => isDraft', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final notifier = c.read(routesProvider.notifier);
    final id = notifier.createRoute(date: DateTime(2026, 6, 14));
    c.read(activeRouteIdProvider.notifier).setActiveRoute(id);
    expect(c.read(activeRouteStateProvider)?.isDraft, isTrue);
  });

  test('após applyOptimization => isPreConfirm', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final notifier = c.read(routesProvider.notifier);
    final id = notifier.createRoute(date: DateTime(2026, 6, 14));
    notifier.addStop(id, _stop('A'));
    notifier.addStop(id, _stop('B'));
    c.read(activeRouteIdProvider.notifier).setActiveRoute(id);
    notifier.applyOptimization(
      id,
      RouteOptimizationResult(
        orderedStops: [_stop('B'), _stop('A')],
        totalDurationMinutes: 18,
        totalDistanceMeters: 5200,
      ),
    );
    expect(c.read(activeRouteStateProvider)?.isPreConfirm, isTrue);
  });
}
