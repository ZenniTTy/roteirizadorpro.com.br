# Session 2026-05-28-04 — Area 4 (add-stop TEXT) MS1 + planning artifacts

## Metadata

- **Date:** 2026-05-28 (America/Sao_Paulo)
- **Sequence:** 04
- **Agent:** Claude Code (Opus 4.7, ultracode on)
- **Human:** Eduardo
- **Topic:** Area 4 discovery + spec + plan + MS1 (Domain layer)
- **Duration:** ~3h (acumulado no dia — 4ª sessão consecutiva sem reset)
- **Related ADRs:** ADR-0035 (Spoke parity hierarchy), ADR-0036 (parity gate), ADR-0037 (Maestro MCP inspection)
- **Related TODO items:** Slice 2 Area 4 — TEXT method

## Goal of the Session

Iniciar Area 4 do Slice 2 (Add stop via TEXT method) após Area 2 (drawer + wizard) ter sido shipped em `cd37a65`. Sessão dividida em planejamento (discovery → spec → plan) + execução do MS1 (Domain layer puro Dart).

## What Was Done

1. **Discovery workflow paralela** (4 agents): estado factual do código + spoke-parity-checker D1 UPFRONT + Context7 Flutter Autocomplete + Context7 Riverpod 3 active-entity. Resultado: discovery report com 7 inventory amendments + 6 perguntas pra Eduardo.
2. **7 decisões de escopo fechadas** via `AskUserQuestion` (2 rounds de 4+3). Resumo: manter Google Places real (não regredir pra stub), adiar edit-stop auto-open pra Area 6, implementar Section A com tap stubbed, footer wirado pro stub do mapa existente, microcopy condicional, transição polish-pass, spec formal.
3. **Inventário `docs/inventory/2026-05-26-spoke-vs-rotpro.md` amended** com 7 D1 findings (§10.21 + §11.4): 3 estados em vez de 2, 2 seções nos resultados, threshold 2 chars, footer "Escolher no mapa" persistente, search bar reativa, microcopy varia, BIG FIND clarificado (inline, não navigation push).
4. **Spec formal** criado em `docs/superpowers/specs/2026-05-28-area4-add-stop-text-method.md`. Status: aprovado por Eduardo.
5. **Plan formal** criado em `docs/superpowers/plans/2026-05-28-area4-add-stop-text-method.md` — 12 tasks bite-sized + 4 microsprints + TDD em cada.
6. **MS1 executada** via `superpowers:subagent-driven-development` (fresh subagent per task + 2-stage review):
   - Task 1: `AddStopUiState` sealed class + 5 variants — commit `d0331a3`.
   - Task 1 fix: payload tests load-bearing pra Task 2 — commit `220479d`.
   - Task 2: `AddStopUiState.from` factory + 5-branch derivation — commit `bc27ba7`.
   - Task 2 fix: invariant tests (empty>>loading + fullAddress OR branch) — commit `19abe5e`.

## Decisions Made

1. **Manter Google Places real** em vez de regredir pra stub hardcoded — código funcional já existe; custo até Slice 3 trocar por Nominatim é aceito (Q1 spec).
2. **`context.pop()` após criar stop** — adiar inline DraggableScrollableSheet auto-open pra Area 6 (Q2). Documentado como gap conhecido em spec §"Open items for Area 6".
3. **Section "Desta rota" com tap stubbed** (SnackBar "Editar parada em breve") — parity estrutural agora, tap funcional quando Area 6 chegar (Q3).
4. **Footer "Escolher no mapa"** wirado pro stub `/home/routes/add-stop/map` existente — Area 5 troca o destino, não a row (Q4).
5. **Microcopy condicional** baseado em `stopCount` — parity completa em vez de "ajustar depois" (Q5).
6. **Transição GoRouter default** — slide-from-bottom de Spoke fica pro polish pass final (Q6).
7. **Spec + plan formais via superpowers** — registrar BIG FIND adiamento, decisões + open items pra Area 6 não perder contexto (Q7).
8. **Sealed `AddStopUiState`** em vez de `AsyncValue.when` direto no widget — pattern matching exhaustivo (Dart compiler enforça branches). Primeira sealed class do projeto.
9. **Naming `EmptyVariant` (não `Empty`)** — manter spec/plan consistentes; sibling-symmetry com `Loading`/`ZeroResults` é trade-off aceito por evitar churn em ~50 referências downstream. Code quality reviewer notou; decisão registrada.

## Open Questions Left

- Nenhuma. MS2/MS3/MS4 têm escopo fechado no plan.

## Files Changed

**Created:**
- `apps/mobile/lib/features/routes/application/add_stop_ui_state.dart` (89 linhas)
- `apps/mobile/test/features/routes/application/add_stop_ui_state_test.dart` (14 tests)
- `docs/superpowers/specs/2026-05-28-area4-add-stop-text-method.md`
- `docs/superpowers/plans/2026-05-28-area4-add-stop-text-method.md`

**Modified:**
- `docs/inventory/2026-05-26-spoke-vs-rotpro.md` — anexos "Audit amendments 2026-05-28" em §10.21 e §11.4 (não reescrita; preserva passada original)
- `TODO.md` — desagregação Slice 2 por Area + status MS1

## Process erros desta sessão (pra não repetir)

> Trigger pra próxima sessão: ao terminar uma microsprint (grupo de tasks com 2-stage review aprovados), ANTES de iniciar a próxima task, executar o checkpoint discipline antes que Eduardo precise pedir.

1. **Não fiz `git push` após MS1 completo.** 4 commits ficaram só local até Eduardo perguntar "atualizou docs e harness?". Risco: perda total se laptop morresse. **Correção:** push imediato após cada MS (não no fim do PR). Persisted em `lesson_checkpoint_discipline_between_microsprints.md`.
2. **TODO.md não atualizado durante o trabalho.** Status canônico ficou desatualizado por ~3h. **Correção:** atualizar TODO no checkpoint de cada MS — entry de "em andamento" enquanto trabalha, marcar `[x]` quando MS fecha. Coberto pela mesma lesson acima.
3. **Sem session log durante o trabalho.** Eu defendia "session log opcional pós-reset" mas Eduardo enforçou "documentar tudo, nada esquecido". **Correção:** criar session log incremental no checkpoint de cada MS (este arquivo é o exemplo retroativo). Coberto pela mesma lesson acima.

## Carry-over pra próxima sessão (MS2)

- Próxima task: Task 3 do plan — `searchQueryProvider` (Riverpod 3 codegen, simple String state).
- Comando primário pra retomar: `Skill superpowers:subagent-driven-development` → continuar TDD per task.
- Pre-flight ainda válido: baseline tests 52→66 (incluindo +14 MS1) verde; analyze clean em arquivos novos; pre-existing warnings em outras telas tolerados.
- Branch `feat/m2-slice-2-area-4-add-stop-text` está pushed e tracking origin.
