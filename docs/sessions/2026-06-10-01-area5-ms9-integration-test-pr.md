# 2026-06-10-01 — Área 5 MS9: primeiro integration_test + editar/remover pausa + PR #25 (Área 5 fechada)

> **Branch:** `feat/m2-slice-2-area-5-route-details` → mergeada em `develop` via **PR #25** (`d139aef`).
> **Commit de feature:** `7acca87` (ADR-0049). **ADR:** 0049.
> **Testes:** 284 host (verde) + 1 integration_test VERDE no M54. **Lints:** 23 pré-existentes (MS-DEBT, intocados).

## Objetivo da sessão

Fechar a Área 5 (Detalhes da rota) com o **MS9**: criar o **primeiro `integration_test` do app**, rodar o **D4 de paridade** e abrir o PR. Continuação de uma sessão anterior (compactada) que já tinha o integration_test base passando.

## O que foi feito

1. **D4 de paridade — dump-only** (a pedido do Eduardo: "Por que vc não usa o app do dump completo e compara com ele?", evitando poluir a conta Spoke licenciada). Comparou `RouteDetailsPage`/`BreakSchedulerPage` shipados contra `~/spoke-dump/jadx-out`. Surgiram 2 gaps:
   - **GAP-1 — editar/remover pausa.** A row de uma pausa existente era `onTap: null`. O dump prova que a Spoke reabre em edit mode + ação de remover (`BreakSetupArgs` sealed: `AddBreak`/`EditBreak`/`UpdateBreak`; strings verbatim `break_screen_remove_button`="Remover pausa", `remove_break_confirmation_dialog_title`/`_description`). Eduardo escolheu **incluir no MS9** (não postergar). Implementado: row existente faz `context.push(extra: BreakConfig)` → `_isEdit` → pré-preenchido + "Remover pausa" + diálogo de confirmação; página retorna sealed `BreakSchedulerResult` (`BreakSaved`/`BreakRemoved`); `_onTapEditarPausa` faz `switch` exaustivo (`updateBreak`/`removeBreak`/no-op).
   - **GAP-2 — "Salvar como padrão" sempre visível.** O dump confirma que não há gate de primeira-rota (mesmo achado do ADR-0047). Checkbox fica incondicional no build.
2. **Primeiro `integration_test` do app** (`area5_route_details_flow_test.dart`): back-stack dos sub-pickers (Detalhes → Partida/Destino/Pausa, system Android-back popando exatamente um nível) + add/editar pausa. **VERDE no Samsung M54** (`RQCW401G33T`).
3. **ADR-0049** + docs sweep (TODO/roadmap/CHANGELOG/plan, Área 5 ✅). Commit `7acca87`, push.
4. **PR #25** aberto pelo Eduardo (gh estava offline pro agente) e **mergeado em `develop`** (`d139aef`).

## Lição-chave: o integration_test em device falha por motivos que o widget test não tem

O integration_test estendido (add+editar pausa) levou **4 tentativas** no device, cada falha diagnosticada com evidência (não chute) antes do fix:

1. **WebSocket transitório** (`Connection closed before full header`) — fronteira do perfil secundário (user 150 / Secure Folder) do M54. Reset adb + retry. (Não é o código.)
2. **`would not hit test`** — o tap na row de pausa caía num `RenderAbsorbPointer`: a transição de **pop** do Navigator (~300ms Material) desenha uma barreira sobre a página por alguns frames. Fix (só no teste): `pump(400ms)` de settle antes do tap, mesmo respiro que `_androidBack` já usa.
3. **Timeout em `break_scheduler_remove`** — CAUSA RAIZ: o `_router()` stand-in do teste construía `const BreakSchedulerPage()`, **descartando o `state.extra`** → edição abria em ADD mode → botão remover nunca montava. O `app.dart` de produção sempre esteve correto. Fix (só no teste): builder lê `state.extra as BreakConfig?` + import de `BreakConfig`.
4. **VERDE** (run `b7xqgulv8`, "All tests passed!").

**Generalização** (salva em memória): ao escrever um `_router()` stand-in num integration_test, **espelhar o builder de produção** — o `extra` em rota aninhada precisa ser repassado, senão o teste exercita um caminho diferente do app. E sempre ler o OUTPUT do `flutter test` (não o exit code — ele retorna 0 mesmo com teste falhando).

## Idiom de integration_test estabelecido (para as próximas áreas)

Primeiro do app — estes três padrões são reusáveis:
- **Map-free `/home` stand-in:** a `RouteShellPage` monta um `GoogleMap` (PlatformView) que trava `tester.pump()` num device (deadlock conhecido google_maps_flutter × integration_test). O teste troca só o `/home` por um botão stand-in; todas as telas sob `/home` são as de produção, nas rotas de produção.
- **`WidgetsBinding.instance.handlePopRoute()`** para o system Android-back (alcança o `RootBackButtonDispatcher` que o GoRouter registra; `WidgetsApp.didPopRoute()` NÃO alcança).
- **Font-free theme:** `GoogleFonts.poppins...` dispara loads fire-and-forget que re-armam um frame pós-teardown → `assert(!_expectingFrame)` sob `LiveTestWidgetsFlutterBinding`. O teste usa um `ColorScheme` igual ao `AppTheme.light` sem o overlay Poppins (assertion é navegação, não tipografia). Sem mudança em produção.

## Surpresa de processo (boa): topologia de branch

Ao preparar o PR descobri que a branch estava **263 commits à frente de `main` mas só 51 à frente de `develop`** — o fluxo do repo é **feature→develop→main** (`develop` = integração, `main` = release-only). Quase abri o PR pra `main` errado. Salvo em memória `project_branch_flow_feature_to_develop`. O git status inicial mostra "Main branch: main", mas isso é default do harness, não o alvo de PR.

## Estado ao fim

- **Área 5 ✅ FECHADA**, mergeada em `develop` (#25). Working tree limpa.
- Próximo (ordem forçada do roadmap): finalizar os **gatilhos da Área 3** (controles `_comingSoon` em `route_shell_page.dart`: Otimizar CTA, tap no stop card → Á6, kebab/bottom-bar → Á9, layer-toggle/recenter), depois Área 6. Plano: `docs/superpowers/plans/2026-06-06-slice2-completion.md` §"Phase MS-A3".

## Memórias tocadas

- **Nova:** `project_branch_flow_feature_to_develop` (PR de feature mira `develop`, nunca `main`).
- **Relevantes aplicadas:** `feedback_spoke_parity_zero_debt_per_ms` (GAP-1/2 resolvidos no MS, não deferidos), `lesson_slice_checklist_integration_test_gate` (1º integration_test do app), `lesson_showmodalbottomsheet_returns_intent_pattern` (sealed result), `feedback_responder_em_portugues`.
