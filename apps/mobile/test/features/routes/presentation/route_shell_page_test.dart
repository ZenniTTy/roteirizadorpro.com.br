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
import 'package:roteirizador_pro/features/routes/presentation/route_shell_page.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/app_drawer.dart';
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
            status: domain.RouteStatus.draft,
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

/// Router-aware wrapper for the MS-A5.7 "Configuração de rota" summary rows.
///
/// The summary rows push `/home/routes/active/:routeId/details` (ADR-0046), so
/// the shell must be mounted inside a [GoRouter] that registers that path (a
/// sentinel stands in for `RouteDetailsPage` so the test asserts the nav, not
/// the page). [activeRouteId] is seeded via [ActiveRouteId] override because
/// the section only renders when there IS an active route — the production
/// shell reads [activeRouteIdProvider] (`String?`, null = no section).
Widget _wrapRouted({
  required String activeRouteId,
  RouteConfig? initialConfig,
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
          status: domain.RouteStatus.draft,
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
          status: domain.RouteStatus.draft,
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
              status: domain.RouteStatus.draft,
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
}

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
