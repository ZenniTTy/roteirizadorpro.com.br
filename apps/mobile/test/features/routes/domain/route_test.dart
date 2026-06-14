// test/features/routes/domain/route_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/domain/optimization_state.dart';
import 'package:roteirizador_pro/features/routes/domain/route.dart';
import 'package:roteirizador_pro/features/routes/domain/route_state.dart';

void main() {
  test('Route default nasce DRAFT com métricas nulas', () {
    final r = Route(id: 'r1', date: DateTime(2026, 6, 13));
    expect(r.routeState.isDraft, isTrue);
    expect(r.totalDurationMinutes, isNull);
    expect(r.totalDistanceMeters, isNull);
  });

  test('copyWith troca routeState e métricas, preserva o resto', () {
    final r = Route(id: 'r1', date: DateTime(2026, 6, 13), name: 'Segunda');
    final next = r.copyWith(
      routeState: const RouteState(optimization: OptimizationState.optimized),
      totalDurationMinutes: 18,
      totalDistanceMeters: 5200,
    );
    expect(next.routeState.isPreConfirm, isTrue);
    expect(next.totalDurationMinutes, 18);
    expect(next.totalDistanceMeters, 5200);
    expect(next.name, 'Segunda'); // preservado
  });
}
