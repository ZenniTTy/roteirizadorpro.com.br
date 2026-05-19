import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/core/providers/api_providers.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/presentation/optimize_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

import '../_helpers/fake_stops_repository.dart';

class _FakeDio extends Fake implements Dio {
  _FakeDio({this.throwOnPost = false});

  bool throwOnPost;

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    if (throwOnPost) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        message: 'Network down',
      );
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: {
        'optimizedOrder': [1, 0],
        'totalDistanceM': 0.0,
        'totalDurationS': 0.0,
      } as T,
    );
  }
}

Stop _s(String id) => Stop(
      id: id,
      lat: 1,
      lng: 1,
      source: StopSource.manual,
      createdAt: DateTime.utc(2026, 5, 19),
    );

void main() {
  testWidgets(
    'OptimizePage renders progress steps and fires onSuccess after the run completes',
    (tester) async {
      var successFired = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            stopsRepositoryProvider.overrideWithValue(
              FakeStopsRepository([_s('a'), _s('b')]),
            ),
            dioProvider.overrideWithValue(_FakeDio()),
          ],
          child: MaterialApp(
            home: OptimizePage(
              onSuccess: (_) => successFired++,
              onSkip: (_) {},
            ),
          ),
        ),
      );

      // First frame renders the loading UI.
      await tester.pump();

      expect(find.textContaining('Analisando'), findsOneWidget);
      expect(find.textContaining('Calculando'), findsOneWidget);
      expect(find.textContaining('Encontrando'), findsOneWidget);
      expect(find.text('Pular →'), findsOneWidget);

      // Let the microtask fire OptimizeController.run, then let the
      // async response resolve and ref.listen notify.
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(successFired, 1);
    },
  );

  testWidgets('Pular fires onSkip and does not invoke onSuccess',
      (tester) async {
    var successFired = 0;
    var skipFired = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stopsRepositoryProvider.overrideWithValue(
            FakeStopsRepository([_s('a'), _s('b')]),
          ),
          dioProvider.overrideWithValue(
            _FakeDio(throwOnPost: true),
          ),
        ],
        child: MaterialApp(
          home: OptimizePage(
            onSuccess: (_) => successFired++,
            onSkip: (_) => skipFired++,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Voltar para a home'));
    await tester.pump();

    expect(successFired, 0);
    expect(skipFired, 1);
  });
}
