import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:roteirizador_pro/features/route_config/domain/route_config.dart';
import 'package:roteirizador_pro/features/route_config/presentation/pages/route_details_page.dart';
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
}) {
  final router = _router(RouteDetailsPage(routeId: routeId));
  return ProviderScope(
    overrides: [
      if (initialConfig != null)
        routeConfigControllerProvider(routeId)
            .overrideWith(() => _TestController(initialConfig)),
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
  testWidgets('AppBar renders title "Detalhes da rota"', (tester) async {
    await tester.pumpWidget(_wrap(routeId: 'r1'));
    await tester.pumpAndSettle();

    expect(find.text('Detalhes da rota'), findsOneWidget);
  });

  testWidgets('AppBar leading is LucideIcons.x', (tester) async {
    await tester.pumpWidget(_wrap(routeId: 'r1'));
    await tester.pumpAndSettle();

    expect(find.byIcon(LucideIcons.x), findsOneWidget);
  });

  testWidgets('AppBar action "Concluído" is disabled when config is invalid',
      (tester) async {
    await tester.pumpWidget(_wrap(routeId: 'r1'));
    await tester.pumpAndSettle();

    final btn = tester.widget<TextButton>(
      find.ancestor(
        of: find.text('Concluído'),
        matching: find.byType(TextButton),
      ),
    );
    expect(btn.onPressed, isNull);
  });

  testWidgets('AppBar action "Concluído" is enabled when config is valid',
      (tester) async {
    const validConfig = RouteConfig(
      timeStart: TimeStart(time: TimeOfDay(hour: 8, minute: 0)),
      timeEnd: TimeEnd(time: TimeOfDay(hour: 18, minute: 0)),
    );
    await tester.pumpWidget(
      _wrap(routeId: 'r1', initialConfig: validConfig),
    );
    await tester.pumpAndSettle();

    final btn = tester.widget<TextButton>(
      find.ancestor(
        of: find.text('Concluído'),
        matching: find.byType(TextButton),
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

  testWidgets('renders 3 RouteDetailsSection in order Partida/Destino/Pausas',
      (tester) async {
    await tester.pumpWidget(_wrap(routeId: 'r1'));
    await tester.pumpAndSettle();

    expect(find.byType(RouteDetailsSection), findsNWidgets(3));
    expect(find.text('Partida'), findsOneWidget);
    // "Destino" appears twice: section title + row label inside the section.
    expect(find.text('Destino'), findsNWidgets(2));
    expect(find.text('Pausas'), findsOneWidget);
  });

  testWidgets(
      'Partida default values: "Usar local atual" + "08:00" when config empty',
      (tester) async {
    await tester.pumpWidget(_wrap(routeId: 'r1'));
    await tester.pumpAndSettle();

    expect(find.text('Usar local atual'), findsOneWidget);
    expect(find.text('08:00'), findsOneWidget);
  });

  testWidgets(
      'Destino default value: "Voltar ao local de início" when destination null',
      (tester) async {
    await tester.pumpWidget(_wrap(routeId: 'r1'));
    await tester.pumpAndSettle();

    expect(find.text('Voltar ao local de início'), findsOneWidget);
  });

  testWidgets('Pausas section shows "+ Adicionar pausa" CTA when empty',
      (tester) async {
    await tester.pumpWidget(_wrap(routeId: 'r1'));
    await tester.pumpAndSettle();

    expect(find.text('+ Adicionar pausa'), findsOneWidget);
  });

  testWidgets('Destino RoundTrip renders "Ida e volta" as trailing value',
      (tester) async {
    const config = RouteConfig(destination: RoundTrip());
    await tester.pumpWidget(_wrap(routeId: 'r1', initialConfig: config));
    await tester.pumpAndSettle();

    expect(find.text('Ida e volta'), findsOneWidget);
  });

  testWidgets('Destino SpecificAddress renders the address as trailing value',
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
}
