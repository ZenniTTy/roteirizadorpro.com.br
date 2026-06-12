// Área 6 — Editar parada: GoRouter back-stack + sub-surfaces (MS-A6 T19).
//
// Exercises the REAL GoRouter stack on a physical device across the Área-6
// routes, with the SYSTEM Android back (WidgetsBinding.handlePopRoute — the
// exact engine signal GoRouter handles) popping exactly ONE level per hop:
//
//   1. /home                                          (map-free stand-in — see note)
//   2. /home/routes/active/:id/stops/:stopId/edit     (EditStopPage REAL)
//   3. .../edit/change-address                        (AddStopPage, PickerMode.changeAddress)
//
// Plus the modal sub-surfaces (ColorPickerSheet / ArrivalWindowSheet) sendo
// dispensadas pelo system-back SEM popar o editor, o pop do "Concluído" (F3),
// o pushReplacement do Duplicar (H11 — back da duplicata NÃO volta ao editor
// da original) e o Remover com AlertDialog confirm voltando à lista (F6).
//
// This is the branch-stack behavior widget tests cannot catch
// (lesson `slice_checklist_integration_test_gate`).
//
// NOTE — why /home is a stand-in, not RouteShellPage (idiom MS-A5.9/ADR-0046):
// the production shell mounts a live GoogleMap; the PlatformView keeps the
// frame pipeline busy and `tester.pump()` never returns (known
// google_maps_flutter × integration_test deadlock). The stop-card → editor
// hop is covered by widget tests (route_shell_page_test.dart, T7/T9). Every
// screen below /home is the PRODUCTION widget at its PRODUCTION path —
// builders MIRROR app.dart (lesson MS9: stand-in builders que divergem da
// produção mascaram bugs de modo/extra).
//
// Hermetic: SharedPreferencesAsync é in-memory (settings + instruções sticky
// nunca tocam o storage real do device). routesProvider é semeado com uma
// rota r1 + stop s1 via subclass do notifier real (mutações reais herdadas).
//
// Run: cd apps/mobile && flutter test integration_test/area6_edit_stop_flow_test.dart -d RQCW401G33T

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:roteirizador_pro/core/theme/app_theme.dart' show AppColors;
import 'package:roteirizador_pro/features/route_config/state/picker_mode.dart';
import 'package:roteirizador_pro/features/routes/domain/route.dart' as domain;
import 'package:roteirizador_pro/features/routes/domain/stop.dart' as domain;
import 'package:roteirizador_pro/features/routes/presentation/pages/add_stop_page.dart';
import 'package:roteirizador_pro/features/routes/presentation/pages/edit_stop_page.dart';
import 'package:roteirizador_pro/features/routes/state/routes_provider.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Notifier real com seed determinístico: herda TODAS as mutações de
/// produção (updateStop/duplicateStop/removeStop) — só o estado inicial muda.
class _SeededRoutes extends Routes {
  @override
  List<domain.Route> build() => [
        domain.Route(
          id: 'r1',
          date: DateTime(2026, 5, 27),
          status: domain.RouteStatus.running,
          stops: [
            domain.Stop(
              id: 's1',
              lat: -23.5,
              lng: -46.6,
              streetName: 'Rua Alfa, 100',
              fullAddress: 'Rua Alfa, 100 - Centro, São Paulo',
            ),
          ],
        ),
      ];
}

/// Subtree real da Área 6 sob um /home stand-in sem mapa. O builder da rota
/// de edit e da change-address ESPELHAM app.dart (modo via constructor,
/// `?new=1` → showAddedBadge) — lição MS9.
GoRouter _router() => GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => FilledButton(
                  // Stands in for the stop-card tap on the active-route shell
                  // (coberto por widget test — ver header).
                  onPressed: () =>
                      context.push('/home/routes/active/r1/stops/s1/edit'),
                  child: const Text('EDITAR_PARADA'),
                ),
              ),
            ),
          ),
          routes: [
            GoRoute(
              path: 'routes/active/:routeId/stops/:stopId/edit',
              builder: (_, state) => EditStopPage(
                routeId: state.pathParameters['routeId']!,
                stopId: state.pathParameters['stopId']!,
                showAddedBadge: state.uri.queryParameters['new'] == '1',
              ),
              routes: [
                GoRoute(
                  path: 'change-address',
                  builder: (_, __) =>
                      const AddStopPage(mode: PickerMode.changeAddress),
                ),
              ],
            ),
          ],
        ),
      ],
    );

/// Pumps 100ms frames until [finder] reaches the target presence, or fails
/// after [timeout]. With [matchGone] = true, waits for the finder to
/// DISAPPEAR (a pop is proven by the PUSHED route vanishing).
Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 15),
  bool matchGone = false,
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    final present = finder.evaluate().isNotEmpty;
    if (present != matchGone) return;
  }
  fail(
    'Timed out after $timeout waiting for $finder to '
    '${matchGone ? "disappear" : "appear"}',
  );
}

/// System Android back — engine path real (`handlePopRoute` →
/// RootBackButtonDispatcher → GoRouter delegate). Ver area5 header.
Future<void> _androidBack(WidgetTester tester) async {
  await WidgetsBinding.instance.handlePopRoute();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Scrolla a ListView do editor até o finder ficar presente (as rows de
/// ação ficam abaixo da dobra no device).
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  final scroll = find.byType(Scrollable).first;
  for (var i = 0; i < 12; i++) {
    if (finder.evaluate().isNotEmpty) break;
    await tester.drag(scroll, const Offset(0, -250));
    await tester.pump(const Duration(milliseconds: 80));
  }
  await tester.pump(const Duration(milliseconds: 200));
}

/// Font-free theme — mesmo racional do area5 test (GoogleFonts dispara
/// fontsChange pós-teste → assert do binding; nenhum widget sob teste
/// referencia fonte).
ThemeData _fontFreeTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.accent,
    error: AppColors.error,
    brightness: Brightness.light,
  );
  return ThemeData(useMaterial3: true, colorScheme: scheme)
      .copyWith(scaffoldBackgroundColor: AppColors.bg);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Área 6 — editor back-stack: sheets dispensadas por system-back, '
      'change-address popa um nível, Concluído popa, Duplicar é '
      'pushReplacement, Remover confirma e volta', (tester) async {
    // Dispose explícito no FIM do body (não addTearDown — o leak-check de
    // SemanticsHandle roda antes dos tearDowns).
    final semantics = tester.ensureSemantics();

    // Hermetic prefs (settings + instruções sticky in-memory).
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routesProvider.overrideWith(_SeededRoutes.new),
        ],
        child: MaterialApp.router(
          theme: _fontFreeTheme(),
          routerConfig: _router(),
        ),
      ),
    );

    // ── 1. /home stand-in → editor (s1). ──
    await _pumpUntil(tester, find.text('EDITAR_PARADA'));
    await tester.tap(find.text('EDITAR_PARADA'));
    await _pumpUntil(tester, find.text('Editar parada'));
    expect(find.text('Rua Alfa, 100'), findsWidgets);

    // ── 2. Chip de cor → ColorPickerSheet → system-back dispensa a sheet
    // SEM popar o editor. ──
    await tester.tap(find.bySemanticsIdentifier('edit_stop_color_chip'));
    await _pumpUntil(
      tester,
      find.bySemanticsIdentifier('edit_stop_color_blue'),
    );
    await _androidBack(tester);
    await _pumpUntil(
      tester,
      find.bySemanticsIdentifier('edit_stop_color_blue'),
      matchGone: true,
    );
    expect(find.text('Editar parada'), findsOneWidget);

    // ── 3. Row Horário de chegada → ArrivalWindowSheet → system-back
    // dispensa SEM popar o editor. ──
    final windowRow = find.bySemanticsIdentifier('edit_stop_window');
    await _scrollTo(tester, windowRow);
    await tester.tap(windowRow);
    await _pumpUntil(tester, find.text('Chegar entre'));
    await _androidBack(tester);
    await _pumpUntil(tester, find.text('Chegar entre'), matchGone: true);
    expect(find.text('Editar parada'), findsOneWidget);

    // ── 4. Mudar endereço → AddStopPage(changeAddress) REAL no path
    // aninhado → system-back popa UM nível (volta ao editor). ──
    final changeRow = find.bySemanticsIdentifier('edit_stop_change_address');
    await _scrollTo(tester, changeRow);
    await tester.tap(changeRow);
    await _pumpUntil(tester, find.text('Buscar endereço'));
    await _androidBack(tester);
    await _pumpUntil(tester, find.text('Buscar endereço'), matchGone: true);
    expect(find.text('Editar parada'), findsOneWidget);

    // ── 5. Concluído popa o editor (F3 — edits já aplicados live). ──
    await tester.tap(find.bySemanticsIdentifier('edit_stop_done'));
    await _pumpUntil(tester, find.text('Editar parada'), matchGone: true);
    await _pumpUntil(tester, find.text('EDITAR_PARADA'));

    // ── 6. Duplicar (H11): re-entra no editor, duplica → editor da
    // duplicata com badge 'Adicionada' (pushReplacement + ?new=1). ──
    await tester.tap(find.text('EDITAR_PARADA'));
    await _pumpUntil(tester, find.text('Editar parada'));
    final duplicateRow = find.bySemanticsIdentifier('edit_stop_duplicate');
    await _scrollTo(tester, duplicateRow);
    await tester.tap(duplicateRow);
    await _pumpUntil(tester, find.text('Adicionada'));

    // System-back da duplicata → /home DIRETO (o editor da original foi
    // SUBSTITUÍDO na pilha — H11; se fosse push, 'Editar parada' voltaria).
    await _androidBack(tester);
    await _pumpUntil(tester, find.text('Adicionada'), matchGone: true);
    await _pumpUntil(tester, find.text('EDITAR_PARADA'));
    expect(find.text('Editar parada'), findsNothing);

    // ── 7. Remover (F6): re-entra no editor de s1, remove com confirm →
    // volta à lista (/home). ──
    await tester.tap(find.text('EDITAR_PARADA'));
    await _pumpUntil(tester, find.text('Editar parada'));
    final removeRow = find.bySemanticsIdentifier('edit_stop_remove');
    await _scrollTo(tester, removeRow);
    await tester.tap(removeRow);
    await _pumpUntil(tester, find.text('Remover "Rua Alfa, 100" da rota?'));
    await tester.tap(find.text('Remover').last);
    await _pumpUntil(
      tester,
      find.text('Remover "Rua Alfa, 100" da rota?'),
      matchGone: true,
    );
    await _pumpUntil(tester, find.text('EDITAR_PARADA'));
    expect(find.text('Editar parada'), findsNothing);

    semantics.dispose();
  });
}
