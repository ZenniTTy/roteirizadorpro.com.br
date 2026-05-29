import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/core/theme/app_theme.dart';
import 'package:roteirizador_pro/features/routes/domain/route_action.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/route_kebab_menu.dart';

/// Wraps the widget with a Scaffold so PopupMenuButton has an Overlay to
/// render into (required for Material popup positioning).
Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.light().copyWith(splashFactory: NoSplash.splashFactory),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('RouteKebabMenu', () {
    testWidgets(
        'renders a trigger with semantics label "Mais opções" before popup '
        'opens', (tester) async {
      await tester.pumpWidget(
        _wrap(RouteKebabMenu(onSelected: (_) {})),
      );

      expect(find.bySemanticsLabel('Mais opções'), findsOneWidget);
    });

    testWidgets('tap on trigger opens popup with exactly 3 items',
        (tester) async {
      await tester.pumpWidget(
        _wrap(RouteKebabMenu(onSelected: (_) {})),
      );

      await tester.tap(find.bySemanticsLabel('Mais opções'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Definir nome e data'), findsOneWidget);
      expect(find.text('Duplicar rota'), findsOneWidget);
      expect(find.text('Excluir rota'), findsOneWidget);
    });

    testWidgets('tap "Definir nome e data" dispatches RouteAction.editMeta',
        (tester) async {
      RouteAction? received;

      await tester.pumpWidget(
        _wrap(RouteKebabMenu(onSelected: (a) => received = a)),
      );

      await tester.tap(find.bySemanticsLabel('Mais opções'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Definir nome e data'));
      await tester.pumpAndSettle();

      expect(received, equals(RouteAction.editMeta));
    });

    testWidgets('tap "Duplicar rota" dispatches RouteAction.duplicate',
        (tester) async {
      RouteAction? received;

      await tester.pumpWidget(
        _wrap(RouteKebabMenu(onSelected: (a) => received = a)),
      );

      await tester.tap(find.bySemanticsLabel('Mais opções'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Duplicar rota'));
      await tester.pumpAndSettle();

      expect(received, equals(RouteAction.duplicate));
    });

    testWidgets('tap "Excluir rota" dispatches RouteAction.delete',
        (tester) async {
      RouteAction? received;

      await tester.pumpWidget(
        _wrap(RouteKebabMenu(onSelected: (a) => received = a)),
      );

      await tester.tap(find.bySemanticsLabel('Mais opções'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Excluir rota'));
      await tester.pumpAndSettle();

      expect(received, equals(RouteAction.delete));
    });

    testWidgets('"Excluir rota" text does NOT use AppColors.error colour',
        (tester) async {
      await tester.pumpWidget(
        _wrap(RouteKebabMenu(onSelected: (_) {})),
      );

      await tester.tap(find.bySemanticsLabel('Mais opções'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final deleteText = tester.widget<Text>(find.text('Excluir rota'));
      expect(
        deleteText.style?.color,
        isNot(equals(AppColors.error)),
        reason:
            'Excluir rota must not use the destructive red (AppColors.error) '
            '— Spoke parity §10.2 + dump 2026-05-27 confirms no destructive colour',
      );
    });

    testWidgets('popup contains no PopupMenuDivider', (tester) async {
      await tester.pumpWidget(
        _wrap(RouteKebabMenu(onSelected: (_) {})),
      );

      await tester.tap(find.bySemanticsLabel('Mais opções'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PopupMenuDivider), findsNothing);
    });

    testWidgets('popup items have no leading Icon inside them', (tester) async {
      await tester.pumpWidget(
        _wrap(RouteKebabMenu(onSelected: (_) {})),
      );

      await tester.tap(find.bySemanticsLabel('Mais opções'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Each PopupMenuItem<RouteAction> child must be a plain Text, not a Row
      // with an Icon — Spoke parity §10.2 confirms no leading icons.
      final firstItem = find.byType(PopupMenuItem<RouteAction>).first;
      expect(
        find.descendant(of: firstItem, matching: find.byType(Icon)),
        findsNothing,
      );
    });
  });
}
