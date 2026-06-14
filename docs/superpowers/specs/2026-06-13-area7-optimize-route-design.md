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
| Q7 | Replicar o gate "10 paradas/assinar" do Spoke? | **NÃO clonar** | `undo_optimization_dialog_*` = "Assine para usar rotas com mais de 10 paradas" é o freemium do Spoke. RotPro é ADR-0030 (acesso único R$ 25,90/30d, paywall só em "Navegar" na Á8, otimização grátis). Divergência intencional de negócio. |
| Q8 | Tamanho da entrega? | **4 PRs sequenciais na `develop`** (A: estado+solver+CTA+progresso; B: PRE-CONFIRM+FTUE+Refinar/Reotimizar; C: Ready-to-Run+Confirmar+Iniciar; D: OrderStopGroups) | Á7 ficou grande (solver + 2 estados + progresso + 2 FTUEs + 2 sheets + banner + chips + CTA sticky + tela de grupos). PR único (modelo Á6) teria diff enorme e arriscado. Cada fatia verde+mergeada antes da próxima; zero débito por fatia (regra do harness). OrderStopGroups é a tela mais cara e independente → último PR. |

## Goals (acceptance for this slice)

A real Samsung M54 (`RQCW401G33T`) install de `v1.1.0-area7` pode, contra a API de produção (ou stub local quando aplicável):

1. Numa rota ativa com ≥2 paradas, ver o CTA "Otimizar rota" sticky no rodapé do shell; tocá-lo dispara a otimização (grátis, sem paywall).
2. Na 1ª otimização da conta, ver o modal educativo de numeração (one-shot) com "Entendi" e "Configurar"; tocar "Entendi" prossegue; a 2ª otimização NÃO re-mostra o modal.
3. Durante a otimização, ver a tela de progresso com as 4 fases sequenciais; ao concluir, chegar ao estado PRE-CONFIRM.
4. No PRE-CONFIRM: ver o mapa na metade superior com a rota desenhada (polyline) + markers numerados; a linha de resumo "X min · N paradas · Y km"; a lista de paradas na ordem otimizada, cada uma com chip "A1".."AN"; e os 3 CTAs no rodapé (tempo / "Refinar" / "Confirmar").
5. Tocar "Refinar" → ver o sheet "Refinar a rota" com "Inverter a rota" (reordena reverso e volta ao PRE-CONFIRM) e "Ordenar a rota manualmente" (abre a tela de desenho de grupos).
6. Abrir o kebab no PRE-CONFIRM → "Reotimizar rota..." → ver "Alternativas de reotimização" com "Atualizar rota" e "Reotimizar rota"; cada uma re-roda o solver e volta ao PRE-CONFIRM atualizado.
7. Na tela de "Ordenar a rota manualmente": desenhar ≥2 grupos no mapa (lasso), tocar "Confirmar rota" → a rota reordena pela ordem dos grupos e volta ao PRE-CONFIRM; "Descartar alterações?" e "Aceitar rota atual?" funcionam nos dialogs.
8. Tocar "Confirmar" no PRE-CONFIRM → ver o modal "IDs definitivos" (one-shot) com "Continuar"/"Cancelar"; "Continuar" chega ao Ready-to-Run (sem o modal "Carregar veículo", cortado).
9. No Ready-to-Run: ver os 2 botões-linha ("Compartilhar rota em tempo real" e "Carregar veículo", ambos exibem "Em breve" ao toque) + os 3 CTAs (tempo / "Editar" / "Iniciar rota").
10. Se a otimização falhar (sem rede): ver o dialog de erro com "Tentar de novo" e "Pular otimização"; "Pular" chega ao Ready-to-Run com o banner "Otimização pendente" no mapa.
11. Tocar "Iniciar rota" no Ready-to-Run — o destino (Modo Delivery, Área 8) ainda não existe; nesta área o tap dispara um SnackBar "Em breve" observável (o mesmo idiom de corte honesto dos botões "Carregar veículo"/"Compartilhar rota em tempo real"), sem navegar para tela inexistente. A Área 8 substitui o SnackBar pela navegação real. **Este é o único gateway que aponta para área futura.**

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
│   ├── stop.dart                           # MOD: + String? deliveryId (A1..AN, "Pendente" pré-otim.)
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
    │   ├── optimize_cta.dart               # NEW: CTA sticky
    │   ├── optimizing_progress_view.dart   # NEW: tela 4 fases
    │   ├── optimization_error_dialog.dart  # NEW: "Não foi possível otimizar"
    │   ├── pre_confirm_view.dart           # NEW: PRE-CONFIRM (summary + chips + 3 CTAs)
    │   ├── ready_to_run_view.dart          # NEW: Ready-to-Run (2 botões-linha + 3 CTAs + banner)
    │   ├── route_summary_row.dart          # NEW: "X min · N paradas · Y km"
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
3. **Fidelidade estrutural + microcopy original** — estrutura/fluxo/estados idênticos ao dump (ADR-0035); texto PT-BR é original (ADR-0010), nunca verbatim do Spoke.
4. **Cortes são botões fiéis + ação honesta** — features Slice 3 (Carregar veículo, Compartilhar tempo real) têm o botão no layout (estrutura fiel) mas ação "Em breve" observável (sem bug silencioso).
5. **`@riverpod` codegen + keepAlive** — controllers espelham o padrão de `map_controls_controller.dart`; toda edição de provider dispara o hook `run-riverpod-codegen` (ADR-0024).
6. **`ReorderableListView.builder` com `onReorderItem`** — confirmado da fonte 3.44 (assinatura `void Function(int oldIndex, int newIndex)`, `newIndex` já corrigido; `onReorder` é `@Deprecated`, assert proíbe passar os dois). Usado onde houver reordenação manual de stops.

## Data flow

### Funil de otimização (DRAFT → PRE-CONFIRM)

1. `RouteShellPage` renderiza o estado visual via `switch` sobre `route.routeState` derivado. DRAFT (`optimization == creating && !optimizing`) → mostra `OptimizeCta` sticky no rodapé.
2. Tap no CTA → `OptimizationController.optimize(type: OptimizeType.restartRoute)`. Antes de rodar: se `!optimizationAcknowledged`, mostra `IdEducationDialog` (one-shot); ao "Entendi" grava a flag (`OptimizationFtueRepository`) e prossegue.
3. Controller seta `optimizing = true` → UI mostra `OptimizingProgressView` (4 fases, timer escalonado). Chama `RouteOptimizer.optimize(start, end, stops, type)`.
4. `LocalRouteOptimizer`: nearest-neighbor a partir de `start` (vizinho mais próximo por `Geolocator.distanceBetween`), refina com 2-opt, atribui `deliveryId` "A1".."AN" na ordem final, calcula `totalDistanceMeters` (soma dos legs) e `totalDurationMinutes` (distância ÷ velocidade urbana constante).
5. Sucesso → `RouteState.copyWith(optimization: optimized, optimizing: false, optimizedAt: now)` + métricas no `Route` + stops reordenados. UI → `PreConfirmView`. Erro → `optimizationErroredAt: now`, UI → `OptimizationErrorDialog`.

### Refinar / Reotimizar (dois fluxos distintos — Q3)

- **"Refinar" (rodapé)** → `RefineRouteSheet`. "Inverter a rota" → `optimize(type: reorderFlexible, direction: reverse)` (reverte a ordem atual). "Ordenar a rota manualmente" → push `OrderStopGroupsPage`.
- **Kebab "Reotimizar rota..."** → `ReoptimizeOptionsSheet`. "Atualizar rota" → `optimize(type: reorderFlexible)`. "Reotimizar rota" → `optimize(type: restartRoute)`. Ambos voltam ao PRE-CONFIRM atualizado.

### OrderStopGroups (Ordenar manualmente — PR-D)

`OrderStopGroupsPage` mostra o GoogleMap full-screen. Gesto de arrasto desenha um polígono (lasso) → `StopGroup` (lista de stops dentro do polígono). "Desenhar o próximo grupo" cria o próximo. "Confirmar rota" (habilitado com ≥2 grupos) → `optimize` respeitando a ordem dos grupos (otimiza dentro de cada grupo, concatena na ordem desenhada). Dialogs: "Descartar alterações?" (sair sem aplicar), "Aceitar rota atual?" (confirmar), "Desfazer" (remove último grupo).

### Confirm → Ready-to-Run

Tap "Confirmar" no PRE-CONFIRM → `RouteLifecycleController.onConfirmRoute()`. Se `!idLockAcknowledged`, mostra `IdLockDialog` (one-shot); "Continuar" → `RouteState.copyWith(confirmed: true)` + grava flag. UI → `ReadyToRunView`. Tap "Iniciar rota" → `onStartRoute()` (`started: true`) → placeholder Á8 nesta área.

## Sub-slice plan

| Sub | Scope | Verification |
|---|---|---|
| **PR-A** | `RouteState`/`OptimizationState`/`OptimizeType`/`OptimizeDirection` + migração do enum + métricas no `Route` + `deliveryId` no `Stop` + `RouteOptimizer`/`LocalRouteOptimizer` (testado isolado) + `OptimizationController` + **CTA "Otimizar rota" sticky** + `OptimizingProgressView` (4 fases) + `OptimizationErrorDialog` | Widget+unit tests verdes; CTA visível no M54; solver reordena uma rota de teste; analyze limpo no escopo |
| **PR-B** | `PreConfirmView` (mapa+polyline+markers, `RouteSummaryRow`, lista ordenada + chips A1..AN, 3 CTAs) + `IdEducationDialog` (one-shot) + `RefineRouteSheet` (Inverter real; Ordenar-manual → push p/ destino do PR-D) + kebab `ReoptimizeOptionsSheet` (Atualizar/Reotimizar reais) | PRE-CONFIRM navegável no M54; FTUE one-shot verificado; Inverter/Atualizar/Reotimizar reordenam |
| **PR-C** | `RouteLifecycleController` (confirm/start/edit) + `IdLockDialog` (one-shot) + `ReadyToRunView` (2 botões-linha "Em breve" + Editar + **"Iniciar rota"** + banner "Otimização pendente") + placeholder Á8 | Ready-to-Run navegável; "Iniciar rota" leva ao placeholder; "Pular otimização" → banner |
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

## Accessibility (Karpathy 3 minimum — not optional)

1. **Semantics labels em cada CTA primário.** "Otimizar rota", "Refinar", "Confirmar", "Editar", "Iniciar rota", "Atualizar rota", "Reotimizar rota", "Inverter a rota", "Confirmar rota" (OrderStopGroups), "Entendi", "Continuar".
2. **Tap targets ≥ 48×48 dp.** Os 3 CTAs do rodapé, os botões-linha do Ready-to-Run, as opções dos sheets, a toolbar de desenho do OrderStopGroups.
3. **Color-contrast WCAG AA contra `prototipo/tokens.js`.** O verde do indicador de tempo, o laranja do banner "Otimização pendente", os chips A1..AN — auditados antes de cada PR fechar.

## Test strategy

| Layer | Tool | What it covers in this slice |
|---|---|---|
| Solver | unit | `LocalRouteOptimizer`: ordem NN+2-opt determinística, métricas, `deliveryId` A1..AN, direção reversa, ordem-por-grupos |
| Estado | unit | `RouteState` derivações (isPreConfirm/isReadyToRun/isOptimizing/hasError), transições do `RouteLifecycleController` |
| FTUE | unit | `OptimizationFtueRepository` one-shot (flags) |
| Widgets | widget | Cada view/sheet/dialog: PRE-CONFIRM render, summary, chips, 3 CTAs, RefineRouteSheet vs ReoptimizeOptionsSheet, banner, "Em breve" dos cortes |
| Fluxo | integration_test (M54) | `area7_optimize_flow_test.dart`: Otimizar → progresso → PRE-CONFIRM → Confirmar → Ready-to-Run → "Iniciar rota" placeholder; FTUE one-shot; erro→Pular→banner |

**TDD red→green por task** via `flutter-test-author` (ADR-0025), idiom da Á6.

**Tech debt explícito (added to `TODO.md` na PR):**

- *2026-06-13:* Solver é stand-in Dart on-device; GraphHopper real = Slice 3 (`POST /routes/optimize`). Fronteira `RouteOptimizer` pronta para o swap.
- *2026-06-13:* "Carregar veículo" (barcode/ML Kit) e "Compartilhar rota em tempo real" (backend) = botão fiel + "Em breve" → Slice 3.
- *2026-06-13:* "Iniciar rota" leva a placeholder até a Área 8 construir o Modo Delivery.

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
