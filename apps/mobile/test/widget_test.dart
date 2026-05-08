import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/app.dart';

void main() {
  testWidgets('placeholder page renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: RoteirizadorProApp()),
    );
    await tester.pump();

    expect(find.text('Roteirizador Pro'), findsOneWidget);
    expect(find.text('EM CONSTRUÇÃO'), findsOneWidget);
  });
}
