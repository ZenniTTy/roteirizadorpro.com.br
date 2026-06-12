import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/data/address_instructions_repository.dart';
import 'package:roteirizador_pro/features/routes/state/address_instructions_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Cria um [ProviderContainer] com store em memória.
/// Espelha o padrão de settings_controller_test e route_defaults_controller_test.
ProviderContainer _container() {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  final c = ProviderContainer(
    overrides: [
      addressInstructionsRepositoryProvider.overrideWithValue(
        AddressInstructionsRepository(SharedPreferencesAsync()),
      ),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('build() — lê o envelope persistido', () {
    test(
      'retorna mapa semeado via repository antes do build (valor não-default)',
      () async {
        // Semeia uma entrada ANTES de construir o container, para que
        // build() retorne um valor não-vazio — prova que ele lê o repo,
        // não retorna {} por padrão acidental.
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.empty();
        final repo = AddressInstructionsRepository(SharedPreferencesAsync());
        await repo.saveDefault('Rua Semente, 99', 'campainha lateral');

        final c = ProviderContainer(
          overrides: [
            addressInstructionsRepositoryProvider.overrideWithValue(repo),
          ],
        );
        addTearDown(c.dispose);

        final result =
            await c.read(addressInstructionsControllerProvider.future);

        expect(
          result['rua semente, 99'],
          'campainha lateral',
          reason: 'build() deve hidratar o state a partir do repository, '
              'não hard-codar um mapa vazio',
        );
      },
    );
  });

  group('saveDefault() — write-then-state pattern', () {
    test(
      'atualiza state para AsyncData com a nova entrada E persiste no repo',
      () async {
        final c = _container();
        // Hidrata o build inicial.
        await c.read(addressInstructionsControllerProvider.future);

        await c
            .read(addressInstructionsControllerProvider.notifier)
            .saveDefault('Av. Brasil, 500', 'portão verde');

        // 1. State in-memory reflete imediatamente.
        final stateAfter =
            await c.read(addressInstructionsControllerProvider.future);
        expect(
          stateAfter['av. brasil, 500'],
          'portão verde',
          reason: 'saveDefault deve atualizar o state para AsyncData contendo '
              'a nova entrada sem round-trip de re-leitura',
        );

        // 2. Repositório também foi persistido.
        final fromRepo =
            await c.read(addressInstructionsRepositoryProvider).read();
        expect(
          fromRepo['av. brasil, 500'],
          'portão verde',
          reason: 'saveDefault deve escrever no repository (não apenas '
              'atualizar o state em memória)',
        );
      },
    );
  });

  group('clearDefault() — write-then-state pattern', () {
    test(
      'remove entrada do state E do repo; outras entradas permanecem intactas',
      () async {
        final c = _container();
        await c.read(addressInstructionsControllerProvider.future);

        // Popula duas entradas.
        final notifier = c.read(addressInstructionsControllerProvider.notifier);
        await notifier.saveDefault('Rua X, 1', 'texto X');
        await notifier.saveDefault('Rua Y, 2', 'texto Y');

        // Remove apenas a primeira.
        await notifier.clearDefault('Rua X, 1');

        // 1. State in-memory: entrada removida.
        final stateAfter =
            await c.read(addressInstructionsControllerProvider.future);
        expect(
          stateAfter.containsKey('rua x, 1'),
          isFalse,
          reason: 'clearDefault deve remover a entrada do state imediatamente',
        );

        // 2. Outra entrada permanece no state.
        expect(
          stateAfter['rua y, 2'],
          'texto Y',
          reason: 'clearDefault não deve afetar outras entradas no state',
        );

        // 3. Persistência confirmada via repo direto.
        final fromRepo =
            await c.read(addressInstructionsRepositoryProvider).read();
        expect(
          fromRepo.containsKey('rua x, 1'),
          isFalse,
          reason: 'clearDefault deve escrever no repository; entrada removida '
              'não pode estar persistida',
        );
        expect(
          fromRepo['rua y, 2'],
          'texto Y',
          reason: 'repository deve manter as outras entradas intactas',
        );
      },
    );
  });
}
