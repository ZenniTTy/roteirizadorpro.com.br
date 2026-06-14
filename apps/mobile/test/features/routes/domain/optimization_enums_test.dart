// test/features/routes/domain/optimization_enums_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/domain/optimization_state.dart';
import 'package:roteirizador_pro/features/routes/domain/optimize_type.dart';
import 'package:roteirizador_pro/features/routes/domain/optimize_direction.dart';

void main() {
  test(
      'OptimizationState espelha o Spoke (3 valores, ordem CREATING/OPTIMIZED/EDITING)',
      () {
    expect(OptimizationState.values, [
      OptimizationState.creating,
      OptimizationState.optimized,
      OptimizationState.editing,
    ]);
  });

  test(
      'OptimizeType espelha o Spoke VERBATIM (4 valores, ordem do dump: '
      'RESTART_ROUTE/REMAINING_STOPS/SKIP_REORDER/REORDER_FLEXIBLE)', () {
    // Lista EXATA (não containsAll): o dump (core/entity/OptimizeType.java) tem
    // 4 valores nesta ordem; REMAINING_STOPS (OrderStopGroups, PR-D) é fácil de
    // esquecer — pinar a lista impede a omissão.
    expect(OptimizeType.values, [
      OptimizeType.restartRoute,
      OptimizeType.remainingStops,
      OptimizeType.skipReorder,
      OptimizeType.reorderFlexible,
    ]);
  });

  test('OptimizeDirection tem reverse (Inverter a rota)', () {
    expect(OptimizeDirection.values, [OptimizeDirection.reverse]);
  });
}
