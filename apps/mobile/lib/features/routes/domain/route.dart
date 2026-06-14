import 'route_state.dart';
import 'stop.dart';

/// Canonical top→bottom order matches the drawer bucket display order
/// (Spoke parity per inventory §11.6 revised 2026-05-27).
enum RoutePeriod { upcoming, today, thisWeek, thisMonth }

class Route {
  const Route({
    required this.id,
    required this.date,
    this.routeState = const RouteState(),
    this.name,
    this.stops = const [],
    this.totalDurationMinutes,
    this.totalDistanceMeters,
  });
  final String id;
  final DateTime date;
  final RouteState routeState;
  final String? name;
  final List<Stop> stops;

  /// Métricas da última otimização bem-sucedida (alimentam a linha summary do
  /// PRE-CONFIRM). Nulas até otimizar; zeradas ao invalidar (estado editing).
  final int? totalDurationMinutes;
  final double? totalDistanceMeters;

  /// Display label for the route row.
  /// If [name] was provided, use it; otherwise fall back to the weekday in
  /// Portuguese, lowercase, matching Spoke's auto-naming pattern observed in
  /// inventory §10.1 ("terça-feira", "quarta-feira", …).
  String displayName() => name ?? _weekdayPtBr(date);

  Route copyWith({
    String? id,
    DateTime? date,
    RouteState? routeState,
    String? name,
    List<Stop>? stops,
    Object? totalDurationMinutes = _omit,
    Object? totalDistanceMeters = _omit,
  }) {
    return Route(
      id: id ?? this.id,
      date: date ?? this.date,
      routeState: routeState ?? this.routeState,
      name: name ?? this.name,
      stops: stops ?? this.stops,
      totalDurationMinutes: identical(totalDurationMinutes, _omit)
          ? this.totalDurationMinutes
          : totalDurationMinutes as int?,
      totalDistanceMeters: identical(totalDistanceMeters, _omit)
          ? this.totalDistanceMeters
          : (totalDistanceMeters as num?)?.toDouble(),
    );
  }

  static const _omit = Object();
}

const _kWeekdayPtBr = <String>[
  '', // index 0 unused
  'segunda-feira',
  'terça-feira',
  'quarta-feira',
  'quinta-feira',
  'sexta-feira',
  'sábado',
  'domingo',
];

String _weekdayPtBr(DateTime d) => _kWeekdayPtBr[d.weekday];
