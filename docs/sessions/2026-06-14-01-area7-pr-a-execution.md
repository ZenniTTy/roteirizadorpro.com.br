# 2026-06-14-01 — Área 7 PR-A: execução (estado + solver + CTA + progresso)

## Metadata

- **Date**: 2026-06-14 (America/Sao_Paulo)
- **Sequence**: 01
- **Agent**: Claude Code
- **Human**: Eduardo
- **Topic**: Área 7 PR-A — execução subagent-driven
- **Related ADRs**: ADR-0051 (filada na T1) · herda ADR-0010/0030/0035/0045
- **Related TODO items**: "Area 7 (Otimizar rota)" → sub-bullet PR-A

## Goal of the Session

Executar o plano do PR-A da Área 7 (`docs/superpowers/plans/2026-06-13-area7-pr-a-state-solver-cta.md`) task-by-task via `superpowers:subagent-driven-development` (subagente fresco por task, TDD red→green via `flutter-test-author` → implementer, review entre tasks), e abrir o PR mirando `develop`. Zero brainstorming novo — as 9 decisões (Q1-Q9) estavam travadas na spec.

## What Was Done

- **13 tasks executadas** (1 ADR + 11 de código TDD + 1 de gates), cada uma com `flutter-test-author` escrevendo o teste RED primeiro (stub `UnimplementedError`, nunca lógica de produção) e um implementer fazendo o GREEN + commit próprio.
- **Reviews adversariais** entre tasks: spec-compliance + code-quality nos pontos de risco (Task 3 PackageLabelFormat, Task 5 migração, Task 7 solver, Task 12 integração no shell).
- **Suite:** baseline 606 → 638 testes verdes. `flutter analyze`: 24 issues, **zero lint novo** do PR-A.
- **Gates do PR-A:** `flutter-perf-auditor` (1 must-fix + 1 should-fix), `adr-guardian` (PASS, sem dep nova). PR #30 aberto → `develop`.

## Decisions Made

1. **`RouteOptimizer.optimize()` virou `Future` (pós-review)** — o `flutter-perf-auditor` apontou must-fix: solver síncrono na UI thread. Decisão (validada com Eduardo: "boas práticas modernas + seguir o Spoke"): tornar a interface assíncrona — fiel ao solver de **backend** do Spoke (`OptimizationRoutingSolver{GOOGLE_MAPS, GRAPH_HOPPER}`), evita breaking change no swap GraphHopper do Slice 3. **SEM `Isolate`** — seria overengineering p/ ≤20 paradas B2C (cap/Isolate fica como otimização *medida* do Slice 3 se houver jank em rotas grandes).
2. **Algoritmo Moderno do `PackageLabelFormat` divergia do plano** — o corpo do plano tinha `letra=index%26`/`num=index~/26+1`, que produz 'A2'/'Z1' em vez de 'B1'/'A26'. O **teste** é o contrato (A1..A26→B1); corrigido para `letra=index~/26`, `num=index%26+1`.
3. **Bug do review da Task 12 corrigido** — `_onOptimize` descartava o retorno de `showOptimizationErrorDialog` ("Tentar de novo" virava no-op silencioso). Agora `retry` re-roda o solver; `skip` mostra SnackBar honest-stub (Ready-to-Run + banner é PR-C).
4. **Migração `RouteStatus`→`RouteState` (Task 5)** pegou 2 desvios reais do plano, ambos acertos do implementer: `5200 as double?` lançava em runtime (Dart não faz cast int→double) → `(… as num?)?.toDouble()`; 2 leituras de `.status` que o grep de `RouteStatus` não pegava.
5. **`hasRoomForCta` no shell (Task 12)** — um teste pré-existente (H6-iii) deu overflow de 13px durante o drag de colapso porque o CTA é o 1º footer fixo do caminho `stops.isNotEmpty`. Gate de altura adicionado (mesmo princípio do `showButtons` existente) — não esconde o CTA em medium/expanded de repouso.

## Auditoria dump-first PÓS-PR (3 divergências encontradas e corrigidas)

Depois de abrir o PR, uma re-verificação direta contra `~/spoke-dump/jadx-out` + `res-decoded/.../values-pt-rBR/strings.xml` (NÃO confiando que a spec/plano da sessão anterior tinham capturado tudo) achou **3 divergências reais** que passaram na execução porque vieram da spec e eu não re-conferi contra a fonte:

1. **`OptimizeType` faltava `REMAINING_STOPS`** (commit `edec273`) — o dump tem **4** valores (`RESTART_ROUTE/REMAINING_STOPS/SKIP_REORDER/REORDER_FLEXIBLE`), eu implementei 3. `REMAINING_STOPS` é o type da re-otimização por grupos (OrderStopGroups, PR-D — `EditRouteViewModel.mo9471v`). O teste usava `containsAll` (mascarou a ausência) → trocado por **lista exata na ordem do dump**. Divergência funcional que morderia no PR-D.
2. **4 fases de progresso ESTAVAM VERBATIM do Spoke pt-rBR** (commit `03e2c14`) — `optimizing_analysing`="Analisando suas paradas...", `_sorting`="Encontrando a melhor ordem...", `_traffic`="Considerando o trânsito...", `_creating`="Criando sua rota..." são EXATAMENTE as strings traduzidas do Circuit. Violava a ADR-0010 (microcopy original). Reescrito: "Conferindo suas entregas..." / "Montando a melhor sequência..." / "Avaliando o trânsito na região..." / "Finalizando sua rota...".
3. **Corpo do `NotEnoughStopsDialog` quase-verbatim** (commit `03e2c14`) de `optimize_route_minimum_stops_body` ("Para otimizar sua rota, adicione 1 ou mais paradas além do ponto de partida e destino") — reformulação fraca demais. Reescrito 100% original.

Confirmados OK (já eram originais): `OptimizationErrorDialog` (título/corpo ≠ `optimization_failed_*`), "Tentar de novo" (Spoke usa "Tente novamente"/"Repetir"), "Pular otimização" (sem equivalente). `RouteState` reduzido (9 de 14 campos do Spoke) é **corte consciente** — `startedAt`/`completedAt` pertencem à Á8/Á9; doc-comment atualizado para registrar (adicioná-los depois não é breaking change). **Lição:** spec/plano de uma sessão anterior NÃO substituem re-conferir o dump na execução — a inferência (mesmo "dump-first" na origem) decai; toda microcopy PT-BR tem de ser comparada 1:1 com `values-pt-rBR/strings.xml` antes de "original".

## Open Questions Left

- [ ] PR #30 aguarda review/merge + Vercel preview. O plano do PR-B (PRE-CONFIRM) só se escreve após o #30 mergear na `develop`.
- [ ] `RouteState` sem `==`/`hashCode` — hoje comparações por identidade são legítimas; reavaliar (Equatable) se o PR-B comparar estados montados separadamente.

## Files Changed

**Created (produção):** `route_state.dart`, `optimization_state.dart`, `optimize_type.dart`, `optimize_direction.dart`, `package_label_format.dart`, `optimization/route_optimizer.dart`, `optimization/local_route_optimizer.dart`, `state/optimization_controller.dart`, `presentation/widgets/{optimize_cta,optimizing_progress_view,not_enough_stops_dialog,optimization_error_dialog}.dart` (+ os testes pareados).

**Modified:** `domain/route.dart` (RouteStatus→RouteState + métricas), `domain/stop.dart` (+pendingRemoval), `state/routes_provider.dart`, `presentation/route_shell_page.dart` (CTA + handler), `TODO.md`, ~10 testes existentes (migração do enum).

**Created (docs):** `docs/decisions/0051-route-lifecycle-and-on-device-solver.md`.

## Commits Pushed

15 commits Conventional (de `539e24f` ADR-0051 a `0210cd8` TODO). Branch `feat/m2-slice-2-area-7-optimize` → PR #30.

## Hand-off Notes for Next Session

- **PR #30 aberto** (base `develop`, OPEN). Após merge: escrever o plano do PR-B (PRE-CONFIRM + FTUE numeração + Refinar≠Reotimizar [[lesson_area7_refinar_vs_reotimizar_two_dialogs]] + remoção deferida G5).
- **No PR-B:** montar `OptimizingProgressView` no shell + isolar o `CircularProgressIndicator` num `RepaintBoundary` (should-fix do perf-auditor adiado, pois o widget só é montado lá).
- **Lição de processo:** subagentes que fazem `cd apps/mobile && git add apps/mobile/test/...` perderam arquivos de teste (path errado pós-cd); recolhidos depois. Verificar `git show <sha> --stat` por task — ver memória `lesson_subagent_git_add_cwd_drops_test_files`.

## Reference Material Used

- Dump estático Spoke v3.65.1 (`~/spoke-dump/jadx-out` — baseline veio da sessão de spec 2026-06-13-01).
- Dart MCP (`ReorderableListView.onReorderItem` confirmado), spec/plano da Á7.
- `flutter-test-author`, `flutter-perf-auditor`, `adr-guardian`, `feature-dev:code-reviewer` (subagentes).
