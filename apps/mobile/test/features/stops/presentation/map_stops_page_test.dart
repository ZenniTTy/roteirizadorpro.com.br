import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/presentation/map_stops_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

import '../_helpers/fake_stops_repository.dart';

Stop _s(String id, {double lat = 0, double lng = 0}) => Stop(
      id: id,
      lat: lat,
      lng: lng,
      source: StopSource.manual,
      createdAt: DateTime.utc(2026, 5, 13),
    );

void main() {
  testWidgets('MapStopsPage renders with geocoded stops', (tester) async {
    final stops = [
      _s('a', lat: -23.55, lng: -46.63),
      _s('b', lat: -23.56, lng: -46.64),
      _s('c', lat: -23.57, lng: -46.65),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stopsRepositoryProvider.overrideWithValue(FakeStopsRepository(stops)),
        ],
        child: const MaterialApp(home: MapStopsPage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Mapa das paradas'), findsOneWidget);
  });

  testWidgets('MapStopsPage shows empty hint when no stops are geocoded',
      (tester) async {
    final stops = [_s('a'), _s('b'), _s('c')];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stopsRepositoryProvider.overrideWithValue(FakeStopsRepository(stops)),
        ],
        child: const MaterialApp(home: MapStopsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Adicione paradas com endereço geocodificado para vê-las no mapa.',
      ),
      findsOneWidget,
    );
  });
}
