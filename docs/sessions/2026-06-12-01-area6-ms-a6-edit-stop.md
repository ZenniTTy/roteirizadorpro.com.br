# 2026-06-12-01 — Área 6 (MS-A6): Editar parada — execução T13–T20 + fechamento

**Branch:** `feat/m2-slice-2-area-6-edit-stop` → PR contra `develop`
**Plano executado:** `docs/superpowers/plans/2026-06-11-area6-edit-stop-plan.md` (20 tasks, TDD red→green por task)
**Spec:** `docs/superpowers/specs/2026-06-11-area6-edit-stop-design.md` (F1–F16/D1–D8/H1–H21)

## O que aconteceu

Execução das tasks T13–T20 (T1–T12 na sessão 2026-06-11). Cada task: `flutter-test-author` (RED) → implementação → GREEN → commit. Suíte foi de 460 → **606 testes**; analyze constante em **23 lints** (MS-DEBT pré-existente, zero novos). Fechamento completo: perf-auditor (0 must-fix; should-fixes aplicados), D4 `spoke-parity-checker` dump-only (0 must-fix, F1–F16 conformes), `adr-guardian` PASS (ADR-0050 cobre `path_provider`), `integration_test/area6_edit_stop_flow_test.dart` verde no M54, smoke E2E release no M54 com golden path completo (criar rota → add stop → editar tudo → duplicar → remover).

## Decisões / débito aceito

- **2 fixes FORA do escopo Á6** entraram na branch, justificados pelo gate do smoke (golden path do plano os exige) + diretriz zero-débito:
  1. `scripts/build-release-apk.sh` não injetava `MAPS_API_KEY` → release com Places quebrado em runtime. Script agora lê do ambiente/`.env` e falha cedo se ausente.
  2. Wizard "Criar rota" não tornava a rota criada ATIVA (`setActiveRoute` só existia no tap do drawer) → "Adicionar parada" pós-create falhava com "Nenhuma rota ativa selecionada". Paridade Spoke ancorada no dump: `RouteCreateViewModel.createRoute` → `AbstractC3206a.c(RouteId)` → `RouteCreateFragment.java:186-193` entrega o id ao caller e o shell renderiza ESSA rota. Teste de widget pina o contrato.
- Microcopy nossa corrige o typo "Direta" do dump (`place_in_vehicle_right`) para "Direita" (ADR-0010 — microcopy original).
- Smoke criou 2 rotas + paradas na conta de produção do Eduardo — estado é **in-memory only** (persistência é Slice 3); some ao matar o app.

## Lições (candidatas a memória, já gravadas onde aplicável)

1. **Teclado Samsung intercepta taps do Maestro sobre a área de conteúdo** — a janela do honeyboard cobre mais do que desenha; taps em rows visíveis "não disparam". Sempre `hideKeyboard` antes de tap em resultado de busca. (O diagnóstico definitivo veio de `adb shell input tap` + screencap a 1s flagrando a SnackBar real.)
2. **`flutter-test-author` morreu no meio do dispatch 3× nesta sessão** (T7 na sessão anterior, T15/T16 nesta) — sempre verificar `git status` + estado dos arquivos após retorno de subagent e completar o gate (RED run + analyze) manualmente.
3. **Smoke E2E de release é gate de verdade**: pegou 2 gaps cross-área que 606 testes host + integration_test não viam (ambos eram de wiring de produção: dart-define e ativação de rota).
4. Lição Maestro adicional: `.at(0)` em finder composto aplica-se ANTES do `descendant` — escopo primeiro, índice depois.

## Estado ao fim

- T20e/T20f: docs sweep (roadmap Á6 ✅, TODO, inventário §10.5/§10.6 amendments, este log) + PR → develop.
- Próxima área: Á7 (Otimizar rota) — dependências Á6 (chips A1/A2) e Á3 (CTA Otimizar, slot do footer nasce lá) satisfeitas.
