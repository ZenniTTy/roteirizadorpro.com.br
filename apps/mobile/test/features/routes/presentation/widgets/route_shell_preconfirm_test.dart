// O switch real (RouteState ativo → PreConfirmView vs sheet DRAFT) vive no
// _RouteShellPageState privado e é coberto pelo integration_test do fechamento
// da Á7. Aqui pinamos a REGRA pública: o PreConfirmView aparece quando
// isPreConfirm e some quando não — idiom do route_shell_optimize_cta_test (PR-A).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/pre_confirm_view.dart';

Stop _stop(String id) => Stop(
      id: id,
      lat: 0,
      lng: 0,
      streetName: id,
      fullAddress: id,
      deliveryId: 'A1',
    );

void main() {
  testWidgets('PreConfirmView visível em PRE-CONFIRM, ausente em DRAFT', (
    tester,
  ) async {
    Widget harness({required bool isPreConfirm}) => MaterialApp(
          home: Scaffold(
            body: isPreConfirm
                ? PreConfirmView(
                    stops: [_stop('a')],
                    durationMinutes: 5,
                    distanceMeters: 800,
                    onRefine: () {},
                    onConfirm: () {},
                    onStopTap: (_) {},
                    onReoptimize: () {},
                  )
                : const SizedBox.shrink(),
          ),
        );

    await tester.pumpWidget(harness(isPreConfirm: false));
    expect(find.byType(PreConfirmView), findsNothing);

    await tester.pumpWidget(harness(isPreConfirm: true));
    expect(find.byType(PreConfirmView), findsOneWidget);
  });
}
