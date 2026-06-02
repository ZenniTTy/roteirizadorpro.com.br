import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/route_config/data/route_defaults_repository.dart';
import 'package:roteirizador_pro/features/route_config/domain/route_config.dart';
import 'package:roteirizador_pro/features/route_config/domain/route_defaults.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('read()', () {
    test('returns RouteDefaults.empty() when key is absent', () async {
      final repo = RouteDefaultsRepository(SharedPreferencesAsync());
      expect(await repo.read(), RouteDefaults.empty());
    });

    test('returns parsed envelope when key is present', () async {
      final prefs = SharedPreferencesAsync();
      const original = RouteDefaults(
        firstRoute: false,
        timeStart: TimeStart(time: TimeOfDay(hour: 9, minute: 0)),
        timeEnd: TimeEnd(time: TimeOfDay(hour: 17, minute: 0)),
        destination: BackToStart(),
      );
      await prefs.setString(
        RouteDefaultsRepository.storageKey,
        jsonEncode(original.toJson()),
      );

      final repo = RouteDefaultsRepository(prefs);
      expect(await repo.read(), original);
    });

    test('returns empty() when stored JSON is malformed', () async {
      final prefs = SharedPreferencesAsync();
      await prefs.setString(
        RouteDefaultsRepository.storageKey,
        '{not json',
      );

      final repo = RouteDefaultsRepository(prefs);
      expect(await repo.read(), RouteDefaults.empty());
    });

    test('returns empty() when stored JSON has wrong schemaVersion', () async {
      final prefs = SharedPreferencesAsync();
      await prefs.setString(
        RouteDefaultsRepository.storageKey,
        jsonEncode({'schemaVersion': 99, 'firstRoute': false}),
      );

      final repo = RouteDefaultsRepository(prefs);
      expect(await repo.read(), RouteDefaults.empty());
    });
  });

  group('write()', () {
    test('serializes and round-trips through read()', () async {
      final prefs = SharedPreferencesAsync();
      final repo = RouteDefaultsRepository(prefs);

      const toWrite = RouteDefaults(
        firstRoute: false,
        startLocation: StartLocation(
          address: 'R Augusta',
          lat: -23.5,
          lng: -46.6,
          isUserCurrentLocation: false,
        ),
        timeStart: TimeStart(time: TimeOfDay(hour: 8, minute: 0)),
        timeEnd: TimeEnd(time: TimeOfDay(hour: 18, minute: 0)),
        destination: RoundTrip(),
        breaks: [
          BreakConfig(
            startTime: TimeOfDay(hour: 12, minute: 0),
            durationMinutes: 30,
          ),
        ],
      );
      await repo.write(toWrite);
      expect(await repo.read(), toWrite);
    });

    test('write replaces previous value', () async {
      final prefs = SharedPreferencesAsync();
      final repo = RouteDefaultsRepository(prefs);

      await repo.write(RouteDefaults.empty());
      const second = RouteDefaults(firstRoute: false);
      await repo.write(second);
      expect(await repo.read(), second);
    });
  });
}
