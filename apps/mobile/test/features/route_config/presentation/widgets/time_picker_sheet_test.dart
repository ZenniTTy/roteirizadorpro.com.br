import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/route_config/presentation/widgets/time_picker_sheet.dart';

/// Pump the [TimePickerSheet] inside a minimal [MaterialApp] so [Material]
/// ancestors required by [InkWell] / [FloatingActionButton] are present.
/// Uses a tall viewport to keep the 4×3 grid + footer in the hit-testable
/// region without per-test resizing.
Future<void> _pumpSheet(
  WidgetTester tester, {
  String title = 'Definir horário de início',
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TimePickerSheet(title: title),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Resolve the InkWell that wraps a digit/shortcut/backspace by the
/// Semantics identifier (per `lesson_maestro_flutter_listtile_tap_needs_
/// semantics` — Flutter widget-test tap targets the InkWell inside the
/// Semantics subtree, not the inner Text node).
Finder _byId(String id) => find.bySemanticsIdentifier(id);

/// Text exclusively inside the live-text header, scoped via the
/// `time_picker_header` Semantics node — keeps the assertion from colliding
/// with identical key labels in the 4×3 grid (e.g. the digit "9" key vs the
/// "9" header live-text).
Finder _headerText(String text) => find.descendant(
      of: _byId('time_picker_header'),
      matching: find.text(text),
    );

Future<void> _tapDigit(WidgetTester tester, String digit) async {
  await tester.tap(_byId('time_picker_digit_$digit'));
  await tester.pump();
}

void main() {
  group('TimePickerSheet — Spoke bsp_time_picker structural parity', () {
    testWidgets('renders header with placeholder title when buffer is empty',
        (tester) async {
      await _pumpSheet(tester, title: 'Definir horário de início');
      expect(_headerText('Definir horário de início'), findsOneWidget);
    });

    testWidgets('renders 12 keys in Spoke grid order: 1-9, :00, 0, :30',
        (tester) async {
      await _pumpSheet(tester);
      for (final d in const [
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
        '8',
        '9',
        '0',
      ]) {
        expect(
          _byId('time_picker_digit_$d'),
          findsOneWidget,
          reason: 'digit $d should be present',
        );
      }
      expect(_byId('time_picker_shortcut_00'), findsOneWidget);
      expect(_byId('time_picker_shortcut_30'), findsOneWidget);
    });

    testWidgets('renders confirm FAB and backspace with Semantics ids',
        (tester) async {
      await _pumpSheet(tester);
      expect(_byId('time_picker_confirm'), findsOneWidget);
      expect(_byId('time_picker_backspace'), findsOneWidget);
    });

    testWidgets('tapping a digit appends to buffer and header shows H format',
        (tester) async {
      await _pumpSheet(tester);
      await _tapDigit(tester, '9');
      // 1 digit → "H" (no colon).
      expect(_headerText('9'), findsOneWidget);
      // Placeholder title is gone once buffer is non-empty.
      expect(_headerText('Definir horário de início'), findsNothing);
    });

    testWidgets('header shows HH after 2 digits, then H:MM, then HH:MM',
        (tester) async {
      await _pumpSheet(tester);
      await _tapDigit(tester, '1');
      await _tapDigit(tester, '2');
      expect(_headerText('12'), findsOneWidget);
      await _tapDigit(tester, '3');
      expect(_headerText('1:23'), findsOneWidget);
      await _tapDigit(tester, '4');
      expect(_headerText('12:34'), findsOneWidget);
    });

    testWidgets('buffer reaches 4 digits → all digit/shortcut keys disable',
        (tester) async {
      await _pumpSheet(tester);
      for (final d in ['1', '0', '3', '0']) {
        await _tapDigit(tester, d);
      }
      expect(_headerText('10:30'), findsOneWidget);

      // Tapping another digit must be a no-op (the inkwell's onTap is null).
      await _tapDigit(tester, '5');
      expect(_headerText('10:30'), findsOneWidget);
      expect(_headerText('10:305'), findsNothing);
    });

    testWidgets(':00 and :30 are disabled when buffer is empty',
        (tester) async {
      await _pumpSheet(tester);
      // Tap with empty buffer is a no-op; header stays on title.
      await tester.tap(_byId('time_picker_shortcut_00'));
      await tester.pump();
      expect(_headerText('Definir horário de início'), findsOneWidget);
    });

    testWidgets(':00 / :30 enabled after 1 hour digit (H:00 valid)',
        (tester) async {
      await _pumpSheet(tester);
      await _tapDigit(tester, '9');
      await tester.tap(_byId('time_picker_shortcut_30'));
      await tester.pump();
      // 9 + 30 → H:MM display = "9:30".
      expect(_headerText('9:30'), findsOneWidget);
    });

    testWidgets(':00 / :30 disabled when leading "25" would yield invalid hour',
        (tester) async {
      await _pumpSheet(tester);
      await _tapDigit(tester, '2');
      await _tapDigit(tester, '5');
      // "25" alone displays as HH.
      expect(_headerText('25'), findsOneWidget);
      // Tapping :00 must NOT append (25 → invalid HH).
      await tester.tap(_byId('time_picker_shortcut_00'));
      await tester.pump();
      expect(_headerText('25'), findsOneWidget);
      expect(_headerText('25:00'), findsNothing);
    });

    testWidgets('backspace disabled at empty buffer; enabled after digit',
        (tester) async {
      await _pumpSheet(tester);
      // Empty buffer: tapping backspace is a no-op (still shows title).
      await tester.tap(_byId('time_picker_backspace'));
      await tester.pump();
      expect(_headerText('Definir horário de início'), findsOneWidget);

      // After a digit, backspace removes it.
      await _tapDigit(tester, '7');
      expect(_headerText('7'), findsOneWidget);
      await tester.tap(_byId('time_picker_backspace'));
      await tester.pump();
      expect(_headerText('Definir horário de início'), findsOneWidget);
    });

    testWidgets('confirm FAB disabled until buffer parses to valid HH:MM',
        (tester) async {
      await _pumpSheet(tester);
      // Empty buffer: onPressed null.
      final fabEmpty = tester.widget<FloatingActionButton>(
        find.descendant(
          of: _byId('time_picker_confirm'),
          matching: find.byType(FloatingActionButton),
        ),
      );
      expect(fabEmpty.onPressed, isNull);

      // Single digit: still invalid (not full HH:MM yet).
      await _tapDigit(tester, '8');
      final fabOneDigit = tester.widget<FloatingActionButton>(
        find.descendant(
          of: _byId('time_picker_confirm'),
          matching: find.byType(FloatingActionButton),
        ),
      );
      expect(fabOneDigit.onPressed, isNull);
    });

    testWidgets('confirm FAB enabled when buffer is a valid HH:MM',
        (tester) async {
      await _pumpSheet(tester);
      for (final d in ['0', '8', '3', '0']) {
        await _tapDigit(tester, d);
      }
      final fab = tester.widget<FloatingActionButton>(
        find.descendant(
          of: _byId('time_picker_confirm'),
          matching: find.byType(FloatingActionButton),
        ),
      );
      expect(fab.onPressed, isNotNull);
    });

    testWidgets('tap confirm pops the sheet with parsed TimeOfDay',
        (tester) async {
      TimeOfDay? returned;
      late BuildContext capturedContext;

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                capturedContext = ctx;
                return ElevatedButton(
                  onPressed: () async {
                    returned = await showModalBottomSheet<TimeOfDay>(
                      context: capturedContext,
                      isScrollControlled: true,
                      useRootNavigator: true,
                      builder: (_) => const TimePickerSheet(
                        title: 'Definir horário de início',
                      ),
                    );
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      for (final d in ['1', '0', '3', '0']) {
        await _tapDigit(tester, d);
      }
      await tester.tap(_byId('time_picker_confirm'));
      await tester.pumpAndSettle();

      expect(returned, const TimeOfDay(hour: 10, minute: 30));
    });

    testWidgets(
        'buffer ALWAYS starts empty even if the sheet is rebuilt '
        '(ADR-0042: never pre-populated)', (tester) async {
      await _pumpSheet(tester);
      // Fresh sheet: header shows the placeholder title, not a time.
      // Scope to the header — `:00`/`:30` shortcut keys in the grid also
      // contain `:` glyphs and would false-positive a global text search.
      expect(_headerText('Definir horário de início'), findsOneWidget);
      expect(
        find.descendant(
          of: _byId('time_picker_header'),
          matching: find.textContaining(':'),
        ),
        findsNothing,
      );
    });
  });
}
