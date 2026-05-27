import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/domain/group_routes_by_period.dart';
import 'package:roteirizador_pro/features/routes/domain/route.dart' as domain;

void main() {
  // Anchor: Wednesday 2026-05-27.
  // Week (Mon–Wed): 2026-05-25, 2026-05-26, 2026-05-27.
  // thisMonth but before this week: 2026-05-01 … 2026-05-24.
  // Sunday of LAST week (PT-BR edge case): 2026-05-24 is a Sunday —
  //   Monday of the current week is 2026-05-25, so 2026-05-24 < monday → thisMonth.
  final kNow = DateTime(2026, 5, 27); // Wednesday

  domain.Route r(String id, DateTime date) => domain.Route(
        id: id,
        date: date,
        status: domain.RouteStatus.draft,
      );

  test('empty list returns empty map', () {
    final result = groupRoutesByPeriod([], kNow);
    expect(result, isEmpty);
  });

  test('routes only on today go into today bucket', () {
    final routes = [
      r('a', DateTime(2026, 5, 27)),
      r('b', DateTime(2026, 5, 27)),
    ];
    final result = groupRoutesByPeriod(routes, kNow);

    expect(result.keys, equals([domain.RoutePeriod.today]));
    expect(result[domain.RoutePeriod.today]!.map((e) => e.id), ['a', 'b']);
  });

  test('four buckets in canonical enum order with correct membership', () {
    final routes = [
      // upcoming — 2026-05-28 (Thursday, tomorrow)
      r('upcoming1', DateTime(2026, 5, 28)),
      // today
      r('today1', DateTime(2026, 5, 27)),
      // thisWeek — 2026-05-25 (Monday this week) and 2026-05-26 (Tuesday)
      r('week1', DateTime(2026, 5, 26)),
      r('week2', DateTime(2026, 5, 25)),
      // thisMonth but before this week — 2026-05-18
      r('month1', DateTime(2026, 5, 18)),
    ];

    final result = groupRoutesByPeriod(routes, kNow);

    // Canonical order: upcoming, today, thisWeek, thisMonth
    expect(
      result.keys.toList(),
      equals([
        domain.RoutePeriod.upcoming,
        domain.RoutePeriod.today,
        domain.RoutePeriod.thisWeek,
        domain.RoutePeriod.thisMonth,
      ]),
    );
    expect(
      result[domain.RoutePeriod.upcoming]!.map((e) => e.id),
      ['upcoming1'],
    );
    expect(result[domain.RoutePeriod.today]!.map((e) => e.id), ['today1']);
    // Descending inside bucket: 26 before 25
    expect(
      result[domain.RoutePeriod.thisWeek]!.map((e) => e.id),
      ['week1', 'week2'],
    );
    expect(result[domain.RoutePeriod.thisMonth]!.map((e) => e.id), ['month1']);
  });

  test('sort within bucket is descending by date', () {
    final routes = [
      r('old', DateTime(2026, 5, 25)), // Monday
      r('new', DateTime(2026, 5, 26)), // Tuesday
    ];
    final result = groupRoutesByPeriod(routes, kNow);
    final ids = result[domain.RoutePeriod.thisWeek]!.map((e) => e.id).toList();
    expect(ids, ['new', 'old']); // newer first
  });

  test('empty buckets are omitted from the map', () {
    // Only a future route — today, thisWeek, thisMonth buckets must be absent.
    final routes = [r('f', DateTime(2026, 5, 30))];
    final result = groupRoutesByPeriod(routes, kNow);

    expect(result.containsKey(domain.RoutePeriod.today), isFalse);
    expect(result.containsKey(domain.RoutePeriod.thisWeek), isFalse);
    expect(result.containsKey(domain.RoutePeriod.thisMonth), isFalse);
    expect(result[domain.RoutePeriod.upcoming]!.map((e) => e.id), ['f']);
  });

  test(
      'PT-BR edge case: Sunday of last week is NOT thisWeek, goes to thisMonth',
      () {
    // 2026-05-24 is Sunday. Monday of current week is 2026-05-25.
    // So 2026-05-24 < monday → thisMonth, NOT thisWeek.
    final routes = [r('sunday', DateTime(2026, 5, 24))];
    final result = groupRoutesByPeriod(routes, kNow);

    expect(result.containsKey(domain.RoutePeriod.thisWeek), isFalse);
    expect(result[domain.RoutePeriod.thisMonth]!.map((e) => e.id), ['sunday']);
  });

  test('routes older than current month are discarded', () {
    final routes = [
      r('old', DateTime(2026, 4, 15)), // April — prior month
      r('today', DateTime(2026, 5, 27)),
    ];
    final result = groupRoutesByPeriod(routes, kNow);

    // Only today bucket — April route discarded.
    expect(result.keys, equals([domain.RoutePeriod.today]));
    expect(result[domain.RoutePeriod.today]!.map((e) => e.id), ['today']);
  });
}
