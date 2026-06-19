import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roteirizador_pro/features/routes/data/active_route_repository.dart';

class _MockPrefs extends Mock implements SharedPreferencesAsync {}

void main() {
  late _MockPrefs prefs;
  late ActiveRouteRepository repo;

  setUp(() {
    prefs = _MockPrefs();
    repo = ActiveRouteRepository(prefs);
  });

  test('read() returns the persisted id', () async {
    when(() => prefs.getString('active_route_id_v1'))
        .thenAnswer((_) async => 'route-42');
    expect(await repo.read(), 'route-42');
  });

  test('read() returns null when nothing persisted', () async {
    when(() => prefs.getString('active_route_id_v1'))
        .thenAnswer((_) async => null);
    expect(await repo.read(), isNull);
  });

  test('write(id) persists the id under the v1 key', () async {
    when(() => prefs.setString('active_route_id_v1', 'route-7'))
        .thenAnswer((_) async {});
    await repo.write('route-7');
    verify(() => prefs.setString('active_route_id_v1', 'route-7')).called(1);
  });

  test('write(null) removes the key (no orphan id)', () async {
    when(() => prefs.remove('active_route_id_v1')).thenAnswer((_) async {});
    await repo.write(null);
    verify(() => prefs.remove('active_route_id_v1')).called(1);
  });
}
