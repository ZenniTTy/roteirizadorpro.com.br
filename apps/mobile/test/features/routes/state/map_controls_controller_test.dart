import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:roteirizador_pro/features/routes/data/map_prefs_repository.dart';
import 'package:roteirizador_pro/features/routes/state/map_controls_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

ProviderContainer _container() {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  final c = ProviderContainer(
    overrides: [
      mapPrefsRepositoryProvider.overrideWithValue(
        MapPrefsRepository(SharedPreferencesAsync()),
      ),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('build()', () {
    test('defaults to MapType.normal + not following on an empty store',
        () async {
      final c = _container();
      final state = await c.read(mapControlsControllerProvider.future);
      expect(state.mapType, MapType.normal);
      expect(state.followingUser, isFalse);
    });

    test('restores the persisted MapType on build', () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final repo = MapPrefsRepository(SharedPreferencesAsync());
      await repo.writeMapType(MapType.satellite);
      final c = ProviderContainer(
        overrides: [mapPrefsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);

      final state = await c.read(mapControlsControllerProvider.future);
      expect(state.mapType, MapType.satellite);
    });
  });

  group('toggleMapType()', () {
    test('flips normal -> satellite and persists', () async {
      final c = _container();
      await c.read(mapControlsControllerProvider.future);

      await c.read(mapControlsControllerProvider.notifier).toggleMapType();

      final state = await c.read(mapControlsControllerProvider.future);
      expect(state.mapType, MapType.satellite);
      // Persisted.
      expect(
        await c.read(mapPrefsRepositoryProvider).readMapType(),
        MapType.satellite,
      );
    });

    test('flips satellite -> normal on a second call (2-state toggle)',
        () async {
      final c = _container();
      await c.read(mapControlsControllerProvider.future);
      final notifier = c.read(mapControlsControllerProvider.notifier);

      await notifier.toggleMapType(); // -> satellite
      await notifier.toggleMapType(); // -> normal

      final state = await c.read(mapControlsControllerProvider.future);
      expect(state.mapType, MapType.normal);
    });

    test('toggling preserves followingUser', () async {
      final c = _container();
      await c.read(mapControlsControllerProvider.future);
      final notifier = c.read(mapControlsControllerProvider.notifier);

      await notifier.startFollowing();
      await notifier.toggleMapType();

      final state = await c.read(mapControlsControllerProvider.future);
      expect(state.followingUser, isTrue);
      expect(state.mapType, MapType.satellite);
    });
  });

  group('follow mode (ephemeral — NOT persisted)', () {
    test('startFollowing() sets followingUser true', () async {
      final c = _container();
      await c.read(mapControlsControllerProvider.future);

      await c.read(mapControlsControllerProvider.notifier).startFollowing();

      final state = await c.read(mapControlsControllerProvider.future);
      expect(state.followingUser, isTrue);
    });

    test(
        'onCameraMoveStarted() with NO pending programmatic move stops follow '
        '(it is a user pan)', () async {
      final c = _container();
      await c.read(mapControlsControllerProvider.future);
      final notifier = c.read(mapControlsControllerProvider.notifier);

      await notifier.startFollowing();
      notifier.onCameraMoveStarted();

      final state = await c.read(mapControlsControllerProvider.future);
      expect(state.followingUser, isFalse);
    });

    test(
        'beginProgrammaticMove() makes the NEXT onCameraMoveStarted a no-op — '
        'our recenter must NOT drop the follow it just enabled (race fix)',
        () async {
      final c = _container();
      await c.read(mapControlsControllerProvider.future);
      final notifier = c.read(mapControlsControllerProvider.notifier);

      await notifier.startFollowing();
      // App animates the camera (recenter): mark the move as ours.
      notifier.beginProgrammaticMove();
      // The GoogleMap fires onCameraMoveStarted for that programmatic move —
      // possibly AFTER the animateCamera Future resolved. It must be consumed,
      // NOT interpreted as a user pan.
      notifier.onCameraMoveStarted();

      final state = await c.read(mapControlsControllerProvider.future);
      expect(
        state.followingUser,
        isTrue,
        reason: 'the programmatic move was consumed, follow stays on',
      );
    });

    test(
        'a programmatic move consumes exactly ONE camera-move event — a '
        'subsequent user pan still stops follow', () async {
      final c = _container();
      await c.read(mapControlsControllerProvider.future);
      final notifier = c.read(mapControlsControllerProvider.notifier);

      await notifier.startFollowing();
      notifier.beginProgrammaticMove();
      notifier.onCameraMoveStarted(); // consumes the programmatic move
      notifier.onCameraMoveStarted(); // real user pan -> stops follow

      final state = await c.read(mapControlsControllerProvider.future);
      expect(state.followingUser, isFalse);
    });

    test('followingUser is NOT persisted across a fresh build', () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final repo = MapPrefsRepository(SharedPreferencesAsync());
      final c1 = ProviderContainer(
        overrides: [mapPrefsRepositoryProvider.overrideWithValue(repo)],
      );
      await c1.read(mapControlsControllerProvider.future);
      await c1.read(mapControlsControllerProvider.notifier).startFollowing();
      c1.dispose();

      // Fresh container over the SAME repo: follow must NOT survive.
      final c2 = ProviderContainer(
        overrides: [mapPrefsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c2.dispose);
      final state = await c2.read(mapControlsControllerProvider.future);
      expect(state.followingUser, isFalse);
    });
  });
}
