import 'optimization_state.dart';

/// Lifecycle da rota — espelha `core/entity/RouteState.java` do Spoke v3.65.1
/// (flags + timestamps ortogonais). O estado VISUAL (DRAFT/otimizando/
/// PRE-CONFIRM/Ready-to-Run/erro) é DERIVADO por getters, nunca armazenado.
///
/// O Spoke tem 14 campos no construtor; modelamos os 9 que o FUNIL DE
/// OTIMIZAÇÃO usa (Á7). Os 2 timestamps de auditoria do ciclo de execução —
/// `startedAt` (quando "Iniciar rota" dispara, Á8) e `completedAt` (conclusão,
/// Á9) — são adicionados quando essas áreas introduzirem a lógica que os lê;
/// como esta é uma classe imutável com `copyWith` e campos nullable, acrescentá-
/// los depois NÃO é breaking change. Campos atuais espelham o `toString()` do
/// Spoke: started/optimizedAt/completed/optimization/optimizing/
/// optimizationErroredAt/optimizationAttemptedAt/optimizationAcknowledged/
/// confirmed.
class RouteState {
  const RouteState({
    this.optimization = OptimizationState.creating,
    this.optimizing = false,
    this.optimizationAcknowledged = false,
    this.confirmed = false,
    this.started = false,
    this.completed = false,
    this.optimizedAt,
    this.optimizationErroredAt,
    this.optimizationAttemptedAt,
  });

  final OptimizationState optimization;
  final bool optimizing;
  final bool optimizationAcknowledged;
  final bool confirmed;
  final bool started;
  final bool completed;
  final DateTime? optimizedAt;
  final DateTime? optimizationErroredAt;
  final DateTime? optimizationAttemptedAt;

  // Estado visual derivado (switch exaustivo na UI usa estes getters).
  bool get isDraft =>
      optimization == OptimizationState.creating && !optimizing && !started;
  bool get isOptimizing => optimizing;
  bool get isPreConfirm =>
      optimization == OptimizationState.optimized && !confirmed && !started;
  bool get isReadyToRun =>
      optimization == OptimizationState.optimized && confirmed && !started;
  bool get isEditing => optimization == OptimizationState.editing;
  bool get hasOptimizationError => optimizationErroredAt != null && !optimizing;

  RouteState copyWith({
    OptimizationState? optimization,
    bool? optimizing,
    bool? optimizationAcknowledged,
    bool? confirmed,
    bool? started,
    bool? completed,
    Object? optimizedAt = _omit,
    Object? optimizationErroredAt = _omit,
    Object? optimizationAttemptedAt = _omit,
  }) {
    return RouteState(
      optimization: optimization ?? this.optimization,
      optimizing: optimizing ?? this.optimizing,
      optimizationAcknowledged:
          optimizationAcknowledged ?? this.optimizationAcknowledged,
      confirmed: confirmed ?? this.confirmed,
      started: started ?? this.started,
      completed: completed ?? this.completed,
      optimizedAt: identical(optimizedAt, _omit)
          ? this.optimizedAt
          : optimizedAt as DateTime?,
      optimizationErroredAt: identical(optimizationErroredAt, _omit)
          ? this.optimizationErroredAt
          : optimizationErroredAt as DateTime?,
      optimizationAttemptedAt: identical(optimizationAttemptedAt, _omit)
          ? this.optimizationAttemptedAt
          : optimizationAttemptedAt as DateTime?,
    );
  }

  // Sentinela para o copyWith distinguir "omitido" de "null explícito"
  // (mesmo idiom de Stop.copyWith — lesson_copywith_nullable_field_pitfall).
  static const _omit = Object();
}
