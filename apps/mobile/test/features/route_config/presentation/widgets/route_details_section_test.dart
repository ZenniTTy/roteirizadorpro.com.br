import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:roteirizador_pro/core/theme/app_theme.dart';
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
        const RouteDetailsSection(
          title: 'Partida',
          children: [
            RouteConfigRow(
              semanticsKey: 'partida_local',
              label: 'Usar local atual',
              leading: LucideIcons.locateFixed,
            ),
          ],
        ),
      ),
    );

    expect(find.text('Partida'), findsOneWidget);
    expect(find.text('Usar local atual'), findsOneWidget);
  });

  testWidgets('header style is muted small label (not bold primary)',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const RouteDetailsSection(
          title: 'Partida',
          children: [
            RouteConfigRow(
              semanticsKey: 'partida_local',
              label: 'Usar local atual',
              leading: LucideIcons.locateFixed,
            ),
          ],
        ),
      ),
    );

    final header = tester.widget<Text>(find.text('Partida'));
    expect(header.style?.color, AppColors.textMuted);
    expect(header.style?.fontSize, lessThanOrEqualTo(13));
    // Spoke headers are NOT bold — they sit at 500 or below.
    expect(
      (header.style?.fontWeight ?? FontWeight.w400).value,
      lessThanOrEqualTo(FontWeight.w500.value),
    );
  });

  testWidgets('renders each child row passed in', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const RouteDetailsSection(
          title: 'Partida',
          children: [
            RouteConfigRow(
              semanticsKey: 'partida_local',
              label: 'Usar local atual',
              leading: LucideIcons.locateFixed,
            ),
            RouteConfigRow(
              semanticsKey: 'partida_inicio',
              label: 'Iniciar agora mesmo  08:00',
              leading: LucideIcons.clock,
            ),
          ],
        ),
      ),
    );

    expect(find.byType(RouteConfigRow), findsNWidgets(2));
  });

  testWidgets('renders NO checkbox (single global checkbox lives on the page)',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const RouteDetailsSection(
          title: 'Partida',
          children: [
            RouteConfigRow(
              semanticsKey: 'partida_local',
              label: 'Usar local atual',
              leading: LucideIcons.locateFixed,
            ),
          ],
        ),
      ),
    );

    expect(find.byType(Checkbox), findsNothing);
    expect(find.text('Salvar como padrão para próximas rotas'), findsNothing);
  });

  testWidgets('children are siblings (no shared section container)',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const RouteDetailsSection(
          title: 'Partida',
          children: [
            RouteConfigRow(
              semanticsKey: 'partida_local',
              label: 'Usar local atual',
              leading: LucideIcons.locateFixed,
            ),
            RouteConfigRow(
              semanticsKey: 'partida_inicio',
              label: 'Iniciar agora mesmo  08:00',
              leading: LucideIcons.clock,
            ),
          ],
        ),
      ),
    );

    // Each row carries its own Card (Card.outlined inside RouteConfigRow).
    expect(
      find.descendant(
        of: find.byType(RouteDetailsSection),
        matching: find.byType(Card),
      ),
      findsNWidgets(2),
    );
  });
}
