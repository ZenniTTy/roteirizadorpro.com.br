# Audit retroativo de paridade — Flutter (develop) × dump estático Spoke v3.65.1

> **Data:** 2026-06-20 · **Escopo:** todas as Áreas já construídas do Slice 2 (Á2–Á7) · **Método:** dump-only (sem runtime na conta licenciada) · **Disparado por:** diretiva de Eduardo 2026-06-19/20 ("audit completo em tudo o que já foi feito para comparar com o dump") · **Registra a estratégia:** [ADR-0052](../decisions/0052-faithful-dump-clone-and-per-phase-investigation.md) · **Backlog vivo no:** [TODO.md](../../TODO.md) §"Fase R" + [08-ROADMAP-v2.md](../08-ROADMAP-v2.md) §"Fase R".

## Como o audit foi feito

- **20 subagentes** orquestrados em workflow (`spoke-parity-checker`, modo **dump-only**): 6 auditores (1 por área) + verificação adversarial de cada must-fix + síntese.
- **Fonte de verdade comparada:** [`docs/inventory/spoke-dump-v3.65.1/MASTER-TABLE.md`](../inventory/spoke-dump-v3.65.1/MASTER-TABLE.md) + `~/spoke-dump/jadx-out/sources` (lógica decompilada) + `~/spoke-dump/jadx-out/resources/res/values-pt-rBR/strings.xml` (strings verbatim) + a design doc de cada área.
- **Sem poluir a conta Spoke:** zero runtime na licença do Eduardo — o jadx responde estrutura, defaults, enums, gates e strings sem tocar o device.
- **Verificação adversarial:** cada um dos 13 must-fix foi re-checado por um segundo agente cético antes de contar. **13 de 13 confirmados `isReal=true`** (confiança 0.78–0.98). Zero falso-positivo — o audit foi conservador.
- **Custo:** ~1.9M tokens, 632 tool-uses, ~13 min de relógio (workflow `wp6fupsv5`).

## Veredito geral — paridade MÉDIA, dívida concentrada na Área 7

O **esqueleto funcional do clone está fiel** ao dump em quase todas as áreas: estruturas de dados (`RouteState`, `OptimizationState`, `OptimizeType`, `StopColor`, `PackageDetails`), fluxos de navegação (DRAFT→PRE-CONFIRM, wizard criar/editar, 3 estados de busca, numpad 4×3, página full-screen de Pausa), enums e os 14 campos do editor de parada **batem enumeração-a-enumeração** com o jadx. **Nenhuma surpresa arquitetural, nenhum enum incompleto, nenhum gate invertido grave.** A remediação é previsível e de baixo risco técnico.

A dívida real está em **duas frentes**:

1. **Microcopy PT-BR reescrita "por significado"** sem comparar 1:1 com o `values-pt-rBR` — não viola o ADR-0035 (microcopy original é permitida), MAS vários casos **mudam o significado funcional** (ex.: "Avaliando o trânsito" sugere trânsito em tempo real que o solver on-device não faz).
2. **O sub-slice PR-C inteiro da Área 7 é honest-stub** — `ReadyToRunView`, `IdLockDialog`, `DiscardChangesDialog`, banner "Otimização pendente" e o `Confirmar` que grava `confirmed:true` não existem. **O usuário literalmente trava no PRE-CONFIRM.** O ciclo de otimização está 2/3 pronto.

### Paridade por área

| Área | Tela | Paridade | must-fix | should-fix | nit |
|---|---|:---:|:---:|:---:|:---:|
| **4** | Adicionar parada (texto + Places) | 🟢 ALTA | 1\* | 1 | 2 |
| **6** | Editar parada (14 campos) | 🟢 ALTA | 1 | 1 | 1 |
| **2** | Drawer + Lista + Wizard + 3-dot | 🟡 média | 2 | 2 | 3 |
| **3** | Tela ativa (mapa + sheet + config) | 🟡 média | 1 | 3 | 2 |
| **5** | Detalhes (Partida/Destino/Pausa) | 🟡 média | 0 | 3 | 2 |
| **7** | Otimizar rota (estados + FTUE) | 🟡 média | **8** | 2 | 1 |
| | **TOTAL** | | **13** | **12** | **11** |

\* O único must-fix da Á4 (A4-D3, edição inline pós-adição) é um gap **intencionalmente escopado para a Á6** — não é ação imediata, é débito documentado. Acionáveis de fato: **12 must-fix**.

## 5 temas de causa-raiz (isto explica o mês de retrabalho)

1. **MICROCOPY REESCRITA SEM CONFERIR O `values-pt-rBR`** — tema dominante, em **5 de 6 áreas** (A2-D1, A3-D1/D4/D5, A4-D2, A5-D1/D2/D3/D5, A6-D3, A7-D1/D2/D3/D9/D10). Causa-raiz: frases inventadas "por significado" em vez de comparadas 1:1 com o dump antes de virar "original". É exatamente o failure mode da lesson `lesson_spec_does_not_replace_reverifying_dump`.
2. **ESTADOS/TELAS TERMINAIS AUSENTES (honest-stubs)** — concentrados na Á7 (ReadyToRunView, IdLockDialog, DiscardChangesDialog, banner "Otimização pendente": A7-D5/D6/D7/D8) com tentáculo na Á3 (A3-D6). O domínio está modelado (`isReadyToRun`, `isEditing` existem como getters órfãos) mas nenhum widget os consome.
3. **GUARDS E GATES FALTANDO** — "fluxo feliz implementado, caminho de proteção não": gate "única rota" no delete (A2-D4), guard de saída com edições pendentes (A7-D7), gate `AppFeature.Breaks` no config summary (A3-D2), gate de modo ADD/EDIT no CTA da pausa (A5-D1).
4. **SUBTITLES ESTÁTICOS QUE DEVERIAM REAGIR AO ESTADO** — config rows que não trocam o texto após o usuário configurar algo: linha Início (A5-D5), linha RoundTrip ignora `startLocation` (A5-D4), search pill placeholder fixo (A3-D3, A4-D2). Mesmo bug conceitual repetido.
5. **FORMA DE APRESENTAÇÃO MODAL DIVERGENTE** (sheet vs dialog vs lateral) — A6-D2 (AlertDialog vs BottomSheet), A2-D5 (bottom sheet vs drawer lateral 90%). Comportamento equivalente, superfície visual diferente; baixa prioridade.

## Plano de remediação priorizado (Fase R — 100% antes da Á8)

Decisão de Eduardo 2026-06-20: **remediar 100% (P0→P3) antes de abrir qualquer área nova.** Fidelidade retroativa total.

### P0 — desbloqueia o ciclo de otimização (maior impacto funcional) · Área 7 PR-C

- **A7-D5** — Implementar `ReadyToRunView` + fazer `_onConfirm()` gravar `confirmed:true` via `confirmRoute()`; expandir o switch do `build()` do shell para cobrir `isReadyToRun`.
- **A7-D6** — Criar `IdLockDialog` one-shot + key `id_lock_ftue_v1` no `OptimizationFtueRepository`, disparado em `_onConfirm()` quando `format==moderno && !idLockAcknowledged`.
- **A7-D7** — Criar `DiscardChangesDialog` + `PopScope`/guard no `RouteShellPage` que checa `isEditing` antes do back, com `discardOptimizationEdits()` no "Descartar".
- **A7-D8** — Fazer "Pular otimização" gravar estado e navegar ao Ready-to-Run com o banner "Otimização pendente" persistente no header do sheet (depende dos itens acima).

### P1 — fluxos e gates que alteram comportamento (não-cosmético) · Áreas 2, 3, 6, 7

- **A7-D4** — `PopupMenuButton` no kebab do PRE-CONFIRM com "Reotimizar rota…" (abre sheet) + "Pular otimização", em vez de abrir o sheet direto.
- **A2-D2** — CTA do wizard condicional: "Continuar para copiar paradas" quando `!isEdit && reuseStops`.
- **A3-D2** — adicionar a 3ª linha "Pausa" no `_ConfigSummarySection` sob o gate de Breaks, navegando para Detalhes.
- **A6-D1** — em `_confirmRemove`, após `markStopForDeferredRemoval`, fazer `context.pop()` espelhando o branch DRAFT.
- **A2-D4 + A2-D3** — gate de "única rota" no delete (snackbar "Não é possível excluir a única rota") + diálogo "Manter/Redefinir progresso" no duplicar.

### P2 — sweep de microcopy contra o `values-pt-rBR` (1 passada coordenada por área) · Áreas 7, 5, 2, 3, 6

- **Á7** — realinhar fases de progresso (sem "trânsito" no Slice 2), `RefineRouteSheet` (título "Refinar a rota"), `ReoptimizeOptionsSheet` ("Atualizar rota"/"Reotimizar rota"), `OptimizationErrorDialog`, `IdEducationDialog` (2 parágrafos) — A7-D1/D2/D3/D9/D10.
- **Á5** — CTA pausa modo ADD = "Adicionar pausa"; diálogo de remoção com duração ("a pausa de N min"); botão "Remover pausa"; subtitle RoundTrip reage a `startLocation`; subtitle Início reage a custom address — A5-D1/D2/D3/D4/D5.
- **Á2** — corrigir 3 labels de seção do drawer ("Próximas rotas", "Início desta semana", "Início deste mês") — A2-D1.
- **Á3** — toasts de layer-toggle (satélite-on/off, sem "Modo"); semantics do recenter = "Centralizar"; placeholder dinâmico da search pill — A3-D1/D5/D3.
- **Á6** — alinhar "Quer remover" (remover "mesmo") — A6-D3.

### P3 — nits e forma de apresentação (decisão de produto, baixo impacto) · Áreas 4, 7, 6, 2, 3

- **Á4** — subir debounce de 500ms para 800ms; placeholder variável por `stopCount` — A4-D1/D2.
- **Á7** — trocar `Icons.*` por `LucideIcons` no `RefineRouteSheet` (consistência ADR-0035) — A7-D11.
- **Á6** — converter `PackageCountDialog` de `showDialog` para `showModalBottomSheet` — A6-D2.
- **Á2** — profile card clickable + seção "Hoje" vazia com estado; decidir bottom-sheet vs drawer lateral 90% (registrar desvio se mantiver) — A2-D6/D7/D5.
- **Á4** — post-add inline edit (A4-D3) já está corretamente escopado para a Área 6 — não antecipar; manter como gap documentado.

---

## Backlog detalhado por área

> Cada drift cita evidência de **impl** (arquivo:linha RotPro) e **dump** (símbolo/recurso/string como identificador — não código reproduzido). `fix` é a direção de correção, não a implementação final.


## Área 2 — Drawer + Lista de rotas + Wizard criar/editar + Popup 3-dot + Reutilizar paradas
_Veredito: medium_

O núcleo da Área 2 está funcionalmente correto: bottom sheet modal, 3 itens no kebab com labels corretos, wizard criar/editar parametrizado, separação Zona C no create/edit, campos de rota (nome + data + 3 opções de data). Foram encontrados 7 drifts, sendo 2 must-fix (labels das seções do drawer errados e wizard sem alterar o CTA ao checar "reutilizar"), 2 should-fix (duplicar rota sem diálogo "Manter/Redefinir progresso" e delete sem gate "única rota") e 3 nits (drawer fullscreen vs 90% width lateral, profile card sem tap, empty "Hoje" sem CTA inline).

### A2-D1 [must-fix] — Labels das seções do drawer divergem do dump (string-mismatch)
- **categoria:** string-mismatch
- **impl:** apps/mobile/lib/features/routes/presentation/widgets/drawer_route_list.dart:89-94 — labels: 'Próximas' / 'Hoje' / 'Esta semana' / 'Este mês'
- **dump:** strings.xml linhas 2017/2338/2016/2015: route_group_upcoming_routes='Próximas rotas', today='Hoje', route_group_earlier_week='Início desta semana', route_group_earlier_month='Início deste mês'. Confirmado no DrawerViewModel$routesFlow$1.java linhas 87-93: R.string.route_group_upcoming_routes / R.string.today / R.string.route_group_earlier_week / R.string.route_group_earlier_month.
- **detalhe:** Três dos quatro labels de seção do drawer estão errados em relação ao dump. 'Próximas' deveria ser 'Próximas rotas'. 'Esta semana' deveria ser 'Início desta semana'. 'Este mês' deveria ser 'Início deste mês'. Apenas 'Hoje' está correto (R.string.today). O usuário que vem do Spoke vê textos diferentes nos cabeçalhos de seção.
- **fix:** Em DrawerRouteList._labelFor(), corrigir: RoutePeriod.upcoming → 'Próximas rotas', RoutePeriod.thisWeek → 'Início desta semana', RoutePeriod.thisMonth → 'Início deste mês'. Microcopy original RotPro (não verbatim Spoke) pode usar equivalentes semânticos, mas a estrutura de 4 buckets com esses significados deve ser mantida.

### A2-D2 [must-fix] — Wizard: CTA não muda para 'Continuar para copiar paradas' quando reuseStops está marcado
- **categoria:** flow-divergence
- **impl:** apps/mobile/lib/features/routes/presentation/wizard_route_page.dart:252-253 — ctaLabel é sempre 'Confirmar' em create mode, independente de state.reuseStops. A navegação para reuse-stops ocorre como side-effect pós-pop (linha 177-185).
- **dump:** strings.xml linhas 2006-2007: route_create_button_title='Criar rota' (default sem reutilizar) e route_create_next_title='Continuar para copiar paradas' (quando reutilizar está ativo). Confirmado em RouteCreateScreenKt.java: o ViewModel tem dois branches de submissão distintos. Ao marcar reutilizar, o CTA muda para a string de 'Continuar', que leva ao fluxo CopyStops em vez de fechar direto.
- **detalhe:** No Spoke, ao marcar 'Reutilizar paradas anteriores', o botão primário do wizard muda de 'Criar rota' para 'Continuar para copiar paradas'. Isso sinaliza claramente ao usuário que ele vai para uma tela intermediária antes de entrar na rota. No RotPro o botão permanece 'Confirmar' e a navegação para reuse-stops acontece como addPostFrameCallback silencioso, sem feedback visual antecipado da mudança de fluxo.
- **fix:** Em WizardRoutePage.build(), tornar ctaLabel condicional: quando !isEdit && state.reuseStops, usar 'Continuar para copiar paradas' (PT-BR original). Manter 'Confirmar' quando reuseStops=false.

### A2-D3 [should-fix] — Duplicar rota não exibe diálogo 'Manter/Redefinir progresso' para rotas com paradas feitas
- **categoria:** missing-feature
- **impl:** apps/mobile/lib/features/routes/state/routes_provider.dart:104-112 — duplicateRoute() copia imediatamente com sufixo '(Cópia)', sem diálogo. apps/mobile/lib/features/routes/presentation/widgets/app_drawer.dart:172-174 — chama duplicateRoute diretamente.
- **dump:** DrawerViewModel$tappedDuplicateRoute$1.java linha 99: emite DrawerEvent.LaunchDuplicateDialogFlow com Action (KeepProgress ou DiscardProgress). DrawerEvent.java linhas 15-66: enum Action { KeepProgress, DiscardProgress }. strings.xml linhas 746-749: duplicate_route_progress_clear='Redefinir progresso da rota', duplicate_route_progress_keep='Manter progresso da rota' com subtítulos explicativos. O diálogo só aparece quando a rota tem paradas feitas (ProofOfDelivery disabled → ação=KeepProgress default; POD enabled → dialog com as 2 opções).
- **detalhe:** Quando uma rota tem paradas marcadas como feitas, o Spoke exibe um diálogo antes de duplicar, perguntando se as paradas feitas devem ser mantidas ou redefinidas na cópia. RotPro duplica silenciosamente sem essa escolha. Em Slice 2 sem backend isso é limitado, mas a estrutura de diálogo deveria estar presente para quando a feature ficar real.
- **fix:** Ao disparar RouteAction.duplicate, verificar se a rota tem stops com status 'done'. Se sim, exibir AlertDialog com duas opções ('Manter progresso' / 'Redefinir progresso'). O duplicateRoute() do notifier pode receber um parâmetro keepProgress: bool. Em Slice 2 (sem backend) o comportamento real é stub, mas a UI do diálogo já pode ser implementada.

### A2-D4 [should-fix] — Excluir rota não tem gate 'não é possível excluir a única rota'
- **categoria:** wrong-gate
- **impl:** apps/mobile/lib/features/routes/presentation/widgets/app_drawer.dart:175-213 — fluxo de delete mostra AlertDialog e chama removeRoute sem verificar se é a única rota.
- **dump:** DrawerViewModel$tappedDeleteRoute$1.java linha 96: quando AbstractC2995a é instância de .d (privilégio negado — única rota), emite DrawerEvent.C3409c(R.string.cannot_delete_only_route_title). strings.xml linha 561: cannot_delete_only_route_title='Não é possível excluir a única rota'. O gate existe no Spoke: tentar excluir a única rota exibe um toast de erro em vez do diálogo de confirmação.
- **detalhe:** No Spoke, ao tentar excluir a última rota existente, o app exibe um toast 'Não é possível excluir a única rota' em vez do diálogo de confirmação. RotPro permite excluir todas as rotas, deixando o estado global sem rota ativa, o que pode causar o crash descrito na MEMORY 'lesson_empty_route_sheet_collapsed_trapped_in_map' em Slice 3.
- **fix:** Em _handleRouteKebabAction(RouteAction.delete), antes de exibir o AlertDialog, verificar se routes.length == 1. Se sim, mostrar snackbar 'Não é possível excluir a única rota' e retornar sem abrir o diálogo.

### A2-D5 [nit] — Drawer é bottom modal fullscreen, não drawer lateral de 90% da largura como no Spoke
- **categoria:** flow-divergence
- **impl:** apps/mobile/lib/features/routes/presentation/widgets/app_drawer.dart:33-49 — showModalBottomSheet com isScrollControlled:true, constraints maxWidth: double.infinity (fullscreen).
- **dump:** Inventário §10.1: 'Drawer body bounds: [0,0][967,...] (90% da largura). Ocupa toda a altura abaixo da status bar.' e 'Scrim: [967,0][1080,2400] (faixa de ~10% à direita)'. DrawerViewModel$routesFlow$1.java confirma uso de Drawer Material (não BottomSheet). A spec de design 2026-05-27-drawer-lateral-design.md §'Drawer' documenta isso como bottom sheet baseando-se em um screenshot, mas o inventário §10.1 é claro: é um drawer 90% width abrindo da esquerda.
- **detalhe:** O Spoke usa um drawer lateral (90% da largura, desliza da esquerda) acessado pelo hamburger. A spec de 27/05 interpretou erroneamente um screenshot e implementou um bottom modal sheet. Funcionalmente ambos expõem as mesmas rotas e ações, mas a direção de abertura e o gesto de dismiss diferem (swipe-down vs swipe-left). ADR-0035 e a spec de design aceitaram a decisão de bottom sheet com embasamento no screenshot, então isso é classificado como nit (diferença estrutural documentada, decisão consciente).
- **fix:** Decisão de Eduardo: manter bottom sheet (diferença funcional mínima, behavior documentado) ou migrar para Scaffold Drawer lateral 90% para fidelidade máxima ao Spoke. Se mantiver, registrar como desvio intencional em docs/inventory.

### A2-D6 [nit] — Profile card do drawer não possui tap (Spoke o torna clickable)
- **categoria:** missing-feature
- **impl:** apps/mobile/lib/features/routes/presentation/widgets/drawer_header_card.dart — sem InkWell/GestureDetector no card de perfil. Não há onTap.
- **dump:** Inventário §10.1: 'Card de perfil clickable inteiro ([46,261][921,441]) — tap navega pra tela de account'. DrawerHeaderUiModel.java e DrawerViewModel.java confirmam o card como item clicável com evento separado. A nota do inventário admite que a navegação real não foi confirmada para conta Standard, mas o elemento é clickable=true.
- **detalhe:** No Spoke o card de perfil (avatar + nome + email + plano) é tappable e navega para uma tela de conta (possivelmente upsell para não-assinantes). Em RotPro o DrawerHeaderCard não possui handler de toque.
- **fix:** Adicionar GestureDetector/InkWell no DrawerHeaderCard com callback onTap apontando para '/settings/account' ou stub snackbar 'Em breve' até a tela de perfil ser implementada (Slice 4+).

### A2-D7 [nit] — Seção 'Hoje' vazia não exibe CTA 'Criar rota' inline no drawer
- **categoria:** missing-state
- **impl:** apps/mobile/lib/features/routes/presentation/widgets/drawer_route_list.dart — DrawerRouteList não renderiza nada especial quando uma seção está vazia. A CTA 'Criar rota' existe somente no rodapé do sheet.
- **dump:** DrawerViewModel$routesFlow$1.java linha 119: new wz5(g3cVar, arrayList2, list2.isEmpty() && (c25562a.f129847a instanceof rac.AbstractC25563b.d) && zM8613g) — o terceiro parâmetro é showCreateRoute=true quando a seção 'Hoje' (AbstractC25563b.d) está vazia E CreateRoute feature está habilitada. wz5.java linha 44: campo 'showCreateRoute'. strings.xml linha 2057: routes_drawer_today_empty='Ainda não há rotas'.
- **detalhe:** Quando não há rotas criadas para o dia de hoje, o Spoke exibe um estado especial dentro da seção 'Hoje' com um indicador 'Ainda não há rotas' e possivelmente um CTA de criação inline. RotPro omite essa seção vazia (buckets vazios são omitidos) e tem apenas o CTA global no rodapé.
- **fix:** Quando RoutePeriod.today existe no grouped mas tem lista vazia, renderizar um _EmptyTodayRow com texto equivalente a 'Ainda não há rotas hoje' em vez de omitir a seção. Só exibir quando a seção vazia for a 'today'.


## flow:route:active-shell (mapa + sheet, controles de mapa, config summary, lista de paradas)
_Veredito: medium_

A implementação da tela ativa de rota (Área 3 — RouteShellPage) está estruturalmente sólida: a arquitetura Column/Sheet espelha corretamente o Spoke, o ciclo DRAFT→PRE-CONFIRM, o auto-expand H6, o snap direcional, o recenter com pending-move counter e o mapa-padding por snap estão todos corretos. Os drifts encontrados são concentrados em quatro pontos: (1) strings dos toasts do layer-toggle divergem dos strings PT-BR do dump; (2) a seção de config summary está faltando a terceira linha "Pausa" que o Spoke renderiza quando AppFeature.Breaks está habilitado; (3) o placeholder da search pill é estático enquanto o Spoke usa 4 estados dinâmicos baseados na contagem de paradas; (4) o rótulo do botão primário do empty state usa singular "Adicionar parada" onde o Spoke usa plural "Adicionar paradas". O banner "Otimização pendente" está explicitamente diferido para PR-C. O semantics label do botão de recenter está incorreto ("Alternar para o mapa" vs "Centralizar").

### A3-D1 [should-fix] — Toast do layer-toggle com strings divergentes do dump PT-BR
- **categoria:** string-mismatch
- **impl:** route_shell_page.dart:482-484 — isSatellite ? 'Modo Satélite ativado' : 'Modo Mapa ativado'
- **dump:** res/values-pt-rBR/strings.xml — map_action_toast_satellite_on='Satélite ativado'; map_action_toast_satellite_off='Satélite desativado'. EditRouteFragment.java:2117-2123 mostra os dois branches: ordinal 0 → satellite_off, ordinal 1 → satellite_on.
- **detalhe:** Nossa implementação usa prefixo 'Modo' e inverte a semântica no branch OFF ('Modo Mapa ativado' para quando sai do satélite). O Spoke usa apenas 'Satélite ativado' / 'Satélite desativado' — sem prefixo 'Modo' e sem mencionar 'Mapa' no branch off. A estrutura semântica é diferente: o Spoke descreve o estado do satélite (ativado/desativado), nós descrevemos o modo resultante (Satélite/Mapa).
- **fix:** Em _onToggleMapType, substituir os literais pelos equivalentes PT-BR originais RotPro: isSatellite ? 'Satélite ativado' : 'Satélite desativado'. Estes são os textos funcionalmente equivalentes — não usar os strings verbatim do Spoke no produto (ADR-0035), mas a estrutura deve ser satélite-on / satélite-off, não modo-mapa / modo-satélite.

### A3-D2 [must-fix] — Config summary não exibe a linha 'Pausa' (3ª linha presente no Spoke quando AppFeature.Breaks está habilitado)
- **categoria:** missing-field
- **impl:** route_shell_page.dart:1454 — comentário explícito: 'Spoke renders a 2-row summary — Início + Ida-e-volta, NO Pausa'. _ConfigSummarySection.build() renderiza exatamente 2 RouteConfigRow widgets (config_summary_inicio + config_summary_destino).
- **dump:** RouteStepListController.java:1084-1096 — após adicionar os itens m39733i (Início) e m39730e (Destino), o bloco 'if (zM8613g2)' adiciona um terceiro item de Pausa. zM8613g2 = c2847b.m8630a(AppFeature.Breaks.f23664b, w8cVarMo42447a).m8613g() — é o gate de AppFeature.Breaks. O RotPro suporta Breaks (break_scheduler_page.dart existe e está no working tree), portanto esse gate é verdadeiro.
- **detalhe:** O Spoke mostra 3 linhas no bloco RouteSetup da sheet: (1) Início/Partida, (2) Destino, (3) Pausa — nessa ordem. A terceira linha é condicional em AppFeature.Breaks, mas como o RotPro tem a feature de Pausa implementada (Área 5), ela deveria aparecer aqui também. O motorista precisa ver e acessar a configuração de Pausa diretamente da tela ativa, sem ter que abrir 'Detalhes da rota' para encontrá-la.
- **fix:** Em _ConfigSummarySection, adicionar um terceiro RouteConfigRow para a Pausa. Deve observar breakConfig via routeConfigControllerProvider(routeId).select(). Label: quando a pausa está configurada exibir a janela horária; quando não está configurada exibir algo como 'Sem pausa definida'. Ícone: LucideIcons.coffee (ou similar — Lucide). Tap navega para /home/routes/active/{id}/details (mesma rota das outras duas linhas). A linha deve ser adicionada após o Destino, na mesma ordem do Spoke.

### A3-D3 [should-fix] — Placeholder da search pill é estático; Spoke usa 4 estados dinâmicos por contagem de paradas
- **categoria:** missing-state
- **impl:** route_shell_page.dart:1158-1163 — Text 'Adicionar parada...' hardcoded sem variação por estado.
- **dump:** SearchBarPlaceholder.java:45-49 — 4 estados: NoStops (focused: 'Digite para adicionar', unfocused: 'Toque para adicionar'), FewStops (focused: 'Digite para adicionar', unfocused: 'Toque para adicionar'), ManyStops (focused: 'Adicione ou busque', unfocused: 'Adicione ou busque'), e CantAddStops (unfocused: 'Encontrar paradas'). Strings em res/values-pt-rBR/strings.xml linhas 2091-2096.
- **detalhe:** O Spoke adapta o texto do pill de busca ao número de paradas e ao estado de foco. Sem paradas: 'Toque para adicionar' (desfocado). Com poucas paradas: mesmo texto. Com muitas paradas: 'Adicione ou busque'. O nosso 'Adicionar parada...' é estático e não muda com a contagem. No mínimo o state NoStops (unfocused) deveria ser 'Toque para adicionar' ao invés do nosso current placeholder estático.
- **fix:** Tornar o placeholder dinâmico em _buildSearchRow baseado em stops.isEmpty e stops.length. Sugestão de mapeamento PT-BR original: (0 paradas) 'Toque para adicionar'; (1+ paradas) 'Adicionar ou buscar paradas'. Como a pill não tem foco real (é um InkWell, não um TextField), o estado 'focused' não é aplicável — usar apenas o unfocused. Isso é um should-fix pois o texto atual ainda comunica a ação corretamente.

### A3-D4 [nit] — Botão primário do empty state usa singular 'Adicionar parada' onde Spoke usa plural 'Adicionar paradas'
- **categoria:** string-mismatch
- **impl:** route_shell_page.dart:969 — _SheetPrimaryButton label: 'Adicionar parada'
- **dump:** res/values-pt-rBR/strings.xml linha 409 — add_stops_button_title='Adicionar paradas'. RouteStepListKt.java:420 confirma uso: 'String strM6818k = bfa.m6818k(c0759dMo2510C, R.string.add_stops_button_title)'.
- **detalhe:** O Spoke usa plural 'Adicionar paradas' (plural) no botão primário do empty state. Nossa impl usa singular 'Adicionar parada'. A diferença é pequena mas semanticamente o plural é mais correto (o usuário vai adicionar múltiplas paradas ao longo do tempo, não apenas uma).
- **fix:** Alterar label de 'Adicionar parada' para 'Adicionar paradas' (plural) em _SheetPrimaryButton no bloco do empty state.

### A3-D5 [nit] — Semantics label do botão de recenter incorreto ('Alternar para o mapa' vs 'Centralizar')
- **categoria:** string-mismatch
- **impl:** route_shell_page.dart:391 — semanticsLabel: 'Alternar para o mapa' no _FloatingCircleButton do recenter.
- **dump:** res/values-pt-rBR/strings.xml — in_app_nav_terms_recenter_button_title='Centralizar'. O Spoke usa esse string como label de acessibilidade do botão de recenter.
- **detalhe:** 'Alternar para o mapa' é semanticamente errado para um botão de centralizar/seguir localização GPS. 'Centralizar' é a descrição correta da ação (o botão centraliza o mapa na posição do usuário). O label incorreto afeta acessibilidade (TalkBack) e testes Maestro que usam semantics identifier.
- **fix:** Alterar semanticsLabel do botão de recenter de 'Alternar para o mapa' para 'Centralizar' (ou equivalente PT-BR como 'Centralizar no mapa' — microcopy original RotPro).

### A3-D6 [should-fix] — Banner 'Otimização pendente' ausente (honest-stub explícito — PR-C)
- **categoria:** missing-feature
- **impl:** route_shell_page.dart:588 — comentário: 'banner Otimização pendente do Spoke é PR-C'. Nenhum banner/widget de otimização pendente renderizado no DRAFT state após PRE-CONFIRM→edição.
- **dump:** res/values-pt-rBR/strings.xml — optimization_pending_button_title='Otimização pendente'. RouteStepListController C3550h.java:394,712 — 'onOptimizationPendingWarningClick' listener. os7.java:34 renderiza o botão 'Otimização pendente'. pd5.java:118 mostra o campo 'showOptimizationPending' no UiModel da sheet.
- **detalhe:** Quando o usuário edita paradas após uma otimização (estado PRE-CONFIRM→DRAFT reversal com edições), o Spoke exibe um banner/botão 'Otimização pendente' na sheet que permite re-otimizar imediatamente. O RotPro não tem esse indicador — o usuário não recebe feedback visual de que a rota precisa ser re-otimizada. Isso é um gap funcional real: após editar uma parada em uma rota otimizada, o motorista pode sair sem saber que a rota ficou desatualizada.
- **fix:** Implementar como PR-C per o plano já documentado: adicionar um widget de banner no topo da sheet no estado DRAFT que já foi PRE-CONFIRM (estado 'needsReoptimization' — detectável por isPreConfirm=false + stops.isNotEmpty + rota previamente otimizada). O banner deve ter uma ação 'Otimizar agora' que dispara _onOptimize(). Microcopy sugerida PT-BR: 'Rota desatualizada — toque para otimizar novamente'.


## Area 4 — Adicionar parada (método texto + autocomplete Google Places)
_Veredito: high_

A Área 4 está em alta paridade funcional. A estrutura principal (3 estados de UI selados, 2 seções de resultados, footer "Escolher no mapa", microcopy variável por stopCount, ícones OCR+Voz no search bar que somem ao digitar, toast pós-add com ação "Ver") está implementada e alinhada ao dump. Foram identificados 4 drifts: (1) debounce 800 ms no Spoke vs 500 ms no RotPro — diferença perceptível em digitação rápida; (2) search bar placeholder varia por stopCount em 4 variantes no Spoke mas o RotPro usa texto fixo; (3) o flow pós-adição de parada (BIG FIND — edição inline sem pop) está documentado como gap intencional da Área 6, mas conta como drift de paridade enquanto não for fechado; (4) a variante de microcopy "Pesquise um endereço para adicionar a primeira parada" (search_emptystate_nostops), que o Spoke usa quando o recurso AddStop está feature-gated, não existe no RotPro — aceitável porque o RotPro não tem feature-gate de tier (sempre habilitado). Não foram encontrados campos ausentes, enums incompletos, gates errados ou fluxos de navegação divergentes além dos já documentados nas specs.

### A4-D1 [should-fix] — Debounce de autocomplete: 800 ms no Spoke vs 500 ms no RotPro
- **categoria:** wrong-default
- **impl:** apps/mobile/lib/features/routes/state/place_autocomplete_provider.dart:36 — `Timer(const Duration(milliseconds: 500), ...)`
- **dump:** ~/spoke-dump/jadx-out/sources/com/circuit/p016ui/search/SearchViewModel.java:869 — `kotlinx.coroutines.C24060g.m38104b(800, r7)` — o Spoke aguarda 800 ms antes de disparar a query de autocomplete
- **detalhe:** O Spoke espera 800 ms de inatividade antes de disparar a busca. Nossa impl usa 500 ms. Com 500 ms, o Places API recebe requisições para strings intermediárias (ex.: 'R', 'Ru', 'Rua') que o Spoke descartaria, aumentando consumo de cota da Places API e podendo exibir resultados transitórios para queries incompletas. A diferença é perceptível em digitação rápida: o RotPro mostra resultados para 'Ru' antes que o usuário termine de digitar 'Rua Paulista', enquanto o Spoke esperaria o usuário pausar por 800 ms.
- **fix:** Mudar `Duration(milliseconds: 500)` para `Duration(milliseconds: 800)` em `place_autocomplete_provider.dart`. Isso reduz chamadas desnecessárias à API sem impacto perceptível em UX (800 ms é o threshold que o Spoke escolheu como ideal para o fluxo de entrega B2C).

### A4-D2 [nit] — Search bar placeholder é fixo no RotPro; Spoke varia por faixa de stopCount (0 / 1-5 / 6+)
- **categoria:** string-mismatch
- **impl:** apps/mobile/lib/features/route_config/state/picker_mode.dart:26 — `hintText: 'Digite o endereço da parada'` (fixo para o modo addStop); apps/mobile/lib/features/routes/presentation/widgets/add_stop_search_bar.dart:81 — `hintText: widget.hintText ?? 'Digite o endereço da parada'`
- **dump:** ~/spoke-dump/jadx-out/sources/com/circuit/p016ui/search/SearchBarPlaceholder.java:42-55 — enum `SearchBarPlaceholder` com 6 variantes; ~/spoke-dump/jadx-out/sources/com/circuit/p016ui/search/SearchViewModel.java:1334 — lógica: voiceActive → 'Entrada por voz ativada'; picker → 'Insira um endereço' (add_stop_placeholder); 0 stops → 'Digite para adicionar' (NoStops focused) / 'Toque para adicionar' (unfocused); 1-5 stops → 'Digite para adicionar' (FewStops); 6+ stops → 'Adicione ou busque' (ManyStops); strings-pt-rBR:2090-2096.
- **detalhe:** O Spoke adapta o hint text do campo de busca em 3 faixas de stopCount: 0 stops = 'Digite para adicionar' (focused) / 'Toque para adicionar' (unfocused); 1-5 stops = 'Digite para adicionar'; 6+ stops = 'Adicione ou busque'. O RotPro usa texto fixo 'Digite o endereço da parada'. A divergência não impede nenhuma função mas cria UX levemente diferente para rotas com muitas paradas (6+), onde o Spoke sinaliza que a busca também é para paradas existentes.
- **fix:** Derivar o hint text do `stopCount` proveniente de `currentRouteStopsProvider`. Para paridade funcional mínima: 0-5 stops → manter 'Digite o endereço da parada' (nossa microcopy original); 6+ stops → algo como 'Adicione ou busque paradas'. Não copiar verbatim do Spoke; usar redação original RotPro com o mesmo significado.

### A4-D3 [must-fix] — Pós-adição de parada: edição inline ausente (BIG FIND — gap intencional Área 6)
- **categoria:** flow-divergence
- **impl:** apps/mobile/lib/features/routes/presentation/pages/add_stop_page.dart:157 — `context.pop<Object?>(newStop.id)` após addStop bem-sucedido; apps/mobile/lib/features/routes/presentation/route_shell_page.dart:535-550 — shell consome o pop e exibe SnackBar 'Parada adicionada' + ação 'Ver'. O spec docs/superpowers/specs/2026-05-28-area4-add-stop-text-method.md §Q2 registra este gap como intencional.
- **dump:** ~/spoke-dump/jadx-out/resources/res/values-pt-rBR/strings.xml:412 — `added_stop_toast_message` = 'Parada adicionada'; linha 751 — `duplicate_stop_toast_view_action` = 'Ver'. ~/spoke-dump/jadx-out/sources/com/circuit/p016ui/search/SearchViewModel.java:1029-1040 — após addStop bem-sucedido, emite `bj0(9, this, baseStopId)` (toast com ação Ver via BottomToasts) e mantém o state da tela de busca vivo (não faz pop). O `EditStopDialogFragment` desliza inline sobre o search screen, não via navegação separada (confirmed em docs/inventory §11.4 amendment 4 + spec area6 §1).
- **detalhe:** No Spoke, após tap em resultado da Section B: (1) stop é criado; (2) toast 'Parada adicionada' + ação 'Ver' aparece; (3) a tela de busca permanece aberta e um `EditStopDialogFragment` desliza inline debaixo da search bar — o usuário pode imediatamente continuar digitando mais paradas. No RotPro, o `context.pop()` fecha completamente a tela de busca e retorna ao shell; o shell mostra o toast + 'Ver' e o usuário precisa re-abrir o add-stop para a próxima parada. Isso quebra o fluxo 'adicionar várias paradas sem sair da busca', que é o caso de uso central do entregador.
- **fix:** Área 6 fecha este gap: em vez de `context.pop()`, manter o add-stop aberto e exibir um DraggableScrollableSheet inline com o editor da parada recém-criada. A search bar permanece interativa no topo. Quando o usuário dispensar o editor (swipe-down ou salvar), o add-stop volta ao estado de busca. Ver docs/superpowers/specs/2026-05-28-area4-add-stop-text-method.md §Q2 e §Open items for Area 6.

### A4-D4 [nit] — Microcopy vazio para modo picker: search_emptystate_nostops ausente (aceitável — sem feature gate)
- **categoria:** missing-state
- **impl:** apps/mobile/lib/features/routes/application/add_stop_ui_state.dart:56-59 — `EmptyVariant` com apenas `stopCount`; apps/mobile/lib/features/route_config/state/picker_mode.dart:38-44 — `startLocation` / `endLocation` retornam body vazio (sem microcopy). Não há variante para estado 'feature desabilitada'.
- **dump:** ~/spoke-dump/jadx-out/sources/com/circuit/p016ui/search/WaitingForQueryMessage.java:36-38 — `SearchFindStops` (ordinal 0) = `R.string.search_emptystate_cant_add_stop` = 'Encontrar paradas nesta rota'; `SearchNoStops` (ordinal 1) = `R.string.search_emptystate_nostops` = 'Pesquise um endereço para adicionar a primeira parada'. ~/spoke-dump/jadx-out/sources/com/circuit/p016ui/search/SearchViewModel.java:980-987 — `m9989L()` verifica `AppFeature.AddStop` feature gate; linha 1344-1346 — quando gate desabilitado, exibe `SearchFindStops`.
- **detalhe:** O Spoke possui um quinto estado de microcopy — 'Encontrar paradas nesta rota' — exibido quando o recurso AddStop está bloqueado por plano (usuário Free sem o gate). O RotPro não tem tiers de plano além do único pago (ADR-0030), então AddStop é sempre habilitado. A variante `search_emptystate_nostops` = 'Pesquise um endereço para adicionar a primeira parada' é usada pelo Spoke em Picker modes com 0 stops e não impacta o fluxo addStop direto. Ambas as variantes ausentes são funcionalmente irrelevantes para o RotPro por design (sem feature gate, sem Picker mode com 0 stops retornando microcopy). Registrado por completude do mapeamento.
- **fix:** Nenhuma ação necessária para os estados feature-gated (o RotPro sempre tem AddStop habilitado). Para a variante 'Pesquise um endereço' dos pickers (startLocation/endLocation com 0 resultados), o body já está vazio per Spoke baseline — comportamento correto. Sem mudança necessária.


## Area 5 — Detalhes da rota (Partida / Destino / Pausa / TimePicker numpad / persistência route_defaults)
_Veredito: medium_

A implementação Flutter da Área 5 está estruturalmente fiel ao dump do Spoke v3.65.1 nos aspectos principais: layout do numpad 4x3, seções Partida/Destino/Pausa, 3-card sheet do Destino, página full-screen da Pausa com janela de horário + duração livre, checkbox "Salvar como padrão" de nível-página, e persistência via SharedPreferences. Quatro drifts funcionais confirmados: (1) o CTA do BreakSchedulerPage em modo ADD usa "Concluído" em vez de "Adicionar pausa"; (2) o diálogo de remoção de pausa omite o parâmetro de duração que o Spoke injeta no texto ("a pausa de Xmin"); (3) o botão de confirmar remoção diz "Remover" em vez de "Remover pausa"; (4) o subtitle da linha RoundTrip em Detalhes da rota sempre mostra o texto "sem startLocation" mesmo quando o usuário já escolheu um local de partida. Um quinto drift menor existe no config summary do shell: o subtitle da linha Início não muda para "Posição do GPS usada ao otimizar" após o usuário setar um endereço customizado. Nenhum campo ou opção do dump está completamente ausente da impl. O suporte a múltiplas pausas do RotPro é uma feature aditiva legítima (Spoke limita a 1 pausa em setup).

### A5-D1 [should-fix] — CTA do modo ADD na tela de pausa usa 'Concluído' em vez de 'Adicionar pausa'
- **categoria:** string-mismatch
- **impl:** apps/mobile/lib/features/route_config/presentation/pages/break_scheduler_page.dart:449 — `child: const Text('Concluído', ...)` sem distinção de modo; comentário na linha 26-29 afirma incorretamente que Spoke usa 'Concluído' em AMBOS os modos
- **dump:** ~/spoke-dump/jadx-out/sources/p000/qt0.java:103-104 — `if (wi8.m45958a(breakSetupArgs, BreakSetupArgs.AddBreak.f33692b)) { g3cVar3 = new g3c(R.string.break_screen_add_break_button, new Object[0]); }` — break_screen_add_break_button = 'Adicionar pausa' (strings.xml); UpdateBreak/EditBreak -> `R.string.done` = 'Concluído'
- **detalhe:** O Spoke diferencia o label do CTA principal por modo: AddBreak -> 'Adicionar pausa'; UpdateBreak/EditBreak -> 'Concluído'. O RotPro usa 'Concluído' nos dois modos. Na prática o usuário que abre a tela para ADICIONAR uma pausa nunca vê 'Adicionar pausa' — o botão já diz que a ação está concluída antes de ele confirmar.
- **fix:** Em `BreakSchedulerPage._ConfirmButton`, passar o texto como parâmetro e resolvê-lo no estado: quando `initialBreak == null` (ADD mode) -> 'Adicionar pausa'; quando `initialBreak != null` (EDIT mode) -> 'Concluído'. Microcopy PT-BR original: 'Adicionar pausa' para add, 'Concluído' para edit.

### A5-D2 [should-fix] — Diálogo 'Remover pausa' não inclui a duração da pausa no texto de confirmação
- **categoria:** string-mismatch
- **impl:** apps/mobile/lib/features/route_config/presentation/pages/break_scheduler_page.dart:496 — `content: const Text('Quer mesmo remover esta pausa da sua rota?')` — texto estático sem parâmetro de duração
- **dump:** ~/spoke-dump/jadx-out/resources/res/values-pt-rBR/strings.xml:1949 — `remove_break_confirmation_dialog_description` = 'Quer remover a pausa de %1$s da sua rota?'; ~/spoke-dump/jadx-out/sources/com/circuit/components/dialog/DialogC2604j.java:16 — `new g3c(R.string.remove_break_confirmation_dialog_description, new Object[]{str})` onde `str` é a duração formatada (ex: '30 min')
- **detalhe:** O Spoke passa a duração da pausa como parâmetro %1$s no texto de confirmação ('Quer remover a pausa de 30 min da sua rota?'), tornando o diálogo contextual. O RotPro mostra um texto genérico sem a duração. Além disso a estrutura da frase difere: Spoke usa 'Quer remover' (sem 'mesmo'), RotPro usa 'Quer mesmo remover'.
- **fix:** Modificar `_RemoveBreakDialog` para receber a duração como parâmetro (`final int durationMinutes`) e compor o texto como 'Quer remover a pausa de N min da sua rota?'. Microcopy PT-BR sugerido: 'Quer remover a pausa de N min da sua rota?' onde N é `durationMinutes`. Passar `_durationMinutes` do pai ao construir o diálogo.

### A5-D3 [nit] — Botão de confirmar remoção de pausa diz 'Remover' em vez de 'Remover pausa'
- **categoria:** string-mismatch
- **impl:** apps/mobile/lib/features/route_config/presentation/pages/break_scheduler_page.dart:513 — `child: const Text('Remover')`
- **dump:** ~/spoke-dump/jadx-out/resources/res/values-pt-rBR/strings.xml:466 — `break_detail_sheet_remove_button` = 'Remover pausa'; ~/spoke-dump/jadx-out/sources/com/circuit/components/dialog/DialogC2604j.java:16 — `new g3c(R.string.break_detail_sheet_remove_button, new Object[0])` como label do botão de confirmação
- **detalhe:** O label do botão de confirmar no AlertDialog de remoção de pausa do Spoke é 'Remover pausa' (não apenas 'Remover'). A versão completa é mais explícita sobre o que será removido, reduzindo risco de toque acidental.
- **fix:** Alterar o Text do botão confirm em `_RemoveBreakDialog` de 'Remover' para 'Remover pausa'. Microcopy PT-BR sugerido: 'Remover pausa'.

### A5-D4 [should-fix] — Subtitle da linha RoundTrip em RouteDetailsPage ignora o startLocation configurado
- **categoria:** wrong-default
- **impl:** apps/mobile/lib/features/route_config/presentation/pages/route_details_page.dart:427-431 — `_destinationSubtitle` retorna SEMPRE 'Viagem de ida e volta a partir do local atual' para RoundTrip, sem condicionar à presença de `config.startLocation`
- **dump:** ~/spoke-dump/jadx-out/sources/com/circuit/p016ui/setup/RouteSetupViewModel.java:388-394 — quando `z=true` (roundtrip) e `address3 != null` (startLocation definido): `string = application.getString(R.string.roundtrip_from_x, f24094n1)` = 'Ida e volta de [nome]'; somente quando `address3 == null`: `string = application.getString(R.string.roundtrip_from_current)` = 'Viagem de ida e volta a partir do local atual'. Strings: roundtrip_from_x = 'Ida e volta de %1$s' (strings.xml:2003), roundtrip_from_current = 'Viagem de ida e volta a partir do local atual' (strings.xml:2001 area)
- **detalhe:** Quando o usuário configura um local de partida (Partida > Local), a linha Destino no Spoke muda o subtitle de 'Viagem de ida e volta a partir do local atual' para 'Ida e volta de [nome do local]'. O RotPro exibe sempre o subtitle do estado sem localização, mesmo após o usuário escolher um endereço de partida específico.
- **fix:** Em `_destinationSubtitle`, condicionar o subtitle de RoundTrip: quando `config.startLocation != null && !config.startLocation!.isUserCurrentLocation` retornar 'Ida e volta de ${config.startLocation!.address}'; caso contrário retornar 'Viagem de ida e volta a partir do local atual'. Requer passar `config` inteiro para `_destinationSubtitle` ou torná-lo um método no nível da página que já tem acesso ao config.

### A5-D5 [nit] — Config summary no shell: subtitle da linha Início não muda quando startLocation customizado é definido
- **categoria:** string-mismatch
- **impl:** apps/mobile/lib/features/routes/presentation/route_shell_page.dart:1505 — `subtitle: 'Use a posição do GPS ao otimizar'` fixo no RouteConfigRow da linha Início, independente de `startLocation` estar definido ou não
- **dump:** ~/spoke-dump/jadx-out/resources/res/values-pt-rBR/strings.xml:2167-2169 — dois subtítulos distintos: `start_location_gps_used_subtitle` = 'Posição do GPS usada ao otimizar' (quando endereço customizado está set) e `start_location_use_gps_subtitle` = 'Use a posição do GPS ao otimizar' (quando em modo GPS/atual). A distinção presente → passado indica estado do campo ao usuário.
- **detalhe:** No config summary da rota ativa, o Spoke alterna o subtitle da linha Início: GPS mode -> 'Use a posição do GPS ao otimizar' (futuro/instrução); custom address set -> 'Posição do GPS usada ao otimizar' (passado/confirmação). O RotPro mantém sempre o texto no modo GPS mesmo quando um endereço custom foi escolhido.
- **fix:** Em `_ConfigSummarySection.build` (route_shell_page.dart), adicionar leitura condicional do subtitle: quando `startLocation != null && !startLocation.isUserCurrentLocation` usar 'Posição do GPS usada ao otimizar'; caso contrário 'Use a posição do GPS ao otimizar'. Microcopy PT-BR original sugerido: respectivamente 'Posição do GPS usada ao otimizar' e 'Use a posição do GPS ao otimizar'.


## flow:stop:edit (Área 6 — Editar parada, 14 campos)
_Veredito: high_

A implementação Flutter da Área 6 está em alta fidelidade funcional com o dump v3.65.1. Todos os 14 campos/ações do editor estão presentes: chip cor+ID, card endereço, instruções de acesso, notas+foto, localizador de pacotes (sheet inline com 5 componentes), stepper de pacotes + dialog free-text, segmented Ordem/Tipo, janela de chegada (2 lados nullable), tempo na parada (min+seg, null herda default global), mudar endereço, duplicar, remover. O domínio (Stop, StopColor×5, StopOrderPolicy, PackageDetails, PlaceInVehicle) bate enumeração a enumeração com o jadx. Foram encontrados 3 drifts: (1) must-fix de fluxo — ao confirmar a remoção DEFERIDA (rota otimizada), o Spoke descarta o editor (dismiss); o RotPro mantém o editor aberto com a parada marcada; (2) should-fix de surface type — o Spoke usa BottomSheet para o dialog de pacotes; RotPro usa AlertDialog (comportamento equivalente, forma diferente); (3) nit de string na remoção normal — RotPro adiciona "mesmo" ao texto do confirm. Nenhum campo ou enum faltando.

### A6-D1 [must-fix] — Remoção DEFERIDA (rota otimizada): Spoke descarta o editor após confirmar; RotPro não
- **categoria:** flow-divergence
- **impl:** apps/mobile/lib/features/routes/presentation/pages/edit_stop_page.dart:300-362 — método `_confirmRemove`: após chamar `markStopForDeferredRemoval`, o código tem comentário explícito 'Sem pop: a parada permanece visível marcada — sai na próxima otimização.' e NÃO faz `context.pop()`.
- **dump:** ~/spoke-dump/jadx-out/sources/com/circuit/p016ui/edit/EditStopDialogFragment$Content$1$1$4$1$1.java:31-33 — quando `abstractC3352j instanceof AbstractC3352j.c` (Deleted), Spoke chama `editStopDialogFragment.m4281m(false, false)` que é o dismiss do AdaptiveModalFragment. AbstractC3352j.c.toString() = 'Deleted' (AbstractC3352j.java:103). Este evento é emitido por EditStopViewModel$onConfirmDeleteStopOnOptimizationClick$1.java:71 após C2975r.m8864a (use-case que marca para remoção). O dialog que aciona isso é DialogC2612n (ConfirmDeleteStopOnOptimizationDialog.java) com strings: título=remove_stop_title='Remover parada', corpo=remove_stop_on_optimization_confirmation_dialog_text='A parada "%1$s" será removida da rota na próxima otimização.'
- **detalhe:** No fluxo de remoção quando a rota está OTIMIZADA (PRE-CONFIRM), o Spoke: (1) mostra AlertDialog com título 'Remover parada' e corpo 'A parada "%1$s" será removida da rota na próxima otimização.'; (2) ao confirmar, emite HostEvent(Deleted) que dispara o dismiss do EditStopDialogFragment (o editor fecha). O RotPro executa os passos (1) e (2) corretamente — mostra o dialog e chama markStopForDeferredRemoval — mas depois NÃO fecha o editor. O usuário fica no editor com a parada ainda visível, sem feedback visual de que ela foi marcada para remoção. A decisão de 'sem pop' foi tomada no código com um comentário de dúvida ('Se o produto preferir popar e mostrar a parada riscada na lista do shell...'), mas o dump confirma inequivocamente: Spoke fecha.
- **fix:** Em `_confirmRemove`, após `markStopForDeferredRemoval`, adicionar `if (mounted && context.canPop()) context.pop()` — espelhando o path do branch de rota DRAFT. O stop marcado aparecerá na lista do shell com `pendingRemoval=true`; a lista já lê esse campo no `_StopCard`. Microcopy original sugerida para o dialog: título='Remover parada', corpo='A parada "$stopLabel" será removida da rota na próxima otimização.' (funcional, original).

### A6-D2 [should-fix] — Dialog de contagem de pacotes: Spoke usa BottomSheet; RotPro usa AlertDialog
- **categoria:** flow-divergence
- **impl:** apps/mobile/lib/features/routes/presentation/widgets/package_count_dialog.dart:24 — `showDialog<int>(barrierDismissible: true, builder: (_) => _PackageCountDialogBody(...))`; apresentado como Dialog modal centralizado.
- **dump:** ~/spoke-dump/jadx-out/sources/com/circuit/p016ui/dialogs/packagecount/ — o arquivo principal compila de PackageCountDialog.kt mas todas as inner classes são nomeadas `PackageCountDialogKt$PackageCountSheet$*` (sufixo `Sheet`, não `Dialog`); ~/spoke-dump/jadx-out/sources/p000/owa.java compila de PackageCountDialog.kt (a classe que representa o Sheet no jadx). Isso indica que o widget do Spoke é um BottomSheet, não um Dialog centrado. Strings confirmadas: `stop_setting_packages_title`='Pacotes', `stop_setting_package_count`='Número de pacotes' (strings.xml:1990-1992).
- **detalhe:** O Spoke apresenta o seletor de quantidade de pacotes como um BottomSheet (PackageCountSheet) que desliza de baixo. O RotPro implementou como AlertDialog centralizado. Funcionalmente o comportamento é idêntico: campo free-text com dígitos, placeholder '1', clamp 1..9999, commit-on-dismiss. A diferença é puramente na forma de apresentação (modal centralized vs bottom sheet). No contexto de um device Android (M54), a distinção é visível ao usuário.
- **fix:** Converter `PackageCountDialog` de `showDialog` para `showModalBottomSheet` com `useRootNavigator: true, useSafeArea: true` — mesmo padrão dos outros sheets da Á6 (ColorPickerSheet, ArrivalWindowSheet, PackageFinderSheet). O conteúdo interno (campo, clamp, commit-on-dismiss via PopScope) fica inalterado. Nenhuma mudança de API necessária — o tipo de retorno `Future<int>` permanece.

### A6-D3 [nit] — Dialog de remoção normal (draft): RotPro usa 'Quer mesmo remover' vs Spoke 'Quer remover'
- **categoria:** string-mismatch
- **impl:** apps/mobile/lib/features/routes/presentation/pages/edit_stop_page.dart:334-338 — `content: Text('Quer mesmo remover "${stop.streetName}" da rota?', ...)`
- **dump:** ~/spoke-dump/jadx-out/resources/res/values-pt-rBR/strings.xml:1959 — `remove_stop_confirmation_dialog_text` = 'Quer remover "%1$s" da rota?' (sem 'mesmo'). A estrutura (um argumento de string = nome/streetName da parada) é idêntica.
- **detalhe:** A estrutura do dialog de confirmação de remoção em rota DRAFT é idêntica: título 'Remover parada', corpo com o nome da parada interpolado, botões Cancelar/Remover. A única diferença é a palavra 'mesmo' adicionada na microcopy do RotPro ('Quer mesmo remover' vs 'Quer remover'). Isso é microcopy original RotPro, permitida por ADR-0035, mas vale registrar que existe a divergência textual. Não impacta funcionalidade.
- **fix:** Opcional: alinhar para 'Quer remover "$streetName" da rota?' se quiser maior consistência funcional-textual. Porém, como ADR-0035 permite microcopy original, esta é uma decisão de produto, não um bug.


## route:optimize
_Veredito: medium_

Audit dump-only da Área 7 (estado, solver, PRE-CONFIRM, markers, reotimizar, FTUE) contra o dump estático Spoke v3.65.1. A estrutura de dados é fiel (RouteState flags+timestamps, OptimizationState enum, OptimizeType 4 valores, OptimizeDirection, PackageLabelFormat, pendingRemoval, FTUE one-shot). O funil de otimização (CTA -> progresso -> PRE-CONFIRM -> Refinar/Reotimizar) existe e o roteamento de estado derivado está correto. Os drifts encontrados concentram-se em dois clusters: (1) microcopy estrutural divergindo do dump em 3 widgets de sheet/diálogo (strings de fase de progresso, sheet Refinar, sheet Reotimizar); (2) falta dos widgets do PR-C (ReadyToRunView, IdLockDialog, DiscardChangesDialog, banner "Otimização pendente") que foram explicitamente marcados como honest-stubs no branch atual. O kebab do PRE-CONFIRM também pula o item intermediário "Reotimizar rota..." que o Spoke exibe antes de abrir o sheet. A implementação de IdEducationDialog tem estrutura funcional correta (two choices, one-shot) mas com título/corpo/label-de-botão divergentes do dump. Refine sheet usa ícones do Material Design em vez de Lucide (violação menor de ADR-0035).

### A7-D1 [must-fix] — Fases de progresso com labels divergentes do dump
- **categoria:** string-mismatch
- **impl:** apps/mobile/lib/features/routes/presentation/widgets/optimizing_progress_view.dart:14-17 — labels: 'Conferindo suas entregas...', 'Montando a melhor sequência...', 'Avaliando o trânsito na região...', 'Finalizando sua rota...'
- **dump:** strings.xml:1780-1784 — optimizing_analysing='Analisando suas paradas...'; optimizing_sorting='Encontrando a melhor ordem...'; optimizing_traffic='Considerando o trânsito...'; optimizing_creating='Criando sua rota...'
- **detalhe:** Todos os 4 rótulos de fase da OptimizingProgressView foram reescritos livremente sem seguir o dump. A estrutura das 4 fases em si está correta (analysing/sorting/traffic/creating na ordem certa), mas o significado funcional de cada label muda: 'Avaliando o trânsito na região' implica que o app consulta trânsito em tempo real (o que o solver on-device Slice 2 NÃO faz); 'Analisando suas paradas...' do Spoke é neutro e preciso. É um bug de comunicação para o usuário.
- **fix:** Alinhar os 4 labels com frases PT-BR originais semanticamente equivalentes às do Spoke: fase analysing → algo como 'Verificando as paradas...'; sorting → 'Encontrando a melhor sequência...'; traffic → 'Calculando a rota...'; creating → 'Preparando a rota...'. Evitar mencionar 'trânsito' nesta fase no Slice 2 (sem dados reais de trânsito). A string exata do dump é referência de significado, não de cópia verbatim.

### A7-D2 [must-fix] — RefineRouteSheet com título e itens divergentes do dump
- **categoria:** string-mismatch
- **impl:** apps/mobile/lib/features/routes/presentation/widgets/refine_route_sheet.dart:10,29,38-49 — título 'Ajustar a rota'; item 1 title 'Inverter a ordem' / subtitle 'Percorre as paradas de trás pra frente'; item 2 title 'Definir a ordem na mão' / subtitle 'Você arrasta as paradas na sequência que quiser'
- **dump:** strings.xml:1967-1972 — refine_route_dialog_title='Refinar a rota'; refine_route_dialog_reverse_title='Inverter a rota' / refine_route_dialog_reverse_description='Inverter a direção da rota'; refine_route_dialog_manual_title='Ordenar a rota manualmente' / refine_route_dialog_manual_description='Definir a ordem da rota desenhando no mapa'
- **detalhe:** Três divergências simultâneas no mesmo sheet: (1) título do sheet é 'Ajustar a rota' em vez de 'Refinar a rota' — importante porque 'Refinar' é o mesmo label do botão que abre o sheet (refine_route_button_title='Refinar'); (2) o item de inversão usa 'Inverter a ordem' em vez de 'Inverter a rota' e subtitle diferente; (3) o item de ordem manual usa 'Definir a ordem na mão' em vez de 'Ordenar a rota manualmente' — o dump especifica claramente 'desenhando no mapa' (OrderStopGroups). A inconsistência entre o label do botão 'Refinar' e o título do sheet 'Ajustar a rota' pode confundir o usuário.
- **fix:** Atualizar refine_route_sheet.dart: título → equivalente PT-BR de 'Refinar a rota'; item Inverter → título equivalente a 'Inverter a rota' / subtitle equivalente a 'Inverter a direção da rota'; item Manual → título equivalente a 'Ordenar a rota manualmente' / subtitle equivalente a 'Definir a ordem da rota desenhando no mapa'. Manter a estrutura funcional (dois ListTile, retorno enum RefineRouteChoice) — só atualizar a copy.

### A7-D3 [must-fix] — ReoptimizeOptionsSheet com título e itens divergentes do dump
- **categoria:** string-mismatch
- **impl:** apps/mobile/lib/features/routes/presentation/widgets/reoptimize_options_sheet.dart:43-87 — título 'Como recalcular'; item 1 title 'Ajustar o que mudou' / subtitle 'Mantém a rota e reposiciona só as paradas novas'; item 2 title 'Recalcular do zero' / subtitle 'Refaz a sequência inteira em busca da melhor ordem'
- **dump:** strings.xml:2001='Alternativas de reotimização' (reoptimization_options_view_title); strings.xml:2427='Atualizar rota' (update_route) + strings.xml:1767='Reordenar apenas as paradas alteradas' (optimization_dialog_update_route_subtitle); strings.xml:2003='Reotimizar rota' (reoptimize_title) + strings.xml:1766='Reordenar todas as paradas para melhor eficiência' (optimization_dialog_reoptimize_route_subtitle). Evidência de código: com/circuit/p016ui/dialogs/applychanges/AbstractC3271c.java:29,63 confirma estes pares título/subtitle; C3269a.java:65 usa reoptimization_options_view_title como título do sheet.
- **detalhe:** O sheet de reotimização tem título e ambos os itens com texto diferente do dump em todas as 6 strings (título + 2×título-de-item + 2×subtitle-de-item). O mais crítico: o título 'Como recalcular' não corresponde a nenhuma string do dump, e os nomes dos itens são reescritas livres que mudam o significado ('Ajustar o que mudou' vs 'Atualizar rota', 'Recalcular do zero' vs 'Reotimizar rota'). O usuário que vem do Spoke reconhece 'Atualizar rota' e 'Reotimizar rota' — os nomes da impl são genéricos e perdem essa familiaridade.
- **fix:** Atualizar reoptimize_options_sheet.dart: título → equivalente PT-BR de 'Alternativas de reotimização'; item update → título 'Atualizar rota' (ou similar) / subtitle equivalente a 'Reordenar apenas as paradas alteradas'; item reoptimize → título 'Reotimizar rota' (ou similar) / subtitle equivalente a 'Reordenar todas as paradas para melhor eficiência'. A lógica funcional (ReoptimizeChoice.update → reorderFlexible, .reoptimize → restartRoute) está correta; só atualizar a copy.

### A7-D4 [must-fix] — Kebab do PRE-CONFIRM pula o item intermediário 'Reotimizar rota...' do menu
- **categoria:** flow-divergence
- **impl:** apps/mobile/lib/features/routes/presentation/widgets/pre_confirm_view.dart:39-43 — IconButton com onPressed: onReoptimize abre o sheet diretamente, sem menu intermediário. apps/mobile/lib/features/routes/presentation/route_shell_page.dart:414-415 — onReoptimize: _onReoptimize chama showReoptimizeOptionsSheet diretamente.
- **dump:** strings.xml:1595 — more_options_reoptimize_route_title='Reotimizar rota...' é um item no menu kebab da rota. jadx: com/circuit/p016ui/dialogs/applychanges/C3269a.java:65 — o sheet 'Alternativas de reotimização' é navegado via ShowReoptimizeRouteDialog, que é emitido pelo ViewModel ao tocar o item de menu 'Reotimizar rota...'.
- **detalhe:** No Spoke, o kebab abre um PopupMenu/dropdown com vários itens (incluindo 'Reotimizar rota...', 'Pular otimização', etc.). Tocar 'Reotimizar rota...' no menu ENTÃO abre o 'Alternativas de reotimização' sheet. Na implementação RotPro, o tap no kebab (moreVertical) abre o ReoptimizeOptionsSheet diretamente, sem o nível intermediário do menu. Isso torna o kebab equivalente a um botão direto, e perde outros itens que deveriam estar no menu (ex: 'Pular otimização', que existe em MASTER-TABLE #20). O route_shell_page.dart DRAFT tem kebab via _comingSoon stub, mas o PreConfirmView tem kebab direto.
- **fix:** Implementar PopupMenuButton no PreConfirmView com pelo menos 2 itens: (1) equivalente de 'Reotimizar rota...' → abre ReoptimizeOptionsSheet; (2) equivalente de 'Pular otimização' (#20 MASTER-TABLE) → ação de skip com confirmação. A estrutura de showMenu/PopupMenuButton do Flutter suporta isso nativamente. O item 'Pular otimização' estava na spec original mas ficou fora do PRE-CONFIRM; o kebab é o lugar correto.

### A7-D5 [must-fix] — ReadyToRunView ausente — Confirmar é honest-stub que não avança o estado
- **categoria:** missing-feature
- **impl:** apps/mobile/lib/features/routes/presentation/route_shell_page.dart:701-708 — _onConfirm() é stub: exibe SnackBar 'Tudo certo — a confirmação final chega na próxima etapa.' sem gravar confirmed:true. Nenhum arquivo ready_to_run_view.dart existe no codebase (grep confirma ausência).
- **dump:** Spec 2026-06-13-area7-optimize-route-design.md §Sub-slice PR-C — ReadyToRunView (2 botões-linha 'Em breve' + 'Editar' volta ao PRE-CONFIRM + 'Iniciar rota' + banner 'Otimização pendente'). strings.xml:775 — edit_route_button_title='Editar'; strings.xml:2204 — start_route_early_button='Iniciar antes…'. O estado isReadyToRun existe em route_state.dart:45 mas nenhum widget o consome.
- **detalhe:** O PR-C (Ready-to-Run + Confirmar + Iniciar rota + Editar + Descartar alterações) foi planejado mas ainda não entregue. O resultado é que o usuário nunca sai do PRE-CONFIRM — 'Confirmar' apenas mostra um SnackBar e o estado confirmed:true nunca é gravado. O RouteLifecycleController equivalente do Spoke (RouteLifecycleController$onConfirmRouteClick) tem toda a lógica de confirmed/IdLockDialog/start que falta aqui. O isReadyToRun getter existe no domínio mas não tem renderização.
- **fix:** Implementar PR-C: (a) ReadyToRunView com os 2 botões-linha ('Compartilhar rota em tempo real' e 'Carregar veículo' com honest-stub 'Em breve'), rodapé com tempo-display + botões 'Editar'/'Iniciar rota'; (b) _onConfirm() grava confirmed:true via routesProvider.notifier.confirmRoute(); (c) o switch de estado no build() do shell expande para cobrir isReadyToRun (atualmente a lógica só bifurca DRAFT vs PRE-CONFIRM); (d) 'Editar' grava confirmed:false voltando ao PRE-CONFIRM; (e) 'Iniciar rota' emite SnackBar 'Em breve' (Área 8).

### A7-D6 [must-fix] — IdLockDialog ausente — tela de confirmação não dispara o FTUE de IDs definitivos
- **categoria:** missing-feature
- **impl:** ausente — nenhum arquivo id_lock_dialog.dart existe. O FTUE de 'idLockAcknowledged' não está no OptimizationFtueRepository (apps/mobile/lib/features/routes/state/optimization_ftue_repository.dart — só tem a key 'numbering_ftue_v1').
- **dump:** strings.xml:1830-1831 — package_identification_lock_dialog_title='Os IDs serão definitivos'; package_identification_lock_dialog_body='Após a confirmação, mesmo que você faça alterações na rota, os IDs não mudarão.' jadx: RouteLifecycleController.java:513-518 — m9614h() verifica PackageLabelMode == OPTIMIZED && !packageLabelIdLockAcknowledged → emite ShowPackageLabelIdLockDialog; quando positivo, m9618l() seta o flag e prossegue com onConfirmRouteClick. Spec 2026-06-13:§Confirm→Ready-to-Run — 'Se !idLockAcknowledged, mostra IdLockDialog one-shot'.
- **detalhe:** A spec previa o IdLockDialog como parte do fluxo de Confirmar (PR-C), com a condição exata do Spoke: só aparece quando PackageLabelMode é OPTIMIZED (depois da otimização) e o flag não foi reconhecido. O OptimizationFtueRepository só rastreia 'numbering' (IdEducationDialog da 1ª otimização) mas não 'idLock' (IdLockDialog do Confirmar). Sem este segundo FTUE, o usuário não recebe o aviso de que os IDs ficam fixos após a confirmação.
- **fix:** Adicionar ao OptimizationFtueRepository: chave 'id_lock_ftue_v1' com isIdLockAcknowledged()/acknowledgeIdLock(). Criar id_lock_dialog.dart com título equivalente a 'Os IDs serão definitivos', corpo equivalente a 'Após a confirmação os IDs não mudarão', botões 'Cancelar'/'Continuar'. Chamar em _onConfirm() do shell ANTES de gravar confirmed:true, com a condição: format == moderno && !idLockAcknowledged (PackageLabelMode.OPTIMIZED no Spoke é equivalente ao nosso default moderno pós-otimização).

### A7-D7 [must-fix] — DiscardChangesDialog ausente — sair com edições pendentes no estado editing não tem confirmação
- **categoria:** missing-feature
- **impl:** ausente — nenhum arquivo discard_changes_dialog.dart existe. O estado isEditing existe em route_state.dart:47 mas nenhum widget consome este getter nem implementa o guard de saída.
- **dump:** strings.xml:744-748 — discard_changes_dialog_title='Descartar alterações'; discard_changes_dialog_body='As alterações não salvas serão perdidas, e a rota reverterá para a versão otimizada mais recente.'; discard_changes_dialog_cancel_button='Continuar editando'; discard_changes_dialog_confirm_button='Descartar alterações'. Spec 2026-06-13:§Confirm→Ready-to-Run — 'Sair com mudanças pendentes → diálogo Descartar alterações? que reverte para a última versão otimizada'.
- **detalhe:** Quando o usuário toca 'Editar' no Ready-to-Run e depois muda paradas (add/remove/reorder), o estado muda para editing (OptimizationState.editing). Tentar voltar ou sair nesse estado deveria disparar o DiscardChangesDialog. Sem este guard, o usuário perde a rota otimizada silenciosamente ao navegar para fora, ou a rota fica em estado editing indeterminado. O Spoke rastreia isso via UpdateRoute que zera optimizedAt e seta optimization=EDITING; a RotPro tem o modelo correto mas sem o guard de UI.
- **fix:** Criar discard_changes_dialog.dart com estrutura equivalente ao Spoke (título 'Descartar alterações?', corpo explicando o rollback, botões 'Continuar editando'/'Descartar alterações'). Adicionar WillPopScope/PopScope no RouteShellPage que verifica isEditing antes de permitir o back; se isEditing, exibe o dialog e, em 'Descartar', executa routesProvider.notifier.discardOptimizationEdits() que restaura o estado optimized + optimizedAt anterior. Alternativa: usar GoRouter redirect/canPop.

### A7-D8 [must-fix] — Banner 'Otimização pendente' ausente no fluxo de 'Pular otimização'
- **categoria:** missing-state
- **impl:** apps/mobile/lib/features/routes/presentation/route_shell_page.dart:596-598 — caso OptimizationErrorChoice.skip exibe SnackBar 'Otimização pulada por enquanto.' e nada mais. Nenhum widget de banner nem estado de 'optimization pending' foi implementado.
- **dump:** strings.xml:1778 — optimization_pending_button_title='Otimização pendente'. Spec 2026-06-13:§Goal 10 — 'Se a otimização falhar (sem rede): ver o dialog de erro com Tentar de novo e Pular otimização; Pular chega ao Ready-to-Run com o banner Otimização pendente no mapa.' Spec §PR-C — 'ReadyToRunView com banner Otimização pendente'.
- **detalhe:** Pular otimização deveria levar o usuário ao Ready-to-Run com um banner/botão no mapa mostrando 'Otimização pendente' (o Spoke usa optimization_pending_button_title). A impl atual exibe um SnackBar transitório e retorna ao DRAFT sem mudar o estado da rota. Isso cria um estado incoerente: a rota fica como DRAFT mas o usuário acha que pulou. O banner permanente sinaliza que a otimização está pendente e permite reiniciá-la.
- **fix:** Este item depende de PR-C (A7-D5). Quando PR-C for implementado: 'Pular otimização' deve gravar optimizationAcknowledged=true + skipReorder=true (ou um flag hasSkippedOptimization dedicado) e navegar ao ReadyToRunView. O ReadyToRunView exibe o banner 'Otimização pendente' (um botão flutuante no mapa ou uma row no topo do sheet) quando o skip foi escolhido. O banner toca _onOptimize para re-tentar.

### A7-D9 [should-fix] — OptimizationErrorDialog com título e corpo divergentes do dump
- **categoria:** string-mismatch
- **impl:** apps/mobile/lib/features/routes/presentation/widgets/optimization_error_dialog.dart:15-18 — título 'Não foi possível otimizar'; corpo 'Confira sua conexão com a internet e tente de novo.'
- **dump:** strings.xml:1776-1777 — optimization_failed_title='Falha ao otimizar'; optimization_failed_body='Não foi possível concluir a otimização. Verifique sua conexão com a internet e tente de novo mais tarde.'
- **detalhe:** O título diverge ('Não foi possível otimizar' vs 'Falha ao otimizar') e o corpo está abreviado (falta 'concluir a otimização' e 'mais tarde'). Ambos os botões ('Pular otimização' e 'Tentar de novo') estão corretos (strings.xml:1598,2014 confirmam). A divergência do título é mais impactante: o Spoke usa um título mais direto/técnico; a impl usa uma paráfrase que altera o tom.
- **fix:** Atualizar optimization_error_dialog.dart: título → equivalente PT-BR de 'Falha ao otimizar' (algo como 'Falha ao otimizar'); corpo → equivalente PT-BR do dump que inclua 'concluir a otimização' e 'mais tarde'. Os botões ('Pular otimização', 'Tentar de novo') já estão corretos.

### A7-D10 [should-fix] — IdEducationDialog com título, corpo e label do botão secundário divergentes do dump
- **categoria:** string-mismatch
- **impl:** apps/mobile/lib/features/routes/presentation/widgets/id_education_dialog.dart:9-31 — título 'Como a numeração funciona'; corpo 'Cada parada ganha um código (A1, A2, A3…) que segue a ordem da rota. Se você reordenar ou otimizar de novo, os códigos se ajustam sozinhos.'; botão secundário 'Ajustar formato'
- **dump:** strings.xml:1812-1816 — package_identification_eduction_dialog_title='IDs ajustados conforme a ordem de rota'; package_identification_eduction_dialog_body='Enquanto você planeja a rota, os IDs de parada são atualizados conforme as suas alterações.\n\nApós a confirmação, mesmo que você faça alterações na rota, os IDs não mudarão.'; package_identification_eduction_dialog_configure='Configurar...'
- **detalhe:** O título é uma reescrita livre ('Como a numeração funciona') em vez de um equivalente ao dump ('IDs ajustados conforme a ordem de rota'). O corpo da impl é um parágrafo só, enquanto o Spoke tem 2 parágrafos distintos: o primeiro sobre o comportamento DURANTE o planejamento (IDs se atualizam), o segundo sobre o comportamento APÓS a confirmação (IDs ficam fixos). Essa segunda informação é funcional — prepara o usuário para o IdLockDialog (A7-D6). O label 'Ajustar formato' difere de 'Configurar...' do dump; a lógica (IdEducationChoice.configure → honest-stub) está correta.
- **fix:** Atualizar id_education_dialog.dart: título → equivalente a 'IDs ajustados conforme a ordem de rota' (ex: 'IDs seguem a ordem da rota'); corpo → dois parágrafos, 1º sobre atualização durante planejamento, 2º sobre fixação pós-confirmação (alinha com o IdLockDialog A7-D6); botão secundário → equivalente a 'Configurar...' (mantém a navegação para honest-stub da Á10).

### A7-D11 [nit] — RefineRouteSheet usa ícones Material Design em vez de Lucide
- **categoria:** other
- **impl:** apps/mobile/lib/features/routes/presentation/widgets/refine_route_sheet.dart:39,44 — Icons.swap_vert e Icons.gesture (ícones do Material Design padrão, não Lucide).
- **dump:** ADR-0035 e CLAUDE.md §Source-of-truth hierarchy — 'icon family (Lucide)'; todos os outros sheets/dialogs da Á7 usam lucide_icons_flutter (refine_route_sheet.dart é o único que usa Icons.*).
- **detalhe:** Inconsistência de identidade visual dentro do mesmo feature: o ReoptimizeOptionsSheet usa LucideIcons.refreshCw e LucideIcons.sparkles corretamente, mas o RefineRouteSheet usa Icons.swap_vert (Material) e Icons.gesture (Material). Viola ADR-0035 (icon family = Lucide). Impacto funcional zero, mas visualmente inconsistente.
- **fix:** Substituir em refine_route_sheet.dart: Icons.swap_vert → LucideIcons.arrowUpDown (ou LucideIcons.chevronsUpDown); Icons.gesture → LucideIcons.penLine (ou LucideIcons.handMetal). Adicionar import 'package:lucide_icons_flutter/lucide_icons.dart'.

