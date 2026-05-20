import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/auth/presentation/register_page.dart';
import 'features/auth/state/auth_controller.dart';
import 'features/settings/presentation/settings_page.dart';
import 'features/stops/presentation/add_stop_page.dart';
import 'features/stops/presentation/add_stops_map_page.dart';
import 'features/stops/presentation/edit_stop_page.dart';
import 'features/stops/presentation/home_page.dart';
import 'features/stops/presentation/map_stops_page.dart';
import 'features/stops/presentation/navigate_page.dart';
import 'features/stops/presentation/ocr_capture_page.dart';
import 'features/stops/presentation/optimize_page.dart';
import 'features/stops/presentation/optimize_route_page.dart';
import 'features/stops/presentation/reorder_page.dart';
import 'features/stops/presentation/route_complete_page.dart';
import 'features/stops/presentation/stop_detail_page.dart';
import 'features/stops/presentation/voice_capture_page.dart';

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
      // While bootstrapping (initial /me roundtrip), keep the user where
      // they are — let the loading state render naturally.
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
      GoRoute(path: '/home', builder: (_, __) => const HomeListPageOrEmpty()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
      GoRoute(path: '/optimize', builder: (_, __) => const OptimizePage()),
      GoRoute(
        path: '/optimize/route',
        builder: (_, __) => const OptimizeRoutePage(),
      ),
      GoRoute(path: '/navigate', builder: (_, __) => const NavigatePage()),
      GoRoute(
        path: '/route-complete',
        builder: (_, __) => const RouteCompletePage(),
      ),
      GoRoute(path: '/stops/add', builder: (_, __) => const AddStopPage()),
      GoRoute(
        path: '/stops/voice',
        builder: (_, __) => const VoiceCapturePage(),
      ),
      GoRoute(
        path: '/stops/ocr',
        builder: (_, __) => const OcrCapturePage(),
      ),
      GoRoute(path: '/stops/map', builder: (_, __) => const MapStopsPage()),
      GoRoute(
        path: '/stops/add-map',
        builder: (_, __) => const AddStopsMapPage(),
      ),
      GoRoute(path: '/stops/reorder', builder: (_, __) => const ReorderPage()),
      GoRoute(
        path: '/stops/:id/edit',
        builder: (_, state) => EditStopPage(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/stops/:id',
        builder: (_, state) => StopDetailPage(id: state.pathParameters['id']!),
      ),
    ],
  );
});

/// Bridges Riverpod's auth state to GoRouter's `refreshListenable`. When the
/// user logs in or out, the listener fires and GoRouter re-evaluates the
/// `redirect` callback.
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
