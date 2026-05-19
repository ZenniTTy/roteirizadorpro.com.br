import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/stops/domain/stop.dart';

part 'external_nav.g.dart';

/// Per ADR-0017, the Google Maps Maps-URLs path omits the `origin`
/// parameter so the Maps app uses the device's current location. That
/// gives a per-URI cap of 9 waypoints + 1 destination = 10 stops.
/// Routes longer than 10 stops are split via [googleMapsUriChunks].
///
/// Source: https://developers.google.com/maps/documentation/urls/get-started
const int kGoogleMapsMaxStopsPerUri = 10;

enum NavProvider { waze, googleMaps }

abstract class ExternalNav {
  /// Builds a single Google Maps Directions URI from up to
  /// [kGoogleMapsMaxStopsPerUri] stops. Throws [ArgumentError] if [stops]
  /// is empty or exceeds the cap; callers with longer routes should use
  /// [googleMapsUriChunks] instead.
  static Uri googleMapsUri(List<Stop> stops) {
    if (stops.isEmpty) {
      throw ArgumentError('stops must not be empty');
    }
    if (stops.length > kGoogleMapsMaxStopsPerUri) {
      throw ArgumentError(
        'stops.length (${stops.length}) exceeds Google Maps single-URI cap '
        'of $kGoogleMapsMaxStopsPerUri; use googleMapsUriChunks instead',
      );
    }
    final destination = stops.last;
    final waypoints = stops.length > 1
        ? stops
            .sublist(0, stops.length - 1)
            .map((s) => '${s.lat},${s.lng}')
            .join('|')
        : null;
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${destination.lat},${destination.lng}',
      if (waypoints != null) 'waypoints': waypoints,
      'travelmode': 'driving',
    });
  }

  /// Splits [stops] into one or more Google Maps Directions URIs, each
  /// holding at most [kGoogleMapsMaxStopsPerUri] stops. The caller fires
  /// the next chunk after the rider completes the previous one.
  static List<Uri> googleMapsUriChunks(List<Stop> stops) {
    if (stops.isEmpty) {
      throw ArgumentError('stops must not be empty');
    }
    final chunks = <Uri>[];
    for (var i = 0; i < stops.length; i += kGoogleMapsMaxStopsPerUri) {
      final end = (i + kGoogleMapsMaxStopsPerUri) > stops.length
          ? stops.length
          : i + kGoogleMapsMaxStopsPerUri;
      chunks.add(googleMapsUri(stops.sublist(i, end)));
    }
    return chunks;
  }

  /// Builds a single Waze deep-link URI for one stop. Waze has no
  /// multi-stop URL variant; the caller drives the parada-por-parada
  /// flow per ADR-0017.
  ///
  /// Throws [ArgumentError] for ungeocoded stops (Null Island sentinel
  /// `lat=0, lng=0`) since opening Waze to the Atlantic Ocean is never
  /// the intended behavior.
  static Uri wazeUri(Stop stop) {
    if (!stop.isGeocoded) {
      throw ArgumentError(
        'stop ${stop.id} is ungeocoded (Null Island sentinel); '
        'cannot build a Waze URI',
      );
    }
    return Uri(
      scheme: 'waze',
      queryParameters: {
        'll': '${stop.lat},${stop.lng}',
        'navigate': 'yes',
      },
    );
  }

  Future<bool> openInGoogleMaps(List<Stop> stops);
  Future<bool> openInWaze(Stop stop);
}

class _RealExternalNav implements ExternalNav {
  @override
  Future<bool> openInGoogleMaps(List<Stop> stops) {
    final uri = ExternalNav.googleMapsUri(stops);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Future<bool> openInWaze(Stop stop) {
    final uri = ExternalNav.wazeUri(stop);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

@riverpod
ExternalNav externalNav(Ref ref) => _RealExternalNav();
