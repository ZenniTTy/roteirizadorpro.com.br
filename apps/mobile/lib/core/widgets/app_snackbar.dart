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

  // Dismiss defensivo — SÓ quando as animações do sistema estão desligadas
  // (`AccessibilityFeatures.disableAnimations`; no Android = animator/transition
  // scale 0, caso do M54 de teste do Eduardo). Nesse modo o auto-dismiss interno
  // do SnackBar — que é DIRIGIDO PELA ANIMAÇÃO de saída — não dispara e o toast
  // fica "preso" tampando o conteúdo. Um Timer próprio garante o fechamento.
  //
  // Com animações LIGADAS (incluindo todos os widget tests) o dismiss nativo já
  // funciona, então NÃO armamos timer extra — evita o "A Timer is still pending"
  // no teardown de testes que mostram o toast e terminam antes dos 3 s. Gate na
  // condição-do-bug = correto e test-safe (sem alterar dezenas de testes).
  final animationsDisabled =
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  if (animationsDisabled) {
    final timer = Timer(const Duration(seconds: 3), controller.close);
    // Se o toast sair antes (swipe / substituído por outro), cancela o Timer.
    controller.closed.whenComplete(timer.cancel);
  }
}
