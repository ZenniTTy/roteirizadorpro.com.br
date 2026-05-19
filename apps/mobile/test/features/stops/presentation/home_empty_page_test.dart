import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/features/stops/data/repositories/stops_repository.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/presentation/home_empty_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

class _EmptyRepo implements StopsRepository {
  @override
  Future<List<Stop>> load() async => const [];

  @override
  Future<void> save(List<Stop> stops) async {}
}

void main() {
  Widget harness({void Function(BuildContext)? onAddPressed}) {
    return ProviderScope(
      overrides: [stopsRepositoryProvider.overrideWithValue(_EmptyRepo())],
      child: MaterialApp(
        home: HomeEmptyPage(onAddPressed: onAddPressed),
      ),
    );
  }

  testWidgets('HomeEmptyPage shows the empty-state CTA', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('Rota de hoje'), findsOneWidget);
    expect(find.text('Nenhuma entrega ainda'), findsOneWidget);
    expect(find.text('Adicionar parada'), findsOneWidget);
  });

  testWidgets('HomeEmptyPage CTA is a tappable button', (tester) async {
    var taps = 0;
    await tester.pumpWidget(harness(onAddPressed: (_) => taps++));
    await tester.pumpAndSettle();

    final ctaFinder = find.widgetWithText(FilledButton, 'Adicionar parada');
    expect(ctaFinder, findsOneWidget);

    await tester.tap(ctaFinder);
    await tester.pumpAndSettle();

    expect(taps, 1);
  });
}
