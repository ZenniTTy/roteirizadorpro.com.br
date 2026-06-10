import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:roteirizador_pro/core/theme/app_theme.dart';
import 'package:roteirizador_pro/features/route_config/presentation/widgets/route_config_row.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SafeArea(child: child)));

void main() {
  testWidgets('renders single-column primary label + leading icon',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const RouteConfigRow(
          semanticsKey: 'partida_local',
          label: 'Usar local atual',
          leading: LucideIcons.locateFixed,
        ),
      ),
    );

    expect(find.text('Usar local atual'), findsOneWidget);
    expect(find.byIcon(LucideIcons.locateFixed), findsOneWidget);
  });

  testWidgets('renders subtitle line when provided', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const RouteConfigRow(
          semanticsKey: 'destino',
          label: 'Ida e volta',
          subtitle: 'Viagem de ida e volta a partir do local atual',
          leading: LucideIcons.repeat,
        ),
      ),
    );

    expect(find.text('Ida e volta'), findsOneWidget);
    expect(
      find.text('Viagem de ida e volta a partir do local atual'),
      findsOneWidget,
    );
  });

  testWidgets('omits subtitle widget when subtitle is null', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const RouteConfigRow(
          semanticsKey: 'partida_local',
          label: 'Usar local atual',
          leading: LucideIcons.locateFixed,
        ),
      ),
    );

    // No secondary text in the tree means only the primary label Text exists
    // within this row (chevron is an Icon, not a Text).
    final texts = tester.widgetList<Text>(
      find.descendant(
        of: find.byType(RouteConfigRow),
        matching: find.byType(Text),
      ),
    );
    expect(texts.length, 1);
    expect(texts.first.data, 'Usar local atual');
  });

  testWidgets('renders trailing chevron icon', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const RouteConfigRow(
          semanticsKey: 'partida_local',
          label: 'Usar local atual',
          leading: LucideIcons.locateFixed,
        ),
      ),
    );

    expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
  });

  testWidgets('renders inside Card.outlined (independent bordered card)',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const RouteConfigRow(
          semanticsKey: 'partida_local',
          label: 'Usar local atual',
          leading: LucideIcons.locateFixed,
        ),
      ),
    );

    // Card.outlined hands back a Card widget; the discriminator is non-null
    // BorderSide on the shape. We assert presence of the Card.
    expect(
      find.descendant(
        of: find.byType(RouteConfigRow),
        matching: find.byType(Card),
      ),
      findsOneWidget,
    );
  });

  testWidgets('leading icon uses primary color when active=true',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const RouteConfigRow(
          semanticsKey: 'partida_local',
          label: 'Usar local atual',
          leading: LucideIcons.locateFixed,
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(LucideIcons.locateFixed));
    expect(icon.color, AppColors.primary);
  });

  testWidgets('leading icon uses muted color when active=false',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const RouteConfigRow(
          semanticsKey: 'adicionar_pausa',
          label: 'Adicionar pausa',
          leading: LucideIcons.coffee,
          active: false,
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(LucideIcons.coffee));
    expect(icon.color, AppColors.textMuted);
  });

  testWidgets('Semantics identifier matches "route_details_row_<key>"',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const RouteConfigRow(
          semanticsKey: 'partida_local',
          label: 'Usar local atual',
          leading: LucideIcons.locateFixed,
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
          label: 'Usar local atual',
          leading: LucideIcons.locateFixed,
          onTap: () => taps++,
        ),
      ),
    );

    await tester.tap(find.text('Usar local atual'));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });

  testWidgets('onTap null = no exception on tap', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const RouteConfigRow(
          semanticsKey: 'partida_local',
          label: 'Usar local atual',
          leading: LucideIcons.locateFixed,
        ),
      ),
    );

    await tester.tap(find.text('Usar local atual'));
    await tester.pumpAndSettle();
    // no exception thrown — pass
  });

  testWidgets('long label does not overflow on narrow constraints',
      (tester) async {
    // 360dp is roughly the logical width of Samsung M54 (1080px @ 3x DPR).
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        const RouteConfigRow(
          semanticsKey: 'destino',
          label: 'Voltar ao local de início que é muito longo de verdade',
          leading: LucideIcons.cornerDownLeft,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders trailingValue widget between label and chevron',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const RouteConfigRow(
          semanticsKey: 'partida_inicio',
          label: 'Iniciar agora mesmo',
          leading: LucideIcons.clock,
          trailingValue: Text('99:99'),
        ),
      ),
    );

    expect(find.text('Iniciar agora mesmo'), findsOneWidget);
    expect(find.text('99:99'), findsOneWidget);
    expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
  });

  group('LiveClockLabel', () {
    testWidgets('renders the injected clock as zero-padded HH:MM',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          LiveClockLabel(clock: () => const TimeOfDay(hour: 7, minute: 5)),
        ),
      );

      expect(find.text('07:05'), findsOneWidget);
    });

    testWidgets('ticks: re-reads the clock and updates after the 30s timer',
        (tester) async {
      var minute = 0;
      await tester.pumpWidget(
        _wrap(
          LiveClockLabel(clock: () => TimeOfDay(hour: 9, minute: minute)),
        ),
      );
      expect(find.text('09:00'), findsOneWidget);

      // Advance the injected clock + let the periodic timer fire.
      minute = 1;
      await tester.pump(const Duration(seconds: 30));
      expect(find.text('09:01'), findsOneWidget);
      expect(find.text('09:00'), findsNothing);
    });

    testWidgets('cancels its timer on dispose (no pending-timer assertion)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          LiveClockLabel(clock: () => const TimeOfDay(hour: 1, minute: 2)),
        ),
      );
      expect(find.text('01:02'), findsOneWidget);

      // Replacing the tree disposes the widget; if the timer were not
      // cancelled, the test binding would flag a pending timer at teardown.
      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
      await tester.pump(const Duration(seconds: 60));

      expect(find.text('01:02'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
