import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/features/share/presentation/share_sheet.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

import '../stops/_helpers/fake_stops_repository.dart';

Stop _s(String id, {double lat = -23.55, double lng = -46.63, String? label}) =>
    Stop(
      id: id,
      lat: lat,
      lng: lng,
      label: label ?? id,
      source: StopSource.manual,
      createdAt: DateTime.utc(2026, 5, 19),
    );

void main() {
  test(
    'buildRouteText numbers stops and includes lat/lng for geocoded entries',
    () {
      final stops = [
        _s('a', lat: -23.55, lng: -46.63, label: 'A'),
        _s('b', lat: -23.56, lng: -46.64, label: 'B'),
      ];

      final text = ShareSheet.buildRouteText(stops);

      expect(text, contains('Rota otimizada — Roteirizador Pro'));
      expect(text, contains('1. A'));
      expect(text, contains('2. B'));
      expect(text, contains('-23.55000, -46.63000'));
      expect(text, contains('-23.56000, -46.64000'));
    },
  );

  test('buildRouteText skips coords for ungeocoded stops', () {
    final stops = [
      _s('a', lat: 0, lng: 0, label: 'só endereço'),
    ];

    final text = ShareSheet.buildRouteText(stops);

    expect(text, contains('1. só endereço'));
    expect(text, isNot(contains('0.00000')));
  });

  testWidgets('ShareSheet renders the Compartilhar CTA and route preview',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stopsRepositoryProvider.overrideWithValue(
            FakeStopsRepository([_s('a', label: 'A')]),
          ),
        ],
        child: const MaterialApp(home: ShareSheet()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Compartilhar'), findsOneWidget);
    // AppBar title per prototype.
    expect(find.text('Indique o app'), findsOneWidget);
    expect(find.text('Voltar'), findsOneWidget);
    expect(find.textContaining('1. A'), findsOneWidget);
  });

  testWidgets(
      'Compartilhar CTA invokes the injected shareFn with text + subject',
      (tester) async {
    String? capturedText;
    String? capturedSubject;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stopsRepositoryProvider.overrideWithValue(
            FakeStopsRepository([_s('a', label: 'A')]),
          ),
        ],
        child: MaterialApp(
          home: ShareSheet(
            shareFn: (text, {subject}) async {
              capturedText = text;
              capturedSubject = subject;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Compartilhar'));
    await tester.pump();

    expect(capturedText, contains('1. A'));
    expect(capturedSubject, 'Rota Roteirizador Pro');
  });

  testWidgets('Compartilhar disabled when zero stops', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stopsRepositoryProvider.overrideWithValue(FakeStopsRepository()),
        ],
        child: const MaterialApp(home: ShareSheet()),
      ),
    );
    await tester.pumpAndSettle();

    final btn = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Compartilhar'),
    );
    expect(btn.onPressed, isNull);
  });
}
