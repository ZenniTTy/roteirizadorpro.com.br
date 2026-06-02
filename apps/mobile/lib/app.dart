import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/auth/presentation/register_page.dart';
import 'features/auth/state/auth_controller.dart';
import 'features/route_config/presentation/pages/route_details_page.dart';
import 'features/routes/presentation/route_shell_page.dart';
import 'features/routes/presentation/wizard_route_page.dart';
import 'features/routes/presentation/reuse_stops_page.dart';
import 'features/routes/presentation/pages/add_stop_page.dart';
import 'features/routes/presentation/pages/add_stop_map_page.dart';

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
            // Full-screen "Detalhes da rota" — opened from active-route
            // sheet (Area 3, wired in MS7) and from wizard complete FTUE
            // (wired in MS8). Slice 2 Area 5 spec §Architecture.
            path: 'routes/active/:routeId/details',
            builder: (_, state) => RouteDetailsPage(
              routeId: state.pathParameters['routeId']!,
            ),
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
