import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/core/services/permissions.dart';
import 'package:roteirizador_pro/features/stops/presentation/voice_capture_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

import '../../../core/_helpers/fake_app_permissions.dart';
import '../_helpers/fake_stops_repository.dart';

void main() {
  testWidgets('VoiceCapturePage renders mic CTA and prompt copy',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stopsRepositoryProvider.overrideWithValue(FakeStopsRepository()),
          appPermissionsProvider.overrideWithValue(FakeAppPermissions()),
        ],
        child: const MaterialApp(home: VoiceCapturePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Falar endereço'), findsOneWidget);
    expect(find.text('Toque para falar o endereço'), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);
  });

  testWidgets(
      'VoiceCapturePage surfaces snackbar when microphone permission denied',
      (tester) async {
    final perms = FakeAppPermissions(micResult: PermissionOutcome.denied);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stopsRepositoryProvider.overrideWithValue(FakeStopsRepository()),
          appPermissionsProvider.overrideWithValue(perms),
        ],
        child: const MaterialApp(home: VoiceCapturePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('voice-mic-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(perms.micCalls, 1);
    expect(find.text('Permissão do microfone necessária.'), findsOneWidget);
  });
}
