import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/route_config/presentation/widgets/route_config_row.dart';
import 'package:roteirizador_pro/features/route_config/presentation/widgets/route_details_section.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: SafeArea(child: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  testWidgets('renders title header above the rows', (tester) async {
    await tester.pumpWidget(
      _wrap(
        RouteDetailsSection(
          title: 'Partida',
          saveAsDefault: true,
          onSaveAsDefaultChanged: (_) {},
          children: const [
            RouteConfigRow(
              semanticsKey: 'partida_local',
              label: 'Local de início',
              trailingValue: 'Usar local atual',
            ),
          ],
        ),
      ),
    );

    expect(find.text('Partida'), findsOneWidget);
    expect(find.text('Local de início'), findsOneWidget);
  });

  testWidgets('renders each child row passed in', (tester) async {
    await tester.pumpWidget(
      _wrap(
        RouteDetailsSection(
          title: 'Partida',
          saveAsDefault: true,
          onSaveAsDefaultChanged: (_) {},
          children: const [
            RouteConfigRow(
              semanticsKey: 'partida_local',
              label: 'Local de início',
              trailingValue: 'Usar local atual',
            ),
            RouteConfigRow(
              semanticsKey: 'partida_inicio',
              label: 'Início',
              trailingValue: '08:00',
            ),
          ],
        ),
      ),
    );

    expect(find.byType(RouteConfigRow), findsNWidgets(2));
  });

  testWidgets(
      'renders footer "Salvar como padrão para próximas rotas" checkbox',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        RouteDetailsSection(
          title: 'Partida',
          saveAsDefault: true,
          onSaveAsDefaultChanged: (_) {},
          children: const [
            RouteConfigRow(
              semanticsKey: 'partida_local',
              label: 'Local de início',
              trailingValue: 'Usar local atual',
            ),
          ],
        ),
      ),
    );

    expect(
      find.text('Salvar como padrão para próximas rotas'),
      findsOneWidget,
    );
    expect(find.byType(Checkbox), findsOneWidget);
  });

  testWidgets('Checkbox toggle dispatches onSaveAsDefaultChanged',
      (tester) async {
    bool? lastValue;
    await tester.pumpWidget(
      _wrap(
        RouteDetailsSection(
          title: 'Partida',
          saveAsDefault: true,
          onSaveAsDefaultChanged: (v) => lastValue = v,
          children: const [
            RouteConfigRow(
              semanticsKey: 'partida_local',
              label: 'Local de início',
              trailingValue: 'Usar local atual',
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(lastValue, false);
  });
}
