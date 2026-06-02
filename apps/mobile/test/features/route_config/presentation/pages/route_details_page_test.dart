import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:roteirizador_pro/features/route_config/domain/route_config.dart';
import 'package:roteirizador_pro/features/route_config/presentation/pages/route_details_page.dart';
import 'package:roteirizador_pro/features/route_config/presentation/widgets/route_config_row.dart';
import 'package:roteirizador_pro/features/route_config/presentation/widgets/route_details_section.dart';
import 'package:roteirizador_pro/features/route_config/state/route_config_controller.dart';

GoRouter _router(Widget home) => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => home),
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

  testWidgets('Concluído is disabled when config is invalid', (tester) async {
    await tester.pumpWidget(_wrap(routeId: 'r1', validOverride: false));
    await tester.pumpAndSettle();

    final btn = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Concluído'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(btn.onPressed, isNull);
  });

  testWidgets('Concluído is enabled when config is valid', (tester) async {
    await tester.pumpWidget(_wrap(routeId: 'r1', validOverride: true));
    await tester.pumpAndSettle();

    final btn = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Concluído'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(btn.onPressed, isNotNull);
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

  testWidgets('Partida row 2 primary label starts with "Iniciar agora mesmo"',
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

    // Spoke renders the live time appended inline; we lock the time as 08:00.
    expect(find.text('Iniciar agora mesmo  08:00'), findsOneWidget);
    // Old label gone.
    expect(find.text('Início'), findsNothing);
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
      'Destino BackToStart() renders "Voltar ao local de início" '
      '(explicit choice, not default)', (tester) async {
    const config = RouteConfig(destination: BackToStart());
    await tester.pumpWidget(_wrap(routeId: 'r1', initialConfig: config));
    await tester.pumpAndSettle();

    expect(find.text('Voltar ao local de início'), findsOneWidget);
  });

  testWidgets('Destino RoundTrip explicit renders "Ida e volta" as primary',
      (tester) async {
    const config = RouteConfig(destination: RoundTrip());
    await tester.pumpWidget(_wrap(routeId: 'r1', initialConfig: config));
    await tester.pumpAndSettle();

    expect(find.text('Ida e volta'), findsOneWidget);
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
    // Repeat for the default Ida e volta destination.
    expect(find.byIcon(LucideIcons.repeat), findsOneWidget);
    // Two clock icons: Partida row 2 + Destino row 2.
    expect(find.byIcon(LucideIcons.clock), findsNWidgets(2));
  });
}
