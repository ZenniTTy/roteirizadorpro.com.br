import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Sealed outcome of a one-shot location lookup. Exhaustive — a `switch` on it
/// has no `default` (per the project's sealed-result convention).
sealed class LocationResult {
  const LocationResult();
}

/// The device location is known.
class LocationReady extends LocationResult {
  const LocationReady(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

/// The user declined (or permanently declined) the location permission. The
/// caller degrades gracefully (a toast), never crashes.
class LocationDenied extends LocationResult {
  const LocationDenied();
}

/// Permission was granted but the position could not be obtained (services off,
/// timeout, platform error). Also a graceful-degradation signal, not a throw.
class LocationUnavailable extends LocationResult {
  const LocationUnavailable();
}

/// One-shot location lookup wrapping `geolocator`. The three platform calls are
/// injected so tests can exercise every permission branch without a real
/// device or a method-channel mock (the static `Geolocator.*` calls are
/// supplied as defaults for production).
class LocationService {
  LocationService({
    Future<LocationPermission> Function()? checkPermission,
    Future<LocationPermission> Function()? requestPermission,
    Future<Position> Function()? getCurrentPosition,
  })  : _checkPermission = checkPermission ?? Geolocator.checkPermission,
        _requestPermission = requestPermission ?? Geolocator.requestPermission,
        _getCurrentPosition = getCurrentPosition ??
            (() => Geolocator.getCurrentPosition(
                  locationSettings: const LocationSettings(
                    accuracy: LocationAccuracy.high,
                  ),
                ));

  final Future<LocationPermission> Function() _checkPermission;
  final Future<LocationPermission> Function() _requestPermission;
  final Future<Position> Function() _getCurrentPosition;

  Future<LocationResult> currentLocation() async {
    var permission = await _checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _requestPermission();
    }
    final granted = permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
    if (!granted) return const LocationDenied();

    try {
      final position = await _getCurrentPosition();
      return LocationReady(position.latitude, position.longitude);
    } catch (e) {
      // Services off, timeout, or a platform error: degrade gracefully — the
      // caller shows a toast, the app never crashes on a recenter tap. Logged
      // so a real failure is distinguishable from a denied permission.
      debugPrint('[location_service] position lookup failed: $e');
      return const LocationUnavailable();
    }
  }
}
