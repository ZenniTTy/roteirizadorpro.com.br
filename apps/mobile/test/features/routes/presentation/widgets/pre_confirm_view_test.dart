// Tests for PreConfirmView (body) + PreConfirmFooter — Á7 PR-B / Á8 fidelity.
//
// Pós-ADR-0052: a PreConfirmView deixou de ter moldura própria (kebab solto +
// RouteSummaryRow centralizado + AnimatedContainer). Agora é só o BODY da lista
// otimizada (Branch B plano: header summary-à-esquerda → Sem pausa → Ponto de
// partida → paradas (número+ETA+chip) → Destino), e o rodapé é o
// PreConfirmFooter (duração verde + Refinar + Confirmar). A moldura (alça +
// busca + drag) vive no shell. Estes testes pinam o body + o footer.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/delivery_id_chip.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/pre_confirm_view.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/route_step_list.dart';

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

  group('PreConfirmView (body)', () {
    testWidgets(
      'lista otimizada (Branch B): Sem pausa → Ponto de partida → paradas '
      '(chips de ID) → Destino, com header summary à esquerda',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            PreConfirmView(
              stops: stops,
              routeName: 'Minha rota',
              durationMinutes: 30,
              distanceMeters: 3000,
              onStopTap: (_) {},
            ),
          ),
        );

        // Header summary à esquerda: linha 1 (duração·N·distância) + nome bold.
        expect(find.textContaining('30 min'), findsOneWidget);
        expect(find.textContaining('2 paradas'), findsOneWidget);
        expect(find.text('Minha rota'), findsOneWidget);

        // A pausa vem PRIMEIRO (Branch B), integrada no trilho.
        expect(find.byType(RouteBreakStep), findsOneWidget);
        expect(find.text('Sem pausa'), findsOneWidget);

        // Linha de início + destino integradas.
        expect(find.byType(RouteStartStep), findsOneWidget);
        expect(find.text('Ponto de partida'), findsOneWidget);
        expect(find.byType(RouteEndStep), findsOneWidget);

        // Dois chips de ID (um por parada) + o texto do primeiro chip.
        expect(find.byType(DeliveryIdChip), findsNWidgets(2));
        expect(find.text('A1'), findsOneWidget);
      },
    );

    testWidgets(
      'duração/distância 0 → header mostra só "N paradas" (não "0 min · 0,0 km")',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            PreConfirmView(
              stops: stops,
              routeName: 'Rota',
              durationMinutes: 0,
              distanceMeters: 0,
              onStopTap: (_) {},
            ),
          ),
        );

        expect(find.textContaining('2 paradas'), findsOneWidget);
        // Sem placeholder de "0 min" / "0,0 km" (parece bug).
        expect(find.textContaining('0 min'), findsNothing);
        expect(find.textContaining('0,0 km'), findsNothing);
      },
    );

    testWidgets('renderiza ListView para a lista de paradas', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PreConfirmView(
            stops: stops,
            durationMinutes: 30,
            distanceMeters: 3000,
            onStopTap: (_) {},
          ),
        ),
      );
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('onStopTap recebe o id correto ao tocar em uma parada',
        (tester) async {
      String? tappedId;
      await tester.pumpWidget(
        _wrap(
          PreConfirmView(
            stops: stops,
            durationMinutes: 30,
            distanceMeters: 3000,
            onStopTap: (id) => tappedId = id,
          ),
        ),
      );
      await tester.tap(find.text('Rua X'));
      expect(tappedId, equals('id-1'));
    });
  });

  group('PreConfirmFooter', () {
    testWidgets('duração verde + Refinar + Confirmar; callbacks disparam',
        (tester) async {
      var refined = false;
      var confirmed = false;
      await tester.pumpWidget(
        _wrap(
          PreConfirmFooter(
            durationMinutes: 30,
            onRefine: () => refined = true,
            onConfirm: () => confirmed = true,
          ),
        ),
      );

      // Duração total em verde à esquerda (valor presente → aparece).
      expect(find.text('30 min'), findsOneWidget);
      expect(find.text('Refinar'), findsOneWidget);
      expect(find.text('Confirmar'), findsOneWidget);

      await tester.tap(find.text('Refinar'));
      expect(refined, isTrue);
      await tester.tap(find.text('Confirmar'));
      expect(confirmed, isTrue);
    });

    testWidgets('duração 0 → segmento verde omitido; Refinar/Confirmar ficam',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          PreConfirmFooter(
            durationMinutes: 0,
            onRefine: () {},
            onConfirm: () {},
          ),
        ),
      );
      expect(find.text('0 min'), findsNothing);
      expect(find.text('Refinar'), findsOneWidget);
      expect(find.text('Confirmar'), findsOneWidget);
    });
  });
}
