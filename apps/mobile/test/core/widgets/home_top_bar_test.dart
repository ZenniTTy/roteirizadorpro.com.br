import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/core/theme/app_theme.dart';
import 'package:roteirizador_pro/core/widgets/home_top_bar.dart';

Future<void> _pump(WidgetTester tester, PreferredSizeWidget appBar) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(appBar: appBar),
    ),
  );
}

void main() {
  group('HomeTopBar', () {
    testWidgets('renders title "Rota de hoje" with size 22 weight 600',
        (tester) async {
      await _pump(tester, const HomeTopBar(count: 0));

      final titleFinder = find.text('Rota de hoje');
      expect(titleFinder, findsOneWidget);

      final title = tester.widget<Text>(titleFinder);
      expect(title.style?.fontSize, 22);
      expect(title.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('ETA chip null state shows "--:--" with muted styling',
        (tester) async {
      await _pump(tester, const HomeTopBar(count: 0));

      final etaText = find.text('--:--');
      expect(etaText, findsOneWidget);

      final widget = tester.widget<Text>(etaText);
      expect(widget.style?.color, const Color(0xFFA09DB0));
    });

    testWidgets('ETA chip non-null state shows the value with primary styling',
        (tester) async {
      await _pump(tester, const HomeTopBar(eta: '~14:30', count: 0));

      final etaText = find.text('~14:30');
      expect(etaText, findsOneWidget);

      final widget = tester.widget<Text>(etaText);
      expect(widget.style?.color, AppColors.primary);
      expect(find.text('--:--'), findsNothing);
    });

    testWidgets('count chip shows the count number', (tester) async {
      await _pump(tester, const HomeTopBar(count: 47));
      expect(find.text('47'), findsOneWidget);
    });

    testWidgets('count chip exposes pluralized Semantics label',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, const HomeTopBar(count: 1));
      expect(find.bySemanticsLabel(RegExp(r'^1 parada\b')), findsOneWidget);

      await _pump(tester, const HomeTopBar(count: 5));
      expect(find.bySemanticsLabel(RegExp(r'^5 paradas\b')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('showMore: true renders the more-vert icon button',
        (tester) async {
      await _pump(tester, const HomeTopBar(count: 0, showMore: true));
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('showMore: false does not render the more-vert icon button',
        (tester) async {
      await _pump(tester, const HomeTopBar(count: 0));
      expect(find.byIcon(Icons.more_vert), findsNothing);
    });

    testWidgets('preferredSize is Size.fromHeight(56)', (tester) async {
      const widget = HomeTopBar(count: 0);
      expect(widget.preferredSize, const Size.fromHeight(56));
    });

    testWidgets('more button fires onMorePressed when tapped', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        HomeTopBar(count: 0, showMore: true, onMorePressed: () => taps++),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });
  });
}
