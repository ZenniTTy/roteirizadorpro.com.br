import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/api_providers.dart';
import 'stops_controller.dart';

part 'optimize_controller.g.dart';

class OptimizeResult {
  const OptimizeResult({
    required this.optimizedOrder,
    required this.totalDistanceM,
    required this.totalDurationS,
  });
  final List<int> optimizedOrder;
  final double totalDistanceM;
  final double totalDurationS;
}

@riverpod
class OptimizeController extends _$OptimizeController {
  @override
  AsyncValue<OptimizeResult?> build() => const AsyncData(null);

  Future<OptimizeResult> run() async {
    state = const AsyncLoading();
    try {
      final stops = await ref.read(stopsControllerProvider.future);
      final body = {
        'stops': [for (final s in stops) s.toDto().toJson()],
      };
      final dio = ref.read(dioProvider);
      final response = await dio.post<Map<String, dynamic>>(
        '/routes/optimize',
        data: body,
      );
      final json = response.data!;
      final result = OptimizeResult(
        optimizedOrder: (json['optimizedOrder'] as List).cast<int>(),
        totalDistanceM: (json['totalDistanceM'] as num).toDouble(),
        totalDurationS: (json['totalDurationS'] as num).toDouble(),
      );
      await ref
          .read(stopsControllerProvider.notifier)
          .applyOptimizedOrder(result.optimizedOrder);
      state = AsyncData(result);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
