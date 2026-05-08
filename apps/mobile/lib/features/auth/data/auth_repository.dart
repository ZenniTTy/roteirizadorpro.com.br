import 'package:dio/dio.dart';

import 'dto/auth_dtos.dart';

class AuthApiException implements Exception {
  AuthApiException({
    required this.statusCode,
    required this.error,
    required this.message,
  });

  final int statusCode;
  final String error;
  final String message;

  @override
  String toString() => 'AuthApiException($statusCode $error: $message)';
}

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<RegisterResponseDto> register(RegisterRequestDto request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: request.toJson(),
      );
      return RegisterResponseDto.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toAuthException(e);
    }
  }

  Future<LoginResponseDto> login(LoginRequestDto request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: request.toJson(),
      );
      return LoginResponseDto.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toAuthException(e);
    }
  }

  Future<MeResponseDto> me() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');
      return MeResponseDto.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toAuthException(e);
    }
  }

  AuthApiException _toAuthException(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return AuthApiException(
        statusCode: e.response?.statusCode ?? 0,
        error: (data['error'] as String?) ?? 'unknown',
        message: (data['message'] as String?) ?? e.message ?? 'request failed',
      );
    }
    return AuthApiException(
      statusCode: e.response?.statusCode ?? 0,
      error: 'network',
      message: e.message ?? 'network error',
    );
  }
}
