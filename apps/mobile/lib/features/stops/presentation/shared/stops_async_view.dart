import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/stop.dart';

/// Wraps the standard loading + error UIs shared by every slice-2 screen that
/// consumes `stopsControllerProvider.when(...)`. Callers only provide the
/// `data` builder. `screenTag` is included in the dev-only debug log emitted
/// when the AsyncValue transitions to the error state.
Widget stopsAsyncView(
  AsyncValue<List<Stop>> async, {
  required String screenTag,
  required Widget Function(BuildContext context, List<Stop> stops) data,
}) {
  return Builder(
    builder: (context) {
      return async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) {
          debugPrint('$screenTag stops error: $error');
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Não conseguimos carregar suas paradas. Tente reabrir o app.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        },
        data: (stops) => data(context, stops),
      );
    },
  );
}
