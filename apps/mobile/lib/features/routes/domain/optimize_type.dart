/// Escopo de uma chamada ao solver — espelha `core/entity/OptimizeType.java`
/// do Spoke v3.65.1 VERBATIM (4 valores, na ordem do dump:
/// RESTART_ROUTE=0, REMAINING_STOPS=1, SKIP_REORDER=2, REORDER_FLEXIBLE=3).
///
/// - `restartRoute` — recalcula do zero ("Reotimizar rota", kebab).
/// - `remainingStops` — re-otimiza preservando os grupos desenhados em
///   "Ordenar a rota manualmente" (OrderStopGroups, PR-D — ver
///   `EditRouteViewModel.mo9471v`/`OptimizationController` no dump).
/// - `skipReorder` — pula a otimização (mantém a ordem atual).
/// - `reorderFlexible` — preserva a estrutura ("Atualizar rota").
enum OptimizeType { restartRoute, remainingStops, skipReorder, reorderFlexible }
