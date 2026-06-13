import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:dio/dio.dart';
import 'package:roteirizador_pro/features/route_config/domain/route_config.dart';
import 'package:roteirizador_pro/features/route_config/state/picker_mode.dart';
import 'package:roteirizador_pro/features/routes/application/add_stop_ui_state.dart';
import 'package:roteirizador_pro/features/routes/data/repositories/places_repository.dart';
import 'package:roteirizador_pro/features/routes/domain/place_autocomplete_prediction.dart';
import 'package:roteirizador_pro/features/routes/domain/place_details.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';
import 'package:roteirizador_pro/features/routes/presentation/pages/add_stop_page.dart';
import 'package:roteirizador_pro/features/routes/domain/route.dart' as domain;
import 'package:roteirizador_pro/features/routes/state/active_route_provider.dart';
import 'package:roteirizador_pro/features/routes/state/add_stop_ui_state_provider.dart';
import 'package:roteirizador_pro/features/routes/state/routes_provider.dart';

/// Manual fake for [PlacesRepository] used by the Partida sub-picker pop
/// test — `mocktail ^1.0.5` is the project default for mocks but a manual
/// fake is sufficient here (single method) and avoids reaching for codegen.
class _FakePlacesRepository implements PlacesRepository {
  _FakePlacesRepository({required this.details});
  final PlaceDetails details;

  @override
  Future<PlaceDetails?> getPlaceDetails(String placeId) async => details;

  @override
  Future<List<PlaceAutocompletePrediction>> autocomplete(String query) async =>
      const [];

  @override
  Dio get dio => throw UnimplementedError();

  @override
  String get apiKey => throw UnimplementedError();
}

GoRouter _router(Widget home) => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => home),
      ],
    );

Widget _wrap({
  required AddStopUiState state,
  PickerMode mode = PickerMode.addStop,
}) {
  final router = _router(AddStopPage(mode: mode));
  return ProviderScope(
    overrides: [
      addStopUiStateProvider(mode).overrideWith((ref) => state),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets(
      'EmptyVariant(0 stops) renders first-paradas microcopy + 3 method buttons',
      (tester) async {
    await tester.pumpWidget(_wrap(state: const EmptyVariant(stopCount: 0)));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Adicione as primeiras paradas'),
      findsOneWidget,
    );
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.text('Leitor'), findsOneWidget);
    expect(find.text('Voz'), findsOneWidget);
  });

  testWidgets('EmptyVariant(stopCount >= 1) renders novas-paradas microcopy',
      (tester) async {
    await tester.pumpWidget(_wrap(state: const EmptyVariant(stopCount: 2)));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Adicione novas paradas ou encontre paradas na rota'),
      findsOneWidget,
    );
  });

  testWidgets('ZeroResults renders no-results microcopy + 3 method buttons',
      (tester) async {
    await tester.pumpWidget(_wrap(state: const ZeroResults()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nenhum resultado encontrado'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
  });

  testWidgets('Loading renders CircularProgressIndicator', (tester) async {
    await tester.pumpWidget(_wrap(state: const Loading()));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
      'WithResults renders Section A header + Section B header + Footer',
      (tester) async {
    const pred = PlaceAutocompletePrediction(
      placeId: 'p1',
      description: 'Av Paulista, 1000',
      mainText: 'Av Paulista, 1000',
      secondaryText: 'Bela Vista, SP',
    );
    final stop =
        Stop(lat: 0, lng: 0, streetName: 'Av Paulista, 500', fullAddress: 'x');
    await tester.pumpWidget(
      _wrap(
        state: WithResults(matchesInRoute: [stop], newCandidates: const [pred]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Desta rota (1)'), findsOneWidget);
    expect(find.text('Adicionar nova parada'), findsOneWidget);
    expect(find.text('Escolher no mapa'), findsOneWidget);
  });

  testWidgets('WithResults footer has trailing chevron icon', (tester) async {
    // §11.4 amendment 2026-05-29 item 7 (INVALIDATED): live side-by-side at
    // 2026-05-29 13:38 confirmed Spoke renders mapPinned + chevronRight.
    // Original D4 inference was uiautomator XML blindspot (Compose Icons).
    const pred = PlaceAutocompletePrediction(
      placeId: 'p1',
      description: 'Av Paulista, 1000',
      mainText: 'Av Paulista, 1000',
      secondaryText: 'Bela Vista, SP',
    );
    final stop =
        Stop(lat: 0, lng: 0, streetName: 'Av Paulista, 500', fullAddress: 'x');
    await tester.pumpWidget(
      _wrap(
        state: WithResults(matchesInRoute: [stop], newCandidates: const [pred]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
  });

  testWidgets(
      'WithResults Section B ListTile leads with cornerDownLeft icon '
      '(Spoke parity 2026-06-02)', (tester) async {
    // Live side-by-side 2026-06-02: Spoke result rows lead with a thin
    // redirect-arrow (cornerDownLeft / ↩), not plusCircle. Holds in both
    // the Add Stop and Partida pickers.
    const pred = PlaceAutocompletePrediction(
      placeId: 'p1',
      description: 'Av Paulista, 1000',
      mainText: 'Av Paulista, 1000',
      secondaryText: 'Bela Vista, SP',
    );
    final stop =
        Stop(lat: 0, lng: 0, streetName: 'Av Paulista, 500', fullAddress: 'x');
    await tester.pumpWidget(
      _wrap(
        state: WithResults(matchesInRoute: [stop], newCandidates: const [pred]),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find
            .ancestor(
              of: find.text('Av Paulista, 1000'),
              matching: find.byType(ListTile),
            )
            .first,
        matching: find.byIcon(LucideIcons.cornerDownLeft),
      ),
      findsOneWidget,
    );
    // Regression: the old plusCircle must not survive in Section B.
    expect(find.byIcon(LucideIcons.plusCircle), findsNothing);
  });

  testWidgets('WithResults Section A ListTile keeps leading icon',
      (tester) async {
    // §11.4 amendment 2026-05-29 item 5: Section A keeps `leading` non-null
    // per MS5 Task 2 scope, differentiating it from Section B.
    const pred = PlaceAutocompletePrediction(
      placeId: 'p1',
      description: 'Av Paulista, 1000',
      mainText: 'Av Paulista, 1000',
      secondaryText: 'Bela Vista, SP',
    );
    final stop =
        Stop(lat: 0, lng: 0, streetName: 'Av Paulista, 500', fullAddress: 'x');
    await tester.pumpWidget(
      _wrap(
        state: WithResults(matchesInRoute: [stop], newCandidates: const [pred]),
      ),
    );
    await tester.pumpAndSettle();

    final sectionATile = tester.widget<ListTile>(
      find
          .ancestor(
            of: find.text('Av Paulista, 500'),
            matching: find.byType(ListTile),
          )
          .first,
    );
    expect(sectionATile.leading, isNotNull);
  });

  testWidgets('WithResults Section A ListTile has trailing pencil icon',
      (tester) async {
    // §11.4 amendment 2026-05-29 item 6: Section A has a trailing edit
    // affordance (pencil) at the right edge, differentiating tap-to-edit
    // (Section A) from tap-to-create (Section B).
    const pred = PlaceAutocompletePrediction(
      placeId: 'p1',
      description: 'Av Paulista, 1000',
      mainText: 'Av Paulista, 1000',
      secondaryText: 'Bela Vista, SP',
    );
    final stop =
        Stop(lat: 0, lng: 0, streetName: 'Av Paulista, 500', fullAddress: 'x');
    await tester.pumpWidget(
      _wrap(
        state: WithResults(matchesInRoute: [stop], newCandidates: const [pred]),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find
            .ancestor(
              of: find.text('Av Paulista, 500'),
              matching: find.byType(ListTile),
            )
            .first,
        matching: find.byIcon(LucideIcons.pencil),
      ),
      findsOneWidget,
    );
  });

  testWidgets('WithResults with empty matchesInRoute hides Section A entirely',
      (tester) async {
    const pred = PlaceAutocompletePrediction(
      placeId: 'p1',
      description: 'd',
      mainText: 'Av Paulista',
      secondaryText: 'SP',
    );
    await tester.pumpWidget(
      _wrap(
        state: const WithResults(matchesInRoute: [], newCandidates: [pred]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Desta rota'), findsNothing);
    expect(find.text('Adicionar nova parada'), findsOneWidget);
  });

  // AMENDED (MS-A6/H11 / F5): Section A tap ALREADY pops with an editStopId
  // record — the old SnackBar 'Editar parada em breve' was the pre-A6 stub.
  // This test is replaced by the pop-with-intent test below; the SnackBar
  // assertion is intentionally removed. The new behaviour must NOT show the
  // old stub message.
  testWidgets(
      'Section A tap does NOT show SnackBar "Editar parada em breve" '
      '(stub replaced by pop-with-intent — MS-A6/H11)', (tester) async {
    final stop = Stop(
      id: 's1',
      lat: 0,
      lng: 0,
      streetName: 'Av Paulista, 500',
      fullAddress: 'x',
    );
    // Mount with a parent route — in production AddStopPage is ALWAYS
    // pushed, so _onSectionATap's pop needs a frame to return to.
    final router = GoRouter(
      initialLocation: '/sender',
      routes: [
        GoRoute(
          path: '/sender',
          builder: (context, __) => Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => ctx.push('/picker'),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        GoRoute(path: '/picker', builder: (_, __) => const AddStopPage()),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          addStopUiStateProvider(PickerMode.addStop).overrideWith(
            (ref) =>
                WithResults(matchesInRoute: [stop], newCandidates: const []),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Av Paulista, 500'));
    await tester.pump();

    // The stub SnackBar must no longer appear after the A6 implementation.
    expect(find.text('Editar parada em breve'), findsNothing);
  });

  // NEW — MS-A6/H11 / F5: Section A tap pops with ({String editStopId})
  testWidgets(
      'MS-A6/H11: Section A tap pops with ({String editStopId: stopId}) '
      'record — no SnackBar, no push', (tester) async {
    // Wire a router so pop() has a parent frame to return to.
    Object? poppedResult;
    bool popReturned = false;

    final stop = Stop(
      id: 's1',
      lat: 0,
      lng: 0,
      streetName: 'Av Paulista, 500',
      fullAddress: 'x',
    );

    final router = GoRouter(
      initialLocation: '/sender',
      routes: [
        GoRoute(
          path: '/sender',
          builder: (context, __) => Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  poppedResult = await ctx.push<Object?>('/picker');
                  popReturned = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/picker',
          builder: (_, __) => const AddStopPage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          addStopUiStateProvider(PickerMode.addStop).overrideWith(
            (ref) =>
                WithResults(matchesInRoute: [stop], newCandidates: const []),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Av Paulista, 500'), findsOneWidget);
    await tester.tap(find.text('Av Paulista, 500'));
    await tester.pumpAndSettle();

    expect(popReturned, isTrue);
    // The result must be the anonymous record type ({String editStopId}).
    expect(poppedResult, isNotNull);
    // ignore_for_file does NOT apply here; we assert the type structurally.
    final r = poppedResult;
    expect(r, isA<({String editStopId})>());
    expect((r as ({String editStopId})).editStopId, 's1');
    // No stub SnackBar must appear.
    expect(find.text('Editar parada em breve'), findsNothing);
  });

  // NEW — MS-A6/F4: Section B tap in addStop mode pops with the new stop's id
  testWidgets(
      'MS-A6/F4: Section B tap (addStop mode) pops with the new stop id '
      '(String) — caller gets the id to open editor with ?new=1',
      (tester) async {
    Object? poppedResult;
    bool popReturned = false;

    const pred = PlaceAutocompletePrediction(
      placeId: 'p1',
      description: 'Av Paulista, 1000',
      mainText: 'Av Paulista, 1000',
      secondaryText: 'Bela Vista, SP',
    );

    final fakeRepo = _FakePlacesRepository(
      details: const PlaceDetails(
        lat: -23.561,
        lng: -46.656,
        shortFormattedAddress: 'Av Paulista, 1000',
        formattedAddress: 'Av Paulista, 1000 - Bela Vista, São Paulo - SP',
      ),
    );

    // The test route needs an active route so _addStopFromPrediction can
    // append a stop. We seed routeId 'r1' as active.
    final router = GoRouter(
      initialLocation: '/sender',
      routes: [
        GoRoute(
          path: '/sender',
          builder: (context, __) => Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  poppedResult = await ctx.push<Object?>('/picker');
                  popReturned = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/picker',
          builder: (_, __) => const AddStopPage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          addStopUiStateProvider(PickerMode.addStop).overrideWith(
            (ref) => const WithResults(
              matchesInRoute: [],
              newCandidates: [pred],
            ),
          ),
          placesRepositoryProvider.overrideWith((ref) => fakeRepo),
          activeRouteIdProvider
              .overrideWith(() => _SeededActiveRouteIdForAddStop('r1')),
          routesProvider.overrideWith(
            () => _MutableFakeRoutesForAddStop([
              _routeR1WithNoStops(),
            ]),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Av Paulista, 1000'), findsOneWidget);
    await tester.tap(find.text('Av Paulista, 1000'));
    await tester.pumpAndSettle();

    expect(popReturned, isTrue);
    expect(poppedResult, isNotNull);
    // The result must be a String (the new stop's id).
    expect(poppedResult, isA<String>());
    final returnedId = poppedResult as String;
    // The id must be non-empty (a UUID was generated by the Stop constructor).
    expect(returnedId, isNotEmpty);
  });

  testWidgets('Footer tap navigates to /home/routes/add-stop/map',
      (tester) async {
    // We override the GoRouter for this test to point /map at a recognisable
    // sentinel screen.
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const AddStopPage()),
        GoRoute(
          path: '/home/routes/add-stop/map',
          builder: (_, __) => const Scaffold(body: Text('SENTINEL_MAP')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          addStopUiStateProvider(PickerMode.addStop).overrideWith(
            (ref) => const WithResults(matchesInRoute: [], newCandidates: []),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Escolher no mapa'));
    await tester.pumpAndSettle();

    expect(find.text('SENTINEL_MAP'), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────────────────
  // PickerMode.startLocation — Spoke baseline 2026-06-02:
  // empty body (no method buttons), custom hint, no "Desta rota" section,
  // no "Escolher no mapa" footer, results header = "Escolha o novo endereço".
  // ─────────────────────────────────────────────────────────────────────────

  testWidgets(
      'startLocation mode: EmptyVariant body is empty (no method buttons, '
      'no microcopy)', (tester) async {
    await tester.pumpWidget(
      _wrap(
        state: const EmptyVariant(stopCount: 0),
        mode: PickerMode.startLocation,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mapa'), findsNothing);
    expect(find.text('Leitor'), findsNothing);
    expect(find.text('Voz'), findsNothing);
    expect(find.textContaining('Adicione as primeiras paradas'), findsNothing);
    expect(
      find.textContaining('Adicione novas paradas ou encontre'),
      findsNothing,
    );
  });

  testWidgets(
      'startLocation mode: search field placeholder is the original shared '
      '"Buscar endereço" (ADR-0035: original, not Spoke\'s "Insira um '
      'endereço"; see /tmp/spoke-a5-inspection/ms5-live-endereco-search.png)',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        state: const EmptyVariant(stopCount: 0),
        mode: PickerMode.startLocation,
      ),
    );
    await tester.pumpAndSettle();

    final hintFinder = find.text('Buscar endereço');
    expect(hintFinder, findsOneWidget);
    // Sanity: default add-stop hint must NOT be present in this mode.
    expect(find.text('Digite o endereço da parada'), findsNothing);
  });

  testWidgets(
      'startLocation mode: WithResults renders only "Escolha o novo '
      'endereço" header (no "Desta rota", no "Adicionar nova parada")',
      (tester) async {
    const pred = PlaceAutocompletePrediction(
      placeId: 'p1',
      description: 'Av Paulista, 1000',
      mainText: 'Av Paulista, 1000',
      secondaryText: 'Bela Vista, SP',
    );
    final stop = Stop(
      lat: 0,
      lng: 0,
      streetName: 'Av Paulista, 500',
      fullAddress: 'x',
    );
    await tester.pumpWidget(
      _wrap(
        state: WithResults(matchesInRoute: [stop], newCandidates: const [pred]),
        mode: PickerMode.startLocation,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Escolha o novo endereço'), findsOneWidget);
    expect(find.text('Adicionar nova parada'), findsNothing);
    // Section A header must not appear — Partida picker has no
    // existing-stops list.
    expect(find.textContaining('Desta rota'), findsNothing);
    // The Section A stop row must also be absent — the entire section is
    // skipped, not just the header.
    expect(find.text('Av Paulista, 500'), findsNothing);
    // The new-candidates row is still rendered.
    expect(find.text('Av Paulista, 1000'), findsOneWidget);
  });

  testWidgets(
      'startLocation mode: WithResults has NO "Escolher no mapa" footer',
      (tester) async {
    const pred = PlaceAutocompletePrediction(
      placeId: 'p1',
      description: 'Av Paulista, 1000',
      mainText: 'Av Paulista, 1000',
      secondaryText: 'Bela Vista, SP',
    );
    await tester.pumpWidget(
      _wrap(
        state: const WithResults(matchesInRoute: [], newCandidates: [pred]),
        mode: PickerMode.startLocation,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Escolher no mapa'), findsNothing);
  });

  testWidgets(
      'startLocation mode: ZeroResults body has no method buttons '
      '(empty Partida picker shows nothing below the field)', (tester) async {
    await tester.pumpWidget(
      _wrap(
        state: const ZeroResults(),
        mode: PickerMode.startLocation,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mapa'), findsNothing);
    expect(find.text('Leitor'), findsNothing);
    expect(find.text('Voz'), findsNothing);
    expect(find.textContaining('Nenhum resultado encontrado'), findsOneWidget);
  });

  testWidgets(
      'startLocation mode: tapping a new-candidate row pops with a '
      'StartLocation built from the prediction', (tester) async {
    // Use a router that has the picker pushed (so pop has a target frame),
    // and verifies the pop result.
    StartLocation? popped;
    bool popReturned = false;
    final router = GoRouter(
      initialLocation: '/sender',
      routes: [
        GoRoute(
          path: '/sender',
          builder: (context, __) => Scaffold(
            body: Center(
              child: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () async {
                    popped = await ctx.push<StartLocation>('/picker');
                    popReturned = true;
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/picker',
          builder: (_, __) => const AddStopPage(mode: PickerMode.startLocation),
        ),
      ],
    );

    const pred = PlaceAutocompletePrediction(
      placeId: 'p1',
      description: 'Av Paulista, 1000',
      mainText: 'Av Paulista, 1000',
      secondaryText: 'Bela Vista, SP',
    );

    final fakeRepo = _FakePlacesRepository(
      details: const PlaceDetails(
        lat: -23.561,
        lng: -46.656,
        shortFormattedAddress: 'Av Paulista, 1000',
        formattedAddress: 'Av Paulista, 1000 - Bela Vista, São Paulo - SP',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          addStopUiStateProvider(PickerMode.startLocation).overrideWith(
            (ref) =>
                const WithResults(matchesInRoute: [], newCandidates: [pred]),
          ),
          placesRepositoryProvider.overrideWith((ref) => fakeRepo),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Picker is on top — tap the new-candidate row.
    expect(find.text('Av Paulista, 1000'), findsOneWidget);
    await tester.tap(find.text('Av Paulista, 1000'));
    await tester.pumpAndSettle();

    // The future resolved with a StartLocation (not null).
    expect(popReturned, isTrue);
    expect(popped, isNotNull);
    expect(popped!.address, 'Av Paulista, 1000');
    expect(popped!.isUserCurrentLocation, isFalse);
    expect(popped!.lat, closeTo(-23.561, 1e-6));
    expect(popped!.lng, closeTo(-46.656, 1e-6));
  });

  testWidgets(
      'endLocation mode: tapping a new-candidate row pops with a '
      'SpecificAddress built from the prediction (ADR-0043)', (tester) async {
    // Symmetric to the startLocation pop test: the Destino sheet's "Destino
    // em outro endereço" card pushes AddStopPage(mode: endLocation); selecting
    // an address must pop a SpecificAddress for the parent to persist via
    // setDestination. Replaces the prior UnsupportedError stub.
    SpecificAddress? popped;
    bool popReturned = false;
    final router = GoRouter(
      initialLocation: '/sender',
      routes: [
        GoRoute(
          path: '/sender',
          builder: (context, __) => Scaffold(
            body: Center(
              child: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () async {
                    popped = await ctx.push<SpecificAddress>('/picker');
                    popReturned = true;
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/picker',
          builder: (_, __) => const AddStopPage(mode: PickerMode.endLocation),
        ),
      ],
    );

    const pred = PlaceAutocompletePrediction(
      placeId: 'p1',
      description: 'Av Paulista, 1000',
      mainText: 'Av Paulista, 1000',
      secondaryText: 'Bela Vista, SP',
    );

    final fakeRepo = _FakePlacesRepository(
      details: const PlaceDetails(
        lat: -23.561,
        lng: -46.656,
        shortFormattedAddress: 'Av Paulista, 1000',
        formattedAddress: 'Av Paulista, 1000 - Bela Vista, São Paulo - SP',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          addStopUiStateProvider(PickerMode.endLocation).overrideWith(
            (ref) =>
                const WithResults(matchesInRoute: [], newCandidates: [pred]),
          ),
          placesRepositoryProvider.overrideWith((ref) => fakeRepo),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Picker is on top — tap the new-candidate row.
    expect(find.text('Av Paulista, 1000'), findsOneWidget);
    await tester.tap(find.text('Av Paulista, 1000'));
    await tester.pumpAndSettle();

    // The future resolved with a SpecificAddress (not null).
    expect(popReturned, isTrue);
    expect(popped, isNotNull);
    expect(popped!.address, 'Av Paulista, 1000');
    expect(popped!.lat, closeTo(-23.561, 1e-6));
    expect(popped!.lng, closeTo(-46.656, 1e-6));
  });

  testWidgets(
      'mode defaults to addStop and preserves Area 4 default behavior '
      '(regression)', (tester) async {
    // Re-exercises the legacy default-hint + empty-state-buttons path with
    // mode left at its default, to lock the no-regression contract for MS3
    // after PickerMode gained an explicit `addStop` value (2026-06-02
    // cleanup).
    await tester.pumpWidget(_wrap(state: const EmptyVariant(stopCount: 0)));
    await tester.pumpAndSettle();

    expect(find.text('Digite o endereço da parada'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.text('Leitor'), findsOneWidget);
    expect(find.text('Voz'), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────────────────
  // PickerMode.changeAddress — T17/H10 (MS-A6)
  //
  // NOTE: These tests will fail with a *compile error* until the implementer
  // adds `changeAddress` to `picker_mode.dart`. That is the intended RED state
  // for a data declaration that does not exist yet.
  // ─────────────────────────────────────────────────────────────────────────

  group('changeAddress (T17/H10)', () {
    testWidgets(
        'changeAddress mode: EmptyVariant shows "Buscar endereço" hint; '
        'NO method buttons, NO microcopy', (tester) async {
      await tester.pumpWidget(
        _wrap(
          state: const EmptyVariant(stopCount: 0),
          mode: PickerMode.changeAddress,
        ),
      );
      await tester.pumpAndSettle();

      // Hint from mode.hintText.
      expect(find.text('Buscar endereço'), findsOneWidget);
      // Default add-stop hint must NOT appear.
      expect(find.text('Digite o endereço da parada'), findsNothing);
      // No method buttons (showMethodButtonsOnEmpty == false).
      expect(find.text('Mapa'), findsNothing);
      expect(find.text('Leitor'), findsNothing);
      expect(find.text('Voz'), findsNothing);
      // No microcopy (showMicrocopyOnEmpty == false).
      expect(find.textContaining('Adicione'), findsNothing);
    });

    testWidgets(
        'changeAddress mode: WithResults shows "Escolha o novo endereço" header; '
        'NO "Desta rota" section (showExistingStopsSection == false); '
        'NO "Escolher no mapa" footer; NO "Adicionar nova parada" header',
        (tester) async {
      const pred = PlaceAutocompletePrediction(
        placeId: 'p1',
        description: 'Av Paulista, 1000',
        mainText: 'Av Paulista, 1000',
        secondaryText: 'Bela Vista, SP',
      );
      // Provide a stop that would match Section A — must be absent.
      final stop = Stop(
        lat: 0,
        lng: 0,
        streetName: 'Av Paulista, 500',
        fullAddress: 'x',
      );

      await tester.pumpWidget(
        _wrap(
          state:
              WithResults(matchesInRoute: [stop], newCandidates: const [pred]),
          mode: PickerMode.changeAddress,
        ),
      );
      await tester.pumpAndSettle();

      // Section B header = mode.resultsSectionHeader.
      expect(find.text('Escolha o novo endereço'), findsOneWidget);
      // Section A header MUST NOT appear (showExistingStopsSection == false).
      expect(find.textContaining('Desta rota'), findsNothing);
      // Section A stop row MUST NOT appear.
      expect(find.text('Av Paulista, 500'), findsNothing);
      // New-candidate row IS rendered.
      expect(find.text('Av Paulista, 1000'), findsOneWidget);
      // No "Adicionar nova parada" header.
      expect(find.text('Adicionar nova parada'), findsNothing);
      // No map footer (showChooseOnMapFooter == false).
      expect(find.text('Escolher no mapa'), findsNothing);
    });

    testWidgets(
        'changeAddress mode: tapping new-candidate row pops the address '
        'record ({lat, lng, streetName, fullAddress}) — '
        'streetName == mainText, fullAddress == details.formattedAddress',
        (tester) async {
      // Wire a router so pop() has a parent frame.
      Object? poppedResult;
      bool popReturned = false;

      const pred = PlaceAutocompletePrediction(
        placeId: 'pCA1',
        description: 'Rua Nova, 200',
        mainText: 'Rua Nova, 200',
        secondaryText: 'Centro, São Paulo',
      );

      final fakeRepo = _FakePlacesRepository(
        details: const PlaceDetails(
          lat: -23.55,
          lng: -46.63,
          shortFormattedAddress: 'Rua Nova, 200',
          formattedAddress: 'Rua Nova, 200 - Centro, São Paulo',
        ),
      );

      final router = GoRouter(
        initialLocation: '/sender',
        routes: [
          GoRoute(
            path: '/sender',
            builder: (context, __) => Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () async {
                    poppedResult = await ctx.push<Object?>('/picker');
                    popReturned = true;
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/picker',
            builder: (_, __) =>
                const AddStopPage(mode: PickerMode.changeAddress),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            addStopUiStateProvider(PickerMode.changeAddress).overrideWith(
              (ref) => const WithResults(
                matchesInRoute: [],
                newCandidates: [pred],
              ),
            ),
            placesRepositoryProvider.overrideWith((ref) => fakeRepo),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Rua Nova, 200'), findsOneWidget);
      await tester.tap(find.text('Rua Nova, 200'));
      await tester.pumpAndSettle();

      expect(popReturned, isTrue);
      expect(poppedResult, isNotNull);

      // The result must be the address record type.
      expect(
        poppedResult,
        isA<
            ({
              double lat,
              double lng,
              String streetName,
              String fullAddress
            })>(),
      );
      final r = poppedResult! as ({
        double lat,
        double lng,
        String streetName,
        String fullAddress
      });
      expect(r.lat, closeTo(-23.55, 1e-6));
      expect(r.lng, closeTo(-46.63, 1e-6));
      expect(r.streetName, 'Rua Nova, 200');
      expect(r.fullAddress, 'Rua Nova, 200 - Centro, São Paulo');
    });

    testWidgets(
        'changeAddress mode: details null → SnackBar de erro; página NÃO popa',
        (tester) async {
      // Fake repo returns null details → error path must NOT pop.
      bool popReturned = false;

      const pred = PlaceAutocompletePrediction(
        placeId: 'pNull',
        description: 'Rua Inexistente',
        mainText: 'Rua Inexistente',
        secondaryText: 'SP',
      );

      // Wrap with a custom override that always returns null.
      final router = GoRouter(
        initialLocation: '/sender',
        routes: [
          GoRoute(
            path: '/sender',
            builder: (context, __) => Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () async {
                    await ctx.push<Object?>('/picker');
                    popReturned = true;
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/picker',
            builder: (_, __) =>
                const AddStopPage(mode: PickerMode.changeAddress),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            addStopUiStateProvider(PickerMode.changeAddress).overrideWith(
              (ref) => const WithResults(
                matchesInRoute: [],
                newCandidates: [pred],
              ),
            ),
            // Override with a repo that always returns null.
            placesRepositoryProvider
                .overrideWith((ref) => _NullDetailsRepository()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rua Inexistente'));
      await tester.pumpAndSettle();

      // SnackBar de erro deve aparecer.
      expect(find.byType(SnackBar), findsOneWidget);
      // Página NÃO popou — popReturned permanece false.
      expect(popReturned, isFalse);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers for MS-A6/F4 Section B pop-with-id test
// ─────────────────────────────────────────────────────────────────────────────

/// Minimal [ActiveRouteId] override that always returns a fixed seed.
/// Mirrors the pattern already used in route_shell_page_test.dart.
class _SeededActiveRouteIdForAddStop extends ActiveRouteId {
  _SeededActiveRouteIdForAddStop(this._seed);
  final String _seed;
  @override
  String? build() => _seed;
}

/// Mutable [Routes] notifier seeded with an initial list.
/// Mirrors [_MutableFakeRoutes] in route_shell_page_test.dart.
class _MutableFakeRoutesForAddStop extends Routes {
  _MutableFakeRoutesForAddStop(this._seed);
  final List<domain.Route> _seed;
  @override
  List<domain.Route> build() => _seed;
}

domain.Route _routeR1WithNoStops() => domain.Route(
      id: 'r1',
      date: DateTime(2026, 5, 27),
      status: domain.RouteStatus.draft,
    );

// ─────────────────────────────────────────────────────────────────────────────
// Helper for changeAddress null-details error test (T17/H10)
// ─────────────────────────────────────────────────────────────────────────────

/// Fake [PlacesRepository] that always returns `null` from [getPlaceDetails].
/// Used to exercise the error branch in `_onSectionBTap` for
/// [PickerMode.changeAddress] (and equivalently for startLocation/endLocation).
class _NullDetailsRepository implements PlacesRepository {
  @override
  Future<PlaceDetails?> getPlaceDetails(String placeId) async => null;

  @override
  Future<List<PlaceAutocompletePrediction>> autocomplete(String query) async =>
      const [];

  @override
  Dio get dio => throw UnimplementedError();

  @override
  String get apiKey => throw UnimplementedError();
}
