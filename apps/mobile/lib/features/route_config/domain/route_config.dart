import 'package:flutter/material.dart' show TimeOfDay;

/// Configurable pieces of a route, modelled as a sealed family so a
/// `switch` over the type list is exhaustive at compile time.
///
/// Top-level [RouteConfig] aggregates the optional sub-states; mutate it via
/// the explicit `with*` updaters (NOT `copyWith`), because the project's
/// `copyWith(field: x ?? this.field)` idiom silently preserves nullable
/// fields when the caller explicitly passes `null` to clear them
/// (lesson `copyWith_nullable_field_pitfall`).
sealed class RouteConfigPart {
  const RouteConfigPart();
}

/// Where the route begins. `isUserCurrentLocation` records whether the value
/// was filled from the device's current GPS fix (rendered as "Usar local
/// atual" in Spoke) or from an explicit address selection.
final class StartLocation extends RouteConfigPart {
  const StartLocation({
    required this.address,
    required this.lat,
    required this.lng,
    required this.isUserCurrentLocation,
  });

  final String address;
  final double lat;
  final double lng;
  final bool isUserCurrentLocation;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StartLocation &&
          other.address == address &&
          other.lat == lat &&
          other.lng == lng &&
          other.isUserCurrentLocation == isUserCurrentLocation;

  @override
  int get hashCode => Object.hash(address, lat, lng, isUserCurrentLocation);
}

/// Wraps a [TimeOfDay] in a distinct nominal type so a [TimeStart] cannot be
/// passed where a [TimeEnd] is expected, even though both carry the same
/// payload shape.
final class TimeStart extends RouteConfigPart {
  const TimeStart({required this.time});
  final TimeOfDay time;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TimeStart && other.time == time;

  @override
  int get hashCode => time.hashCode;
}

final class TimeEnd extends RouteConfigPart {
  const TimeEnd({required this.time});
  final TimeOfDay time;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TimeEnd && other.time == time;

  @override
  int get hashCode => time.hashCode;
}

/// Where the route ends. Three Spoke-canonical variants.
sealed class Destination extends RouteConfigPart {
  const Destination();
}

/// Loop back to whatever [StartLocation] resolved to at run time.
final class BackToStart extends Destination {
  const BackToStart();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BackToStart;

  @override
  int get hashCode => (BackToStart).hashCode;
}

/// End at an explicit address distinct from the start.
final class SpecificAddress extends Destination {
  const SpecificAddress({
    required this.address,
    required this.lat,
    required this.lng,
  });

  final String address;
  final double lat;
  final double lng;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpecificAddress &&
          other.address == address &&
          other.lat == lat &&
          other.lng == lng;

  @override
  int get hashCode => Object.hash(address, lat, lng);
}

/// Solver may revisit the start mid-route ("ida e volta").
final class RoundTrip extends Destination {
  const RoundTrip();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RoundTrip;

  @override
  int get hashCode => (RoundTrip).hashCode;
}

/// Named `BreakConfig` (not `Break`) — `break` is a reserved keyword.
final class BreakConfig extends RouteConfigPart {
  const BreakConfig({
    required this.startTime,
    required this.durationMinutes,
  });

  final TimeOfDay startTime;
  final int durationMinutes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BreakConfig &&
          other.startTime == startTime &&
          other.durationMinutes == durationMinutes;

  @override
  int get hashCode => Object.hash(startTime, durationMinutes);
}

/// Aggregate of one route's user-configurable state.
///
/// All sub-states except [breaks] are nullable to model "not yet set". Use the
/// per-field `with*` updaters to mutate — they accept `null` explicitly to
/// clear, side-stepping the [copyWith] nullable-pitfall.
class RouteConfig {
  const RouteConfig({
    this.startLocation,
    this.timeStart,
    this.timeEnd,
    this.destination,
    this.breaks = const [],
  });

  /// Bootstrap value: nothing configured, no breaks.
  factory RouteConfig.empty() => const RouteConfig();

  final StartLocation? startLocation;
  final TimeStart? timeStart;
  final TimeEnd? timeEnd;
  final Destination? destination;
  final List<BreakConfig> breaks;

  /// True when both times are set AND `timeEnd` strictly after `timeStart`.
  /// Equal times count as invalid — a zero-length window is meaningless.
  bool get isValid {
    final s = timeStart;
    final e = timeEnd;
    if (s == null || e == null) return false;
    final startMin = s.time.hour * 60 + s.time.minute;
    final endMin = e.time.hour * 60 + e.time.minute;
    return endMin > startMin;
  }

  RouteConfig withStartLocation(StartLocation? value) => RouteConfig(
        startLocation: value,
        timeStart: timeStart,
        timeEnd: timeEnd,
        destination: destination,
        breaks: breaks,
      );

  RouteConfig withTimeStart(TimeStart? value) => RouteConfig(
        startLocation: startLocation,
        timeStart: value,
        timeEnd: timeEnd,
        destination: destination,
        breaks: breaks,
      );

  RouteConfig withTimeEnd(TimeEnd? value) => RouteConfig(
        startLocation: startLocation,
        timeStart: timeStart,
        timeEnd: value,
        destination: destination,
        breaks: breaks,
      );

  RouteConfig withDestination(Destination? value) => RouteConfig(
        startLocation: startLocation,
        timeStart: timeStart,
        timeEnd: timeEnd,
        destination: value,
        breaks: breaks,
      );

  RouteConfig withBreaks(List<BreakConfig> value) => RouteConfig(
        startLocation: startLocation,
        timeStart: timeStart,
        timeEnd: timeEnd,
        destination: destination,
        breaks: List.unmodifiable(value),
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RouteConfig) return false;
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
        startLocation,
        timeStart,
        timeEnd,
        destination,
        Object.hashAll(breaks),
      );
}
