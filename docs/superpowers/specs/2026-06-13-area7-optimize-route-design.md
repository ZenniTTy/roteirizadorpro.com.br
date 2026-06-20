# Spec — Área 7: Otimizar rota (Slice 2)

> **Date:** 2026-06-13
> **Author:** Claude Code (with Eduardo)
> **Status:** Awaiting user review before invoking `writing-plans`
> **Branch:** `feat/m2-slice-2-area-7-optimize` (off `develop` at `10a8a75`)
> **Source of truth:** `docs/08-ROADMAP-v2.md` "Área 7 — Otimizar rota (3 estados + 3 modais FTUE)". This spec elaborates that section; if the two disagree, the ROADMAP wins and the contradiction is a bug to fix in the same PR. **Esta spec corrige duas premissas do roadmap, validadas dump-first (ver §Decisões):** (1) os "3 estados" são derivados de flags ortogonais do `RouteState`, não um enum linear; (2) "Refinar" e "Reotimizar" são DOIS sheets distintos, não um.

---

## Context

A Área 5 (Detalhes da rota) fechou em 2026-06-10 e a Área 6 (Editar parada) em 2026-06-12 — ambas na `develop`. A tela ativa de rota (`route_shell_page.dart`, Área 3) está ~90% pronta: tem o sheet de 3-snaps, a lista de stops (MS-A6), a seção de config-resumo (MS-A5.7), e os controles de mapa reais (MS-A3). O **slot do rodapé do shell está vazio** com ≥1 parada (os botões empty-state somem) — é exatamente onde o CTA "Otimizar rota" nasce, e é a 1ª task desta área.

A Área 7 é o **funil de otimização**: o motorista toca "Otimizar rota", o app reordena as paradas, mostra um estado de pré-confirmação (mapa + rota desenhada + resumo tempo/paradas/km + IDs A1..AN), confirma, e chega ao estado "pronto para rodar" onde "Iniciar rota" é o gateway para o Modo Delivery (Área 8). Otimização é **grátis** — o paywall (ADR-0030) só dispara em "Navegar" na Área 8.

Esta área foi modelada **dump-first** (ADR-0045): o dump estático do Spoke v3.65.1 (`~/spoke-dump/jadx-out`) resolveu a estrutura por código (`RouteState.kt`, `OptimizationState.kt`, `OptimizeType.kt`, `OptimizeDirection.kt`, strings `optimizing_*`/`optimization_*`/`refine_route_*`/`order_stop_groups_*`), e o `spoke-parity-checker` (2026-06-13, Maestro MCP no M54) confirmou o funil dinâmico ao vivo. **Fica fora:** backend real de otimização (GraphHopper — Slice 3), barcode scanning do "Carregar veículo" (ML Kit — Slice 3), e o live-tracking do "Compartilhar rota em tempo real" (endpoint público + web — Slice 3).

## Decisões locked in this brainstorming session

| # | Question | Decision | Rationale |
|---|---|---|---|
| Q1 | De onde vêm a ordem otimizada + métricas (tempo/km) no Slice 2, já que GraphHopper é Slice 3? | **Solver mínimo on-device em Dart** (nearest-neighbor + 2-opt, distância Haversine via `Geolocator.distanceBetween`) | O Spoke usa um solver de backend (`OptimizationRoutingSolver{GOOGLE_MAPS, GRAPH_HOPPER}` — `core/entity/OptimizationRoutingSolver.java`). Não há "fazer igual" no mobile-only do Slice 2. O solver Dart é stand-in fiel: a fronteira `RouteOptimizer.optimize()` troca de implementação no Slice 3 sem tocar UI/estado. Toda a UI pós-otimização (PRE-CONFIRM, summary, chips) só faz sentido com ordem+métricas reais — mock zerado pareceria quebrado. |
| Q2 | Como modelar o lifecycle (o Spoke tem 5+ fases no funil)? | **Replicar fiel o `RouteState`**: `OptimizationState` enum {creating, optimized, editing} + flags ortogonais (`confirmed`, `started`, `optimizing`, `optimizationAcknowledged`) + timestamps | Validação dump-first **corrigiu** a proposta original de enum linear de 6 valores. `core/entity/RouteState.java` (campos do `toString()` verbatim: `started/startedAt/optimizedAt/completed/.../optimization/optimizing/optimizationErroredAt/optimizationAttemptedAt/optimizationAcknowledged/confirmed`) + `OptimizationState.java` (`CREATING/OPTIMIZED/EDITING`) provam que o Spoke usa flags+timestamps ortogonais, não um eixo linear. O estado visual (PRE-CONFIRM, Ready-to-Run) é DERIVADO desses flags. Mais fiel e mais expressivo (ex.: "otimizado mas erro na última tentativa" é representável). |
| Q3 | "Refinar" e "Reotimizar" são o mesmo dialog? | **NÃO — são dois sheets distintos.** "Refinar" (botão rodapé) → "Refinar a rota" {Inverter / Ordenar manual}. "Reotimizar rota..." (kebab) → "Alternativas de reotimização" {Atualizar / Reotimizar} | O deep-grep no jadx via dump tinha o `optimization_explainer_*` ("Compare as opções") e eu ia mapeá-lo ao botão "Refinar". O `spoke-parity-checker` ao vivo provou que "Refinar" abre OUTRA coisa: `refine_route_dialog_*` ("Inverter a rota" / "Ordenar a rota manualmente"). O explainer é o do KEBAB. Mapear ao slot errado = implementar widget errado (o failure mode da Á5, ADR-0041..0044). Lição travada em memória `lesson_area7_refinar_vs_reotimizar_two_dialogs`. |
| Q4 | Quanto do "Refinar" entra no Slice 2? | **"Inverter a rota" REAL** (`OptimizeDirection.REVERSE`) + **"Ordenar a rota manualmente" (OrderStopGroups) REAL on-device** | O dump prova que "Inverter" é uma chamada ao solver com direção reversa (`core/entity/OptimizeDirection.java` = `REVERSE`). OrderStopGroups (`ui/home/editroute/orderstopgroup`, `OrderStopGroupDrawerOverlayKt$eagerDetectDragGestures`, strings `order_stop_groups_*` completas) é lasso de polígonos sobre o GoogleMap + agrupamento — **zero backend, zero ML Kit** → viável e fiel agora. Eduardo escolheu 100% idêntico onde viável. |
| Q5 | "Carregar veículo" entra no Slice 2? | **Botão fiel + ação "Em breve" → Slice 3** | Correção factual do dump: o núcleo de "Carregar veículo" é **escanear barcode** de cada pacote (`domain/interactors/ScanStopBarcodeForLoadVehicle`, `MarkAsDone$requiresBarcodeScanningToLoadVehicle`, `ui/scanner/LabelScannerViewModel$processLoadVehicleBarcode`) — depende de ML Kit, a mesma dep pesada que o roadmap já difere p/ Slice 3 (OCR/Voz). Fazer só o wizard visual = bug silencioso (Eduardo: "evite bugs silenciosos"). Botão presente (layout idêntico ao Spoke) + ação honesta. |
| Q6 | "Compartilhar rota em tempo real" entra no Slice 2? | **Botão fiel + ação "Em breve" → Slice 3** | É live-tracking p/ cliente final: link público + página web + posição em tempo real — tudo backend (Slice 3, não existe). Antecipar = breaking change na fronteira mobile/backend do roadmap (Eduardo: "evite breaking changes"). Botão presente, ação honesta. Distinto do "Compartilhar cópia da rota" do kebab (peer-transfer B2B, cortado) e da ShareSheet original RotPro (`/settings/share`). |
| Q7 | Replicar o gate "10 paradas/assinar" do Spoke? | **NÃO clonar** | `undo_optimization_dialog_*` = "Assine para usar rotas com mais de 10 paradas" é o freemium do Spoke. RotPro é ADR-0030 (acesso único R$ 25,90/30d, paywall só em "Navegar" na Á8, otimização grátis). Divergência intencional de negócio. **Consequência (dump-confirmado):** a ação "Desfazer otimização" (`undo_optimization_*`) existe no Spoke SÓ acoplada a esse paywall (`PaywallDialogFragment.java:122` → `DialogC2615o0` é o único call-site) — ao cortar o gate, ela cai junto. Não há controle órfão; nenhum widget de "desfazer" nesta área. |
| Q8 | Tamanho da entrega? | **4 PRs sequenciais na `develop`** (A: estado+solver+CTA+progresso; B: PRE-CONFIRM+FTUE+Refinar/Reotimizar; C: Ready-to-Run+Confirmar+Iniciar; D: OrderStopGroups) | Á7 ficou grande (solver + 2 estados + progresso + 2 FTUEs + 2 sheets + banner + chips + CTA sticky + tela de grupos). PR único (modelo Á6) teria diff enorme e arriscado. Cada fatia verde+mergeada antes da próxima; zero débito por fatia (regra do harness). OrderStopGroups é a tela mais cara e independente → último PR. |
| Q9 | Formato do chip de ID (A1..AN) e seu default? | **Moderno como default declarado, gerado por enum `PackageLabelFormat {moderno, classico}`** | Validação dump-first **corrigiu** minha premissa: o fallback hard-coded do Spoke é **Clássico** (`p000/a4e.java:16` = `PackageLabelFormat.BASE`, gated por A/B test), não Moderno. O texto do chip é função desse formato (`domain/utils/C3003e.java`: Moderno=letra+dígito linha 174-179; Clássico=número puro linha 165). RotPro usa **Moderno como default por escolha de produto** (mais legível p/ etiquetar pacotes), não por cópia do default Spoke. O toggle Moderno/Clássico vive na **Á10** (`package_identification_format_*`, ainda não feita) — débito explícito no TODO. Parametrizar a geração por enum (não string literal "A$n") deixa o braço Clássico fiel-mas-dormente e a Á10 só liga o toggle. |

## Goals (acceptance for this slice)

A real Samsung M54 (`RQCW401G33T`) install de `v1.1.0-area7` pode, contra a API de produção (ou stub local quando aplicável):

1. Numa rota ativa com ≥2 paradas, ver o CTA "Otimizar rota" sticky no rodapé do shell; tocá-lo dispara a otimização (grátis, sem paywall).
2. Na 1ª otimização da conta, ver o modal educativo de numeração (one-shot) com "Entendi" e "Configurar"; tocar "Entendi" prossegue; a 2ª otimização NÃO re-mostra o modal.
3. Durante a otimização, ver a tela de progresso com as 4 fases sequenciais; ao concluir, chegar ao estado PRE-CONFIRM.
4. No PRE-CONFIRM: ver o mapa na metade superior com a rota desenhada (polyline) + markers numerados; a linha de resumo "X min · N paradas · Y km"; a lista de paradas na ordem otimizada, cada uma com chip "A1".."AN"; e o rodapé com **1 indicador de tempo (display, NÃO clicável)** + **2 CTAs** ("Refinar" / "Confirmar").
5. Tocar "Refinar" → ver o sheet "Refinar a rota" com "Inverter a rota" (reordena reverso e volta ao PRE-CONFIRM) e "Ordenar a rota manualmente" (abre a tela de desenho de grupos).
6. Abrir o kebab no PRE-CONFIRM → "Reotimizar rota..." → ver "Alternativas de reotimização" com "Atualizar rota" e "Reotimizar rota"; cada uma re-roda o solver e volta ao PRE-CONFIRM atualizado.
7. Na tela de "Ordenar a rota manualmente": desenhar ≥2 grupos no mapa (lasso), tocar "Confirmar rota" → a rota reordena pela ordem dos grupos e volta ao PRE-CONFIRM; "Descartar alterações?" e "Aceitar rota atual?" funcionam nos dialogs.
8. Tocar "Confirmar" no PRE-CONFIRM → ver o modal "IDs definitivos" (one-shot) com "Continuar"/"Cancelar"; "Continuar" chega ao Ready-to-Run (sem o modal "Carregar veículo", cortado).
9. No Ready-to-Run: ver os 2 botões-linha ("Compartilhar rota em tempo real" e "Carregar veículo", ambos exibem "Em breve" ao toque) + o rodapé com **1 indicador de tempo (display)** + **2 CTAs** ("Editar" / "Iniciar rota").
10. Se a otimização falhar (sem rede): ver o dialog de erro com "Tentar de novo" e "Pular otimização"; "Pular" chega ao Ready-to-Run com o banner "Otimização pendente" no mapa.
11. Tocar "Iniciar rota" no Ready-to-Run — o destino (Modo Delivery, Área 8) ainda não existe; nesta área o tap dispara um SnackBar "Em breve" observável (o mesmo idiom de corte honesto dos botões "Carregar veículo"/"Compartilhar rota em tempo real"), sem navegar para tela inexistente. A Área 8 substitui o SnackBar pela navegação real. **Este é o único gateway que aponta para área futura.**
12. Tocar **"Editar"** no Ready-to-Run → a rota volta ao estado PRE-CONFIRM (botões "Refinar"/"Confirmar" de novo no rodapé), permitindo mexer nas paradas. Se o motorista adicionar/remover/reordenar paradas após editar, a otimização anterior é invalidada (o resumo "X min · N paradas" some até re-otimizar); ao tentar sair com mudanças pendentes, ver o diálogo "Descartar alterações?" que reverte para a última versão otimizada.
13. Tocar "Otimizar rota" com **menos paradas que o mínimo** (apenas Partida/Destino sem parada intermediária suficiente) → o solver NÃO roda; ver um diálogo próprio "Adicione mais paradas" (título + corpo + único botão "Ok"), **distinto** do diálogo de falha de rede do Goal 10.
14. Remover uma parada quando a rota **já está otimizada** → a parada NÃO some na hora; ver um confirm distinto ("a parada será removida na próxima otimização") e a parada fica marcada para remoção deferida, aplicada na próxima re-otimização. (Em rota DRAFT, "Remover" continua deletando na hora, como na Área 6.)

### Non-goals (explicit, to keep scope tight)

- **Solver real GraphHopper** (Slice 3 — `POST /routes/optimize`). O solver Dart on-device é stand-in.
- **Barcode scanning do "Carregar veículo"** (Slice 3 — ML Kit, junto com OCR/Voz).
- **Live-tracking "Compartilhar rota em tempo real"** (Slice 3 — endpoint público + página web).
- **Gate "10 paradas/assinar"** (cortado — ADR-0030).
- **Modal FTUE "Carregar veículo?"** (cortado — introduz feature OUT-OF-SCOPE).
- **Modo Delivery** (Área 8 — "Iniciar rota" leva a placeholder aqui).
- **Persistência server-side do `RouteState`** (Slice 3 — no Slice 2 vive em memória/SharedPreferencesAsync onde aplicável).

## Architecture

### Mobile feature module layout (NEW + MODIFIED)

```
apps/mobile/lib/features/routes/
├── domain/
│   ├── route.dart                          # MOD: RouteStatus → RouteState (flags+timestamps), métricas
│   ├── route_state.dart                    # NEW: RouteState (espelha core/entity/RouteState.kt)
│   ├── optimization_state.dart             # NEW: enum {creating, optimized, editing}
│   ├── optimize_type.dart                  # NEW: enum {restartRoute, reorderFlexible, skipReorder}
│   ├── optimize_direction.dart             # NEW: enum {reverse}
│   ├── package_label_format.dart           # NEW: enum {moderno, classico} (default moderno; chip A1.. vs 1..) [G6]
│   ├── stop.dart                           # MOD: + String? deliveryId (A1..AN/"Pendente") + bool pendingRemoval (G5)
│   └── optimization/
│       ├── route_optimizer.dart            # NEW: interface RouteOptimizer + RouteOptimizationResult
│       ├── local_route_optimizer.dart      # NEW: NN + 2-opt, Haversine (impl. Slice 2)
│       └── stop_group.dart                 # NEW: StopGroup (OrderStopGroups — polígono + stops)
├── state/
│   ├── optimization_controller.dart        # NEW: @riverpod — orquestra o funil (espelha map_controls_controller)
│   ├── route_lifecycle_controller.dart     # NEW: @riverpod — transições confirm/start/edit (espelha RouteLifecycleController)
│   └── optimization_ftue_repository.dart    # NEW: flags one-shot (SharedPreferencesAsync)
└── presentation/
    ├── route_shell_page.dart               # MOD: CTA "Otimizar rota" sticky no rodapé (1ª task) + switch de estado visual
    ├── widgets/
    │   ├── optimize_cta.dart               # NEW: CTA sticky (desabilitado/gated abaixo do mínimo de paradas, G1)
    │   ├── optimizing_progress_view.dart   # NEW: tela 4 fases
    │   ├── optimization_error_dialog.dart  # NEW: erro de REDE ("Não foi possível otimizar" + Tentar de novo/Pular)
    │   ├── not_enough_stops_dialog.dart    # NEW: G1 — "Adicione mais paradas" (título + corpo + único botão Ok); ≠ erro de rede
    │   ├── confirm_deferred_removal_dialog.dart # NEW: G5 — "será removida na próxima otimização" (estado otimizado)
    │   ├── pre_confirm_view.dart           # NEW: PRE-CONFIRM (summary display + chips + 1 tempo-display + 2 CTAs)
    │   ├── ready_to_run_view.dart          # NEW: Ready-to-Run (2 botões-linha + 1 tempo-display + 2 CTAs + banner)
    │   ├── route_summary_row.dart          # NEW: "X min · N paradas · Y km" — DISPLAY puro, sem onTap (G4)
    │   ├── id_education_dialog.dart        # NEW: FTUE "Numeração definida pela ordem da rota"
    │   ├── id_lock_dialog.dart             # NEW: FTUE "A numeração ficará fixa"
    │   ├── refine_route_sheet.dart         # NEW: "Refinar a rota" {Inverter / Ordenar manual}
    │   └── reoptimize_options_sheet.dart   # NEW: "Alternativas de reotimização" {Atualizar / Reotimizar}
    └── pages/
        └── order_stop_groups_page.dart     # NEW (PR-D): lasso no mapa + grupos + 3 dialogs
```

### Contract evolution

Nenhuma mudança de contrato backend nesta área (solver é on-device; `POST /routes/optimize` real é Slice 3). Portanto **sem obrigação de DTO mirror** (ADR-0013) nesta área. Quando o Slice 3 trocar o solver, o `RouteOptimizationResult` ganha um DTO espelhando a resposta TypeBox — mas isso é Slice 3.

### Architecture principles

1. **Solver atrás de interface** — `RouteOptimizer` é abstrato; `LocalRouteOptimizer` é a impl. do Slice 2. Slice 3 injeta `GraphHopperRouteOptimizer` via override de provider. UI/estado nunca importam a impl. concreta.
2. **Estado visual é derivado, não armazenado** — PRE-CONFIRM/Ready-to-Run/erro são funções puras de `RouteState` (getters), não campos. Switch exaustivo na UI (`AsyncValue` selada, sem `default` — token 3.44).
3. **Fidelidade estrutural + microcopy original** — estrutura/fluxo/estados idênticos ao dump (ADR-0035); texto PT-BR é original, nunca verbatim do Spoke.
4. **Cortes são botões fiéis + ação honesta** — features Slice 3 (Carregar veículo, Compartilhar tempo real) têm o botão no layout (estrutura fiel) mas ação "Em breve" observável (sem bug silencioso).
5. **`@riverpod` codegen + keepAlive** — controllers espelham o padrão de `map_controls_controller.dart`; toda edição de provider dispara o hook `run-riverpod-codegen` (ADR-0024).
6. **`ReorderableListView.builder` com `onReorderItem`** — confirmado da fonte 3.44 (assinatura `void Function(int oldIndex, int newIndex)`, `newIndex` já corrigido; `onReorder` é `@Deprecated`, assert proíbe passar os dois). Usado onde houver reordenação manual de stops.
7. **"Editar" é o inverso de "Confirmar" (G2/G3), não navegação** — `onEditRoute()` reusa a flag `confirmed` (true→false), devolvendo a rota ao PRE-CONFIRM no MESMO shell (sem push de "route builder" — a paráfrase do inventário §10.12 estava errada, ver `RouteLifecycleController$onEditRouteClick:49` → `ConfirmedState(false)`). O estado `editing` é alcançado quando paradas mudam numa rota já otimizada (`UpdateRoute.java:115-117`: muda stops + estava OPTIMIZED → entra EDITING e **zera `optimizedAt`**, invalidando as métricas obsoletas). Getter derivado `isEditing` entra no switch exaustivo. Sair com mudanças pendentes → diálogo "Descartar alterações?" reverte à última versão otimizada.

## Data flow

### Funil de otimização (DRAFT → PRE-CONFIRM)

1. `RouteShellPage` renderiza o estado visual via `switch` sobre `route.routeState` derivado. DRAFT (`optimization == creating && !optimizing`) → mostra `OptimizeCta` sticky no rodapé.
2. Tap no CTA → `OptimizationController.optimize(type: OptimizeType.restartRoute)`. **Guard de mínimo (G1, espelha `OptimizeActiveRoute$optimise$1:356` → `OptimizationError.NotEnoughStops`):** se a contagem de paradas otimizáveis for insuficiente (menos de 1 parada além de Partida/Destino), o controller NÃO chama o solver e mostra o `NotEnoughStopsDialog` (título "Adicione mais paradas" + corpo + único botão "Ok", microcopy original). Distinto do erro de rede (passo 5). Senão, prossegue.
3. Se `!optimizationAcknowledged`, mostra `IdEducationDialog` (one-shot); ao "Entendi" grava a flag (`OptimizationFtueRepository`) e prossegue.
4. Controller seta `optimizing = true` → UI mostra `OptimizingProgressView` (4 fases, timer escalonado). Chama `RouteOptimizer.optimize(start, end, stops, type)`.
5. `LocalRouteOptimizer`: nearest-neighbor a partir de `start` (vizinho mais próximo por `Geolocator.distanceBetween`), refina com 2-opt, atribui `deliveryId` na ordem final **via `PackageLabelFormat` (default `moderno` → "A1".."AN"; `classico` → "1".."N", G6/Q9)**, calcula `totalDistanceMeters` (soma dos legs) e `totalDurationMinutes` (distância ÷ velocidade urbana constante). Stops com `pendingRemoval == true` (G5) são excluídos da otimização (a remoção deferida se efetiva aqui).
6. Sucesso → `RouteState.copyWith(optimization: optimized, optimizing: false, optimizedAt: now)` + métricas no `Route` + stops reordenados. UI → `PreConfirmView`. Erro de REDE → `optimizationErroredAt: now`, UI → `OptimizationErrorDialog`.

### Refinar / Reotimizar (dois fluxos distintos — Q3)

- **"Refinar" (rodapé)** → `RefineRouteSheet`. "Inverter a rota" → `optimize(type: reorderFlexible, direction: reverse)` (reverte a ordem atual). "Ordenar a rota manualmente" → push `OrderStopGroupsPage`.
- **Kebab "Reotimizar rota..."** → `ReoptimizeOptionsSheet`. "Atualizar rota" → `optimize(type: reorderFlexible)`. "Reotimizar rota" → `optimize(type: restartRoute)`. Ambos voltam ao PRE-CONFIRM atualizado.

### OrderStopGroups (Ordenar manualmente — PR-D)

`OrderStopGroupsPage` mostra o GoogleMap full-screen. Gesto de arrasto desenha um polígono (lasso) → `StopGroup` (lista de stops dentro do polígono). "Desenhar o próximo grupo" cria o próximo. "Confirmar rota" (habilitado com ≥2 grupos) → `optimize` respeitando a ordem dos grupos (otimiza dentro de cada grupo, concatena na ordem desenhada). Dialogs: "Descartar alterações?" (sair sem aplicar), "Aceitar rota atual?" (confirmar), "Desfazer" (remove último grupo).

### Confirm → Ready-to-Run → Editar (transições de lifecycle)

- **Confirmar:** tap "Confirmar" no PRE-CONFIRM → `RouteLifecycleController.onConfirmRoute()`. Se `!idLockAcknowledged`, mostra `IdLockDialog` (one-shot); "Continuar" → `RouteState.copyWith(confirmed: true, optimizationAcknowledged: true)` + grava flag. UI → `ReadyToRunView`.
- **Iniciar rota:** tap "Iniciar rota" → `onStartRoute()` (`started: true`) → placeholder Á8 (SnackBar "Em breve" nesta área).
- **Editar (G2/G3, des-confirma):** tap "Editar" no Ready-to-Run → `onEditRoute()` → `RouteState.copyWith(confirmed: false)` (espelha `RouteLifecycleController$onEditRoute:49` → `ConfirmedState(false)` — NÃO reseta `optimizationAcknowledged`). O getter derivado roteia de volta a `PreConfirmView` (mesmo shell, sem push). Se o motorista então mudar paradas (add/remove/reorder), `UpdateRoute` detecta `stops mudaram && optimization == optimized` → `RouteState.copyWith(optimization: editing, optimizedAt: null)` (G3 — invalida as métricas; o resumo "X min" some até re-otimizar). Sair com mudanças pendentes → diálogo "Descartar alterações?" reverte à última versão otimizada.

### Remoção de parada em estado otimizado (G5)

Quando `route.optimization == optimized` (a rota já foi otimizada), "Remover parada" NÃO deleta imediatamente (diferente do DRAFT/Á6). Espelha `StopActionsController$onDeleteStopClick:55` → `ConfirmDeleteStopOnOptimizationDialog`: mostra o `ConfirmDeferredRemovalDialog` (microcopy original equivalente a "a parada será removida na próxima otimização"); confirmar marca `stop.pendingRemoval = true` (remoção DEFERIDA, sem backend no Slice 2) — a parada permanece visível na lista mas marcada, e é efetivamente excluída no próximo `optimize()` (passo 5 do funil). Em rota DRAFT (`optimization == creating`), a remoção continua imediata, como a Área 6 entregou.

## Sub-slice plan

| Sub | Scope | Verification |
|---|---|---|
| **PR-A** | `RouteState`/`OptimizationState`/`OptimizeType`/`OptimizeDirection`/**`PackageLabelFormat` (G6)** + migração do enum + métricas no `Route` + `deliveryId`+**`pendingRemoval` (G5)** no `Stop` + `RouteOptimizer`/`LocalRouteOptimizer` (testado isolado) + `OptimizationController` (**com guard de mínimo G1**) + **CTA "Otimizar rota" sticky** (gated abaixo do mínimo) + `OptimizingProgressView` (4 fases) + `OptimizationErrorDialog` (rede) + **`NotEnoughStopsDialog` (G1)** | Widget+unit tests verdes; CTA visível no M54; solver reordena; guard de mínimo dispara o dialog próprio; analyze limpo no escopo |
| **PR-B** | `PreConfirmView` (mapa+polyline+markers, `RouteSummaryRow` **display-only G4**, lista ordenada + chips A1..AN, **1 tempo-display + 2 CTAs**) + `IdEducationDialog` (one-shot) + `RefineRouteSheet` (Inverter real; Ordenar-manual → push p/ destino do PR-D) + kebab `ReoptimizeOptionsSheet` (Atualizar/Reotimizar reais) + **remoção deferida em estado otimizado (`ConfirmDeferredRemovalDialog`, G5)** | PRE-CONFIRM navegável no M54; FTUE one-shot verificado; Inverter/Atualizar/Reotimizar reordenam; remover parada otimizada defere (não deleta na hora) |
| **PR-C** | `RouteLifecycleController` (confirm/start/**edit = des-confirma, G2/G3**) + `IdLockDialog` (one-shot) + `ReadyToRunView` (2 botões-linha "Em breve" + **"Editar" volta ao PRE-CONFIRM** + **"Iniciar rota"** + banner "Otimização pendente") + estado `editing` (invalida `optimizedAt`) + "Descartar alterações?" + placeholder Á8 | Ready-to-Run navegável; "Editar" volta ao PRE-CONFIRM e invalida métricas ao mudar stops; "Iniciar rota" → placeholder; "Pular otimização" → banner |
| **PR-D** | `OrderStopGroupsPage` (lasso + grupos + 3 dialogs + re-otimiza por grupos) + fecha "Ordenar manualmente" do PR-B | Desenhar ≥2 grupos reordena a rota no M54; dialogs funcionam |
| **Fechamento** | `integration_test/area7_optimize_flow_test.dart` no M54 + D4 dump-only + `flutter-perf-auditor` + smoke E2E release + docs sweep | `/verify-slice` GO; integration_test verde no M54 |

**Estimativa:** maior dos slices da Área 2; 4 PRs + fechamento.

## Libraries

| Purpose | Package | Version target | Cost | Context7 ID (or stdlib rationale) |
|---|---|---|---|---|
| Distância Haversine (solver) | `geolocator` | `^14.0.2` (já instalado) | 0 | Já no pubspec (`Geolocator.distanceBetween`); sem nova dep |
| Reordenação + mapa + prefs | `google_maps_flutter`, `shared_preferences`, Flutter SDK | já instalados | 0 | Flutter-team / já no pubspec — exceção stdlib per CLAUDE.md |

**Nenhuma biblioteca nova nesta área.** O solver é Dart puro sobre `geolocator` já instalado. Portanto `adr-guardian` não deve sinalizar mudança de stack além da ADR-0051 (lifecycle/solver — decisão de arquitetura, não dependência).

## ADRs filed during this slice

- **ADR-0051** — Route lifecycle model (`RouteState` flags+timestamps espelhando o Spoke) + solver on-device Dart como stand-in do GraphHopper (Slice 3). Documenta: a substituição do `enum RouteStatus` linear, a fronteira `RouteOptimizer`, e os cortes (Carregar veículo / Compartilhar tempo real = Slice 3; gate-10-paradas = não clonar per ADR-0030). Filed in PR-A.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| **Migração do `enum RouteStatus` quebra consumidores existentes** | PR-A faz a migração completa com getters de compatibilidade onde necessário; `flutter analyze` + suite verdes antes do merge. Sem `// TODO` de migração (zero débito). |
| **Solver Dart lento ou ordem ruim p/ muitas paradas** | NN+2-opt é O(n²) — aceitável p/ as rotas B2C típicas (≤~20 paradas). Cap de iterações no 2-opt. O solver real (GraphHopper) vem no Slice 3; este é stand-in. |
| **Mapear "Refinar" ao widget errado (failure mode Á5)** | Memória `lesson_area7_refinar_vs_reotimizar_two_dialogs` travada; spec Q3 explícita; D4 dump-only valida cada sheet contra `refine_route_dialog_*` vs `optimization_dialog_*`. |
| **OrderStopGroups: gesto de lasso conflita com gestos do GoogleMap** | Lição travada `lesson_googlemap_eats_gestures_use_column` + `eagerDetectDragGestures` (o Spoke usa o mesmo padrão). Modo de desenho desabilita pan do mapa enquanto o lasso está ativo. |
| **Bug silencioso nos cortes** | Carregar veículo / Compartilhar tempo real exibem "Em breve" observável (SnackBar), nunca `onTap: () {}` vazio (regra de qualidade do checklist). |
| **FTUE one-shot reaparece ou não dispara** | Flags em `SharedPreferencesAsync` (idiom Á3 `MapPrefsRepository`); integration_test verifica que a 2ª otimização não re-mostra o modal. |
| **`onReorder` vs `onReorderItem` (token 3.44)** | Confirmado da fonte (`reorderable_list.dart`): usar só `onReorderItem`; o assert do Flutter falha se passar os dois. |
| **G1 — solver roda sobre lista degenerada (tela "0 paradas"/crash)** | Guard de mínimo no `OptimizationController` ANTES do solver; `NotEnoughStopsDialog` próprio. Unit test do limiar + widget test do dialog. CTA `OptimizeCta` também gated abaixo do mínimo. |
| **G2/G3 — "Editar" vira botão morto ou pop errado (failure mode ADR-0041..0044)** | "Editar" = `confirmed: false` (reuso de flag), volta ao PRE-CONFIRM no mesmo shell; mudar stops em rota otimizada → `editing` + `optimizedAt: null` (invalida métrica obsoleta). Unit test da transição + integration_test cobre o tap. Inventário §10.12 corrigido ("des-confirma", não "reabre route builder"). |
| **G5 — remover parada otimizada deleta na hora (diverge do Spoke)** | Ramo por estado: `optimization == optimized` → `ConfirmDeferredRemovalDialog` + `pendingRemoval` (deferido); DRAFT → delete imediato (Á6). Widget test pina os dois ramos. |
| **G6 — chip de ID hard-coded "A$n" colide com o toggle da Á10** | Geração via enum `PackageLabelFormat` {moderno(default)/classico}, não string literal. Braço Clássico fiel-mas-dormente; Á10 só liga o toggle. Débito explícito no TODO. |

## Accessibility (Karpathy 3 minimum — not optional)

1. **Semantics labels em cada CTA primário.** "Otimizar rota", "Refinar", "Confirmar", "Editar", "Iniciar rota", "Atualizar rota", "Reotimizar rota", "Inverter a rota", "Confirmar rota" (OrderStopGroups), "Entendi", "Continuar".
2. **Tap targets ≥ 48×48 dp.** Os 2 CTAs do rodapé (o indicador de tempo é display, NÃO recebe Semantics(button) nem tap — G4), os botões-linha do Ready-to-Run, as opções dos sheets, a toolbar de desenho do OrderStopGroups.
3. **Color-contrast WCAG AA contra `prototipo/tokens.js`.** O verde do indicador de tempo, o laranja do banner "Otimização pendente", os chips A1..AN — auditados antes de cada PR fechar.

## Test strategy

| Layer | Tool | What it covers in this slice |
|---|---|---|
| Solver | unit | `LocalRouteOptimizer`: ordem NN+2-opt determinística, métricas, `deliveryId` (Moderno A1..AN E Clássico 1..N, G6), direção reversa, ordem-por-grupos, **guard de mínimo (G1)**, **exclusão de `pendingRemoval` (G5)** |
| Estado | unit | `RouteState` derivações (isPreConfirm/isReadyToRun/**isEditing**/isOptimizing/hasError), transições do `RouteLifecycleController` (**confirm/start/edit — edit des-confirma G2; mudar stops invalida `optimizedAt` G3**) |
| FTUE | unit | `OptimizationFtueRepository` one-shot (flags) |
| Widgets | widget | Cada view/sheet/dialog: PRE-CONFIRM render, summary **(display, sem onTap — G4)**, chips, 1 tempo + 2 CTAs, RefineRouteSheet vs ReoptimizeOptionsSheet, banner, "Em breve" dos cortes, **`NotEnoughStopsDialog` (G1)**, **`ConfirmDeferredRemovalDialog` — ramos draft vs optimized (G5)** |
| Fluxo | integration_test (M54) | `area7_optimize_flow_test.dart`: Otimizar → progresso → PRE-CONFIRM → Confirmar → Ready-to-Run → **Editar→PRE-CONFIRM** → "Iniciar rota" placeholder; FTUE one-shot; erro→Pular→banner; **mínimo→dialog (G1)** |

**TDD red→green por task** via `flutter-test-author` (ADR-0025), idiom da Á6.

**Tech debt explícito (added to `TODO.md` na PR):**

- *2026-06-13:* Solver é stand-in Dart on-device; GraphHopper real = Slice 3 (`POST /routes/optimize`). Fronteira `RouteOptimizer` pronta para o swap.
- *2026-06-13:* "Carregar veículo" (barcode/ML Kit) e "Compartilhar rota em tempo real" (backend) = botão fiel + "Em breve" → Slice 3.
- *2026-06-13:* "Iniciar rota" leva a placeholder até a Área 8 construir o Modo Delivery.
- *2026-06-13 (G6):* O toggle "Formato do ID" (Moderno/Clássico) vive na **Área 10** (ainda não feita). A Á7 usa Moderno como default (escolha de produto; o fallback do Spoke é Clássico) e gera o chip via enum `PackageLabelFormat` — a Á10 só liga o toggle, sem re-trabalho no gerador.

## PR-C — resolução do modelo de estado (2026-06-20, dump-first, Fase R/P0)

> Investigação dump-first (ADR-0052) que destrava o PR-C, fechando os 4 must-fix do audit 2026-06-20 (A7-D5/D6/D7/D8). Arbitrada pelo jadx: `OptimizationController.performSkipOptimization` → interactor `SkipOptimization.kt` (`C2976r0`) → `UpdateRoute`; strings `package_identification_lock_dialog_*`, `discard_changes_dialog_*`, `optimization_pending_button_title`, `start_button_title`. A lógica fina do skip vem de continuation ofuscado (Pairip — limitação ADR-0045); o modelo abaixo é o fiel-suficiente, confirmado por strings+estrutura+spec, a ser validado por teste + D4.

**Ready-to-Run tem DOIS caminhos de entrada** (otimizado e skip), então o estado visual relaxa:

- `isReadyToRun` ⇒ `confirmed && !started && !completed` (era `optimization == optimized && confirmed && !started`; relaxar é **aditivo** — nada setava `confirmed` sem otimizar antes).
- `isDraft` ganha guard `&& !confirmed` (rota confirmada nunca é draft).
- `isPreConfirm` inalterado (`optimization == optimized && !confirmed && !started`).
- **novo** `hasPendingOptimization` ⇒ `isReadyToRun && optimization != optimized` → dispara o banner "Otimização pendente".

**Transições (provider `Routes`):**

| Ação | Origem | Efeito no `RouteState` | UI resultante |
|---|---|---|---|
| `confirmRoute()` | "Confirmar" (PRE-CONFIRM) | `confirmed:true, optimizationAcknowledged:true` | Ready-to-Run (sem banner) |
| `skipOptimization()` | "Pular otimização" (erro) | `confirmed:true, optimizationAcknowledged:true` (optimization fica `creating`) | Ready-to-Run + banner pendente |
| `editRoute()` | "Editar" (Ready-to-Run) | `confirmed:false` | otimizado→PRE-CONFIRM; skip→DRAFT |
| `discardOptimizationEdits()` | "Descartar alterações" | restaura snapshot otimizado + `optimization:optimized, optimizedAt:<snapshot>` | PRE-CONFIRM |
| (stop muda em rota otimizada não-confirmada) | add/remove/update stop | `optimization:editing, optimizedAt:null` (G3 — invalida métrica) | PRE-CONFIRM em modo editing |

**FTUE IdLock (A7-D6):** key nova `id_lock_ftue_v1` no `OptimizationFtueRepository` (`isIdLockAcknowledged`/`acknowledgeIdLock`); diálogo one-shot em `confirmRoute` ANTES de gravar, gate `format==moderno && !idLockAcknowledged`. Microcopy **original** fiel ao significado de `package_identification_lock_dialog_*` ("os IDs ficam fixos após confirmar").

**Discard/editing (A7-D7):** `Route` ganha `optimizedStopsSnapshot` (gravado no `applyOptimization`); a transição para `editing` ocorre quando stops mudam numa rota otimizada não-confirmada; `PopScope` no shell gateia o back em `isEditing` → `DiscardChangesDialog`; "Descartar" restaura o snapshot. Microcopy original fiel a `discard_changes_dialog_*`.

**Sub-unidades de entrega (TDD red→green, ADR-0025):** (1) domínio+estado (getters + 5 métodos do provider + snapshot + FTUE key); (2) diálogos (`IdLockDialog` + `DiscardChangesDialog`); (3) `ReadyToRunView` + banner; (4) wiring no `route_shell_page` (switch `isReadyToRun`, `_onConfirm`/`_onEdit`/`_onStart`/`_onSkip`, `PopScope`).

## Verification gates (per `M2-SLICE-CHECKLIST.md`)

Para declarar a Área 7 done (por PR e no fechamento):

- [ ] `flutter analyze` clean no escopo (nenhum lint novo; baseline 23 MS-DEBT).
- [ ] `flutter test` passa (baseline + novos por PR).
- [ ] `integration_test/area7_optimize_flow_test.dart` verde no M54 (hard gate — toca nav/estado).
- [ ] `spoke-parity-checker` D4 dump-only via `/verify-slice` — 0 must-fix (compara contra `RouteState.kt`/`OptimizeType.kt`/`refine_route_*`/`order_stop_groups_*` + design doc).
- [ ] `flutter-perf-auditor` — must-fix resolvidos (PRE-CONFIRM tem mapa+lista; OrderStopGroups tem overlay de gesto — pontos de atenção de perf).
- [ ] `adr-guardian` — PASS (ADR-0051 acompanha a mudança de lifecycle).
- [ ] Smoke E2E no M54 com APK release (`build-release-apk.sh`) — golden path dos §Goals.
- [ ] PR body preenchido; Vercel preview SUCCESS.
- [ ] Pós-merge final: TODO/roadmap/inventário atualizados (§13.C.4 fechado).

## References

- `CLAUDE.md` — operating manual.
- `docs/08-ROADMAP-v2.md` — §"Área 7 — Otimizar rota" (esta spec elabora e corrige).
- `docs/M2-SLICE-CHECKLIST.md` — gates respeitados.
- `docs/inventory/2026-05-26-spoke-vs-rotpro.md` — §10.8–10.12, §13.C.4 (paridade UX; amendado por esta spec).
- `docs/inventory/spoke-dump-v3.65.1/MASTER-TABLE.md` — #20 Pular otimização.
- **Dump estático Spoke v3.65.1** (`~/spoke-dump/jadx-out`): `core/entity/RouteState.java`, `OptimizationState.java`, `OptimizeType.java`, `OptimizeDirection.java`, `OptimizationOrder.java`, `OptimizationRoutingSolver.java`; `ui/home/editroute/optimization/OptimizationController.java`; `ui/home/editroute/lifecycle/RouteLifecycleController.java`; `ui/home/editroute/orderstopgroup/*`; `ui/loading/LoadVehicle*`, `ui/scanner/LabelScannerViewModel*`; `ui/dialogs/optimizationexplainer/*`. Strings: `~/spoke-dump/res-decoded/res/values-pt-rBR/strings.xml` (`optimizing_*`, `optimization_*`, `refine_route_*`, `order_stop_groups_*`, `package_identification_*`, `load_vehicle_*`).
- `spoke-parity-checker` report 2026-06-13 (Maestro MCP + jadx greps) — funil dinâmico confirmado ao vivo.
- `prototipo/tokens.js` + `prototipo/ui.jsx` — identidade visual (ADR-0035).
- ADR-0030 (paywall só em Navegar), ADR-0035 (Spoke white-label), ADR-0042 (numpad — reuso), ADR-0045 (dump-first), ADR-0049 (D4 dump-only), ADR-0024 (riverpod codegen), ADR-0025 (flutter-test-author).
- Flutter 3.44: `package:flutter/src/material/reorderable_list.dart` (`onReorderItem` confirmado via Dart MCP, 2026-06-13).
- Memória: `lesson_area7_refinar_vs_reotimizar_two_dialogs`, `lesson_googlemap_eats_gestures_use_column`, `lesson_master_table_covers_setup_not_active_shell`, `feedback_spoke_evidence_per_ms`, `project_spoke_b2c_vs_b2b_boundary`.
