import 'package:dio/dio.dart';

import '../../features/auth/data/token_storage.dart';

/// Adds the access token to every request, and on 401 tries to swap the
/// refresh token for a new pair via `POST /auth/refresh`.
///
/// `QueuedInterceptor` serializes onError calls — while one request is
/// refreshing the token, others wait. This avoids N parallel /auth/refresh
/// calls when several requests 401 at once.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.tokenStorage,
    required this.refreshDio,
    required this.onLogout,
  });

  final TokenStorage tokenStorage;

  /// A second Dio instance used ONLY for the /auth/refresh call. Must not
  /// have this interceptor attached, or a 401 inside refresh would recurse.
  final Dio refreshDio;

  /// Called when refresh is impossible (no refresh token) or fails (server
  /// rejected). The caller is expected to clear auth state and route the
  /// user to /login.
  final Future<void> Function() onLogout;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skipAuth'] == true) {
      handler.next(options);
      return;
    }
    final tokens = await tokenStorage.read();
    if (tokens != null) {
      options.headers['Authorization'] = 'Bearer ${tokens.access}';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isAuthRoute = err.requestOptions.path.startsWith('/auth/');
    if (err.response?.statusCode != 401 || isAuthRoute) {
      handler.next(err);
      return;
    }

    final tokens = await tokenStorage.read();
    if (tokens == null) {
      await onLogout();
      handler.next(err);
      return;
    }

    try {
      final refreshResponse = await refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh': tokens.refresh},
      );
      final access = refreshResponse.data!['access'] as String;
      final refresh = refreshResponse.data!['refresh'] as String;
      await tokenStorage.save(AuthTokens(access: access, refresh: refresh));

      final retryOptions = err.requestOptions.copyWith(
        headers: {
          ...err.requestOptions.headers,
          'Authorization': 'Bearer $access',
        },
      );
      final retryResponse = await refreshDio.fetch<dynamic>(retryOptions);
      handler.resolve(retryResponse);
    } on DioException {
      await tokenStorage.clear();
      await onLogout();
      handler.next(err);
    }
  }
}
