import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/features/stops/presentation/shared/home_bottom_nav.dart';

void main() {
  Widget harness({HomeNavTab active = HomeNavTab.route}) {
    return MaterialApp(
      home: Scaffold(
        bottomNavigationBar: HomeBottomNav(active: active),
      ),
    );
  }

  testWidgets('renders two destinations: Rota and Configurações',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('Rota'), findsOneWidget);
    expect(find.text('Configurações'), findsOneWidget);
  });

  testWidgets('highlights the active tab', (tester) async {
    await tester.pumpWidget(harness(active: HomeNavTab.settings));
    await tester.pumpAndSettle();

    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, HomeNavTab.settings.index);
  });
}
