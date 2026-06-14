# 2026-06-13-01 — Área 7 (Otimizar rota): spec + plano do PR-A

## Metadata

- **Date**: 2026-06-13 (America/Sao_Paulo)
- **Sequence**: 01
- **Agent**: Claude Code
- **Human**: Eduardo
- **Topic**: Área 7 — Otimizar rota (brainstorming → spec → plano do PR-A)
- **Related ADRs**: ADR-0051 (a filar na T1 do PR-A) · herda ADR-0030 (paywall só em Navegar), ADR-0035 (white-label), ADR-0042 (numpad reuso), ADR-0045 (dump-first), ADR-0049 (D4 dump-only)
- **Related TODO items**: "Area 7 (Otimizar rota — 3 estados + 3 FTUE modals)"

## Goal of the Session

Iniciar a Área 7 do Slice 2 com disciplina dump-first: ler o dump do Spoke, confirmar o funil dinâmico ao vivo, e produzir a spec + o plano de implementação ANTES de qualquer código. Mergear o PR #29 pendente.

## What Was Done

- **PR #29 mergeado** (microcopy "Quer mesmo remover" da Á6) + branch deletada. `develop` em `10a8a75`.
- **Dump-first da Á7**: MASTER-TABLE #20 + deep-grep no `~/spoke-dump/jadx-out` (`OptimizationController`, `RouteState.kt`, `OptimizationState.kt`, `OptimizeType.kt`, `OptimizeDirection.kt`, `optimizationexplainer`, strings `optimizing_*`/`optimization_*`/`refine_route_*`/`order_stop_groups_*`/`load_vehicle_*`).
- **spoke-parity-checker UPFRONT** (Maestro MCP no M54): confirmou o funil ao vivo e me corrigiu 3×.
- **Brainstorming** (skill): 9 decisões travadas (Q1-Q9). Validação dump-first CORRIGIU minha proposta inicial de enum linear → `RouteState` flags+timestamps fiel ao Spoke.
- **Spec escrita** (`docs/superpowers/specs/2026-06-13-area7-optimize-route-design.md`).
- **Triagem adversarial dos gaps** (workflow `whyvfc40t`, 7 agentes vs dump): das 7 "correções" que levantei, 4 reais (G1/G2/G3/G5), 2 de clareza (G4/G6), 1 overengineering (G7, cortada). 3 premissas minhas provadas FALSAS pelo dump. Spec corrigida.
- **Plano do PR-A escrito** (`docs/superpowers/plans/2026-06-13-area7-pr-a-state-solver-cta.md`): 13 tasks TDD red→green.

## Decisions Made

1. **Lifecycle = `RouteState` fiel ao Spoke** (flags+timestamps + `OptimizationState{creating,optimized,editing}`), NÃO enum linear. Estado visual derivado por getters. Prova: `core/entity/RouteState.java`/`OptimizationState.java`.
2. **Solver = `LocalRouteOptimizer` Dart on-device** (NN+2-opt, Haversine via geolocator já instalado) atrás da interface `RouteOptimizer`. Slice 3 troca por GraphHopper sem tocar UI. Prova: `OptimizationRoutingSolver{GOOGLE_MAPS,GRAPH_HOPPER}` — o Spoke alterna solvers nativamente.
3. **"Refinar" ≠ "Reotimizar"** — dois sheets distintos (lição travada em memória). Refinar (rodapé) = Inverter/Ordenar-manual; Reotimizar (kebab) = Atualizar/Reotimizar.
4. **4 PRs sequenciais**, plano por PR (não monolítico). PR-A destrava tudo.
5. **Cortes honestos**: Carregar veículo (barcode/ML Kit) + Compartilhar tempo real (backend) = botão fiel + "Em breve" → Slice 3. OrderStopGroups (Ordenar manual) é REAL on-device (PR-D). Gate-10-paradas NÃO clonado (ADR-0030).
6. **6 gaps corrigidos na spec** (G1 guard mínimo; G2/G3 Editar=des-confirma + editing zera optimizedAt; G5 remoção deferida; G4 "X min"=display; G6 chip via PackageLabelFormat default Moderno).

## Open Questions Left

- [ ] §13.C.4 ("Refinar" opções) — RESOLVIDA pelo dump (era PENDENTE). Atualizar o roadmap/inventário no PR-A ou no fechamento da Á7.
- [ ] O `start` do solver usa o 1º stop como referência até o PR-B ligar a Partida real (débito declarado no plano T12).

## Files Changed

**Created (docs):**
- `docs/superpowers/specs/2026-06-13-area7-optimize-route-design.md`
- `docs/superpowers/plans/2026-06-13-area7-pr-a-state-solver-cta.md`

**Memory (fora do repo):**
- `lesson_area7_refinar_vs_reotimizar_two_dialogs.md` + `project_area7_planning_state.md` (+ pointers no MEMORY.md)

## Commits Pushed

```
0787dc4  docs(specs): design da Área 7 (Otimizar rota) — dump-first
57cb5be  docs(specs): corrige 6 gaps da spec Á7 (triagem adversarial)
5c53f76  docs(plans): plano do Á7 PR-A (estado + solver + CTA + progresso)
```

## Hand-off Notes for Next Session

- **Branch**: `feat/m2-slice-2-area-7-optimize` (pushada). Só docs até aqui — ZERO código de produção.
- **Próximo passo**: EXECUTAR o plano do PR-A (`docs/superpowers/plans/2026-06-13-area7-pr-a-state-solver-cta.md`), subagent-driven recomendado. 1ª task de código = T2 (enums).
- **Cuidado na T5**: migra `RouteStatus`→`RouteState` em ~10 arquivos de teste existentes (efeito amplo — mostrar resultado ao Eduardo antes de seguir).
- **NÃO re-fazer brainstorming**: as 9 decisões (Q1-Q9) estão travadas na spec. A Á7 é Spoke-fiel via dump; só perguntar o que o dump não cobre.

## Lições (candidatas a memória)

1. **Refinar ≠ Reotimizar** (já virou memória `lesson_area7_refinar_vs_reotimizar_two_dialogs`).
2. **Triagem adversarial pega premissas próprias erradas** — 3 das minhas 7 "correções" tinham premissa falsa, só caíram porque agentes foram ao dump. Ler o dump ANTES de afirmar vale pro próprio agente, não só pro implementador.
3. **`Stop.deliveryId` já existia** — a spec dizia "NEW" mas era MOD. Ler o arquivo real antes de planejar evita task errada.

## Reference Material Used

- Dump estático Spoke v3.65.1: `~/spoke-dump/jadx-out` (`core/entity/RouteState.kt`, `OptimizationState.kt`, `OptimizeType.kt`, `OptimizeDirection.kt`, `OptimizationRoutingSolver.kt`, `ui/home/editroute/optimization/`, `ui/home/editroute/lifecycle/`, `ui/home/editroute/orderstopgroup/`, `ui/loading/LoadVehicle*`) + `res-decoded/.../values-pt-rBR/strings.xml`.
- spoke-parity-checker report (Maestro MCP, M54, 2026-06-13).
- Dart MCP: `ReorderableListView.onReorderItem` confirmado da fonte 3.44.
- Workflow `whyvfc40t` (triagem adversarial dos 7 gaps).
