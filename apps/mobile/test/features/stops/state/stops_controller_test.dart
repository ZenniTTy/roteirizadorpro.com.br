import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

import '../_helpers/fake_stops_repository.dart';

Stop _stop(String id, {double lat = 0, double lng = 0}) => Stop(
      id: id,
      lat: lat,
      lng: lng,
      label: 'L-$id',
      source: StopSource.manual,
      createdAt: DateTime.utc(2026, 5, 13, 12),
    );

void main() {
  late FakeStopsRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = FakeStopsRepository();
    container = ProviderContainer(
      overrides: [stopsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  test('build hydrates from repository', () async {
    repo.seed([_stop('a'), _stop('b')]);
    final initial = await container.read(stopsControllerProvider.future);
    expect(initial.map((s) => s.id), ['a', 'b']);
  });

  test('add appends and persists', () async {
    await container.read(stopsControllerProvider.future);
    final controller = container.read(stopsControllerProvider.notifier);

    await controller.add(_stop('a'));
    await controller.add(_stop('b'));

    final state = await container.read(stopsControllerProvider.future);
    expect(state.map((s) => s.id), ['a', 'b']);
    expect(repo.saved.map((s) => s.id), ['a', 'b']);
  });

  test('remove drops the matching id', () async {
    repo.seed([_stop('a'), _stop('b'), _stop('c')]);
    await container.read(stopsControllerProvider.future);
    final controller = container.read(stopsControllerProvider.notifier);

    await controller.remove('b');

    final state = await container.read(stopsControllerProvider.future);
    expect(state.map((s) => s.id), ['a', 'c']);
  });

  test('update replaces by id preserving order', () async {
    repo.seed([_stop('a'), _stop('b', lat: 1)]);
    await container.read(stopsControllerProvider.future);
    final controller = container.read(stopsControllerProvider.notifier);

    await controller.updateStop(_stop('b', lat: 99));

    final state = await container.read(stopsControllerProvider.future);
    expect(state[1].lat, 99);
    expect(state.map((s) => s.id), ['a', 'b']);
  });

  test('reorder moves by index', () async {
    repo.seed([_stop('a'), _stop('b'), _stop('c')]);
    await container.read(stopsControllerProvider.future);
    final controller = container.read(stopsControllerProvider.notifier);

    await controller.reorder(0, 2);

    final state = await container.read(stopsControllerProvider.future);
    expect(state.map((s) => s.id), ['b', 'a', 'c']);
  });

  test('applyOptimizedOrder permutes by index list', () async {
    repo.seed([_stop('a'), _stop('b'), _stop('c')]);
    await container.read(stopsControllerProvider.future);
    final controller = container.read(stopsControllerProvider.notifier);

    await controller.applyOptimizedOrder([2, 0, 1]);

    final state = await container.read(stopsControllerProvider.future);
    expect(state.map((s) => s.id), ['c', 'a', 'b']);
  });

  test('clear empties the list and persists', () async {
    repo.seed([_stop('a')]);
    await container.read(stopsControllerProvider.future);
    final controller = container.read(stopsControllerProvider.notifier);

    await controller.clear();

    final state = await container.read(stopsControllerProvider.future);
    expect(state, isEmpty);
    expect(repo.saved, isEmpty);
  });
}
