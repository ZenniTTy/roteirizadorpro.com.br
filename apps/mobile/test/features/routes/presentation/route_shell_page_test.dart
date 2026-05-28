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
      'sheet collapsed shows ONLY handle + search pill + kebab — big '
      'buttons stay hidden (Spoke parity 2026-05-28)', (tester) async {
    await tester.pumpWidget(_wrapPage());
    await tester.pump();

    // Search pill placeholder is the canonical entry for adding stops.
    expect(find.text('Adicionar parada...'), findsOneWidget);

    // Kebab (gradient circle, "Opções da rota") sits at the right of the
    // search row in the sheet — distinguishes it from the floating
    // map controls.
    expect(find.bySemanticsLabel('Opções da rota'), findsOneWidget);

    // Big buttons devem ESTAR ESCONDIDOS no estado collapsed — Spoke
    // (live 2026-05-28) só renderiza esses botões quando o sheet sobe
    // pra medium+. Nosso showButtons usa
    // currentFraction > collapsedFraction + 0.02; no primeiro pump as
    // duas frações coincidem → botões ocultos.
    expect(find.text('Adicionar parada'), findsNothing);
    expect(find.text('Copiar paradas de uma rota anterior'), findsNothing);

    // Empty state ("Adicione as primeiras paradas...") também só aparece
    // quando o sheet sobe.
    expect(
      find.textContaining('Adicione as primeiras paradas'),
      findsNothing,
    );

    // Hamburger is in the floating button — exactly one in the page.
    expect(find.bySemanticsLabel('Abrir menu'), findsOneWidget);
  });

  testWidgets(
      'shell uses Column { Expanded(map), AnimatedContainer(sheet) } so map '
      'and sheet never overlap — Spoke arch parity', (tester) async {
    // Maestro experiments 2026-05-28 provaram que o padrão canônico
    // (CustomScrollView + SliverFillRemaining) FALHA quando o
    // DraggableScrollableSheet está num Stack com GoogleMap por baixo:
    // o EagerGestureRecognizer do mapa (PlatformView) sempre ganha a arena
    // de hit-test contra o sheet. flutter/flutter#105994 / #28655.
    //
    // O Spoke (canonical white-label source) NÃO empilha map+sheet num
    // Stack — usa Column onde o mapa redimensiona dinamicamente conforme
    // o sheet expande. Mapa nunca está por baixo do sheet → zero conflito
    // de gesto. Replicar essa arquitetura é o fix definitivo.
    //
    // Este test garante a invariante estrutural: NÃO há
    // DraggableScrollableSheet (que requer Stack/Positioned fullscreen pra
    // funcionar); HÁ uma Column com Expanded + AnimatedContainer.
    await tester.pumpWidget(_wrapPage());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Sheet manual, não DraggableScrollableSheet.
    expect(
      find.byType(DraggableScrollableSheet),
      findsNothing,
      reason:
          'O sheet manual via GestureDetector + AnimatedContainer substituiu '
          'o DraggableScrollableSheet (que não funciona dentro de SizedBox '
          'da Column nem coexiste bem com GoogleMap por baixo).',
    );

    // Column é a estrutura raiz do body.
    expect(
      find.descendant(
        of: find.byType(Scaffold),
        matching: find.byType(Column),
      ),
      findsWidgets,
    );

    // AnimatedContainer envolve o sheet (anima a altura entre snaps).
    expect(find.byType(AnimatedContainer), findsAtLeastNWidgets(1));
  });
}
