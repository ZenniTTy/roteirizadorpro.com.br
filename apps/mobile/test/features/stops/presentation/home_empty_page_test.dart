import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/core/widgets/rp_fab.dart';
import 'package:roteirizador_pro/features/stops/presentation/home_empty_page.dart';

void main() {
  Widget harness({void Function(BuildContext)? onAddPressed}) {
    return MaterialApp(
      home: HomeEmptyPage(onAddPressed: onAddPressed),
    );
  }

  testWidgets('HomeEmptyPage shows the empty-state copy and pill',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('Rota de hoje'), findsOneWidget);
    expect(find.text('Nenhuma entrega ainda'), findsOneWidget);
    expect(find.text('Como funciona?'), findsOneWidget);
  });

  testWidgets('FAB tap fires onAddPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(harness(onAddPressed: (_) => taps++));
    await tester.pumpAndSettle();

    final fab = find.byType(RpFab);
    expect(fab, findsOneWidget);

    await tester.tap(fab);
    await tester.pumpAndSettle();

    expect(taps, 1);
  });

  testWidgets('"Como funciona?" pill tap also fires onAddPressed',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(harness(onAddPressed: (_) => taps++));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Como funciona?'));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });
}
