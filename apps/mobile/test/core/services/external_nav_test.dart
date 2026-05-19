import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/core/services/external_nav.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';

Stop _s(double lat, double lng) => Stop(
      id: '$lat,$lng',
      lat: lat,
      lng: lng,
      source: StopSource.manual,
      createdAt: DateTime.utc(2026, 5, 19),
    );

void main() {
  group('ExternalNav.googleMapsUri', () {
    test('single stop omits origin and waypoints', () {
      final uri = ExternalNav.googleMapsUri([_s(-23.55, -46.63)]);

      expect(uri.scheme, 'https');
      expect(uri.host, 'www.google.com');
      expect(uri.path, '/maps/dir/');
      expect(uri.queryParameters['api'], '1');
      expect(uri.queryParameters['destination'], '-23.55,-46.63');
      expect(uri.queryParameters.containsKey('origin'), isFalse);
      expect(uri.queryParameters.containsKey('waypoints'), isFalse);
      expect(uri.queryParameters['travelmode'], 'driving');
    });

    test('two stops put first as waypoint and last as destination', () {
      final uri =
          ExternalNav.googleMapsUri([_s(-23.55, -46.63), _s(-23.56, -46.64)]);

      expect(uri.queryParameters['destination'], '-23.56,-46.64');
      expect(uri.queryParameters['waypoints'], '-23.55,-46.63');
      expect(uri.queryParameters.containsKey('origin'), isFalse);
    });

    test('ten stops fill 9 waypoints + 1 destination at the cap', () {
      final stops =
          List.generate(10, (i) => _s(-23.0 - i * 0.01, -46.0 - i * 0.01));
      final uri = ExternalNav.googleMapsUri(stops);

      expect(uri.queryParameters['destination'], '-23.09,-46.09');
      final waypoints = uri.queryParameters['waypoints']!.split('|');
      expect(waypoints.length, 9);
      expect(waypoints.first, '-23.0,-46.0');
      expect(waypoints.last, '-23.08,-46.08');
    });

    test('eleven stops throw — caller must use chunks', () {
      final stops =
          List.generate(11, (i) => _s(-23.0 - i * 0.01, -46.0 - i * 0.01));

      expect(
        () => ExternalNav.googleMapsUri(stops),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('empty stops throws', () {
      expect(
        () => ExternalNav.googleMapsUri(const []),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('ExternalNav.googleMapsUriChunks', () {
    test('five stops produce one chunk', () {
      final stops =
          List.generate(5, (i) => _s(-23.0 - i * 0.01, -46.0 - i * 0.01));
      final chunks = ExternalNav.googleMapsUriChunks(stops);
      expect(chunks.length, 1);
    });

    test('ten stops produce one chunk at the cap', () {
      final stops =
          List.generate(10, (i) => _s(-23.0 - i * 0.01, -46.0 - i * 0.01));
      final chunks = ExternalNav.googleMapsUriChunks(stops);
      expect(chunks.length, 1);
    });

    test('eleven stops split into 10 + 1', () {
      final stops =
          List.generate(11, (i) => _s(-23.0 - i * 0.01, -46.0 - i * 0.01));
      final chunks = ExternalNav.googleMapsUriChunks(stops);
      expect(chunks.length, 2);
      expect(chunks[0].queryParameters['destination'], '-23.09,-46.09');
      expect(chunks[1].queryParameters['destination'], '-23.1,-46.1');
      expect(chunks[1].queryParameters.containsKey('waypoints'), isFalse);
    });

    test('twenty stops split into 10 + 10', () {
      final stops =
          List.generate(20, (i) => _s(-23.0 - i * 0.01, -46.0 - i * 0.01));
      final chunks = ExternalNav.googleMapsUriChunks(stops);
      expect(chunks.length, 2);
      expect(chunks[0].queryParameters['waypoints']!.split('|').length, 9);
      expect(chunks[1].queryParameters['waypoints']!.split('|').length, 9);
    });

    test('empty stops throw', () {
      expect(
        () => ExternalNav.googleMapsUriChunks(const []),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('ExternalNav.wazeUri', () {
    test('builds waze:// URI with ll and navigate=yes', () {
      final uri = ExternalNav.wazeUri(_s(-23.55, -46.63));

      expect(uri.scheme, 'waze');
      expect(uri.queryParameters['ll'], '-23.55,-46.63');
      expect(uri.queryParameters['navigate'], 'yes');
    });

    test('ungeocoded stop (Null Island sentinel) throws', () {
      final ungeocoded = _s(0, 0);
      expect(
        () => ExternalNav.wazeUri(ungeocoded),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
