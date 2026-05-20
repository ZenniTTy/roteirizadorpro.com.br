import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

/// Two-tab bottom nav shared by the home family (HomeEmptyPage,
/// HomeListPage) per prototipo/ui.jsx:186-211. Built on Material 3
/// NavigationBar with the prototype's primaryLight pill indicator so
/// the visual matches without re-implementing the M3 component.
///
/// In production each consuming page resolves a [StatefulNavigationShell]
/// via `StatefulNavigationShell.maybeOf(context)` (the shell from ADR-0022)
/// and passes it via [navigationShell]. The shell drives both
/// [NavigationBar.selectedIndex] (`currentIndex`) and the tap handler
/// (`goBranch(index)`), so tab switches preserve each branch's stack.
///
/// When [navigationShell] is null — the case in widget tests that mount the
/// nav under a plain `MaterialApp` — the widget falls back to the legacy
/// [active] prop for selection and `context.go(...)` for navigation. This
/// keeps the 91 widget tests green.
class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    this.active = HomeNavTab.route,
    this.navigationShell,
  });

  final HomeNavTab active;
  final StatefulNavigationShell? navigationShell;

  @override
  Widget build(BuildContext context) {
    final shell = navigationShell;
    final selectedIndex = shell?.currentIndex ?? active.index;
    return NavigationBarTheme(
      data: const NavigationBarThemeData(
        indicatorColor: AppColors.primaryLight,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 72,
        onDestinationSelected: (index) {
          if (shell != null) {
            if (index == shell.currentIndex) return;
            shell.goBranch(index);
            return;
          }
          // Test-only fallback path (no shell ancestor).
          final target = HomeNavTab.values[index];
          if (target.index == selectedIndex) return;
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
