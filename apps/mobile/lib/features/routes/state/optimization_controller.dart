import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/optimize_direction.dart';
import '../domain/optimize_type.dart';
import '../domain/optimization/local_route_optimizer.dart';
import '../domain/optimization/route_optimizer.dart';
import '../domain/stop.dart';

part 'optimization_controller.g.dart';

/// Binding do solver. Slice 2 = LocalRouteOptimizer (on-device). Slice 3
/// sobrescreve este provider por um GraphHopperRouteOptimizer sem tocar a UI.
@Riverpod(keepAlive: true)
RouteOptimizer routeOptimizer(Ref ref) => LocalRouteOptimizer();

/// Resultado de uma tentativa de otimização. Sealed — a UI faz switch
/// exaustivo sem default.
sealed class OptimizationOutcome {
  const OptimizationOutcome();
}

class NotEnoughStops extends OptimizationOutcome {
  const NotEnoughStops();
}

class OptimizationSuccess extends OptimizationOutcome {
  const OptimizationSuccess(this.result);
  final RouteOptimizationResult result;
}

class OptimizationFailure extends OptimizationOutcome {
  const OptimizationFailure();
}

@riverpod
class OptimizationController extends _$OptimizationController {
  @override
  OptimizationPhase? build() => null;

  static const int minStops = 1;

  Future<OptimizationOutcome> optimize({
    required GeoPoint start,
    GeoPoint? end,
    required List<Stop> stops,
    required OptimizeType type,
    OptimizeDirection? direction,
  }) async {
    final optimizable = stops.where((s) => !s.pendingRemoval).length;
    if (optimizable < minStops) {
      return const NotEnoughStops(); // G1 — solver não roda
    }

    try {
      state = OptimizationPhase.analysing;
      final optimizer = ref.read(routeOptimizerProvider);
      // As fases são visuais; o solver on-device é síncrono e rápido. O avanço
      // escalonado das 4 fases na UI é refinado no PR-B (PRE-CONFIRM); aqui o
      // controller só marca que está otimizando e volta a ocioso ao concluir.
      final result = optimizer.optimize(
        start: start,
        end: end,
        stops: stops,
        type: type,
        direction: direction,
      );
      state = null;
      return OptimizationSuccess(result);
    } catch (e) {
      state = null;
      return const OptimizationFailure();
    }
  }
}

/// Fase de progresso visível na OptimizingProgressView (4 fases do Spoke).
enum OptimizationPhase { analysing, sorting, traffic, creating }
