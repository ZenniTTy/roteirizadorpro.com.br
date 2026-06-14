// Tests for EditStopPage — MS-A6 T8.
//
// Spec: docs/superpowers/specs/2026-06-11-area6-edit-stop-design.md
// Contrato: D1, F3, H12, H19, ordem visual §10.6.
//
// Setup: GoRouter de teste com rota pai '/home' (sentinela) e rota
// '/home/routes/active/:routeId/stops/:stopId/edit' → EditStopPage.
// routesProvider semeado com _FakeRoutes contendo Route 'r1' + Stop 's1'.
// Tela alta (1080×3200 / DPR 2.0) para o corpo scrollável não transbordar.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:roteirizador_pro/features/route_config/presentation/widgets/time_picker_sheet.dart';
import 'package:roteirizador_pro/features/routes/data/address_instructions_repository.dart';
import 'package:roteirizador_pro/features/routes/domain/package_details.dart';
import 'package:roteirizador_pro/features/routes/domain/optimization_state.dart'
    as domain;
import 'package:roteirizador_pro/features/routes/domain/place_in_vehicle.dart';
import 'package:roteirizador_pro/features/routes/domain/route.dart' as domain;
import 'package:roteirizador_pro/features/routes/domain/route_state.dart'
    as domain;
import 'package:roteirizador_pro/features/routes/domain/stop.dart' as domain;
import 'package:roteirizador_pro/features/routes/domain/stop_color.dart';
import 'package:roteirizador_pro/features/routes/domain/stop_order_policy.dart';
import 'package:roteirizador_pro/features/routes/presentation/pages/edit_stop_page.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/access_instructions_sheet.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/arrival_window_sheet.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/package_count_row.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/package_finder_sheet.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/stop_notes_section.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/time_at_stop_dialog.dart';
import 'package:roteirizador_pro/features/routes/state/address_instructions_controller.dart';
import 'package:roteirizador_pro/features/routes/state/routes_provider.dart';
import 'package:roteirizador_pro/features/settings/data/settings_repository.dart';
import 'package:roteirizador_pro/features/settings/state/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// Fake do [Routes] notifier — retorna uma lista semeada ao invés do seed de
/// produção. Permite que [updateStop] funcione normalmente (herda a
/// implementação real da superclasse) e que o container seja manipulável
/// externamente nos testes de reatividade.
class _FakeRoutes extends Routes {
  _FakeRoutes(this._seed);
  final List<domain.Route> _seed;

  @override
  List<domain.Route> build() => _seed;
}

/// Fake do [SettingsController] que retorna [defaultStopDuration] = 2 min.
/// Usado no teste 16.8 para verificar que a página lê o global (H14).
class _FakeSettingsController extends SettingsController {
  @override
  Future<Settings> build() async =>
      const Settings(defaultStopDuration: Duration(minutes: 2));
}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

final _stop1 = domain.Stop(
  id: 's1',
  lat: -23.5,
  lng: -46.6,
  streetName: 'Rua Alfa, 100',
  fullAddress: 'Rua Alfa, 100 - Centro, São Paulo',
);

// ---------------------------------------------------------------------------
// Helpers de setup
// ---------------------------------------------------------------------------

/// Tela alta: evita overflow no corpo scrollável da EditStopPage.
void _useTallFrame(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 3200);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Constrói um [GoRouter] de teste com:
/// - `/home` → sentinela (SENTINEL_HOME) — permite verificar pop.
/// - `/home/routes/active/:routeId/stops/:stopId/edit` → [EditStopPage].
///
/// [showAddedBadge] é lido do query param `?new=1`.
GoRouter _buildRouter({
  required String routeId,
  required String stopId,
  bool withNewBadge = false,
}) {
  final location =
      '/home/routes/active/$routeId/stops/$stopId/edit${withNewBadge ? '?new=1' : ''}';
  return GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('SENTINEL_HOME'))),
        routes: [
          GoRoute(
            path: 'routes/active/:routeId/stops/:stopId/edit',
            builder: (context, state) => EditStopPage(
              routeId: state.pathParameters['routeId']!,
              stopId: state.pathParameters['stopId']!,
              showAddedBadge: state.uri.queryParameters['new'] == '1',
            ),
          ),
        ],
      ),
    ],
  );
}

/// Monta o widget com o provider semeado com a rota 'r1' contendo [stops].
Widget _buildApp({
  required GoRouter router,
  List<domain.Stop> stops = const [],
}) {
  return ProviderScope(
    overrides: [
      routesProvider.overrideWith(
        () => _FakeRoutes([
          domain.Route(
            id: 'r1',
            date: DateTime(2026, 5, 27),
            routeState: const domain.RouteState(
              optimization: domain.OptimizationState.optimized,
              confirmed: true,
              started: true,
            ),
            stops: stops,
          ),
        ]),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

// ---------------------------------------------------------------------------
// Helpers de navegação / scroll
// ---------------------------------------------------------------------------

/// Faz scroll até que o finder seja visível (ou esgota 10 swipes).
Future<void> _scrollUntilVisible(
  WidgetTester tester,
  Finder finder, {
  Finder? scrollable,
  double dy = -200,
}) async {
  final scroll = scrollable ?? find.byType(Scrollable).first;
  for (var i = 0; i < 10; i++) {
    if (finder.evaluate().isNotEmpty) {
      final box = tester.renderObject(finder).paintBounds;
      if (box.height > 0) break;
    }
    await tester.drag(scroll, Offset(0, dy));
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Helper para grupos 13–17 (fora do main para evitar local-variable-with-underscore)
// ---------------------------------------------------------------------------

/// Monta a EditStopPage com [routesProvider] e
/// [addressInstructionsRepositoryProvider] injetados.
/// Retorna o [ProviderContainer] para inspeção de estado pós-ação.
/// O caller é responsável por `addTearDown(container.dispose)`.
Future<ProviderContainer> pumpPageWithInstructions(
  WidgetTester tester, {
  required AddressInstructionsRepository repo,
  required List<domain.Stop> stops,
}) async {
  tester.view.physicalSize = const Size(1080, 3200);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    overrides: [
      routesProvider.overrideWith(
        () => _FakeRoutes([
          domain.Route(
            id: 'r1',
            date: DateTime(2026, 5, 27),
            routeState: const domain.RouteState(
              optimization: domain.OptimizationState.optimized,
              confirmed: true,
              started: true,
            ),
            stops: stops,
          ),
        ]),
      ),
      addressInstructionsRepositoryProvider.overrideWithValue(repo),
    ],
  );

  const location = '/home/routes/active/r1/stops/s1/edit';
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('SENTINEL_HOME'))),
        routes: [
          GoRoute(
            path: 'routes/active/:routeId/stops/:stopId/edit',
            builder: (context, state) => EditStopPage(
              routeId: state.pathParameters['routeId']!,
              stopId: state.pathParameters['stopId']!,
            ),
          ),
        ],
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

// ---------------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------------

void main() {
  // ── 1. Header ─────────────────────────────────────────────────────────────

  group('Header', () {
    testWidgets('título "Editar parada" é visível', (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Editar parada'), findsOneWidget);
    });

    testWidgets(
        'botão Ajuda à esquerda expõe Semantics "edit_stop_help" e exibe '
        'SnackBar ao ser tocado (stub D7)', (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      final helpButton = find.bySemanticsIdentifier('edit_stop_help');
      expect(helpButton, findsOneWidget);

      await tester.tap(helpButton);
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets(
        'botão "Concluído" à direita expõe Semantics "edit_stop_done" e '
        'ao ser tocado popa sem salvar (F3 — edits já são live)',
        (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      final doneButton = find.bySemanticsIdentifier('edit_stop_done');
      expect(doneButton, findsOneWidget);

      await tester.tap(doneButton);
      await tester.pumpAndSettle();

      // Após o pop, a página sentinela raiz deve estar visível.
      expect(find.text('SENTINEL_HOME'), findsOneWidget);
      // A página de edição não deve mais estar presente.
      expect(find.text('Editar parada'), findsNothing);
    });

    testWidgets(
        'tap em "Concluído" não modifica o stop no provider '
        '(F3 — Concluído não salva nada)', (tester) async {
      _useTallFrame(tester);
      final container = ProviderContainer(
        overrides: [
          routesProvider.overrideWith(
            () => _FakeRoutes([
              domain.Route(
                id: 'r1',
                date: DateTime(2026, 5, 27),
                routeState: const domain.RouteState(
                  optimization: domain.OptimizationState.optimized,
                  confirmed: true,
                  started: true,
                ),
                stops: [_stop1],
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: _buildRouter(routeId: 'r1', stopId: 's1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsIdentifier('edit_stop_done'));
      await tester.pumpAndSettle();

      // Stop permanece intacto no provider.
      final routes = container.read(routesProvider);
      final route = routes.firstWhere((r) => r.id == 'r1');
      final stop = route.stops.firstWhere((s) => s.id == 's1');
      expect(stop.streetName, 'Rua Alfa, 100');
    });
  });

  // ── 2. Badge "Adicionada" ─────────────────────────────────────────────────

  group('Badge "Adicionada"', () {
    testWidgets(
        'badge "Adicionada" VISÍVEL quando rota aberta com ?new=1 '
        '(showAddedBadge=true)', (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1', withNewBadge: true),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Adicionada'), findsOneWidget);
    });

    testWidgets(
        'badge "Adicionada" AUSENTE sem query param (showAddedBadge=false)',
        (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Adicionada'), findsNothing);
    });
  });

  // ── 3. Card endereço read-only ────────────────────────────────────────────

  group('Card endereço read-only', () {
    testWidgets('streetName visível no card de endereço', (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rua Alfa, 100'), findsOneWidget);
    });

    testWidgets('fullAddress visível no card de endereço', (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rua Alfa, 100 - Centro, São Paulo'), findsOneWidget);
    });

    testWidgets(
        'NENHUM TextField pré-preenchido com streetName ou fullAddress '
        '(endereço é read-only, não editável inline)', (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      // Verifica que não há TextField com o texto do endereço.
      final textFields = tester.widgetList<TextField>(find.byType(TextField));
      for (final tf in textFields) {
        final controller = tf.controller;
        if (controller != null) {
          expect(
            controller.text,
            isNot(contains('Rua Alfa')),
            reason:
                'TextField não deve conter o streetName — endereço é read-only',
          );
          expect(
            controller.text,
            isNot(contains('Centro, São Paulo')),
            reason:
                'TextField não deve conter o fullAddress — endereço é read-only',
          );
        }
      }
    });
  });

  // ── 4. Ordem visual §10.6 ────────────────────────────────────────────────

  group('Ordem visual §10.6', () {
    testWidgets(
        'elementos aparecem na ordem crescente de posição vertical: '
        'chip cor → chip ID → card endereço (streetName) → '
        'Instruções de acesso → campo notas → Localizador de pacotes → '
        'Pacotes → Ordem → Tipo → Horário de chegada → Tempo na parada → '
        'Mudar endereço → Duplicar parada → Remover parada', (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      // Âncoras na ordem esperada: (semanticsIdentifier ou texto).
      // Coletamos os dy de cada âncora de forma progressiva com scroll.
      // Para cada par consecutive (a, b): a.dy < b.dy.

      // Função auxiliar: obtém o dy do centro de um finder após scroll.
      Future<double> getDy(Finder finder) async {
        await _scrollUntilVisible(tester, finder);
        return tester.getCenter(finder).dy;
      }

      final colorChip = find.bySemanticsIdentifier('edit_stop_color_chip');
      final idChip = find.bySemanticsIdentifier('edit_stop_id_chip');
      final streetNameText = find.text('Rua Alfa, 100');
      final accessInstructions = find.text('Instruções de acesso');
      final notesField = find.text('Adicionar notas');
      final packageFinder = find.text('Localizador de pacotes');
      final packages = find.text('Pacotes');
      final order = find.text('Ordem');
      final type = find.text('Tipo');
      final arrivalWindow = find.text('Horário de chegada');
      final timeAtStop = find.text('Tempo na parada');
      final changeAddress = find.text('Mudar endereço');
      final duplicate = find.text('Duplicar parada');
      final remove = find.text('Remover parada');

      // Obtemos dy progressivamente do topo para o rodapé.
      final dyColor = await getDy(colorChip);
      final dyId = await getDy(idChip);
      final dyStreet = await getDy(streetNameText);
      final dyAccess = await getDy(accessInstructions);
      final dyNotes = await getDy(notesField);
      final dyFinder = await getDy(packageFinder);
      final dyPackages = await getDy(packages);
      final dyOrder = await getDy(order);
      final dyType = await getDy(type);
      final dyArrival = await getDy(arrivalWindow);
      final dyTime = await getDy(timeAtStop);
      final dyChangeAddr = await getDy(changeAddress);
      final dyDuplicate = await getDy(duplicate);
      final dyRemove = await getDy(remove);

      // Chips cor+ID são um GRUPO horizontal (§10.6 "chips cor+ID" — lado a
      // lado como no Spoke): mesma linha, cor à ESQUERDA do ID.
      expect(
        dyColor,
        lessThanOrEqualTo(dyId),
        reason: 'chip cor não pode estar abaixo do chip ID',
      );
      expect(
        tester.getCenter(colorChip).dx,
        lessThan(tester.getCenter(idChip).dx),
        reason: 'chip cor deve estar à esquerda do chip ID (mesma linha)',
      );
      expect(
        dyId,
        lessThan(dyStreet),
        reason: 'chip ID deve estar acima do card de endereço',
      );
      expect(
        dyStreet,
        lessThan(dyAccess),
        reason: 'endereço deve estar acima de "Instruções de acesso"',
      );
      expect(
        dyAccess,
        lessThan(dyNotes),
        reason: '"Instruções de acesso" deve estar acima do campo notas',
      );
      expect(
        dyNotes,
        lessThan(dyFinder),
        reason: 'campo notas deve estar acima de "Localizador de pacotes"',
      );
      expect(
        dyFinder,
        lessThan(dyPackages),
        reason: '"Localizador de pacotes" deve estar acima de "Pacotes"',
      );
      expect(
        dyPackages,
        lessThan(dyOrder),
        reason: '"Pacotes" deve estar acima de "Ordem"',
      );
      expect(
        dyOrder,
        lessThan(dyType),
        reason: '"Ordem" deve estar acima de "Tipo"',
      );
      expect(
        dyType,
        lessThan(dyArrival),
        reason: '"Tipo" deve estar acima de "Horário de chegada"',
      );
      expect(
        dyArrival,
        lessThan(dyTime),
        reason: '"Horário de chegada" deve estar acima de "Tempo na parada"',
      );
      expect(
        dyTime,
        lessThan(dyChangeAddr),
        reason: '"Tempo na parada" deve estar acima de "Mudar endereço"',
      );
      expect(
        dyChangeAddr,
        lessThan(dyDuplicate),
        reason: '"Mudar endereço" deve estar acima de "Duplicar parada"',
      );
      expect(
        dyDuplicate,
        lessThan(dyRemove),
        reason: '"Duplicar parada" deve estar acima de "Remover parada"',
      );
    });
  });

  // ── 5. Chip ID e rows stub ────────────────────────────────────────────────

  group('Chip ID', () {
    testWidgets('chip ID mostra "Pendente" quando deliveryId é null',
        (tester) async {
      _useTallFrame(tester);
      // _stop1 tem deliveryId null por padrão.
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      // O chip pode estar abaixo do fold — scroll até ele.
      final idChip = find.bySemanticsIdentifier('edit_stop_id_chip');
      await _scrollUntilVisible(tester, idChip);

      expect(find.text('Pendente'), findsOneWidget);
    });

    testWidgets(
        'toque no chip ID exibe SnackBar (stub D7 — tela "Formato do ID" '
        'pertence à Á10)', (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      final idChip = find.bySemanticsIdentifier('edit_stop_id_chip');
      await _scrollUntilVisible(tester, idChip);

      await tester.tap(idChip);
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('Rows stub — SnackBar para taps ainda não implementados', () {
    // Teste 'Localizador de pacotes exibe SnackBar (stub)' AMENDADO para o
    // contrato T16: a row abre a PackageFinderSheet (fluxo completo no
    // group 16) e NÃO emite mais SnackBar de stub.
    testWidgets(
        '(T16) — toque em "Localizador de pacotes" NÃO exibe SnackBar '
        '(row deixou de ser stub)', (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      final row = find.text('Localizador de pacotes');
      await _scrollUntilVisible(tester, row);

      await tester.tap(row);
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
    });

    // Teste 'Pacotes exibe SnackBar (stub)' AMENDADO para o contrato T13:
    // a página renderiza PackageCountRow no lugar da _EditStopRow genérica.
    testWidgets(
        '11 (T13) — página renderiza PackageCountRow para "Pacotes" '
        'e NÃO exibe SnackBar ao tocar "+"', (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      // PackageCountRow deve estar na árvore.
      expect(
        find.byType(PackageCountRow),
        findsOneWidget,
        reason: 'EditStopPage deve usar PackageCountRow, não _EditStopRow stub',
      );

      // Tap no botão "+" NÃO deve exibir SnackBar de stub.
      final plusBtn = find.bySemanticsIdentifier('edit_stop_packages_plus');
      await _scrollUntilVisible(tester, plusBtn);
      await tester.tap(plusBtn);
      await tester.pump();

      expect(
        find.byType(SnackBar),
        findsNothing,
        reason: '"+" não deve mostrar SnackBar — é ação live do stepper',
      );
    });
  });

  // ── 6. H12 — stopId que não resolve → pop pós-frame ─────────────────────

  group('H12 — stopId inválido', () {
    testWidgets(
        'stopId "nao-existe" que não resolve na rota → página popa '
        'automaticamente; SENTINEL_HOME visível, sem exception',
        (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 'nao-existe'),
          stops: [_stop1], // só tem 's1', não 'nao-existe'
        ),
      );
      await tester.pumpAndSettle();

      // Página deve ter popado, expondo o sentinel.
      expect(find.text('SENTINEL_HOME'), findsOneWidget);
      // A página de edição não deve estar na árvore.
      expect(find.text('Editar parada'), findsNothing);
      // Nenhuma exception deve ter escapado.
      expect(tester.takeException(), isNull);
    });
  });

  // ── 7. Reatividade — mutations externas re-renderizam a página ───────────

  group('Reatividade via routesProvider', () {
    testWidgets(
        'updateStop no provider com novo streetName → novo texto aparece '
        'na página sem rebuild forçado (ref.watch/select)', (tester) async {
      _useTallFrame(tester);
      final container = ProviderContainer(
        overrides: [
          routesProvider.overrideWith(
            () => _FakeRoutes([
              domain.Route(
                id: 'r1',
                date: DateTime(2026, 5, 27),
                routeState: const domain.RouteState(
                  optimization: domain.OptimizationState.optimized,
                  confirmed: true,
                  started: true,
                ),
                stops: [_stop1],
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: _buildRouter(routeId: 'r1', stopId: 's1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Confirma que o texto inicial está presente.
      expect(find.text('Rua Alfa, 100'), findsOneWidget);

      // Muta o stop externamente via provider.
      final updatedStop = _stop1.copyWith(
        streetName: 'Rua Nova, 999',
        fullAddress: 'Rua Nova, 999 - Bela Vista, São Paulo',
      );
      container.read(routesProvider.notifier).updateStop('r1', updatedStop);
      await tester.pump();

      // O novo texto deve aparecer (página observa via ref.watch/select).
      expect(find.text('Rua Nova, 999'), findsOneWidget);
      // O texto antigo deve sumir.
      expect(find.text('Rua Alfa, 100'), findsNothing);
    });
  });

  // ── 8. Ação "Remover parada" — presença ──────────────────────────────────

  group('Ações de rodapé — presença', () {
    testWidgets(
        '"Remover parada" está presente na página '
        '(cor destrutiva e Semantics "edit_stop_remove" são pinados na T18 '
        '— aqui só presença)', (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      final removeAction = find.text('Remover parada');
      await _scrollUntilVisible(tester, removeAction);

      expect(removeAction, findsOneWidget);
    });
  });

  // ── 9–11. Chip de cor — integração com ColorPickerSheet (F3/F10/H13) ──────
  //
  // Estes testes pinam que o chip 'edit_stop_color_chip' abre a ColorPickerSheet
  // real (não stub SnackBar), que commits da sheet aplicam updateStop live no
  // provider, e que 'Limpar' limpa o campo color do stop.

  group('Chip de cor — integração ColorPickerSheet', () {
    testWidgets(
        '9 — tap no chip abre ColorPickerSheet (header "Cor" visível); '
        'sem SnackBar stub "Cor em breve"', (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      final colorChip = find.bySemanticsIdentifier('edit_stop_color_chip');
      await _scrollUntilVisible(tester, colorChip);

      await tester.tap(colorChip);
      await tester.pumpAndSettle();

      // Sheet aberta: 'Cor' agora aparece 2× (chip + header da sheet) e os
      // 5 swatches estão presentes (âncora inequívoca da sheet).
      expect(find.text('Cor'), findsNWidgets(2));
      expect(
        find.bySemanticsIdentifier('edit_stop_color_blue'),
        findsOneWidget,
      );

      // Nenhum SnackBar de stub.
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets(
        '10 — selecionar teal + "Concluído" → provider tem color == teal '
        'e chip exibe dot colorido (Key edit_stop_color_chip_dot)',
        (tester) async {
      _useTallFrame(tester);
      final container = ProviderContainer(
        overrides: [
          routesProvider.overrideWith(
            () => _FakeRoutes([
              domain.Route(
                id: 'r1',
                date: DateTime(2026, 5, 27),
                routeState: const domain.RouteState(
                  optimization: domain.OptimizationState.optimized,
                  confirmed: true,
                  started: true,
                ),
                stops: [_stop1],
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: _buildRouter(routeId: 'r1', stopId: 's1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Abre a sheet.
      final colorChip = find.bySemanticsIdentifier('edit_stop_color_chip');
      await _scrollUntilVisible(tester, colorChip);
      await tester.tap(colorChip);
      await tester.pumpAndSettle();

      // Seleciona teal.
      await tester.tap(find.bySemanticsIdentifier('edit_stop_color_teal'));
      await tester.pump();

      // Confirma com o Concluído DA SHEET (o header da página também tem
      // 'Concluído' — a sheet, no root overlay, vem por último na árvore).
      await tester.tap(find.text('Concluído').last);
      await tester.pumpAndSettle();

      // Provider deve ter color == teal.
      final routes = container.read(routesProvider);
      final route = routes.firstWhere((r) => r.id == 'r1');
      final stop = route.stops.firstWhere((s) => s.id == 's1');
      expect(stop.color, StopColor.teal);

      // Chip deve exibir um dot colorido quando color != null.
      expect(find.byKey(const Key('edit_stop_color_chip_dot')), findsOneWidget);
    });

    testWidgets(
        '11 — stop já colorido (orange) → abrir sheet + "Limpar" → '
        'provider tem color == null', (tester) async {
      _useTallFrame(tester);

      final orangeStop = _stop1.copyWith(color: StopColor.orange);

      final container = ProviderContainer(
        overrides: [
          routesProvider.overrideWith(
            () => _FakeRoutes([
              domain.Route(
                id: 'r1',
                date: DateTime(2026, 5, 27),
                routeState: const domain.RouteState(
                  optimization: domain.OptimizationState.optimized,
                  confirmed: true,
                  started: true,
                ),
                stops: [orangeStop],
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: _buildRouter(routeId: 'r1', stopId: 's1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Abre a sheet.
      final colorChip = find.bySemanticsIdentifier('edit_stop_color_chip');
      await _scrollUntilVisible(tester, colorChip);
      await tester.tap(colorChip);
      await tester.pumpAndSettle();

      // Limpa.
      await tester.tap(find.text('Limpar'));
      await tester.pumpAndSettle();

      // Provider deve ter color == null.
      final routes = container.read(routesProvider);
      final route = routes.firstWhere((r) => r.id == 'r1');
      final stop = route.stops.firstWhere((s) => s.id == 's1');
      expect(stop.color, isNull);
    });
  });

  // ── 12. Integração — EditStopPage renderiza StopNotesSection ─────────────
  //
  // Verifica que a página usa o widget real StopNotesSection no lugar do
  // placeholder _buildNotesSection (que era um Container com Text/IconButton
  // estático). Este teste FALHA até que o implementador substitua
  // _buildNotesSection por StopNotesSection na EditStopPage.

  group('12 — Integração StopNotesSection na página', () {
    testWidgets(
        'EditStopPage renderiza StopNotesSection (find.byType) no lugar '
        'do placeholder _buildNotesSection', (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      // StopNotesSection deve estar na árvore de widgets.
      // Este finder falha enquanto a página ainda usa o placeholder interno.
      expect(
        find.byType(StopNotesSection),
        findsOneWidget,
        reason: 'EditStopPage deve usar StopNotesSection, não o placeholder',
      );
    });
  });

  // ── 13–17. Integração AccessInstructionsSheet (F13 / H18) ─────────────────
  //
  // Setup: InMemorySharedPreferencesAsync via plataforma global (padrão do
  // projeto — ver route_defaults_controller_test.dart). Cada teste seta
  // SharedPreferencesAsyncPlatform.instance fresh (instância isolada) antes
  // de criar o repositório.
  //
  // A chave normalizada do fixture _stop1 é:
  //   AddressInstructionsRepository.normalizeKey('Rua Alfa, 100 - Centro, São Paulo')
  //   == 'rua alfa, 100 - centro, são paulo'

  group(
      '13 — tap em edit_stop_access_instructions abre AccessInstructionsSheet',
      () {
    testWidgets(
        'tap no botão "Instruções de acesso" abre sheet '
        '(switch label "Salvar como padrão para este endereço" visível)',
        (tester) async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final repo = AddressInstructionsRepository(SharedPreferencesAsync());
      final container = await pumpPageWithInstructions(
        tester,
        repo: repo,
        stops: [_stop1],
      );
      addTearDown(container.dispose);

      final btn = find.bySemanticsIdentifier('edit_stop_access_instructions');
      await _scrollUntilVisible(tester, btn);
      await tester.tap(btn);
      await tester.pumpAndSettle();

      // Sheet aberta: switch label é âncora inequívoca (não ambígua com o
      // texto do botão da página).
      expect(
        find.text('Salvar como padrão para este endereço'),
        findsOneWidget,
      );

      // Nenhum SnackBar de stub deve aparecer.
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group(
      '14 — pré-preenchimento H18: stop sem accessInstructions + sticky no repo',
      () {
    testWidgets(
        'stop sem accessInstructions + repo semeado com sticky → '
        'sheet abre com TextField contendo o sticky', (tester) async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final repo = AddressInstructionsRepository(SharedPreferencesAsync());
      await repo.saveDefault(_stop1.fullAddress, 'portão lateral');

      final container = await pumpPageWithInstructions(
        tester,
        repo: repo,
        stops: [_stop1], // accessInstructions == null
      );
      addTearDown(container.dispose);

      final btn = find.bySemanticsIdentifier('edit_stop_access_instructions');
      await _scrollUntilVisible(tester, btn);
      await tester.tap(btn);
      await tester.pumpAndSettle();

      // O TextField deve conter o texto sticky do endereço.
      expect(find.text('portão lateral'), findsAtLeastNWidgets(1));
    });

    testWidgets(
        'stop COM accessInstructions próprio → sheet mostra o do stop '
        '(prioridade stop > sticky)', (tester) async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final repo = AddressInstructionsRepository(SharedPreferencesAsync());
      await repo.saveDefault(_stop1.fullAddress, 'portão lateral');

      final stopWithInstructions =
          _stop1.copyWith(accessInstructions: 'portão verde');

      final container = await pumpPageWithInstructions(
        tester,
        repo: repo,
        stops: [stopWithInstructions],
      );
      addTearDown(container.dispose);

      final btn = find.bySemanticsIdentifier('edit_stop_access_instructions');
      await _scrollUntilVisible(tester, btn);
      await tester.tap(btn);
      await tester.pumpAndSettle();

      // Deve exibir o texto do stop, não o sticky.
      expect(find.text('portão verde'), findsAtLeastNWidgets(1));
      expect(find.text('portão lateral'), findsNothing);
    });
  });

  group('15 — Salvar com switch ON → grava no stop E no repositório', () {
    testWidgets(
        '"Salvar" com texto + switch ON → stop.accessInstructions == texto '
        'E repo.instructionFor(fullAddress) == texto', (tester) async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final repo = AddressInstructionsRepository(SharedPreferencesAsync());

      final container = await pumpPageWithInstructions(
        tester,
        repo: repo,
        stops: [_stop1],
      );
      addTearDown(container.dispose);

      final btn = find.bySemanticsIdentifier('edit_stop_access_instructions');
      await _scrollUntilVisible(tester, btn);
      await tester.tap(btn);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.descendant(
          of: find.byType(AccessInstructionsSheet),
          matching: find.byType(TextField),
        ),
        'campainha 3x',
      );
      await tester.pump();

      // Liga o switch.
      await tester.tap(find.byType(Switch));
      await tester.pump();

      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      // Stop no provider deve ter accessInstructions atualizado.
      final routes = container.read(routesProvider);
      final stop = routes
          .firstWhere((r) => r.id == 'r1')
          .stops
          .firstWhere((s) => s.id == 's1');
      expect(stop.accessInstructions, 'campainha 3x');

      // Repositório também deve ter o sticky gravado.
      final sticky = await repo.instructionFor(_stop1.fullAddress);
      expect(sticky, 'campainha 3x');
    });
  });

  group('16 — Salvar com switch OFF → grava só no stop, não no repositório',
      () {
    testWidgets(
        '"Salvar" com texto + switch OFF → stop atualizado, '
        'repo.instructionFor == null (sem sticky gravado)', (tester) async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final repo = AddressInstructionsRepository(SharedPreferencesAsync());

      final container = await pumpPageWithInstructions(
        tester,
        repo: repo,
        stops: [_stop1],
      );
      addTearDown(container.dispose);

      final btn = find.bySemanticsIdentifier('edit_stop_access_instructions');
      await _scrollUntilVisible(tester, btn);
      await tester.tap(btn);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.descendant(
          of: find.byType(AccessInstructionsSheet),
          matching: find.byType(TextField),
        ),
        'tocar campainha',
      );
      await tester.pump();

      // Switch permanece OFF.
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      // Stop deve ter a instrução.
      final routes = container.read(routesProvider);
      final stop = routes
          .firstWhere((r) => r.id == 'r1')
          .stops
          .firstWhere((s) => s.id == 's1');
      expect(stop.accessInstructions, 'tocar campainha');

      // Repositório NÃO deve ter sticky.
      final sticky = await repo.instructionFor(_stop1.fullAddress);
      expect(sticky, isNull);
    });
  });

  group('17 — Limpar com switch ON → remove do stop E do repositório', () {
    testWidgets(
        '"Limpar" com switch ON → stop.accessInstructions == null '
        'E repo.instructionFor == null (sticky removido)', (tester) async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final repo = AddressInstructionsRepository(SharedPreferencesAsync());

      await repo.saveDefault(_stop1.fullAddress, 'código 5678');
      final stopWithInstructions =
          _stop1.copyWith(accessInstructions: 'código 5678');

      final container = await pumpPageWithInstructions(
        tester,
        repo: repo,
        stops: [stopWithInstructions],
      );
      addTearDown(container.dispose);

      final btn = find.bySemanticsIdentifier('edit_stop_access_instructions');
      await _scrollUntilVisible(tester, btn);
      await tester.tap(btn);
      await tester.pumpAndSettle();

      // Liga o switch (o texto 'código 5678' já está no TextField).
      await tester.tap(find.byType(Switch));
      await tester.pump();

      await tester.tap(find.text('Limpar'));
      await tester.pumpAndSettle();

      // Stop deve ter accessInstructions == null.
      final routes = container.read(routesProvider);
      final stop = routes
          .firstWhere((r) => r.id == 'r1')
          .stops
          .firstWhere((s) => s.id == 's1');
      expect(stop.accessInstructions, isNull);

      // Repositório deve ter o sticky removido.
      final sticky = await repo.instructionFor(_stop1.fullAddress);
      expect(sticky, isNull);
    });
  });

  // ── 12–13. Integração PackageCountRow na página (F3, F8) ──────────────────

  group('12 — Integração live stepper (F3)', () {
    testWidgets(
        'tap "+" 2× → provider: stop.packagesCount == 3 (seed 1); '
        'tap "−" 1× → 2', (tester) async {
      _useTallFrame(tester);
      final container = ProviderContainer(
        overrides: [
          routesProvider.overrideWith(
            () => _FakeRoutes([
              domain.Route(
                id: 'r1',
                date: DateTime(2026, 5, 27),
                routeState: const domain.RouteState(
                  optimization: domain.OptimizationState.optimized,
                  confirmed: true,
                  started: true,
                ),
                stops: [_stop1], // packagesCount == 1
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: _buildRouter(routeId: 'r1', stopId: 's1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final plusBtn = find.bySemanticsIdentifier('edit_stop_packages_plus');
      await _scrollUntilVisible(tester, plusBtn);

      // Tap "+" 2×
      await tester.tap(plusBtn);
      await tester.pump();
      await tester.tap(plusBtn);
      await tester.pump();

      var routes = container.read(routesProvider);
      var stop = routes
          .firstWhere((r) => r.id == 'r1')
          .stops
          .firstWhere((s) => s.id == 's1');
      expect(
        stop.packagesCount,
        3,
        reason: 'seed 1 + 2 taps "+" = 3',
      );

      // Tap "−" 1×
      final minusBtn = find.bySemanticsIdentifier('edit_stop_packages_minus');
      await tester.tap(minusBtn);
      await tester.pump();

      routes = container.read(routesProvider);
      stop = routes
          .firstWhere((r) => r.id == 'r1')
          .stops
          .firstWhere((s) => s.id == 's1');
      expect(
        stop.packagesCount,
        2,
        reason: '3 - 1 tap "−" = 2',
      );
    });
  });

  // ── 14. Ordem + Tipo segmented (F16/H21) ─────────────────────────────────
  //
  // Spec §13.C.1, F3, F16, H19, H21.
  // Cada row deixa de ser _EditStopRow stub e passa a conter um
  // SegmentedButton inline. Os testes abaixo FALHAM enquanto a página ainda
  // usa _EditStopRow com onTap → _stub('Ordem') / _stub('Tipo').

  group('14 — Ordem + Tipo segmented (F16/H21)', () {
    // ── 14.1  Row Ordem: SegmentedButton<StopOrderPolicy> com 3 segments ──

    testWidgets(
        '14.1 — Row Ordem contém SegmentedButton<StopOrderPolicy> '
        'com segments Primeira / Automática / Última (H21/F16)',
        (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      // Scroll até a row Ordem (abaixo da dobra).
      await _scrollUntilVisible(tester, find.text('Ordem'));

      // Deve existir um SegmentedButton parametrizado com StopOrderPolicy.
      expect(
        find.byType(SegmentedButton<StopOrderPolicy>),
        findsOneWidget,
        reason: 'Row Ordem deve usar SegmentedButton<StopOrderPolicy>',
      );

      // Os três labels de segment devem estar presentes e escopados ao botão.
      final btn = find.byType(SegmentedButton<StopOrderPolicy>);
      expect(
        find.descendant(of: btn, matching: find.text('Primeira')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: btn, matching: find.text('Automática')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: btn, matching: find.text('Última')),
        findsOneWidget,
      );
    });

    // ── 14.2  showSelectedIcon == false (H21) ─────────────────────────────

    testWidgets(
        '14.2 — SegmentedButton<StopOrderPolicy> tem showSelectedIcon == false (H21)',
        (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      await _scrollUntilVisible(
        tester,
        find.byType(SegmentedButton<StopOrderPolicy>),
      );

      final widget = tester.widget<SegmentedButton<StopOrderPolicy>>(
        find.byType(SegmentedButton<StopOrderPolicy>),
      );
      expect(
        widget.showSelectedIcon,
        isFalse,
        reason: 'H21: showSelectedIcon deve ser false na row Ordem',
      );
    });

    // ── 14.3  Seleção reflete stop.orderPolicy (default == auto) ──────────

    testWidgets(
        '14.3 — SegmentedButton<StopOrderPolicy> selected == {auto} '
        'quando stop seedado com orderPolicy == auto (default)',
        (tester) async {
      _useTallFrame(tester);
      // _stop1.orderPolicy == StopOrderPolicy.auto (default do construtor)
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      await _scrollUntilVisible(
        tester,
        find.byType(SegmentedButton<StopOrderPolicy>),
      );

      final widget = tester.widget<SegmentedButton<StopOrderPolicy>>(
        find.byType(SegmentedButton<StopOrderPolicy>),
      );
      expect(
        widget.selected,
        equals({StopOrderPolicy.auto}),
        reason:
            'selected deve refletir stop.orderPolicy == auto (valor não-default do ponto de vista do test)',
      );
    });

    // ── 14.4  Seleção reflete variante first ──────────────────────────────

    testWidgets(
        '14.4 — SegmentedButton<StopOrderPolicy> selected == {first} '
        'quando stop seedado com orderPolicy == first', (tester) async {
      _useTallFrame(tester);
      final stopFirst = _stop1.copyWith(orderPolicy: StopOrderPolicy.first);
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [stopFirst],
        ),
      );
      await tester.pumpAndSettle();

      await _scrollUntilVisible(
        tester,
        find.byType(SegmentedButton<StopOrderPolicy>),
      );

      final widget = tester.widget<SegmentedButton<StopOrderPolicy>>(
        find.byType(SegmentedButton<StopOrderPolicy>),
      );
      expect(widget.selected, equals({StopOrderPolicy.first}));
    });

    // ── 14.5  onSelectionChanged != null (§13.C.1 — nunca disabled) ───────

    testWidgets(
        '14.5 — SegmentedButton<StopOrderPolicy>.onSelectionChanged != null '
        '(§13.C.1 — sempre habilitado)', (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      await _scrollUntilVisible(
        tester,
        find.byType(SegmentedButton<StopOrderPolicy>),
      );

      final widget = tester.widget<SegmentedButton<StopOrderPolicy>>(
        find.byType(SegmentedButton<StopOrderPolicy>),
      );
      expect(
        widget.onSelectionChanged,
        isNotNull,
        reason:
            '§13.C.1: SegmentedButton<StopOrderPolicy> nunca deve ser disabled',
      );
    });

    // ── 14.6  Live update Ordem (F3): tap 'Última' → provider ─────────────

    testWidgets(
        '14.6 — tap no segment "Última" → provider: '
        'stop.orderPolicy == StopOrderPolicy.last (F3 / live update)',
        (tester) async {
      _useTallFrame(tester);
      final container = ProviderContainer(
        overrides: [
          routesProvider.overrideWith(
            () => _FakeRoutes([
              domain.Route(
                id: 'r1',
                date: DateTime(2026, 5, 27),
                routeState: const domain.RouteState(
                  optimization: domain.OptimizationState.optimized,
                  confirmed: true,
                  started: true,
                ),
                stops: [_stop1], // orderPolicy == auto
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: _buildRouter(routeId: 'r1', stopId: 's1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final btn = find.byType(SegmentedButton<StopOrderPolicy>);
      await _scrollUntilVisible(tester, btn);

      await tester.tap(
        find.descendant(of: btn, matching: find.text('Última')),
      );
      await tester.pumpAndSettle();

      final routes = container.read(routesProvider);
      final stop = routes
          .firstWhere((r) => r.id == 'r1')
          .stops
          .firstWhere((s) => s.id == 's1');
      expect(
        stop.orderPolicy,
        StopOrderPolicy.last,
        reason:
            'F3: tap em "Última" deve gravar live no provider sem Concluído',
      );
    });

    // ── 14.7  Tap Ordem NÃO exibe SnackBar de stub ────────────────────────

    testWidgets(
        '14.7 — tap no segment "Última" NÃO exibe SnackBar de stub '
        '(row deixou de ser stub)', (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      final btn = find.byType(SegmentedButton<StopOrderPolicy>);
      await _scrollUntilVisible(tester, btn);

      await tester.tap(
        find.descendant(of: btn, matching: find.text('Última')),
      );
      await tester.pump();

      expect(
        find.byType(SnackBar),
        findsNothing,
        reason: 'Row Ordem não deve mais emitir SnackBar de stub',
      );
    });

    // ── 14.8  Semantics edit_stop_order ainda presente (H19) ──────────────

    testWidgets(
        '14.8 — Semantics identifier "edit_stop_order" continua presente '
        'na row Ordem mesmo após migração para SegmentedButton (H19)',
        (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      await _scrollUntilVisible(
        tester,
        find.byType(SegmentedButton<StopOrderPolicy>),
      );

      expect(
        find.bySemanticsIdentifier('edit_stop_order'),
        findsOneWidget,
        reason: 'H19: identifier edit_stop_order deve permanecer na row',
      );
    });

    // ── 14.9  Row Tipo: SegmentedButton<StopType> com 2 segments ──────────

    testWidgets(
        '14.9 — Row Tipo contém SegmentedButton<domain.StopType> '
        'com segments Entrega / Coleta (F16)', (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      await _scrollUntilVisible(tester, find.text('Tipo'));

      expect(
        find.byType(SegmentedButton<domain.StopType>),
        findsOneWidget,
        reason: 'Row Tipo deve usar SegmentedButton<StopType>',
      );

      final btn = find.byType(SegmentedButton<domain.StopType>);
      expect(
        find.descendant(of: btn, matching: find.text('Entrega')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: btn, matching: find.text('Coleta')),
        findsOneWidget,
      );
    });

    // ── 14.10  showSelectedIcon == false para Tipo (H21) ──────────────────

    testWidgets(
        '14.10 — SegmentedButton<domain.StopType> tem showSelectedIcon == false (H21)',
        (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      await _scrollUntilVisible(
        tester,
        find.byType(SegmentedButton<domain.StopType>),
      );

      final widget = tester.widget<SegmentedButton<domain.StopType>>(
        find.byType(SegmentedButton<domain.StopType>),
      );
      expect(
        widget.showSelectedIcon,
        isFalse,
        reason: 'H21: showSelectedIcon deve ser false na row Tipo',
      );
    });

    // ── 14.11  Seleção Tipo reflete stop.type (default == delivery) ────────

    testWidgets(
        '14.11 — SegmentedButton<domain.StopType> selected == {delivery} '
        'quando stop seedado com type == delivery (default)', (tester) async {
      _useTallFrame(tester);
      // _stop1.type == StopType.delivery (default)
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      await _scrollUntilVisible(
        tester,
        find.byType(SegmentedButton<domain.StopType>),
      );

      final widget = tester.widget<SegmentedButton<domain.StopType>>(
        find.byType(SegmentedButton<domain.StopType>),
      );
      expect(widget.selected, equals({domain.StopType.delivery}));
    });

    // ── 14.12  Seleção Tipo reflete variante pickup ────────────────────────

    testWidgets(
        '14.12 — SegmentedButton<domain.StopType> selected == {pickup} '
        'quando stop seedado com type == pickup', (tester) async {
      _useTallFrame(tester);
      final stopPickup = _stop1.copyWith(type: domain.StopType.pickup);
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [stopPickup],
        ),
      );
      await tester.pumpAndSettle();

      await _scrollUntilVisible(
        tester,
        find.byType(SegmentedButton<domain.StopType>),
      );

      final widget = tester.widget<SegmentedButton<domain.StopType>>(
        find.byType(SegmentedButton<domain.StopType>),
      );
      expect(widget.selected, equals({domain.StopType.pickup}));
    });

    // ── 14.13  onSelectionChanged != null para Tipo (§13.C.1) ─────────────

    testWidgets(
        '14.13 — SegmentedButton<domain.StopType>.onSelectionChanged != null '
        '(§13.C.1 — sempre habilitado)', (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      await _scrollUntilVisible(
        tester,
        find.byType(SegmentedButton<domain.StopType>),
      );

      final widget = tester.widget<SegmentedButton<domain.StopType>>(
        find.byType(SegmentedButton<domain.StopType>),
      );
      expect(
        widget.onSelectionChanged,
        isNotNull,
        reason: '§13.C.1: SegmentedButton<StopType> nunca deve ser disabled',
      );
    });

    // ── 14.14  Live update Tipo (F3): tap 'Coleta' → provider ─────────────

    testWidgets(
        '14.14 — tap no segment "Coleta" → provider: '
        'stop.type == StopType.pickup (F3 / live update)', (tester) async {
      _useTallFrame(tester);
      final container = ProviderContainer(
        overrides: [
          routesProvider.overrideWith(
            () => _FakeRoutes([
              domain.Route(
                id: 'r1',
                date: DateTime(2026, 5, 27),
                routeState: const domain.RouteState(
                  optimization: domain.OptimizationState.optimized,
                  confirmed: true,
                  started: true,
                ),
                stops: [_stop1], // type == delivery
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: _buildRouter(routeId: 'r1', stopId: 's1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final btn = find.byType(SegmentedButton<domain.StopType>);
      await _scrollUntilVisible(tester, btn);

      await tester.tap(
        find.descendant(of: btn, matching: find.text('Coleta')),
      );
      await tester.pumpAndSettle();

      final routes = container.read(routesProvider);
      final stop = routes
          .firstWhere((r) => r.id == 'r1')
          .stops
          .firstWhere((s) => s.id == 's1');
      expect(
        stop.type,
        domain.StopType.pickup,
        reason:
            'F3: tap em "Coleta" deve gravar live no provider sem Concluído',
      );
    });

    // ── 14.15  Tap Tipo NÃO exibe SnackBar de stub ────────────────────────

    testWidgets(
        '14.15 — tap no segment "Coleta" NÃO exibe SnackBar de stub '
        '(row deixou de ser stub)', (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      final btn = find.byType(SegmentedButton<domain.StopType>);
      await _scrollUntilVisible(tester, btn);

      await tester.tap(
        find.descendant(of: btn, matching: find.text('Coleta')),
      );
      await tester.pump();

      expect(
        find.byType(SnackBar),
        findsNothing,
        reason: 'Row Tipo não deve mais emitir SnackBar de stub',
      );
    });

    // ── 14.16  Semantics edit_stop_type ainda presente (H19) ──────────────

    testWidgets(
        '14.16 — Semantics identifier "edit_stop_type" continua presente '
        'na row Tipo mesmo após migração para SegmentedButton (H19)',
        (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      await _scrollUntilVisible(
        tester,
        find.byType(SegmentedButton<domain.StopType>),
      );

      expect(
        find.bySemanticsIdentifier('edit_stop_type'),
        findsOneWidget,
        reason: 'H19: identifier edit_stop_type deve permanecer na row',
      );
    });
  });

  group('13 — Integração dialog (F8): digitar no dialog → provider', () {
    testWidgets(
        'tap no número → dialog; digitar "15" + barrier dismiss → '
        'provider: stop.packagesCount == 15', (tester) async {
      _useTallFrame(tester);
      final container = ProviderContainer(
        overrides: [
          routesProvider.overrideWith(
            () => _FakeRoutes([
              domain.Route(
                id: 'r1',
                date: DateTime(2026, 5, 27),
                routeState: const domain.RouteState(
                  optimization: domain.OptimizationState.optimized,
                  confirmed: true,
                  started: true,
                ),
                stops: [_stop1],
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: _buildRouter(routeId: 'r1', stopId: 's1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final valueBtn = find.bySemanticsIdentifier('edit_stop_packages_value');
      await _scrollUntilVisible(tester, valueBtn);

      await tester.tap(valueBtn);
      await tester.pumpAndSettle();

      // Dialog aberto — digita '15'. Escopa ao Dialog: a página também tem um
      // TextField (notas da StopNotesSection) e find.byType acharia os dois.
      await tester.enterText(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(TextField),
        ),
        '15',
      );
      await tester.pump();

      // Dismiss via barrier
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      final routes = container.read(routesProvider);
      final stop = routes
          .firstWhere((r) => r.id == 'r1')
          .stops
          .firstWhere((s) => s.id == 's1');
      expect(
        stop.packagesCount,
        15,
        reason: 'commit-on-dismiss do dialog deve aplicar 15 no provider',
      );
    });
  });

  // ── 15. Horário de chegada (F7/H1/D8) ────────────────────────────────────
  //
  // Testa a row 'Horário de chegada' (edit_stop_window) que:
  // 1. Exibe o valor formatado conforme o estado do stop (jadx UiFormatters).
  // 2. Abre ArrivalWindowSheet ao tap (sem SnackBar de stub).
  // 3. Commit de 'Limpar' limpa timeWindowStart/End no provider (prova _omit).
  // 4. Commit de um lado só é válido (H1) e grava no provider.

  group('15 — Horário de chegada (F7/H1/D8)', () {
    // ── 15.1  Formatação conforme estado do stop ─────────────────────────────

    testWidgets('15.1 — stop sem janela → row exibe "Qualquer momento"',
        (tester) async {
      _useTallFrame(tester);
      // _stop1 tem timeWindowStart == null e timeWindowEnd == null (default).
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      final row = find.bySemanticsIdentifier('edit_stop_window');
      await _scrollUntilVisible(tester, row);

      // Valor exibido na row.
      expect(find.text('Qualquer momento'), findsOneWidget);
    });

    testWidgets(
        '15.2 — só start (09:30) → row exibe "Após 09:30" '
        '(edit_time_window_after_time, jadx UiFormatters.m8466v)',
        (tester) async {
      _useTallFrame(tester);
      final stopStart = _stop1.copyWith(
        timeWindowStart: const TimeOfDay(hour: 9, minute: 30),
      );
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [stopStart],
        ),
      );
      await tester.pumpAndSettle();

      await _scrollUntilVisible(
        tester,
        find.bySemanticsIdentifier('edit_stop_window'),
      );

      expect(find.text('Após 09:30'), findsOneWidget);
    });

    testWidgets(
        '15.3 — só end (18:00) → row exibe "Antes de 18:00" '
        '(edit_time_window_before_time, jadx UiFormatters.m8466v)',
        (tester) async {
      _useTallFrame(tester);
      final stopEnd = _stop1.copyWith(
        timeWindowEnd: const TimeOfDay(hour: 18, minute: 0),
      );
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [stopEnd],
        ),
      );
      await tester.pumpAndSettle();

      await _scrollUntilVisible(
        tester,
        find.bySemanticsIdentifier('edit_stop_window'),
      );

      expect(find.text('Antes de 18:00'), findsOneWidget);
    });

    testWidgets(
        '15.4 — ambos (09:30/18:00) → row exibe "09:30 - 18:00" '
        '(separador " - " verbatim do jadx)', (tester) async {
      _useTallFrame(tester);
      final stopBoth = _stop1.copyWith(
        timeWindowStart: const TimeOfDay(hour: 9, minute: 30),
        timeWindowEnd: const TimeOfDay(hour: 18, minute: 0),
      );
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [stopBoth],
        ),
      );
      await tester.pumpAndSettle();

      await _scrollUntilVisible(
        tester,
        find.bySemanticsIdentifier('edit_stop_window'),
      );

      expect(find.text('09:30 - 18:00'), findsOneWidget);
    });

    // ── 15.5  Tap abre ArrivalWindowSheet (sem SnackBar de stub) ─────────────

    testWidgets(
        '15.5 — tap na row "Horário de chegada" abre ArrivalWindowSheet '
        '(find.byType); sem SnackBar de stub', (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      final row = find.bySemanticsIdentifier('edit_stop_window');
      await _scrollUntilVisible(tester, row);
      await tester.tap(row);
      await tester.pumpAndSettle();

      expect(
        find.byType(ArrivalWindowSheet),
        findsOneWidget,
        reason: 'Tap em "Horário de chegada" deve abrir ArrivalWindowSheet',
      );
      expect(
        find.byType(SnackBar),
        findsNothing,
        reason: 'Row não deve mais emitir SnackBar de stub',
      );
    });

    // ── 15.6  Fluxo commit: 'Limpar' → provider null/null ────────────────────

    testWidgets(
        '15.6 — stop com janela 09:30/18:00 → abre sheet → tap "Limpar" → '
        'provider: timeWindowStart == null && timeWindowEnd == null '
        '(prova _omit: copyWith null explícito LIMPA — lesson copyWith-null-fallback)',
        (tester) async {
      _useTallFrame(tester);
      final stopBoth = _stop1.copyWith(
        timeWindowStart: const TimeOfDay(hour: 9, minute: 30),
        timeWindowEnd: const TimeOfDay(hour: 18, minute: 0),
      );
      final container = ProviderContainer(
        overrides: [
          routesProvider.overrideWith(
            () => _FakeRoutes([
              domain.Route(
                id: 'r1',
                date: DateTime(2026, 5, 27),
                routeState: const domain.RouteState(
                  optimization: domain.OptimizationState.optimized,
                  confirmed: true,
                  started: true,
                ),
                stops: [stopBoth],
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: _buildRouter(routeId: 'r1', stopId: 's1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final row = find.bySemanticsIdentifier('edit_stop_window');
      await _scrollUntilVisible(tester, row);
      await tester.tap(row);
      await tester.pumpAndSettle();

      // Sheet aberta — toca 'Limpar'.
      await tester.tap(find.text('Limpar'));
      await tester.pumpAndSettle();

      final routes = container.read(routesProvider);
      final stop = routes
          .firstWhere((r) => r.id == 'r1')
          .stops
          .firstWhere((s) => s.id == 's1');
      expect(
        stop.timeWindowStart,
        isNull,
        reason:
            '"Limpar" deve chamar copyWith(timeWindowStart: null) — _omit LIMPA',
      );
      expect(
        stop.timeWindowEnd,
        isNull,
        reason:
            '"Limpar" deve chamar copyWith(timeWindowEnd: null) — _omit LIMPA',
      );
    });

    // ── 15.7  Fluxo set: stop sem janela → numpad row1 → confirmar → provider ─

    testWidgets(
        '15.7 — stop sem janela → sheet → numpad "Chegar entre" → 9 + :30 + '
        'confirm → "Concluído" → provider: timeWindowStart == 09:30, '
        'timeWindowEnd == null (H1: um lado só é válido)', (tester) async {
      _useTallFrame(tester);
      final container = ProviderContainer(
        overrides: [
          routesProvider.overrideWith(
            () => _FakeRoutes([
              domain.Route(
                id: 'r1',
                date: DateTime(2026, 5, 27),
                routeState: const domain.RouteState(
                  optimization: domain.OptimizationState.optimized,
                  confirmed: true,
                  started: true,
                ),
                stops: [_stop1], // timeWindowStart == null
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: _buildRouter(routeId: 'r1', stopId: 's1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final row = find.bySemanticsIdentifier('edit_stop_window');
      await _scrollUntilVisible(tester, row);
      await tester.tap(row);
      await tester.pumpAndSettle();

      // Sheet aberta — toca a row 'Chegar entre' para abrir o numpad.
      await tester.tap(find.bySemanticsIdentifier('edit_stop_window_start'));
      await tester.pumpAndSettle();

      // Digita '9' + ':30' no numpad.
      await tester.tap(find.bySemanticsIdentifier('time_picker_digit_9'));
      await tester.pump();
      await tester.tap(find.bySemanticsIdentifier('time_picker_shortcut_30'));
      await tester.pump();

      // Confirma no numpad.
      await tester.tap(find.bySemanticsIdentifier('time_picker_confirm'));
      await tester.pumpAndSettle();

      // Numpad fechou; a sheet principal ainda está aberta.
      expect(find.byType(TimePickerSheet), findsNothing);

      // Confirma com 'Concluído' da sheet (última ocorrência no overlay).
      await tester.tap(find.text('Concluído').last);
      await tester.pumpAndSettle();

      final routes = container.read(routesProvider);
      final stop = routes
          .firstWhere((r) => r.id == 'r1')
          .stops
          .firstWhere((s) => s.id == 's1');
      expect(
        stop.timeWindowStart,
        const TimeOfDay(hour: 9, minute: 30),
        reason:
            'F3: "Concluído" deve gravar timeWindowStart == 09:30 no provider',
      );
      expect(
        stop.timeWindowEnd,
        isNull,
        reason: 'H1: um lado só é válido — timeWindowEnd deve permanecer null',
      );
    });
  });

  // ── 16. Tempo na parada (F9/H14) + Localizador de pacotes (F11/H13) ────────
  //
  // ATENÇÃO: estes testes precisam de InMemorySharedPreferencesAsync porque a
  // página passará a ref.watch(settingsControllerProvider) após implementação.
  // O setUp global registra a plataforma em memória para que os grupos antigos
  // (que não tocam settings) continuem verdes.

  group('16 — Tempo na parada + Localizador (F9/F11/H14)', () {
    setUp(() {
      // Isola SharedPreferences de disco para todos os testes deste grupo.
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    // ── 16.1  Formatação da row Tempo na parada ───────────────────────────────

    testWidgets(
        '16.1 — stop.estimatedTimeAtStop == null → row exibe '
        '"Padrão (1 min)" (fallback Settings.fallbackStopDuration = 1 min)',
        (tester) async {
      _useTallFrame(tester);
      // _stop1 tem estimatedTimeAtStop == null (default do construtor).
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      final row = find.bySemanticsIdentifier('edit_stop_duration');
      await _scrollUntilVisible(tester, row);

      expect(
        find.text('Padrão (1 min)'),
        findsOneWidget,
        reason:
            'sem override e defaultStopDuration == 1 min → "Padrão (1 min)"',
      );
    });

    testWidgets('16.2 — override Duration(minutes:5) → row exibe "5 min"',
        (tester) async {
      _useTallFrame(tester);
      final stop5 = _stop1.copyWith(
        estimatedTimeAtStop: const Duration(minutes: 5),
      );
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [stop5],
        ),
      );
      await tester.pumpAndSettle();

      final row = find.bySemanticsIdentifier('edit_stop_duration');
      await _scrollUntilVisible(tester, row);

      expect(find.text('5 min'), findsOneWidget);
    });

    testWidgets(
        '16.3 — override Duration(minutes:1, seconds:30) → row exibe "1 min 30 s"',
        (tester) async {
      _useTallFrame(tester);
      final stop130 = _stop1.copyWith(
        estimatedTimeAtStop: const Duration(minutes: 1, seconds: 30),
      );
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [stop130],
        ),
      );
      await tester.pumpAndSettle();

      final row = find.bySemanticsIdentifier('edit_stop_duration');
      await _scrollUntilVisible(tester, row);

      expect(find.text('1 min 30 s'), findsOneWidget);
    });

    testWidgets('16.4 — override Duration(seconds:30) → row exibe "30 s"',
        (tester) async {
      _useTallFrame(tester);
      final stop30s = _stop1.copyWith(
        estimatedTimeAtStop: const Duration(seconds: 30),
      );
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [stop30s],
        ),
      );
      await tester.pumpAndSettle();

      final row = find.bySemanticsIdentifier('edit_stop_duration');
      await _scrollUntilVisible(tester, row);

      expect(find.text('30 s'), findsOneWidget);
    });

    // ── 16.5  Tap na row abre TimeAtStopDialog (sem SnackBar de stub) ─────────

    testWidgets(
        '16.5 — tap na row "Tempo na parada" abre TimeAtStopDialog '
        '(find.text("Minutos") visível); sem SnackBar de stub', (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      final row = find.bySemanticsIdentifier('edit_stop_duration');
      await _scrollUntilVisible(tester, row);
      await tester.tap(row);
      await tester.pumpAndSettle();

      expect(
        find.byType(TimeAtStopDialog),
        findsNothing, // dialog expõe apenas via showDialog — verifica o conteúdo
        reason:
            'TimeAtStopDialog.show usa showDialog, não StatefulWidget direto',
      );
      expect(
        find.text('Minutos'),
        findsAtLeastNWidgets(1),
        reason: 'Tap em "Tempo na parada" deve abrir TimeAtStopDialog',
      );
      expect(
        find.byType(SnackBar),
        findsNothing,
        reason: 'Row não deve mais emitir SnackBar de stub',
      );
    });

    // ── 16.6  Fluxo commit: digitar + dismiss → provider ─────────────────────

    testWidgets(
        '16.6 — stop sem override → dialog → Minutos="5" + barrier dismiss → '
        'provider: estimatedTimeAtStop == Duration(minutes:5)', (tester) async {
      _useTallFrame(tester);
      final container = ProviderContainer(
        overrides: [
          routesProvider.overrideWith(
            () => _FakeRoutes([
              domain.Route(
                id: 'r1',
                date: DateTime(2026, 5, 27),
                routeState: const domain.RouteState(
                  optimization: domain.OptimizationState.optimized,
                  confirmed: true,
                  started: true,
                ),
                stops: [_stop1], // estimatedTimeAtStop == null
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: _buildRouter(routeId: 'r1', stopId: 's1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final row = find.bySemanticsIdentifier('edit_stop_duration');
      await _scrollUntilVisible(tester, row);
      await tester.tap(row);
      await tester.pumpAndSettle();

      // Digita '5' no campo Minutos. O .at(0) vem DEPOIS do descendant —
      // aplicado antes ele pegaria o TextField global 0 (notas da página).
      await tester.enterText(
        find
            .descendant(
              of: find.byType(Dialog),
              matching: find.byType(TextField),
            )
            .at(0),
        '5',
      );
      await tester.pump();

      // Dismiss via barrier.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      final routes = container.read(routesProvider);
      final stop = routes
          .firstWhere((r) => r.id == 'r1')
          .stops
          .firstWhere((s) => s.id == 's1');
      expect(
        stop.estimatedTimeAtStop,
        const Duration(minutes: 5),
        reason: 'commit-on-dismiss: Minutos="5" → estimatedTimeAtStop = 5 min',
      );
    });

    // ── 16.7  Fluxo clear: ambos vazios → provider null ──────────────────────

    testWidgets(
        '16.7 — stop com override → dialog → limpar ambos os campos + '
        'dismiss → provider: estimatedTimeAtStop == null (prova _omit)',
        (tester) async {
      _useTallFrame(tester);
      final stopWithDur =
          _stop1.copyWith(estimatedTimeAtStop: const Duration(minutes: 3));
      final container = ProviderContainer(
        overrides: [
          routesProvider.overrideWith(
            () => _FakeRoutes([
              domain.Route(
                id: 'r1',
                date: DateTime(2026, 5, 27),
                routeState: const domain.RouteState(
                  optimization: domain.OptimizationState.optimized,
                  confirmed: true,
                  started: true,
                ),
                stops: [stopWithDur],
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: _buildRouter(routeId: 'r1', stopId: 's1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final row = find.bySemanticsIdentifier('edit_stop_duration');
      await _scrollUntilVisible(tester, row);
      await tester.tap(row);
      await tester.pumpAndSettle();

      // Limpa Minutos (pré-preenchido com '3'). O .at() vem DEPOIS do
      // descendant — aplicado antes pegaria TextFields globais da página.
      await tester.enterText(
        find
            .descendant(
              of: find.byType(Dialog),
              matching: find.byType(TextField),
            )
            .at(0),
        '',
      );
      // Limpa Segundos (pré-preenchido com '0').
      await tester.enterText(
        find
            .descendant(
              of: find.byType(Dialog),
              matching: find.byType(TextField),
            )
            .at(1),
        '',
      );
      await tester.pump();

      // Dismiss via barrier.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      final routes = container.read(routesProvider);
      final stop = routes
          .firstWhere((r) => r.id == 'r1')
          .stops
          .firstWhere((s) => s.id == 's1');
      expect(
        stop.estimatedTimeAtStop,
        isNull,
        reason:
            'ambos campos vazios → (duration: null) → estimatedTimeAtStop limpo via copyWith _omit',
      );
    });

    // ── 16.8  Opção: default global ≠ fallback ────────────────────────────────
    // Override settingsControllerProvider com 2 min → row exibe 'Padrão (2 min)'.

    testWidgets(
        '16.8 — override settingsController com defaultStopDuration=2min → '
        'row exibe "Padrão (2 min)" (H14: widget lê o global, não re-declara)',
        (tester) async {
      _useTallFrame(tester);

      final container = ProviderContainer(
        overrides: [
          routesProvider.overrideWith(
            () => _FakeRoutes([
              domain.Route(
                id: 'r1',
                date: DateTime(2026, 5, 27),
                routeState: const domain.RouteState(
                  optimization: domain.OptimizationState.optimized,
                  confirmed: true,
                  started: true,
                ),
                stops: [_stop1], // estimatedTimeAtStop == null
              ),
            ]),
          ),
          // Injeta Settings com defaultStopDuration = 2 min.
          settingsControllerProvider.overrideWith(
            () => _FakeSettingsController(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: _buildRouter(routeId: 'r1', stopId: 's1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final row = find.bySemanticsIdentifier('edit_stop_duration');
      await _scrollUntilVisible(tester, row);

      expect(
        find.text('Padrão (2 min)'),
        findsOneWidget,
        reason:
            'H14: row deve refletir o defaultStopDuration do settingsController',
      );
    });

    // ── 16.9  Localizador — formatação da row ─────────────────────────────────

    testWidgets(
        '16.9 — stop sem packageDetails e placeInVehicle → row exibe '
        '"Não definido" (place_in_vehicle_not_set)', (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      final row = find.bySemanticsIdentifier('edit_stop_finder');
      await _scrollUntilVisible(tester, row);

      expect(find.text('Não definido'), findsOneWidget);
    });

    testWidgets(
        '16.10 — stop com PackageDetails(dimension:small, type:box) + '
        'PlaceInVehicle(x:left, y:front, z:floor) → row exibe '
        '"Pequeno, Caixa, Frente, Esquerda, Chão" (F11 — ordem dim,type,Y,X,Z)',
        (tester) async {
      _useTallFrame(tester);
      final stopFull = _stop1.copyWith(
        packageDetails: const PackageDetails(
          dimension: PackageDimension.small,
          type: PackageType.box,
        ),
        placeInVehicle: const PlaceInVehicle(
          x: PlaceX.left,
          y: PlaceY.front,
          z: PlaceZ.floor,
        ),
      );
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [stopFull],
        ),
      );
      await tester.pumpAndSettle();

      final row = find.bySemanticsIdentifier('edit_stop_finder');
      await _scrollUntilVisible(tester, row);

      expect(
        find.text('Pequeno, Caixa, Frente, Esquerda, Chão'),
        findsOneWidget,
        reason: 'F11: ordem dim, type, Y, X, Z separado por ", "',
      );
    });

    testWidgets(
        '16.11 — stop com PackageDetails(dimension:medium) apenas → '
        'row exibe "Médio" (parcial)', (tester) async {
      _useTallFrame(tester);
      final stopPartial = _stop1.copyWith(
        packageDetails:
            const PackageDetails(dimension: PackageDimension.medium),
      );
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [stopPartial],
        ),
      );
      await tester.pumpAndSettle();

      final row = find.bySemanticsIdentifier('edit_stop_finder');
      await _scrollUntilVisible(tester, row);

      expect(find.text('Médio'), findsOneWidget);
    });

    // ── 16.12  Tap na row abre PackageFinderSheet (sem SnackBar de stub) ──────

    testWidgets(
        '16.12 — tap na row "Localizador de pacotes" abre PackageFinderSheet '
        '(find.text("Localizador de pacotes") aparece 2× — row + header da sheet); '
        'sem SnackBar de stub', (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      final row = find.bySemanticsIdentifier('edit_stop_finder');
      await _scrollUntilVisible(tester, row);
      await tester.tap(row);
      await tester.pumpAndSettle();

      // PackageFinderSheet deve estar na árvore (showModalBottomSheet injeta
      // o widget diretamente na árvore — diferente do showDialog).
      expect(
        find.byType(PackageFinderSheet),
        findsOneWidget,
        reason: 'Tap em "Localizador de pacotes" deve abrir PackageFinderSheet',
      );
      // 'Localizador de pacotes' aparece tanto na row (scroll view) quanto no
      // header da sheet (root overlay) — findsNWidgets(2).
      expect(
        find.text('Localizador de pacotes'),
        findsNWidgets(2),
        reason: 'row + header da sheet devem exibir "Localizador de pacotes"',
      );
      expect(
        find.byType(SnackBar),
        findsNothing,
        reason: 'Row não deve mais emitir SnackBar de stub',
      );
    });

    // ── 16.13  Fluxo commit: chips + Concluído → provider ────────────────────

    testWidgets(
        '16.13 — sheet → tap finder_chip_small + finder_chip_front → '
        '"Concluído" (.last) → provider: packageDetails=(small), '
        'placeInVehicle=(y:front)', (tester) async {
      _useTallFrame(tester);
      final container = ProviderContainer(
        overrides: [
          routesProvider.overrideWith(
            () => _FakeRoutes([
              domain.Route(
                id: 'r1',
                date: DateTime(2026, 5, 27),
                routeState: const domain.RouteState(
                  optimization: domain.OptimizationState.optimized,
                  confirmed: true,
                  started: true,
                ),
                stops: [_stop1],
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: _buildRouter(routeId: 'r1', stopId: 's1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final row = find.bySemanticsIdentifier('edit_stop_finder');
      await _scrollUntilVisible(tester, row);
      await tester.tap(row);
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsIdentifier('finder_chip_small'));
      await tester.pump();
      await tester.tap(find.bySemanticsIdentifier('finder_chip_front'));
      await tester.pump();

      // 'Concluído' mais recente na árvore (header da sheet no root overlay).
      await tester.tap(find.text('Concluído').last);
      await tester.pumpAndSettle();

      final routes = container.read(routesProvider);
      final stop = routes
          .firstWhere((r) => r.id == 'r1')
          .stops
          .firstWhere((s) => s.id == 's1');
      expect(
        stop.packageDetails,
        const PackageDetails(dimension: PackageDimension.small),
        reason: 'F3: "Concluído" deve gravar packageDetails live no provider',
      );
      expect(
        stop.placeInVehicle,
        const PlaceInVehicle(y: PlaceY.front),
        reason: 'F3: "Concluído" deve gravar placeInVehicle live no provider',
      );
    });

    // ── 16.14  Fluxo Limpar: stop com dados → Limpar → provider null/null ────

    testWidgets(
        '16.14 — stop com tudo definido → sheet → "Limpar" → '
        'provider: packageDetails == null, placeInVehicle == null (prova _omit)',
        (tester) async {
      _useTallFrame(tester);
      final stopFull = _stop1.copyWith(
        packageDetails: const PackageDetails(
          dimension: PackageDimension.large,
          type: PackageType.bag,
        ),
        placeInVehicle: const PlaceInVehicle(
          y: PlaceY.back,
          x: PlaceX.right,
          z: PlaceZ.shelf,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          routesProvider.overrideWith(
            () => _FakeRoutes([
              domain.Route(
                id: 'r1',
                date: DateTime(2026, 5, 27),
                routeState: const domain.RouteState(
                  optimization: domain.OptimizationState.optimized,
                  confirmed: true,
                  started: true,
                ),
                stops: [stopFull],
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: _buildRouter(routeId: 'r1', stopId: 's1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final row = find.bySemanticsIdentifier('edit_stop_finder');
      await _scrollUntilVisible(tester, row);
      await tester.tap(row);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Limpar'));
      await tester.pumpAndSettle();

      final routes = container.read(routesProvider);
      final stop = routes
          .firstWhere((r) => r.id == 'r1')
          .stops
          .firstWhere((s) => s.id == 's1');
      expect(
        stop.packageDetails,
        isNull,
        reason: '"Limpar" deve zerar packageDetails via copyWith _omit',
      );
      expect(
        stop.placeInVehicle,
        isNull,
        reason: '"Limpar" deve zerar placeInVehicle via copyWith _omit',
      );
    });
  });

  // ── 17. Mudar endereço (H10/H18) ─────────────────────────────────────────
  //
  // Spec T17 (docs/superpowers/plans/2026-06-11-area6-edit-stop-plan.md).
  //
  // Setup: um _buildRouterWithChangeAddress que inclui a subrota
  // 'change-address' apontando para _ChangeAddressStandIn — uma página
  // mínima com botão 'POP_NEW_ADDRESS' que popa o record fixo de teste.
  //
  // NOTE: Os testes 17.1–17.4 falham por assertion enquanto a implementação
  // não existir (edit_stop_page.dart row 'Mudar endereço' é stub SnackBar;
  // add_stop_page.dart não tem o case changeAddress ainda; app.dart não tem
  // a subrota). O 17.3 (H18) também depende de PickerMode.changeAddress, que
  // deve ser adicionado ao enum pelo implementador.

  group('17 — Mudar endereço (H10/H18)', () {
    // ── 17.1  Tap na row → stand-in visível (push aconteceu; sem SnackBar) ─

    testWidgets(
        '17.1 — tap em edit_stop_change_address → _ChangeAddressStandIn '
        'visível; sem SnackBar de stub', (tester) async {
      _useTallFrame(tester);
      final router = _buildRouterWithChangeAddress(
        routeId: 'r1',
        stopId: 's1',
      );
      await tester.pumpWidget(
        _buildApp(router: router, stops: [_stop1]),
      );
      await tester.pumpAndSettle();

      final row = find.bySemanticsIdentifier('edit_stop_change_address');
      await _scrollUntilVisible(tester, row);

      await tester.tap(row);
      await tester.pumpAndSettle();

      // Stand-in visível → push aconteceu.
      expect(find.text('CHANGE_ADDRESS_STAND_IN'), findsOneWidget);
      // Nenhum SnackBar de stub.
      expect(find.byType(SnackBar), findsNothing);
    });

    // ── 17.2  POP_NEW_ADDRESS → editor visível + provider atualizado ────────

    testWidgets(
        '17.2 — tap POP_NEW_ADDRESS → editor visível; provider: '
        'lat/lng/streetName/fullAddress == novos valores; '
        'notes/color/packagesCount preservados (campos não tocados)',
        (tester) async {
      _useTallFrame(tester);

      // Seed com campos extras para verificar que NÃO são tocados.
      final seedStop = _stop1.copyWith(
        notes: 'nota X',
        color: StopColor.blue,
        packagesCount: 7,
      );

      final container = ProviderContainer(
        overrides: [
          routesProvider.overrideWith(
            () => _FakeRoutes([
              domain.Route(
                id: 'r1',
                date: DateTime(2026, 5, 27),
                routeState: const domain.RouteState(
                  optimization: domain.OptimizationState.optimized,
                  confirmed: true,
                  started: true,
                ),
                stops: [seedStop],
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = _buildRouterWithChangeAddress(
        routeId: 'r1',
        stopId: 's1',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Abre o picker (stand-in).
      final row = find.bySemanticsIdentifier('edit_stop_change_address');
      await _scrollUntilVisible(tester, row);
      await tester.tap(row);
      await tester.pumpAndSettle();

      // Tap no botão que popa o record com os novos dados.
      await tester.tap(find.text('POP_NEW_ADDRESS'));
      await tester.pumpAndSettle();

      // Editor deve estar visível de volta.
      expect(find.text('Editar parada'), findsOneWidget);

      // Verifica provider.
      final routes = container.read(routesProvider);
      final stop = routes
          .firstWhere((r) => r.id == 'r1')
          .stops
          .firstWhere((s) => s.id == 's1');

      // Os 4 campos de endereço devem ser os novos.
      expect(stop.lat, closeTo(-23.55, 1e-6));
      expect(stop.lng, closeTo(-46.63, 1e-6));
      expect(stop.streetName, 'Rua Nova, 200');
      expect(stop.fullAddress, 'Rua Nova, 200 - Centro, São Paulo');

      // Os demais campos devem estar preservados.
      expect(stop.notes, 'nota X');
      expect(stop.color, StopColor.blue);
      expect(stop.packagesCount, 7);
    });

    // ── 17.3  H18: sticky resolve para o NOVO endereço ──────────────────────

    testWidgets(
        '17.3 — H18: após POP_NEW_ADDRESS, tap em "Instruções de acesso" → '
        'TextField pré-preenchido com a sticky do NOVO fullAddress '
        '(não do endereço antigo)', (tester) async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final repo = AddressInstructionsRepository(SharedPreferencesAsync());

      // Grava sticky para o NOVO endereço (chave normalizada).
      await repo.saveDefault(
        'Rua Nova, 200 - Centro, São Paulo',
        'portão novo',
      );
      // Garante que o endereço antigo NÃO tem sticky (resolve null).
      // (Não gravar nada para _stop1.fullAddress.)

      // stop sem accessInstructions: a sheet vai tentar o sticky do endereço.
      final container = ProviderContainer(
        overrides: [
          routesProvider.overrideWith(
            () => _FakeRoutes([
              domain.Route(
                id: 'r1',
                date: DateTime(2026, 5, 27),
                routeState: const domain.RouteState(
                  optimization: domain.OptimizationState.optimized,
                  confirmed: true,
                  started: true,
                ),
                stops: [_stop1], // accessInstructions == null
              ),
            ]),
          ),
          addressInstructionsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      // Router com a subrota change-address.
      const location = '/home/routes/active/r1/stops/s1/edit';
      final router = GoRouter(
        initialLocation: location,
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) =>
                const Scaffold(body: Center(child: Text('SENTINEL_HOME'))),
            routes: [
              GoRoute(
                path: 'routes/active/:routeId/stops/:stopId/edit',
                builder: (context, state) => EditStopPage(
                  routeId: state.pathParameters['routeId']!,
                  stopId: state.pathParameters['stopId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'change-address',
                    builder: (_, __) => const _ChangeAddressStandIn(),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      // Configura tela alta.
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Muda o endereço via stand-in.
      final changeRow = find.bySemanticsIdentifier('edit_stop_change_address');
      await _scrollUntilVisible(tester, changeRow);
      await tester.tap(changeRow);
      await tester.pumpAndSettle();

      await tester.tap(find.text('POP_NEW_ADDRESS'));
      await tester.pumpAndSettle();

      // Abre "Instruções de acesso" — deve usar o sticky do NOVO endereço.
      final accessBtn =
          find.bySemanticsIdentifier('edit_stop_access_instructions');
      await _scrollUntilVisible(tester, accessBtn);
      await tester.tap(accessBtn);
      await tester.pumpAndSettle();

      // TextField deve conter o sticky do novo endereço.
      expect(find.text('portão novo'), findsAtLeastNWidgets(1));
      // Sticky do endereço antigo NÃO deve aparecer.
      expect(find.text('portão lateral'), findsNothing);
    });

    // ── 17.4  Back do stand-in (sem valor) → editor intacto ─────────────────

    testWidgets(
        '17.4 — back do stand-in (pop sem valor) → editor visível; '
        'stop INALTERADO no provider', (tester) async {
      _useTallFrame(tester);

      final container = ProviderContainer(
        overrides: [
          routesProvider.overrideWith(
            () => _FakeRoutes([
              domain.Route(
                id: 'r1',
                date: DateTime(2026, 5, 27),
                routeState: const domain.RouteState(
                  optimization: domain.OptimizationState.optimized,
                  confirmed: true,
                  started: true,
                ),
                stops: [_stop1],
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = _buildRouterWithChangeAddress(
        routeId: 'r1',
        stopId: 's1',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Abre o stand-in.
      final row = find.bySemanticsIdentifier('edit_stop_change_address');
      await _scrollUntilVisible(tester, row);
      await tester.tap(row);
      await tester.pumpAndSettle();

      // Volta sem valor (simula "Voltar" / pop sem record).
      await tester.tap(find.text('BACK_NO_VALUE'));
      await tester.pumpAndSettle();

      // Editor deve estar visível de volta.
      expect(find.text('Editar parada'), findsOneWidget);

      // Stop deve estar inalterado.
      final routes = container.read(routesProvider);
      final stop = routes
          .firstWhere((r) => r.id == 'r1')
          .stops
          .firstWhere((s) => s.id == 's1');
      expect(stop.lat, closeTo(-23.5, 1e-6));
      expect(stop.lng, closeTo(-46.6, 1e-6));
      expect(stop.streetName, 'Rua Alfa, 100');
      expect(stop.fullAddress, 'Rua Alfa, 100 - Centro, São Paulo');
    });
  });

  // ── 18. Duplicar + Remover parada (F5/F6/H11) ────────────────────────────
  //
  // Spec: F5 — Duplicar é imediato (sem dialog); insere a cópia logo após a
  // original; em seguida pushReplacement para o editor da duplicata com ?new=1.
  // F6 — Remover mostra AlertDialog de confirmação com streetName do stop no
  // corpo; 'Cancelar' fecha sem mudar nada; 'Remover' → removeStop + pop.
  // H11 — pushReplacement na duplicação: back da duplicata leva a SENTINEL_HOME
  // (editor da original saiu da pilha).
  //
  // Setup: _stop18 com campos custom (notes/color/packagesCount) para provar
  // que a duplicata copia esses campos; _buildRouter18 é um alias do
  // _buildRouter padrão (rota já suporta :stopId dinâmico + ?new=1).
  //
  // Os 6 testes FALHAM enquanto as rows usam _stub (SnackBar) em vez das
  // ações reais.

  group('18 — Duplicar + Remover (F5/F6/H11)', () {
    // ── 18.1  Duplicar: provider ganha 2º stop logo após a original ──────────

    testWidgets(
        '18.1 — tap edit_stop_duplicate → provider: rota tem 2 stops; '
        'índice 1 = duplicata (id ≠ s1, status=pending, campos copiados); '
        'sem AlertDialog; sem SnackBar de stub', (tester) async {
      _useTallFrame(tester);

      // Stop com campos custom para provar que a duplicata os copia.
      final seedStop = _stop1.copyWith(
        notes: 'notas duplicar',
        color: StopColor.blue,
        packagesCount: 5,
      );

      final container = ProviderContainer(
        overrides: [
          routesProvider.overrideWith(
            () => _FakeRoutes([
              domain.Route(
                id: 'r1',
                date: DateTime(2026, 5, 27),
                routeState: const domain.RouteState(
                  optimization: domain.OptimizationState.optimized,
                  confirmed: true,
                  started: true,
                ),
                stops: [seedStop],
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: _buildRouter(routeId: 'r1', stopId: 's1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dupRow = find.bySemanticsIdentifier('edit_stop_duplicate');
      await _scrollUntilVisible(tester, dupRow);
      await tester.tap(dupRow);
      await tester.pumpAndSettle();

      // Rota 'r1' deve ter 2 stops agora.
      final routes = container.read(routesProvider);
      final route = routes.firstWhere((r) => r.id == 'r1');
      expect(
        route.stops.length,
        2,
        reason: 'F5: duplicar deve inserir a cópia — rota passa de 1→2 stops',
      );

      // Stop no índice 1 é a duplicata: id novo.
      final dup = route.stops[1];
      expect(
        dup.id,
        isNot('s1'),
        reason: 'a duplicata deve ter id gerado diferente do original',
      );

      // Status pending e campos de entrega zerados.
      expect(
        dup.status,
        domain.StopStatus.pending,
        reason: 'F5: duplicata deve ter status == pending',
      );
      expect(dup.deliveryId, isNull);
      expect(dup.positionInRoute, isNull);
      expect(dup.photoPaths, isEmpty);

      // Campos copiados do original.
      expect(dup.notes, 'notas duplicar');
      expect(dup.color, StopColor.blue);
      expect(dup.packagesCount, 5);
      expect(dup.streetName, 'Rua Alfa, 100');

      // F5: duplicar é IMEDIATO — sem AlertDialog de confirmação.
      expect(
        find.byType(AlertDialog),
        findsNothing,
        reason: 'F5: duplicar não exige confirmação — sem AlertDialog',
      );

      // Sem SnackBar de stub.
      expect(
        find.byType(SnackBar),
        findsNothing,
        reason: 'row deve agir, não emitir SnackBar de stub',
      );
    });

    // ── 18.2  Duplicar: editor exibido é o da duplicata com badge ────────────

    testWidgets(
        '18.2 — após tap em edit_stop_duplicate, '
        'badge "Adicionada" visível (pushReplacement com ?new=1)',
        (tester) async {
      _useTallFrame(tester);

      final container = ProviderContainer(
        overrides: [
          routesProvider.overrideWith(
            () => _FakeRoutes([
              domain.Route(
                id: 'r1',
                date: DateTime(2026, 5, 27),
                routeState: const domain.RouteState(
                  optimization: domain.OptimizationState.optimized,
                  confirmed: true,
                  started: true,
                ),
                stops: [_stop1],
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: _buildRouter(routeId: 'r1', stopId: 's1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dupRow = find.bySemanticsIdentifier('edit_stop_duplicate');
      await _scrollUntilVisible(tester, dupRow);
      await tester.tap(dupRow);
      await tester.pumpAndSettle();

      // pushReplacement para o editor da duplicata com ?new=1 → badge visível.
      expect(
        find.text('Adicionada'),
        findsOneWidget,
        reason:
            'H11: pushReplacement com ?new=1 deve exibir badge "Adicionada"',
      );
    });

    // ── 18.3  H11 pushReplacement: back leva a SENTINEL_HOME ─────────────────

    testWidgets(
        '18.3 — H11: após duplicar, tap em "Concluído" (pop da duplicata) → '
        'SENTINEL_HOME visível (editor da original saiu da pilha)',
        (tester) async {
      _useTallFrame(tester);

      final container = ProviderContainer(
        overrides: [
          routesProvider.overrideWith(
            () => _FakeRoutes([
              domain.Route(
                id: 'r1',
                date: DateTime(2026, 5, 27),
                routeState: const domain.RouteState(
                  optimization: domain.OptimizationState.optimized,
                  confirmed: true,
                  started: true,
                ),
                stops: [_stop1],
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: _buildRouter(routeId: 'r1', stopId: 's1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Duplica.
      final dupRow = find.bySemanticsIdentifier('edit_stop_duplicate');
      await _scrollUntilVisible(tester, dupRow);
      await tester.tap(dupRow);
      await tester.pumpAndSettle();

      // Agora estamos no editor da duplicata (badge visível).
      expect(find.text('Adicionada'), findsOneWidget);

      // Popa via "Concluído" (header do editor da duplicata).
      final doneBtn = find.bySemanticsIdentifier('edit_stop_done');
      expect(doneBtn, findsOneWidget);
      await tester.tap(doneBtn);
      await tester.pumpAndSettle();

      // H11: pushReplacement — a pilha tem apenas SENTINEL_HOME.
      expect(
        find.text('SENTINEL_HOME'),
        findsOneWidget,
        reason: 'H11: pushReplacement garante que pop da duplicata vai ao '
            'SENTINEL_HOME, não ao editor da original',
      );

      // O editor (original ou duplicata) não deve estar visível.
      expect(find.text('Editar parada'), findsNothing);
    });

    // ── 18.4  Remover: AlertDialog com título + streetName no corpo ───────────

    testWidgets(
        '18.4 — tap edit_stop_remove → AlertDialog visível; '
        'título "Remover parada" (find.byType(AlertDialog)); '
        'corpo contém streetName "Rua Alfa, 100"; sem SnackBar de stub',
        (tester) async {
      _useTallFrame(tester);

      await tester.pumpWidget(
        _buildApp(
          router: _buildRouter(routeId: 'r1', stopId: 's1'),
          stops: [_stop1],
        ),
      );
      await tester.pumpAndSettle();

      final removeRow = find.bySemanticsIdentifier('edit_stop_remove');
      await _scrollUntilVisible(tester, removeRow);
      await tester.tap(removeRow);
      await tester.pumpAndSettle();

      // AlertDialog aberto.
      expect(
        find.byType(AlertDialog),
        findsOneWidget,
        reason: 'F6: tap em "Remover parada" deve abrir AlertDialog',
      );

      // Título: "Remover parada" aparece 2× — label da row + título do dialog.
      // Usamos findsNWidgets(2) ou ancoramos no descendant do AlertDialog.
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Remover parada'),
        ),
        findsOneWidget,
        reason: 'AlertDialog deve ter título "Remover parada"',
      );

      // Corpo contém streetName — pin no streetName, não na frase inteira.
      expect(
        find.textContaining('Rua Alfa, 100'),
        findsAtLeastNWidgets(1),
        reason: 'corpo do dialog deve conter streetName do stop '
            '(remove_stop_confirmation_dialog_text)',
      );

      // Botões presentes.
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Remover'), findsOneWidget);

      // Sem SnackBar de stub.
      expect(
        find.byType(SnackBar),
        findsNothing,
        reason: 'row deve abrir dialog, não emitir SnackBar de stub',
      );
    });

    // ── 18.5  Remover → Cancelar: dialog fecha, stop persiste ────────────────

    testWidgets(
        '18.5 — "Cancelar" no AlertDialog → dialog fecha; '
        'stop AINDA no provider; editor visível', (tester) async {
      _useTallFrame(tester);

      final container = ProviderContainer(
        overrides: [
          routesProvider.overrideWith(
            () => _FakeRoutes([
              domain.Route(
                id: 'r1',
                date: DateTime(2026, 5, 27),
                routeState: const domain.RouteState(
                  optimization: domain.OptimizationState.optimized,
                  confirmed: true,
                  started: true,
                ),
                stops: [_stop1],
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: _buildRouter(routeId: 'r1', stopId: 's1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final removeRow = find.bySemanticsIdentifier('edit_stop_remove');
      await _scrollUntilVisible(tester, removeRow);
      await tester.tap(removeRow);
      await tester.pumpAndSettle();

      // AlertDialog aberto — toca "Cancelar".
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // Dialog deve ter fechado.
      expect(
        find.byType(AlertDialog),
        findsNothing,
        reason: '"Cancelar" deve fechar o dialog',
      );

      // Stop AINDA no provider.
      final routes = container.read(routesProvider);
      final route = routes.firstWhere((r) => r.id == 'r1');
      expect(
        route.stops.length,
        1,
        reason: '"Cancelar" não deve remover o stop',
      );
      expect(route.stops.first.id, 's1');

      // Editor ainda visível.
      expect(find.text('Editar parada'), findsOneWidget);
    });

    // ── 18.6  Remover → Remover: stop some + editor popa ────────────────────

    testWidgets(
        '18.6 — "Remover" no AlertDialog → stop FORA do provider '
        '(rota com 0 stops); SENTINEL_HOME visível (editor popou)',
        (tester) async {
      _useTallFrame(tester);

      final container = ProviderContainer(
        overrides: [
          routesProvider.overrideWith(
            () => _FakeRoutes([
              domain.Route(
                id: 'r1',
                date: DateTime(2026, 5, 27),
                routeState: const domain.RouteState(
                  optimization: domain.OptimizationState.optimized,
                  confirmed: true,
                  started: true,
                ),
                stops: [_stop1],
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: _buildRouter(routeId: 'r1', stopId: 's1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final removeRow = find.bySemanticsIdentifier('edit_stop_remove');
      await _scrollUntilVisible(tester, removeRow);
      await tester.tap(removeRow);
      await tester.pumpAndSettle();

      // AlertDialog aberto — toca "Remover".
      await tester.tap(find.text('Remover'));
      await tester.pumpAndSettle();

      // Stop fora do provider.
      final routes = container.read(routesProvider);
      final route = routes.firstWhere((r) => r.id == 'r1');
      expect(
        route.stops.length,
        0,
        reason: 'F6: "Remover" deve remover o stop do provider',
      );

      // Editor popou — SENTINEL_HOME visível.
      expect(
        find.text('SENTINEL_HOME'),
        findsOneWidget,
        reason:
            'F6: após removeStop, a página deve popar (via handler ou guard H12)',
      );

      // Editor não deve mais estar visível.
      expect(find.text('Editar parada'), findsNothing);

      // Nenhum dialog residual.
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers top-level para o grupo 17 — Mudar endereço
// ─────────────────────────────────────────────────────────────────────────────

/// Constrói um [GoRouter] com a rota de edição aninhada com a subrota
/// `change-address` apontando para [_ChangeAddressStandIn].
///
/// Usado nos testes 17.1, 17.2 e 17.4 onde não é necessário injetar
/// [AddressInstructionsRepository]. Para o 17.3 um router inline equivalente
/// é criado diretamente no teste com o override adicional do repositório.
GoRouter _buildRouterWithChangeAddress({
  required String routeId,
  required String stopId,
}) {
  final location = '/home/routes/active/$routeId/stops/$stopId/edit';
  return GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('SENTINEL_HOME'))),
        routes: [
          GoRoute(
            path: 'routes/active/:routeId/stops/:stopId/edit',
            builder: (context, state) => EditStopPage(
              routeId: state.pathParameters['routeId']!,
              stopId: state.pathParameters['stopId']!,
            ),
            routes: [
              GoRoute(
                path: 'change-address',
                builder: (_, __) => const _ChangeAddressStandIn(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Stand-in para a subrota change-address (grupo 17)
// ─────────────────────────────────────────────────────────────────────────────

/// Página stand-in que simula o [AddStopPage] no modo `changeAddress`.
/// Expõe dois botões:
/// - 'POP_NEW_ADDRESS': popa o record fixo
///   `(lat:-23.55, lng:-46.63, streetName:'Rua Nova, 200',
///     fullAddress:'Rua Nova, 200 - Centro, São Paulo')`.
/// - 'BACK_NO_VALUE': popa sem valor (simula o botão Voltar).
///
/// O EditStopPage inspeciona o resultado: record presente → updateStop;
/// null (back) → nenhuma ação.
class _ChangeAddressStandIn extends StatelessWidget {
  const _ChangeAddressStandIn();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('CHANGE_ADDRESS_STAND_IN'),
            ElevatedButton(
              onPressed: () => context.pop<Object?>(
                (
                  lat: -23.55,
                  lng: -46.63,
                  streetName: 'Rua Nova, 200',
                  fullAddress: 'Rua Nova, 200 - Centro, São Paulo',
                ),
              ),
              child: const Text('POP_NEW_ADDRESS'),
            ),
            ElevatedButton(
              onPressed: () => context.pop<Object?>(null),
              child: const Text('BACK_NO_VALUE'),
            ),
          ],
        ),
      ),
    );
  }
}
