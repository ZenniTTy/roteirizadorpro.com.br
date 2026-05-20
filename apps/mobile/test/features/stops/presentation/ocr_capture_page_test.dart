import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/core/services/permissions.dart';
import 'package:roteirizador_pro/features/stops/presentation/ocr_capture_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

import '../../../core/_helpers/fake_app_permissions.dart';
import '../_helpers/fake_stops_repository.dart';

Future<void> _pump(
  WidgetTester tester, {
  FakeAppPermissions? perms,
  FakeStopsRepository? repo,
  void Function(BuildContext)? onConfirmed,
  String? initialTranscript,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        stopsRepositoryProvider
            .overrideWithValue(repo ?? FakeStopsRepository()),
        appPermissionsProvider.overrideWithValue(perms ?? FakeAppPermissions()),
      ],
      child: MaterialApp(
        home: OcrCapturePage(
          onConfirmed: onConfirmed,
          initialTranscript: initialTranscript,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('OcrCapturePage renders dark scaffold + prompt copy',
      (tester) async {
    await _pump(tester);

    expect(find.text('Aponte para a etiqueta do pacote'), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
  });

  testWidgets('Capture button has the ocr-capture-button key', (tester) async {
    await _pump(tester);
    expect(find.byKey(const Key('ocr-capture-button')), findsOneWidget);
  });

  testWidgets('Frosted close button renders the X icon', (tester) async {
    await _pump(tester);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('Mock package label shows MARIA SOUZA destinatário',
      (tester) async {
    await _pump(tester);
    expect(find.text('DESTINATÁRIO:'), findsOneWidget);
    expect(find.text('MARIA SOUZA'), findsOneWidget);
  });

  testWidgets(
      'Result card renders with Editar + Confirmar when transcript is seeded',
      (tester) async {
    await _pump(tester, initialTranscript: 'R. Haddock Lobo, 1500');

    expect(find.text('Endereço encontrado:'), findsOneWidget);
    expect(find.text('R. Haddock Lobo, 1500'), findsOneWidget);
    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Confirmar'), findsOneWidget);
    expect(find.byKey(const Key('ocr-confirm-button')), findsOneWidget);
  });

  testWidgets('Confirmar with seeded transcript persists the stop',
      (tester) async {
    final repo = FakeStopsRepository();
    var confirms = 0;
    await _pump(
      tester,
      repo: repo,
      initialTranscript: 'R. Haddock Lobo, 1500',
      onConfirmed: (_) => confirms++,
    );

    await tester.tap(find.byKey(const Key('ocr-confirm-button')));
    await tester.pumpAndSettle();

    expect(repo.saved, hasLength(1));
    expect(repo.saved.first.label, 'R. Haddock Lobo, 1500');
    expect(repo.saved.first.source.name, 'ocr');
    expect(confirms, 1);
  });

  testWidgets('OcrCapturePage surfaces snackbar when camera permission denied',
      (tester) async {
    final perms = FakeAppPermissions(cameraResult: PermissionOutcome.denied);
    await _pump(tester, perms: perms);

    await tester.tap(find.byKey(const Key('ocr-capture-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(perms.cameraCalls, 1);
    expect(find.text('Permissão da câmera necessária.'), findsOneWidget);
  });
}
