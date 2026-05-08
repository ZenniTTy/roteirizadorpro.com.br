import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/api_providers.dart';
import '../data/auth_repository.dart';
import '../data/dto/auth_dtos.dart';
import '../data/token_storage.dart';

part 'auth_controller.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(ref.watch(dioProvider));
}

/// Holds the currently-authenticated user, or `null` if logged out.
///
/// `build` runs once on first read: looks up tokens, calls `/auth/me` to
/// validate, then settles into one of:
///   - `AsyncData(user)` — authenticated
///   - `AsyncData(null)` — unauthenticated (no tokens, or /me failed)
///   - `AsyncError`     — propagated from explicit login/register failures
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  Future<AuthUserDto?> build() async {
    final tokens = await ref.read(tokenStorageProvider).read();
    if (tokens == null) return null;
    try {
      final response = await ref.read(authRepositoryProvider).me();
      return response.user;
    } on AuthApiException catch (e) {
      if (e.statusCode == 401) {
        await ref.read(tokenStorageProvider).clear();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final response = await ref.read(authRepositoryProvider).login(
            LoginRequestDto(email: email, password: password),
          );
      await ref.read(tokenStorageProvider).save(
            AuthTokens(access: response.access, refresh: response.refresh),
          );
      return response.user;
    });
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    await ref.read(authRepositoryProvider).register(
          RegisterRequestDto(
            email: email,
            password: password,
            name: name,
            phone: phone,
          ),
        );
    // Per the M1 contract, register does NOT auto-login; the user must
    // explicitly authenticate via /auth/login. State stays unchanged on
    // success; thrown AuthApiException bubbles up to the UI on failure.
  }

  Future<void> signOut() async {
    await ref.read(tokenStorageProvider).clear();
    state = const AsyncValue.data(null);
  }

  /// Used by the Dio interceptor when refresh fails — we already cleared
  /// tokens there, so this just flips the in-memory state.
  Future<void> signOutLocal() async {
    state = const AsyncValue.data(null);
  }
}
