import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/delivery_id_chip.dart';

void main() {
  testWidgets('mostra o deliveryId', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: DeliveryIdChip(deliveryId: 'A1')),
    ),);
    expect(find.text('A1'), findsOneWidget);
  });

  testWidgets('deliveryId null mostra "—" (parada não numerada ainda)',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: DeliveryIdChip(deliveryId: null)),
    ),);
    expect(find.text('—'), findsOneWidget);
  });
}
