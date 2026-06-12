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
import 'package:roteirizador_pro/features/routes/data/address_instructions_repository.dart';
import 'package:roteirizador_pro/features/routes/domain/route.dart' as domain;
import 'package:roteirizador_pro/features/routes/domain/stop.dart' as domain;
import 'package:roteirizador_pro/features/routes/domain/stop_color.dart';
import 'package:roteirizador_pro/features/routes/presentation/pages/edit_stop_page.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/access_instructions_sheet.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/package_count_row.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/stop_notes_section.dart';
import 'package:roteirizador_pro/features/routes/state/address_instructions_controller.dart';
import 'package:roteirizador_pro/features/routes/state/routes_provider.dart';
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
            status: domain.RouteStatus.running,
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
            status: domain.RouteStatus.running,
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
                status: domain.RouteStatus.running,
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
    testWidgets('toque em "Localizador de pacotes" exibe SnackBar (stub)',
        (tester) async {
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

      expect(find.byType(SnackBar), findsOneWidget);
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
                status: domain.RouteStatus.running,
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
                status: domain.RouteStatus.running,
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
                status: domain.RouteStatus.running,
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
                status: domain.RouteStatus.running,
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
                status: domain.RouteStatus.running,
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
}
