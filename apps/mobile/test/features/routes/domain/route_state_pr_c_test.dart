// test/features/routes/domain/route_state_pr_c_test.dart
//
// TDD red — PR-C sub-unidade 1: getters de RouteState.
//
// Comportamentos pinados:
//  - isReadyToRun relaxado: confirmed && !started && !completed
//    (não requer optimization==optimized — skip-path entra)
//  - isDraft ganha guard: confirmed==true ⇒ isDraft==false
//  - hasPendingOptimization (novo getter): isReadyToRun && optimization != optimized
//  - isPreConfirm (não-regressão): permanece optimization==optimized && !confirmed && !started
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/domain/optimization_state.dart';
import 'package:roteirizador_pro/features/routes/domain/route_state.dart';

void main() {
  group('isReadyToRun — caminho relaxado (PR-C)', () {
    test(
      'confirmed=true + optimization=creating + !started ⇒ isReadyToRun '
      '(skip-path: "Pular otimização" chega aqui)',
      () {
        const s = RouteState(
          optimization: OptimizationState.creating,
          confirmed: true,
        );
        expect(s.isReadyToRun, isTrue);
      },
    );

    test(
      'confirmed=true + optimization=optimized + !started ⇒ isReadyToRun '
      '(caminho normal — deve continuar verdadeiro)',
      () {
        const s = RouteState(
          optimization: OptimizationState.optimized,
          confirmed: true,
        );
        expect(s.isReadyToRun, isTrue);
      },
    );

    test(
      'confirmed=true + started=true ⇒ isReadyToRun=false '
      '(rota já em execução — Área 8)',
      () {
        const s = RouteState(
          optimization: OptimizationState.optimized,
          confirmed: true,
          started: true,
        );
        expect(s.isReadyToRun, isFalse);
      },
    );

    test(
      'confirmed=true + completed=true ⇒ isReadyToRun=false '
      '(rota concluída não pode reiniciar)',
      () {
        const s = RouteState(
          optimization: OptimizationState.optimized,
          confirmed: true,
          completed: true,
        );
        expect(s.isReadyToRun, isFalse);
      },
    );

    test(
      'confirmed=false ⇒ isReadyToRun=false '
      '(sem confirmar ainda é PRE-CONFIRM ou DRAFT)',
      () {
        const s = RouteState(
          optimization: OptimizationState.optimized,
          confirmed: false,
        );
        expect(s.isReadyToRun, isFalse);
      },
    );
  });

  group('isDraft — guard confirmed (PR-C)', () {
    test(
      'confirmed=true + optimization=creating ⇒ isDraft=false '
      '(rota confirmada nunca é draft, mesmo no skip-path)',
      () {
        const s = RouteState(
          optimization: OptimizationState.creating,
          confirmed: true,
        );
        expect(s.isDraft, isFalse);
      },
    );

    test(
      'confirmed=false + optimization=creating ⇒ isDraft=true '
      '(estado draft normal permanece)',
      () {
        const s = RouteState(
          optimization: OptimizationState.creating,
          confirmed: false,
        );
        expect(s.isDraft, isTrue);
      },
    );
  });

  group('hasPendingOptimization — novo getter (PR-C)', () {
    test(
      'confirmed=true + optimization=creating ⇒ hasPendingOptimization=true '
      '(skip-path: rota confirmada mas nunca otimizada → banner pendente)',
      () {
        const s = RouteState(
          optimization: OptimizationState.creating,
          confirmed: true,
        );
        expect(s.hasPendingOptimization, isTrue);
      },
    );

    test(
      'confirmed=true + optimization=optimized ⇒ hasPendingOptimization=false '
      '(otimizada+confirmada: sem banner)',
      () {
        const s = RouteState(
          optimization: OptimizationState.optimized,
          confirmed: true,
        );
        expect(s.hasPendingOptimization, isFalse);
      },
    );

    test(
      'draft (confirmed=false, optimization=creating) ⇒ hasPendingOptimization=false '
      '(não é ReadyToRun, getter é false)',
      () {
        const s = RouteState();
        expect(s.hasPendingOptimization, isFalse);
      },
    );

    test(
      'started=true ⇒ hasPendingOptimization=false '
      '(não é ReadyToRun porque started=true)',
      () {
        const s = RouteState(
          optimization: OptimizationState.creating,
          confirmed: true,
          started: true,
        );
        expect(s.hasPendingOptimization, isFalse);
      },
    );
  });

  group('isPreConfirm — não-regressão (PR-C)', () {
    test(
      'optimization=optimized + confirmed=false + started=false ⇒ isPreConfirm=true',
      () {
        const s = RouteState(
          optimization: OptimizationState.optimized,
        );
        expect(s.isPreConfirm, isTrue);
      },
    );

    test(
      'optimization=optimized + confirmed=true ⇒ isPreConfirm=false '
      '(confirmado sai do PRE-CONFIRM)',
      () {
        const s = RouteState(
          optimization: OptimizationState.optimized,
          confirmed: true,
        );
        expect(s.isPreConfirm, isFalse);
      },
    );

    test(
      'optimization=creating + confirmed=false ⇒ isPreConfirm=false '
      '(draft nunca é PRE-CONFIRM)',
      () {
        const s = RouteState(
          optimization: OptimizationState.creating,
        );
        expect(s.isPreConfirm, isFalse);
      },
    );
  });
}
