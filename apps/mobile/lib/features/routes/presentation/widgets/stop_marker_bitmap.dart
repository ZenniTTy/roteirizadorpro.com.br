import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// CONTRACT (defined by flutter-test-author for bug fix "markers gigantes"):
//
// [StopMarkerBitmap] é o tipo de retorno de [stopMarkerBitmap].
// Carrega o descriptor JÁ criado e o imagePixelRatio que foi usado ao
// desenhar o PNG, para que o caller (routeMapMarkersProvider) passe
// imagePixelRatio para BitmapDescriptor.bytes(...) e o mapa divida o PNG
// físico de volta ao tamanho lógico correto.
//
// Campos:
//   descriptor      — BitmapDescriptor pronto para Marker.icon
//   imagePixelRatio — igual ao devicePixelRatio passado para stopMarkerBitmap;
//                     deve ser > 0
class StopMarkerBitmap {
  const StopMarkerBitmap({
    required this.descriptor,
    required this.imagePixelRatio,
  });

  final BitmapDescriptor descriptor;
  final double imagePixelRatio;
}

/// Desenha o pino da parada (balão arredondado + label centrado) via `dart:ui`
/// Canvas e devolve um [StopMarkerBitmap] contendo o [BitmapDescriptor] e o
/// [imagePixelRatio] usado, para que o provider passe ambos ao mapa.
///
/// O label é a IDENTIFICAÇÃO da parada (deliveryId/índice) — NÃO a hora
/// estimada (ETA é Slice 3; o tempo local engana).
Future<StopMarkerBitmap> stopMarkerBitmap({
  required String label,
  required Color fill,
  required Color textColor,
  double devicePixelRatio = 3.0,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // Dimensões em DP lógicos (× devicePixelRatio só p/ desenhar nítido; o mapa
  // divide de volta via imagePixelRatio). O balão do Spoke é compacto: ~12sp
  // de fonte + ~6dp de padding → pino ~28dp de altura. (12 = caption do
  // prototipo; o 14sp anterior, somado à AUSÊNCIA de imagePixelRatio, era o
  // que fazia o pino sair gigante no device.)
  final fontSize = 12.0 * devicePixelRatio;
  final padding = 6.0 * devicePixelRatio;
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
      // `toByteData` pode devolver null em falha de encoding (raro num
      // ui.Image recém-desenhado). Erro EXPLÍCITO em vez de `bytes!`: o
      // `routeMapMarkersProvider` entra em AsyncError observável (o shell
      // degrada p/ markers vazios via `.value ?? {}`, sem crash, mas a falha
      // não some silenciosamente — fica em `.hasError`).
      if (bytes == null) {
        throw StateError('toByteData devolveu null para o marker "$label"');
      }
      // imagePixelRatio = devicePixelRatio: o PNG foi desenhado em pixels
      // FÍSICOS (× dpr); informar isto faz o mapa dividir de volta ao tamanho
      // lógico → pino com tamanho CONSTANTE em dp em qualquer densidade
      // (o que o Spoke obtém nativamente com Compose dp). SEM este parâmetro,
      // o mapa renderiza o PNG físico 1:1 → pino ~dpr× maior (o bug).
      final descriptor = BitmapDescriptor.bytes(
        bytes.buffer.asUint8List(),
        imagePixelRatio: devicePixelRatio,
      );
      return StopMarkerBitmap(
        descriptor: descriptor,
        imagePixelRatio: devicePixelRatio,
      );
    } finally {
      image.dispose();
    }
  } finally {
    picture.dispose();
    paragraph.dispose();
  }
}
