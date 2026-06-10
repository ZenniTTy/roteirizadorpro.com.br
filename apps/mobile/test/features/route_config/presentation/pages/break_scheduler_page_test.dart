import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/route_config/domain/route_config.dart';
import 'package:roteirizador_pro/features/route_config/presentation/pages/break_scheduler_page.dart';

/// Pumps a launcher button that pushes [BreakSchedulerPage] as a route and
/// records the popped [BreakConfig] (or null), mirroring how
/// `RouteDetailsPage._onTapAdicionarPausa` awaits the page result. Returns a
/// getter into the recorded value so a test can push, interact, then assert
/// what the page popped.
class _Harness {
  BreakConfig? popped;
  bool resolved = false;
}

Future<_Harness> _pushPage(WidgetTester tester) async {
  // Match the numpad test's viewport so the 4×3 grid + FAB are fully laid out
  // and hittable (the numpad sheet is tall; the default 800×600 test view
  // clips its lower keys, making taps silently miss).
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final harness = _Harness();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                harness.popped = await Navigator.of(context).push<BreakConfig>(
                  MaterialPageRoute(
                    builder: (_) => const BreakSchedulerPage(),
                  ),
                );
                harness.resolved = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return harness;
}

void main() {
  group('BreakSchedulerPage — structure (Spoke baseline, ADR-0044)', () {
    testWidgets('renders the Spoke title + subtitle', (tester) async {
      await _pushPage(tester);
      expect(find.text('Configure a pausa'), findsOneWidget);
      expect(
        find.textContaining('Planeje suas pausas'),
        findsOneWidget,
      );
    });

    testWidgets('renders both section questions', (tester) async {
      await _pushPage(tester);
      expect(find.text('Quando deseja fazer a pausa?'), findsOneWidget);
      expect(find.text('Qual será a duração da pausa?'), findsOneWidget);
    });

    testWidgets('seeds Spoke default window 08:00–15:00', (tester) async {
      await _pushPage(tester);
      expect(find.text('08:00'), findsOneWidget);
      expect(find.text('15:00'), findsOneWidget);
    });

    testWidgets('seeds Spoke default duration "Padrão (30 min)"',
        (tester) async {
      await _pushPage(tester);
      expect(find.text('Padrão (30 min)'), findsOneWidget);
    });

    testWidgets('back arrow + window fields + duration + CTA carry semantics',
        (tester) async {
      await _pushPage(tester);
      expect(
        find.bySemanticsIdentifier('break_scheduler_back'),
        findsOneWidget,
      );
      expect(find.bySemanticsIdentifier('break_from_time'), findsOneWidget);
      expect(find.bySemanticsIdentifier('break_to_time'), findsOneWidget);
      expect(find.bySemanticsIdentifier('break_duration'), findsOneWidget);
      expect(
        find.bySemanticsIdentifier('break_scheduler_confirm'),
        findsOneWidget,
      );
    });
  });

  group('BreakSchedulerPage — behavior (returns-intent)', () {
    testWidgets('"Adicionar pausa" pops the BreakConfig with the defaults',
        (tester) async {
      final harness = await _pushPage(tester);

      await tester.tap(find.bySemanticsIdentifier('break_scheduler_confirm'));
      await tester.pumpAndSettle();

      expect(harness.resolved, isTrue);
      expect(
        harness.popped,
        const BreakConfig(
          fromTime: TimeOfDay(hour: 8, minute: 0),
          toTime: TimeOfDay(hour: 15, minute: 0),
          durationMinutes: 30,
        ),
      );
    });

    testWidgets('back arrow pops null (cancel — no break created)',
        (tester) async {
      final harness = await _pushPage(tester);

      await tester.tap(find.bySemanticsIdentifier('break_scheduler_back'));
      await tester.pumpAndSettle();

      expect(harness.resolved, isTrue);
      expect(harness.popped, isNull);
    });

    testWidgets('editing the "from" time via the numpad updates the window',
        (tester) async {
      final harness = await _pushPage(tester);

      // Open the reused numpad on the "Entre" field and type 09:00 as four
      // digits (the proven sequence from time_picker_sheet_test): 0,9,0,0.
      await tester.tap(find.bySemanticsIdentifier('break_from_time'));
      await tester.pumpAndSettle();
      for (final d in ['0', '9', '0', '0']) {
        await tester.tap(find.bySemanticsIdentifier('time_picker_digit_$d'));
        await tester.pump();
      }
      await tester.tap(find.bySemanticsIdentifier('time_picker_confirm'));
      await tester.pumpAndSettle();

      expect(find.text('09:00'), findsOneWidget);

      await tester.tap(find.bySemanticsIdentifier('break_scheduler_confirm'));
      await tester.pumpAndSettle();
      expect(harness.popped?.fromTime, const TimeOfDay(hour: 9, minute: 0));
    });

    testWidgets(
        'duration dialog applies a typed value and drops the "Padrão" '
        'prefix once edited', (tester) async {
      final harness = await _pushPage(tester);

      await tester.tap(find.bySemanticsIdentifier('break_duration'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.bySemanticsIdentifier('break_duration_input'),
        '45',
      );
      await tester.pump();
      await tester.tap(find.bySemanticsIdentifier('break_duration_confirm'));
      await tester.pumpAndSettle();

      // Edited → bare "45 min", no "Padrão" prefix.
      expect(find.text('45 min'), findsOneWidget);
      expect(find.text('Padrão (30 min)'), findsNothing);

      await tester.tap(find.bySemanticsIdentifier('break_scheduler_confirm'));
      await tester.pumpAndSettle();
      expect(harness.popped?.durationMinutes, 45);
    });

    testWidgets(
        're-confirming the default 30 (unchanged) keeps the "Padrão (30 min)" '
        'framing — the prefix denotes the default VALUE, not a touched-flag',
        (tester) async {
      await _pushPage(tester);

      await tester.tap(find.bySemanticsIdentifier('break_duration'));
      await tester.pumpAndSettle();
      // Definir without changing the pre-filled "30".
      await tester.tap(find.bySemanticsIdentifier('break_duration_confirm'));
      await tester.pumpAndSettle();

      // Still "Padrão (30 min)" — re-confirming 30 didn't change it away.
      expect(find.text('Padrão (30 min)'), findsOneWidget);
      expect(find.text('30 min'), findsNothing);
    });

    testWidgets(
        'duration dialog rejects a non-positive value (Definir '
        'disabled, value unchanged)', (tester) async {
      final harness = await _pushPage(tester);

      await tester.tap(find.bySemanticsIdentifier('break_duration'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.bySemanticsIdentifier('break_duration_input'),
        '0',
      );
      await tester.pump();

      // Confirm is disabled for 0 — tapping it is a no-op; the value stays 30.
      await tester.tap(find.bySemanticsIdentifier('break_duration_confirm'));
      await tester.pumpAndSettle();

      // Still on the dialog (it didn't close on the invalid value).
      expect(find.text('Duração da pausa (minutos)'), findsOneWidget);

      // Cancel out and confirm the page kept the default 30.
      await tester.tap(find.bySemanticsIdentifier('break_duration_cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Padrão (30 min)'), findsOneWidget);

      await tester.tap(find.bySemanticsIdentifier('break_scheduler_confirm'));
      await tester.pumpAndSettle();
      expect(harness.popped?.durationMinutes, 30);
    });
  });
}
