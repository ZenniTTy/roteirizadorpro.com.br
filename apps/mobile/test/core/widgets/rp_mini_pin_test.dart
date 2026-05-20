import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/core/theme/app_theme.dart';
import 'package:roteirizador_pro/core/widgets/rp_mini_pin.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

BoxDecoration _bodyDecoration(WidgetTester tester) {
  final containers = find
      .descendant(
        of: find.byType(RpMiniPin),
        matching: find.byType(Container),
      )
      .evaluate()
      .map((e) => e.widget as Container)
      .toList();
  return containers.firstWhere(
    (c) {
      final d = c.decoration;
      return d is BoxDecoration && d.borderRadius != null;
    },
  ).decoration! as BoxDecoration;
}

void main() {
  group('RpMiniPin', () {
    testWidgets('renders the index number in the body', (tester) async {
      await _pump(tester, const RpMiniPin(index: 7));
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('selected state uses primary background and white text',
        (tester) async {
      await _pump(tester, const RpMiniPin(index: 1, selected: true));

      final decoration = _bodyDecoration(tester);
      expect(decoration.color, AppColors.primary);

      final text = tester.widget<Text>(find.text('1'));
      expect(text.style?.color, Colors.white);
    });

    testWidgets('unselected state uses white background with primary border',
        (tester) async {
      await _pump(tester, const RpMiniPin(index: 3));

      final decoration = _bodyDecoration(tester);
      expect(decoration.color, Colors.white);
      expect(decoration.border?.top.color, AppColors.primary);
      expect(decoration.border?.top.width, 2.0);

      final text = tester.widget<Text>(find.text('3'));
      expect(text.style?.color, AppColors.primary);
    });

    testWidgets('text uses fontSize 10 weight 700', (tester) async {
      await _pump(tester, const RpMiniPin(index: 12));
      final text = tester.widget<Text>(find.text('12'));
      expect(text.style?.fontSize, 10);
      expect(text.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('body has borderRadius 6', (tester) async {
      await _pump(tester, const RpMiniPin(index: 1));
      final decoration = _bodyDecoration(tester);
      expect(decoration.borderRadius, BorderRadius.circular(6));
    });

    testWidgets('tap fires onPressed when provided', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        RpMiniPin(index: 1, onPressed: () => taps++),
      );

      await tester.tap(find.byType(RpMiniPin));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('Semantics label announces index and selection state',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const RpMiniPin(index: 5, selected: true),
      );

      expect(
        find.bySemanticsLabel(RegExp(r'^Parada 5, selecionada\b')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('without onPressed, tap is a no-op and semantics is not button',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, const RpMiniPin(index: 9));

      await tester.tap(find.byType(RpMiniPin));
      await tester.pumpAndSettle();

      final semantics = tester.getSemantics(find.byType(RpMiniPin));
      expect(
        semantics.flagsCollection.isButton,
        isFalse,
      );
      handle.dispose();
    });
  });
}
