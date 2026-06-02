import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:roteirizador_pro/features/route_config/presentation/widgets/route_config_row.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SafeArea(child: child)));

void main() {
  testWidgets('renders label + trailing value', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const RouteConfigRow(
          semanticsKey: 'partida_local',
          label: 'Local de início',
          trailingValue: 'Usar local atual',
        ),
      ),
    );

    expect(find.text('Local de início'), findsOneWidget);
    expect(find.text('Usar local atual'), findsOneWidget);
  });

  testWidgets('renders trailing chevron icon', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const RouteConfigRow(
          semanticsKey: 'partida_local',
          label: 'Local de início',
          trailingValue: 'Usar local atual',
        ),
      ),
    );

    expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
  });

  testWidgets('Semantics identifier matches "route_details_row_<key>"',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const RouteConfigRow(
          semanticsKey: 'partida_local',
          label: 'Local de início',
          trailingValue: 'Usar local atual',
        ),
      ),
    );

    final found = find.bySemanticsIdentifier('route_details_row_partida_local');
    expect(found, findsOneWidget);
  });

  testWidgets('tap dispatches onTap callback', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        RouteConfigRow(
          semanticsKey: 'partida_local',
          label: 'Local de início',
          trailingValue: 'Usar local atual',
          onTap: () => taps++,
        ),
      ),
    );

    await tester.tap(find.text('Local de início'));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });

  testWidgets('onTap null = no exception on tap', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const RouteConfigRow(
          semanticsKey: 'partida_local',
          label: 'Local de início',
          trailingValue: 'Usar local atual',
        ),
      ),
    );

    await tester.tap(find.text('Local de início'));
    await tester.pumpAndSettle();
    // no exception thrown — pass
  });
}
