import 'package:flutter/material.dart' show TimeOfDay;

import 'route_config.dart';

/// JSON envelope persisted under a single `SharedPreferencesAsync` key.
///
/// Field names mirror the future Slice 3 TypeBox schema (camelCase) so a
/// later backend migration can lift the same shape onto the wire without
/// renames.
///
/// Forward-compat strategy: any parse error — missing/wrong-type
/// `schemaVersion`, unknown destination type, malformed time string — falls
/// back to [RouteDefaults.empty]. We never throw at deserialization time;
/// the worst outcome is the user sees the FTUE flow again.
class RouteDefaults {
  const RouteDefaults({
    this.schemaVersion = 1,
    this.firstRoute = true,
    this.startLocation,
    this.timeStart,
    this.timeEnd,
    this.destination,
    this.breaks = const [],
  });

  /// Bootstrap envelope written on first launch.
  factory RouteDefaults.empty() => const RouteDefaults();

  final int schemaVersion;
  final bool firstRoute;
  final StartLocation? startLocation;
  final TimeStart? timeStart;
  final TimeEnd? timeEnd;
  final Destination? destination;
  final List<BreakConfig> breaks;

  static const int _currentSchemaVersion = 1;

  /// Parses [json] into a [RouteDefaults]. Returns [RouteDefaults.empty] on
  /// any structural or value error; never throws.
  factory RouteDefaults.fromJson(Map<String, dynamic> json) {
    try {
      final version = json['schemaVersion'];
      if (version is! int || version != _currentSchemaVersion) {
        return RouteDefaults.empty();
      }
      final firstRoute = json['firstRoute'];
      if (firstRoute is! bool) return RouteDefaults.empty();

      final startLocation = _startLocationFromJson(json['startLocation']);
      final timeStart = _timeStartFromJson(json['timeStart']);
      final timeEnd = _timeEndFromJson(json['timeEnd']);
      final destination = _destinationFromJson(json['destination']);
      final breaks = _breaksFromJson(json['breaks']);

      return RouteDefaults(
        firstRoute: firstRoute,
        startLocation: startLocation,
        timeStart: timeStart,
        timeEnd: timeEnd,
        destination: destination,
        breaks: breaks,
      );
    } catch (_) {
      return RouteDefaults.empty();
    }
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'firstRoute': firstRoute,
        'startLocation': _startLocationToJson(startLocation),
        'timeStart': _timeOfDayToJson(timeStart?.time),
        'timeEnd': _timeOfDayToJson(timeEnd?.time),
        'destination': _destinationToJson(destination),
        'breaks': breaks
            .map(
              (b) => {
                'startTime': _timeOfDayToJson(b.startTime),
                'durationMinutes': b.durationMinutes,
              },
            )
            .toList(),
      };

  /// Build a new envelope overriding only the listed fields.
  /// Nullable fields use sentinel-via-Object.is to distinguish "omit" from
  /// "set to null" — important so callers can clear, mirroring [RouteConfig]
  /// updaters.
  RouteDefaults copyWith({
    int? schemaVersion,
    bool? firstRoute,
    Object? startLocation = _omit,
    Object? timeStart = _omit,
    Object? timeEnd = _omit,
    Object? destination = _omit,
    List<BreakConfig>? breaks,
  }) {
    return RouteDefaults(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      firstRoute: firstRoute ?? this.firstRoute,
      startLocation: identical(startLocation, _omit)
          ? this.startLocation
          : startLocation as StartLocation?,
      timeStart: identical(timeStart, _omit)
          ? this.timeStart
          : timeStart as TimeStart?,
      timeEnd: identical(timeEnd, _omit) ? this.timeEnd : timeEnd as TimeEnd?,
      destination: identical(destination, _omit)
          ? this.destination
          : destination as Destination?,
      breaks: breaks ?? this.breaks,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RouteDefaults) return false;
    if (other.schemaVersion != schemaVersion) return false;
    if (other.firstRoute != firstRoute) return false;
    if (other.startLocation != startLocation) return false;
    if (other.timeStart != timeStart) return false;
    if (other.timeEnd != timeEnd) return false;
    if (other.destination != destination) return false;
    if (other.breaks.length != breaks.length) return false;
    for (var i = 0; i < breaks.length; i++) {
      if (other.breaks[i] != breaks[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        schemaVersion,
        firstRoute,
        startLocation,
        timeStart,
        timeEnd,
        destination,
        Object.hashAll(breaks),
      );
}

/// Sentinel for [RouteDefaults.copyWith] nullable-field detection. Never
/// exposed; private to this library.
const Object _omit = Object();

// -- private serialization helpers ------------------------------------------

String? _timeOfDayToJson(TimeOfDay? t) {
  if (t == null) return null;
  final hh = t.hour.toString().padLeft(2, '0');
  final mm = t.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

TimeOfDay _timeOfDayFromString(String s) {
  final parts = s.split(':');
  if (parts.length != 2) throw const FormatException('bad time');
  final h = int.parse(parts[0]);
  final m = int.parse(parts[1]);
  if (h < 0 || h > 23 || m < 0 || m > 59) {
    throw const FormatException('out of range');
  }
  return TimeOfDay(hour: h, minute: m);
}

Map<String, dynamic>? _startLocationToJson(StartLocation? s) {
  if (s == null) return null;
  return {
    'address': s.address,
    'lat': s.lat,
    'lng': s.lng,
    'isUserCurrentLocation': s.isUserCurrentLocation,
  };
}

StartLocation? _startLocationFromJson(Object? raw) {
  if (raw == null) return null;
  if (raw is! Map<String, dynamic>) {
    throw const FormatException('startLocation not a map');
  }
  return StartLocation(
    address: raw['address'] as String,
    lat: (raw['lat'] as num).toDouble(),
    lng: (raw['lng'] as num).toDouble(),
    isUserCurrentLocation: raw['isUserCurrentLocation'] as bool,
  );
}

TimeStart? _timeStartFromJson(Object? raw) {
  if (raw == null) return null;
  if (raw is! String) throw const FormatException('timeStart not a string');
  return TimeStart(time: _timeOfDayFromString(raw));
}

TimeEnd? _timeEndFromJson(Object? raw) {
  if (raw == null) return null;
  if (raw is! String) throw const FormatException('timeEnd not a string');
  return TimeEnd(time: _timeOfDayFromString(raw));
}

Map<String, dynamic>? _destinationToJson(Destination? d) {
  return switch (d) {
    null => null,
    BackToStart() => {'type': 'backToStart'},
    SpecificAddress(:final address, :final lat, :final lng) => {
        'type': 'specificAddress',
        'address': address,
        'lat': lat,
        'lng': lng,
      },
    RoundTrip() => {'type': 'roundTrip'},
  };
}

Destination? _destinationFromJson(Object? raw) {
  if (raw == null) return null;
  if (raw is! Map<String, dynamic>) {
    throw const FormatException('destination not a map');
  }
  final type = raw['type'];
  return switch (type) {
    'backToStart' => const BackToStart(),
    'specificAddress' => SpecificAddress(
        address: raw['address'] as String,
        lat: (raw['lat'] as num).toDouble(),
        lng: (raw['lng'] as num).toDouble(),
      ),
    'roundTrip' => const RoundTrip(),
    _ => throw const FormatException('unknown destination type'),
  };
}

List<BreakConfig> _breaksFromJson(Object? raw) {
  if (raw == null) return const [];
  if (raw is! List) throw const FormatException('breaks not a list');
  return raw.map((e) {
    if (e is! Map<String, dynamic>) {
      throw const FormatException('break entry not a map');
    }
    final startTime = e['startTime'];
    final durationMinutes = e['durationMinutes'];
    if (startTime is! String || durationMinutes is! int) {
      throw const FormatException('break entry bad shape');
    }
    return BreakConfig(
      startTime: _timeOfDayFromString(startTime),
      durationMinutes: durationMinutes,
    );
  }).toList(growable: false);
}
