import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:roteirizador_pro/features/share/presentation/share_sheet.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

import '../stops/_helpers/fake_stops_repository.dart';

Stop _s(String id, {double lat = -23.55, double lng = -46.63, String? label}) =>
    Stop(
      id: id,
      lat: lat,
      lng: lng,
      label: label ?? id,
      source: StopSource.manual,
      createdAt: DateTime.utc(2026, 5, 19),
    );

Widget _harness({
  List<Stop> stops = const [],
  Future<void> Function(String, {String? subject})? shareFn,
}) {
  return ProviderScope(
    overrides: [
      stopsRepositoryProvider.overrideWithValue(FakeStopsRepository(stops)),
    ],
    child: MaterialApp(home: ShareSheet(shareFn: shareFn)),
  );
}

void main() {
  test(
    'buildRouteText numbers stops and includes lat/lng for geocoded entries',
    () {
      final stops = [
        _s('a', lat: -23.55, lng: -46.63, label: 'A'),
        _s('b', lat: -23.56, lng: -46.64, label: 'B'),
      ];

      final text = ShareSheet.buildRouteText(stops);

      expect(text, contains('Rota otimizada — Roteirizador Pro'));
      expect(text, contains('1. A'));
      expect(text, contains('2. B'));
      expect(text, contains('-23.55000, -46.63000'));
      expect(text, contains('-23.56000, -46.64000'));
    },
  );

  test('buildRouteText skips coords for ungeocoded stops', () {
    final stops = [
      _s('a', lat: 0, lng: 0, label: 'só endereço'),
    ];

    final text = ShareSheet.buildRouteText(stops);

    expect(text, contains('1. só endereço'));
    expect(text, isNot(contains('0.00000')));
  });

  testWidgets(
    'ShareSheet renders three named-channel cards, header subtitle, and QR section',
    (tester) async {
      await tester.pumpWidget(_harness(stops: [_s('a', label: 'A')]));
      await tester.pumpAndSettle();

      // AppBar title per prototype.
      expect(find.text('Indique o app'), findsOneWidget);
      // Header subtitle.
      expect(
        find.textContaining('Passe o link para outro motoboy'),
        findsOneWidget,
      );
      // Three named-channel card titles.
      expect(find.text('Compartilhar no WhatsApp'), findsOneWidget);
      expect(find.text('Copiar link de download'), findsOneWidget);
      expect(find.text('Mostrar QR Code'), findsOneWidget);
      // QR section caption.
      expect(find.text('Aponte a câmera para o código'), findsOneWidget);
      // Default pill state.
      expect(find.text('Copiar'), findsOneWidget);
      // Old controls must be gone.
      expect(find.text('Voltar'), findsNothing);
      expect(find.text('Compartilhar'), findsNothing);
    },
  );

  testWidgets(
    'WhatsApp card tap fires injected shareFn with route text and subject Minha rota',
    (tester) async {
      String? capturedText;
      String? capturedSubject;

      await tester.pumpWidget(
        _harness(
          stops: [_s('a', label: 'A')],
          shareFn: (text, {subject}) async {
            capturedText = text;
            capturedSubject = subject;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Compartilhar no WhatsApp'));
      await tester.pump();

      expect(capturedText, contains('1. A'));
      expect(capturedSubject, 'Minha rota');
    },
  );

  testWidgets(
    'WhatsApp card is visually disabled when zero stops',
    (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      // The Opacity wrapper signals the disabled state for the
      // _WhatsAppCard. The card is the first `_ShareCard` Opacity in
      // the tree (CopyLink and Qr cards are never disabled).
      final opacityFinder = find.ancestor(
        of: find.text('Compartilhar no WhatsApp'),
        matching: find.byType(Opacity),
      );
      expect(opacityFinder, findsOneWidget);
      final opacity = tester.widget<Opacity>(opacityFinder);
      expect(opacity.opacity, 0.5);
    },
  );

  testWidgets(
    'Copy pill toggles to Copiado state after tap and reverts after 1500ms',
    (tester) async {
      // Mock the platform clipboard channel so Clipboard.setData
      // resolves cleanly inside the test environment.
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => null,
      );
      addTearDown(() {
        messenger.setMockMethodCallHandler(SystemChannels.platform, null);
      });

      await tester.pumpWidget(_harness(stops: [_s('a', label: 'A')]));
      await tester.pumpAndSettle();

      expect(find.text('Copiar'), findsOneWidget);
      expect(find.text('Copiado!'), findsNothing);

      await tester.tap(find.text('Copiar'));
      // Two pumps: first to let the await Clipboard.setData
      // microtask resolve, second to flush the resulting setState.
      await tester.pump();
      await tester.pump();

      expect(find.text('Copiado!'), findsOneWidget);
      expect(find.text('Copiar'), findsNothing);

      // Timer drives the revert; pumpAndSettle would hang on the
      // scheduled callback. Advance virtual time past 1500ms instead.
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.text('Copiar'), findsOneWidget);
      expect(find.text('Copiado!'), findsNothing);
    },
  );

  testWidgets(
    'QR section card renders QrImageView alongside scan caption',
    (tester) async {
      await tester.pumpWidget(_harness(stops: [_s('a', label: 'A')]));
      await tester.pumpAndSettle();

      // `QrImageView.data` is stored in a private field on the
      // qr_flutter widget, so we assert the widget is built (its
      // construction would throw on an invalid payload) and that the
      // accompanying caption is rendered.
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('Aponte a câmera para o código'), findsOneWidget);
    },
  );
}
