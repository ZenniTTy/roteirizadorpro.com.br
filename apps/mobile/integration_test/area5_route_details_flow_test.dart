// Área 5 — Detalhes da rota: GoRouter sub-picker back-stack chain (MS-A5.9).
//
// Exercises the REAL GoRouter stack on a physical device across the Área-5
// sub-routes, with the SYSTEM Android back (WidgetsApp.didPopRoute — the exact
// engine signal GoRouter handles) popping exactly ONE level at every hop:
//
//   1. /home                                    (map-free placeholder — see note)
//   2. /home/routes/active/:id/details          (RouteDetailsPage)
//   3. .../details/start-location               (AddStopPage, PickerMode.startLocation)
//   4. .../details/end-location                 (AddStopPage, PickerMode.endLocation)
//   5. .../details/break-scheduler              (BreakSchedulerPage)
//
// This is the branch-stack behavior widget tests cannot catch
// (lesson `slice_checklist_integration_test_gate`): a real device + real
// GoRouter + real didPopRoute, verifying each sub-picker pushes and each
// system-back pops exactly one level, never skipping to home or dead-ending.
//
// NOTE — why /home is a placeholder, not RouteShellPage (ADR-0046 decision,
// Eduardo 2026-06-10): the production shell mounts a live GoogleMap. On a real
// device the GoogleMap PlatformView keeps the frame pipeline busy, so
// `tester.pump()` in integration_test never returns — a known
// google_maps_flutter × integration_test deadlock, NOT a defect in our code.
// The shell→Detalhes hop is covered by a widget test
// (route_shell_page_test.dart, MS7). This test mounts the REAL Detalhes,
// AddStopPage, and BreakSchedulerPage widgets at their REAL routes — only the
// map-bearing /home is swapped for a tappable stand-in so the chain under test
// (the fragile sub-route back-stack) runs without the PlatformView hang.
//
// Hermetic: SharedPreferencesAsync is the in-memory substrate so the MS8
// defaults-seed never touches the device's real storage. No auth/network: the
// router is mounted directly, bypassing the redirect.
//
// Run: cd apps/mobile && flutter test integration_test/ -d RQCW401G33T

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:roteirizador_pro/core/theme/app_theme.dart' show AppColors;
import 'package:roteirizador_pro/features/route_config/data/route_defaults_repository.dart';
import 'package:roteirizador_pro/features/route_config/domain/route_config.dart'
    show BreakConfig;
import 'package:roteirizador_pro/features/route_config/presentation/pages/break_scheduler_page.dart';
import 'package:roteirizador_pro/features/route_config/presentation/pages/route_details_page.dart';
import 'package:roteirizador_pro/features/route_config/state/picker_mode.dart';
import 'package:roteirizador_pro/features/route_config/state/route_defaults_controller.dart';
import 'package:roteirizador_pro/features/routes/presentation/pages/add_stop_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// The real Área-5 route subtree, mounted under a map-free /home stand-in so
/// the GoogleMap PlatformView deadlock never fires. Every screen below /home
/// is the PRODUCTION widget at its PRODUCTION path — only /home itself is
/// swapped (see file header).
GoRouter _router() => GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => FilledButton(
                  // Stands in for the ADR-0046 "Configuração de rota" summary
                  // tap that opens Detalhes from the active-route shell.
                  onPressed: () =>
                      context.push('/home/routes/active/r1/details'),
                  child: const Text('ABRIR_DETALHES'),
                ),
              ),
            ),
          ),
          routes: [
            GoRoute(
              path: 'routes/active/:routeId/details',
              builder: (_, state) =>
                  RouteDetailsPage(routeId: state.pathParameters['routeId']!),
              routes: [
                GoRoute(
                  path: 'start-location',
                  builder: (_, __) =>
                      const AddStopPage(mode: PickerMode.startLocation),
                ),
                GoRoute(
                  path: 'end-location',
                  builder: (_, __) =>
                      const AddStopPage(mode: PickerMode.endLocation),
                ),
                GoRoute(
                  path: 'break-scheduler',
                  // Mirror app.dart: ADD mode when pushed with no `extra`, EDIT
                  // mode (pre-filled + "Remover pausa") when the existing-break
                  // row pushes the BreakConfig as `extra`. The earlier stand-in
                  // hard-coded `const BreakSchedulerPage()`, dropping the
                  // `extra` — so the edit tap reopened in ADD mode and
                  // `break_scheduler_remove` never mounted (ADR-0049).
                  builder: (_, state) => BreakSchedulerPage(
                    initialBreak: state.extra as BreakConfig?,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );

/// Pumps 100ms frames until [finder] reaches the target presence, or fails
/// after [timeout]. Default waits for the finder to APPEAR; with
/// [matchGone] = true it waits for the finder to DISAPPEAR (used to prove a
/// pop removed the just-pushed route — a buried route stays mounted, so a pop
/// is proven by the PUSHED route vanishing, not the buried one returning).
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

/// Simulates the SYSTEM Android back button — the exact engine path the OS
/// uses (`SystemNavigator` → `'popRoute'` platform message →
/// `WidgetsBinding.handlePopRoute`, binding.dart:1307/1113). This routes through
/// the `RootBackButtonDispatcher` GoRouter registers (router.dart:244), so the
/// GoRouter delegate's `popRoute` actually fires. (Calling `didPopRoute()` on
/// the `WidgetsApp` State directly does NOT reach GoRouter's dispatcher — that
/// was the first attempt's bug.) This is the behavior widget tests can't
/// exercise faithfully (lesson `keycode_back_dismisses_screen`).
Future<void> _androidBack(WidgetTester tester) async {
  await WidgetsBinding.instance.handlePopRoute();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Font-free theme for the integration test (workflow wf_dd8177f2-f19 verdict).
///
/// The production AppTheme.light() calls GoogleFonts.poppinsTextTheme, which
/// fires up to ~15 fire-and-forget font loads. Each awaits AssetManifest BEFORE
/// the allowRuntimeFetching gate, and a completed/cached load emits a
/// `fontsChange` system message that re-arms a frame AFTER the test's final
/// pump → LiveTestWidgetsFlutterBinding.postTest hits `assert(!_expectingFrame)`.
/// `allowRuntimeFetching = false` does NOT fix it (the async asset tail and the
/// warm device-cache path both escape the flag).
///
/// `grep -rn GoogleFonts lib/` has exactly ONE hit (app_theme.dart:108); the
/// three widgets under test (RouteDetailsPage / AddStopPage / BreakSchedulerPage)
/// inherit typography from the theme and reference no font. This test asserts
/// navigation + back-stack, never typography — so a plain Material textTheme
/// (same ColorScheme as AppTheme.light, minus the Poppins overlay) removes the
/// only code path that reaches loadFontIfNecessary. No production change.
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
      'Área 5 — sub-picker back-stack: Detalhes → Partida/Destino/Pausa, '
      'system Android-back pops exactly one level each time', (tester) async {
    // bySemanticsIdentifier needs an active semantics tree. Dispose the handle
    // explicitly at the END of the body (below) — NOT via addTearDown, because
    // _endOfTestVerifications checks for leaked SemanticsHandles BEFORE the
    // tearDown callbacks run, so an addTearDown dispose is too late.
    final semantics = tester.ensureSemantics();

    // Hermetic prefs: the MS8 defaults-seed reads an empty in-memory store.
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routeDefaultsRepositoryProvider.overrideWithValue(
            RouteDefaultsRepository(SharedPreferencesAsync()),
          ),
        ],
        child: MaterialApp.router(
          theme: _fontFreeTheme(),
          routerConfig: _router(),
        ),
      ),
    );

    // ── Route 1: /home stand-in. ──
    await _pumpUntil(tester, find.text('ABRIR_DETALHES'));

    // ── Route 2: open Detalhes da rota. ──
    await tester.tap(find.text('ABRIR_DETALHES'));
    await _pumpUntil(tester, find.text('Detalhes da rota'));

    // NOTE on assertions: GoRouter `push` keeps the underlying route MOUNTED
    // (covered, not destroyed), so the buried "Detalhes da rota" title stays in
    // the tree while a sub-picker is on top. A pop is therefore proven by the
    // PUSHED route's marker DISAPPEARING (findsNothing on it after back), not by
    // the buried title reappearing — that would pass trivially even if back did
    // nothing. Each back below asserts the just-pushed screen is gone.

    // ── Route 3: Partida row → start-location picker (pushed on top). ──
    await tester
        .tap(find.bySemanticsIdentifier('route_details_row_partida_local'));
    await _pumpUntil(tester, find.text('Buscar endereço'));

    // System back pops ONE level → the picker is gone, Detalhes is interactive
    // again (proven by the Destino row tap landing on the next route).
    await _androidBack(tester);
    await _pumpUntil(tester, find.text('Buscar endereço'), matchGone: true);

    // ── Route 4: Destino row → 3-card sheet → card 2 → end-location. ──
    await tester.tap(find.bySemanticsIdentifier('route_details_row_destino'));
    await _pumpUntil(tester, find.text('Voltar ao ponto de partida'));
    await tester.tap(
      find.bySemanticsIdentifier('destination_card_specific_address'),
    );
    await _pumpUntil(tester, find.text('Buscar endereço'));

    // Back out WITHOUT selecting → picker gone, Detalhes selection untouched
    // (ADR-0043 divergence #6: the sheet is NOT reshown, default stays).
    await _androidBack(tester);
    await _pumpUntil(tester, find.text('Buscar endereço'), matchGone: true);
    // The Destino row still reads its default (selection was not mutated).
    expect(find.text('Ida e volta'), findsWidgets);

    // ── Route 5: Adicionar pausa → break-scheduler page (ADR-0044). ──
    await tester.tap(
      find.bySemanticsIdentifier('route_details_row_adicionar_pausa'),
    );
    await _pumpUntil(tester, find.text('Configure a pausa'));

    // Confirm with defaults → BreakSaved → break appears as a row on Detalhes.
    await tester.tap(find.bySemanticsIdentifier('break_scheduler_confirm'));
    await _pumpUntil(tester, find.text('Pausa de 30 min'));

    // The break row's title mounts as soon as Detalhes re-mounts under the
    // pop, but the Navigator's pop transition (Material ~300ms) still draws a
    // RenderAbsorbPointer barrier over the page for a few frames. Tapping the
    // row before that barrier clears gets the tap absorbed (a RenderOffstage/
    // RenderAbsorbPointer hit-test miss on a device — the exact failure the
    // base run avoided because it never re-entered a popped route). Let the
    // pop transition settle before the edit tap, same 400ms `_androidBack`
    // already uses for the reverse direction.
    await tester.pump(const Duration(milliseconds: 400));

    // ── Route 5b: tap the existing break row → EDIT mode (ADR-0049). On the
    // real device this proves the existing-break row is navigable and the page
    // reopens pre-filled with the "Remover pausa" action. ──
    await tester.tap(find.bySemanticsIdentifier('route_details_row_pausa_0'));
    await _pumpUntil(
      tester,
      find.bySemanticsIdentifier('break_scheduler_remove'),
    );
    expect(find.text('Configure a pausa'), findsOneWidget);

    // Back pops the editor → its title is gone, break still present.
    await _androidBack(tester);
    await _pumpUntil(tester, find.text('Configure a pausa'), matchGone: true);
    expect(find.text('Pausa de 30 min'), findsOneWidget);

    // ── Final back: Detalhes → /home. Detalhes is POPPED (not buried), so its
    // title unmounts. Wait for the title to actually DISAPPEAR (the pop +
    // transition can outlast a single frame — assert via matchGone, not a
    // one-shot findsNothing), then confirm the /home stand-in is back on top. ──
    await _androidBack(tester);
    await _pumpUntil(tester, find.text('Detalhes da rota'), matchGone: true);
    await _pumpUntil(tester, find.text('ABRIR_DETALHES'));

    // Dispose the semantics handle here (end of body) so the leaked-handle
    // check in _endOfTestVerifications, which runs before tearDown, passes.
    semantics.dispose();
  });
}
