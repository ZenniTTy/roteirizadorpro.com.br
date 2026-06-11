import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Immutable state of the active-route map controls (the two floating circular
/// buttons on the right of [RouteShellPage]).
///
/// Mirrors Spoke's behavior (static dump v3.65.1, `EditRouteFragment` +
/// `MapController`):
///   - **mapType** — a persisted 2-state toggle (`normal` <-> `satellite`),
///     stored in `MapTypePreferences` on the Spoke side. The layer button
///     flips it and shows a toast.
///   - **followingUser** — the recenter button enters `FollowMyLocation`
///     (camera tracks the GPS); the mode is ephemeral and is dropped the
///     moment the user pans the map (Spoke's `MapControllerMode.Manual`). It is
///     deliberately NOT persisted.
@immutable
class MapControlsState {
  const MapControlsState({
    this.mapType = MapType.normal,
    this.followingUser = false,
  });

  final MapType mapType;
  final bool followingUser;

  MapControlsState copyWith({MapType? mapType, bool? followingUser}) {
    return MapControlsState(
      mapType: mapType ?? this.mapType,
      followingUser: followingUser ?? this.followingUser,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapControlsState &&
          other.mapType == mapType &&
          other.followingUser == followingUser;

  @override
  int get hashCode => Object.hash(mapType, followingUser);
}
