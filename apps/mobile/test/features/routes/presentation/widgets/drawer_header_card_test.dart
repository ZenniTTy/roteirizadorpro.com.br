import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/core/theme/app_theme.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/drawer_header_card.dart';

import '../../_helpers/fake_current_user.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: child),
      ),
    );

void main() {
  testWidgets('shows user name and email', (tester) async {
    await tester.pumpWidget(
      _wrap(
        DrawerHeaderCard(
          user: kUserWithoutSub,
          onHelp: () {},
          onSettings: () {},
          onSubscribe: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Bruno Costa'), findsOneWidget);
    expect(find.text('bruno@example.com'), findsOneWidget);
  });

  testWidgets('Assinar button is PRESENT when user has no active subscription',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        DrawerHeaderCard(
          user: kUserWithoutSub,
          onHelp: () {},
          onSettings: () {},
          onSubscribe: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Assinar'), findsOneWidget);
  });

  testWidgets('Assinar button is ABSENT when user has active subscription',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        DrawerHeaderCard(
          user: kUserWithSub,
          onHelp: () {},
          onSettings: () {},
          onSubscribe: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Assinar'), findsNothing);
  });

  // Help and Settings icons used to live here; per Spoke parity §10.1
  // amendment 2026-05-27, they now render in the sheet's top bar
  // (DrawerSheetTopBar — see app_drawer.dart). The semantics check for
  // their presence moved to app_drawer_test.dart.
}
