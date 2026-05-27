import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roteirizador_pro/features/routes/presentation/wizard_route_page.dart';

void main() {
  group('WizardRoutePage', () {
    testWidgets('renders correctly and has all required widgets', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WizardRoutePage(),
          ),
        ),
      );

      // Verify basic widgets exist (Should fail on UnimplementedError first)
      expect(find.text('Criar rota'), findsOneWidget);
      expect(find.text('Confirmar'), findsOneWidget);
    });
  });
}
