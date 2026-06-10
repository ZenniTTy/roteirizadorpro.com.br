# ADR-0049: Editar/remover pausa fecha o GAP-1 da paridade Spoke (`BreakSetupArgs.EditBreak`); "Salvar como padrão" fica sempre visível (GAP-2)

- **Status:** Accepted
- **Date:** 2026-06-10
- **Deciders:** Eduardo
- **Related ADRs:** ADR-0035 (Spoke white-label hierarchy: comportamento = Spoke, microcopy = identidade original), ADR-0044 (BreakScheduler window domain + página full-screen), ADR-0045 (static dump baseline — a fonte que confirmou GAP-1 e GAP-2), ADR-0046 (config summary que alcança a Detalhes), ADR-0047 (persistência route-defaults + "Salvar como padrão" wired, default UNCHECKED)

## Context

MS-A5.9 era o fechamento da Área 5: criar o **primeiro `integration_test`** do app (back-stack dos sub-pickers num device real), rodar o **D4 de paridade** e abrir o PR da Área 5. O D4 — feito **dump-only** a pedido do Eduardo ("Por que vc não usa o app do dump completo e compara com ele?", evitando poluir a conta Spoke licenciada) — comparou o `RouteDetailsPage` + `BreakSchedulerPage` shipados contra os fatos do dump estático (`~/spoke-dump/jadx-out`, 53k `.java` + `docs/inventory/spoke-dump-v3.65.1/`). Surgiram dois gaps.

### GAP-1 — a row de uma pausa existente não era navegável (editar/remover faltando)

No código pré-MS9, `_pausaSection` renderizava as pausas existentes com `onTap: null` — só a row "Adicionar pausa" abria a `BreakSchedulerPage`. O dump prova que Spoke **abre a pausa existente em modo edição, com ação de remover**:

- **`BreakSetupArgs` é uma sealed class com 3 arms** (`com/circuit/ui/setup/breaks/BreakSetupArgs.java`): `AddBreak`, `EditBreak`, `UpdateBreak`. `AddBreak` = nova pausa; `EditBreak` = reabrir uma pausa existente pré-preenchida; `UpdateBreak` = salvar a edição. (Há também `RemoveBreak`/`UpdateBreakAndResetRoute` no `EditRouteViewModel`.)
- **Strings de remoção verbatim PT-BR** (`strings-pt-rBR.xml`):
  - `break_screen_remove_button` = **"Remover pausa"** (botão na tela de edição)
  - `remove_break_confirmation_dialog_title` = **"Remover pausa"**
  - `remove_break_confirmation_dialog_description` = **"Quer remover a pausa de %1$s da sua rota?"**

Ou seja: tocar numa pausa existente reabre a tela "Configure a pausa" pré-preenchida + mostra "Remover pausa" + um diálogo de confirmação antes de remover. O código pré-MS9 não tinha isso → **gap real de paridade**, não cosmético.

### GAP-2 — visibilidade do checkbox "Salvar como padrão"

ADR-0047 já cravou que o checkbox é wired e o default é UNCHECKED. A pergunta aberta do D4 era: ele é **sempre visível** ou só na primeira rota? O dump não expõe uma condição de gate (`grep` por `isFirstRoute|firstRoute|hasSeenSetup|shouldShowSetup` no `RouteSetup*` retorna nada — o mesmo achado que motivou ADR-0047 a cortar o FTUE), e `RouteSetupViewModel.setSaveAsDefault(Z)V` é incondicional. **Não existe gate de primeira-rota no Spoke** — logo o checkbox é parte fixa da tela.

### Bug no andaime do integration_test (não no app)

Ao escrever o `integration_test`, o teste estendido (adicionar pausa → editar) falhou no device com timeout esperando `break_scheduler_remove`. A causa-raiz foi um bug **no arquivo de teste**, não no app: o `_router()` stand-in do teste construía `const BreakSchedulerPage()`, **descartando o `state.extra`**, então a edição reabria em modo ADD (sem botão remover). O `app.dart` de produção sempre esteve correto (`BreakSchedulerPage(initialBreak: state.extra as BreakConfig?)`). Documentado aqui porque a lição (espelhar o builder de produção no router de teste; o `extra` em rota aninhada precisa ser repassado) é reusável.

## Decision

**1. A row de uma pausa existente reabre a `BreakSchedulerPage` em modo edição (`EditBreak`).** `_pausaSection` agora dá `onTap: () => _onTapEditarPausa(i, config.breaks[i])`, que faz `context.push(..., extra: current)`. O `app.dart` builder lê `initialBreak: state.extra as BreakConfig?`; quando não-nulo, `_isEdit` é true → campos pré-preenchidos + botão "Remover pausa".

**2. O resultado da `BreakSchedulerPage` é uma sealed family `BreakSchedulerResult` (`BreakSaved` / `BreakRemoved`)**, espelhando o `BreakSetupArgs`/resultado do Spoke. Concluído → `BreakSaved(config)`; Remover → `BreakRemoved`; back/cancel → `null`. `_onTapEditarPausa` faz `switch` exaustivo: `BreakSaved`→`updateBreak(index, config)`, `BreakRemoved`→`removeBreak(index)`, `null`→no-op. (A row "Adicionar pausa" continua em modo ADD: push sem `extra`, `BreakSaved`→`addBreak`.)

**3. Remover exige confirmação.** "Remover pausa" abre `_RemoveBreakDialog` (título "Remover pausa" + confirmar/cancelar) antes de popar `BreakRemoved`, espelhando `remove_break_confirmation_dialog_*` do Spoke. **Microcopy é identidade original (ADR-0035):** usamos "Quer mesmo remover esta pausa da sua rota?" em vez do verbatim com duração interpolada do Spoke ("Quer remover a pausa de %1$s da sua rota?") — a *estrutura* (dialog de confirmação título/descrição/2 ações) é a paridade; o texto PT-BR é nosso.

**4. A row de pausa é de duas linhas (GAP-3, já no MS8 mas formalizado aqui):** título bold "Pausa de N min" + subtítulo muted "Entre A e B", espelhando `route_setup_break_option_title`/`_subtitle` — não uma string concatenada.

**5. O CTA é "Concluído" (GAP-4):** o botão de confirmar da `BreakSchedulerPage` usa o label "Concluído" (semantics `break_scheduler_confirm`), sempre habilitado (Spoke nunca gateia o confirm — ADR-0043 §S2).

**6. "Salvar como padrão" é sempre visível (GAP-2 resolvido).** O `_SalvarComoPadraoCheckbox` é renderizado incondicionalmente no build do `RouteDetailsPage` (sem gate de primeira-rota), porque o dump prova que Spoke não tem esse gate. Default UNCHECKED (ADR-0047). Coerente com o corte do FTUE: a tela é parte fixa, não FTUE.

**7. O `integration_test` (`area5_route_details_flow_test.dart`) é validado VERDE no M54.** Dois fixes só no arquivo de teste, nenhum em produção:
   - **(a)** `pump(400ms)` de settle entre confirmar a pausa e tocar na row de edição — a transição de pop do Navigator (~300ms Material) desenha um `RenderAbsorbPointer` sobre a página por alguns frames; tocar antes disso fazia o tap ser absorvido (`would not hit test` num device). Mesmo respiro que `_androidBack` já usa.
   - **(b)** o builder do break-scheduler no `_router()` de teste agora lê `state.extra as BreakConfig?` (antes `const BreakSchedulerPage()` descartava o `extra` → edição abria em ADD mode → `break_scheduler_remove` nunca montava).

## Consequences

- **Positivo (paridade fechada):** editar/remover pausa agora bate com `BreakSetupArgs.EditBreak`/`UpdateBreak` + diálogo de remoção do Spoke (dump-confirmado). GAP-1 fechado dentro do MS9 a pedido do Eduardo ("Incluir editar/remover agora no MS9"), sem postergar a divergência (`feedback_spoke_parity_zero_debt_per_ms`).
- **Positivo (primeiro integration_test do app):** a cadeia de back-stack dos sub-pickers (Detalhes → Partida/Destino/Pausa, system Android-back popando exatamente um nível) está validada num device real — a classe de bug que widget tests não pegam (`lesson_slice_checklist_integration_test_gate`). Cobre add **e** edit de pausa.
- **Positivo (dump-first de novo):** GAP-1 e GAP-2 foram resolvidos pelo dump em minutos, sem criar rotas de teste na conta Spoke licenciada — outro ponto pro método dump-first (ADR-0045/0048).
- **Neutro (microcopy divergente consciente):** o texto do diálogo de remoção é nosso, não verbatim do Spoke — registrado aqui pra um reviewer futuro não "corrigir" pro texto do Spoke (anti-pattern: tratar microcopy como paridade, contra ADR-0035).
- **Negativo (sealed result adiciona um tipo):** `BreakSchedulerResult` é mais um tipo no domínio; justificado por espelhar a forma do Spoke e dar `switch` exaustivo (vs. um `bool removed` + `BreakConfig?` ambíguo).

## Alternatives considered

1. **Postergar editar/remover pausa pra um MS depois.** Rejeitado — Eduardo escolheu "Incluir editar/remover agora no MS9"; postergar divergência Spoke é proibido (`feedback_spoke_parity_zero_debt_per_ms`).
2. **Resultado da página como `BreakConfig?` + flag `removed`.** Rejeitado — ambíguo (um `BreakConfig?` null poderia ser cancel OU remove). A sealed family torna os 3 desfechos (saved/removed/cancel) explícitos e exaustivos no `switch`.
3. **Remover sem diálogo de confirmação.** Rejeitado — o dump tem `remove_break_confirmation_dialog_*`; Spoke confirma antes de remover, então nós também.
4. **Gate do "Salvar como padrão" na primeira rota.** Rejeitado — o dump prova que não existe gate de primeira-rota (mesmo achado de ADR-0047); o checkbox é parte fixa da tela.
5. **Inspecionar editar/remover ao vivo no Spoke pra confirmar.** Considerado mas desnecessário — o dump respondeu no nível do código (sealed args + strings verbatim), e ao vivo criaria pausas de teste na conta licenciada.

## References

- D4 paridade: dump-only (`~/spoke-dump/jadx-out` + `docs/inventory/spoke-dump-v3.65.1/`), a pedido do Eduardo ("Por que vc não usa o app do dump completo e compara com ele?")
- Static dump (autoritativo): `com/circuit/ui/setup/breaks/BreakSetupArgs.java` (sealed `AddBreak`/`EditBreak`/`UpdateBreak`) + `strings-pt-rBR.xml` (`break_screen_remove_button`, `remove_break_confirmation_dialog_title`/`_description`)
- Código: `route_config.dart` (sealed `BreakSchedulerResult`), `break_scheduler_page.dart` (`initialBreak`/`_onConfirm`/`_onRemove`/`_RemoveBreakDialog`), `route_details_page.dart` (`_pausaSection`/`_onTapEditarPausa`/`_SalvarComoPadraoCheckbox`), `app.dart` (builder lê `state.extra`)
- Testes: `break_scheduler_page_test.dart` (11 casos), `route_details_page_test.dart` (46 casos, +3 edit/remove), `integration_test/area5_route_details_flow_test.dart` (back-stack + add+edit pausa, VERDE no M54 `RQCW401G33T` run b7xqgulv8)
- Roadmap/plan: `docs/08-ROADMAP-v2.md` Área 5 MS9 + `docs/superpowers/plans/2026-06-06-slice2-completion.md` §MS-A5.9 (atualizados no mesmo commit set)
- Memory: `feedback_spoke_parity_zero_debt_per_ms`, `lesson_slice_checklist_integration_test_gate`, `lesson_showmodalbottomsheet_returns_intent_pattern` (returns-intent pattern), `lesson_master_table_covers_setup_not_active_shell`
