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
  ScaffoldMessenger.of(context)
    // Substitui o toast anterior em vez de enfileirar — um toast novo não
    // espera 3 s o anterior sair (o que o Eduardo percebeu como "preso").
    ..hideCurrentSnackBar()
    ..showSnackBar(
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
}
