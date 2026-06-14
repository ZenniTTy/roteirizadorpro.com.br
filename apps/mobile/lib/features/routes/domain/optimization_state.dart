/// Estado de otimização da rota — espelha `core/entity/OptimizationState.kt`
/// do Spoke v3.65.1 (CREATING/OPTIMIZED/EDITING). Ortogonal às flags
/// `confirmed`/`started` do RouteState.
enum OptimizationState { creating, optimized, editing }
