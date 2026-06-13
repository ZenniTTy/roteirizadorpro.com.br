import 'dart:io';

import 'package:roteirizador_pro/features/routes/data/package_photo_store.dart';

/// Fake manual de [PackagePhotoStore] para testes de provider.
///
/// Registra chamadas recebidas e retorna valores configuráveis, sem tocar
/// o sistema de arquivos real (regra: sem dart:io nos testes de provider).
///
/// Uso:
/// ```dart
/// final fake = FakePackagePhotoStore();
/// fake.copyAllResult = ['novo1.jpg', 'novo2.jpg'];
/// fake.saveForResult = '/fake/path.jpg';
/// container = ProviderContainer(overrides: [
///   packagePhotoStoreProvider.overrideWithValue(fake),
/// ]);
/// ```
class FakePackagePhotoStore extends PackagePhotoStore {
  FakePackagePhotoStore()
      : super(
          // baseDirProvider nunca é chamado pelo fake — mas o construtor exige
          // o argumento; fornecemos um stub que nunca é invocado.
          baseDirProvider: () async => Directory.systemTemp,
        );

  // -------------------------------------------------------------------------
  // Configuração de retorno
  // -------------------------------------------------------------------------

  /// Valor retornado pela próxima chamada a [saveFor]. null simula falha de I/O.
  String? saveForResult;

  /// Valor retornado pela próxima chamada a [copyAll].
  List<String> copyAllResult = const [];

  /// Valor retornado pela próxima chamada a [deleteFor].
  bool deleteForResult = true;

  // -------------------------------------------------------------------------
  // Registro de chamadas
  // -------------------------------------------------------------------------

  /// Cada elemento é (routeId, stopId). Registrado por [saveFor].
  final List<(String, String)> saveForCalls = [];

  /// Cada elemento é (routeId, fromStopId, toStopId).
  final List<(String, String, String)> copyAllCalls = [];

  /// Cada elemento é (routeId, stopId).
  final List<(String, String)> deleteForCalls = [];

  // -------------------------------------------------------------------------
  // Overrides
  // -------------------------------------------------------------------------

  @override
  Future<String?> saveFor(
    String routeId,
    String stopId,
    File sourceFile,
  ) async {
    saveForCalls.add((routeId, stopId));
    return saveForResult;
  }

  @override
  Future<List<String>> copyAll(
    String routeId,
    String fromStopId,
    String toStopId,
  ) async {
    copyAllCalls.add((routeId, fromStopId, toStopId));
    return copyAllResult;
  }

  @override
  Future<bool> deleteFor(String routeId, String stopId) async {
    deleteForCalls.add((routeId, stopId));
    return deleteForResult;
  }
}
