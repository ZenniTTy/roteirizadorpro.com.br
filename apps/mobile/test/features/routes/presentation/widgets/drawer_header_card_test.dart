import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/core/theme/app_theme.dart';
import 'package:roteirizador_pro/features/routes/domain/user_view_model.dart';
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
          onSubscribe: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Assinar'), findsNothing);
  });

  testWidgets(
      'Assinar button is ABSENT when user is unavailable '
      '(loading/error state)', (tester) async {
    await tester.pumpWidget(
      _wrap(
        DrawerHeaderCard(
          user: UserViewModel.unavailable(),
          onSubscribe: () {},
        ),
      ),
    );
    await tester.pump();

    // unavailable() carries hasActiveSubscription=false but should NOT render
    // the Assinar CTA — that would be misleading while the session is
    // degraded.
    expect(find.text('Assinar'), findsNothing);
    expect(find.text('Sessão indisponível'), findsOneWidget);
  });
}
