import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:roteirizador_pro/features/stops/data/repositories/shared_prefs_stops_repository.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  Stop make(String id, double lat, double lng) => Stop(
        id: id,
        lat: lat,
        lng: lng,
        label: 'L-$id',
        source: StopSource.manual,
        createdAt: DateTime.utc(2026, 5, 13, 12),
      );

  test('load returns empty list when no key is present', () async {
    final repo = SharedPrefsStopsRepository();
    expect(await repo.load(), isEmpty);
  });

  test('save then load roundtrips the list preserving order', () async {
    final repo = SharedPrefsStopsRepository();
    final stops = [make('a', 1, 2), make('b', 3, 4), make('c', 5, 6)];

    await repo.save(stops);
    final restored = await repo.load();

    expect(restored, stops);
  });

  test('persisted JSON uses the _v: 1 envelope', () async {
    final repo = SharedPrefsStopsRepository();
    await repo.save([make('a', 1, 2)]);

    final raw = await SharedPreferencesAsync()
        .getString(SharedPrefsStopsRepository.storageKey);

    expect(raw, isNotNull);
    expect(raw, contains('"_v":1'));
    expect(raw, contains('"stops"'));
  });

  test('load tolerates a corrupt/legacy payload by returning empty', () async {
    await SharedPreferencesAsync()
        .setString(SharedPrefsStopsRepository.storageKey, 'not-json');

    final repo = SharedPrefsStopsRepository();
    expect(await repo.load(), isEmpty);
  });

  test('save([]) clears the persisted list', () async {
    final repo = SharedPrefsStopsRepository();
    await repo.save([make('a', 1, 2)]);
    await repo.save([]);

    expect(await repo.load(), isEmpty);
  });
}
