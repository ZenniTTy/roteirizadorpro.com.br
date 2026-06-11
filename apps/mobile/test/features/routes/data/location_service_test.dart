import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:roteirizador_pro/features/routes/data/location_service.dart';

/// A [Position] is verbose to build; this helper makes one at a fixed point.
Position _pos(double lat, double lng) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.fromMillisecondsSinceEpoch(0),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

void main() {
  group('currentLocation()', () {
    test('returns LocationReady with the position when permission is granted',
        () async {
      final service = LocationService(
        checkPermission: () async => LocationPermission.whileInUse,
        requestPermission: () async => LocationPermission.whileInUse,
        getCurrentPosition: () async => _pos(-23.55, -46.63),
      );

      final result = await service.currentLocation();

      expect(result, isA<LocationReady>());
      final ready = result as LocationReady;
      expect(ready.latitude, -23.55);
      expect(ready.longitude, -46.63);
    });

    test('requests permission when initially denied, succeeds if then granted',
        () async {
      var requested = false;
      final service = LocationService(
        checkPermission: () async => LocationPermission.denied,
        requestPermission: () async {
          requested = true;
          return LocationPermission.whileInUse;
        },
        getCurrentPosition: () async => _pos(-23.0, -46.0),
      );

      final result = await service.currentLocation();

      expect(requested, isTrue);
      expect(result, isA<LocationReady>());
    });

    test('returns LocationDenied (NOT an exception) when permission is denied',
        () async {
      final service = LocationService(
        checkPermission: () async => LocationPermission.denied,
        requestPermission: () async => LocationPermission.denied,
        getCurrentPosition: () async => _pos(0, 0),
      );

      final result = await service.currentLocation();

      expect(result, isA<LocationDenied>());
    });

    test('returns LocationDenied when permission is deniedForever', () async {
      final service = LocationService(
        checkPermission: () async => LocationPermission.deniedForever,
        requestPermission: () async => LocationPermission.deniedForever,
        getCurrentPosition: () async => _pos(0, 0),
      );

      final result = await service.currentLocation();

      expect(result, isA<LocationDenied>());
    });

    test('does NOT call getCurrentPosition when permission is denied',
        () async {
      var positionFetched = false;
      final service = LocationService(
        checkPermission: () async => LocationPermission.deniedForever,
        requestPermission: () async => LocationPermission.deniedForever,
        getCurrentPosition: () async {
          positionFetched = true;
          return _pos(0, 0);
        },
      );

      await service.currentLocation();

      expect(positionFetched, isFalse);
    });

    test(
        'returns LocationUnavailable (NOT an exception) when the position '
        'lookup throws', () async {
      final service = LocationService(
        checkPermission: () async => LocationPermission.whileInUse,
        requestPermission: () async => LocationPermission.whileInUse,
        getCurrentPosition: () async =>
            throw const LocationServiceDisabledException(),
      );

      final result = await service.currentLocation();

      expect(result, isA<LocationUnavailable>());
    });
  });
}
