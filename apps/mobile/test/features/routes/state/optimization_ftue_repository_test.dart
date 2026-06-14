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

  test('false por padrão, true após acknowledgeNumbering', () async {
    final repo = OptimizationFtueRepository(SharedPreferencesAsync());

    expect(await repo.isNumberingAcknowledged(), isFalse);

    await repo.acknowledgeNumbering();

    expect(await repo.isNumberingAcknowledged(), isTrue);
  });
}
