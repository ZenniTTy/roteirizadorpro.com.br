import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/core/widgets/rp_button.dart';
import 'package:roteirizador_pro/core/widgets/rp_ghost_button.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/presentation/reorder_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

import '../_helpers/fake_stops_repository.dart';
import '../../../_support/phone_surface.dart';

// Wider-than-default test surface; the RpGhostButton "Desenhar o grupo
// seguinte" label overflows at the canonical 400-wide phone size under
// the Ahem font that widget tests fall back to. Production fonts render
// correctly; lift this back to the default once RpGhostButton's label
// supports `Flexible` or a third real consumer pushes the fix into the
// shared widget (tracked in TODO.md).
const _reorderSurface = Size(560, 900);

Stop _s(String id, {double lat = -23.55, double lng = -46.63, String? label}) =>
    Stop(
      id: id,
      lat: lat,
      lng: lng,
      label: label ?? 'L-$id',
      source: StopSource.manual,
      createdAt: DateTime.utc(2026, 5, 19),
    );

Widget _hostReorderPage(
  List<Stop> stops, {
  void Function(BuildContext context)? onReoptimize,
  void Function(BuildContext context)? onDismiss,
}) {
  return ProviderScope(
    overrides: [
      stopsRepositoryProvider.overrideWithValue(FakeStopsRepository(stops)),
    ],
    child: MaterialApp(
      home: ReorderPage(
        onReoptimize: onReoptimize,
        onDismiss: onDismiss,
      ),
    ),
  );
}

// Two-stage pump matching the MS-10 pattern: flutter_map tile fetches are
// indeterminate, so pumpAndSettle deadlocks. One frame + 1 second covers
// the async stops load and the initial map layout.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

/// Flatten a RichText into its rendered string so we can substring-match
/// against the composed "N paradas selecionadas no grupo" line.
String _renderedText(RichText rt) {
  final buffer = StringBuffer();
  void walk(InlineSpan span) {
    if (span is TextSpan) {
      if (span.text != null) buffer.write(span.text);
      for (final c in span.children ?? const <InlineSpan>[]) {
        walk(c);
      }
    }
  }

  walk(rt.text);
  return buffer.toString();
}

void main() {
  testWidgets(
    'Map layer + numbered pins render for geocoded stops',
    (tester) async {
      await phoneSurface(tester, size: _reorderSurface);
      final stops = [
        _s('a', lat: -23.55, lng: -46.63),
        _s('b', lat: -23.56, lng: -46.64),
        _s('c', lat: -23.57, lng: -46.65),
      ];

      await tester.pumpWidget(_hostReorderPage(stops));
      await _settle(tester);

      // Pin labels 1, 2, 3 from RpMiniPin.
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    },
  );

  testWidgets(
    'Dispatcher card renders with persona + body copy',
    (tester) async {
      await phoneSurface(tester, size: _reorderSurface);
      await tester.pumpWidget(_hostReorderPage([_s('a')]));
      await _settle(tester);

      expect(find.text('Despachante'), findsOneWidget);
      expect(
        find.text('Pode ir para Vila Nova Conceição primeiro?'),
        findsOneWidget,
      );
      expect(find.text('8:46'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);
    },
  );

  testWidgets(
    'Bottom panel default state: 0 paradas + both CTAs',
    (tester) async {
      await phoneSurface(tester, size: _reorderSurface);
      await tester.pumpWidget(_hostReorderPage([_s('a')]));
      await _settle(tester);

      // The RichText composes "0 paradas" + " selecionadas no grupo" — the
      // count portion is its own TextSpan so find.text would miss it; the
      // suffix span is reliably searchable on its own.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              _renderedText(w).contains('selecionadas no grupo'),
        ),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(RpGhostButton, 'Desenhar o grupo seguinte'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(RpButton, 'Reotimizar rota'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Tapping "Desenhar o grupo seguinte" is idempotent on empty selection',
    (tester) async {
      await phoneSurface(tester, size: _reorderSurface);
      await tester.pumpWidget(_hostReorderPage([_s('a')]));
      await _settle(tester);

      await tester.tap(
        find.widgetWithText(RpGhostButton, 'Desenhar o grupo seguinte'),
      );
      await tester.pump();

      // Still mounted, still shows the suffix span — no exceptions thrown.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              _renderedText(w).contains('selecionadas no grupo'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Tapping "Reotimizar rota" fires onReoptimize callback',
    (tester) async {
      await phoneSurface(tester, size: _reorderSurface);
      var fired = 0;
      await tester.pumpWidget(
        _hostReorderPage([_s('a')], onReoptimize: (_) => fired++),
      );
      await _settle(tester);

      await tester.tap(find.widgetWithText(RpButton, 'Reotimizar rota'));
      await tester.pump();

      expect(fired, 1);
    },
  );

  testWidgets(
    'Lasso pan records points and renders the CustomPaint stroke',
    (tester) async {
      await phoneSurface(tester, size: _reorderSurface);
      final stops = [
        _s('a', lat: -23.55, lng: -46.63),
        _s('b', lat: -23.56, lng: -46.64),
      ];
      await tester.pumpWidget(_hostReorderPage(stops));
      await _settle(tester);

      // Drag across the gesture overlay. Use raw pointer events so the
      // GestureDetector receives the pan as a pan (not a tap).
      final gesture = await tester.startGesture(const Offset(120, 400));
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 40));
      await tester.pump();
      await gesture.moveBy(const Offset(-40, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(0, -40));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      // The Undo pill only appears when _draggedPoints is non-empty.
      expect(find.text('Desfazer'), findsOneWidget);
    },
  );

  testWidgets(
    'Tapping Undo pill clears the lasso',
    (tester) async {
      await phoneSurface(tester, size: _reorderSurface);
      await tester.pumpWidget(_hostReorderPage([_s('a')]));
      await _settle(tester);

      final gesture = await tester.startGesture(const Offset(120, 400));
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 40));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(find.text('Desfazer'), findsOneWidget);

      await tester.tap(find.text('Desfazer'));
      await tester.pump();

      expect(find.text('Desfazer'), findsNothing);
    },
  );

  testWidgets(
    'Dispatcher card hides after first lasso pan',
    (tester) async {
      await phoneSurface(tester, size: _reorderSurface);
      await tester.pumpWidget(_hostReorderPage([_s('a')]));
      await _settle(tester);

      expect(find.text('Despachante'), findsOneWidget);

      final gesture = await tester.startGesture(const Offset(120, 400));
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(find.text('Despachante'), findsNothing);
    },
  );

  testWidgets(
    'Empty stops list renders the empty-state copy',
    (tester) async {
      await phoneSurface(tester, size: _reorderSurface);
      await tester.pumpWidget(_hostReorderPage(const []));
      await _settle(tester);

      expect(find.text('Nenhuma parada para reordenar.'), findsOneWidget);
    },
  );

  // Pure-function coverage for the lasso geometry. `MapCamera.latLngToScreenOffset`
  // requires a fully laid-out FlutterMap that the widget-test harness can't
  // deterministically produce; covering the algorithm directly side-steps
  // that brittleness.
  group('pointInPolygon — ray-casting geometry', () {
    // 100x100 square at origin.
    const square = <Offset>[
      Offset(0, 0),
      Offset(100, 0),
      Offset(100, 100),
      Offset(0, 100),
    ];

    test('point inside the square is inside', () {
      expect(pointInPolygon(const Offset(50, 50), square), isTrue);
    });

    test('point outside the square is outside', () {
      expect(pointInPolygon(const Offset(150, 50), square), isFalse);
      expect(pointInPolygon(const Offset(-10, 50), square), isFalse);
      expect(pointInPolygon(const Offset(50, -10), square), isFalse);
    });

    test('degenerate polygons (fewer than 3 vertices) are never inside', () {
      expect(pointInPolygon(const Offset(0, 0), const []), isFalse);
      expect(
        pointInPolygon(const Offset(0, 0), const [Offset(0, 0)]),
        isFalse,
      );
      expect(
        pointInPolygon(
          const Offset(50, 50),
          const [Offset(0, 0), Offset(100, 100)],
        ),
        isFalse,
      );
    });

    test('concave (U-shape) excludes the dent and includes the arms', () {
      // U opens upward. Vertices clockwise starting bottom-left.
      const u = <Offset>[
        Offset(0, 100),
        Offset(0, 0),
        Offset(30, 0),
        Offset(30, 60),
        Offset(70, 60),
        Offset(70, 0),
        Offset(100, 0),
        Offset(100, 100),
      ];
      // Inside the left arm.
      expect(pointInPolygon(const Offset(15, 30), u), isTrue);
      // Inside the right arm.
      expect(pointInPolygon(const Offset(85, 30), u), isTrue);
      // Inside the bottom slab.
      expect(pointInPolygon(const Offset(50, 80), u), isTrue);
      // In the dent (the U's hollow).
      expect(pointInPolygon(const Offset(50, 30), u), isFalse);
    });

    test('approximated freeform lasso captures its enclosed centroid', () {
      // 12-vertex approximated circle, radius 40, centered at (50, 50).
      final lasso = <Offset>[
        for (var i = 0; i < 12; i++)
          Offset(
            50 + 40 * math.cos(i * 2 * math.pi / 12),
            50 + 40 * math.sin(i * 2 * math.pi / 12),
          ),
      ];
      expect(pointInPolygon(const Offset(50, 50), lasso), isTrue);
      // Point clearly outside the circle radius.
      expect(pointInPolygon(const Offset(100, 100), lasso), isFalse);
    });
  });
}
