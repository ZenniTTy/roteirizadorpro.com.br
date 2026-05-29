import 'stop.dart';

/// Status of a route in its lifecycle.
enum RouteStatus { draft, optimized, running, completed }

/// Canonical top→bottom order matches the drawer bucket display order
/// (Spoke parity per inventory §11.6 revised 2026-05-27).
enum RoutePeriod { upcoming, today, thisWeek, thisMonth }

class Route {
  const Route({
    required this.id,
    required this.date,
    required this.status,
    this.name,
    this.stops = const [],
  });
  final String id;
  final DateTime date;
  final RouteStatus status;
  final String? name;
  final List<Stop> stops;

  /// Display label for the route row.
  /// If [name] was provided, use it; otherwise fall back to the weekday in
  /// Portuguese, lowercase, matching Spoke's auto-naming pattern observed in
  /// inventory §10.1 ("terça-feira", "quarta-feira", …).
  String displayName() => name ?? _weekdayPtBr(date);

  Route copyWith({
    String? id,
    DateTime? date,
    RouteStatus? status,
    String? name,
    List<Stop>? stops,
  }) {
    return Route(
      id: id ?? this.id,
      date: date ?? this.date,
      status: status ?? this.status,
      name: name ?? this.name,
      stops: stops ?? this.stops,
    );
  }
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
