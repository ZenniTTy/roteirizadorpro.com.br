import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Gerencia fotos de pacote armazenadas 100% localmente no dispositivo.
///
/// Estrutura de diretório:
///   `package_photos/<routeId>/<stopId>/<uuid>.jpg`
///   sob o diretório retornado por [baseDirProvider].
///
/// As dependências de I/O são injetadas via [baseDirProvider] para que os
/// testes possam usar um diretório temporário sem depender de path_provider.
///
/// Nenhum dos métodos lança para a UI — falhas de I/O são registradas com
/// [debugPrint] e retornam valores vazios/null/false (H15).
///
/// Sem upload: o Spoke também guarda fotos só no device (F12, ADR-0050).
class PackagePhotoStore {
  PackagePhotoStore({required Future<Directory> Function() baseDirProvider})
      : _baseDirProvider = baseDirProvider;

  /// Wiring de produção: persiste sob `getApplicationSupportDirectory()`
  /// (paralelo fiel ao `getFilesDir()` do Spoke — H17).
  PackagePhotoStore.production()
      : this(baseDirProvider: getApplicationSupportDirectory);

  final Future<Directory> Function() _baseDirProvider;

  Future<Directory> _stopDir(String routeId, String stopId) async {
    final base = await _baseDirProvider();
    return Directory('${base.path}/package_photos/$routeId/$stopId');
  }

  /// Salva uma foto: copia [sourceFile] para
  /// `package_photos/<routeId>/<stopId>/<uuid>.jpg` e retorna o path
  /// absoluto novo, ou null em falha de I/O (H15 — nunca throw para a UI).
  Future<String?> saveFor(
    String routeId,
    String stopId,
    File sourceFile,
  ) async {
    try {
      final dir = await _stopDir(routeId, stopId);
      await dir.create(recursive: true);
      final destPath = '${dir.path}/${const Uuid().v4()}.jpg';
      await sourceFile.copy(destPath);
      return destPath;
    } catch (e) {
      debugPrint('PackagePhotoStore.saveFor falhou: $e');
      return null;
    }
  }

  /// Duplica os ARQUIVOS de fotos de [fromStopId] para [toStopId] e retorna os
  /// paths novos (lista vazia se não havia fotos ou em falha). Paths nunca
  /// compartilhados entre stops (H16).
  Future<List<String>> copyAll(
    String routeId,
    String fromStopId,
    String toStopId,
  ) async {
    try {
      final fromDir = await _stopDir(routeId, fromStopId);
      if (!await fromDir.exists()) return const [];
      final toDir = await _stopDir(routeId, toStopId);
      await toDir.create(recursive: true);
      final newPaths = <String>[];
      await for (final entity in fromDir.list()) {
        if (entity is! File) continue;
        final destPath = '${toDir.path}/${const Uuid().v4()}.jpg';
        await entity.copy(destPath);
        newPaths.add(destPath);
      }
      return newPaths;
    } catch (e) {
      debugPrint('PackagePhotoStore.copyAll falhou: $e');
      return const [];
    }
  }

  /// Remove o diretório de fotos do stop. Retorna true em sucesso,
  /// false quando o diretório não existe ou em falha de I/O (degrada com
  /// debugPrint, sem throw).
  Future<bool> deleteFor(String routeId, String stopId) async {
    try {
      final dir = await _stopDir(routeId, stopId);
      if (!await dir.exists()) return false;
      await dir.delete(recursive: true);
      return true;
    } catch (e) {
      debugPrint('PackagePhotoStore.deleteFor falhou: $e');
      return false;
    }
  }
}
