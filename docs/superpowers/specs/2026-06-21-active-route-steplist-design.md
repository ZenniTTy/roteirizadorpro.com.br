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

## Precisa-runtime (flag, não rodar)

1. Destaque visual do `isNextStep` na rota ativa (cor/scroll/pulsação) — Compose ofuscado.
2. Zero-pad do número (`ond.m40675a`) — provável `toString()` sem pad (nós usamos `padLeft(2,'0')` → revisar).
3. Quais `ChipDescription` aparecem inline na lista vs só no detail sheet.
