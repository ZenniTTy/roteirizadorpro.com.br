import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:roteirizador_pro/features/route_config/domain/route_config.dart';
import 'package:roteirizador_pro/features/route_config/presentation/widgets/destination_picker_sheet.dart';

/// Pumps a button that opens [DestinationPickerSheet] via
/// `showModalBottomSheet<DestinationChoice>` and records the popped result, so
/// each test can assert what the sheet pops for a given tap. Mirrors the
/// real launcher in `route_details_page.dart`.
Future<DestinationChoice?> _openSheetAndTap(
  WidgetTester tester, {
  required String semanticsIdToTap,
}) async {
  DestinationChoice? popped;
  var resolved = false;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                popped = await showModalBottomSheet<DestinationChoice>(
                  context: context,
                  builder: (_) => const DestinationPickerSheet(),
                );
                resolved = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();

  await tester.tap(find.bySemanticsIdentifier(semanticsIdToTap));
  await tester.pumpAndSettle();

  expect(resolved, isTrue, reason: 'sheet should have popped');
  return popped;
}

void main() {
  group('DestinationPickerSheet — structure (Spoke baseline)', () {
    Future<void> pumpSheet(WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DestinationPickerSheet()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('header shows title "Destino" and "Concluído" text button',
        (tester) async {
      await pumpSheet(tester);

      expect(find.text('Destino'), findsOneWidget);
      // "Concluído" is a blue TextButton (close-without-change), NOT a
      // full-width FilledButton and NOT an AppBar action.
      expect(
        find.ancestor(
          of: find.text('Concluído'),
          matching: find.byType(TextButton),
        ),
        findsOneWidget,
      );
      // No "Confirmar", no X dismiss button on the sheet (Spoke baseline).
      expect(find.text('Confirmar'), findsNothing);
    });

    testWidgets('renders a Divider below the header', (tester) async {
      await pumpSheet(tester);
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('renders exactly 3 cards with Spoke titles + subtitles',
        (tester) async {
      await pumpSheet(tester);

      // Card 1 — RoundTrip.
      expect(find.text('Voltar ao ponto de partida'), findsOneWidget);
      expect(find.text('Ida e volta (recomendado)'), findsOneWidget);
      // Card 2 — SpecificAddress (address search).
      expect(find.text('Destino em outro endereço'), findsOneWidget);
      expect(find.text('Digite qualquer endereço'), findsOneWidget);
      // Card 3 — NoDestination.
      expect(find.text('Não usar destino'), findsOneWidget);
      expect(find.text('Não recomendado para transportadoras'), findsOneWidget);
    });

    testWidgets('card icons match Spoke pixels (cornerUpLeft / mapPin / x)',
        (tester) async {
      await pumpSheet(tester);

      expect(find.byIcon(LucideIcons.cornerUpLeft), findsOneWidget);
      expect(find.byIcon(LucideIcons.mapPin), findsOneWidget);
      expect(find.byIcon(LucideIcons.x), findsOneWidget);
    });

    testWidgets(
        'has NO radio circle and NO selection checkmark (all cards identical)',
        (tester) async {
      await pumpSheet(tester);

      // Spoke shows no current-selection indicator: no Radio, no check icon.
      expect(find.byType(Radio<Object?>), findsNothing);
      expect(find.byIcon(LucideIcons.check), findsNothing);
    });

    testWidgets('each card + Concluído expose a Semantics identifier',
        (tester) async {
      await pumpSheet(tester);

      expect(
        find.bySemanticsIdentifier('destination_card_round_trip'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsIdentifier('destination_card_specific_address'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsIdentifier('destination_card_no_destination'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsIdentifier('destination_done'),
        findsOneWidget,
      );
    });
  });

  group('DestinationPickerSheet — tap intents (card tap IS the confirm)', () {
    testWidgets('card 1 tap pops DestinationChosen(RoundTrip)', (tester) async {
      final result = await _openSheetAndTap(
        tester,
        semanticsIdToTap: 'destination_card_round_trip',
      );
      expect(result, isA<DestinationChosen>());
      expect((result! as DestinationChosen).destination, const RoundTrip());
    });

    testWidgets('card 3 tap pops DestinationChosen(NoDestination)',
        (tester) async {
      final result = await _openSheetAndTap(
        tester,
        semanticsIdToTap: 'destination_card_no_destination',
      );
      expect(result, isA<DestinationChosen>());
      expect(
        (result! as DestinationChosen).destination,
        const NoDestination(),
      );
    });

    testWidgets('card 2 tap pops AddressSearchRequested (no Destination yet)',
        (tester) async {
      final result = await _openSheetAndTap(
        tester,
        semanticsIdToTap: 'destination_card_specific_address',
      );
      // Card 2 does NOT carry a Destination — the parent pushes the address
      // search and builds SpecificAddress from the returned place.
      expect(result, isA<AddressSearchRequested>());
    });

    testWidgets('Concluído tap pops null (close without change)',
        (tester) async {
      final result = await _openSheetAndTap(
        tester,
        semanticsIdToTap: 'destination_done',
      );
      expect(result, isNull);
    });
  });
}
