import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/core/providers/api_providers.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/state/optimize_controller.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

import '../_helpers/fake_stops_repository.dart';

class _FakeDio extends Fake implements Dio {
  Map<String, dynamic>? lastBody;

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
    lastBody = data as Map<String, dynamic>?;
    final responseData = <String, dynamic>{
      'optimizedOrder': [2, 0, 1],
      'totalDistanceM': 12345.6,
      'totalDurationS': 678.9,
    };
    return Response<T>(
      data: responseData as T,
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
    );
  }
}

Stop _stop(String id, {double lat = 0, double lng = 0}) => Stop(
      id: id,
      lat: lat,
      lng: lng,
      source: StopSource.manual,
      createdAt: DateTime.utc(2026, 5, 13, 12),
    );

void main() {
  late FakeStopsRepository repo;
  late _FakeDio fakeDio;
  late ProviderContainer container;

  setUp(() {
    repo = FakeStopsRepository();
    fakeDio = _FakeDio();
    container = ProviderContainer(
      overrides: [
        stopsRepositoryProvider.overrideWithValue(repo),
        dioProvider.overrideWithValue(fakeDio),
      ],
    );
    addTearDown(container.dispose);
  });

  test('run posts stops as StopDto[] and applies optimizedOrder', () async {
    repo.seed([
      _stop('a', lat: 1.0, lng: 0.0),
      _stop('b'),
      _stop('c'),
    ]);

    await container.read(stopsControllerProvider.future);

    final notifier = container.read(optimizeControllerProvider.notifier);
    final result = await notifier.run();

    final stops = fakeDio.lastBody!['stops'] as List<dynamic>;
    expect(
      stops.first,
      equals(<String, dynamic>{'lat': 1.0, 'lng': 0.0}),
    );

    final reordered = await container.read(stopsControllerProvider.future);
    expect(reordered.map((s) => s.id), ['c', 'a', 'b']);

    expect(result.totalDistanceM, 12345.6);
    expect(result.totalDurationS, 678.9);
  });
}
