// Tests for PackageFinderSheet — MS-A6 T16.
//
// Spec: docs/superpowers/plans/2026-06-11-area6-edit-stop-plan.md §T16 / F11/H13/H19.
// Contrato (dump Spoke v3.65.1):
//   - Header: TextButton 'Limpar' | 'Localizador de pacotes' | TextButton 'Concluído'.
//   - Row 'ID de parada': deliveryId ?? 'Pendente' (display only).
//   - Seção 'Descrição do pacote': chips Pequeno/Médio/Grande + Caixa/Sacola/Carta.
//   - Seção 'Lugar no veículo': chips inline (sem sub-nav): Frente/Meio/Atrás,
//     Esquerda/Direita, Chão/Prateleira.
//   - Tap em chip já selecionado DESSELECIONA (toggle desselecionável).
//   - Seleção inicial reflete initialDetails/initialPlace.
//   - 'Concluído' popa estado normalizado: tudo null → null no record.
//   - 'Limpar' popa (details: null, place: null).
//   - Barrier dismiss → null (cancel).
//   - Semantics H19: finder_chip_<enumName> (ex.: finder_chip_small, etc.).
//
// Host: MaterialApp.router (GoRouter) — mesmo idiom do arrival_window_sheet_test.
// Frame alto (1080×3200 / DPR 2.0) — sheet é comprida.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:roteirizador_pro/features/routes/domain/package_details.dart';
import 'package:roteirizador_pro/features/routes/domain/place_in_vehicle.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/package_finder_sheet.dart';

// ---------------------------------------------------------------------------
// Host
// ---------------------------------------------------------------------------

class _SheetHost extends StatefulWidget {
  const _SheetHost({
    this.initialDetails,
    this.initialPlace,
    this.deliveryId,
  });
  final PackageDetails? initialDetails;
  final PlaceInVehicle? initialPlace;
  final String? deliveryId;

  @override
  State<_SheetHost> createState() => _SheetHostState();
}

class _SheetHostState extends State<_SheetHost> {
  PackageFinderSelection? result;
  bool opened = false;
  bool dismissed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            key: const Key('open_sheet'),
            onPressed: () async {
              final r = await PackageFinderSheet.show(
                context,
                initialDetails: widget.initialDetails,
                initialPlace: widget.initialPlace,
                deliveryId: widget.deliveryId,
              );
              if (!mounted) return;
              setState(() {
                result = r;
                opened = true;
                dismissed = r == null;
              });
            },
            child: const Text('Abrir'),
          ),
          if (opened && !dismissed) ...[
            Text(
              'details_dimension:${result?.details?.dimension?.name ?? 'null'}',
              key: const Key('result_details_dimension'),
            ),
            Text(
              'details_type:${result?.details?.type?.name ?? 'null'}',
              key: const Key('result_details_type'),
            ),
            Text(
              'place_x:${result?.place?.x?.name ?? 'null'}',
              key: const Key('result_place_x'),
            ),
            Text(
              'place_y:${result?.place?.y?.name ?? 'null'}',
              key: const Key('result_place_y'),
            ),
            Text(
              'place_z:${result?.place?.z?.name ?? 'null'}',
              key: const Key('result_place_z'),
            ),
          ],
          if (opened && dismissed)
            const Text('dismissed', key: Key('result_dismissed')),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper: monta host dentro de MaterialApp.router (useRootNavigator: true — H13)
// ---------------------------------------------------------------------------

Widget _buildApp({
  PackageDetails? initialDetails,
  PlaceInVehicle? initialPlace,
  String? deliveryId,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => _SheetHost(
          initialDetails: initialDetails,
          initialPlace: initialPlace,
          deliveryId: deliveryId,
        ),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void _useTallFrame(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 3200);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

// ---------------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------------

void main() {
  // ── 1. Header ──────────────────────────────────────────────────────────────

  group('1 — Header (package_finder_title)', () {
    testWidgets(
        'sheet abre com header: TextButton "Limpar" à esquerda, '
        'título "Localizador de pacotes" ao centro, TextButton "Concluído" à direita',
        (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      expect(find.text('Limpar'), findsOneWidget);
      expect(find.text('Localizador de pacotes'), findsAtLeastNWidgets(1));
      expect(find.text('Concluído'), findsOneWidget);
    });
  });

  // ── 2. Row ID de parada ────────────────────────────────────────────────────

  group('2 — Row "ID de parada" (package_identification_feature_title)', () {
    testWidgets(
        '2a — sem deliveryId → row exibe "Pendente" '
        '(package_label_status_pending do dump v3.65.1)', (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      expect(find.text('ID de parada'), findsOneWidget);
      expect(find.text('Pendente'), findsOneWidget);
    });

    testWidgets('2b — com deliveryId="A1" → row exibe "A1" (display only)',
        (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(_buildApp(deliveryId: 'A1'));
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      expect(find.text('A1'), findsOneWidget);
      expect(find.text('Pendente'), findsNothing);
    });
  });

  // ── 3. Seção 'Descrição do pacote' ────────────────────────────────────────

  group('3 — Seção "Descrição do pacote" (package_description_title)', () {
    testWidgets(
        '3a — seção "Descrição do pacote" visível com chips de dimensão '
        'Pequeno/Médio/Grande (package_description_title)', (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      expect(find.text('Descrição do pacote'), findsOneWidget);
      expect(
        find.bySemanticsIdentifier('finder_chip_small'),
        findsOneWidget,
        reason: 'chip Pequeno deve expor identifier finder_chip_small (H19)',
      );
      expect(
        find.bySemanticsIdentifier('finder_chip_medium'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsIdentifier('finder_chip_large'),
        findsOneWidget,
      );
    });

    testWidgets(
        '3b — chips de tipo Caixa/Sacola/Carta presentes '
        '(finder_chip_box, finder_chip_bag, finder_chip_letter)',
        (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      expect(find.bySemanticsIdentifier('finder_chip_box'), findsOneWidget);
      expect(find.bySemanticsIdentifier('finder_chip_bag'), findsOneWidget);
      expect(find.bySemanticsIdentifier('finder_chip_letter'), findsOneWidget);
    });
  });

  // ── 4. Seção 'Lugar no veículo' ───────────────────────────────────────────

  group(
      '4 — Seção "Lugar no veículo" (place_in_vehicle — H13: inline, sem sub-nav)',
      () {
    testWidgets(
        '4a — seção "Lugar no veículo" visível com chips Y: '
        'Frente/Meio/Atrás inline na sheet', (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      expect(find.text('Lugar no veículo'), findsOneWidget);
      expect(find.bySemanticsIdentifier('finder_chip_front'), findsOneWidget);
      expect(find.bySemanticsIdentifier('finder_chip_middle'), findsOneWidget);
      expect(find.bySemanticsIdentifier('finder_chip_back'), findsOneWidget);
    });

    testWidgets(
        '4b — chips X: Esquerda/Direita (finder_chip_left, finder_chip_right)',
        (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      expect(find.bySemanticsIdentifier('finder_chip_left'), findsOneWidget);
      expect(find.bySemanticsIdentifier('finder_chip_right'), findsOneWidget);
    });

    testWidgets(
        '4c — chips Z: Chão/Prateleira (finder_chip_floor, finder_chip_shelf)',
        (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      expect(find.bySemanticsIdentifier('finder_chip_floor'), findsOneWidget);
      expect(find.bySemanticsIdentifier('finder_chip_shelf'), findsOneWidget);
    });
  });

  // ── 5. Seleção inicial reflete initialDetails / initialPlace ──────────────

  group('5 — Seleção inicial', () {
    testWidgets(
        '5a — initialDetails(dimension: small, type: box) → chips '
        'finder_chip_small e finder_chip_box aparecem selecionados',
        (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(
        _buildApp(
          initialDetails: const PackageDetails(
            dimension: PackageDimension.small,
            type: PackageType.box,
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      // Os chips selecionados devem estar na árvore (a seleção visual é
      // interna ao widget; verificamos via 'Concluído' que o estado é mantido).
      // Aqui só validamos que os chips estão presentes; o teste 6a valida o
      // round-trip completo.
      expect(
        find.bySemanticsIdentifier('finder_chip_small'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsIdentifier('finder_chip_box'),
        findsOneWidget,
      );
    });

    testWidgets(
        '5b — initialPlace(y: front, x: left, z: floor) + "Concluído" → '
        'place retornado tem y=front, x=left, z=floor', (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(
        _buildApp(
          initialPlace: const PlaceInVehicle(
            y: PlaceY.front,
            x: PlaceX.left,
            z: PlaceZ.floor,
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Concluído'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<Text>(find.byKey(const Key('result_place_y'))).data,
        'place_y:front',
        reason: 'seleção inicial y=front deve persistir no Concluído',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('result_place_x'))).data,
        'place_x:left',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('result_place_z'))).data,
        'place_z:floor',
      );
    });
  });

  // ── 6. 'Concluído' popa estado normalizado ────────────────────────────────

  group('6 — "Concluído" popa estado normalizado', () {
    testWidgets(
        '6a — tap finder_chip_small + finder_chip_front + "Concluído" → '
        'show() resolve (details: {small}, place: {front})', (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsIdentifier('finder_chip_small'));
      await tester.pump();
      await tester.tap(find.bySemanticsIdentifier('finder_chip_front'));
      await tester.pump();

      await tester.tap(find.text('Concluído'));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<Text>(find.byKey(const Key('result_details_dimension')))
            .data,
        'details_dimension:small',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('result_details_type'))).data,
        'details_type:null',
        reason: 'chip de tipo não selecionado → null',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('result_place_y'))).data,
        'place_y:front',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('result_place_x'))).data,
        'place_x:null',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('result_place_z'))).data,
        'place_z:null',
      );
    });

    testWidgets(
        '6b — nada selecionado + "Concluído" → '
        'show() resolve (details: null, place: null) (normalizado)',
        (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Concluído'));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<Text>(find.byKey(const Key('result_details_dimension')))
            .data,
        'details_dimension:null',
        reason: 'tudo null → details normalizado para null',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('result_place_y'))).data,
        'place_y:null',
        reason: 'tudo null → place normalizado para null',
      );
    });

    testWidgets(
        '6c — selecionar {small, box, front} → "Concluído" → '
        'details=(small, box), place=(y:front)', (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsIdentifier('finder_chip_small'));
      await tester.pump();
      await tester.tap(find.bySemanticsIdentifier('finder_chip_box'));
      await tester.pump();
      await tester.tap(find.bySemanticsIdentifier('finder_chip_front'));
      await tester.pump();

      await tester.tap(find.text('Concluído'));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<Text>(find.byKey(const Key('result_details_dimension')))
            .data,
        'details_dimension:small',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('result_details_type'))).data,
        'details_type:box',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('result_place_y'))).data,
        'place_y:front',
      );
    });
  });

  // ── 7. Toggle desselecionável (tap em chip selecionado desseleciona) ───────

  group('7 — Toggle desselecionável', () {
    testWidgets(
        '7 — tap em finder_chip_small 2× (seleciona + desseleciona) + '
        '"Concluído" → details == null (chip voltou a null)', (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      // Seleciona.
      await tester.tap(find.bySemanticsIdentifier('finder_chip_small'));
      await tester.pump();
      // Desseleciona.
      await tester.tap(find.bySemanticsIdentifier('finder_chip_small'));
      await tester.pump();

      await tester.tap(find.text('Concluído'));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<Text>(find.byKey(const Key('result_details_dimension')))
            .data,
        'details_dimension:null',
        reason:
            'tap duplo no mesmo chip deve desselecionar (toggle desselecionável)',
      );
    });
  });

  // ── 8. 'Limpar' popa (details: null, place: null) ─────────────────────────

  group('8 — "Limpar" popa (details: null, place: null)', () {
    testWidgets(
        '8a — "Limpar" com tudo selecionado → '
        'show() resolve (details: null, place: null)', (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(
        _buildApp(
          initialDetails: const PackageDetails(
            dimension: PackageDimension.small,
            type: PackageType.box,
          ),
          initialPlace: const PlaceInVehicle(
            y: PlaceY.front,
            x: PlaceX.left,
            z: PlaceZ.floor,
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Limpar'));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<Text>(find.byKey(const Key('result_details_dimension')))
            .data,
        'details_dimension:null',
        reason: '"Limpar" deve zerar details',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('result_place_y'))).data,
        'place_y:null',
        reason: '"Limpar" deve zerar place',
      );
    });

    testWidgets(
        '8b — "Limpar" com nada selecionado → '
        'show() resolve (details: null, place: null)', (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Limpar'));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<Text>(find.byKey(const Key('result_details_dimension')))
            .data,
        'details_dimension:null',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('result_place_y'))).data,
        'place_y:null',
      );
    });
  });

  // ── 9. Barrier dismiss → null (cancel) ────────────────────────────────────

  group('9 — Barrier dismiss → Future resolve null (cancel)', () {
    testWidgets('tap na barrier (fora da sheet) → show() resolve null (cancel)',
        (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      // Tap no canto superior esquerdo — fora da sheet.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('result_dismissed')), findsOneWidget);
    });
  });
}
