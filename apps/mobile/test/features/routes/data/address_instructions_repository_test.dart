import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/data/address_instructions_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('read() — chave ausente → mapa vazio (contrato F13)', () {
    test(
      'retorna {} quando a chave ainda não existe (não {} default implícito)',
      () async {
        final repo = AddressInstructionsRepository(SharedPreferencesAsync());

        final result = await repo.read();

        // Deve ser vazio — mas NUNCA pode passar antes da implementação
        // existir: um stub throw UnimplementedError() deve falhar aqui.
        expect(
          result,
          isEmpty,
          reason: 'F13: envelope ausente → mapa vazio, sem throw',
        );
        expect(
          result,
          isA<Map<String, String>>(),
          reason: 'tipo deve ser Map<String, String>',
        );
      },
    );
  });

  group('normalizeKey() — H18: trim + lowercase canônico', () {
    test(
      "normalizeKey('  AbC, 1  ') == 'abc, 1'",
      () {
        const input = '  AbC, 1  ';
        const expected = 'abc, 1';

        final result = AddressInstructionsRepository.normalizeKey(input);

        // Valor não-default — não pode passar acidentalmente num stub.
        expect(
          result,
          expected,
          reason: 'H18: trim().toLowerCase() é a normalização canônica',
        );
      },
    );
  });

  group(
    'saveDefault + instructionFor — normalização H18 nas duas pontas',
    () {
      test(
        'salva com espaços e maiúsculas; recupera com chave em minúsculas (H18)',
        () async {
          final prefs = SharedPreferencesAsync();
          final repo = AddressInstructionsRepository(prefs);

          await repo.saveDefault('  Av. Paulista, 100  ', 'portão azul');

          final result = await repo.instructionFor('av. paulista, 100');

          // Valor não-default: 'portão azul' nunca seria retornado sem
          // implementação real de normalização.
          expect(
            result,
            'portão azul',
            reason: 'H18: chave normalizada em saveDefault deve ser encontrada '
                'por instructionFor com chave já normalizada',
          );
        },
      );

      test(
        'instructionFor com chave em maiúsculas encontra valor salvo em minúsculas (H18)',
        () async {
          final prefs = SharedPreferencesAsync();
          final repo = AddressInstructionsRepository(prefs);

          await repo.saveDefault('  Av. Paulista, 100  ', 'portão azul');

          final result = await repo.instructionFor('AV. PAULISTA, 100');

          expect(
            result,
            'portão azul',
            reason: 'H18: normalização é simétrica — maiúsculas na busca '
                'também encontram a entrada',
          );
        },
      );
    },
  );

  group('persistência real — mesma instância prefs, instâncias repo distintas',
      () {
    test(
      'gravar com uma instância; ler com outra instância do mesmo prefs → valor lá',
      () async {
        final prefs = SharedPreferencesAsync();
        final repoA = AddressInstructionsRepository(prefs);
        final repoB = AddressInstructionsRepository(prefs);

        await repoA.saveDefault('Rua das Flores, 42', 'campainha 3');

        // repoB é uma instância diferente — confirma que a persistência
        // ocorreu no SharedPreferences, não apenas em memória.
        final result = await repoB.instructionFor('rua das flores, 42');

        expect(
          result,
          'campainha 3',
          reason: 'persistência real: instância distinta do repo deve enxergar '
              'o valor gravado pela primeira instância',
        );
      },
    );
  });

  group('saveDefault idempotência — substitui, não duplica', () {
    test(
      'salvar duas vezes o mesmo endereço com textos diferentes → read() tem 1 entrada',
      () async {
        final prefs = SharedPreferencesAsync();
        final repo = AddressInstructionsRepository(prefs);

        await repo.saveDefault('Rua A, 1', 'primeiro texto');
        await repo.saveDefault('Rua A, 1', 'segundo texto');

        final map = await repo.read();

        // Exatamente 1 entrada — não pode duplicar.
        expect(
          map.length,
          1,
          reason: 'saveDefault do mesmo endereço substitui o texto anterior; '
              'não cria entrada duplicada',
        );
        expect(
          map.values.first,
          'segundo texto',
          reason: 'o valor mais recente prevalece',
        );
      },
    );
  });

  group('clearDefault — remove entrada, preserva outras', () {
    test(
      'após clearDefault: instructionFor retorna null; outros endereços intactos',
      () async {
        final prefs = SharedPreferencesAsync();
        final repo = AddressInstructionsRepository(prefs);

        await repo.saveDefault('Rua A, 1', 'texto A');
        await repo.saveDefault('Rua B, 2', 'texto B');

        await repo.clearDefault('Rua A, 1');

        // Endereço removido → null.
        final afterClear = await repo.instructionFor('rua a, 1');
        expect(
          afterClear,
          isNull,
          reason:
              'clearDefault deve remover a entrada; instructionFor retorna null',
        );

        // Outro endereço permanece intacto.
        final otherEntry = await repo.instructionFor('rua b, 2');
        expect(
          otherEntry,
          'texto B',
          reason: 'clearDefault não deve afetar outros endereços no envelope',
        );
      },
    );
  });

  group('resiliência envelope corrompido — H15', () {
    test(
      'JSON malformado → read() retorna {} sem throw',
      () async {
        final prefs = SharedPreferencesAsync();
        await prefs.setString(
          AddressInstructionsRepository.storageKey,
          '{{{nope',
        );
        final repo = AddressInstructionsRepository(prefs);

        // H15: não deve lançar exceção.
        final result = await repo.read();

        expect(
          result,
          isEmpty,
          reason: 'H15: JSON malformado → {} sem throw',
        );
      },
    );

    test(
      "JSON válido mas não-mapa ('42') → read() retorna {} sem throw",
      () async {
        final prefs = SharedPreferencesAsync();
        await prefs.setString(
          AddressInstructionsRepository.storageKey,
          jsonEncode(42),
        );
        final repo = AddressInstructionsRepository(prefs);

        final result = await repo.read();

        expect(
          result,
          isEmpty,
          reason: 'H15: payload não-mapa (bare integer) → {} sem throw',
        );
      },
    );
  });
}
