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
      'sheet collapsed exposes search pill, big buttons, and kebab — '
      'while floating hamburger remains separate', (tester) async {
    await tester.pumpWidget(_wrapPage());
    await tester.pump();

    // Search pill placeholder is the canonical entry for adding stops.
    expect(find.text('Adicionar parada...'), findsOneWidget);

    // Kebab (gradient circle, "Opções da rota") sits at the right of the
    // search row in the sheet — distinguishes it from the floating
    // map controls.
    expect(find.bySemanticsLabel('Opções da rota'), findsOneWidget);

    // Big buttons (medium-state content) — these are also visible at
    // collapsed sizes thanks to the CustomScrollView's overscroll
    // behaviour (see "drag from empty space" test below).
    expect(find.text('Adicionar paradas'), findsOneWidget);
    expect(
      find.text('Copiar paradas de uma rota anterior'),
      findsOneWidget,
    );

    // Hamburger is in the floating button — exactly one in the page.
    expect(find.bySemanticsLabel('Abrir menu'), findsOneWidget);
  });

  testWidgets(
      'sheet body uses CustomScrollView with a SliverFillRemaining filler '
      '(hasScrollBody: false) so drag from the empty area expands the sheet',
      (tester) async {
    // This is the canonical fix for "DraggableScrollableSheet doesn't expand
    // when dragging in the empty area below the content" (Flutter issues
    // #35758 / #116427). The previous ListView + transparent Container filler
    // was a hack that made the inner list scrollable, so drag gestures on
    // the empty area scrolled the invisible filler INSTEAD of expanding the
    // sheet. CustomScrollView + SliverFillRemaining(hasScrollBody: false)
    // makes the filler NOT consume the gesture, so it propagates to the
    // DraggableScrollableSheet pai and the sheet expands as expected.
    await tester.pumpWidget(_wrapPage());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byType(CustomScrollView),
      findsOneWidget,
      reason:
          'Sheet body must use CustomScrollView (not ListView) so we can pair '
          'a real content sliver with a SliverFillRemaining(hasScrollBody: '
          'false) — see Flutter issues #35758 and #116427. The previous '
          'ListView + transparent Container filler hack caused empty-area '
          'drags to scroll internal content instead of expanding the '
          'DraggableScrollableSheet.',
    );

    // Guard against regression to the ListView hack: there must be no
    // ListView inside the DraggableScrollableSheet builder.
    final draggable = find.byType(DraggableScrollableSheet);
    expect(draggable, findsOneWidget);
    expect(
      find.descendant(of: draggable, matching: find.byType(ListView)),
      findsNothing,
      reason: 'No ListView inside the sheet — the canonical pattern is '
          'CustomScrollView + SliverFillRemaining.',
    );
  });
}
