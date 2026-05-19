import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

/// Two-tab bottom nav shared by the home family (HomeEmptyPage,
/// HomeListPage) per prototipo/ui.jsx:186-211. Built on Material 3
/// NavigationBar with the prototype's primaryLight pill indicator so
/// the visual matches without re-implementing the M3 component.
class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({super.key, this.active = HomeNavTab.route});

  final HomeNavTab active;

  @override
  Widget build(BuildContext context) {
    return NavigationBarTheme(
      data: const NavigationBarThemeData(
        indicatorColor: AppColors.primaryLight,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      child: NavigationBar(
        selectedIndex: active.index,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 72,
        onDestinationSelected: (index) {
          final target = HomeNavTab.values[index];
          if (target == active) return;
          switch (target) {
            case HomeNavTab.route:
              context.go('/home');
            case HomeNavTab.settings:
              context.go('/settings');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.alt_route_outlined),
            selectedIcon: Icon(Icons.alt_route, color: AppColors.primary),
            label: 'Rota',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: AppColors.primary),
            label: 'Configurações',
          ),
        ],
      ),
    );
  }
}

enum HomeNavTab { route, settings }
