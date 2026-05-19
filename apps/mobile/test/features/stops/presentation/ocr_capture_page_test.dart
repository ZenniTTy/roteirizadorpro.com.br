import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/core/services/permissions.dart';
import 'package:roteirizador_pro/features/stops/presentation/ocr_capture_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

import '../../../core/_helpers/fake_app_permissions.dart';
import '../_helpers/fake_stops_repository.dart';

void main() {
  testWidgets('OcrCapturePage renders camera CTA and prompt copy',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stopsRepositoryProvider.overrideWithValue(FakeStopsRepository()),
          appPermissionsProvider.overrideWithValue(FakeAppPermissions()),
        ],
        child: const MaterialApp(home: OcrCapturePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aponte para a etiqueta do pacote'), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
  });

  testWidgets('OcrCapturePage surfaces snackbar when camera permission denied',
      (tester) async {
    final perms = FakeAppPermissions(cameraResult: PermissionOutcome.denied);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stopsRepositoryProvider.overrideWithValue(FakeStopsRepository()),
          appPermissionsProvider.overrideWithValue(perms),
        ],
        child: const MaterialApp(home: OcrCapturePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('ocr-capture-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(perms.cameraCalls, 1);
    expect(find.text('Permissão da câmera necessária.'), findsOneWidget);
  });
}
