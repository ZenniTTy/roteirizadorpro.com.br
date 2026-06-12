import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/domain/package_details.dart';
import 'package:roteirizador_pro/features/routes/domain/place_in_vehicle.dart';
import 'package:roteirizador_pro/features/routes/domain/stop_color.dart';
import 'package:roteirizador_pro/features/routes/domain/stop_order_policy.dart';

void main() {
  // ---------------------------------------------------------------------------
  // StopColor (F10)
  // ---------------------------------------------------------------------------
  group('StopColor', () {
    test('tem exatamente 5 valores na ordem [blue, teal, purple, pink, orange]',
        () {
      // Os stubs têm apenas 1 valor — este assert falha em assertion (RED).
      expect(StopColor.values.length, 5);
      expect(
        StopColor.values.map((e) => e.name).toList(),
        ['blue', 'teal', 'purple', 'pink', 'orange'],
      );
    });
  });

  // ---------------------------------------------------------------------------
  // StopOrderPolicy (F16)
  // ---------------------------------------------------------------------------
  group('StopOrderPolicy', () {
    test('tem exatamente 3 valores na ordem [first, auto, last]', () {
      // O stub tem apenas 1 valor — este assert falha em assertion (RED).
      expect(StopOrderPolicy.values.length, 3);
      expect(
        StopOrderPolicy.values.map((e) => e.name).toList(),
        ['first', 'auto', 'last'],
      );
    });

    test('o valor padrão semântico (índice 1) é auto', () {
      // Com stub de 1 valor, index 1 lança RangeError — falha em assertion (RED).
      expect(StopOrderPolicy.values[1].name, 'auto');
    });
  });

  // ---------------------------------------------------------------------------
  // PackageDimension e PackageType (F8)
  // ---------------------------------------------------------------------------
  group('PackageDimension', () {
    test('tem exatamente 3 valores na ordem [small, medium, large]', () {
      // O stub tem apenas 1 valor — este assert falha em assertion (RED).
      expect(PackageDimension.values.length, 3);
      expect(
        PackageDimension.values.map((e) => e.name).toList(),
        ['small', 'medium', 'large'],
      );
    });
  });

  group('PackageType', () {
    test('tem exatamente 3 valores na ordem [box, bag, letter]', () {
      // O stub tem apenas 1 valor — este assert falha em assertion (RED).
      expect(PackageType.values.length, 3);
      expect(
        PackageType.values.map((e) => e.name).toList(),
        ['box', 'bag', 'letter'],
      );
    });
  });

  // ---------------------------------------------------------------------------
  // PackageDetails — igualdade por valor
  //
  // Os testes de igualdade usam apenas PackageDimension.small e PackageType.box
  // (os únicos valores disponíveis nos stubs). A cobertura dos outros valores de
  // enum está nos grupos PackageDimension/PackageType acima via values.length e
  // values.map(e.name). A igualdade por valor falha porque o stub não sobrescreve
  // == e hashCode (Object.== usa identidade de objeto).
  // ---------------------------------------------------------------------------
  group('PackageDetails', () {
    test('aceita construtor const sem argumentos (tudo nulo)', () {
      // Deve compilar e não lançar — o ctor é const.
      const details = PackageDetails();
      expect(details.dimension, isNull);
      expect(details.type, isNull);
    });

    test(
        'duas instâncias com os mesmos campos são == e têm o mesmo hashCode '
        '(igualdade por valor)', () {
      // `a` e `b` são non-const de propósito: instâncias de runtime distintas
      // (o Dart canonicaliza objetos const com os mesmos argumentos, o que
      // mascararia a ausência do override de ==).
      const dim = PackageDimension.small;
      const tipo = PackageType.box;
      // ignore: prefer_const_constructors
      final a = PackageDetails(dimension: dim, type: tipo);
      // ignore: prefer_const_constructors
      final b = PackageDetails(dimension: dim, type: tipo);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('instância com campo nulo difere de instância com campo definido', () {
      // Este já passa mesmo sem override (identidade difere) — serve como
      // sanity-check; o assert acima é o que falha e prova a lacuna.
      const comDimensao = PackageDetails(dimension: PackageDimension.small);
      const semDimensao = PackageDetails();
      expect(comDimensao, isNot(equals(semDimensao)));
    });
  });

  // ---------------------------------------------------------------------------
  // PlaceX, PlaceY, PlaceZ — cobertura de enum
  // ---------------------------------------------------------------------------
  group('PlaceX', () {
    test('tem exatamente 2 valores na ordem [left, right]', () {
      expect(PlaceX.values.length, 2);
      expect(
        PlaceX.values.map((e) => e.name).toList(),
        ['left', 'right'],
      );
    });
  });

  group('PlaceY', () {
    test('tem exatamente 3 valores na ordem [front, middle, back]', () {
      expect(PlaceY.values.length, 3);
      expect(
        PlaceY.values.map((e) => e.name).toList(),
        ['front', 'middle', 'back'],
      );
    });
  });

  group('PlaceZ', () {
    test('tem exatamente 2 valores na ordem [floor, shelf]', () {
      expect(PlaceZ.values.length, 2);
      expect(
        PlaceZ.values.map((e) => e.name).toList(),
        ['floor', 'shelf'],
      );
    });
  });

  // ---------------------------------------------------------------------------
  // PlaceInVehicle — igualdade por valor
  //
  // Usa apenas PlaceY.front, PlaceX.left, PlaceZ.floor — valores presentes nos
  // stubs. A falha em assertion acontece porque o stub não sobrescreve == e
  // hashCode (Object.== usa identidade).
  // ---------------------------------------------------------------------------
  group('PlaceInVehicle — igualdade por valor', () {
    test('aceita construtor const sem argumentos (tudo nulo)', () {
      const place = PlaceInVehicle();
      expect(place.x, isNull);
      expect(place.y, isNull);
      expect(place.z, isNull);
    });

    test(
        'duas instâncias com os mesmos campos são == e têm o mesmo hashCode '
        '(igualdade por valor)', () {
      // `a` e `b` são non-const de propósito: instâncias de runtime distintas
      // (o Dart canonicaliza objetos const com os mesmos argumentos, o que
      // mascararia a ausência do override de ==).
      const eixoY = PlaceY.front;
      const eixoX = PlaceX.left;
      const eixoZ = PlaceZ.floor;
      // ignore: prefer_const_constructors
      final a = PlaceInVehicle(y: eixoY, x: eixoX, z: eixoZ);
      // ignore: prefer_const_constructors
      final b = PlaceInVehicle(y: eixoY, x: eixoX, z: eixoZ);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('instância com campo nulo difere de instância com campo definido', () {
      // Sanity-check: identidade difere mesmo sem override.
      const comEixoY = PlaceInVehicle(y: PlaceY.front);
      const semEixoY = PlaceInVehicle();
      expect(comEixoY, isNot(equals(semEixoY)));
    });
  });

  // ---------------------------------------------------------------------------
  // PlaceInVehicle.shortCode — microcopy PT-BR, ordem Y,X,Z (F11)
  //
  // Mapeamento PT-BR (microcopy original RotPro):
  //   PlaceY.front  → 'F' (Frente)
  //   PlaceY.middle → 'M' (Meio)
  //   PlaceY.back   → 'A' (Atrás)
  //   PlaceX.left   → 'E' (Esquerda)
  //   PlaceX.right  → 'D' (Direita)
  //   PlaceZ.floor  → 'C' (Chão)
  //   PlaceZ.shelf  → 'P' (Prateleira)
  //
  // Os testes de shortCode usam apenas valores presentes nos stubs
  // (front/left/floor) para evitar erros de compilação. O stub lança
  // UnimplementedError em shortCode → todos falham em assertion (RED).
  // Os casos com valores adicionais (back, middle, right, shelf) tornam-se
  // testáveis após o implementador adicionar os valores de enum completos.
  // ---------------------------------------------------------------------------
  group('PlaceInVehicle.shortCode', () {
    test(
        'front + left + floor → "FEC" '
        '(Y=Frente, X=Esquerda, Z=Chão, ordem Y,X,Z)', () {
      const place = PlaceInVehicle(
        y: PlaceY.front,
        x: PlaceX.left,
        z: PlaceZ.floor,
      );
      // O stub lança UnimplementedError → falha em assertion (RED).
      expect(place.shortCode, 'FEC');
    });

    test('nenhum eixo definido → null (F11)', () {
      const place = PlaceInVehicle();
      // O stub lança UnimplementedError → falha em assertion (RED).
      expect(place.shortCode, isNull);
    });

    test('somente front (sem X, sem Z) → "F" (somente Y definido)', () {
      const place = PlaceInVehicle(y: PlaceY.front);
      expect(place.shortCode, 'F');
    });

    test('somente left (sem Y, sem Z) → "E" (somente X definido)', () {
      const place = PlaceInVehicle(x: PlaceX.left);
      expect(place.shortCode, 'E');
    });

    test('somente floor (sem Y, sem X) → "C" (somente Z definido)', () {
      const place = PlaceInVehicle(z: PlaceZ.floor);
      expect(place.shortCode, 'C');
    });

    test('front + floor (sem X) → "FC" (Y e Z definidos, X pulado)', () {
      const place = PlaceInVehicle(y: PlaceY.front, z: PlaceZ.floor);
      expect(place.shortCode, 'FC');
    });
  });
}
