import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/pre_confirm_view.dart';

Stop stop(String id) => Stop(
      id: id,
      lat: 0,
      lng: 0,
      streetName: id,
      fullAddress: id,
      deliveryId: 'A1',
    );

void main() {
  testWidgets('mostra o kebab "Opções da rota"; tap dispara onReoptimize',
      (tester) async {
    var reoptimized = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PreConfirmView(
            stops: [stop('a')],
            durationMinutes: 5,
            distanceMeters: 800,
            onRefine: () {},
            onConfirm: () {},
            onStopTap: (_) {},
            onReoptimize: () => reoptimized = true,
          ),
        ),
      ),
    );
    final kebab = find.bySemanticsLabel('Opções da rota');
    expect(kebab, findsOneWidget);
    await tester.tap(kebab);
    expect(reoptimized, isTrue);
  });
}
