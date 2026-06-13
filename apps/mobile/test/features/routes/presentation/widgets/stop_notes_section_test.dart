// Tests for StopNotesSection — MS-A6 T11 (F12/H15/H17).
//
// Spec: docs/superpowers/specs/2026-06-11-area6-edit-stop-design.md
// Contrato: notas live (F3), câmera injetável (H17), thumbnails com
// errorBuilder (H15), cancelamento + permissão negada tratados graciosamente.
//
// Setup: ProviderScope com overrides de cameraPickerProvider,
// packagePhotoStoreProvider e routesProvider (_FakeRoutes).
// Tela alta (1080×3200 / DPR 2.0) para o conteúdo scrollável não transbordar.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:roteirizador_pro/features/routes/domain/route.dart' as domain;
import 'package:roteirizador_pro/features/routes/domain/stop.dart' as domain;
import 'package:roteirizador_pro/features/routes/presentation/widgets/stop_notes_section.dart';
import 'package:roteirizador_pro/features/routes/state/routes_provider.dart';

import '../../_helpers/fake_package_photo_store.dart';

// ---------------------------------------------------------------------------
// Bytes mínimos de uma PNG 1×1 pixel transparente (RFC 2083 / ISO 15948).
// Usados para criar um XFile com conteúdo de imagem válido nos testes de
// thumbnail (evitar crash no imageDecoder).
// ---------------------------------------------------------------------------
final _kMinimalPng1x1 = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk length + type
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // width=1, height=1
  0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, // bit depth, color type, etc
  0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, // IDAT chunk length + type
  0x54, 0x08, 0xD7, 0x63, 0xF8, 0xFF, 0xFF, 0xFF, // IDAT data (zlib)
  0x00, 0x05, 0xFE, 0x02, 0xFE, 0xDC, 0xCC, 0x59, // IDAT cont
  0xE7, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, // IEND chunk
  0x44, 0xAE, 0x42, 0x60, 0x82, // IEND cont
]);

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeRoutes extends Routes {
  _FakeRoutes(this._seed);
  final List<domain.Route> _seed;

  @override
  List<domain.Route> build() => _seed;
}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

final _stopBase = domain.Stop(
  id: 's1',
  lat: -23.5,
  lng: -46.6,
  streetName: 'Rua Alfa, 100',
  fullAddress: 'Rua Alfa, 100 - Centro, São Paulo',
);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

void _useTallFrame(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 3200);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Constrói o StopNotesSection isolado dentro de um ProviderScope + MaterialApp.
///
/// [stop] é a fixture do stop semeada.
/// [pickerResult] é o que o fake cameraPicker retorna (null = cancelamento).
/// [pickerThrows] configura o picker para lançar PlatformException.
/// [photoStore] é o FakePackagePhotoStore pré-configurado.
/// [container] externo permite inspecionar o state após interação.
Widget _buildWidget({
  required domain.Stop stop,
  Future<XFile?> Function()? pickerResult,
  FakePackagePhotoStore? photoStore,
  ProviderContainer? container,
}) {
  final store = photoStore ?? FakePackagePhotoStore();
  final picker = pickerResult ?? (() async => null);

  final overrides = [
    routesProvider.overrideWith(
      () => _FakeRoutes([
        domain.Route(
          id: 'r1',
          date: DateTime(2026, 5, 27),
          status: domain.RouteStatus.running,
          stops: [stop],
        ),
      ]),
    ),
    packagePhotoStoreProvider.overrideWithValue(store),
    cameraPickerProvider.overrideWithValue(picker),
  ];

  final scope = container != null
      ? UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: StopNotesSection(routeId: 'r1', stop: stop),
            ),
          ),
        )
      : ProviderScope(
          overrides: overrides,
          child: MaterialApp(
            home: Scaffold(
              body: StopNotesSection(routeId: 'r1', stop: stop),
            ),
          ),
        );

  return scope;
}

/// Monta o widget com um container externo e os overrides já aplicados.
Widget _buildWithContainer({
  required domain.Stop stop,
  required Future<XFile?> Function() picker,
  required FakePackagePhotoStore photoStore,
  required ProviderContainer container,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: Scaffold(
        body: StopNotesSection(routeId: 'r1', stop: stop),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------------

void main() {
  // ── 1. TextField multiline com hintText 'Adicionar notas' ─────────────────

  group('1 — TextField notas — estrutura', () {
    testWidgets('renderiza TextField multiline com hintText "Adicionar notas"',
        (tester) async {
      _useTallFrame(tester);
      await tester.pumpWidget(_buildWidget(stop: _stopBase));
      await tester.pumpAndSettle();

      final tf = tester.widget<TextField>(find.byType(TextField));
      // maxLines null = multiline.
      expect(
        tf.maxLines,
        isNull,
        reason: 'TextField deve ser multiline (maxLines: null)',
      );
      expect(
        tf.decoration?.hintText,
        'Adicionar notas',
        reason: 'hintText deve ser "Adicionar notas"',
      );
    });

    testWidgets(
        'stop.notes == null → TextField começa vazio (nenhum texto inicial)',
        (tester) async {
      _useTallFrame(tester);
      final stop = _stopBase; // notes == null
      await tester.pumpWidget(_buildWidget(stop: stop));
      await tester.pumpAndSettle();

      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(
        tf.controller?.text ?? '',
        isEmpty,
        reason: 'notes null → controller.text deve ser vazio',
      );
    });

    testWidgets(
        'stop.notes preenchido → TextField iniciado com o valor do notes',
        (tester) async {
      _useTallFrame(tester);
      final stop = _stopBase.copyWith(notes: 'Ligar na portaria');
      await tester.pumpWidget(_buildWidget(stop: stop));
      await tester.pumpAndSettle();

      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(
        tf.controller?.text,
        'Ligar na portaria',
        reason: 'notes preenchido → controller.text deve refletir o valor',
      );
    });
  });

  // ── 2. Notas live — digitar + unfocus → updateStop ────────────────────────

  group('2 — Notas live (F3)', () {
    testWidgets(
        'digitar texto + unfocus → updateStop chamado com notes == texto',
        (tester) async {
      _useTallFrame(tester);

      final container = ProviderContainer(
        overrides: [
          routesProvider.overrideWith(
            () => _FakeRoutes([
              domain.Route(
                id: 'r1',
                date: DateTime(2026, 5, 27),
                status: domain.RouteStatus.running,
                stops: [_stopBase],
              ),
            ]),
          ),
          packagePhotoStoreProvider.overrideWithValue(FakePackagePhotoStore()),
          cameraPickerProvider.overrideWithValue(() async => null),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _buildWithContainer(
          stop: _stopBase,
          picker: () async => null,
          photoStore: FakePackagePhotoStore(),
          container: container,
        ),
      );
      await tester.pumpAndSettle();

      // Digita no TextField.
      await tester.enterText(find.byType(TextField), 'Deixar na guarita');
      // Unfocus (simula perda de foco).
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Provider deve ter notes == 'Deixar na guarita'.
      final routes = container.read(routesProvider);
      final stop = routes.firstWhere((r) => r.id == 'r1').stops.firstWhere(
            (s) => s.id == 's1',
          );
      expect(
        stop.notes,
        'Deixar na guarita',
        reason: 'updateStop deve ter sido chamado com o texto digitado',
      );
    });

    testWidgets(
        'apagar todo o texto + unfocus → notes == null (não string vazia)',
        (tester) async {
      _useTallFrame(tester);

      final stopComNotes = _stopBase.copyWith(notes: 'Texto anterior');

      final container = ProviderContainer(
        overrides: [
          routesProvider.overrideWith(
            () => _FakeRoutes([
              domain.Route(
                id: 'r1',
                date: DateTime(2026, 5, 27),
                status: domain.RouteStatus.running,
                stops: [stopComNotes],
              ),
            ]),
          ),
          packagePhotoStoreProvider.overrideWithValue(FakePackagePhotoStore()),
          cameraPickerProvider.overrideWithValue(() async => null),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _buildWithContainer(
          stop: stopComNotes,
          picker: () async => null,
          photoStore: FakePackagePhotoStore(),
          container: container,
        ),
      );
      await tester.pumpAndSettle();

      // Apaga tudo.
      await tester.enterText(find.byType(TextField), '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      final routes = container.read(routesProvider);
      final stop = routes.firstWhere((r) => r.id == 'r1').stops.firstWhere(
            (s) => s.id == 's1',
          );
      expect(
        stop.notes,
        isNull,
        reason: 'texto vazio deve gerar notes == null, não string vazia',
      );
    });
  });

  // ── 3. Câmera sucesso ─────────────────────────────────────────────────────

  group('3 — Câmera sucesso', () {
    testWidgets(
        'tap em edit_stop_camera → saveFor chamado com (routeId, stopId) e '
        'photoPaths atualizado no provider', (tester) async {
      _useTallFrame(tester);

      // Cria arquivo temporário real com bytes PNG válidos.
      final tmpDir = Directory.systemTemp.createTempSync('stop_photo_test_');
      addTearDown(() => tmpDir.deleteSync(recursive: true));
      final tmpFile = File('${tmpDir.path}/photo.jpg');
      tmpFile.writeAsBytesSync(_kMinimalPng1x1);

      final fakeXFile = XFile(tmpFile.path);
      final photoStore = FakePackagePhotoStore()
        ..saveForResult = '/fake/saved/path.jpg';

      final container = ProviderContainer(
        overrides: [
          routesProvider.overrideWith(
            () => _FakeRoutes([
              domain.Route(
                id: 'r1',
                date: DateTime(2026, 5, 27),
                status: domain.RouteStatus.running,
                stops: [_stopBase],
              ),
            ]),
          ),
          packagePhotoStoreProvider.overrideWithValue(photoStore),
          cameraPickerProvider.overrideWithValue(() async => fakeXFile),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _buildWithContainer(
          stop: _stopBase,
          picker: () async => fakeXFile,
          photoStore: photoStore,
          container: container,
        ),
      );
      await tester.pumpAndSettle();

      // Toca no botão da câmera.
      await tester.tap(find.bySemanticsIdentifier('edit_stop_camera'));
      await tester.pumpAndSettle();

      // saveFor deve ter sido chamado uma vez com routeId='r1', stopId='s1'.
      expect(
        photoStore.saveForCalls,
        contains(('r1', 's1')),
        reason: 'saveFor deve ser chamado com (routeId, stopId) corretos',
      );

      // Provider deve ter photoPaths contendo o path retornado.
      final routes = container.read(routesProvider);
      final stop = routes
          .firstWhere((r) => r.id == 'r1')
          .stops
          .firstWhere((s) => s.id == 's1');
      expect(
        stop.photoPaths,
        contains('/fake/saved/path.jpg'),
        reason: 'photoPaths deve conter o path retornado por saveFor',
      );
    });
  });

  // ── 4. Câmera cancelada ───────────────────────────────────────────────────

  group('4 — Câmera cancelada (picker retorna null)', () {
    testWidgets('picker retorna null → SnackBar presente + photoPaths intacto',
        (tester) async {
      _useTallFrame(tester);

      final photoStore = FakePackagePhotoStore();

      final container = ProviderContainer(
        overrides: [
          routesProvider.overrideWith(
            () => _FakeRoutes([
              domain.Route(
                id: 'r1',
                date: DateTime(2026, 5, 27),
                status: domain.RouteStatus.running,
                stops: [_stopBase],
              ),
            ]),
          ),
          packagePhotoStoreProvider.overrideWithValue(photoStore),
          cameraPickerProvider.overrideWithValue(() async => null),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _buildWithContainer(
          stop: _stopBase,
          picker: () async => null,
          photoStore: photoStore,
          container: container,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsIdentifier('edit_stop_camera'));
      await tester.pumpAndSettle();

      // SnackBar deve estar presente (microcopy de cancelamento/negação).
      expect(
        find.byType(SnackBar),
        findsOneWidget,
        reason: 'cancelamento deve exibir SnackBar',
      );

      // Estado do stop não deve ter mudado.
      final routes = container.read(routesProvider);
      final stop = routes
          .firstWhere((r) => r.id == 'r1')
          .stops
          .firstWhere((s) => s.id == 's1');
      expect(
        stop.photoPaths,
        isEmpty,
        reason: 'photoPaths deve permanecer intacto após cancelamento',
      );

      // saveFor não deve ter sido chamado.
      expect(
        photoStore.saveForCalls,
        isEmpty,
        reason: 'saveFor não deve ser chamado quando picker retorna null',
      );
    });
  });

  // ── 5. Permissão negada ───────────────────────────────────────────────────

  group('5 — Permissão negada (PlatformException camera_access_denied)', () {
    testWidgets(
        'picker lança PlatformException → SnackBar presente + estado intacto '
        '+ exceção não vaza (tester.takeException() == null)', (tester) async {
      _useTallFrame(tester);

      final photoStore = FakePackagePhotoStore();

      final container = ProviderContainer(
        overrides: [
          routesProvider.overrideWith(
            () => _FakeRoutes([
              domain.Route(
                id: 'r1',
                date: DateTime(2026, 5, 27),
                status: domain.RouteStatus.running,
                stops: [_stopBase],
              ),
            ]),
          ),
          packagePhotoStoreProvider.overrideWithValue(photoStore),
          cameraPickerProvider.overrideWithValue(
            () async => throw PlatformException(
              code: 'camera_access_denied',
              message: 'Acesso à câmera negado',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _buildWithContainer(
          stop: _stopBase,
          picker: () async => throw PlatformException(
            code: 'camera_access_denied',
          ),
          photoStore: photoStore,
          container: container,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsIdentifier('edit_stop_camera'));
      await tester.pumpAndSettle();

      // SnackBar deve estar presente.
      expect(
        find.byType(SnackBar),
        findsOneWidget,
        reason: 'permissão negada deve exibir SnackBar',
      );

      // Exceção não deve ter vazado.
      expect(
        tester.takeException(),
        isNull,
        reason: 'PlatformException não deve vazar para o tester',
      );

      // Estado intacto.
      final routes = container.read(routesProvider);
      final stop = routes
          .firstWhere((r) => r.id == 'r1')
          .stops
          .firstWhere((s) => s.id == 's1');
      expect(stop.photoPaths, isEmpty);
    });
  });

  // ── 6. Thumbnails ─────────────────────────────────────────────────────────

  group('6 — Thumbnails (H15)', () {
    testWidgets(
        'stop com photoPaths com path inexistente → placeholder '
        'Key("stop_photo_placeholder_0") presente, sem crash', (tester) async {
      _useTallFrame(tester);

      final stop = _stopBase.copyWith(
        photoPaths: ['/caminho/que/nao/existe.jpg'],
      );

      await tester.pumpWidget(
        _buildWidget(
          stop: stop,
          pickerResult: () async => null,
          photoStore: FakePackagePhotoStore(),
        ),
      );
      // FileImage faz I/O REAL: o FakeAsync do tester nunca completa o
      // readAsBytes — runAsync dá um turno de event loop verdadeiro para a
      // falha de leitura chegar ao errorBuilder.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();

      expect(
        find.byKey(const Key('stop_photo_placeholder_0')),
        findsOneWidget,
        reason: 'path inexistente deve renderizar placeholder sem crash (H15)',
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'stop com photoPath REAL (PNG 1×1) → Image renderiza '
        'Key("stop_photo_0") presente', (tester) async {
      _useTallFrame(tester);

      // Cria arquivo temporário com bytes PNG válidos.
      final tmpDir = Directory.systemTemp.createTempSync('thumb_test_');
      addTearDown(() => tmpDir.deleteSync(recursive: true));
      final tmpFile = File('${tmpDir.path}/real_photo.jpg');
      tmpFile.writeAsBytesSync(_kMinimalPng1x1);

      final stop = _stopBase.copyWith(photoPaths: [tmpFile.path]);

      await tester.pumpWidget(
        _buildWidget(
          stop: stop,
          pickerResult: () async => null,
          photoStore: FakePackagePhotoStore(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(
        find.byKey(const Key('stop_photo_0')),
        findsOneWidget,
        reason: 'arquivo PNG válido deve renderizar Image com Key correto',
      );

      expect(tester.takeException(), isNull);
    });
  });
}
