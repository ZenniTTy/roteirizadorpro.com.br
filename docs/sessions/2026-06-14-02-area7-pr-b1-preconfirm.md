# 2026-06-14-02 — Área 7 PR-B1: PRE-CONFIRM estrutura (execução subagent-driven + gates)

## Metadata

- **Date**: 2026-06-14 (America/Sao_Paulo)
- **Sequence**: 02
- **Agent**: Claude Code
- **Human**: Eduardo
- **Topic**: Área 7 PR-B1 — PRE-CONFIRM (aplicar otimização + FTUE + Refinar/Reotimizar + remoção deferida G5)
- **Related ADRs**: herda ADR-0035/0045/0051 (nenhuma nova — sem mudança de stack)
- **Related TODO items**: "Area 7 (Otimizar rota)" → sub-bullet PR-B1

## Goal of the Session

Executar o PR-B1 da Área 7 (`docs/superpowers/plans/2026-06-14-area7-pr-b1-preconfirm-structure.md`, 12 tasks TDD) — a ESTRUTURA do estado PRE-CONFIRM sem o mapa pesado (que é o PR-B2). Continuação direta do PR-A (já mergeado, PR #30). T1-T4 já estavam verdes no início da sessão.

## What Was Done

- **T5–T10 via Workflow (ultracode):** 6 widgets/repos TDD (RED stub `UnimplementedError` → GREEN com microcopy travada → revisão adversarial de spec+microcopy+qualidade), 18 agents. Sem commits pelos subagents — o controller commitou cada task da raiz após verificar (lição `lesson_subagent_git_add_cwd_drops_test_files`).
- **T11 (wire no shell) inline:** o ponto de maior risco (já teve bug silencioso no PR-A), feito à mão com leitura cuidadosa do shell real + auto-revisão adversarial.
- **Gates (T12):** `flutter-perf-auditor` + `spoke-parity-checker` D4 dump-only em paralelo. Ambos acharam achados reais (ver abaixo).
- **Suite:** 638 → **670** testes verdes. `flutter analyze` sem lint novo.

## Decisions Made

1. **Microcopy reformulada (re-auditoria dump-first ANTES de codificar).** A re-conferência 1:1 contra `values-pt-rBR/strings.xml` pegou **"Inverter a rota" VERBATIM** (`refine_route_dialog_reverse_title`) + 2 near-verbatim no plano. Eduardo: "siga as boas práticas" → reformular TUDO (zero colisão): "Inverter a ordem"/"Definir a ordem na mão"/"Recalcular do zero"/"Ajustar o que mudou"/"Ajustar a rota"/"Como recalcular"/"Ajustar formato". Travado no plano antes da orquestração.
2. **Solver/FTUE async sem overengineering** — o provider FTUE usa o idiom `SharedPreferencesAsync` existente; sem dep nova.
3. **G5 reclassificado must-fix (decisão Eduardo: "tudo igual ao Spoke").** O spoke-parity-checker apontou que o `edit_stop_page` removia a parada IMEDIATAMENTE mesmo em rota otimizada — divergência observável (o Spoke defere p/ a próxima otimização). O `ConfirmDeferredRemovalDialog` + `markStopForDeferredRemoval` já existiam (faltava o ramo). Wirado neste PR: rota otimizada → deferida; DRAFT → imediata.
4. **Kebab "Reotimizar" NÃO wirado — o dump contradisse a premissa do should-fix.** Investigação no jadx (`EditRouteFragment$Content$2$1` → `ReoptimizeRouteDialog`; `EditRouteFragment$MapSection$1$10$1` → `OrderStopGroupsOptimizeButtonType.Reoptimize`; `EditRoutePage.ReoptimizeOrderStopGroups`) provou que no Spoke o trigger vive no **OrderStopGroups (PR-D) + toolbar do mapa (PR-B2)**, NÃO num kebab solto do PRE-CONFIRM. Wirar agora seria inventar UI (drift estrutural). Eduardo: "evite drifts" → caller adiado p/ onde o Spoke ancora. O `ReoptimizeOptionsSheet` fica pronto+testado.
5. **Perf must-fix:** `ref.watch(activeRouteStateProvider)` lia o `RouteState` inteiro (9 campos, sem `==`) p/ um getter → `.select((s) => s?.isPreConfirm ?? false)`. Resolve pragmaticamente o débito (g) do PR-A (sem Equatable).

## Bugs/achados pegos pelos gates e revisões (e corrigidos)

1. **Bug do teste T6** (revisão code-reviewer, conf. 100): o helper `openDialog` retornava `captured` ANTES do tap (o `await showIdEducationDialog` ainda suspenso) → `choice` sempre `null` → as 2 asserções de tap nunca passariam. A verificação REAL em disco confirmou (17/19 passavam). Reescrito no padrão do sibling `confirm_deferred_removal_dialog_test` (variável de escopo lida após o tap).
2. **Bug silencioso no `_onRefine`** (auto-revisão): o ramo `invert` engolia `OptimizationFailure` sem feedback (`if (outcome is OptimizationSuccess)` sem else). Corrigido: switch exaustivo nos 3 outcomes (sucesso aplica; falha → diálogo de erro com retry; G1 → diálogo). Mesmo failure mode do "Tentar de novo" do PR-A.
3. **Regressão dos testes 18.4/18.6** (G5): o `_buildApp` do `edit_stop_page_test` hard-codava `OptimizationState.optimized` p/ TODA rota → com o G5, esses testes (que exercem remoção IMEDIATA) caíram no fluxo deferido e quebraram. Causa raiz: o estado otimizado era acidente do helper, não requisito do teste. Corrigido: `_buildApp` parametrizado por `routeState` (default mantém otimizada p/ os ~70 outros testes); 18.4/18.5/18.6 → DRAFT; +18.7/18.8 cobrindo o ramo deferido.
4. **Entropia de lint** (trailing commas) nos testes T1/T3/T4 do PR-A — peguei na auditoria de abertura da sessão e corrigi cirurgicamente (só os 3 testes meus; revertido o que o `dart fix` tocou em arquivos de outros PRs).

## Open Questions Left

- [ ] PR-B1 aguarda review/merge. PR-B2 (mapa + polyline + markers numerados) + PR-C (Ready-to-Run) + PR-D (OrderStopGroups) depois.
- [ ] O wire do kebab Reotimizar + do "Ordenar manualmente" entra no PR-B2/PR-D no ponto Spoke-fiel.

## Files Changed

**Created (produção):** `state/optimization_ftue_repository.dart` (+ provider), `presentation/widgets/{id_education_dialog,refine_route_sheet,reoptimize_options_sheet,confirm_deferred_removal_dialog,pre_confirm_view,route_summary_row,delivery_id_chip}.dart` (+ testes pareados). *(T1-T4 já na sessão anterior.)*

**Modified:** `state/routes_provider.dart` (applyOptimization + markStopForDeferredRemoval — T1), `state/active_route_state_provider.dart` (T2), `presentation/route_shell_page.dart` (switch + `_onOptimize`/`_onRefine`/`_onConfirm` + `.select`), `presentation/pages/edit_stop_page.dart` (G5 ramo deferido), `edit_stop_page_test.dart` (18.4-18.6 DRAFT + 18.7/18.8 G5), `TODO.md`, `docs/10-CHANGELOG.md`, plano (microcopy travada).

## Commits Pushed

T1-T11 + perf + G5 + docs: de `3610270` (T1) a `a4f8cde` (G5). Branch `feat/m2-slice-2-area-7-pre-confirm` → PR-B1.

## Hand-off Notes for Next Session

- **PR-B2** monta o mapa+polyline+markers numerados no PRE-CONFIRM + (provavelmente) o toolbar onde o Spoke ancora o trigger de reotimização. **Wirar o `ReoptimizeOptionsSheet` lá** (já pronto+testado).
- **Lição:** o dump não respondeu só "o que existe" — respondeu "ONDE o trigger vive". Antes de wirar um widget pronto a um ponto de entrada, conferir no jadx ONDE o Spoke o ancora (o should-fix do parity-checker assumia kebab solto; o jadx provou OrderStopGroups/toolbar).
- **Lição reforçada:** revisão adversarial de subagent vale — pegou o bug do teste T6 que o GREEN não viu. Sempre verificar o estado REAL em disco (rodar a suite) em vez de confiar no relato "PASS" do implementer.

## Reference Material Used

- Dump estático Spoke v3.65.1 (`~/spoke-dump/jadx-out` + `res-decoded/.../values-pt-rBR/strings.xml`).
- `flutter-test-author`, `feature-dev:code-reviewer`, `flutter-perf-auditor`, `spoke-parity-checker` (subagentes via Workflow + dispatch direto).
- Plano `2026-06-14-area7-pr-b1-preconfirm-structure.md` + spec `2026-06-13-area7-optimize-route-design.md`.
