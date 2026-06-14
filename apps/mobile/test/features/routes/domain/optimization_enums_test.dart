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

  test('OptimizeType cobre os modos do Spoke usados na Á7', () {
    expect(
      OptimizeType.values,
      containsAll([
        OptimizeType.restartRoute,
        OptimizeType.reorderFlexible,
        OptimizeType.skipReorder,
      ]),
    );
  });

  test('OptimizeDirection tem reverse (Inverter a rota)', () {
    expect(OptimizeDirection.values, [OptimizeDirection.reverse]);
  });
}
