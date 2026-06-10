import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:roteirizador_pro/features/route_config/domain/route_config.dart';
import 'package:roteirizador_pro/features/route_config/presentation/pages/break_scheduler_page.dart';
import 'package:roteirizador_pro/features/route_config/presentation/pages/route_details_page.dart';
import 'package:roteirizador_pro/features/route_config/presentation/widgets/destination_picker_sheet.dart';
import 'package:roteirizador_pro/features/route_config/presentation/widgets/route_config_row.dart';
import 'package:roteirizador_pro/features/route_config/presentation/widgets/route_details_section.dart';
import 'package:roteirizador_pro/features/route_config/state/route_config_controller.dart';

GoRouter _router(Widget home) => GoRouter(
      initialLocation: '/home/routes/active/r1/details',
      routes: [
        GoRoute(
          // Mount RouteDetailsPage at the real path so its sub-picker pushes
          // (`.../details/break-scheduler`, ADR-0044) resolve in-harness.
          path: '/home/routes/active/:routeId/details',
          builder: (_, __) => home,
          routes: [
            GoRoute(
              path: 'break-scheduler',
              builder: (_, __) => const BreakSchedulerPage(),
            ),
          ],
        ),
      ],
    );

Widget _wrap({
  required String routeId,
  RouteConfig? initialConfig,
  bool? validOverride,
}) {
  final router = _router(RouteDetailsPage(routeId: routeId));
  return ProviderScope(
    overrides: [
      if (initialConfig != null)
        routeConfigControllerProvider(routeId)
            .overrideWith(() => _TestController(initialConfig)),
      if (validOverride != null)
        isRouteConfigValidProvider(routeId)
            .overrideWith((ref) => validOverride),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

class _TestController extends RouteConfigController {
  _TestController(this._initial);
  final RouteConfig _initial;
  @override
  RouteConfig build(String routeId) => _initial;
}

void main() {
  // Use a tall enough device frame so the Concluído button + the bottom
  // checkbox are visible without scrolling — keeps every assertion below
  // independent of scroll/visibility plumbing.
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('renders body title "Detalhes da rota" (no AppBar)',
      (tester) async {
    await tester.pumpWidget(_wrap(routeId: 'r1'));
    await tester.pumpAndSettle();

    expect(find.text('Detalhes da rota'), findsOneWidget);
    // Spoke renders no AppBar — the title is body content.
    expect(find.byType(AppBar), findsNothing);
  });

  testWidgets(
      'close X icon present with Semantics identifier '
      '"route_details_close"', (tester) async {
    await tester.pumpWidget(_wrap(routeId: 'r1'));
    await tester.pumpAndSettle();

    expect(find.byIcon(LucideIcons.x), findsOneWidget);
    expect(
      find.bySemanticsIdentifier('route_details_close'),
      findsOneWidget,
    );
  });

  testWidgets(
      'Concluído renders as full-width FilledButton (not AppBar action)',
      (tester) async {
    await tester.pumpWidget(_wrap(routeId: 'r1', validOverride: true));
    await tester.pumpAndSettle();

    expect(find.byType(TextButton), findsNothing);
    expect(
      find.ancestor(
        of: find.text('Concluído'),
        matching: find.byType(FilledButton),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'Concluído is ALWAYS enabled — Spoke never gates it on time validity '
      '(live capture 2026-06-03, EVIDENCE.md §S2)', (tester) async {
    // Spoke renders Concluído tappable even with neither time set, so the
    // common path (accept "Iniciar agora mesmo" + "Ida e volta" defaults) is
    // one tap. validOverride:false would have disabled it under the OLD gate;
    // it must now stay enabled. Solver-window validation lives in the domain
    // (isRouteConfigValidProvider / RouteConfig.isValid), not this button.
    await tester.pumpWidget(_wrap(routeId: 'r1', validOverride: false));
    await tester.pumpAndSettle();

    final btn = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Concluído'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(btn.onPressed, isNotNull);
  });

  testWidgets('Concluído stays enabled on a freshly-opened (empty) config too',
      (tester) async {
    // RouteConfig.empty() ships both times null → the OLD gate disabled the
    // button on first open. Pin the Spoke-correct always-enabled behavior.
    await tester.pumpWidget(_wrap(routeId: 'r1'));
    await tester.pumpAndSettle();

    final btn = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Concluído'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(btn.onPressed, isNotNull);
  });

  testWidgets('Tapping Concluído pops back to the sender route (N6)',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/details',
      routes: [
        GoRoute(
          path: '/sender',
          builder: (_, __) => const Scaffold(body: Text('SENDER')),
        ),
        GoRoute(
          path: '/details',
          builder: (_, __) => const RouteDetailsPage(routeId: 'r1'),
        ),
      ],
    );
    // Seed a back-stack so pop has somewhere to land.
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();
    router.push('/details');
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsIdentifier('route_details_confirm'));
    await tester.pumpAndSettle();

    // Popped one level — still on a /details (the seeded one), not crashed.
    expect(tester.takeException(), isNull);
    expect(find.byType(RouteDetailsPage), findsOneWidget);
  });

  testWidgets('Tapping the close-X pops the route (N6)', (tester) async {
    final router = GoRouter(
      initialLocation: '/details',
      routes: [
        GoRoute(
          path: '/details',
          builder: (_, __) => const RouteDetailsPage(routeId: 'r1'),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();
    router.push('/details');
    await tester.pumpAndSettle();
    expect(find.byType(RouteDetailsPage), findsWidgets);

    await tester.tap(find.bySemanticsIdentifier('route_details_close'));
    await tester.pumpAndSettle();

    // The pushed copy popped; the initial /details remains, no crash.
    expect(tester.takeException(), isNull);
    expect(find.byType(RouteDetailsPage), findsOneWidget);
  });

  testWidgets('Concluído has Semantics identifier "route_details_confirm"',
      (tester) async {
    await tester.pumpWidget(_wrap(routeId: 'r1'));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsIdentifier('route_details_confirm'),
      findsOneWidget,
    );
  });

  testWidgets('renders 3 RouteDetailsSection in order Partida/Destino/Pausa',
      (tester) async {
    await tester.pumpWidget(_wrap(routeId: 'r1'));
    await tester.pumpAndSettle();

    expect(find.byType(RouteDetailsSection), findsNWidgets(3));
    expect(find.text('Partida'), findsOneWidget);
    // Section title only — the row label is "Ida e volta", not "Destino".
    expect(find.text('Destino'), findsOneWidget);
    // Section title is singular per Spoke: "Pausa", not "Pausas".
    expect(find.text('Pausa'), findsOneWidget);
  });

  testWidgets(
      'Partida row 1 primary label is "Usar local atual" (no '
      '"Local de início" 2-column layout)', (tester) async {
    await tester.pumpWidget(_wrap(routeId: 'r1'));
    await tester.pumpAndSettle();

    expect(find.text('Usar local atual'), findsOneWidget);
    expect(find.text('Local de início'), findsNothing);
  });

  testWidgets(
      'Partida row 2 label collapses to "HH:MM" when timeStart is configured '
      '(Spoke parity: no "Iniciar agora mesmo" prefix once a time is set)',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        routeId: 'r1',
        initialConfig: const RouteConfig(
          timeStart: TimeStart(time: TimeOfDay(hour: 8, minute: 0)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verified live in /tmp/spoke-a5-inspection/ms4-live-detalhes-final.xml:
    // row contains a single TextView with text="10:30" — no prefix.
    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('Iniciar agora mesmo  08:00'), findsNothing);
    expect(find.text('Iniciar agora mesmo'), findsNothing);
    // Old MS3 label gone.
    expect(find.text('Início'), findsNothing);
  });

  testWidgets(
      'Partida row 2 label is "Iniciar agora mesmo" when timeStart is null '
      '(Spoke parity: placeholder phrase before any time is set)',
      (tester) async {
    await tester.pumpWidget(_wrap(routeId: 'r1'));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar agora mesmo'), findsOneWidget);
    expect(find.text('Início'), findsNothing);
    // Spoke renders a live wall-clock alongside the label while unconfigured
    // (EVIDENCE.md §S1). The page mounts a LiveClockLabel on this row.
    expect(
      find.descendant(
        of: find.bySemanticsIdentifier('route_details_row_partida_inicio'),
        matching: find.byType(LiveClockLabel),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'Partida row 2 has NO LiveClockLabel once timeStart is set '
      '(Spoke collapse to lone HH:MM)', (tester) async {
    const config =
        RouteConfig(timeStart: TimeStart(time: TimeOfDay(hour: 8, minute: 0)));
    await tester.pumpWidget(_wrap(routeId: 'r1', initialConfig: config));
    await tester.pumpAndSettle();

    expect(find.byType(LiveClockLabel), findsNothing);
    expect(find.text('08:00'), findsOneWidget);
  });

  testWidgets('Destino row 1 default label is "Ida e volta" (Spoke default)',
      (tester) async {
    // No destination set ⇒ Spoke shows "Ida e volta" as the default mode.
    await tester.pumpWidget(_wrap(routeId: 'r1'));
    await tester.pumpAndSettle();

    expect(find.text('Ida e volta'), findsOneWidget);
    // Old default gone.
    expect(find.text('Voltar ao local de início'), findsNothing);
  });

  testWidgets(
      'Destino row 1 has subtitle "Viagem de ida e volta a partir do '
      'local atual" when default', (tester) async {
    await tester.pumpWidget(_wrap(routeId: 'r1'));
    await tester.pumpAndSettle();

    expect(
      find.text('Viagem de ida e volta a partir do local atual'),
      findsOneWidget,
    );
  });

  testWidgets(
      'Destino has a second row "Definir horário de término" when '
      'timeEnd is null', (tester) async {
    await tester.pumpWidget(_wrap(routeId: 'r1'));
    await tester.pumpAndSettle();

    expect(find.text('Definir horário de término'), findsOneWidget);
    expect(
      find.bySemanticsIdentifier('route_details_row_destino_horario_termino'),
      findsOneWidget,
    );
  });

  testWidgets(
      'Destino NoDestination() renders "Nenhum destino" with the flag icon '
      'and NO subtitle (Spoke parity, single-line row)', (tester) async {
    const config = RouteConfig(destination: NoDestination());
    await tester.pumpWidget(_wrap(routeId: 'r1', initialConfig: config));
    await tester.pumpAndSettle();

    // Label per /tmp/spoke-a5-inspection/ms5-after-nao-usar.png.
    expect(find.text('Nenhum destino'), findsOneWidget);
    // Row icon is FLAG (the sheet card uses X; the row uses flag — two
    // surfaces, same state — per divergence #2).
    expect(find.byIcon(LucideIcons.flag), findsOneWidget);
    // No subtitle: the round-trip subtitle must NOT appear (divergence #3).
    expect(
      find.text('Viagem de ida e volta a partir do local atual'),
      findsNothing,
    );
  });

  testWidgets(
      'Destino RoundTrip explicit renders "Ida e volta" as primary with the '
      'cornerUpLeft icon (Spoke parity, not repeat)', (tester) async {
    const config = RouteConfig(destination: RoundTrip());
    await tester.pumpWidget(_wrap(routeId: 'r1', initialConfig: config));
    await tester.pumpAndSettle();

    expect(find.text('Ida e volta'), findsOneWidget);
    // Row icon is cornerUpLeft (same as the sheet card 1), NOT repeat
    // (divergence #4).
    expect(find.byIcon(LucideIcons.cornerUpLeft), findsOneWidget);
    expect(find.byIcon(LucideIcons.repeat), findsNothing);
  });

  testWidgets('Destino SpecificAddress renders the address as primary',
      (tester) async {
    const config = RouteConfig(
      destination: SpecificAddress(
        address: 'R. Augusta, 100',
        lat: -23.5,
        lng: -46.6,
      ),
    );
    await tester.pumpWidget(_wrap(routeId: 'r1', initialConfig: config));
    await tester.pumpAndSettle();

    expect(find.text('R. Augusta, 100'), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────────────────
  // MS5 — Destino row → bottom-sheet sub-picker (ADR-0043).
  // Tapping the Destino row opens DestinationPickerSheet; a card tap applies
  // the chosen Destination immediately; "Concluído" closes without change.
  // ─────────────────────────────────────────────────────────────────────────

  testWidgets('Destino row 1 tap opens the DestinationPickerSheet',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(routeId: 'r1'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsIdentifier('route_details_row_destino'));
    await tester.pumpAndSettle();

    // Sheet header + its 3 cards are now on screen.
    expect(find.byType(DestinationPickerSheet), findsOneWidget);
    expect(find.text('Voltar ao ponto de partida'), findsOneWidget);
    expect(find.text('Não usar destino'), findsOneWidget);
  });

  testWidgets(
      'Destino sheet card "Não usar destino" applies NoDestination → row '
      'shows "Nenhum destino" + flag icon, no subtitle', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(routeId: 'r1'));
    await tester.pumpAndSettle();

    // Default state.
    expect(find.text('Ida e volta'), findsOneWidget);

    await tester.tap(find.bySemanticsIdentifier('route_details_row_destino'));
    await tester.pumpAndSettle();
    await tester
        .tap(find.bySemanticsIdentifier('destination_card_no_destination'));
    await tester.pumpAndSettle();

    // Sheet dismissed AND selection applied (card tap IS the confirm).
    expect(find.byType(DestinationPickerSheet), findsNothing);
    expect(find.text('Nenhum destino'), findsOneWidget);
    expect(find.byIcon(LucideIcons.flag), findsOneWidget);
    expect(
      find.text('Viagem de ida e volta a partir do local atual'),
      findsNothing,
    );
  });

  testWidgets(
      'Destino sheet "Concluído" closes the sheet WITHOUT changing the '
      'selection (Spoke close-without-change contract, divergence #5)',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Start in NoDestination so we can prove "Concluído" leaves it untouched.
    const config = RouteConfig(destination: NoDestination());
    await tester.pumpWidget(_wrap(routeId: 'r1', initialConfig: config));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum destino'), findsOneWidget);

    await tester.tap(find.bySemanticsIdentifier('route_details_row_destino'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsIdentifier('destination_done'));
    await tester.pumpAndSettle();

    // Sheet gone, row label unchanged — Concluído never mutates the row.
    expect(find.byType(DestinationPickerSheet), findsNothing);
    expect(find.text('Nenhum destino'), findsOneWidget);
  });

  testWidgets(
      'Destino sheet card "Destino em outro endereço" pushes the end-location '
      'route and applies the returned SpecificAddress (card-2 two-hop nav, '
      'ADR-0043 divergence #6)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Router rich enough to actually exercise the card-2 push: the
    // end-location route stands in for AddStopPage(mode: endLocation) and
    // pops a SpecificAddress, the same typed result the real picker returns.
    // The plain `_wrap` router (path '/' only) cannot route this push — this
    // is the exact branch-route push Flutter #155746 makes fragile, so it
    // needs a real route registered (see lesson_slice_checklist_integration_test_gate;
    // the on-device golden path is covered in MS9).
    const picked = SpecificAddress(
      address: 'Av Paulista, 1000',
      lat: -23.561,
      lng: -46.656,
    );
    final router = GoRouter(
      initialLocation: '/home/routes/active/r1/details',
      routes: [
        GoRoute(
          path: '/home/routes/active/:routeId/details',
          builder: (_, state) =>
              RouteDetailsPage(routeId: state.pathParameters['routeId']!),
          routes: [
            GoRoute(
              path: 'end-location',
              builder: (context, __) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    key: const Key('stub_pick_address'),
                    onPressed: () => context.pop<SpecificAddress>(picked),
                    child: const Text('pick'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    // Default state.
    expect(find.text('Ida e volta'), findsOneWidget);

    // Open the Destino sheet, tap card 2 → sheet closes, end-location pushed.
    await tester.tap(find.bySemanticsIdentifier('route_details_row_destino'));
    await tester.pumpAndSettle();
    await tester
        .tap(find.bySemanticsIdentifier('destination_card_specific_address'));
    await tester.pumpAndSettle();

    // We are now on the pushed end-location route (sheet gone).
    expect(find.byType(DestinationPickerSheet), findsNothing);
    expect(find.byKey(const Key('stub_pick_address')), findsOneWidget);

    // Pick an address → pops the SpecificAddress → setDestination applies it.
    await tester.tap(find.byKey(const Key('stub_pick_address')));
    await tester.pumpAndSettle();

    // Back on Detalhes; the Destino row now shows the chosen address.
    expect(find.text('Av Paulista, 1000'), findsOneWidget);
    expect(find.byIcon(LucideIcons.mapPin), findsOneWidget);
  });

  testWidgets(
      'Destino sheet card-2 push that is backed out (null pop) leaves the '
      'destination untouched (divergence #6 backout case)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/home/routes/active/r1/details',
      routes: [
        GoRoute(
          path: '/home/routes/active/:routeId/details',
          builder: (_, state) =>
              RouteDetailsPage(routeId: state.pathParameters['routeId']!),
          routes: [
            GoRoute(
              path: 'end-location',
              builder: (context, __) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    key: const Key('stub_back'),
                    // Pops with no value → null result, mimicking system back.
                    onPressed: () => context.pop(),
                    child: const Text('back'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ida e volta'), findsOneWidget);

    await tester.tap(find.bySemanticsIdentifier('route_details_row_destino'));
    await tester.pumpAndSettle();
    await tester
        .tap(find.bySemanticsIdentifier('destination_card_specific_address'));
    await tester.pumpAndSettle();

    // Back out without selecting (null pop).
    await tester.tap(find.byKey(const Key('stub_back')));
    await tester.pumpAndSettle();

    // Destination unchanged — still the RoundTrip default.
    expect(find.text('Ida e volta'), findsOneWidget);
  });

  testWidgets(
      'Pausa section shows "Adicionar pausa" (no "+ " prefix) when '
      'empty', (tester) async {
    await tester.pumpWidget(_wrap(routeId: 'r1'));
    await tester.pumpAndSettle();

    expect(find.text('Adicionar pausa'), findsOneWidget);
    // Old "+ Adicionar pausa" prefix gone.
    expect(find.text('+ Adicionar pausa'), findsNothing);
  });

  testWidgets(
      'Adicionar pausa row exposes Semantics identifier '
      '"route_details_row_adicionar_pausa" for Maestro', (tester) async {
    await tester.pumpWidget(_wrap(routeId: 'r1'));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsIdentifier('route_details_row_adicionar_pausa'),
      findsOneWidget,
    );
  });

  testWidgets(
      'Adicionar pausa row pushes the "Configure a pausa" page (ADR-0044 — '
      'real scheduler, no interim SnackBar)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(routeId: 'r1'));
    await tester.pumpAndSettle();

    await tester
        .tap(find.bySemanticsIdentifier('route_details_row_adicionar_pausa'));
    await tester.pumpAndSettle();

    // We are now on the pushed full-screen scheduler page.
    expect(find.text('Configure a pausa'), findsOneWidget);
    // The old interim affordance is gone.
    expect(find.text('Pausa em breve'), findsNothing);
  });

  testWidgets(
      'a break returned from the scheduler renders as a window row '
      '"08:00–15:00 • 30min" on Detalhes da rota (ADR-0044)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(routeId: 'r1'));
    await tester.pumpAndSettle();

    // Open the scheduler and confirm with the Spoke defaults (08:00–15:00/30).
    await tester
        .tap(find.bySemanticsIdentifier('route_details_row_adicionar_pausa'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsIdentifier('break_scheduler_confirm'));
    await tester.pumpAndSettle();

    // Back on Detalhes da rota, the new break shows as a window range row.
    expect(find.text('08:00–15:00 • 30min'), findsOneWidget);
  });

  testWidgets(
      '"Salvar como padrão" checkbox: exactly one, default UNCHECKED, '
      'below the Concluído button', (tester) async {
    // Tall viewport so both Concluído and the checkbox lay out in-frame for
    // the y-coordinate comparison.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(routeId: 'r1'));
    await tester.pumpAndSettle();

    // Spoke uses the exact label "Salvar como padrão" — no per-section
    // "para próximas rotas" suffix variants.
    expect(find.text('Salvar como padrão'), findsOneWidget);
    expect(find.text('Salvar como padrão para próximas rotas'), findsNothing);

    final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox));
    expect(checkboxes.length, 1, reason: 'exactly one screen-level checkbox');
    expect(checkboxes.first.value, isFalse, reason: 'default UNCHECKED');

    // Concluído sits above the checkbox in paint order.
    final concluidoY = tester
        .getCenter(
          find.ancestor(
            of: find.text('Concluído'),
            matching: find.byType(FilledButton),
          ),
        )
        .dy;
    final checkboxY = tester.getCenter(find.byType(Checkbox).first).dy;
    expect(checkboxY, greaterThan(concluidoY));
  });

  testWidgets('Salvar como padrão checkbox can be toggled on', (tester) async {
    // Use a tall viewport so the checkbox (bottom of the scrollable Column)
    // is in the hit-testable region. Default test view (800×600) clips it.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(routeId: 'r1'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    final cb = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(cb.value, isTrue);
  });

  testWidgets('every row leads with an icon (no row without leading icon)',
      (tester) async {
    await tester.pumpWidget(_wrap(routeId: 'r1'));
    await tester.pumpAndSettle();

    // 5 rows: Partida x2, Destino x2, Pausa Adicionar x1.
    expect(find.byType(RouteConfigRow), findsNWidgets(5));
    // GPS-target on Partida row 1.
    expect(find.byIcon(LucideIcons.locateFixed), findsOneWidget);
    // Coffee on the Adicionar pausa row.
    expect(find.byIcon(LucideIcons.coffee), findsOneWidget);
    // cornerUpLeft for the default Ida e volta destination (Spoke parity).
    expect(find.byIcon(LucideIcons.cornerUpLeft), findsOneWidget);
    // Two clock icons: Partida row 2 + Destino row 2.
    expect(find.byIcon(LucideIcons.clock), findsNWidgets(2));
  });

  // ─────────────────────────────────────────────────────────────────────────
  // MS3 — Partida row navigation: tapping Partida-Local pushes the
  // start-location sub-route AND writes the popped StartLocation back
  // through `routeConfigControllerProvider.setStartLocation`.
  // ─────────────────────────────────────────────────────────────────────────

  testWidgets(
      'Partida row 1 tap pushes /home/routes/active/:id/details/start-location',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/home/routes/active/r1/details',
      routes: [
        GoRoute(
          path: '/home/routes/active/:routeId/details',
          builder: (_, state) => RouteDetailsPage(
            routeId: state.pathParameters['routeId']!,
          ),
          routes: [
            GoRoute(
              path: 'start-location',
              builder: (_, __) =>
                  const Scaffold(body: Text('SENTINEL_START_LOCATION')),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Tap via the row's Semantics identifier so we hit the InkWell's
    // onTap, not an inner Text node (per lesson
    // `maestro_flutter_listtile_tap_needs_semantics`, which applies to
    // widget tests too once the production widget uses Semantics).
    await tester
        .tap(find.bySemanticsIdentifier('route_details_row_partida_local'));
    await tester.pumpAndSettle();

    expect(find.text('SENTINEL_START_LOCATION'), findsOneWidget);
  });

  testWidgets(
      'Partida row 1 tap returning a StartLocation writes it through '
      'routeConfigController.setStartLocation', (tester) async {
    // The sentinel sub-route pops a known StartLocation so we can verify
    // the parent picks it up. Default Partida label is "Usar local atual";
    // after the pop, the row label must read the returned address.
    const expected = StartLocation(
      address: 'Rua Augusta, 500',
      lat: -23.55,
      lng: -46.66,
      isUserCurrentLocation: false,
    );
    final router = GoRouter(
      initialLocation: '/home/routes/active/r1/details',
      routes: [
        GoRoute(
          path: '/home/routes/active/:routeId/details',
          builder: (_, state) => RouteDetailsPage(
            routeId: state.pathParameters['routeId']!,
          ),
          routes: [
            GoRoute(
              path: 'start-location',
              builder: (context, __) => Scaffold(
                body: Center(
                  child: Builder(
                    builder: (ctx) => ElevatedButton(
                      onPressed: () => ctx.pop<StartLocation>(expected),
                      child: const Text('pop_with_value'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Sanity: pre-tap label is the default.
    expect(find.text('Usar local atual'), findsOneWidget);

    await tester
        .tap(find.bySemanticsIdentifier('route_details_row_partida_local'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('pop_with_value'));
    await tester.pumpAndSettle();

    // Back on Detalhes; the Partida-Local label must now reflect the
    // selected address, proving the controller was updated.
    expect(find.text('Rua Augusta, 500'), findsOneWidget);
    expect(find.text('Usar local atual'), findsNothing);
  });

  testWidgets(
      'Partida row 1 tap that pops with null leaves the row label '
      'unchanged (Spoke X-close contract)', (tester) async {
    final router = GoRouter(
      initialLocation: '/home/routes/active/r1/details',
      routes: [
        GoRoute(
          path: '/home/routes/active/:routeId/details',
          builder: (_, state) => RouteDetailsPage(
            routeId: state.pathParameters['routeId']!,
          ),
          routes: [
            GoRoute(
              path: 'start-location',
              builder: (context, __) => Scaffold(
                body: Center(
                  child: Builder(
                    builder: (ctx) => ElevatedButton(
                      // Pop with no value — matches X-close + back gesture.
                      onPressed: () => ctx.pop(),
                      child: const Text('pop_no_value'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester
        .tap(find.bySemanticsIdentifier('route_details_row_partida_local'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('pop_no_value'));
    await tester.pumpAndSettle();

    // Row label must still be the default — null result is a no-op.
    expect(find.text('Usar local atual'), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Numpad TimePickerSheet wiring (ADR-0042).
  // Tapping the Partida-Início / Destino-Término rows opens the sheet;
  // confirming with a TimeOfDay writes through routeConfigController and
  // refreshes the row label per Spoke (`HH:MM` inline).
  // ─────────────────────────────────────────────────────────────────────────

  testWidgets(
      'Partida row 2 tap opens TimePickerSheet with title '
      '"Definir primeiro horário" (Spoke live capture 2026-06-03)',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(routeId: 'r1'));
    await tester.pumpAndSettle();

    await tester
        .tap(find.bySemanticsIdentifier('route_details_row_partida_inicio'));
    await tester.pumpAndSettle();

    // Header of the freshly-opened sheet shows the Spoke placeholder title.
    // Live: /tmp/spoke-a5-msfix/timepicker-inicio-header.png (rid
    // bsp_input_time = "Definir primeiro horário").
    expect(
      find.descendant(
        of: find.bySemanticsIdentifier('time_picker_header'),
        matching: find.text('Definir primeiro horário'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'Destino row 2 tap opens TimePickerSheet with title '
      '"Definir último horário" (Spoke live capture 2026-06-03)',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(routeId: 'r1'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.bySemanticsIdentifier('route_details_row_destino_horario_termino'),
    );
    await tester.pumpAndSettle();

    // Live: /tmp/spoke-a5-msfix/timepicker-termino-header.png
    // (rid bsp_input_time = "Definir último horário").
    expect(
      find.descendant(
        of: find.bySemanticsIdentifier('time_picker_header'),
        matching: find.text('Definir último horário'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'Confirming TimePickerSheet on Partida row writes timeStart and '
      'collapses label to "HH:MM" (Spoke parity, no prefix)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(routeId: 'r1'));
    await tester.pumpAndSettle();

    await tester
        .tap(find.bySemanticsIdentifier('route_details_row_partida_inicio'));
    await tester.pumpAndSettle();

    // Type 10:30.
    for (final d in ['1', '0', '3', '0']) {
      await tester.tap(find.bySemanticsIdentifier('time_picker_digit_$d'));
      await tester.pump();
    }
    await tester.tap(find.bySemanticsIdentifier('time_picker_confirm'));
    await tester.pumpAndSettle();

    // Spoke parity: label is just '10:30' — no 'Iniciar agora mesmo' prefix.
    expect(find.text('10:30'), findsOneWidget);
    expect(find.text('Iniciar agora mesmo  10:30'), findsNothing);
    expect(find.text('Iniciar agora mesmo'), findsNothing);
  });

  testWidgets(
      'Confirming TimePickerSheet on Destino row writes timeEnd and '
      'refreshes label to "HH:MM"', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(routeId: 'r1'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.bySemanticsIdentifier('route_details_row_destino_horario_termino'),
    );
    await tester.pumpAndSettle();

    for (final d in ['1', '8', '0', '0']) {
      await tester.tap(find.bySemanticsIdentifier('time_picker_digit_$d'));
      await tester.pump();
    }
    await tester.tap(find.bySemanticsIdentifier('time_picker_confirm'));
    await tester.pumpAndSettle();

    // Spoke renders the value inline — placeholder is gone, "18:00" shows.
    expect(find.text('18:00'), findsOneWidget);
    expect(find.text('Definir horário de término'), findsNothing);
  });
}
