import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:roteirizador_pro/features/routes/application/add_stop_ui_state.dart';
import 'package:roteirizador_pro/features/routes/domain/place_autocomplete_prediction.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';
import 'package:roteirizador_pro/features/routes/presentation/pages/add_stop_page.dart';
import 'package:roteirizador_pro/features/routes/state/add_stop_ui_state_provider.dart';

GoRouter _router(Widget home) => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => home),
        GoRoute(
            path: '/map',
            builder: (_, __) => const Scaffold(body: Text('MAP'))),
      ],
    );

Widget _wrap({required AddStopUiState state}) {
  final router = _router(const AddStopPage());
  return ProviderScope(
    overrides: [
      addStopUiStateProvider.overrideWith((ref) => state),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets(
      'EmptyVariant(0 stops) renders first-paradas microcopy + 3 method buttons',
      (tester) async {
    await tester.pumpWidget(_wrap(state: const EmptyVariant(stopCount: 0)));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Adicione as primeiras paradas'),
      findsOneWidget,
    );
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.text('Leitor'), findsOneWidget);
    expect(find.text('Voz'), findsOneWidget);
  });

  testWidgets('EmptyVariant(stopCount >= 1) renders novas-paradas microcopy',
      (tester) async {
    await tester.pumpWidget(_wrap(state: const EmptyVariant(stopCount: 2)));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Adicione novas paradas ou encontre paradas na rota'),
      findsOneWidget,
    );
  });

  testWidgets('ZeroResults renders no-results microcopy + 3 method buttons',
      (tester) async {
    await tester.pumpWidget(_wrap(state: const ZeroResults()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nenhum resultado encontrado'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
  });

  testWidgets('Loading renders CircularProgressIndicator', (tester) async {
    await tester.pumpWidget(_wrap(state: const Loading()));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
      'WithResults renders Section A header + Section B header + Footer',
      (tester) async {
    const pred = PlaceAutocompletePrediction(
      placeId: 'p1',
      description: 'Av Paulista, 1000',
      mainText: 'Av Paulista, 1000',
      secondaryText: 'Bela Vista, SP',
    );
    final stop =
        Stop(lat: 0, lng: 0, streetName: 'Av Paulista, 500', fullAddress: 'x');
    await tester.pumpWidget(
      _wrap(
        state: WithResults(matchesInRoute: [stop], newCandidates: const [pred]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Desta rota (1)'), findsOneWidget);
    expect(find.text('Adicionar nova parada'), findsOneWidget);
    expect(find.text('Escolher no mapa'), findsOneWidget);
  });

  testWidgets('WithResults footer has no trailing chevron icon',
      (tester) async {
    // §11.4 amendment 2026-05-29 item 7: Footer renders text-only, no chevron.
    const pred = PlaceAutocompletePrediction(
      placeId: 'p1',
      description: 'Av Paulista, 1000',
      mainText: 'Av Paulista, 1000',
      secondaryText: 'Bela Vista, SP',
    );
    final stop =
        Stop(lat: 0, lng: 0, streetName: 'Av Paulista, 500', fullAddress: 'x');
    await tester.pumpWidget(
      _wrap(
        state: WithResults(matchesInRoute: [stop], newCandidates: const [pred]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(LucideIcons.chevronRight), findsNothing);
  });

  testWidgets('WithResults Section B ListTile has no leading icon',
      (tester) async {
    // §11.4 amendment 2026-05-29 item 5: Section B ListTile has no leading
    // icon (text-only at x=208).
    const pred = PlaceAutocompletePrediction(
      placeId: 'p1',
      description: 'Av Paulista, 1000',
      mainText: 'Av Paulista, 1000',
      secondaryText: 'Bela Vista, SP',
    );
    final stop =
        Stop(lat: 0, lng: 0, streetName: 'Av Paulista, 500', fullAddress: 'x');
    await tester.pumpWidget(
      _wrap(
        state: WithResults(matchesInRoute: [stop], newCandidates: const [pred]),
      ),
    );
    await tester.pumpAndSettle();

    final sectionBTile = tester.widget<ListTile>(
      find
          .ancestor(
            of: find.text('Av Paulista, 1000'),
            matching: find.byType(ListTile),
          )
          .first,
    );
    expect(sectionBTile.leading, isNull);
  });

  testWidgets('WithResults Section A ListTile keeps leading icon',
      (tester) async {
    // §11.4 amendment 2026-05-29 item 5: Section A keeps `leading` non-null
    // per MS5 Task 2 scope, differentiating it from Section B.
    const pred = PlaceAutocompletePrediction(
      placeId: 'p1',
      description: 'Av Paulista, 1000',
      mainText: 'Av Paulista, 1000',
      secondaryText: 'Bela Vista, SP',
    );
    final stop =
        Stop(lat: 0, lng: 0, streetName: 'Av Paulista, 500', fullAddress: 'x');
    await tester.pumpWidget(
      _wrap(
        state: WithResults(matchesInRoute: [stop], newCandidates: const [pred]),
      ),
    );
    await tester.pumpAndSettle();

    final sectionATile = tester.widget<ListTile>(
      find
          .ancestor(
            of: find.text('Av Paulista, 500'),
            matching: find.byType(ListTile),
          )
          .first,
    );
    expect(sectionATile.leading, isNotNull);
  });

  testWidgets('WithResults Section A ListTile has trailing pencil icon',
      (tester) async {
    // §11.4 amendment 2026-05-29 item 6: Section A has a trailing edit
    // affordance (pencil) at the right edge, differentiating tap-to-edit
    // (Section A) from tap-to-create (Section B).
    const pred = PlaceAutocompletePrediction(
      placeId: 'p1',
      description: 'Av Paulista, 1000',
      mainText: 'Av Paulista, 1000',
      secondaryText: 'Bela Vista, SP',
    );
    final stop =
        Stop(lat: 0, lng: 0, streetName: 'Av Paulista, 500', fullAddress: 'x');
    await tester.pumpWidget(
      _wrap(
        state: WithResults(matchesInRoute: [stop], newCandidates: const [pred]),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find
            .ancestor(
              of: find.text('Av Paulista, 500'),
              matching: find.byType(ListTile),
            )
            .first,
        matching: find.byIcon(LucideIcons.pencil),
      ),
      findsOneWidget,
    );
  });

  testWidgets('WithResults with empty matchesInRoute hides Section A entirely',
      (tester) async {
    const pred = PlaceAutocompletePrediction(
      placeId: 'p1',
      description: 'd',
      mainText: 'Av Paulista',
      secondaryText: 'SP',
    );
    await tester.pumpWidget(
      _wrap(
        state: const WithResults(matchesInRoute: [], newCandidates: [pred]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Desta rota'), findsNothing);
    expect(find.text('Adicionar nova parada'), findsOneWidget);
  });

  testWidgets('Section A tap shows SnackBar "Editar parada em breve"',
      (tester) async {
    final stop =
        Stop(lat: 0, lng: 0, streetName: 'Av Paulista, 500', fullAddress: 'x');
    await tester.pumpWidget(
      _wrap(
        state: WithResults(matchesInRoute: [stop], newCandidates: const []),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Av Paulista, 500'));
    await tester.pump();

    expect(find.text('Editar parada em breve'), findsOneWidget);
  });

  testWidgets('Footer tap navigates to /home/routes/add-stop/map',
      (tester) async {
    // We override the GoRouter for this test to point /map at a recognisable
    // sentinel screen.
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const AddStopPage()),
        GoRoute(
          path: '/home/routes/add-stop/map',
          builder: (_, __) => const Scaffold(body: Text('SENTINEL_MAP')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          addStopUiStateProvider.overrideWith(
            (ref) => const WithResults(matchesInRoute: [], newCandidates: []),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Escolher no mapa'));
    await tester.pumpAndSettle();

    expect(find.text('SENTINEL_MAP'), findsOneWidget);
  });
}
