import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/address_instructions_repository.dart';

part 'address_instructions_controller.g.dart';

/// Singleton repository binding. Override in tests to inject an
/// `InMemorySharedPreferencesAsync`-backed instance.
@Riverpod(keepAlive: true)
AddressInstructionsRepository addressInstructionsRepository(Ref ref) {
  return AddressInstructionsRepository(SharedPreferencesAsync());
}

/// Mapa de instruções de acesso por endereço (sticky-ao-endereço, F13).
/// Singleton — um único envelope compartilhado entre todas as paradas.
///
/// `keepAlive: true` espelha o padrão `settingsRepository`: callers lêem
/// este mapa em boundaries de navegação; descartar o provider forçaria uma
/// re-leitura do SharedPrefs a cada navegação.
@Riverpod(keepAlive: true)
class AddressInstructionsController extends _$AddressInstructionsController {
  @override
  Future<Map<String, String>> build() async {
    final repo = ref.read(addressInstructionsRepositoryProvider);
    return repo.read();
  }

  /// Grava/substitui a instrução do [fullAddress] e atualiza o state para
  /// `AsyncData` do mapa novo (write-then-state).
  Future<void> saveDefault(String fullAddress, String text) async {
    final repo = ref.read(addressInstructionsRepositoryProvider);
    await repo.saveDefault(fullAddress, text);
    state = AsyncData(await repo.read());
  }

  /// Remove a instrução do [fullAddress] e atualiza o state para
  /// `AsyncData` do mapa resultante (write-then-state).
  Future<void> clearDefault(String fullAddress) async {
    final repo = ref.read(addressInstructionsRepositoryProvider);
    await repo.clearDefault(fullAddress);
    state = AsyncData(await repo.read());
  }
}
