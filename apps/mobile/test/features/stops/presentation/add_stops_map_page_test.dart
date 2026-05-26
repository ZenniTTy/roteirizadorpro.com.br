import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:roteirizador_pro/features/stops/presentation/add_stops_map_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

import '../_helpers/fake_stops_repository.dart';

Future<void> _pump(
  WidgetTester tester, {
  FakeStopsRepository? repo,
  void Function(BuildContext)? onConfirmed,
  void Function(BuildContext, String)? onEditAfterAdd,
  void Function(BuildContext)? onBack,
  List<LatLng>? initialPending,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        stopsRepositoryProvider
            .overrideWithValue(repo ?? FakeStopsRepository()),
      ],
      child: MaterialApp(
        home: AddStopsMapPage(
          onConfirmed: onConfirmed,
          onEditAfterAdd: onEditAfterAdd,
          onBack: onBack,
          initialPending: initialPending,
        ),
      ),
    ),
  );
  // Let provider bootstrap settle without awaiting tile-loader timers.
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

const _samplePin = LatLng(-23.55, -46.63);

void main() {
  testWidgets('Floating search header renders the "Buscar endereço…" pill',
      (tester) async {
    await _pump(tester);
    expect(find.text('Buscar endereço…'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });

  testWidgets('Back button is present in the floating header', (tester) async {
    await _pump(tester);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('No selection → no bottom sheet (no Adicionar parada button)',
      (tester) async {
    await _pump(tester);
    expect(find.byKey(const Key('add-stops-map-confirm')), findsNothing);
    expect(find.text('Adicionar parada'), findsNothing);
  });

  testWidgets('Undo button is hidden until at least one pin exists',
      (tester) async {
    await _pump(tester);
    expect(find.byKey(const Key('add-stops-map-undo')), findsNothing);
  });

  testWidgets('Seeded pin renders the bottom sheet with Adicionar parada',
      (tester) async {
    await _pump(tester, initialPending: const [_samplePin]);

    expect(find.byKey(const Key('add-stops-map-confirm')), findsOneWidget);
    expect(find.text('Adicionar parada'), findsOneWidget);
    expect(find.text('Adicionar e editar'), findsOneWidget);
    expect(find.byIcon(Icons.location_on), findsOneWidget);
    expect(find.text('Parada 1'), findsOneWidget);
  });

  testWidgets('Adicionar parada persists the stop and fires onConfirmed',
      (tester) async {
    final repo = FakeStopsRepository();
    var confirms = 0;
    await _pump(
      tester,
      repo: repo,
      initialPending: const [_samplePin],
      onConfirmed: (_) => confirms++,
    );

    await tester.tap(find.byKey(const Key('add-stops-map-confirm')));
    await tester.pumpAndSettle();

    expect(repo.saved, hasLength(1));
    expect(repo.saved.first.lat, _samplePin.latitude);
    expect(repo.saved.first.lng, _samplePin.longitude);
    expect(repo.saved.first.source.name, 'mapTap');
    expect(confirms, 1);
  });

  testWidgets(
      'Adicionar e editar fires onEditAfterAdd with the persisted stop id',
      (tester) async {
    final repo = FakeStopsRepository();
    String? capturedId;
    await _pump(
      tester,
      repo: repo,
      initialPending: const [_samplePin],
      onEditAfterAdd: (_, id) => capturedId = id,
    );

    await tester.tap(find.text('Adicionar e editar'));
    await tester.pumpAndSettle();

    expect(repo.saved, hasLength(1));
    expect(capturedId, isNotNull);
    expect(capturedId, repo.saved.first.id);
  });

  testWidgets('onBack callback fires when the back button is tapped',
      (tester) async {
    var backs = 0;
    await _pump(tester, onBack: (_) => backs++);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(backs, 1);
  });
}
