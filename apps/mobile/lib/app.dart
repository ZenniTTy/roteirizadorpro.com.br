import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/auth/presentation/register_page.dart';
import 'features/auth/state/auth_controller.dart';
import 'features/route_config/domain/route_config.dart' show BreakConfig;
import 'features/route_config/presentation/pages/break_scheduler_page.dart';
import 'features/route_config/presentation/pages/route_details_page.dart';
import 'features/route_config/state/picker_mode.dart';
import 'features/routes/presentation/route_shell_page.dart';
import 'features/routes/presentation/wizard_route_page.dart';
import 'features/routes/presentation/reuse_stops_page.dart';
import 'features/routes/presentation/pages/add_stop_page.dart';
import 'features/routes/presentation/pages/add_stop_map_page.dart';
import 'features/routes/presentation/pages/edit_stop_page.dart';

class RoteirizadorProApp extends ConsumerWidget {
  const RoteirizadorProApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);
    return MaterialApp.router(
      title: 'Roteirizador Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}

final _routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      if (auth.isLoading) return null;
      final loggedIn = auth.value != null;
      final loc = state.matchedLocation;
      final onAuthScreen = loc == '/login' || loc == '/register';
      if (!loggedIn && !onAuthScreen) return '/login';
      if (loggedIn && onAuthScreen) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(
        path: '/home',
        builder: (_, __) => const RouteShellPage(),
        routes: [
          GoRoute(
            path: 'routes/create',
            builder: (_, __) => const WizardRoutePage(),
          ),
          GoRoute(
            // Edit metadata (name+date) for an existing route — opened from
            // drawer popup 3-dot "Definir nome e data". Reuses WizardRoutePage
            // parameterised by routeId. Spoke parity §10.3 (inventário).
            path: 'routes/:routeId/edit',
            builder: (_, state) =>
                WizardRoutePage(routeId: state.pathParameters['routeId']),
          ),
          GoRoute(
            path: 'routes/reuse-stops',
            builder: (_, __) => const ReuseStopsPage(),
          ),
          GoRoute(
            path: 'routes/add-stop',
            builder: (_, __) => const AddStopPage(),
            routes: [
              GoRoute(
                path: 'map',
                builder: (_, __) => const AddStopMapPage(),
              ),
            ],
          ),
          GoRoute(
            // Full-screen "Editar parada" (MS-A6, D1) — opened from the
            // active-route sheet's stop cards, from the post-add toast "Ver"
            // and after Duplicar. `?new=1` shows the "Adicionada" badge
            // (F4/F5). Edits apply live per field (F3).
            path: 'routes/active/:routeId/stops/:stopId/edit',
            builder: (_, state) => EditStopPage(
              routeId: state.pathParameters['routeId']!,
              stopId: state.pathParameters['stopId']!,
              showAddedBadge: state.uri.queryParameters['new'] == '1',
            ),
          ),
          GoRoute(
            // Full-screen "Detalhes da rota" — opened from active-route
            // sheet (Area 3, wired in MS7) and from wizard complete FTUE
            // (wired in MS8). Slice 2 Area 5 spec §Architecture.
            path: 'routes/active/:routeId/details',
            builder: (_, state) => RouteDetailsPage(
              routeId: state.pathParameters['routeId']!,
            ),
            routes: [
              GoRoute(
                // Partida sub-picker. Reuses AddStopPage with
                // `PickerMode.startLocation`; the tap on Detalhes da
                // rota's Partida row pushes this route and awaits a
                // `StartLocation` (typed pop result).
                path: 'start-location',
                builder: (_, __) =>
                    const AddStopPage(mode: PickerMode.startLocation),
              ),
              GoRoute(
                // Destino sub-picker (card 2 "Destino em outro endereço").
                // Reuses AddStopPage with `PickerMode.endLocation`; the
                // Destino sheet pops first, then this route is pushed and
                // awaits a `SpecificAddress` (typed pop result). ADR-0043.
                path: 'end-location',
                builder: (_, __) =>
                    const AddStopPage(mode: PickerMode.endLocation),
              ),
              GoRoute(
                // Pausa sub-picker — full-screen "Configure a pausa" page.
                // The "Adicionar pausa" row pushes this with no `extra` (ADD
                // mode); an existing-break row pushes it with the BreakConfig as
                // `extra` (EDIT mode → pre-filled + "Remover pausa"). Awaits a
                // `BreakSchedulerResult` (BreakSaved/BreakRemoved; null on
                // back/cancel). Spoke renders this as a routed page, not a sheet
                // (live capture 2026-06-09). ADR-0044 + ADR-0049.
                path: 'break-scheduler',
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
});

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._ref) {
    _ref.listen(
      authControllerProvider,
      (_, __) => notifyListeners(),
      fireImmediately: false,
    );
  }
  final Ref _ref;
}
