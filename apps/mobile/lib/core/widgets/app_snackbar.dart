import 'dart:async';

import 'package:flutter/material.dart';

// CONTRACT (defined by flutter-test-author for bug fix "snackbar não
// auto-dismiss / cobre conteúdo"):
//
// [showAppSnackBar] é o único ponto de entrada para SnackBars no app.
// Requisitos:
//   behavior  — SnackBarBehavior.floating  (não cobre a bottom nav)
//   duration  — const Duration(seconds: 3) (auto-dismiss em 3 s)
//   action    — parâmetro opcional; quando fornecido, é exibido no SnackBar
//
// O implementador deve usar ScaffoldMessenger.of(context).showSnackBar(...)
// com os parâmetros acima. NÃO deixar os defaults do Material (4 s / fixed).
void showAppSnackBar(
  BuildContext context,
  String message, {
  SnackBarAction? action,
}) {
  final messenger = ScaffoldMessenger.of(context)
    // Substitui o toast anterior em vez de enfileirar — um toast novo não
    // espera 3 s o anterior sair (o que o Eduardo percebeu como "preso").
    ..hideCurrentSnackBar();

  final controller = messenger.showSnackBar(
    SnackBar(
      // `floating` flutua acima do conteúdo inferior (FAB/barra) em vez de
      // empurrá-lo — o default `fixed` é o que tampava o conteúdo.
      behavior: SnackBarBehavior.floating,
      // 3 s: auto-dismiss curto (o default do Material é 4 s, que o usuário
      // percebeu como "não some").
      duration: const Duration(seconds: 3),
      content: Text(message),
      action: action,
    ),
  );

  // Dismiss defensivo: em devices com animações desligadas
  // (developer options → animator_duration_scale = 0, caso do M54 de teste) o
  // auto-dismiss interno do SnackBar — que é dirigido pela animação de saída —
  // não dispara e o toast fica "preso" na tela. Um Timer próprio garante o
  // fechamento independente do estado das animações. `close()` é no-op seguro
  // se o toast já saiu ou foi substituído por outro.
  final timer = Timer(const Duration(seconds: 3), controller.close);
  // Se o toast sair naturalmente antes (animações on, swipe, ou substituído por
  // outro toast), cancela o Timer pra não deixar timer pendente.
  controller.closed.whenComplete(timer.cancel);
}
