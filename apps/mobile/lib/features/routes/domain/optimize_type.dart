/// Escopo de uma chamada ao solver — espelha `core/entity/OptimizeType.kt`
/// do Spoke. `restartRoute` recalcula do zero (Reotimizar), `reorderFlexible`
/// preserva a estrutura (Atualizar), `skipReorder` pula a otimização.
enum OptimizeType { restartRoute, reorderFlexible, skipReorder }
