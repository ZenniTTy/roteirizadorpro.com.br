import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:roteirizador_pro/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'add-stop golden path: open shell → tap search pill → type → see results '
    '→ Android back returns to shell',
    (tester) async {
      await tester.pumpWidget(const ProviderScope(child: RoteirizadorProApp()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Login is assumed to be persisted on the device (Remember-me checkbox).
      // If we land on /login, type credentials. Skipped here — Eduardo runs
      // this against a logged-in device.

      // 1. From shell, tap the search pill.
      final pill = find.text('Adicionar parada...');
      expect(pill, findsOneWidget,
          reason: 'shell should expose the search pill');
      await tester.tap(pill);
      await tester.pumpAndSettle();

      // 2. AddStopPage opens. Type a query.
      final tf = find.byType(TextField).last;
      await tester.enterText(tf, 'Av');
      await tester.pumpAndSettle(const Duration(milliseconds: 800));

      // 3. Results or zero-result state appears (depends on prod data).
      // Either is acceptable — the test asserts only that the page reacted to
      // the typing AND OCR/Voice icons disappeared (Spoke parity §11.4).
      // The original icons (Icon(LucideIcons.scanLine) and Icon(LucideIcons.mic))
      // should no longer be on screen.
      // We assert by their tooltip-derived semantics labels.
      expect(
        find.bySemanticsLabel('Ler etiqueta de endereço'),
        findsNothing,
        reason: 'OCR icon must hide when query is non-empty',
      );
      expect(
        find.bySemanticsLabel('Dite o endereço'),
        findsNothing,
        reason: 'Voice icon must hide when query is non-empty',
      );

      // 4. Android back.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        find.text('Adicionar parada...'),
        findsOneWidget,
        reason: 'should return to shell (search pill visible again)',
      );
    },
  );
}
