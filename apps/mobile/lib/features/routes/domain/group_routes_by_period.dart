import 'package:flutter/foundation.dart';

import 'route.dart';

/// Groups [routes] into period buckets relative to [now].
///
/// Rules (per spec 2026-05-27 + inventory §11.6 revised):
/// - Week starts on Monday (PT-BR convention).
/// - upcoming  : route.date > today
/// - today     : route.date == today
/// - thisWeek  : monday(now) <= route.date < today
/// - thisMonth : same year & month as now AND route.date < monday(now)
/// - Older routes are discarded (Slice 2 scope; pagination is Slice 3).
/// - Each returned bucket list is sorted descending by date (newest first).
/// - Empty buckets are omitted from the result map.
/// - Iteration order of the result follows [RoutePeriod] enum order
///   (upcoming → today → thisWeek → thisMonth).
Map<RoutePeriod, List<Route>> groupRoutesByPeriod(
  List<Route> routes,
  DateTime now,
) {
  final today = DateTime(now.year, now.month, now.day);
  // weekday: Mon=1 … Sun=7. Monday of current week:
  final monday = today.subtract(Duration(days: today.weekday - 1));

  final buckets = <RoutePeriod, List<Route>>{
    RoutePeriod.upcoming: <Route>[],
    RoutePeriod.today: <Route>[],
    RoutePeriod.thisWeek: <Route>[],
    RoutePeriod.thisMonth: <Route>[],
  };

  for (final r in routes) {
    final d = DateTime(r.date.year, r.date.month, r.date.day);
    if (d.isAfter(today)) {
      buckets[RoutePeriod.upcoming]!.add(r);
    } else if (d.isAtSameMomentAs(today)) {
      buckets[RoutePeriod.today]!.add(r);
    } else if (!d.isBefore(monday)) {
      // monday <= d < today
      buckets[RoutePeriod.thisWeek]!.add(r);
    } else if (d.year == today.year && d.month == today.month) {
      // same month, before this week's Monday
      buckets[RoutePeriod.thisMonth]!.add(r);
    }
    // else: older than current month → discarded.
  }

  // Sort descending by date inside each bucket, and drop empty buckets while
  // preserving canonical enum order.
  final out = <RoutePeriod, List<Route>>{};
  var bucketedCount = 0;
  for (final period in RoutePeriod.values) {
    final list = buckets[period]!;
    bucketedCount += list.length;
    if (list.isEmpty) continue;
    list.sort((a, b) => b.date.compareTo(a.date));
    out[period] = list;
  }
  // Surface silently-dropped rows in debug builds so Slice 3's CRUD work
  // doesn't accidentally hide history beyond the current month.
  if (kDebugMode && bucketedCount != routes.length) {
    debugPrint(
      '[groupRoutesByPeriod] dropped ${routes.length - bucketedCount} route(s) '
      'older than current month (Slice 2 scope — pagination is Slice 3).',
    );
  }
  return out;
}
