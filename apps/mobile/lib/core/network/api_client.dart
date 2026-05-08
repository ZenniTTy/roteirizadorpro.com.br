import 'package:dio/dio.dart';

import '../../features/auth/data/token_storage.dart';
import '../env/app_env.dart';
import 'auth_interceptor.dart';

/// Bundles the application Dio (auth-aware) and the bare Dio used for
/// /auth/refresh and retries. The bare Dio MUST NOT have the auth
/// interceptor attached — it would recurse on a refresh 401.
class ApiClient {
  ApiClient(this.dio, this._refreshDio);

  final Dio dio;
  final Dio _refreshDio;

  void close() {
    dio.close(force: true);
    _refreshDio.close(force: true);
  }
}

ApiClient buildApiClient({
  required TokenStorage tokenStorage,
  required Future<void> Function() onLogout,
}) {
  final base = BaseOptions(
    baseUrl: AppEnv.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 10),
    contentType: 'application/json',
    responseType: ResponseType.json,
  );

  final refreshDio = Dio(base);
  final dio = Dio(base);

  dio.interceptors.add(
    AuthInterceptor(
      tokenStorage: tokenStorage,
      refreshDio: refreshDio,
      onLogout: onLogout,
    ),
  );

  return ApiClient(dio, refreshDio);
}
