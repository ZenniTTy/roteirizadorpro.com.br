import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/auth/presentation/register_page.dart';
import 'features/auth/state/auth_controller.dart';
import 'features/routes/presentation/route_shell_page.dart';
import 'features/routes/presentation/wizard_route_page.dart';

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
