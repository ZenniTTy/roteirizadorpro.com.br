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

/// Where the route ends. Three Spoke-canonical variants, mapping 1:1 onto the
/// three cards in Spoke's Destino bottom sheet (ADR-0043): [RoundTrip]
/// ("Voltar ao ponto de partida"), [SpecificAddress] ("Destino em outro
/// endereço"), and [NoDestination] ("Não usar destino").
sealed class Destination extends RouteConfigPart {
  const Destination();
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

/// Solver may revisit the start mid-route ("ida e volta"). Spoke's
/// brand-new-route default and the [RouteConfig.empty] bootstrap value.
final class RoundTrip extends Destination {
  const RoundTrip();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RoundTrip;

  @override
  int get hashCode => (RoundTrip).hashCode;
}

/// No destination — the route ends wherever the last stop is ("Não usar
/// destino" in Spoke; "Nenhum destino" in the parent Detalhes row). Carries
/// no payload.
final class NoDestination extends Destination {
  const NoDestination();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NoDestination;

  @override
  int get hashCode => (NoDestination).hashCode;
}

/// Named `BreakConfig` (not `Break`) — `break` is a reserved keyword.
///
/// Spoke models a break as a time WINDOW (live capture 2026-06-09, ADR-0044):
/// "take a [durationMinutes]-minute break sometime between [fromTime] and
/// [toTime]". The solver places the actual break inside that window. The
/// Spoke defaults are 08:00–15:00 / 30 min. This is NOT a single fixed start
/// time — that was an un-drilled inference the live "Configure a pausa" page
/// corrected (inventory §16 had it marked "Não drilled").
final class BreakConfig extends RouteConfigPart {
  const BreakConfig({
    required this.fromTime,
    required this.toTime,
    required this.durationMinutes,
  });

  /// Earliest the break may start ("Entre" field; Spoke default 08:00).
  final TimeOfDay fromTime;

  /// Latest the break may start ("E" field; Spoke default 15:00).
  final TimeOfDay toTime;

  /// Break length in minutes (free integer; Spoke default 30).
  final int durationMinutes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BreakConfig &&
          other.fromTime == fromTime &&
          other.toTime == toTime &&
          other.durationMinutes == durationMinutes;

  @override
  int get hashCode => Object.hash(fromTime, toTime, durationMinutes);
}

/// Result the "Configure a pausa" page pops (ADR-0049). Mirrors Spoke's
/// `BreakSetupResult` sealed family (`BreakChanged` / `BreakRemoved`,
/// `~/spoke-dump/.../breaks/BreakSetupResult.java`): a single typed return that
/// distinguishes "save this break" from "remove this break", so the parent can
/// route to `addBreak` / `updateBreak` / `removeBreak` without a second channel.
/// A `null` pop (system back / `←`) means "cancel — leave the break list
/// untouched", as before.
sealed class BreakSchedulerResult {
  const BreakSchedulerResult();
}

/// The user confirmed a break (add OR edit) — apply [config]. In add mode the
/// parent appends it; in edit mode the parent replaces the break at its index.
final class BreakSaved extends BreakSchedulerResult {
  const BreakSaved(this.config);
  final BreakConfig config;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BreakSaved && other.config == config;

  @override
  int get hashCode => config.hashCode;
}

/// The user removed the break being edited (Spoke's "Remover pausa" →
/// `BreakRemoved`). Only reachable in edit mode; the parent drops the break at
/// its index. Carries no payload — the index is owned by the call site.
final class BreakRemoved extends BreakSchedulerResult {
  const BreakRemoved();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BreakRemoved;

  @override
  int get hashCode => (BreakRemoved).hashCode;
}

/// Aggregate of one route's user-configurable state.
///
/// All sub-states except [breaks] and [destination] are nullable to model
/// "not yet set". [destination] is nullable so [withDestination] can clear it
/// explicitly, but the bootstrap [RouteConfig.empty] ships
/// `destination: const RoundTrip()` because Spoke's brand-new-route default is
/// "Ida e volta" — the domain encodes that contract directly, instead of
/// letting the presentation layer mask null. Use the per-field `with*`
/// updaters to mutate — they accept `null` explicitly to clear, side-stepping
/// the [copyWith] nullable-pitfall.
class RouteConfig {
  const RouteConfig({
    this.startLocation,
    this.timeStart,
    this.timeEnd,
    this.destination,
    this.breaks = const [],
  });

  /// Bootstrap value: only [destination] pre-populated to Spoke's default
  /// ("Ida e volta"); every other field unset; no breaks.
  factory RouteConfig.empty() => const RouteConfig(destination: RoundTrip());

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
