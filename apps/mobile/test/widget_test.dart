import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/app.dart';

void main() {
  testWidgets('login page renders headline and primary CTA',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: RoteirizadorProApp()),
    );
    await tester.pump();

    expect(find.text('Roteirizador Pro'), findsOneWidget);
    expect(find.text('Entregue mais. Chegue em casa cedo.'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Continuar com Google'), findsOneWidget);
  });
}
