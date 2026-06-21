# Área — Lista de paradas da rota ativa (`editroute/steplist`) — design dump-first

> **Origem:** dump-map dump-only do Spoke v3.65.1 (jadx estático), disparado 2026-06-21 após Eduardo reportar que a lista de paradas da rota ativa "está amadora / espaçamento diverge do Spoke". Esta superfície **nunca esteve na MASTER-TABLE** (que cobre setup + detalhe de parada, não o shell ativo — ver `lesson_master_table_covers_setup_not_active_shell`). Este doc é o baseline de FATO da área, per ADR-0045 + diretiva "mapear a área inteira antes de implementar".
>
> **Fonte Spoke (jadx):** `p000/nnd.java` (StopRouteStepUiModelFormatter), `com/circuit/components/steps/AbstractC2673d.java` (icon sealed), `AbstractC2671b.java` (badge sealed), `C2676g.java` (RouteStepUiModel), `RouteStepListGroups$RouteStepGroup.java`, `RouteStepListController.java`, `UpdateEtaChecker.java`. Strings: `res/values-pt-rBR/strings.xml`.

## 1. Anatomia da linha (RouteStepUiModel / `C2676g`)

Cada item da lista carrega: `lineOne` (nome da rua), `lineTwo` (endereço/subtítulo), `icon` (slot ESQUERDO), `badge` (slot DIREITO), `lineAbove`/`lineBelow` (trilho vertical), `isFaded`, `isNextStep`, `isHighlighted`, `chips`/`properties`, `checkbox`, `swipeActions`.

### Slot ESQUERDO — `icon` (`AbstractC2673d`, sealed)

| Subtipo | Quando | Conteúdo |
|---|---|---|
| `Circle` | DRAFT (não otimizado) ou stop sem posição/ETA | círculo vazio |
| `StopNumber(n)` | otimizado, com posição, **sem** ETA disponível | número de sequência |
| `Time(hh:mm)` | ETA disponível, sem posição | horário |
| `TimeAndStopNumber(hh:mm, n)` | **caso principal da rota otimizada** | horário **+** número juntos |
| `Duration(txt)` | pausa/break | ex. "30 min" |
| `Alert` | endereço com problema | triângulo |

**Número e ETA COEXISTEM** no slot esquerdo (`TimeAndStopNumber`) — o ETA NÃO substitui o número. Lógica de escolha em `nnd.m39739p` (528-531).

### Slot DIREITO — `badge` (`AbstractC2671b`, sealed)

`Done` (check), `Skipped`, `Deleted`, contagem de pacotes, ou cor por `StopColor`. Nosso dot 10×10 cobre pending/delivered/failed mas não distingue Skipped.

### Trilho vertical (`RouteStepLine`)

`Solid` conecta stops; `Dashed` na pausa / stop pulado; `None` nas pontas. Visual "trilho de metrô" à esquerda, na coluna do `icon`.

## 2. Linha de INÍCIO (Start row) — primeiro item, sempre

Dois métodos por estado (`nnd.m39733i` DRAFT / `nnd.m39736l` otimizado):

| Estado | `lineOne` sem origem | `lineOne` com origem | `lineTwo` |
|---|---|---|---|
| DRAFT | `start_location_current_placeholder_title` = **"Iniciar no local atual"** | nome da rua | "Use a posição do GPS ao otimizar" (`start_location_use_gps_subtitle`) |
| Otimizado/ativo | `start_location_placeholder_title` = **"Ponto de partida"** | nome da rua | "Posição do GPS usada ao otimizar" (`start_location_gps_used_subtitle`) |

`icon` = `Time(horário de início)` quando há startedAt/agendado, senão `Circle`. **Tappable** (abre seletor de origem).

## 3. Linha de DESTINO (End row) — último item, sempre

`nnd.m39730e`:

| Condição | `lineOne` | `lineTwo` |
|---|---|---|
| Sem destino | "Nenhum destino" (`no_end_location_placeholder`) | "Toque para definir o destino e horário de término" |
| Round-trip | "Ida e volta" (`round_trip`) | "Retorne ao ponto de partida" / "Voltar a %s" |
| Destino explícito | "Finalizar até %s" (`finish_at_x`) | endereço do destino |

`icon` = `Time` (horário de término estimado) ou `Circle`. **Tappable**.

## 4. ETA — fonte e disponibilidade

- Calculado por `qac.m42923b(...)` → `Instant` absoluto (horário de início + tempos de viagem acumulados + serviço por stop). `UpdateEtaChecker` re-dispara quando GPS muda (rota ativa). Formatado por `UiFormatters.m8458m` → `null` quando indisponível.
- **No slot da lista o formato é só o horário** ("14:32"); o prefixo "Chegada: " (`ESTIMATED_TIME_OF_ARRIVAL_SHORT`) aparece em outros contextos (detalhe/marker).
- Disponibilidade: DRAFT → ausente (`Circle`); PRE-CONFIRM/ativo → presente.

## 5. Agrupamento (`RouteStepListGroup`)

- **Otimizado** (`f139026e==true`): seções com header — `Skipped` ("Puladas"), `AddTransferredStops`/`DeleteTransferredStops` (transfer, B2B — CORTADO), `Added` ("Adicionadas"), `Edited` ("Editadas"), `Removed` ("Removidas"), `ExistingRoute`, `Ordered` (lista principal sem header).
- **DRAFT**: sem grupos de status — Setup + Start + End + (Pausa?) + Stops.
- Status de delivery (done/failed/skipped) NÃO cria grupo — afeta `badge` + `isFaded`.

## 6. Variantes por RouteState (resumo)

| Estado | icon | ETA | grupos | start |
|---|---|---|---|---|
| DRAFT | Circle | — | layout simples | "Iniciar no local atual" |
| PRE-CONFIRM | StopNumber/TimeAndStopNumber | sim | Added/Edited/Ordered | "Ponto de partida" |
| READY/active | TimeAndStopNumber | sim, live | + Skipped, isNextStep | horário real |
| Completed | badge Done + isFaded | — | lista plana | — |

---

## Plano de implementação RotPro (refazer fiel)

**Camada de LAYOUT PURO (sem dado novo — fazer agora):**

- **GAP-1 Start row** (must) — `_StartRow` no topo: "Iniciar no local atual" (DRAFT) / "Ponto de partida" (otimizado), subtítulo GPS, tappable→setup.
- **GAP-2 End row** (must) — `_EndRow` no fim: "Nenhum destino" / "Ida e volta" / "Finalizar em X", tappable.
- **GAP-4 Trilho vertical** (must) — linha Solid conectando stops na coluna do badge.
- **GAP-5 Badge numérico** (should) — `_StopBadge(position, etaTime?)`: só número quando sem ETA; número + horário abaixo quando houver.
- **GAP-8 badge Skipped** (nit) — distinguir Skipped do dot atual.

**Camada DEPENDENTE DE DADO:**

- **GAP-6 ETA por stop** — Spoke mostra horário de chegada absoluto. `LocalRouteOptimizer` hoje só retorna `totalDuration`. Decisão: (a) `LocalRouteOptimizer` passa a expor ETAs cumulativas locais agora (startTime + soma dos legs) → preenche o slot já; (b) deixar slot pronto e popular só no Slice 3 (GraphHopper retorna ETA por leg → `Stop.estimatedArrival`). **A view fica pronta nos dois casos; a diferença é se o número aparece em Slice 2 ou Slice 3.**
- **GAP-3 Agrupamento Added/Edited** — requer `Stop` expor grupo (ou rastrear stops adicionados pós-otimização). Mínimo PRE-CONFIRM: agrupar `positionInRoute == null` numa seção "Adicionados".

**CORTADO (B2B per fronteira B2C):** grupos `AddTransferredStops`/`DeleteTransferredStops` (transfer peer-to-peer entre motoristas).

## AMENDMENT 2026-06-21 — captura ao vivo do Spoke (estado otimizado/edit)

> Eduardo pediu paridade ESTRUTURAL milimétrica (identidade visual nossa, ADR-0035).
> Maestro `inspect_screen` no Spoke retorna árvore vazia (`enabled:false`) — blindspot
> Compose (`lesson_uiautomator_blindspot_compose_imagevectors`). dp do dump está
> ofuscado (Pairip) → não extraível limpo. Fonte de fidelidade = **screenshot ao vivo**
> (`/tmp/spoke1.png`, device 1080px) + estrutura do dump. Reimplementar em Flutter.

**Estrutura REAL do Spoke no estado otimizado/edit (uma lista CONTÍNUA, trilho atravessa tudo):**

1. Header: "N paradas" (muted) + nome da rota (bold).
2. **Group header** full-width, faixa cinza clara, texto pequeno muted: ex. **"Paradas adicionadas"**, **"Rota existente"** (enums `RouteStepListGroup`: Added/Edited/Removed/Skipped/ExistingRoute).
3. Linhas, todas no MESMO trilho vertical (disco à esquerda, conteúdo, trailing à direita):
   - **Parada adicionada:** disco cinza + rua/endereço + **dot azul** (trailing).
   - **Pausa:** disco cinza + "Sem pausa" / "Toque para agendar uma pausa" + ícone xícara (trailing).
   - **Ponto de partida:** disco = **hora (pequena, em cima) sobre pin** + "Ponto de partida" / "Posição do GPS usada ao otimizar" + **ícone casa** (trailing).
   - **Parada (stop):** disco = **hora sobre número** (TimeAndStopNumber) + rua/endereço + **chip de ID "A1"** (trailing).
   - **Destino:** disco = **hora** (sem número) + rua/endereço + **ícone bandeira** (trailing).
4. Rodapé: **Descartar** (outlined) / **Aplicar alterações (N)** (filled) — no estado edit.

**Divergência vs RotPro (s3.png PRE-CONFIRM):** nós temos caixa config-summary SEPARADA
(rounded cards, ADR-0046) + lista de paradas solta SEM grupos, SEM início/pausa/destino
integrados. O Spoke integra TUDO numa lista só com grupos. **Esta é a divergência
estrutural grande** (o "completamente diferente" do Eduardo).

**Plano de reimplementação (identidade nossa):**
- Tipos de linha novos no `route_step_list.dart`: `RouteStartStep` (hora+pin / casa),
  `RoutePauseStep` (xícara), `RouteEndStep` (hora / bandeira), `RouteGroupHeader` (faixa).
- A lista (DRAFT/PRE-CONFIRM/Ready) vira UMA lista contínua: [grupos +] início + pausa +
  stops + destino, todos no mesmo trilho. Disco já faz time-over-number ✓.
- **Intersecção ADR-0046:** nos estados otimizados o config-summary em caixa é SUBSTITUÍDO
  pelas linhas integradas (início/destino viram step rows). Registrar via amendment/ADR.
- DRAFT: confirmar via captura Spoke se mantém caixa ou já é lista integrada (Precisa-captura).

## BLUEPRINT DE IMPLEMENTAÇÃO (deep-dump 2026-06-21 — `nnd.java` + `RouteStepListController.java` + `RouteStepListKt.java`)

> Fatos do dump (cita file:line no relatório do dispatch). O Spoke renderiza a lista num `LazyColumn` com **5 tipos de linha** (GroupHeader, Start, Break, Stop, End), regidos por **3 branches** (`isOptimized` × `hasPostOptChanges`).

### 5 tipos de linha (strings PT-BR verbatim)

| Tipo | lineOne | lineTwo | disco (esquerda) | trailing (direita) |
|---|---|---|---|---|
| **GroupHeader** | label do grupo (ver branches) | — | sem disco/trilho; faixa | ícone `deleted_mini` só em Removidas/DeleteTransfer |
| **Start (DRAFT)** | "Iniciar no local atual" (ou nome origem) | "Use a posição do GPS ao otimizar" | Time se houver hora, senão Circle | badge Start → `lucide:home` |
| **Start (otimizado)** | "Ponto de partida" (ou nome origem) | "Posição do GPS usada ao otimizar" | Time(leadingDot) ou Circle; faded se started | `lucide:home` |
| **Break** | "Sem pausa" | "Toque para agendar uma pausa" | Circle | badge None → `lucide:coffee` |
| **Stop** | nome da rua | endereço (linha 2) | Circle / StopNumber / Time / **TimeAndStopNumber** / Alert(skipped) | chip de ID (NotDone/Checked/Success/Failure/Deleted) |
| **Added-stop** | nome da rua | endereço | **sempre Circle** (sem nº até reotimizar) | chip de ID |
| **End/Destino** | "Nenhum destino" / "Ida e volta" / "Finalizar até %s" (ou nome) | "Toque para definir o destino e horário de término" / "Retorne ao ponto de partida" / "Voltar a %s" / endereço | Time ou Circle | badge End → `lucide:flag` |

Disco `AbstractC2673d`: **Circle** (vazio) · **StopNumber**(nº) · **Time**(hora, leadingDot p/ stop atual) · **TimeAndStopNumber**(hora em cima + nº embaixo) · **Alert**(`lucide:alert-circle`, skipped/removido).
Trilho `RouteStepLine`: **Solid** · **Dashed** · **None** — por-linha (`lineAbove`/`lineBelow` independentes).

### 3 branches (ordem das linhas)

- **Branch C — DRAFT (não otimizado):** header **"Configuração de rota"** (`route_setup_header`) → Start row → Destino row → Break row (se feature on) → header **"Paradas"** (plural, `group_header_stops`) → stops. **Sem grupos Added/Edited.** *(É AQUI que o nosso config-summary-em-caixa diverge: o Spoke integra início/destino/pausa como LINHAS no trilho sob "Configuração de rota", não uma caixa separada.)*
- **Branch B — OTIMIZADO sem mudanças / ATIVO:** lista **PLANA, sem grupos**: Break (opcional) → Start → stops → Destino. *(É o nosso PRE-CONFIRM logo após otimizar — sem grupos.)*
- **Branch A — OTIMIZADO com edições pós-opt:** grupos na ordem **Paradas puladas → [transfer B2B, CORTADO] → Paradas adicionadas → Paradas editadas → Paradas removidas → Rota existente** (header só se há itens acima) → Break → Start → stops → Destino. *(É a screenshot `/tmp/spoke1.png`, com "Aplicar alterações (N)".)*

Labels de grupo verbatim: "Paradas puladas" (`skipped_stops`), "Paradas adicionadas" (`added_stops`), "Paradas editadas" (`edited_stops`), "Paradas removidas" (`removed_stops`), "Rota existente" (`existing_route`), "Configuração de rota" (`route_setup_header`), "Parada"/"Paradas" (`group_header_stops`).

### dp legíveis (resto ofuscado → usar proporção da screenshot + token scale 4/8/12/16)

- Padding horizontal externo: **16dp** · Header de grupo padding interno: **8dp** · ícone do header: **24dp** · padding topo do texto do header: **4dp** · botão "Copiar paradas": **16/8/16/16**. Diâmetro do disco / altura da linha / font sizes: **não legíveis** (tema Compose ofuscado).

### Intersecção ADR-0046

No DRAFT, o Spoke integra início/destino/pausa como linhas no trilho sob "Configuração de rota" — NÃO uma caixa de rounded-cards separada. Substituir o config-summary-em-caixa pelas linhas integradas é a mudança estrutural; registrar amendment ao ADR-0046 (ou novo ADR) quando implementar.

## Precisa-runtime (flag, não rodar)

1. Destaque visual do `isNextStep` na rota ativa (cor/scroll/pulsação) — Compose ofuscado.
2. Zero-pad do número (`ond.m40675a`) — provável `toString()` sem pad (nós usamos `padLeft(2,'0')` → revisar).
3. Quais `ChipDescription` aparecem inline na lista vs só no detail sheet.
