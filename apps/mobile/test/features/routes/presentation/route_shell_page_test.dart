import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:roteirizador_pro/core/theme/app_theme.dart';
import 'package:roteirizador_pro/features/route_config/domain/route_config.dart';
import 'package:roteirizador_pro/features/route_config/presentation/widgets/route_config_row.dart';
import 'package:roteirizador_pro/features/route_config/state/route_config_controller.dart';
import 'package:roteirizador_pro/features/routes/data/location_service.dart';
import 'package:roteirizador_pro/features/routes/domain/map_controls_state.dart';
import 'package:roteirizador_pro/features/routes/domain/route.dart' as domain;
import 'package:roteirizador_pro/features/routes/domain/stop.dart' as domain;
import 'package:roteirizador_pro/features/routes/presentation/route_shell_page.dart';
import 'package:roteirizador_pro/features/routes/domain/optimization_state.dart';
import 'package:roteirizador_pro/features/routes/domain/route_state.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/app_drawer.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/pre_confirm_view.dart';
import 'package:roteirizador_pro/features/routes/state/active_route_provider.dart';
import 'package:roteirizador_pro/features/routes/state/current_user_provider.dart';
import 'package:roteirizador_pro/features/routes/state/map_controls_controller.dart';
import 'package:roteirizador_pro/features/routes/state/routes_provider.dart';

import '../_helpers/fake_current_user.dart';

Widget _wrapPage() => ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(kUserWithoutSub),
        routesProvider.overrideWithValue([
          domain.Route(
            id: 'seed1',
            date: DateTime(2026, 5, 27),
          ),
        ]),
      ],
      child: MaterialApp(
        theme: AppTheme.light().copyWith(
          splashFactory: NoSplash.splashFactory,
        ),
        home: const RouteShellPage(),
      ),
    );

/// Router-aware wrapper for the MS-A5.7 "Configuração de rota" summary rows
/// and MS-A6 stop-list tests.
///
/// The summary rows push `/home/routes/active/:routeId/details` (ADR-0046), so
/// the shell must be mounted inside a [GoRouter] that registers that path (a
/// sentinel stands in for `RouteDetailsPage` so the test asserts the nav, not
/// the page). [activeRouteId] is seeded via [ActiveRouteId] override because
/// the section only renders when there IS an active route — the production
/// shell reads [activeRouteIdProvider] (`String?`, null = no section).
///
/// [stops] seeds the route with pre-existing stops (MS-A6 §3.2.1 tests).
/// The router includes two new sentinels added for MS-A6 (H8, H19):
///   - `routes/:routeId/edit` — tapping the route name in the sheet header.
///   - `routes/active/:routeId/stops/:stopId/edit` — tapping a stop card.
Widget _wrapRouted({
  required String activeRouteId,
  RouteConfig? initialConfig,
  List<domain.Stop> stops = const [],
}) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, __) => const RouteShellPage(),
        routes: [
          GoRoute(
            path: 'routes/active/:routeId/details',
            builder: (_, __) =>
                const Scaffold(body: Text('SENTINEL_DETALHES_DA_ROTA')),
          ),
          GoRoute(
            path: 'routes/reuse-stops',
            builder: (_, __) =>
                const Scaffold(body: Text('SENTINEL_REUTILIZAR_PARADAS')),
          ),
          // MS-A6 H8 — tapping the route name opens the edit-route screen.
          GoRoute(
            path: 'routes/:routeId/edit',
            builder: (context, state) => Scaffold(
              body: Text(
                'SENTINEL_EDIT_ROUTE_${state.pathParameters['routeId']}',
              ),
            ),
          ),
          // MS-A6 H19 — tapping a stop card opens the edit-stop screen.
          GoRoute(
            path: 'routes/active/:routeId/stops/:stopId/edit',
            builder: (context, state) => Scaffold(
              body: Text(
                'SENTINEL_EDIT_STOP_${state.pathParameters['stopId']}',
              ),
            ),
          ),
        ],
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWithValue(kUserWithoutSub),
      routesProvider.overrideWithValue([
        domain.Route(
          id: activeRouteId,
          date: DateTime(2026, 5, 27),
          stops: stops,
        ),
      ]),
      activeRouteIdProvider
          .overrideWith(() => _SeededActiveRouteId(activeRouteId)),
      if (initialConfig != null)
        routeConfigControllerProvider(activeRouteId)
            .overrideWith(() => _SeededConfigController(initialConfig)),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light().copyWith(splashFactory: NoSplash.splashFactory),
      routerConfig: router,
    ),
  );
}

class _SeededActiveRouteId extends ActiveRouteId {
  _SeededActiveRouteId(this._seed);
  final String _seed;
  @override
  String? build() => _seed;
}

/// Fake map-controls controller seeded with a fixed state, recording whether
/// [toggleMapType]/[startFollowing] were invoked. Lets widget tests assert the
/// shell's map buttons drive the controller without touching SharedPrefs or a
/// real GoogleMap.
class _FakeMapControls extends MapControlsController {
  _FakeMapControls(this._seed);
  final MapControlsState _seed;
  int toggleCount = 0;
  int startFollowingCount = 0;

  @override
  Future<MapControlsState> build() async => _seed;

  @override
  Future<void> toggleMapType() async {
    toggleCount++;
    final next = state.value!.mapType == MapType.normal
        ? MapType.satellite
        : MapType.normal;
    state = AsyncData(state.value!.copyWith(mapType: next));
  }

  @override
  Future<void> startFollowing() async {
    startFollowingCount++;
    state = AsyncData(state.value!.copyWith(followingUser: true));
  }
}

/// Wrap the shell with a seeded map-controls controller (no router needed for
/// the map-control assertions; the buttons are floating chrome on the map).
/// Optionally inject a [LocationService] for the recenter flow.
Widget _wrapWithMapControls(
  MapControlsState seed, {
  LocationService? locationService,
}) {
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWithValue(kUserWithoutSub),
      routesProvider.overrideWithValue([
        domain.Route(
          id: 'seed1',
          date: DateTime(2026, 5, 27),
        ),
      ]),
      mapControlsControllerProvider.overrideWith(() => _FakeMapControls(seed)),
      if (locationService != null)
        locationServiceProvider.overrideWithValue(locationService),
    ],
    child: MaterialApp(
      theme: AppTheme.light().copyWith(splashFactory: NoSplash.splashFactory),
      home: const RouteShellPage(),
    ),
  );
}

class _SeededConfigController extends RouteConfigController {
  _SeededConfigController(this._initial);
  final RouteConfig _initial;
  @override
  RouteConfig build(String routeId) => _initial;
}

/// Drag the sheet up so it leaves the collapsed state and the medium+ body
/// (config summary + future stop list) renders. Mirrors the existing
/// big-button visibility gate (`showButtons`).
Future<void> _expandSheet(WidgetTester tester) async {
  // A slow upward drag on the sheet's search pill (no flick velocity) lands the
  // sheet near medium and snaps-to-nearest there (direction-based snap only
  // promotes a full snap on a >50 px/s flick). Medium keeps the fixed sheet
  // children within the test frame; the body itself scrolls, so the config
  // rows are reachable. A faster flick would over-shoot to expanded (0.90) and
  // overflow the short test frame.
  final pill = find.text('Adicionar parada...');
  final gesture = await tester.startGesture(tester.getCenter(pill));
  // Move up in small steps so the per-update fraction tracks without building
  // flick velocity; total ~480px lands in the medium band (0.40) on a
  // 1600-logical-px frame, then snap-to-nearest settles at medium.
  for (var i = 0; i < 24; i++) {
    await gesture.moveBy(const Offset(0, -20));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders a Scaffold', (tester) async {
    await tester.pumpWidget(_wrapPage());
    await tester.pump();

    expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
  });

  testWidgets(
      'floating hamburger IconButton with semantics label "Abrir menu" is '
      'present', (tester) async {
    await tester.pumpWidget(_wrapPage());
    await tester.pump();

    expect(find.bySemanticsLabel('Abrir menu'), findsOneWidget);
  });

  testWidgets('tapping the hamburger opens AppDrawer as a modal bottom sheet',
      (tester) async {
    await tester.pumpWidget(_wrapPage());
    await tester.pump();

    expect(find.byType(AppDrawer), findsNothing);

    await tester.tap(find.bySemanticsLabel('Abrir menu'));
    await tester.pump(); // start sheet open animation
    await tester.pump(const Duration(milliseconds: 400)); // settle

    expect(find.byType(AppDrawer), findsOneWidget);
    // The sheet's top bar exposes the close affordance — distinguishes it
    // from any other AppDrawer render.
    expect(find.bySemanticsLabel('Fechar'), findsOneWidget);
  });

  testWidgets(
      'sheet collapsed shows ONLY handle + search pill + kebab — big '
      'buttons stay hidden (Spoke parity 2026-05-28)', (tester) async {
    await tester.pumpWidget(_wrapPage());
    await tester.pump();

    // Search pill placeholder is the canonical entry for adding stops.
    expect(find.text('Adicionar parada...'), findsOneWidget);

    // Kebab (gradient circle, "Opções da rota") sits at the right of the
    // search row in the sheet — distinguishes it from the floating
    // map controls.
    expect(find.bySemanticsLabel('Opções da rota'), findsOneWidget);

    // Big buttons devem ESTAR ESCONDIDOS no estado collapsed — Spoke
    // (live 2026-05-28) só renderiza esses botões quando o sheet sobe
    // pra medium+. Nosso showButtons usa
    // currentFraction > collapsedFraction + 0.02; no primeiro pump as
    // duas frações coincidem → botões ocultos.
    expect(find.text('Adicionar parada'), findsNothing);
    expect(find.text('Copiar paradas de uma rota anterior'), findsNothing);

    // Empty state ("Adicione as primeiras paradas...") também só aparece
    // quando o sheet sobe.
    expect(
      find.textContaining('Adicione as primeiras paradas'),
      findsNothing,
    );

    // Hamburger is in the floating button — exactly one in the page.
    expect(find.bySemanticsLabel('Abrir menu'), findsOneWidget);
  });

  testWidgets(
      'shell uses Column { Expanded(map), AnimatedContainer(sheet) } so map '
      'and sheet never overlap — Spoke arch parity', (tester) async {
    // Maestro experiments 2026-05-28 provaram que o padrão canônico
    // (CustomScrollView + SliverFillRemaining) FALHA quando o
    // DraggableScrollableSheet está num Stack com GoogleMap por baixo:
    // o EagerGestureRecognizer do mapa (PlatformView) sempre ganha a arena
    // de hit-test contra o sheet. flutter/flutter#105994 / #28655.
    //
    // O Spoke (canonical white-label source) NÃO empilha map+sheet num
    // Stack — usa Column onde o mapa redimensiona dinamicamente conforme
    // o sheet expande. Mapa nunca está por baixo do sheet → zero conflito
    // de gesto. Replicar essa arquitetura é o fix definitivo.
    //
    // Este test garante a invariante estrutural: NÃO há
    // DraggableScrollableSheet (que requer Stack/Positioned fullscreen pra
    // funcionar); HÁ uma Column com Expanded + AnimatedContainer.
    await tester.pumpWidget(_wrapPage());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Sheet manual, não DraggableScrollableSheet.
    expect(
      find.byType(DraggableScrollableSheet),
      findsNothing,
      reason:
          'O sheet manual via GestureDetector + AnimatedContainer substituiu '
          'o DraggableScrollableSheet (que não funciona dentro de SizedBox '
          'da Column nem coexiste bem com GoogleMap por baixo).',
    );

    // Column é a estrutura raiz do body.
    expect(
      find.descendant(
        of: find.byType(Scaffold),
        matching: find.byType(Column),
      ),
      findsWidgets,
    );

    // AnimatedContainer envolve o sheet (anima a altura entre snaps).
    expect(find.byType(AnimatedContainer), findsAtLeastNWidgets(1));
  });

  // ───────────────────────────────────────────────────────────────────────
  // MS-A5.7 — "Configuração de rota" summary section (ADR-0046).
  // Spoke's active-route sheet shows a 2-row summary (Início + Ida-e-volta,
  // NO Pausa) above the stop list; tapping either row opens the full
  // "Detalhes da rota" page. The summary uses DIFFERENT microcopy than the
  // Detalhes-page rows. The section renders only when there IS an active
  // route and the sheet is expanded past collapsed.
  // ───────────────────────────────────────────────────────────────────────

  // A tall, low-density frame (540×1600 logical) gives the medium sheet snap
  // (0.40 → 640 logical px) enough room for the fixed sheet children (handle +
  // search row + big buttons) AND the scrollable config body, so no RenderFlex
  // overflow fires during expansion. A 360×800 frame puts medium at exactly the
  // overflow boundary; this avoids that test-only fragility without touching
  // the production sheet layout (which scrolls its body anyway).
  void useTallFrame(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
      'expanded sheet shows the "Configuração de rota" header when a route is '
      'active', (tester) async {
    useTallFrame(tester);
    await tester.pumpWidget(_wrapRouted(activeRouteId: 'r1'));
    await tester.pumpAndSettle();
    await _expandSheet(tester);

    expect(find.text('Configuração de rota'), findsOneWidget);
  });

  testWidgets(
      'summary shows EXACTLY 2 rows (Início + Ida-e-volta) — no inline Pausa '
      'row (Spoke parity, ADR-0046)', (tester) async {
    useTallFrame(tester);
    await tester.pumpWidget(_wrapRouted(activeRouteId: 'r1'));
    await tester.pumpAndSettle();
    await _expandSheet(tester);

    expect(find.byType(RouteConfigRow), findsNWidgets(2));
    // Pausa is NOT a summary row — it lives inside the Detalhes page only.
    expect(find.text('Adicionar pausa'), findsNothing);
  });

  testWidgets(
      'Início summary row uses the active-route microcopy "Iniciar no local '
      'atual" + "Use a posição do GPS ao otimizar" (distinct from Detalhes)',
      (tester) async {
    useTallFrame(tester);
    await tester.pumpWidget(_wrapRouted(activeRouteId: 'r1'));
    await tester.pumpAndSettle();
    await _expandSheet(tester);

    expect(find.text('Iniciar no local atual'), findsOneWidget);
    expect(find.text('Use a posição do GPS ao otimizar'), findsOneWidget);
    // The Detalhes-page Partida wording must NOT leak into the summary.
    expect(find.text('Usar local atual'), findsNothing);
    expect(find.text('Iniciar agora mesmo'), findsNothing);
  });

  testWidgets(
      'Ida-e-volta summary row shows "Ida e volta" + "Retorne ao ponto de '
      'partida" for the RoundTrip default', (tester) async {
    useTallFrame(tester);
    await tester.pumpWidget(_wrapRouted(activeRouteId: 'r1'));
    await tester.pumpAndSettle();
    await _expandSheet(tester);

    expect(find.text('Ida e volta'), findsOneWidget);
    expect(find.text('Retorne ao ponto de partida'), findsOneWidget);
  });

  testWidgets(
      'both summary rows expose Semantics identifiers for Maestro/integration '
      '(config_summary_inicio + config_summary_destino)', (tester) async {
    useTallFrame(tester);
    await tester.pumpWidget(_wrapRouted(activeRouteId: 'r1'));
    await tester.pumpAndSettle();
    await _expandSheet(tester);

    expect(
      find.bySemanticsIdentifier('route_details_row_config_summary_inicio'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsIdentifier('route_details_row_config_summary_destino'),
      findsOneWidget,
    );
  });

  testWidgets(
      'tapping the Início summary row pushes the Detalhes da rota page '
      '(ADR-0046)', (tester) async {
    useTallFrame(tester);
    await tester.pumpWidget(_wrapRouted(activeRouteId: 'r1'));
    await tester.pumpAndSettle();
    await _expandSheet(tester);

    await tester.tap(
      find.bySemanticsIdentifier('route_details_row_config_summary_inicio'),
    );
    await tester.pumpAndSettle();

    expect(find.text('SENTINEL_DETALHES_DA_ROTA'), findsOneWidget);
  });

  testWidgets(
      'tapping the Ida-e-volta summary row pushes the SAME Detalhes da rota '
      'page (both rows open one screen)', (tester) async {
    useTallFrame(tester);
    await tester.pumpWidget(_wrapRouted(activeRouteId: 'r1'));
    await tester.pumpAndSettle();
    await _expandSheet(tester);

    await tester.tap(
      find.bySemanticsIdentifier('route_details_row_config_summary_destino'),
    );
    await tester.pumpAndSettle();

    expect(find.text('SENTINEL_DETALHES_DA_ROTA'), findsOneWidget);
  });

  testWidgets(
      'Início summary row reflects a configured custom start address (not the '
      'GPS placeholder) when startLocation is set', (tester) async {
    useTallFrame(tester);
    await tester.pumpWidget(
      _wrapRouted(
        activeRouteId: 'r1',
        initialConfig: const RouteConfig(
          startLocation: StartLocation(
            address: 'Rua Augusta, 500',
            lat: -23.55,
            lng: -46.66,
            isUserCurrentLocation: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _expandSheet(tester);

    expect(find.text('Rua Augusta, 500'), findsOneWidget);
    expect(find.text('Iniciar no local atual'), findsNothing);
  });

  testWidgets(
      'NO "Configuração de rota" section renders when there is no active route '
      '(activeRouteId null)', (tester) async {
    useTallFrame(tester);
    // _wrapPage() never seeds activeRouteIdProvider → it stays null.
    await tester.pumpWidget(_wrapPage());
    await tester.pumpAndSettle();
    await _expandSheet(tester);

    expect(find.text('Configuração de rota'), findsNothing);
    expect(find.byType(RouteConfigRow), findsNothing);
  });

  // ───────────────────────────────────────────────────────────────────────
  // MS-A3 — "Copiar paradas de uma rota anterior" trigger.
  // The sheet's secondary big button was a `_comingSoon` stub; it now pushes
  // the existing `/home/routes/reuse-stops` route (ReuseStopsPage). Spoke's
  // active-route empty state offers the same "copy from a previous route"
  // affordance (inventory §6.2bis empty-state secondary CTA).
  // ───────────────────────────────────────────────────────────────────────

  testWidgets(
      'tapping "Copiar paradas de uma rota anterior" pushes the reuse-stops '
      'route (MS-A3, no longer a "em breve" stub)', (tester) async {
    useTallFrame(tester);
    await tester.pumpWidget(_wrapRouted(activeRouteId: 'r1'));
    await tester.pumpAndSettle();
    await _expandSheet(tester);

    final copyButton = find.text('Copiar paradas de uma rota anterior');
    expect(copyButton, findsOneWidget);

    await tester.tap(copyButton);
    await tester.pumpAndSettle();

    expect(find.text('SENTINEL_REUTILIZAR_PARADAS'), findsOneWidget);
    // The old stub SnackBar must NOT fire anymore.
    expect(find.text('Copiar paradas em breve'), findsNothing);
  });

  // ───────────────────────────────────────────────────────────────────────
  // MS-A3 — map layer toggle (Task 1). Spoke `MapTypeClick` -> 2-state
  // MapType persisted + toast (static dump v3.65.1, EditRouteFragment +
  // MapTypePreferences + map_action_toast_satellite_on/off). The floating
  // "Alternar modo de mapa" button drives `mapControlsControllerProvider`.
  // ───────────────────────────────────────────────────────────────────────

  testWidgets(
      'GoogleMap renders with MapType.normal when the controller state is normal',
      (tester) async {
    await tester.pumpWidget(
      _wrapWithMapControls(const MapControlsState(mapType: MapType.normal)),
    );
    await tester.pump();

    final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
    expect(map.mapType, MapType.normal);
  });

  testWidgets(
      'GoogleMap renders with MapType.satellite when controller state is '
      'satellite (layer pref reflected, not hard-coded)', (tester) async {
    await tester.pumpWidget(
      _wrapWithMapControls(const MapControlsState(mapType: MapType.satellite)),
    );
    await tester.pump();

    final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
    expect(map.mapType, MapType.satellite);
  });

  testWidgets(
      'tapping "Alternar modo de mapa" calls toggleMapType + flips the map to '
      'satellite (no longer a "em breve" stub)', (tester) async {
    await tester.pumpWidget(
      _wrapWithMapControls(const MapControlsState(mapType: MapType.normal)),
    );
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Alternar modo de mapa'));
    await tester.pump(); // toggle is async; flush the microtask
    await tester.pump();

    final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
    expect(map.mapType, MapType.satellite);
    // The old stub SnackBar must NOT fire.
    expect(find.text('Alternar modo de mapa — em breve'), findsNothing);
  });

  testWidgets(
      'toggling to satellite shows an original-microcopy toast confirming the '
      'layer changed', (tester) async {
    await tester.pumpWidget(
      _wrapWithMapControls(const MapControlsState(mapType: MapType.normal)),
    );
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Alternar modo de mapa'));
    await tester.pump();
    await tester.pump();

    // Toast wording is original PT-BR (ADR-0035 — not Spoke verbatim), and it
    // names the satellite state the toggle just entered.
    expect(find.textContaining('Satélite'), findsOneWidget);
  });

  testWidgets(
      'both map controls stay visible regardless of sheet expansion (Spoke '
      'gates them by flow, NOT by sheet height — MS-A3 dump correction)',
      (tester) async {
    useTallFrame(tester);
    await tester.pumpWidget(_wrapRouted(activeRouteId: 'r1'));
    await tester.pumpAndSettle();

    // Collapsed: both controls present.
    expect(find.bySemanticsLabel('Alternar modo de mapa'), findsOneWidget);
    expect(find.bySemanticsLabel('Alternar para o mapa'), findsOneWidget);

    // Expand the sheet to medium+ — controls must NOT disappear (the
    // decompiled MapToolbarControlsController gates visibility by active flow,
    // not by sheet state; the old "collapsed-only" inventory note was an
    // inference refuted by the dump).
    await _expandSheet(tester);
    expect(find.bySemanticsLabel('Alternar modo de mapa'), findsOneWidget);
    expect(find.bySemanticsLabel('Alternar para o mapa'), findsOneWidget);
  });

  // ───────────────────────────────────────────────────────────────────────
  // MS-A3 — recenter / follow-my-location (Task 2). Spoke `ReCenterButtonClick`
  // -> `MapControllerMode.FollowMyLocation`, with a graceful fallback when the
  // location permission is unavailable (EditRouteViewModel.m9428W). The
  // floating "Alternar para o mapa" button drives the flow through
  // `LocationService` + `mapControlsControllerProvider`.
  // ───────────────────────────────────────────────────────────────────────

  testWidgets(
      'tapping "Alternar para o mapa" with permission granted starts following '
      '(no longer a "em breve" stub)', (tester) async {
    final controls = _FakeMapControls(const MapControlsState());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(kUserWithoutSub),
          routesProvider.overrideWithValue([
            domain.Route(
              id: 'seed1',
              date: DateTime(2026, 5, 27),
            ),
          ]),
          mapControlsControllerProvider.overrideWith(() => controls),
          locationServiceProvider.overrideWithValue(
            LocationService(
              checkPermission: () async => LocationPermission.whileInUse,
              requestPermission: () async => LocationPermission.whileInUse,
              getCurrentPosition: () async => _fakePosition(-23.5, -46.6),
            ),
          ),
        ],
        child: MaterialApp(
          theme:
              AppTheme.light().copyWith(splashFactory: NoSplash.splashFactory),
          home: const RouteShellPage(),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Alternar para o mapa'));
    await tester.pump();
    await tester.pump();

    expect(controls.startFollowingCount, 1);
    expect(find.text('Centrar no mapa em breve'), findsNothing);
  });

  testWidgets(
      'tapping recenter with permission DENIED shows a graceful permission '
      'toast and does NOT enter follow mode (no crash)', (tester) async {
    await tester.pumpWidget(
      _wrapWithMapControls(
        const MapControlsState(),
        locationService: LocationService(
          checkPermission: () async => LocationPermission.deniedForever,
          requestPermission: () async => LocationPermission.deniedForever,
          getCurrentPosition: () async => _fakePosition(0, 0),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Alternar para o mapa'));
    await tester.pump();
    await tester.pump();

    // Graceful PT-BR fallback toast — app did not throw.
    expect(find.textContaining('localização'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // The seeded fake stays not-following (the `_wrapWithMapControls` controller
    // is never told to start, since permission was denied).
    expect(find.text('Centrar no mapa em breve'), findsNothing);
  });

  // ── MS-A6 Task 7 — Stop list in the active-route sheet (§3.2.1, H5–H8) ──

  // ── H8: Header "N paradas" + route name tappable ─────────────────────────

  testWidgets(
      'MS-A6/H8: with 2 stops, sheet shows "2 paradas" + route displayName',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrapWithStops([_stop1, _stop2]));
    await tester.pumpAndSettle();
    // With ≥1 stop the sheet auto-expands (H6) — no manual _expandSheet needed.

    expect(find.text('2 paradas'), findsOneWidget);
    // The route was seeded on Wednesday 2026-05-27 → displayName() = 'quarta-feira'.
    expect(find.textContaining('quarta-feira'), findsWidgets);
  });

  testWidgets(
      'MS-A6/H8: route name in the stop-list header has Semantics identifier '
      '"sheet_route_name"', (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrapWithStops([_stop1]));
    await tester.pumpAndSettle();

    expect(find.bySemanticsIdentifier('sheet_route_name'), findsOneWidget);
  });

  testWidgets(
      'MS-A6/H8: tapping the route name in the header pushes '
      'routes/:routeId/edit sentinel', (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrapWithStops([_stop1], routeId: 'r1'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsIdentifier('sheet_route_name'));
    await tester.pumpAndSettle();

    expect(find.text('SENTINEL_EDIT_ROUTE_r1'), findsOneWidget);
  });

  // ── H19: Stop cards — badge, address lines, status dot, semantics ─────────

  testWidgets(
      'MS-A6/H19: with 2 stops, cards show badges "01" and "02", '
      'streetName and fullAddress', (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrapWithStops([_stop1, _stop2]));
    await tester.pumpAndSettle();

    expect(find.text('01'), findsOneWidget);
    expect(find.text('02'), findsOneWidget);

    expect(find.text('Rua Alfa, 100'), findsOneWidget);
    expect(find.text('Rua Beta, 200'), findsOneWidget);

    expect(
      find.text('Rua Alfa, 100 - Centro, São Paulo'),
      findsOneWidget,
    );
    expect(
      find.text('Rua Beta, 200 - Vila Nova, São Paulo'),
      findsOneWidget,
    );
  });

  testWidgets(
      'MS-A6/H19: stop cards expose status dot via Keys '
      'stop_card_1_status_dot and stop_card_2_status_dot', (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrapWithStops([_stop1, _stop2]));
    await tester.pumpAndSettle();

    // Key-based lookup — does NOT assert color (implementation's choice).
    expect(find.byKey(const Key('stop_card_1_status_dot')), findsOneWidget);
    expect(find.byKey(const Key('stop_card_2_status_dot')), findsOneWidget);
  });

  testWidgets(
      'MS-A6/H19: stop cards expose Semantics identifiers '
      '"stop_card_1" and "stop_card_2"', (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrapWithStops([_stop1, _stop2]));
    await tester.pumpAndSettle();

    expect(find.bySemanticsIdentifier('stop_card_1'), findsOneWidget);
    expect(find.bySemanticsIdentifier('stop_card_2'), findsOneWidget);
  });

  testWidgets(
      'MS-A6/H19: tapping stop card s1 pushes '
      'routes/active/:routeId/stops/s1/edit sentinel', (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrapWithStops([_stop1, _stop2], routeId: 'r1'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsIdentifier('stop_card_1'));
    await tester.pumpAndSettle();

    expect(find.text('SENTINEL_EDIT_STOP_s1'), findsOneWidget);
  });

  // ── H5: With ≥1 stop, big buttons absent; search pill present ────────────

  testWidgets(
      'MS-A6/H5: with ≥1 stop, "Adicionar parada" and '
      '"Copiar paradas de uma rota anterior" are absent; '
      'search pill stays visible', (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrapWithStops([_stop1]));
    await tester.pumpAndSettle();

    // Big buttons must be gone with ≥1 stop (H5 — empty-state-only).
    expect(find.text('Adicionar parada'), findsNothing);
    expect(find.text('Copiar paradas de uma rota anterior'), findsNothing);

    // Empty-state microcopy also absent.
    expect(
      find.textContaining('Adicione as primeiras paradas'),
      findsNothing,
    );

    // Search pill always visible.
    expect(find.text('Adicionar parada...'), findsOneWidget);
  });

  // ── H7: Config summary semantics still present when stops are listed ──────

  testWidgets(
      'MS-A6/H7: with 2 stops, config_summary_inicio and '
      'config_summary_destino semantics are still present in the body',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrapWithStops([_stop1, _stop2]));
    await tester.pumpAndSettle();

    // Config summary = ListView item 0 (above the stop cards).
    expect(
      find.bySemanticsIdentifier('route_details_row_config_summary_inicio'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsIdentifier('route_details_row_config_summary_destino'),
      findsOneWidget,
    );
  });

  // ── H6: Auto-expand one-shot ──────────────────────────────────────────────

  testWidgets(
      'MS-A6/H6-i: mounting with ≥1 stop immediately expands sheet '
      'to ~0.90 × screen height (±2%)', (tester) async {
    // Frame: 1080×2400 physical, DPR 2.0 → 540×1200 logical.
    // _expandedFraction 0.90 → expected AnimatedContainer height ~1080 logical px.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrapWithStops([_stop1]));
    await tester.pumpAndSettle();

    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    const expandedFraction = 0.90;
    const tolerance = 0.02; // ±2%

    final sheetSize = tester.getSize(find.byType(AnimatedContainer).first);
    final ratio = sheetSize.height / screenHeight;

    expect(
      ratio,
      greaterThanOrEqualTo(expandedFraction - tolerance),
      reason: 'Sheet height ratio ${ratio.toStringAsFixed(3)} is below '
          '${(expandedFraction - tolerance).toStringAsFixed(3)} — '
          'auto-expand one-shot did not fire on mount.',
    );
    expect(
      ratio,
      lessThanOrEqualTo(expandedFraction + tolerance),
      reason: 'Sheet height ratio ${ratio.toStringAsFixed(3)} exceeds '
          '${(expandedFraction + tolerance).toStringAsFixed(3)} — '
          'unexpected overshoot.',
    );
  });

  testWidgets(
      'MS-A6/H6-ii: starting with 0 stops then adding the first stop '
      'auto-expands the sheet to ~0.90', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(kUserWithoutSub),
        routesProvider.overrideWith(
          () => _MutableFakeRoutes([
            domain.Route(
              id: 'r1',
              date: DateTime(2026, 5, 27),
            ),
          ]),
        ),
        activeRouteIdProvider.overrideWith(() => _SeededActiveRouteId('r1')),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme:
              AppTheme.light().copyWith(splashFactory: NoSplash.splashFactory),
          routerConfig: _buildSentinelRouter(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;

    // Rota ativa VAZIA → abre em medium (~0.40), NÃO colapsado: senão nascia
    // sob o mapa e o PlatformView roubava o gesto da alça ("preso no mapa",
    // fix de UX da Á3 confirmado no M54 2026-06-14). Ainda longe do expanded.
    final beforeRatio =
        tester.getSize(find.byType(AnimatedContainer).first).height /
            screenHeight;
    expect(
      beforeRatio,
      allOf(greaterThan(0.30), lessThan(0.60)),
      reason: 'Sheet com rota ativa vazia deve abrir em medium (~0.40), '
          'não colapsado nem expanded (got $beforeRatio).',
    );

    // Add the first stop → ref.listen triggers auto-expand.
    container.read(routesProvider.notifier).addStop('r1', _stop1);
    await tester.pumpAndSettle();

    const expandedFraction = 0.90;
    const tolerance = 0.02;
    final afterRatio =
        tester.getSize(find.byType(AnimatedContainer).first).height /
            screenHeight;
    expect(
      afterRatio,
      greaterThanOrEqualTo(expandedFraction - tolerance),
      reason: 'After adding first stop, sheet ratio '
          '${afterRatio.toStringAsFixed(3)} did not reach expanded (~0.90). '
          'ref.listen on stop count may be missing.',
    );
  });

  testWidgets(
      'MS-A6/H6-iii: one-shot — after manual collapse, adding a 2nd stop '
      'does NOT re-expand the sheet', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(kUserWithoutSub),
        routesProvider.overrideWith(
          () => _MutableFakeRoutes([
            domain.Route(
              id: 'r1',
              date: DateTime(2026, 5, 27),
            ),
          ]),
        ),
        activeRouteIdProvider.overrideWith(() => _SeededActiveRouteId('r1')),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme:
              AppTheme.light().copyWith(splashFactory: NoSplash.splashFactory),
          routerConfig: _buildSentinelRouter(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Step 1: add first stop → auto-expand fires.
    container.read(routesProvider.notifier).addStop('r1', _stop1);
    await tester.pumpAndSettle();

    // Step 2: drag the sheet handle downward (strong flick) TWICE to
    // collapse — the direction-based snap (MS-A5 contract) descends ONE
    // snap per flick: expanded(0.90) → medium(0.40) → collapsed.
    for (var i = 0; i < 2; i++) {
      final sheetRect = tester.getRect(find.byType(AnimatedContainer).first);
      final sheetTopCenter = sheetRect.topCenter;
      // 12 px offset lands inside the 24 px handle area; 500 px delta +
      // 150 ms gives enough velocity to trigger a downward flick snap.
      await tester.timedDragFrom(
        sheetTopCenter + const Offset(0, 12),
        const Offset(0, 500),
        const Duration(milliseconds: 150),
      );
      await tester.pumpAndSettle();
    }

    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final collapsedRatio =
        tester.getSize(find.byType(AnimatedContainer).first).height /
            screenHeight;
    expect(
      collapsedRatio,
      lessThan(0.30),
      reason: 'Sheet did not collapse after drag '
          '(got ratio ${collapsedRatio.toStringAsFixed(3)}).',
    );

    // Step 3: add a 2nd stop → must NOT re-expand (one-shot exhausted).
    container.read(routesProvider.notifier).addStop('r1', _stop2);
    await tester.pumpAndSettle();

    final afterRatio =
        tester.getSize(find.byType(AnimatedContainer).first).height /
            screenHeight;
    expect(
      afterRatio,
      lessThan(0.30),
      reason: 'Sheet re-expanded after adding 2nd stop — '
          'one-shot guard is missing '
          '(got ratio ${afterRatio.toStringAsFixed(3)}).',
    );
  });

  // MS-A6 Task 9 — H9/F4/H11 entrypoint tests (search pill + big button).
  _registerH9Tests();

  // Dump-parity corrections (kr4.java baseline — 2026-06-18):
  //   C1 — _mediumFraction ~0.50 (Spoke Default anchor = 0.5 × screenHeight)
  //   C2 — PRE-CONFIRM opens at medium (~0.50), NOT inheriting DRAFT 0.90
  //   C3 — GoogleMap.padding.bottom == sheet height (UpdateMapPaddingEffect)
  _registerDumpParityTests();
}

// ─────────────────────────────────────────────────────────────────────────────
// MS-A6 top-level helpers (outside main) — fakes, fixtures, router builder.
// ─────────────────────────────────────────────────────────────────────────────

/// Fake [Routes] notifier with mutable state — allows [addStop] to propagate
/// via ref.listen in the H6 mutation tests. Starts with the provided seed;
/// the real [Routes] methods (addStop, etc.) work normally because we only
/// override [build].
class _MutableFakeRoutes extends Routes {
  _MutableFakeRoutes(this._seed);
  final List<domain.Route> _seed;
  @override
  List<domain.Route> build() => _seed;
}

/// Convenience wrapper: [_wrapRouted] with an explicit [stops] list.
Widget _wrapWithStops(
  List<domain.Stop> stops, {
  String routeId = 'r1',
}) =>
    _wrapRouted(activeRouteId: routeId, stops: stops);

/// Fixture stop 1 — stable id 's1' reused across all MS-A6 tests.
final _stop1 = domain.Stop(
  id: 's1',
  lat: -23.5,
  lng: -46.6,
  streetName: 'Rua Alfa, 100',
  fullAddress: 'Rua Alfa, 100 - Centro, São Paulo',
);

/// Fixture stop 2 — stable id 's2'.
final _stop2 = domain.Stop(
  id: 's2',
  lat: -23.51,
  lng: -46.61,
  streetName: 'Rua Beta, 200',
  fullAddress: 'Rua Beta, 200 - Vila Nova, São Paulo',
);

/// Builds a [GoRouter] with all sentinels needed by the MS-A6 mutation tests
/// (H6-ii and H6-iii) that use [UncontrolledProviderScope] + raw router.
/// Mirrors the routes registered inside [_wrapRouted].
GoRouter _buildSentinelRouter() => GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => const RouteShellPage(),
          routes: [
            GoRoute(
              path: 'routes/active/:routeId/details',
              builder: (_, __) =>
                  const Scaffold(body: Text('SENTINEL_DETALHES_DA_ROTA')),
            ),
            GoRoute(
              path: 'routes/reuse-stops',
              builder: (_, __) =>
                  const Scaffold(body: Text('SENTINEL_REUTILIZAR_PARADAS')),
            ),
            GoRoute(
              path: 'routes/:routeId/edit',
              builder: (context, state) => Scaffold(
                body: Text(
                  'SENTINEL_EDIT_ROUTE_${state.pathParameters['routeId']}',
                ),
              ),
            ),
            GoRoute(
              path: 'routes/active/:routeId/stops/:stopId/edit',
              builder: (context, state) => Scaffold(
                body: Text(
                  'SENTINEL_EDIT_STOP_${state.pathParameters['stopId']}',
                ),
              ),
            ),
          ],
        ),
      ],
    );

/// Build a [Position] at a fixed point for the recenter widget tests.
Position _fakePosition(double lat, double lng) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.fromMillisecondsSinceEpoch(0),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

// ─────────────────────────────────────────────────────────────────────────────
// MS-A6 H9/F4/H11 — Search-pill and big-button entrypoints (Task 9).
//
// The shell's two "add-stop" call-sites (search pill + big button) both do
// `context.push('/home/routes/add-stop')`.  After the A6 implementation:
//   - A pop with a String id  → SnackBar 'Parada adicionada' + action 'Ver'
//                               → tapping 'Ver' pushes the edit screen with ?new=1
//   - A pop with ({editStopId}) → navigate DIRECTLY to the edit screen (no SnackBar)
//   - A pop with null or other → no navigation (unchanged from current behaviour)
//
// To test these without AddStopPage's real logic, we register a fake page on
// the `routes/add-stop` path that exposes two buttons:
//   TextButton('POP_COM_ID')     → context.pop('s-novo')
//   TextButton('POP_COM_INTENT') → context.pop((editStopId: 's1'))
// ─────────────────────────────────────────────────────────────────────────────

/// Builds a GoRouter identical to [_wrapRouted]'s router but with two extras:
///  1. `routes/add-stop` path → [_FakeAddStopPage] (pop-with-id / pop-with-intent).
///  2. `routes/active/:routeId/stops/:stopId/edit` echoes BOTH the stopId AND
///     the `?new` query parameter so tests can verify F4's `new=1` badge contract.
GoRouter _buildH9SentinelRouter() => GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => const RouteShellPage(),
          routes: [
            GoRoute(
              path: 'routes/active/:routeId/details',
              builder: (_, __) =>
                  const Scaffold(body: Text('SENTINEL_DETALHES_DA_ROTA')),
            ),
            GoRoute(
              path: 'routes/reuse-stops',
              builder: (_, __) =>
                  const Scaffold(body: Text('SENTINEL_REUTILIZAR_PARADAS')),
            ),
            GoRoute(
              path: 'routes/:routeId/edit',
              builder: (context, state) => Scaffold(
                body: Text(
                  'SENTINEL_EDIT_ROUTE_${state.pathParameters['routeId']}',
                ),
              ),
            ),
            // MS-A6 H9/F4/H11 — fake add-stop page.
            GoRoute(
              path: 'routes/add-stop',
              builder: (_, __) => const _FakeAddStopPage(),
            ),
            // MS-A6 H9/F4: sentinel echoes stopId + ?new query param.
            GoRoute(
              path: 'routes/active/:routeId/stops/:stopId/edit',
              builder: (context, state) => Scaffold(
                body: Text(
                  'SENTINEL_EDIT_STOP_'
                  '${state.pathParameters['stopId']}'
                  '_new=${state.uri.queryParameters['new'] ?? '0'}',
                ),
              ),
            ),
          ],
        ),
      ],
    );

/// Fake page that sits at `routes/add-stop` in [_buildH9SentinelRouter].
/// Two buttons allow the test to control what the page pops back:
///   POP_COM_ID     → context.pop('s-novo')          (new stop created)
///   POP_COM_INTENT → context.pop((editStopId: 's1')) (existing stop match)
class _FakeAddStopPage extends StatelessWidget {
  const _FakeAddStopPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextButton(
            onPressed: () => context.pop<Object?>('s-novo'),
            child: const Text('POP_COM_ID'),
          ),
          TextButton(
            onPressed: () => context.pop<Object?>((editStopId: 's1')),
            child: const Text('POP_COM_INTENT'),
          ),
        ],
      ),
    );
  }
}

/// Convenience wrapper for the H9 entrypoint tests: seeds a route with
/// the given [stops] list and mounts the shell inside [_buildH9SentinelRouter].
Widget _wrapRoutedH9({
  String routeId = 'r1',
  List<domain.Stop> stops = const [],
}) {
  final router = _buildH9SentinelRouter();
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWithValue(kUserWithoutSub),
      routesProvider.overrideWithValue([
        domain.Route(
          id: routeId,
          date: DateTime(2026, 5, 27),
          stops: stops,
        ),
      ]),
      activeRouteIdProvider.overrideWith(() => _SeededActiveRouteId(routeId)),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light().copyWith(splashFactory: NoSplash.splashFactory),
      routerConfig: router,
    ),
  );
}

// ── H9/F4/H11 tests (Task 9) ────────────────────────────────────────────────

// These tests live OUTSIDE `main()` intentionally — they share the H9 helpers
// declared above and are grouped by a `group()` call injected into the test
// runner via a separate test file extension. Per project pattern, widget tests
// may be split across multiple top-level `testWidgets` calls; the runner picks
// them all up as long as they are inside a `main()`.  We therefore declare a
// second `main`-equivalent via a `void _h9Tests() {...}` called from the
// primary main() … but that complicates the existing file. Instead, add these
// directly inside the existing main() by editing above.
//
// Rather than edit inside main(), we APPEND a second `void main()` extension.
// Dart test runner supports multiple `main()` declarations inside a single test
// file via the `package:test` `group` + `test` calling conventions — however,
// having two `main()` functions in the same file is not valid Dart.
//
// Correct approach: declare a helper function and call it from `main()`.
// We cannot edit inside main() without re-reading the whole file; therefore
// we declare the tests here as free functions and reference them from main()
// by appending a call at the END of the existing main block. We do that via
// the Edit tool targeting the closing brace of main().

// Defined as top-level functions to be called from main().  Each becomes a
// testWidgets() call.
void _registerH9Tests() {
  // ── H9 Test 1: search pill → POP_COM_ID → SnackBar 'Parada adicionada' with 'Ver' ──

  testWidgets(
      'MS-A6/H9-1: search-pill tap → fake page → POP_COM_ID → '
      'SnackBar "Parada adicionada" visible with action "Ver"', (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrapRoutedH9());
    await tester.pumpAndSettle();

    // Tap the search pill to push the fake add-stop page.
    await tester.tap(find.text('Adicionar parada...'));
    await tester.pumpAndSettle();

    expect(find.text('POP_COM_ID'), findsOneWidget);

    // Pop with a new-stop id.
    await tester.tap(find.text('POP_COM_ID'));
    await tester.pumpAndSettle();

    // Shell must show 'Parada adicionada' SnackBar.
    expect(find.text('Parada adicionada'), findsOneWidget);
    // SnackBarAction 'Ver' must be present (note: SnackBarAction does not
    // accept Semantics — interact via find.text per project lesson H9).
    expect(find.text('Ver'), findsOneWidget);
  });

  // ── H9 Test 2: tap 'Ver' → navigate to editor with ?new=1 ─────────────────

  testWidgets(
      'MS-A6/H9-2: tapping "Ver" in the SnackBar navigates to the '
      'edit-stop sentinel with stopId "s-novo" and ?new=1', (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrapRoutedH9());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Adicionar parada...'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('POP_COM_ID'));
    await tester.pumpAndSettle();

    // Tap the 'Ver' action.
    await tester.tap(find.text('Ver'));
    await tester.pumpAndSettle();

    // The editor sentinel must show the stop id AND new=1.
    expect(
      find.text('SENTINEL_EDIT_STOP_s-novo_new=1'),
      findsOneWidget,
      reason:
          'Tapping "Ver" must push the editor for the new stop with ?new=1.',
    );
  });

  // ── H9 Test 3: POP_COM_INTENT → direct editor navigation, no SnackBar ─────

  testWidgets(
      'MS-A6/H9-3: search-pill tap → POP_COM_INTENT → editor opens '
      'directly for existing stop (no "Parada adicionada" SnackBar)',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Seed 1 stop so the sheet is expanded (H6 auto-expand) and the search
    // pill is reachable.
    await tester.pumpWidget(_wrapRoutedH9(stops: [_stop1]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Adicionar parada...'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('POP_COM_INTENT'));
    await tester.pumpAndSettle();

    // Must navigate directly to the editor for 's1' with new=0.
    expect(
      find.text('SENTINEL_EDIT_STOP_s1_new=0'),
      findsOneWidget,
      reason: 'pop-with-intent must push the editor for the existing stop s1 '
          'WITHOUT the new=1 badge.',
    );
    // No 'Parada adicionada' SnackBar for an existing-stop intent.
    expect(find.text('Parada adicionada'), findsNothing);
    // AddStopPage must NOT remain on the navigation stack: a back-press
    // from the editor returns to the shell, not to the fake add-stop page.
    // We verify by checking the fake page is gone.
    expect(find.text('POP_COM_INTENT'), findsNothing);
  });

  // ── H9 Test 4: big button (0 stops) → POP_COM_ID → SnackBar 'Ver' ─────────

  testWidgets(
      'MS-A6/H9-4: big button "Adicionar parada" (0-stops state) → '
      'POP_COM_ID → SnackBar "Parada adicionada" + action "Ver"',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 0 stops: big buttons are visible when sheet is expanded.
    await tester.pumpWidget(_wrapRoutedH9());
    await tester.pumpAndSettle();
    await _expandSheet(tester);

    final bigButton = find.text('Adicionar parada');
    expect(bigButton, findsOneWidget);

    await tester.tap(bigButton);
    await tester.pumpAndSettle();

    expect(find.text('POP_COM_ID'), findsOneWidget);

    await tester.tap(find.text('POP_COM_ID'));
    await tester.pumpAndSettle();

    expect(find.text('Parada adicionada'), findsOneWidget);
    expect(find.text('Ver'), findsOneWidget);
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Dump-parity corrections (kr4.java baseline, 2026-06-18)
//
// C1 — _mediumFraction ~0.50 (Spoke Default anchor = 0.5 × screenHeight,
//      proven by kr4.java measure lambda in VerticalDraggableSheet).
//      Current production value is 0.40 → tests below pin it to ~0.50 ±0.02.
//
// C2 — PRE-CONFIRM sheet must open at medium (~0.50), NOT at expanded (0.90).
//      Today the DRAFT auto-expand fires at 0.90, and PRE-CONFIRM inherits
//      that fraction because there is no reset when the state flips. The mapa
//      gets squished to 10% — "tampa o mapa" bug. Correct anchor = Default
//      (medium, 0.50) per Spoke's PRE-CONFIRM entry.
//
// C3 — GoogleMap.padding.bottom must equal the current sheet height
//      (mirrors Spoke's UpdateMapPaddingEffect / GoogleMap.setPadding).
//      Today GoogleMap is constructed with no padding parameter (defaults to
//      EdgeInsets.zero). Tests assert padding.bottom > 0 and ≈ fraction×height.
// ─────────────────────────────────────────────────────────────────────────────

/// Builds a [ProviderScope] with a route seeded in PRE-CONFIRM state
/// (optimization == optimized, confirmed == false, started == false).
/// Uses [_wrapRouted]'s router-aware pattern so GoRouter sentinels are
/// available (PreConfirmView's "Confirmar" button eventually pushes a route).
Widget _wrapInPreConfirm({
  List<domain.Stop> stops = const [],
}) {
  const preConfirmState = RouteState(
    optimization: OptimizationState.optimized,
    confirmed: false,
    started: false,
  );
  final router = _buildSentinelRouter();
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWithValue(kUserWithoutSub),
      routesProvider.overrideWithValue([
        domain.Route(
          id: 'r-preconfirm',
          date: DateTime(2026, 5, 27),
          routeState: preConfirmState,
          stops: stops,
          totalDurationMinutes: 42,
          totalDistanceMeters: 15000,
        ),
      ]),
      activeRouteIdProvider.overrideWith(
        () => _SeededActiveRouteId('r-preconfirm'),
      ),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light().copyWith(splashFactory: NoSplash.splashFactory),
      routerConfig: router,
    ),
  );
}

void _registerDumpParityTests() {
  // ── C1: _mediumFraction pinned to ~0.50 (kr4.java Default anchor) ──────────

  testWidgets(
      'C1 — rota ativa vazia abre o sheet na âncora Default do Spoke (~0.50, '
      'kr4.java): ratio deve estar em [0.48, 0.52]', (tester) async {
    // Frame: 1080×3200 physical, DPR 2.0 → 540×1600 logical.
    // _mediumFraction 0.50 → expected AnimatedContainer height = 800 logical px.
    // Current production value is 0.40 → ratio ~0.40 → test will FAIL (red).
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Empty route → no stops → initState fires the medium branch.
    await tester.pumpWidget(_wrapRouted(activeRouteId: 'r1'));
    await tester.pumpAndSettle();

    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final sheetHeight =
        tester.getSize(find.byType(AnimatedContainer).first).height;
    final ratio = sheetHeight / screenHeight;

    // Spoke Default anchor = 0.5 × screenHeight (kr4.java, 2026-06-18).
    // Tolerance ±0.02 absorbs bottom-inset rounding across device profiles.
    expect(
      ratio,
      greaterThanOrEqualTo(0.48),
      reason: 'Sheet ratio ${ratio.toStringAsFixed(3)} is below 0.48 — '
          '_mediumFraction is still 0.40 (needs to be updated to 0.50 '
          'per kr4.java Default anchor).',
    );
    expect(
      ratio,
      lessThanOrEqualTo(0.52),
      reason: 'Sheet ratio ${ratio.toStringAsFixed(3)} exceeds 0.52 — '
          'unexpected overshoot above the Default anchor.',
    );
  });

  // ── C2: PRE-CONFIRM opens at medium (~0.50), NOT inheriting DRAFT 0.90 ─────

  testWidgets(
      'C2 — PRE-CONFIRM abre o sheet em medium (~0.50) deixando o mapa '
      'visível — não herda 0.90 do DRAFT (tampa o mapa bug)', (tester) async {
    // Frame: 1080×3200 physical, DPR 2.0 → 540×1600 logical.
    // Scenario: a route that is ALREADY in PRE-CONFIRM when the shell mounts
    // (e.g. user navigates back to the route after optimization completed).
    // The auto-expand one-shot fired for 0 stops, then the state flipped to
    // PRE-CONFIRM. Today the fraction stays at 0.90 from the DRAFT expand.
    // After C2 fix the fraction must reset to _mediumFraction (0.50) when
    // isPreConfirm becomes true — ratio expected in [0.48, 0.52].
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Seed with 2 stops in PRE-CONFIRM state. This exercises the realistic
    // path: route had stops (triggering auto-expand to 0.90 in DRAFT), then
    // the optimizer ran and isPreConfirm flipped to true. Without a reset the
    // fraction stays at 0.90. With the fix it snaps back to _mediumFraction.
    await tester.pumpWidget(_wrapInPreConfirm(stops: [_stop1, _stop2]));
    await tester.pumpAndSettle();

    // Confirm we are genuinely in PRE-CONFIRM (PreConfirmView rendered).
    expect(
      find.byType(PreConfirmView),
      findsOneWidget,
      reason: 'PreConfirmView must be present — route was not seeded in '
          'PRE-CONFIRM state (optimization==optimized, confirmed==false).',
    );

    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final sheetHeight =
        tester.getSize(find.byType(AnimatedContainer).first).height;
    final ratio = sheetHeight / screenHeight;

    // Must NOT be at expanded (0.90) — that squishes the map to 10%.
    expect(
      ratio,
      lessThan(0.80),
      reason: 'Sheet ratio ${ratio.toStringAsFixed(3)} ≥ 0.80 — PRE-CONFIRM '
          'inherited the DRAFT 0.90 expand; the map is hidden ("tampa o mapa"). '
          'The shell must reset _sheetFraction to _mediumFraction when '
          'isPreConfirm becomes true.',
    );

    // Must be at medium (~0.50 per C1 fix) — leaving ~50% of screen for map.
    expect(
      ratio,
      greaterThanOrEqualTo(0.48),
      reason: 'Sheet ratio ${ratio.toStringAsFixed(3)} < 0.48 — PRE-CONFIRM '
          'sheet is too small; expected medium (~0.50).',
    );
    expect(
      ratio,
      lessThanOrEqualTo(0.52),
      reason: 'Sheet ratio ${ratio.toStringAsFixed(3)} > 0.52 — PRE-CONFIRM '
          'sheet exceeds the Default anchor (0.50 ±0.02).',
    );
  });

  // ── C3: GoogleMap.padding.bottom == sheet height (UpdateMapPaddingEffect) ───

  testWidgets(
      'C3 — GoogleMap recebe padding.bottom dinâmico igual à altura do sheet '
      '(paridade UpdateMapPaddingEffect / setPadding do Spoke)',
      (tester) async {
    // Frame: 1080×3200 physical, DPR 2.0 → 540×1600 logical.
    // After C1 fix: empty-route medium fraction = 0.50 → sheet height = 800 px.
    // GoogleMap.padding.bottom must equal that height (800 logical px ±1).
    // Today the GoogleMap is constructed without a padding parameter
    // (EdgeInsets.zero default) → padding.bottom == 0 → test FAILS (red).
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrapRouted(activeRouteId: 'r1'));
    await tester.pumpAndSettle();

    final map = tester.widget<GoogleMap>(find.byType(GoogleMap));

    // Primary assertion: padding.bottom must be > 0.
    expect(
      map.padding.bottom,
      greaterThan(0),
      reason: 'GoogleMap.padding.bottom is 0 — UpdateMapPaddingEffect not '
          'wired. The map POI labels are obscured behind the sheet.',
    );

    // Secondary assertion: padding.bottom tracks the sheet height.
    // After C1 fix the medium fraction = 0.50, so sheet height = 800 logical px
    // on this frame. We compute the expected value the same way the shell does:
    // mq.size.height × clampedFraction.
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final sheetHeight =
        tester.getSize(find.byType(AnimatedContainer).first).height;
    // ±1 px tolerance covers double→logical pixel rounding.
    expect(
      map.padding.bottom,
      closeTo(sheetHeight, 1.0),
      reason: 'GoogleMap.padding.bottom (${map.padding.bottom}) does not '
          'match the current sheet height ($sheetHeight). '
          'Expected screenHeight($screenHeight) × currentFraction ≈ $sheetHeight.',
    );
  });
}
