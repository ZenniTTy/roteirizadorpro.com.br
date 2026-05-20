import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/core/theme/app_theme.dart';
import 'package:roteirizador_pro/core/widgets/rp_fab.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('RpFab', () {
    testWidgets('renders a 56x56 circle with the plus icon', (tester) async {
      await _pump(tester, RpFab(onPressed: () {}));

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(RpFab),
          matching: find.byType(Container),
        ),
      );
      expect(container.constraints?.maxWidth, 56);
      expect(container.constraints?.maxHeight, 56);

      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.gradient, isA<LinearGradient>());

      final icon = tester.widget<Icon>(find.byIcon(Icons.add));
      expect(icon.size, 26);
      expect(icon.color, Colors.white);
    });

    testWidgets('tap fires onPressed', (tester) async {
      var taps = 0;
      await _pump(tester, RpFab(onPressed: () => taps++));

      await tester.tap(find.byType(RpFab));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('tooltip is mounted with the provided message', (tester) async {
      await _pump(
        tester,
        RpFab(onPressed: () {}, tooltip: 'Adicionar parada'),
      );

      final tooltip = tester.widget<Tooltip>(
        find.descendant(
          of: find.byType(RpFab),
          matching: find.byType(Tooltip),
        ),
      );
      expect(tooltip.message, 'Adicionar parada');
    });

    testWidgets('without tooltip, no Tooltip widget is mounted',
        (tester) async {
      await _pump(tester, RpFab(onPressed: () {}));
      expect(find.byType(Tooltip), findsNothing);
    });

    testWidgets('custom icon is honored', (tester) async {
      await _pump(
        tester,
        RpFab(onPressed: () {}, icon: Icons.mic),
      );
      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.byIcon(Icons.add), findsNothing);
    });
  });
}
