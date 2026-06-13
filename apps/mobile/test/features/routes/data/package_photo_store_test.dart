import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/data/package_photo_store.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Infra: diretório temporário real criado e apagado por cada grupo/teste.
  // A injeção via baseDirProvider dispensa path_provider nos testes.
  // ---------------------------------------------------------------------------
  late Directory tempDir;
  late PackagePhotoStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pkg_photo_test_');
    store = PackagePhotoStore(baseDirProvider: () async => tempDir);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  // Helper: grava um arquivo-fonte de conteúdo fixo no tempDir.
  Future<File> makeSourceFile(String name, String content) async {
    final f = File('${tempDir.path}/$name');
    await f.writeAsString(content);
    return f;
  }

  // ---------------------------------------------------------------------------
  // saveFor
  // ---------------------------------------------------------------------------
  group('saveFor', () {
    test(
        'copia o arquivo para package_photos/<routeId>/<stopId>/<uuid>.jpg, '
        'retorna path existente com conteúdo idêntico e segmentos corretos',
        () async {
      final source = await makeSourceFile('foto.jpg', 'conteudo-foto');
      const routeId = 'rota-1';
      const stopId = 'stop-A';

      final result = await store.saveFor(routeId, stopId, source);

      // Retorno não é null.
      expect(result, isNotNull);

      // Arquivo existe no disco.
      final saved = File(result!);
      expect(
        saved.existsSync(),
        isTrue,
        reason: 'O arquivo salvo deve existir no disco',
      );

      // Conteúdo idêntico ao source.
      expect(
        await saved.readAsString(),
        'conteudo-foto',
        reason: 'Conteúdo do arquivo salvo deve ser igual ao source',
      );

      // Path contém os segmentos esperados e termina em .jpg.
      expect(
        result,
        contains('package_photos/$routeId/$stopId'),
        reason: 'Path deve conter package_photos/<routeId>/<stopId>',
      );
      expect(
        result,
        endsWith('.jpg'),
        reason: 'Path deve terminar em .jpg',
      );
    });

    test(
        'dois saveFor consecutivos do mesmo source geram paths DIFERENTES '
        '(uuid distinto no nome)', () async {
      final source = await makeSourceFile('foto2.jpg', 'bytes');
      const routeId = 'rota-1';
      const stopId = 'stop-B';

      final path1 = await store.saveFor(routeId, stopId, source);
      final path2 = await store.saveFor(routeId, stopId, source);

      expect(path1, isNotNull);
      expect(path2, isNotNull);
      expect(
        path1,
        isNot(equals(path2)),
        reason:
            'Cada chamada deve gerar um nome de arquivo único (uuid distinto)',
      );
    });

    test('sourceFile inexistente retorna null e NÃO lança exceção (H15)',
        () async {
      final missing = File('${tempDir.path}/nao_existe.jpg');
      // Garante que o arquivo realmente não existe.
      expect(missing.existsSync(), isFalse);

      final result = await store.saveFor('rota-x', 'stop-x', missing);

      expect(
        result,
        isNull,
        reason:
            'Falha de I/O deve retornar null, nunca propagar exceção para a UI',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // copyAll
  // ---------------------------------------------------------------------------
  group('copyAll', () {
    test(
        'com 2 fotos salvas em fromStop, retorna 2 paths sob toStop, '
        'arquivos existem e são disjuntos dos originais (H16)', () async {
      const routeId = 'rota-2';
      const fromStop = 'stop-orig';
      const toStop = 'stop-copia';

      final s1 = await makeSourceFile('f1.jpg', 'dados1');
      final s2 = await makeSourceFile('f2.jpg', 'dados2');

      final orig1 = await store.saveFor(routeId, fromStop, s1);
      final orig2 = await store.saveFor(routeId, fromStop, s2);

      expect(orig1, isNotNull);
      expect(orig2, isNotNull);

      final copied = await store.copyAll(routeId, fromStop, toStop);

      // Dois paths retornados.
      expect(
        copied,
        hasLength(2),
        reason: 'Deve retornar um path por foto copiada',
      );

      // Cada arquivo copiado existe no disco.
      for (final p in copied) {
        expect(
          File(p).existsSync(),
          isTrue,
          reason: 'Arquivo copiado $p deve existir no disco',
        );
      }

      // Paths estão sob o diretório do toStop.
      for (final p in copied) {
        expect(
          p,
          contains('package_photos/$routeId/$toStop'),
          reason: 'Path copiado deve estar sob o diretório do toStop',
        );
      }

      // Paths são disjuntos dos originais (não compartilhados — H16).
      expect(copied, isNot(contains(orig1)));
      expect(copied, isNot(contains(orig2)));

      // Originais continuam existindo.
      expect(
        File(orig1!).existsSync(),
        isTrue,
        reason: 'Arquivo original fromStop deve continuar existindo após cópia',
      );
      expect(
        File(orig2!).existsSync(),
        isTrue,
        reason: 'Arquivo original fromStop deve continuar existindo após cópia',
      );
    });

    test('de stop sem fotos retorna lista vazia sem lançar exceção', () async {
      final result =
          await store.copyAll('rota-vazia', 'stop-sem-foto', 'stop-dest');

      expect(
        result,
        isEmpty,
        reason:
            'copyAll de stop sem fotos deve retornar lista vazia, nunca lançar',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // deleteFor
  // ---------------------------------------------------------------------------
  group('deleteFor', () {
    test(
        'remove o diretório do stop — paths salvos anteriormente deixam de '
        'existir — e retorna true', () async {
      const routeId = 'rota-3';
      const stopId = 'stop-del';

      final source = await makeSourceFile('foto_del.jpg', 'x');
      final saved = await store.saveFor(routeId, stopId, source);
      expect(saved, isNotNull);
      expect(File(saved!).existsSync(), isTrue);

      final ok = await store.deleteFor(routeId, stopId);

      expect(
        ok,
        isTrue,
        reason: 'deleteFor de stop existente deve retornar true',
      );
      expect(
        File(saved).existsSync(),
        isFalse,
        reason: 'Arquivo do stop deve ter sido removido do disco',
      );
    });

    test('de stop que nunca teve foto retorna false e NÃO lança exceção',
        () async {
      // Nenhuma foto foi salva para este stop.
      final result =
          await store.deleteFor('rota-inexistente', 'stop-inexistente');

      // Contrato do plano: diretório inexistente → false, sem throw.
      expect(
        result,
        isFalse,
        reason:
            'deleteFor de stop inexistente deve retornar false, nunca lançar',
      );
    });
  });
}
