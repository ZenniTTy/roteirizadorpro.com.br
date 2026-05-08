import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/data/token_storage.dart';
import '../../features/auth/state/auth_controller.dart';
import '../network/api_client.dart';

part 'api_providers.g.dart';

@Riverpod(keepAlive: true)
TokenStorage tokenStorage(Ref ref) => TokenStorage();

@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) {
  final storage = ref.watch(tokenStorageProvider);
  final client = buildApiClient(
    tokenStorage: storage,
    onLogout: () async {
      await ref.read(authControllerProvider.notifier).signOutLocal();
    },
  );
  ref.onDispose(client.close);
  return client;
}

@Riverpod(keepAlive: true)
Dio dio(Ref ref) => ref.watch(apiClientProvider).dio;
