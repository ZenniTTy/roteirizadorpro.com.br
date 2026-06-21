# Front blueprint — copy

> Data: 2026-06-21
> Fonte: `jadx-out/sources/com/circuit/p016ui/copy/` + `res/values-pt-rBR/strings.xml` + `plurals.xml`
> Escopo: fluxo "Reutilizar paradas" — copiar paradas de uma rota passada para uma rota destino
> Pacote Kotlin original: `com.circuit.ui.copy`

---

## 1. Visão geral do fluxo

O fluxo `copy` é acionado a partir de três pontos de entrada na UI e apresenta uma tela única (`CopyStopsScreen`) exibida como **modal adaptativo** (`AdaptiveModalFragment`). O usuário escolhe quais paradas perdidas/puladas/feitas quer copiar, seleciona a rota destino, e confirma. O fluxo termina em navegação de volta, criação de nova rota ou erro.

### Pontos de entrada (strings que disparam a tela)

| String key | Valor PT-BR | Contexto |
|---|---|---|
| `route_copy_stops_title` | "Opções de início rápido" | sheet de opções de rota |
| `route_copy_stops_option` | "Reutilizar paradas anteriores" | item dentro do sheet acima |
| `completed_route_copy_stops_button` | "Copiar paradas para uma nova rota" | tela de rota concluída |
| `more_options_copy_stops_title` | "Copiar paradas..." | kebab menu da lista de rotas |
| `stop_sheet_copy_stops_button` | "Copiar paradas de uma rota anterior" | sheet de parada |

---

## 2. CopyStopsScreen — tela principal

**Classe:** `CopyStopsScreenKt` (Compose screen) + `CopyStopsViewModel`
**Container:** `CopyStopsFragment` extends `AdaptiveModalFragment` (size = `AdaptiveModalSize.Large`, draggable, round corners em cima)
**Propósito:** selecionar paradas de uma rota fonte e copiá-las para uma rota destino

### 2.1 Estrutura geral da tela

A tela é composta por um `LazyColumn` com scroll + header fixo animado acima:

```
┌─────────────────────────────────────────────┐
│  [Header animado / SearchBar]               │  ← sticky, troca por AnimatedContent
├─────────────────────────────────────────────┤
│  [Seletor "De:" — rota fonte]               │  ← anima com scroll (colapsa para o topo)
│  [Seletor "Para:" — rota destino]           │  ← aparece quando há destino selecionado
├─────────────────────────────────────────────┤
│  LazyColumn:                                │
│    Seção: "Paradas não realizadas"          │  ← CopyStopsSection.Failed
│      [item de parada com checkbox]          │
│      ... ou empty state da seção            │
│    Seção: "Paradas puladas"                 │  ← CopyStopsSection.Skipped
│    Seção: "Paradas feitas"                  │  ← CopyStopsSection.Done
│    [Item "Criar nova rota" (+ ícone)]       │  ← opcional, só quando destino é selecionável
│    [Aviso de limite 50 rotas]               │  ← condicional
├─────────────────────────────────────────────┤
│  [Botão CTA "Copiar paradas"]               │  ← rodapé, só visível se seleção > 0 e destino
└─────────────────────────────────────────────┘
```

### 2.2 Estado vazio (sem destino selecionado)

Exibido quando `isNoDestinationSelected == true` (campo `f141987e` do UiModel `xs4`). Ocupa o espaço do LazyColumn:

- **Imagem:** `R.drawable.il_copy_stops_empty` (ilustração, largura até 300dp)
- **Título:** "Transfira as paradas perdidas facilmente" (`copy_stops_empty_title`)
- **Subtítulo:** "Selecione a rota onde quer colocar as paradas copiadas" (`copy_stops_empty_subtitle`)

> **Precisa-runtime:** sim — confirmar animação de entrada/saída do estado vazio.

### 2.3 Header / SearchBar (AnimatedContent)

O header alterna entre dois modos via `AnimatedContent` com booleano `isSearchOpen` (`xs4.f141988f != null`):

#### Modo normal (searchBar fechada)
- **Título animado** "Reutilizar paradas" (`copy_stops_header`) — transiciona de tamanho/posição com scroll (começa grande, centralizado, encolhe e move para o topo esquerdo conforme scroll avança)
- **Seletor "De:"** (função `m9175u`) — visível abaixo do título:
  - Label: "De:" (`copy_stops_option_from_hint`)
  - Valor: nome da rota fonte selecionada ou placeholder
  - Ícone: `R.drawable.chevron_down` (24dp, cor `onSurface`)
  - Comportamento: clicável → abre picker de rota fonte (animação slide horizontal)
  - Colapsa em direção ao topo com o scroll (animação de posição Y)
- **Seletor "Para:"** (função `m9164j`) — visível quando há destino selecionável (modo `CopyToSelectableRoute`):
  - Label: "Para:" (`copy_stops_option_to_hint`)
  - Valor: nome da rota destino ou "Nenhuma rota selecionada" (`copy_stops_option_to_no_route_selected`)
  - Ícone: `R.drawable.chevron_down` (24dp)
  - Fundo: card com ripple animado
  - Só aparece se `xs4.f141984b.f17638a` (modo com destino selecionável habilitado)
- **Ícone busca** (`R.drawable.magnifying_glass` ou equivalente) — botão no topo direito que abre SearchBar

#### Modo busca (searchBar aberta)
- `CopyStopsSearchBar` — barra de busca com:
  - Placeholder: "Pesquisar" (`copy_stops_searchbar_placeholder`)
  - Campo de texto com foco automático ao abrir
  - Sombra animada: aparece quando lista fez scroll (elevation 16dp animada)
  - Botão limpar (ícone X interno ao campo)
  - Back/fechar: fecha a SearchBar e limpa o texto

> **Precisa-runtime:** sim — confirmar ícone exato do botão "busca" no header normal + comportamento do back button dentro da SearchBar.

### 2.4 Seções de paradas (LazyColumn)

Três seções fixas em ordem:

| Enum | String título | String empty | Drawable ícone | Ordem |
|---|---|---|---|---|
| `CopyStopsSection.Failed` | "Paradas não realizadas" | "Nenhuma parada não realizada nesta rota" | `parcel_fail` | 1 |
| `CopyStopsSection.Skipped` | "Paradas puladas" | "Nenhuma parada pulada nesta rota" | `parcel` | 2 |
| `CopyStopsSection.Done` | "Paradas feitas" | "Nenhuma parada feita nesta rota" | `parcel_success` | 3 |

Cada seção tem:
- **Cabeçalho da seção** (`m9177w`): `ToggleableState` (checkbox triestado — On/Off/Indeterminate), título da seção, ícone da seção. O checkbox de seção controla todas as paradas da seção. Se seção está desabilitada (`isDisabled`), o checkbox não aparece (só o título/ícone).
- **Lista de paradas** (quando não vazia): cada item via `m9170p` contendo:
  - **Checkbox** individual (tri-state via `ToggleableState`): marca/desmarca a parada
  - **Nome da rota** (`qq4.f128676b`) — texto principal
  - **Subtítulo/data** (`qq4.f128677c`) — texto secundário
  - **Contador de paradas** (`qq4.f128678d`) — terceiro texto menor
  - **Estados de cor** do item de rota:
    - `isSelected` (f128679e): fundo destaque (cor primária sutil) + ícone check verde à esquerda
    - `isDisabled` (f128680f): fundo desabilitado (opacidade) — rota já usada como destino ou não aplicável
    - normal: fundo surface
  - **Ícone check** (`R.drawable.check`, 24dp, cor `primary`) — visível apenas quando `isSelected == true`
  - Tap na linha: chama `onStopCheckChange(stopId, isChecked)`
  - Tap em linha desabilitada: chama `onDisabledRouteClick()` (mostra toast/snackbar)
- **Empty state da seção** (quando lista vazia): texto centralizado com a string empty da seção

> **Precisa-runtime:** sim — confirmar visual exato do tri-state checkbox (Indeterminate parece parcial, precisa screenshot para confirmar o widget concreto — pode ser `TriStateCheckbox` ou customizado).

### 2.5 Item "Criar nova rota" (condicional)

Exibido logo depois das seções quando o modo é `CopyToSelectableRoute` (usuário pode escolher destino).

- Ícone: `R.drawable.plus` (24dp, cor `secondary`)
- Linha 1: "Criar nova rota" (`create_new_route_button`)
- Linha 2: "Copiar paradas para uma nova rota" (`copy_stops_to_new_route_button`)
- Tap: chama `onCreateRouteSelected()` → evento `CreateRoute` → navega para tela de criação de rota

### 2.6 Aviso de limite de rotas (condicional)

Aparece quando a lista de rotas disponíveis atingiu 50 (`list.size() >= 50`):

- Título: "Mostrando as últimas 50 rotas" (`copy_stops_route_limit_title`, `%1$d = 50`)
- Subtítulo: "Volte à página da rota antiga para copiar paradas anteriores." (`copy_stops_route_limit_subtitle`)
- Sem ícone, sem botão — apenas texto informativo

### 2.7 Picker de rota (lista de rotas disponíveis)

Exibido ao tocar no seletor "De:" ou "Para:" (modo `CopyToSelectableRoute`). Cada item de rota (`qq4`) exibe:

- **Nome da rota** (`qq4.f128676b` — vem de `C3188a.formatDate(route.date, pt-BR format)`)
- **Subtítulo:** nome da rota (`qq4.f128677c`) — pode ser `null`
- **Terceira linha:**
  - Se rota não iniciada (`f23997b == true`): "Não iniciada" (`copy_stops_route_not_started_subtitle`)
  - Se rota iniciada: "%1$d parada(s) perdida(s)" (plural `copy_stops_route_missed_stops_count` — `"1 parada perdida"` / `"N paradas perdidas"`)
- Rota desabilitada (já selecionada como destino): aparece opaca, tap chama `onDisabledRouteClick()`

### 2.8 Estado de busca vazia (search, sem resultados)

Exibido quando busca ativa (`isSearchOpen`) retorna lista vazia:

- Título: "Nenhum resultado encontrado" (`search_no_results_title`)
- Subtítulo: "Tente reformular sua busca ou selecione outra rota" (`copy_stops_search_no_results_description`)
- Sem ícone/ilustração neste estado

### 2.9 Botão CTA (rodapé)

Aparece via `AnimatedVisibility` apenas quando:
- `searchBar fechada` E
- `seleção > 0` (pelo menos uma parada selecionada) E
- `destino selecionado`

Dois tipos de botão (`CopyButtonType`):
- `Normal` — botão primário sólido
- `Outline` — botão contornado

Texto quando desabilitado (sem seleção): "Copiar paradas" (`copy_stops_copy_button_disabled`)

Ações adicionais visíveis no rodapé (quando modo permite):
- "Pular cópia e criar rota" (`copy_stops_skip_copy_button`) — botão text/secundário
- "Pular cópia e duplicar rota" (`copy_stops_skip_copy_and_duplicate_button`) — botão text/secundário

Tap no CTA: chama `onCopyButtonClick()`.

> **Precisa-runtime:** sim — confirmar se os botões "pular" aparecem sempre ou só quando não há seleção + confirmação do tipo de botão (Normal vs Outline) por modo de entrada.

---

## 3. CopyStopsViewModel — lógica de negócio

**Classe:** `CopyStopsViewModel` extends `jz3<xs4, AbstractC3192e>` (BaseViewModel com UiState + Event)

### 3.1 UiState (xs4 — CopyStopsUiModel)

Campos decodificados do construtor `xs4(null, 63)`:

| Campo (ofuscado) | Tipo | Semântica |
|---|---|---|
| `f141983a` (ucd) | `SourceRouteUiModel` | dados da rota fonte selecionada (routeId, nome, hasLimit) |
| `f141984b` (bn5) | `DestinationRouteUiModel` | dados do destino (isSelectableMode, selectedRouteId, routeOptions, hasLimit) |
| `f141985c` | `CopyButtonUiModel` | estado do botão CTA (enabled, type, text) |
| `f141986d` | `List<ws4>` (CopyStopsSectionUiModel) | seções de paradas com seus items |
| `f141987e` | `Boolean` | `isNoDestinationSelected` |
| `f141988f` | `String?` | texto da busca ativa (null = searchBar fechada) |

### 3.2 Eventos de saída (AbstractC3192e)

| Evento | String interna | Ação no Fragment |
|---|---|---|
| `AbstractC3192e.a` ("Back") | — | `popBackStack()` |
| `AbstractC3192e.b` ("CreateRoute") | — | navega para `RouteCreateFragment` (NewRoute mode) com `copy_stops` resultKey |
| `AbstractC3192e.c` ("Error") | — | toast genérico de erro (`R.string.generic_error`) |
| `AbstractC3192e.d` ("Finish") | — | navega para `action_home` (tela inicial) |

### 3.3 Modos de entrada (CopyStopsArgs — sealed class)

| Subtipo | Campos | Contexto de uso |
|---|---|---|
| `CopyToExistingRoute` | `routeId: RouteId`, `title: String` | copiar para rota existente já determinada |
| `CopyToNewRoute` | `title: String`, `date: Instant` | copiar e criar nova rota com esses dados |
| `CopyToDuplicatedRoute` | `title: String`, `date: Instant`, `routeId: RouteId`, `keepProgress: Boolean` | copiar para rota duplicada (mantém ou reseta progresso) |
| `CopyToSelectableRoute` | `destinationRouteId: RouteId?` | usuário escolhe o destino na tela (modo mais genérico) |

### 3.4 Limite de rotas

- Máximo exibido: **50 rotas** (hardcoded em `m9194W`: `m9196Y(50, ...)`)
- Aviso aparece quando `list.size() >= 50`
- O aviso de limite **não bloqueia** — é informativo

### 3.5 Callbacks do ViewModel

| Método | Disparo |
|---|---|
| `onSectionCheckChange(section, isChecked)` | tap no checkbox de seção (selecionar/deselecionar todos) |
| `onStopCheckChange(stopId, isChecked)` | tap no checkbox de parada individual |
| `onSourceRouteSelected(routeId)` | usuário seleciona rota fonte no picker |
| `onDestinationRouteSelected(routeId)` | usuário seleciona rota destino |
| `onCreateRouteSelected()` | tap no item "Criar nova rota" |
| `onCopyButtonClick()` | tap no CTA |
| `onDisabledRouteClick()` | tap em rota desabilitada na lista |
| `onOpenSearch()` | tap no ícone busca |
| `onCloseSearch()` | fechar searchBar |
| `onSearchTextChanged(text)` | digitação na SearchBar |
| `onBackClick()` | botão físico de volta ou gestura |

---

## 4. Strings PT-BR verbatim completas

```
copy_stops_header                  = "Reutilizar paradas"
copy_stops_option_from_hint        = "De:"
copy_stops_option_to_hint          = "Para:"
copy_stops_option_to_no_route_selected = "Nenhuma rota selecionada"
copy_stops_failed_section_title    = "Paradas não realizadas"
copy_stops_skipped_section_title   = "Paradas puladas"
copy_stops_done_section_title      = "Paradas feitas"
copy_stops_empty_failed_section_text  = "Nenhuma parada não realizada nesta rota"
copy_stops_empty_skipped_section_text = "Nenhuma parada pulada nesta rota"
copy_stops_empty_done_section_text    = "Nenhuma parada feita nesta rota"
copy_stops_empty_title             = "Transfira as paradas perdidas facilmente"
copy_stops_empty_subtitle          = "Selecione a rota onde quer colocar as paradas copiadas"
copy_stops_route_not_started_subtitle = "Não iniciada"
copy_stops_route_limit_title       = "Mostrando as últimas %1$d rotas"  (runtime: %1$d = 50)
copy_stops_route_limit_subtitle    = "Volte à página da rota antiga para copiar paradas anteriores."
copy_stops_search_no_results_description = "Tente reformular sua busca ou selecione outra rota"
copy_stops_searchbar_placeholder   = "Pesquisar"
copy_stops_copy_button_disabled    = "Copiar paradas"
copy_stops_to_new_route_button     = "Copiar paradas para uma nova rota"
copy_stops_skip_copy_button        = "Pular cópia e criar rota"
copy_stops_skip_copy_and_duplicate_button = "Pular cópia e duplicar rota"
create_new_route_button            = "Criar nova rota"
search_no_results_title            = "Nenhum resultado encontrado"

[PLURAL] copy_stops_route_missed_stops_count:
  one   = "%1$d parada perdida"
  other = "%1$d paradas perdidas"

[ENTRYPOINTS]
route_copy_stops_title             = "Opções de início rápido"
route_copy_stops_option            = "Reutilizar paradas anteriores"
completed_route_copy_stops_button  = "Copiar paradas para uma nova rota"
more_options_copy_stops_title      = "Copiar paradas..."
stop_sheet_copy_stops_button       = "Copiar paradas de uma rota anterior"
```

---

## 5. Ícones (drawable → equivalente Lucide sugerido)

| Drawable Spoke | Contexto | Lucide sugerido |
|---|---|---|
| `chevron_down` | seletor "De:" e "Para:" | `ChevronDown` |
| `plus` | item "Criar nova rota" | `Plus` |
| `check` | checkbox selecionado em item de rota | `Check` |
| `parcel_fail` | ícone seção "Paradas não realizadas" | `PackageX` |
| `parcel` | ícone seção "Paradas puladas" | `Package` |
| `parcel_success` | ícone seção "Paradas feitas" | `PackageCheck` |
| `il_copy_stops_empty` | ilustração estado vazio | *(ilustração original — criar equivalente)* |
| `magnifying_glass` (inferido) | botão abrir busca | `Search` |

> Ícone da busca no header não aparece literalmente no código do SearchBar — **Precisa-runtime** para confirmar se é lupa ou se está dentro da SearchBar component interno.

---

## 6. Navegação

| Origem | Destino | Condição |
|---|---|---|
| Qualquer ponto de entrada externo | `CopyStopsFragment` (modal) | via `RouteId` + `CopyStopsArgs` |
| Evento `Back` | `popBackStack()` | botão voltar / gesto |
| Evento `Finish` | `action_home` (rota ativa) | cópia concluída com sucesso |
| Evento `CreateRoute` | `RouteCreateFragment` mode `NewRoute` | usuário toca "Criar nova rota" |
| Evento `Error` | toast de erro + permanece na tela | falha na cópia |
| Seletor "Para:" | (mesmo modal, picker de rotas na LazyColumn) | sem nova tela, filtra na mesma lista |

---

## 7. Estados / defaults / enums

### CopyStopsSection (enum, 3 valores, ordem fixa)
```
Failed  → seção "Paradas não realizadas" (índice 0)
Skipped → seção "Paradas puladas"        (índice 1)
Done    → seção "Paradas feitas"         (índice 2)
```

### CopyButtonType (enum, 2 valores)
```
Normal  → botão primário sólido
Outline → botão contornado/secundário
```

### ToggleableState do checkbox de seção
```
On           → todas as paradas da seção selecionadas
Off          → nenhuma selecionada
Indeterminate → seleção parcial
```

### Limites
```
Máximo de rotas exibidas: 50
Mostra aviso quando: list.size() >= 50
```

### Defaults no boot do ViewModel
- Rota fonte: `findDefaultSourceRoute()` — tenta a rota ativa; se a ativa conflita com o arg, busca outra rota
- Rota destino: pré-selecionada quando `CopyToExistingRoute` ou `CopyToDuplicatedRoute`; vazia quando `CopyToSelectableRoute` com `destinationRouteId == null`
- Todas as paradas: **desmarcadas** por padrão (usuário seleciona manualmente)

---

## 8. Precisa-runtime (resumo)

| Item | Motivo |
|---|---|
| Ícone do botão "busca" no header normal | Não aparece no código decompilado do header normal — pode estar dentro de um componente reutilizável |
| Visual do checkbox tri-state (`Indeterminate`) | Pode ser `TriStateCheckbox` nativo Compose ou custom — necessita screenshot |
| Animação de transição dos seletores "De:"/"Para:" com scroll | Parâmetros de animação (`lerp` com ihdVar) legíveis no código mas comportamento visual precisa confirmação |
| Botões "Pular cópia" — quando aparecem | Condição exata não totalmente clara no código (pode depender do `CopyStopsArgs` específico) |
| Ordem real das seções quando uma está vazia | Seção vazia some completamente ou mostra empty state? O código mostra ambas possibilidades |
| Visual do item de rota desabilitado | Código mostra cor diferente (`dy3.f97568b` = sem fundo?) mas precisa screenshot para cor exata |
