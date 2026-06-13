import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/domain/package_details.dart';
import 'package:roteirizador_pro/features/routes/domain/place_in_vehicle.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';
import 'package:roteirizador_pro/features/routes/domain/stop_color.dart';
import 'package:roteirizador_pro/features/routes/domain/stop_order_policy.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Fábrica de um Stop totalmente preenchido, reutilizada em vários grupos.
  // ---------------------------------------------------------------------------
  Stop stopCompleto() => Stop(
        id: 'id-fixo',
        positionInRoute: 3,
        deliveryId: 'A1',
        type: StopType.pickup,
        status: StopStatus.delivered,
        lat: -23.5,
        lng: -46.6,
        streetName: 'Av. Paulista',
        fullAddress: 'Av. Paulista, 1000',
        notes: 'toque 3 vezes',
        packagesCount: 2,
        timeWindowStart: const TimeOfDay(hour: 8, minute: 0),
        timeWindowEnd: const TimeOfDay(hour: 18, minute: 0),
        priority: 2,
        orderPolicy: StopOrderPolicy.first,
        color: StopColor.teal,
        packageDetails: const PackageDetails(
          dimension: PackageDimension.small,
          type: PackageType.box,
        ),
        placeInVehicle: const PlaceInVehicle(y: PlaceY.front),
        photoPaths: const ['p1.jpg'],
        accessInstructions: 'portão azul',
        estimatedTimeAtStop: const Duration(minutes: 5),
      );

  // ---------------------------------------------------------------------------
  // 1. Defaults (H3)
  // ---------------------------------------------------------------------------
  group('Stop — defaults ao construir sem argumentos opcionais', () {
    late Stop s;

    setUp(() {
      s = Stop(
        lat: -23.5,
        lng: -46.6,
        streetName: 'Rua X',
        fullAddress: 'Rua X, 1',
      );
    });

    test('orderPolicy padrão é auto (não first nem last)', () {
      // O stub retorna StopOrderPolicy.first → falha em assertion (RED).
      expect(s.orderPolicy, StopOrderPolicy.auto);
    });

    test('packagesCount padrão é 1', () {
      expect(s.packagesCount, 1);
    });

    test('photoPaths padrão é lista vazia', () {
      // O stub retorna const [\'stub\'] → falha em assertion (RED).
      expect(s.photoPaths, isEmpty);
    });

    test('status padrão é pending', () {
      expect(s.status, StopStatus.pending);
    });

    test('type padrão é delivery', () {
      expect(s.type, StopType.delivery);
    });

    test('campos nullable opcionais são null por padrão', () {
      expect(s.positionInRoute, isNull);
      expect(s.deliveryId, isNull);
      expect(s.notes, isNull);
      expect(s.timeWindowStart, isNull);
      expect(s.timeWindowEnd, isNull);
      expect(s.priority, isNull);
      expect(s.color, isNull);
      expect(s.packageDetails, isNull);
      expect(s.placeInVehicle, isNull);
      expect(s.accessInstructions, isNull);
      expect(s.estimatedTimeAtStop, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // 2. copyWith clears-it — um teste por campo nullable (H2)
  //    A cada teste: partir de um Stop PREENCHIDO e assertar que
  //    copyWith(<campo>: null) produz o campo null no resultado.
  // ---------------------------------------------------------------------------
  group('Stop.copyWith — clears-it (null limpa o campo, não preserva)', () {
    test('copyWith(notes: null) limpa notes', () {
      final resultado = stopCompleto().copyWith(notes: null);
      // O copyWith atual usa `?? this.notes` → preserva em vez de limpar (RED).
      expect(resultado.notes, isNull);
    });

    test('copyWith(timeWindowStart: null) limpa timeWindowStart', () {
      final resultado = stopCompleto().copyWith(timeWindowStart: null);
      expect(resultado.timeWindowStart, isNull);
    });

    test('copyWith(timeWindowEnd: null) limpa timeWindowEnd', () {
      final resultado = stopCompleto().copyWith(timeWindowEnd: null);
      expect(resultado.timeWindowEnd, isNull);
    });

    test('copyWith(priority: null) limpa priority', () {
      final resultado = stopCompleto().copyWith(priority: null);
      expect(resultado.priority, isNull);
    });

    test('copyWith(deliveryId: null) limpa deliveryId', () {
      final resultado = stopCompleto().copyWith(deliveryId: null);
      expect(resultado.deliveryId, isNull);
    });

    test('copyWith(positionInRoute: null) limpa positionInRoute', () {
      final resultado = stopCompleto().copyWith(positionInRoute: null);
      expect(resultado.positionInRoute, isNull);
    });

    test('copyWith(accessInstructions: null) limpa accessInstructions', () {
      final resultado = stopCompleto().copyWith(accessInstructions: null);
      expect(resultado.accessInstructions, isNull);
    });

    test('copyWith(color: null) limpa color', () {
      final resultado = stopCompleto().copyWith(color: null);
      expect(resultado.color, isNull);
    });

    test('copyWith(packageDetails: null) limpa packageDetails', () {
      final resultado = stopCompleto().copyWith(packageDetails: null);
      expect(resultado.packageDetails, isNull);
    });

    test('copyWith(placeInVehicle: null) limpa placeInVehicle', () {
      final resultado = stopCompleto().copyWith(placeInVehicle: null);
      expect(resultado.placeInVehicle, isNull);
    });

    test('copyWith(estimatedTimeAtStop: null) limpa estimatedTimeAtStop', () {
      final resultado = stopCompleto().copyWith(estimatedTimeAtStop: null);
      expect(resultado.estimatedTimeAtStop, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // 3. copyWith sem args preserva TODOS os campos (H2)
  // ---------------------------------------------------------------------------
  group('Stop.copyWith — omitir arg preserva o campo', () {
    test('copyWith() sem argumentos preserva todos os campos', () {
      final original = stopCompleto();
      // O corpo do copyWith lança UnimplementedError → falha (RED).
      final copia = original.copyWith();

      expect(copia.id, original.id);
      expect(copia.positionInRoute, original.positionInRoute);
      expect(copia.deliveryId, original.deliveryId);
      expect(copia.type, original.type);
      expect(copia.status, original.status);
      expect(copia.lat, original.lat);
      expect(copia.lng, original.lng);
      expect(copia.streetName, original.streetName);
      expect(copia.fullAddress, original.fullAddress);
      expect(copia.notes, original.notes);
      expect(copia.packagesCount, original.packagesCount);
      expect(copia.timeWindowStart, original.timeWindowStart);
      expect(copia.timeWindowEnd, original.timeWindowEnd);
      expect(copia.priority, original.priority);
      expect(copia.orderPolicy, original.orderPolicy);
      expect(copia.color, original.color);
      expect(copia.packageDetails, original.packageDetails);
      expect(copia.placeInVehicle, original.placeInVehicle);
      expect(copia.photoPaths, original.photoPaths);
      expect(copia.accessInstructions, original.accessInstructions);
      expect(copia.estimatedTimeAtStop, original.estimatedTimeAtStop);
    });
  });

  // ---------------------------------------------------------------------------
  // 4. copyWith substitui — valores mudam ao passar argumento não-nulo (H1/H2)
  // ---------------------------------------------------------------------------
  group('Stop.copyWith — substituição de valores', () {
    test('copyWith(notes: x) substitui notes', () {
      final resultado = stopCompleto().copyWith(notes: 'novo aviso');
      expect(resultado.notes, 'novo aviso');
    });

    test('copyWith(orderPolicy: last) substitui orderPolicy', () {
      final resultado =
          stopCompleto().copyWith(orderPolicy: StopOrderPolicy.last);
      expect(resultado.orderPolicy, StopOrderPolicy.last);
    });

    test(
        'copyWith(timeWindowStart: TimeOfDay(9,30)) substitui timeWindowStart — tipo TimeOfDay (H1)',
        () {
      final resultado = stopCompleto()
          .copyWith(timeWindowStart: const TimeOfDay(hour: 9, minute: 30));
      expect(resultado.timeWindowStart, const TimeOfDay(hour: 9, minute: 30));
    });

    test('copyWith(color: StopColor.orange) substitui color', () {
      final resultado = stopCompleto().copyWith(color: StopColor.orange);
      expect(resultado.color, StopColor.orange);
    });

    test('copyWith(photoPaths: [a, b]) substitui photoPaths', () {
      final resultado =
          stopCompleto().copyWith(photoPaths: const ['a.jpg', 'b.jpg']);
      expect(resultado.photoPaths, const ['a.jpg', 'b.jpg']);
    });
  });

  // ---------------------------------------------------------------------------
  // 5. Coexistência priority e orderPolicy (H4)
  // ---------------------------------------------------------------------------
  group('Stop — priority e orderPolicy coexistem (H4)', () {
    test(
        'um Stop pode ter priority: 2 E orderPolicy: first simultaneamente '
        '(campos ortogonais — solver vs posição)', () {
      final s = Stop(
        lat: -23.5,
        lng: -46.6,
        streetName: 'Rua Y',
        fullAddress: 'Rua Y, 5',
        priority: 2,
        orderPolicy: StopOrderPolicy.first,
      );
      expect(s.priority, 2);
      expect(s.orderPolicy, StopOrderPolicy.first);
    });
  });
}
