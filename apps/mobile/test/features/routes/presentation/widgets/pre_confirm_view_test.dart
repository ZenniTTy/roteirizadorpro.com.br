import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/delivery_id_chip.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/pre_confirm_view.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/route_summary_row.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Stop _makeStop({
  required String id,
  required String deliveryId,
  required String streetName,
  String? fullAddress,
}) =>
    Stop(
      id: id,
      lat: 0,
      lng: 0,
      streetName: streetName,
      fullAddress: fullAddress ?? '$streetName, 100',
      deliveryId: deliveryId,
    );

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  final stops = [
    _makeStop(id: 'id-1', deliveryId: 'A1', streetName: 'Rua X'),
    _makeStop(id: 'id-2', deliveryId: 'A2', streetName: 'Rua Y'),
  ];

  testWidgets(
    'renderiza RouteSummaryRow, chips de ID, labels de botão e texto de parada',
    (tester) async {
      var refined = false;
      var confirmed = false;

      await tester.pumpWidget(
        _wrap(
          PreConfirmView(
            stops: stops,
            durationMinutes: 30,
            distanceMeters: 3000,
            onRefine: () => refined = true,
            onConfirm: () => confirmed = true,
            onStopTap: (_) {},
            onReoptimize: () {},
          ),
        ),
      );

      // RouteSummaryRow deve aparecer exatamente uma vez
      expect(find.byType(RouteSummaryRow), findsOneWidget);

      // Dois DeliveryIdChips (um por parada)
      expect(find.byType(DeliveryIdChip), findsNWidgets(2));

      // Texto do chip da primeira parada
      expect(find.text('A1'), findsOneWidget);

      // Botões de ação
      expect(find.text('Refinar'), findsOneWidget);
      expect(find.text('Confirmar'), findsOneWidget);

      // Tap em "Refinar" dispara onRefine
      await tester.tap(find.text('Refinar'));
      expect(refined, isTrue);

      // Tap em "Confirmar" dispara onConfirm
      await tester.tap(find.text('Confirmar'));
      expect(confirmed, isTrue);
    },
  );

  testWidgets(
    'renderiza ListView para a lista de paradas',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          PreConfirmView(
            stops: stops,
            durationMinutes: 30,
            distanceMeters: 3000,
            onRefine: () {},
            onConfirm: () {},
            onStopTap: (_) {},
            onReoptimize: () {},
          ),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
    },
  );

  testWidgets(
    'onStopTap recebe o id correto ao tocar em uma parada',
    (tester) async {
      String? tappedId;

      await tester.pumpWidget(
        _wrap(
          PreConfirmView(
            stops: stops,
            durationMinutes: 30,
            distanceMeters: 3000,
            onRefine: () {},
            onConfirm: () {},
            onStopTap: (id) => tappedId = id,
            onReoptimize: () {},
          ),
        ),
      );

      // Toca no ListTile da primeira parada pelo texto do streetName
      await tester.tap(find.text('Rua X'));
      expect(tappedId, equals('id-1'));
    },
  );
}
