import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/location_service.dart';
import '../data/map_prefs_repository.dart';
import '../domain/map_controls_state.dart';

part 'map_controls_controller.g.dart';

/// Singleton repository binding. Override in tests to inject an
/// `InMemorySharedPreferencesAsync`-backed instance.
@Riverpod(keepAlive: true)
MapPrefsRepository mapPrefsRepository(Ref ref) {
  return MapPrefsRepository(SharedPreferencesAsync());
}

/// Singleton location-service binding (recenter flow). Override in tests to
/// inject permission/position branches without a real device.
@Riverpod(keepAlive: true)
LocationService locationService(Ref ref) {
  return LocationService();
}

/// Active-route map controls (layer toggle + recenter follow mode).
///
/// `keepAlive: true` because the map layer preference and follow mode must
/// survive the sheet's frequent rebuilds; dropping the provider would re-read
/// SharedPrefs and reset follow on every drag frame.
@Riverpod(keepAlive: true)
class MapControlsController extends _$MapControlsController {
  /// Count of programmatic camera moves (our recenter animations) whose
  /// `onCameraMoveStarted` callback has not arrived yet. The GoogleMap fires
  /// `onCameraMoveStarted` for BOTH user pans and our own `animateCamera`, and
  /// that callback can arrive AFTER `animateCamera`'s Future resolves — so a
  /// boolean flag reset right after the await would race. A counter consumed
  /// one-per-event is order-independent: each programmatic move is "spent" by
  /// the next camera-move event, and only an unmatched event (a real user pan)
  /// drops follow mode.
  int _pendingProgrammaticMoves = 0;

  @override
  Future<MapControlsState> build() async {
    final mapType = await ref.read(mapPrefsRepositoryProvider).readMapType();
    // followingUser starts false on every build — follow is ephemeral (Spoke
    // drops it to `Manual` on pan; a fresh launch is never auto-following).
    return MapControlsState(mapType: mapType);
  }

  /// Flips the persisted map layer between `normal` and `satellite`
  /// (Spoke `MapTypeClick` -> 2-state `MapTypePreferences`). Preserves the
  /// ephemeral follow mode.
  Future<void> toggleMapType() async {
    final current = await future;
    final next =
        current.mapType == MapType.normal ? MapType.satellite : MapType.normal;
    await ref.read(mapPrefsRepositoryProvider).writeMapType(next);
    state = AsyncData(current.copyWith(mapType: next));
  }

  /// Enters follow-my-location (recenter). Ephemeral — not persisted.
  /// (Spoke `ReCenterButtonClick` -> `MapControllerMode.FollowMyLocation`.)
  Future<void> startFollowing() async {
    final current = await future;
    if (current.followingUser) return;
    state = AsyncData(current.copyWith(followingUser: true));
  }

  /// Marks the start of an app-initiated camera animation (recenter). The next
  /// `onCameraMoveStarted` is then attributed to us, not the user, regardless
  /// of whether it arrives before or after `animateCamera` resolves.
  void beginProgrammaticMove() {
    _pendingProgrammaticMoves++;
  }

  /// Handles a `GoogleMap.onCameraMoveStarted` event. If a programmatic move is
  /// pending it is consumed (no-op — our own recenter); otherwise this is a
  /// genuine user pan and follow mode is dropped (Spoke's exit to
  /// `MapControllerMode.Manual`). Synchronous: the callback fires on the UI
  /// thread and must not await.
  void onCameraMoveStarted() {
    if (_pendingProgrammaticMoves > 0) {
      _pendingProgrammaticMoves--;
      return;
    }
    final current = state.value;
    if (current == null || !current.followingUser) return;
    state = AsyncData(current.copyWith(followingUser: false));
  }
}
