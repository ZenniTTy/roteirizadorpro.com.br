// CONTRACT REMINDER (flutter-test-author):
//
// stopMarkerBitmap(...) deve retornar [StopMarkerBitmap] — NÃO um
// BitmapDescriptor bare. O implementador precisa:
//   1. Manter a classe StopMarkerBitmap em stop_marker_bitmap.dart com:
//        final BitmapDescriptor descriptor
//        final double imagePixelRatio
//   2. Fazer stopMarkerBitmap retornar StopMarkerBitmap(
//        descriptor: BitmapDescriptor.bytes(bytes, imagePixelRatio: dpr),
//        imagePixelRatio: dpr,
//      )
//      onde dpr é o parâmetro devicePixelRatio recebido.
//
// Após a implementação todos os testes abaixo devem ficar verdes.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/stop_marker_bitmap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('stopMarkerBitmap', () {
    test(
      'retorna StopMarkerBitmap com descriptor e imagePixelRatio igual ao dpr passado',
      () async {
        const dpr = 2.5;
        final result = await stopMarkerBitmap(
          label: 'A1',
          fill: Colors.blue,
          textColor: Colors.white,
          devicePixelRatio: dpr,
        );

        // O retorno deve ser do tipo correto (não um BitmapDescriptor bare).
        expect(result, isA<StopMarkerBitmap>());

        // O descriptor deve ser um BitmapDescriptor válido.
        expect(result.descriptor, isA<BitmapDescriptor>());

        // imagePixelRatio deve ser positivo e igual ao dpr solicitado.
        expect(result.imagePixelRatio, greaterThan(0.0));
        expect(result.imagePixelRatio, equals(dpr));
      },
    );

    test(
      'imagePixelRatio reflete o devicePixelRatio default (3.0) quando omitido',
      () async {
        final result = await stopMarkerBitmap(
          label: 'B2',
          fill: Colors.red,
          textColor: Colors.white,
        );

        expect(result.imagePixelRatio, equals(3.0));
      },
    );

    test(
      'labels diferentes geram bitmaps sem lançar exceção',
      () async {
        final a = await stopMarkerBitmap(
          label: 'A1',
          fill: Colors.blue,
          textColor: Colors.white,
        );
        final b = await stopMarkerBitmap(
          label: 'A10',
          fill: Colors.blue,
          textColor: Colors.white,
        );

        expect(a, isA<StopMarkerBitmap>());
        expect(b, isA<StopMarkerBitmap>());
        expect(a.descriptor, isA<BitmapDescriptor>());
        expect(b.descriptor, isA<BitmapDescriptor>());
      },
    );
  });
}
