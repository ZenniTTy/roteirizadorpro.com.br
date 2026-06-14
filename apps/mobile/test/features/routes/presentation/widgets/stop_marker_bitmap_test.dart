import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/stop_marker_bitmap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('gera um BitmapDescriptor para o label', () async {
    final d = await stopMarkerBitmap(
      label: 'A1',
      fill: Colors.blue,
      textColor: Colors.white,
    );
    expect(d, isA<BitmapDescriptor>());
  });

  test('labels diferentes geram bitmaps (não lança)', () async {
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
    expect(a, isA<BitmapDescriptor>());
    expect(b, isA<BitmapDescriptor>());
  });
}
