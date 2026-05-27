import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:roteirizador_pro/core/theme/app_theme.dart';
import 'package:roteirizador_pro/features/routes/domain/route.dart' as domain;
import 'package:roteirizador_pro/features/routes/presentation/widgets/drawer_route_tile.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/route_kebab_menu.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    );

domain.Route _route(String id) => domain.Route(
      id: id,
      date: DateTime(2026, 5, 27),
      status: domain.RouteStatus.draft,
      name: 'Rota $id',
    );

void main() {
  testWidgets('inactive route renders name in AppColors.text colour',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        DrawerRouteTile(
          route: _route('r1'),
          activeRouteId: null, // no active route
          onTap: () {},
          onKebabAction: (_) {},
        ),
      ),
    );

    final nameWidget = tester.widget<Text>(find.text('Rota r1'));
    expect(nameWidget.style?.color, equals(AppColors.text));
  });

  testWidgets('active route renders name in AppColors.primary colour',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        DrawerRouteTile(
          route: _route('r2'),
          activeRouteId: 'r2', // this tile is active
          onTap: () {},
          onKebabAction: (_) {},
        ),
      ),
    );

    final nameWidget = tester.widget<Text>(find.text('Rota r2'));
    expect(nameWidget.style?.color, equals(AppColors.primary));
  });

  testWidgets('kebab icon is present', (tester) async {
    await tester.pumpWidget(
      _wrap(
        DrawerRouteTile(
          route: _route('r3'),
          activeRouteId: null,
          onTap: () {},
          onKebabAction: (_) {},
        ),
      ),
    );

    // Accept either the icon widget or a semantics label.
    final byIcon = find.byIcon(LucideIcons.ellipsisVertical);
    final bySemantics = find.bySemanticsLabel('Mais opções');
    expect(
      byIcon.evaluate().isNotEmpty || bySemantics.evaluate().isNotEmpty,
      isTrue,
      reason: 'Expected kebab icon (LucideIcons.ellipsisVertical) or '
          'semantics label "Mais opções"',
    );
  });

  testWidgets('kebab is rendered as a RouteKebabMenu widget', (tester) async {
    await tester.pumpWidget(
      _wrap(
        DrawerRouteTile(
          route: _route('r5'),
          activeRouteId: null,
          onTap: () {},
          onKebabAction: (_) {},
        ),
      ),
    );

    expect(find.byType(RouteKebabMenu), findsOneWidget);
  });

  testWidgets('abbreviated date is rendered', (tester) async {
    // Route date: 2026-05-27 → expect some abbreviated form like "27 de mai."
    await tester.pumpWidget(
      _wrap(
        DrawerRouteTile(
          route: _route('r4'),
          activeRouteId: null,
          onTap: () {},
          onKebabAction: (_) {},
        ),
      ),
    );

    // The exact format will contain "mai" (Portuguese abbreviation for May).
    expect(find.textContaining('mai'), findsAtLeastNWidgets(1));
  });
}
