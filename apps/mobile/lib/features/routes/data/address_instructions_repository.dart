import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Instruções de acesso padrão POR ENDEREÇO (sticky-ao-endereço, F13).
/// Envelope address_instructions_v1: mapa JSON {endereçoNormalizado: texto}.
///
/// Resiliência (H15): envelope corrompido ou não-mapa degrada para `{}` com
/// debugPrint — nunca lança para a UI.
class AddressInstructionsRepository {
  AddressInstructionsRepository(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const String storageKey = 'address_instructions_v1';

  /// Normalização canônica da chave (H18): fullAddress.trim().toLowerCase().
  static String normalizeKey(String fullAddress) =>
      fullAddress.trim().toLowerCase();

  /// Mapa completo {chave normalizada: instrução}. Corrompido/não-mapa → {} + debugPrint (H15).
  Future<Map<String, String>> read() async {
    final raw = await _prefs.getString(storageKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return {};
      return {
        for (final entry in decoded.entries)
          if (entry.value is String) entry.key: entry.value as String,
      };
    } catch (e) {
      debugPrint('[address_instructions_repository] corrupted JSON: $e');
      return {};
    }
  }

  /// Instrução default para o endereço, ou null (normaliza a chave antes).
  Future<String?> instructionFor(String fullAddress) async {
    final map = await read();
    return map[normalizeKey(fullAddress)];
  }

  /// Grava/substitui o default do endereço (read-modify-write do envelope).
  Future<void> saveDefault(String fullAddress, String text) async {
    final map = await read();
    map[normalizeKey(fullAddress)] = text;
    await _write(map);
  }

  /// Remove o default do endereço.
  Future<void> clearDefault(String fullAddress) async {
    final map = await read();
    map.remove(normalizeKey(fullAddress));
    await _write(map);
  }

  Future<void> _write(Map<String, String> map) async {
    await _prefs.setString(storageKey, jsonEncode(map));
  }
}
