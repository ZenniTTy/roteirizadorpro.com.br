import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Desenha o pino da parada (balão arredondado + label centrado) via `dart:ui`
/// Canvas e devolve um [BitmapDescriptor] p/ um `Marker` NATIVO do
/// google_maps_flutter (sem overlay em Stack — o gesto fica com o mapa).
/// Pipeline oficial (Context7 /flutter/website): PictureRecorder → Canvas →
/// Picture.toImage → toByteData(png) → BitmapDescriptor.
///
/// O label é a IDENTIFICAÇÃO da parada (deliveryId/índice) — NÃO a hora
/// estimada (ETA é Slice 3; o tempo local engana).
Future<BitmapDescriptor> stopMarkerBitmap({
  required String label,
  required Color fill,
  required Color textColor,
  double devicePixelRatio = 3.0,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final fontSize = 14.0 * devicePixelRatio;
  final padding = 8.0 * devicePixelRatio;
  final paragraphBuilder = ui.ParagraphBuilder(
    ui.ParagraphStyle(textAlign: TextAlign.center, fontSize: fontSize),
  )
    ..pushStyle(ui.TextStyle(color: textColor, fontWeight: FontWeight.w700))
    ..addText(label);
  final paragraph = paragraphBuilder.build()
    ..layout(const ui.ParagraphConstraints(width: double.infinity));

  final textW = paragraph.maxIntrinsicWidth;
  final textH = paragraph.height;
  final w = textW + padding * 2;
  final h = textH + padding * 2;
  final r = Radius.circular(h / 2);

  canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), r),
    Paint()..color = fill,
  );
  canvas.drawParagraph(paragraph, Offset(padding, padding));

  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(w.ceil(), h.ceil());
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  } finally {
    picture.dispose();
    paragraph.dispose();
  }
}
