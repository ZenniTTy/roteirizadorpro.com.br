import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/presentation/map_stops_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

import '../_helpers/fake_stops_repository.dart';

Stop _s(String id, {double lat = 0, double lng = 0, String? label}) => Stop(
      id: id,
      lat: lat,
      lng: lng,
      label: label,
      source: StopSource.manual,
      createdAt: DateTime.utc(2026, 5, 13),
    );

Future<void> _pump(
  WidgetTester tester, {
  required List<Stop> stops,
  void Function(BuildContext)? onBack,
  void Function(BuildContext)? onAddStop,
  void Function(BuildContext)? onStartNavigation,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        stopsRepositoryProvider.overrideWithValue(FakeStopsRepository(stops)),
      ],
      child: MaterialApp(
        home: MapStopsPage(
          onBack: onBack,
          onAddStop: onAddStop,
          onStartNavigation: onStartNavigation,
        ),
      ),
    ),
  );
  // Let the provider bootstrap + first map frame settle without awaiting
  // the OSM tile-loader timers (which would deadlock pumpAndSettle).
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('MapStopsPage shows empty hint when no stops are geocoded',
      (tester) async {
    await _pump(tester, stops: [_s('a'), _s('b'), _s('c')]);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Adicione paradas com endereço geocodificado para vê-las no mapa.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Header card renders "Rota de hoje · N paradas"', (tester) async {
    await _pump(
      tester,
      stops: [
        _s('a', lat: -23.55, lng: -46.63),
        _s('b', lat: -23.56, lng: -46.64),
        _s('c', lat: -23.57, lng: -46.65),
      ],
    );

    expect(find.text('Rota de hoje · 3 paradas'), findsOneWidget);
  });

  testWidgets('AO VIVO chip renders with the live label', (tester) async {
    await _pump(tester, stops: [_s('a', lat: -23.55, lng: -46.63)]);
    expect(find.text('AO VIVO'), findsOneWidget);
  });

  testWidgets('Map control buttons are present (zoom in, zoom out, recenter)',
      (tester) async {
    await _pump(tester, stops: [_s('a', lat: -23.55, lng: -46.63)]);

    expect(find.byKey(const Key('map-stops-zoom-in')), findsOneWidget);
    expect(find.byKey(const Key('map-stops-zoom-out')), findsOneWidget);
    expect(find.byKey(const Key('map-stops-recenter')), findsOneWidget);
  });

  testWidgets('Status pins render 1..N indices over geocoded stops',
      (tester) async {
    await _pump(
      tester,
      stops: [
        _s('a', lat: -23.55, lng: -46.63),
        _s('b', lat: -23.56, lng: -46.64),
        _s('c', lat: -23.57, lng: -46.65),
      ],
    );

    // The bottom-panel badge also renders '1', so the first index is
    // expected twice; indices 2 and 3 are unique to the pin layer.
    expect(find.text('1'), findsAtLeastNWidgets(2));
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('Bottom panel renders Próxima parada + Adicionar/Editar + CTA',
      (tester) async {
    await _pump(
      tester,
      stops: [_s('a', lat: -23.55, lng: -46.63, label: 'R. Oscar Freire, 875')],
    );

    expect(find.text('PRÓXIMA PARADA'), findsOneWidget);
    expect(find.text('R. Oscar Freire, 875'), findsOneWidget);
    expect(find.text('Adicionar'), findsAtLeastNWidgets(1));
    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Iniciar navegação'), findsOneWidget);
  });

  testWidgets('Iniciar navegação fires onStartNavigation', (tester) async {
    var navs = 0;
    await _pump(
      tester,
      stops: [_s('a', lat: -23.55, lng: -46.63, label: 'X')],
      onStartNavigation: (_) => navs++,
    );

    await tester.tap(find.text('Iniciar navegação'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(navs, 1);
  });

  testWidgets('Back button fires onBack callback', (tester) async {
    var backs = 0;
    await _pump(
      tester,
      stops: [_s('a', lat: -23.55, lng: -46.63)],
      onBack: (_) => backs++,
    );

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(backs, 1);
  });

  testWidgets('Adicionar (header) fires onAddStop', (tester) async {
    var adds = 0;
    await _pump(
      tester,
      stops: [_s('a', lat: -23.55, lng: -46.63)],
      onAddStop: (_) => adds++,
    );

    // The header "Adicionar" button (FilledButton.icon) — tap by icon-text
    // pairing to disambiguate from the bottom panel's "Adicionar" button.
    await tester.tap(find.widgetWithText(FilledButton, 'Adicionar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(adds, 1);
  });
}
