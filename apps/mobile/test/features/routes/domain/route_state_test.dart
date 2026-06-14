// test/features/routes/domain/route_state_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/domain/optimization_state.dart';
import 'package:roteirizador_pro/features/routes/domain/route_state.dart';

void main() {
  test('default = DRAFT (creating, nada otimizado/confirmado/iniciado)', () {
    const s = RouteState();
    expect(s.optimization, OptimizationState.creating);
    expect(s.isDraft, isTrue);
    expect(s.isPreConfirm, isFalse);
    expect(s.isReadyToRun, isFalse);
    expect(s.isOptimizing, isFalse);
  });

  test('optimizing=true => isOptimizing (tela de progresso)', () {
    const s = RouteState(optimizing: true);
    expect(s.isOptimizing, isTrue);
    expect(s.isDraft, isFalse);
  });

  test('optimized && !confirmed => PRE-CONFIRM', () {
    const s = RouteState(optimization: OptimizationState.optimized);
    expect(s.isPreConfirm, isTrue);
    expect(s.isReadyToRun, isFalse);
  });

  test('optimized && confirmed && !started => READY-TO-RUN', () {
    const s = RouteState(
      optimization: OptimizationState.optimized,
      confirmed: true,
    );
    expect(s.isReadyToRun, isTrue);
    expect(s.isPreConfirm, isFalse);
  });

  test('editing (após mexer em rota otimizada) é distinto e zera otimização',
      () {
    const s = RouteState(optimization: OptimizationState.editing);
    expect(s.isEditing, isTrue);
    expect(s.isPreConfirm, isFalse);
    expect(s.isReadyToRun, isFalse);
  });

  test('optimizationErroredAt sem optimizing => hasOptimizationError', () {
    final s = RouteState(optimizationErroredAt: DateTime(2026, 6, 13));
    expect(s.hasOptimizationError, isTrue);
  });

  test('copyWith preserva campos omitidos e troca os passados', () {
    const base = RouteState();
    final next = base.copyWith(
      optimization: OptimizationState.optimized,
      confirmed: true,
    );
    expect(next.optimization, OptimizationState.optimized);
    expect(next.confirmed, isTrue);
    expect(next.started, isFalse); // omitido => preservado
  });
}
