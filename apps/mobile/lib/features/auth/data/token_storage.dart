import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'dto/auth_dtos.dart';

class AuthTokens {
  const AuthTokens({required this.access, required this.refresh});

  final String access;
  final String refresh;
}

class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? _defaultStorage;

  static const _accessKey = 'rp.auth.access';
  static const _refreshKey = 'rp.auth.refresh';
  static const _userKey = 'rp.auth.user';

  static const _defaultStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  final FlutterSecureStorage _storage;

  Future<AuthTokens?> read() async {
    final access = await _storage.read(key: _accessKey);
    final refresh = await _storage.read(key: _refreshKey);
    if (access == null || refresh == null) return null;
    return AuthTokens(access: access, refresh: refresh);
  }

  Future<AuthUserDto?> readUser() async {
    final userJson = await _storage.read(key: _userKey);
    if (userJson == null) return null;
    try {
      return AuthUserDto.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(AuthTokens tokens, [AuthUserDto? user]) async {
    await _storage.write(key: _accessKey, value: tokens.access);
    await _storage.write(key: _refreshKey, value: tokens.refresh);
    if (user != null) {
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _userKey);
  }
}
