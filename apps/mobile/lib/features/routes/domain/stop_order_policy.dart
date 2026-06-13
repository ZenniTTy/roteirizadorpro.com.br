/// Constraint de posição da parada na rota (fato F16, dump v3.65.1):
/// Primeira / Automática / Última. O default semântico é [auto].
///
/// DISTINTO de `Stop.priority` (prioridade de atendimento do solver,
/// consumida no Slice 3) — ver hardening H4 do spec da Área 6.
enum StopOrderPolicy { first, auto, last }
