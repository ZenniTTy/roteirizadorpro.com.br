import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:roteirizador_pro/core/services/external_nav.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/presentation/optimize_route_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

import '../_helpers/fake_stops_repository.dart';
import '../../../core/_helpers/fake_external_nav.dart';

Stop _s(String id, {double lat = -23.55, double lng = -46.63, String? label}) =>
    Stop(
      id: id,
      lat: lat,
      lng: lng,
      label: label ?? 'L-$id',
      source: StopSource.manual,
      createdAt: DateTime.utc(2026, 5, 19),
    );

Stop _ungeocoded(String id) => Stop(
      id: id,
      lat: 0,
      lng: 0,
      label: 'L-$id',
      source: StopSource.manual,
      createdAt: DateTime.utc(2026, 5, 19),
    );

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets(
    'OptimizeRoutePage renders stops list, AppBar title and Iniciar CTA',
    (tester) async {
      final stops = [
        _s('a', lat: -23.55, lng: -46.63),
        _s('b', lat: -23.56, lng: -46.64),
        _s('c', lat: -23.57, lng: -46.65),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            stopsRepositoryProvider
                .overrideWithValue(FakeStopsRepository(stops)),
            externalNavProvider.overrideWithValue(FakeExternalNav()),
          ],
          child: const MaterialApp(home: OptimizeRoutePage()),
        ),
      );

      // Allow flutter_map tiles and async stops to settle without
      // pumpAndSettle (tile fetches are indeterminate).
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Rota otimizada'), findsOneWidget);
      expect(find.text('L-a'), findsOneWidget);
      expect(find.text('L-b'), findsOneWidget);
      expect(find.text('L-c'), findsOneWidget);
      expect(find.text('Iniciar navegação'), findsOneWidget);
    },
  );

  testWidgets(
    'Ungeocoded stops are flagged in the list and shown in the banner',
    (tester) async {
      final stops = [
        _s('geo', lat: -23.55, lng: -46.63),
        _ungeocoded('nogeo'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            stopsRepositoryProvider
                .overrideWithValue(FakeStopsRepository(stops)),
            externalNavProvider.overrideWithValue(FakeExternalNav()),
          ],
          child: const MaterialApp(home: OptimizeRoutePage()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('sem geocodificação'), findsOneWidget);
      expect(find.byIcon(Icons.location_off), findsOneWidget);
    },
  );

  testWidgets(
    'Iniciar navegação default (Waze) opens first stop and fires callback',
    (tester) async {
      final fakeNav = FakeExternalNav();
      final stops = [
        _s('a', lat: -23.55, lng: -46.63),
        _s('b', lat: -23.56, lng: -46.64),
      ];

      var navigateFired = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            stopsRepositoryProvider
                .overrideWithValue(FakeStopsRepository(stops)),
            externalNavProvider.overrideWithValue(fakeNav),
          ],
          child: MaterialApp(
            home: OptimizeRoutePage(
              onNavigateStarted: (_) => navigateFired++,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Iniciar navegação'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        fakeNav.wazeCalls.length,
        1,
        reason: 'Waze is default per ADR-0017',
      );
      expect(fakeNav.wazeCalls.first.id, 'a');
      expect(fakeNav.googleMapsCalls, isEmpty);
      expect(navigateFired, 1);
    },
  );

  testWidgets(
    'Iniciar disabled when zero geocoded stops',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            stopsRepositoryProvider.overrideWithValue(
              FakeStopsRepository([_ungeocoded('x'), _ungeocoded('y')]),
            ),
            externalNavProvider.overrideWithValue(FakeExternalNav()),
          ],
          child: const MaterialApp(home: OptimizeRoutePage()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final cta = find.widgetWithText(FilledButton, 'Iniciar navegação');
      expect(cta, findsOneWidget);
      expect(tester.widget<FilledButton>(cta).onPressed, isNull);
    },
  );
}
