import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/core/theme/app_theme.dart';
import 'package:roteirizador_pro/features/routes/domain/route.dart' as domain;
import 'package:roteirizador_pro/features/routes/presentation/route_shell_page.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/app_drawer.dart';
import 'package:roteirizador_pro/features/routes/state/current_user_provider.dart';
import 'package:roteirizador_pro/features/routes/state/routes_provider.dart';

import '../_helpers/fake_current_user.dart';

Widget _wrapPage() => ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(kUserWithoutSub),
        routesProvider.overrideWithValue([
          domain.Route(
            id: 'seed1',
            date: DateTime(2026, 5, 27),
            status: domain.RouteStatus.draft,
          ),
        ]),
      ],
      child: MaterialApp(
        theme: AppTheme.light().copyWith(
          splashFactory: NoSplash.splashFactory,
        ),
        home: const RouteShellPage(),
      ),
    );

void main() {
  testWidgets('renders a Scaffold', (tester) async {
    await tester.pumpWidget(_wrapPage());
    await tester.pump();

    expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
  });

  testWidgets(
      'floating hamburger IconButton with semantics label "Abrir menu" is '
      'present', (tester) async {
    await tester.pumpWidget(_wrapPage());
    await tester.pump();

    expect(find.bySemanticsLabel('Abrir menu'), findsOneWidget);
  });

  testWidgets('tapping the hamburger opens AppDrawer as a modal bottom sheet',
      (tester) async {
    await tester.pumpWidget(_wrapPage());
    await tester.pump();

    expect(find.byType(AppDrawer), findsNothing);

    await tester.tap(find.bySemanticsLabel('Abrir menu'));
    await tester.pump(); // start sheet open animation
    await tester.pump(const Duration(milliseconds: 400)); // settle

    expect(find.byType(AppDrawer), findsOneWidget);
    // The sheet's top bar exposes the close affordance — distinguishes it
    // from any other AppDrawer render.
    expect(find.bySemanticsLabel('Fechar'), findsOneWidget);
  });

  testWidgets(
      'sheet collapsed exposes the OCR / Voice / kebab icons but NOT the '
      'hamburger', (tester) async {
    await tester.pumpWidget(_wrapPage());
    await tester.pump();

    expect(find.bySemanticsLabel('Ler etiqueta de endereço'), findsOneWidget);
    expect(find.bySemanticsLabel('Dite o endereço'), findsOneWidget);
    expect(find.bySemanticsLabel('Mais opções da rota'), findsOneWidget);

    // Hamburger is in the floating button — exactly one in the page.
    expect(find.bySemanticsLabel('Abrir menu'), findsOneWidget);
  });
}
