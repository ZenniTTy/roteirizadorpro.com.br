// test/features/routes/state/optimization_ftue_repository_pr_c_test.dart
//
// TDD red — PR-C sub-unidade 1: novos métodos isIdLockAcknowledged /
// acknowledgeIdLock no OptimizationFtueRepository.
//
// Comportamentos pinados:
//  - isIdLockAcknowledged() retorna false por padrão (key id_lock_ftue_v1)
//  - acknowledgeIdLock() → isIdLockAcknowledged() passa a retornar true
//  - acknowledgeIdLock NÃO afeta isNumberingAcknowledged (chaves independentes)
//  - acknowledgeNumbering NÃO afeta isIdLockAcknowledged (chaves independentes)
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:roteirizador_pro/features/routes/state/optimization_ftue_repository.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('isIdLockAcknowledged / acknowledgeIdLock (PR-C)', () {
    test(
      'false por padrão (key id_lock_ftue_v1 não existe ainda)',
      () async {
        final repo = OptimizationFtueRepository(SharedPreferencesAsync());
        expect(await repo.isIdLockAcknowledged(), isFalse);
      },
    );

    test(
      'true após acknowledgeIdLock',
      () async {
        final repo = OptimizationFtueRepository(SharedPreferencesAsync());
        await repo.acknowledgeIdLock();
        expect(await repo.isIdLockAcknowledged(), isTrue);
      },
    );

    test(
      'acknowledgeIdLock NÃO afeta isNumberingAcknowledged '
      '(chaves são independentes — id_lock_ftue_v1 ≠ numbering_ftue_v1)',
      () async {
        final repo = OptimizationFtueRepository(SharedPreferencesAsync());
        // só reconhece id_lock
        await repo.acknowledgeIdLock();
        // numbering ainda deve estar false
        expect(await repo.isNumberingAcknowledged(), isFalse);
      },
    );

    test(
      'acknowledgeNumbering NÃO afeta isIdLockAcknowledged '
      '(chaves são independentes)',
      () async {
        final repo = OptimizationFtueRepository(SharedPreferencesAsync());
        // só reconhece numbering
        await repo.acknowledgeNumbering();
        // id_lock ainda deve estar false
        expect(await repo.isIdLockAcknowledged(), isFalse);
      },
    );
  });
}
