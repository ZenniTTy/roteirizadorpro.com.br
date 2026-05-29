import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/add_stop_search_bar.dart';
import 'package:roteirizador_pro/features/routes/state/search_query_provider.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  testWidgets('OCR + Voice icons visible when query is empty', (tester) async {
    await tester.pumpWidget(_wrap(const AddStopSearchBar()));
    await tester.pump();

    expect(find.byIcon(LucideIcons.scanLine), findsOneWidget);
    expect(find.byIcon(LucideIcons.mic), findsOneWidget);
  });

  testWidgets('OCR + Voice icons hidden when query is non-empty',
      (tester) async {
    await tester.pumpWidget(_wrap(const AddStopSearchBar()));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Av');
    await tester.pump();

    expect(find.byIcon(LucideIcons.scanLine), findsNothing);
    expect(find.byIcon(LucideIcons.mic), findsNothing);
  });

  testWidgets('typing mirrors to searchQueryProvider', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: AddStopSearchBar())),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Av Paulista');
    await tester.pump();

    expect(container.read(searchQueryProvider), 'Av Paulista');
  });

  // Spec Goal #10 + §11.4 amendment 2026-05-29 (D4 finding #5)
  testWidgets('tapping X clears input and restores OCR+Voice icons',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: AddStopSearchBar())),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Av Paulista');
    await tester.pump();

    // Sanity: while query is non-empty, OCR + Voice are hidden.
    expect(find.byIcon(LucideIcons.scanLine), findsNothing);
    expect(find.byIcon(LucideIcons.mic), findsNothing);

    await tester.tap(find.byTooltip('Limpar'));
    await tester.pump();

    expect(container.read(searchQueryProvider), '');
    expect(find.byIcon(LucideIcons.scanLine), findsOneWidget);
    expect(find.byIcon(LucideIcons.mic), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
  });
}
