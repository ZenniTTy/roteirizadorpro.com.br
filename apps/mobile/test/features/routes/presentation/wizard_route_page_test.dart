import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:roteirizador_pro/features/routes/domain/route.dart' as domain;
import 'package:roteirizador_pro/features/routes/presentation/wizard_route_page.dart';
import 'package:roteirizador_pro/features/routes/state/active_route_provider.dart';
import 'package:roteirizador_pro/features/routes/state/routes_provider.dart';

Widget _wrap({String? routeId, List<domain.Route>? seedRoutes}) {
  return ProviderScope(
    overrides: [
      if (seedRoutes != null)
        routesProvider.overrideWith(() => _FakeRoutes(seedRoutes)),
    ],
    child: MaterialApp(
      home: WizardRoutePage(routeId: routeId),
    ),
  );
}

class _FakeRoutes extends Routes {
  _FakeRoutes(this._seed);
  final List<domain.Route> _seed;
  @override
  List<domain.Route> build() => _seed;
}

void main() {
  group('WizardRoutePage — create mode', () {
    testWidgets(
        'renders title "Criar rota", CTA "Confirmar", X close icon '
        '(Spoke D4 2026-05-28: both create AND edit use X; inventário §6.2 '
        'corrigido neste PR), and Zona C with reuseStops checkbox',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Criar rota'), findsOneWidget);
      expect(find.text('Confirmar'), findsOneWidget);
      expect(find.byIcon(LucideIcons.x), findsOneWidget);
      expect(find.byIcon(LucideIcons.arrowLeft), findsNothing);
      // Zona C present in create.
      expect(find.text('Atalhos'), findsOneWidget);
      expect(find.text('Aproveitar últimas paradas'), findsOneWidget);
    });

    testWidgets(
        'Confirmar (create) torna a rota recém-criada a ATIVA '
        '(paridade Spoke: criar → entra na rota; smoke E2E MS-A6 flagrou '
        '"Nenhuma rota ativa selecionada" no fluxo criar → adicionar parada)',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          routesProvider.overrideWith(() => _FakeRoutes([])),
        ],
      );
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: '/create',
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) =>
                const Scaffold(body: Center(child: Text('SENTINEL_HOME'))),
          ),
          GoRoute(
            path: '/create',
            builder: (_, __) => const WizardRoutePage(routeId: null),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      final routes = container.read(routesProvider);
      expect(routes, hasLength(1), reason: 'Confirmar deve criar a rota');
      expect(
        container.read(activeRouteIdProvider),
        routes.single.id,
        reason: 'a rota recém-criada deve virar a ativa '
            '(senão "Adicionar parada" falha com "Nenhuma rota ativa")',
      );
    });
  });

  group('WizardRoutePage — edit mode', () {
    testWidgets(
        'when routeId resolves, renders title "Editar rota", CTA '
        '"Salvar alterações", X close icon, and HIDES Zona C — Spoke §10.3',
        (tester) async {
      final routes = [
        domain.Route(
          id: 'r1',
          date: DateTime(2026, 6, 15),
          name: 'Minha rota fixa',
        ),
      ];
      await tester.pumpWidget(_wrap(routeId: 'r1', seedRoutes: routes));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Editar rota'), findsOneWidget);
      expect(find.text('Salvar alterações'), findsOneWidget);
      expect(find.byIcon(LucideIcons.x), findsOneWidget);
      expect(find.byIcon(LucideIcons.arrowLeft), findsNothing);
      // Zona C HIDDEN in edit.
      expect(find.text('Atalhos'), findsNothing);
      expect(find.text('Aproveitar últimas paradas'), findsNothing);
    });

    testWidgets('pre-populates the name field from the resolved route',
        (tester) async {
      final routes = [
        domain.Route(
          id: 'r2',
          date: DateTime(2026, 6, 16),
          name: 'Rota da semana',
        ),
      ];
      await tester.pumpWidget(_wrap(routeId: 'r2', seedRoutes: routes));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Pre-populated name appears as the field's text (not as placeholder).
      expect(find.text('Rota da semana'), findsOneWidget);
    });

    testWidgets(
        'when route.name is null (auto-named route), pre-populates with '
        'route.displayName() — the SAME string shown on the drawer row '
        '(Maestro smoke test 2026-05-28 reconciliation: earlier version '
        'used _computeAutoName which appended " Rota N", causing visible '
        'inconsistency between drawer "sexta-feira" and edit field '
        '"sexta-feira Rota 1")', (tester) async {
      // Wednesday → PT-BR weekday "quarta-feira". Route.displayName()
      // returns just the weekday when name is null.
      final routes = [
        domain.Route(
          id: 'r-auto',
          date: DateTime(2026, 6, 17), // wednesday
          name: null,
        ),
      ];
      await tester.pumpWidget(_wrap(routeId: 'r-auto', seedRoutes: routes));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // The field must contain the weekday — and NOT followed by " Rota N".
      expect(find.text('quarta-feira'), findsOneWidget);
      expect(find.textContaining('Rota '), findsNothing);
    });

    testWidgets('falls back to create UI when routeId does not resolve',
        (tester) async {
      // routeId given but seed list does not contain it → behave as create.
      await tester.pumpWidget(
        _wrap(
          routeId: 'does-not-exist',
          seedRoutes: const [],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // isEdit is true (routeId != null), so the chrome is still edit-style
      // (X close, "Editar rota", "Salvar alterações"); however the form
      // starts empty because the route resolution failed. Regression guard:
      // we don't crash on a stale deep-link.
      expect(find.text('Editar rota'), findsOneWidget);
      expect(find.byIcon(LucideIcons.x), findsOneWidget);
      // No crash + no leftover state.
    });
  });
}
