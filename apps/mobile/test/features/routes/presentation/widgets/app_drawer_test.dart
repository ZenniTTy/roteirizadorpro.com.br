import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:roteirizador_pro/core/theme/app_theme.dart';
import 'package:roteirizador_pro/features/routes/domain/route.dart' as domain;
import 'package:roteirizador_pro/features/routes/presentation/widgets/app_drawer.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/drawer_route_list.dart';
import 'package:roteirizador_pro/features/routes/state/current_user_provider.dart';
import 'package:roteirizador_pro/features/routes/state/routes_provider.dart';

import '../../_helpers/fake_current_user.dart';

Widget _wrapDrawer({required List<domain.Route> routes}) => ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(kUserWithoutSub),
        routesProvider.overrideWithValue(routes),
      ],
      child: MaterialApp(
        theme: AppTheme.light().copyWith(
          // ink_sparkle.frag fails to decode under flutter_test on this SDK.
          splashFactory: NoSplash.splashFactory,
        ),
        home: const Scaffold(body: AppDrawer()),
      ),
    );

void main() {
  final kRoutes = [
    domain.Route(
      id: 'r1',
      date: DateTime(2026, 5, 27),
      status: domain.RouteStatus.running,
      name: 'Rota 1',
    ),
  ];

  testWidgets('renders DrawerRouteList and Criar rota CTA with routes present',
      (tester) async {
    await tester.pumpWidget(_wrapDrawer(routes: kRoutes));
    await tester.pump();

    expect(find.byType(DrawerRouteList), findsOneWidget);
    expect(find.text('Criar rota'), findsOneWidget);
  });

  testWidgets('Criar rota CTA has Lucide.plus icon', (tester) async {
    await tester.pumpWidget(_wrapDrawer(routes: kRoutes));
    await tester.pump();

    expect(find.byIcon(LucideIcons.plus), findsOneWidget);
  });

  testWidgets(
      'header and CTA remain visible when routesProvider returns empty list; '
      'no bucket headers rendered', (tester) async {
    await tester.pumpWidget(_wrapDrawer(routes: []));
    await tester.pump();

    expect(find.text('Bruno Costa'), findsOneWidget);
    expect(find.text('Criar rota'), findsOneWidget);
    expect(find.text('Hoje'), findsNothing);
    expect(find.text('Próximas'), findsNothing);
    expect(find.text('Esta semana'), findsNothing);
    expect(find.text('Este mês'), findsNothing);
  });

  testWidgets(
      'top bar contains close (X), Ajuda, and Configurações icon buttons',
      (tester) async {
    await tester.pumpWidget(_wrapDrawer(routes: kRoutes));
    await tester.pump();

    expect(find.bySemanticsLabel('Fechar'), findsOneWidget);
    expect(find.bySemanticsLabel('Ajuda'), findsOneWidget);
    expect(find.bySemanticsLabel('Configurações'), findsOneWidget);
  });
}
