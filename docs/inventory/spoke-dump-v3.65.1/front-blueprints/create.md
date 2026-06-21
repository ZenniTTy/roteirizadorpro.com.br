# Front blueprint — create

**Data:** 2026-06-21
**Pacotes fonte:** `com.circuit.p016ui.create` · `com.circuit.p016ui.copy`
**Escopo:** wizard de criação, edição e duplicação de rota + tela de reutilização de paradas (CopyStops, acionada como 2º passo do wizard).

---

## 1. RouteCreateScreen (tela principal do wizard)

**Nome:** Tela de criação / edição / duplicação de rota.
**Classe:** `com.circuit.p016ui.create.RouteCreateFragment` + `RouteCreateScreenKt` (Compose).
**ViewModel:** `RouteCreateViewModel`.
**Estado:** `cac` (RouteCreateState).

### Variantes de entrada (RouteCreateArgs)

| Variante | Campos adicionais | Título da toolbar |
|---|---|---|
| `NewRoute` | `copyStopsOptionChecked: Boolean`, `hasCopyStopsOption: Boolean`, `resultKey: RouteCreateResultKey?` | `"Criar rota"` |
| `EditRoute` | `id: RouteId` | `"Editar rota"` |
| `DuplicateRoute` | `id: RouteId`, `keepProgress: Boolean` | `"Duplicar rota"` |

### Estrutura de campos (ordem de exibição)

1. **Cabeçalho / título da rota**
   - Label: `"Nome da rota (opcional)"` (`route_name_optional_title`)
   - Campo de texto: valor atual em `cac.title` (String); placeholder em `cac.placeholderTitle`
   - Editável somente quando `cac.canChangeTitle == true` (em `EditRoute`, o campo fica bloqueado se a rota veio do dispatcher — `canChangeTitle = false`)

2. **Seção "Selecione a data"** (`route_date_picker_title`)
   - Lista de chips/cards de data rápida: `cac.dates: List<RouteDateUiModel (mac)>`
     - Cada item contém: `title: jqd`, `subtitle: jqd?`, `date: Instant`, `selected: Boolean`
     - Tipicamente 2 opções rápidas geradas: "Hoje" / "Amanhã" (strings: `today`, `tomorrow`)
     - Ícone de cada item: `R.drawable.calendar` → Lucide `Calendar`
   - Chip/card de data customizada: `"Escolher data"` (`route_date_picker_custom`)
     - Ícone: `R.drawable.calendar` → Lucide `Calendar`
     - Habilitado somente quando `cac.isDateSelectionEnabled == true`
   - Ao tocar em "Escolher data": abre `MaterialDatePicker` (date picker padrão Material; constraint via `FutureDateValidator` — só datas >= hoje)

3. **Seção "Selecione o depósito"** (`route_depot_selection_title`) — visível somente quando `cac.depotOption.showDepotOption == true`
   - Linha de seleção: exibe nome do depósito atual (`cac.depotOption.selectedDepot?.name`) ou string vazia quando nenhum selecionado
   - Ícone quando depósito está selecionado: `R.drawable.depot` → Lucide `Warehouse` / `MapPin`
   - Bloqueado quando lista de depósitos vazia (`cac.depotOption.depots.isEmpty()`) ou `canChangeDepot == false`
   - Ao tocar: emite evento `ShowDepotPicker` → abre `DepotDialog`

4. **Seção "Opções de início rápido"** (`route_copy_stops_title`) — visível somente quando `cac.hasCopyStopsOption == true`
   - Checkbox/toggle: label `"Reutilizar paradas anteriores"` (`route_copy_stops_option`)
   - Ícone: `R.drawable.pin_copy` → Lucide `Copy`
   - Estado: `cac.copyStopsChecked: Boolean`

### Botão primário (rodapé)

Texto varia por contexto:

| Condição | Texto |
|---|---|
| `copyStopsChecked == true && hasCopyStopsOption == true` | `"Continuar para copiar paradas"` (`route_create_next_title`) |
| `EditRoute` | `"Salvar alterações"` (`save_changes_button`) |
| `NewRoute` ou `DuplicateRoute` sem copyStops | `"Confirmar"` (`confirm_button_title`) |

### Strings PT-BR verbatim (tela principal)

| Chave | Valor |
|---|---|
| `create_new_route_title` | `"Criar rota"` |
| `edit_route_title` | `"Editar rota"` |
| `duplicate_route` | `"Duplicar rota"` |
| `route_name_optional_title` | `"Nome da rota (opcional)"` |
| `route_date_picker_title` | `"Selecione a data"` |
| `route_date_picker_custom` | `"Escolher data"` |
| `route_depot_selection_title` | `"Selecione o depósito"` |
| `route_copy_stops_title` | `"Opções de início rápido"` |
| `route_copy_stops_option` | `"Reutilizar paradas anteriores"` |
| `route_create_next_title` | `"Continuar para copiar paradas"` |
| `save_changes_button` | `"Salvar alterações"` |
| `confirm_button_title` | `"Confirmar"` |
| `route_create_button_title` | `"Criar rota"` |
| `today` | `"Hoje"` |
| `tomorrow` | `"Amanhã"` |

### Navegação

- **Abre de:** Home (botão "+"), menu kebab de rota existente, tela de rota completada.
- **Apresentado como:** `AdaptiveModalFragment` (bottom sheet ou dialog adaptativo por tamanho de tela).
- **Back/fechar:** `popOrFinish` — fecha o fragment (não vai para outra tela).
- **Ao confirmar (sem copyStops):** emite `AbstractC3206a.c (Finish)` → fecha o modal e envia o `RouteId` de volta via `RouteCreateResultKey` para quem abriu.
- **Ao confirmar (com copyStops, nova rota):** emite `AbstractC3206a.b (CopyStopsToNew)` → navega para `CopyStopsFragment` com `CopyStopsArgs.CopyToNewRoute`.
- **Ao confirmar (com copyStops, duplicação):** emite `AbstractC3206a.a (CopyStopsToDuplicate)` → navega para `CopyStopsFragment` com `CopyStopsArgs.CopyToDuplicatedRoute`.
- **Ao tocar "Escolher data":** emite `AbstractC3206a.d (ShowDatePicker)` → abre `MaterialDatePicker` via `childFragmentManager`.
- **Ao tocar depósito:** emite `AbstractC3206a.e (ShowDepotPicker)` → abre `DepotDialog`.

### Estados e defaults

| Campo | Default |
|---|---|
| `title` | `""` (vazio — o placeholder é o auto-título calculado) |
| `selectedDate` | **Hoje** se hora local < 17h; **Amanhã** se hora local >= 17h (e não é DuplicateRoute) |
| `isDateSelectionEnabled` | `true` para NewRoute / DuplicateRoute; em EditRoute: depende do modo dispatch |
| `canChangeTitle` | `true` para NewRoute / DuplicateRoute; em EditRoute: `false` se rota veio do dispatcher |
| `hasCopyStopsOption` | `true` somente se `PlanFeature.CopyStopsOnRouteCreation` ativo no plano AND (variante é `NewRoute` com `hasCopyStopsOption=true` OR `DuplicateRoute`) |
| `showDepotOption` (mk5) | `true` somente em `NewRoute`; depots carregados via `GetDepots` |
| `copyStopsChecked` | Herda de `NewRoute.copyStopsOptionChecked` |

### RouteCreateState (cac) — campos completos

```
title: String                     // nome digitado pelo usuário
canChangeTitle: Boolean
placeholderTitle: String          // auto-título (data formatada)
dates: List<RouteDateUiModel>     // opções rápidas de data
isDateSelectionEnabled: Boolean
toolbarTitle: jqd                 // string resource do título (Criar/Editar/Duplicar rota)
saveButtonText: jqd               // string resource do botão primário
depotOption: DepotsUiModel (mk5)
hasCopyStopsOption: Boolean
copyStopsChecked: Boolean
```

### DepotsUiModel (mk5) — campos

```
showDepotOption: Boolean          // se a seção de depósito é exibida
canChangeDepot: Boolean
defaultDepot: DepotId?
userSelectedDepot: DepotId?
depots: List<DepotId>
selectedDepot: DepotId?           // derived: userSelectedDepot ?: defaultDepot
```

### Eventos emitidos pelo ViewModel (AbstractC3206a)

| Evento | Classe | Dados |
|---|---|---|
| `CopyStopsToDuplicate` | `a` | title, date, routeId, keepProgress |
| `CopyStopsToNew` | `b` | title, date |
| `Finish` | `c` | routeId (nullable) |
| `ShowDatePicker` | `d` | earliest: Instant |
| `ShowDepotPicker` | `e` | selected: DepotId, options: List<DepotId> |

### Ícones

| Drawable Spoke | Uso | Lucide sugerido (RotPro) |
|---|---|---|
| `calendar` | item de data / "Escolher data" | `Calendar` |
| `depot` | depósito selecionado | `Warehouse` |
| `pin_copy` | opção "Reutilizar paradas" | `Copy` |

### Precisa-runtime

- Comportamento exato do adaptive modal (altura do sheet em telefone vs tablet).
- Animação de transição ao selecionar chip de data (visual do selected/unselected).
- Comportamento de blur/dim do fundo ao abrir DatePicker.
- Se o campo de nome tem um ícone de lápis ou simplesmente é um `TextField` sem ícone.

---

## 2. DepotDialog (seletor de depósito)

**Nome:** Dialog de seleção de depósito (abre a partir do RouteCreateScreen).
**Classe:** `com.circuit.p016ui.settings.dialogs.DepotDialog` (estende `AdaptiveModalDialog`).

### Estrutura

1. Título: `"Depósitos"` (`depot_selection_dialog_title`)
2. Lista de opções (`RadioListTile` / `jv3`): cada item tem `id: DepotId`, `title: String`, `selected: Boolean` (item selecionado = depósito atual)
3. Sem botão de confirmação explícito — tap em um item seleciona e fecha (`onDepotSelected` callback → `ViewModel.onDepotSelected`)

### Strings PT-BR verbatim

| Chave | Valor |
|---|---|
| `depot_selection_dialog_title` | `"Depósitos"` |

### Navegação

- **Abre de:** toque na linha de depósito em RouteCreateScreen.
- **Fecha:** ao selecionar uma opção.

### Precisa-runtime

- Tamanho / altura do dialog (adaptive modal — medium ou large).
- Se há dismiss ao tocar fora ou só ao selecionar item.

---

## 3. MaterialDatePicker (seletor de data customizada)

**Nome:** Picker de data do Material Design (fecha ao selecionar uma data).
**Componente:** `MaterialDatePicker<Long>` com `SingleDateSelector`.
**Constraint:** `FutureDateValidator` — rejeita datas anteriores a "hoje" (mais precisamente: `Instant.now()` no momento da abertura).

### Strings PT-BR (Material / AndroidX — já traduzidas)

| Chave | Valor |
|---|---|
| `m3c_date_picker_title` | `"Selecionar data"` |
| `m3c_date_picker_headline` | `"Data selecionada"` |
| `m3c_date_picker_today_description` | `"Hoje"` |
| `mtrl_picker_date_header_title` | `"Selecionar data"` |

### Navegação

- **Abre de:** botão "Escolher data" em RouteCreateScreen.
- **Ao confirmar:** chama `RouteCreateViewModel.chosenDate(Instant)` → atualiza `cac.dates` e `selectedDate`.
- **Fecha:** ao confirmar ou ao tocar fora / botão de cancelar do sistema.

### Precisa-runtime

- Posição inicial do calendário (mês corrente vs mês da data selecionada).
- Exibição do picker em modo input (digitar data) vs calendário visual.

---

## 4. CopyStopsScreen (tela de reutilizar paradas — 2º passo do wizard)

**Nome:** Tela de seleção e cópia de paradas de rota anterior.
**Classe:** `com.circuit.p016ui.copy.CopyStopsFragment` + `CopyStopsScreenKt` (Compose).
**ViewModel:** `CopyStopsViewModel`.
**Estado:** `xs4` (CopyStopsState).

### Variantes de entrada (CopyStopsArgs)

| Variante | Campos | Contexto |
|---|---|---|
| `CopyToNewRoute` | `title: String`, `date: Instant` | Vindo de NewRoute + copyStopsChecked |
| `CopyToDuplicatedRoute` | `title: String`, `date: Instant`, `routeId: RouteId`, `keepProgress: Boolean` | Vindo de DuplicateRoute |
| `CopyToExistingRoute` | `routeId: RouteId`, `title: String` | Reutilizar de uma rota existente (entrada direta, não pelo wizard) |
| `CopyToSelectableRoute` | `destinationRouteId: RouteId` | Seleção de destino alternativo |

### Estrutura da tela

**Região superior — barra de origem/destino:**
1. Linha "De:" (`copy_stops_option_from_hint`) — exibe a rota de origem selecionada (`xs4.source.selectedRouteTitle`)
2. Linha "Para:" (`copy_stops_option_to_hint`) — exibe a rota de destino (`xs4.destination.selectedRouteTitle`)
   - Quando nenhuma rota destino selecionada: `"Nenhuma rota selecionada"` (`copy_stops_option_to_no_route_selected`)
   - Ícone dropdown: `R.drawable.chevron_down` → Lucide `ChevronDown`

**Cabeçalho / título:** `"Reutilizar paradas"` (`copy_stops_header`)

**Barra de busca:** placeholder `"Pesquisar"` (`copy_stops_searchbar_placeholder`)

**Seções de paradas** (`xs4.sections: List<CopyStopsSectionUiModel>`):

Três seções fixas, em ordem:

| Enum `CopyStopsSection` | Título | Ícone drawable | Texto de vazio |
|---|---|---|---|
| `Failed` | `"Paradas não realizadas"` (`copy_stops_failed_section_title`) | `parcel_fail` | `"Nenhuma parada não realizada nesta rota"` |
| `Skipped` | `"Paradas puladas"` (`copy_stops_skipped_section_title`) | `parcel` | `"Nenhuma parada pulada nesta rota"` |
| `Done` | `"Paradas feitas"` (`copy_stops_done_section_title`) | `parcel_success` | `"Nenhuma parada feita nesta rota"` |

Cada seção tem `SectionToggleState`: `On` / `Off` / `Indeterminate` (para seleção parcial).

**Estado de lista de rotas disponíveis (painel "Para:"):**
- Limite: 50 rotas (`list.size() >= 50`)
- Ao atingir limite: banner `"Mostrando as últimas %1$d rotas"` (`copy_stops_route_limit_title`, valor = 50) + subtítulo `"Volte à página da rota antiga para copiar paradas anteriores."` (`copy_stops_route_limit_subtitle`)
- Rota não iniciada: sublabel `"Não iniciada"` (`copy_stops_route_not_started_subtitle`)

**Estado vazio (nenhuma rota de origem):**
- Imagem ilustrativa: `R.drawable.il_copy_stops_empty`
- Título: `"Transfira as paradas perdidas facilmente"` (`copy_stops_empty_title`)
- Subtítulo: `"Selecione a rota onde quer colocar as paradas copiadas"` (`copy_stops_empty_subtitle`)

**Estado sem resultados de busca:**
- Título: `"Nenhum resultado encontrado"` (`search_no_results_title`)
- Descrição: `"Tente reformular sua busca ou selecione outra rota"` (`copy_stops_search_no_results_description`)

**Botão "Criar nova rota"** (na lista de rotas destino quando aplicável):
- Ícone: `R.drawable.plus` → Lucide `Plus`
- Label acima do botão: `"Criar nova rota"` (`create_new_route_button`)
- Botão abaixo: `"Copiar paradas para uma nova rota"` (`copy_stops_to_new_route_button`)

### Botões de ação (rodapé — CopyButtonUiModel lq4)

| Situação | Texto do botão primário | Tipo |
|---|---|---|
| Selecionadas paradas para copiar | `"Copiar paradas"` (texto dinâmico com contagem) | `Normal` |
| Nenhuma parada selecionada | `"Copiar paradas"` (`copy_stops_copy_button_disabled`) desabilitado | `Normal` |

**Botão secundário (pular cópia):**

| Variante | Texto |
|---|---|
| `CopyToNewRoute` | `"Pular cópia e criar rota"` (`copy_stops_skip_copy_button`) |
| `CopyToDuplicatedRoute` | `"Pular cópia e duplicar rota"` (`copy_stops_skip_copy_and_duplicate_button`) |

**Botão "Copiar paradas para uma nova rota"** (na área de destino quando "Para:" não tem seleção):
- `"Copiar paradas para uma nova rota"` (`copy_stops_to_new_route_button`)

### CopyStopsState (xs4) — campos

```
source: SourceRouteUiModel (ucd)
  selectedRouteId: RouteId
  selectedRouteTitle: jqd
  routeOptionsLimitReachedVisible: Boolean
  routes: List<qq4>              // lista de rotas disponíveis como origem

destination: DestinationRouteUiModel (bn5)
  visible: Boolean
  createRouteVisible: Boolean
  selectedRouteId: RouteId?
  selectedRouteTitle: jqd        // título ou "Nenhuma rota selecionada"
  routeOptionsLimitReachedVisible: Boolean
  routes: List<qq4>              // lista de rotas disponíveis como destino

copyButton: CopyButtonUiModel (lq4)
  enabled: Boolean
  text: jqd
  type: CopyButtonType { Normal | Outline }

sections: List<CopyStopsSectionUiModel (ws4)>
  section: CopyStopsSection { Failed | Skipped | Done }
  toggleState: SectionToggleState { On | Off | Indeterminate }
  stops: List<vld>               // itens de parada selecionáveis
  hasEmptyState: Boolean
  isAtRouteLimit: Boolean

showNoDestinationSelected: Boolean
searchText: String
```

### Eventos emitidos (AbstractC3192e)

| Evento | Ação |
|---|---|
| `Back` | `popBackStack` (fecha CopyStops, volta ao wizard) |
| `CreateRoute` | navega para `RouteCreateFragment` com `NewRoute(resultKey)` |
| `Error` | exibe snackbar `"generic_error"` |
| `Finish` | navega para `R.id.action_home` (rota criada/copiada com sucesso) |

### Navegação

- **Abre de:** RouteCreateScreen ao confirmar com `copyStopsChecked == true`.
- **Também abre de:** botão "Copiar paradas..." no kebab de rota (`more_options_copy_stops_title`), botão "Copiar paradas para uma nova rota" na tela de rota completada.
- **Fecha (Back):** volta para RouteCreateScreen ou para a rota de origem.
- **Fecha (Finish):** vai para Home (rota ativa).

### Strings PT-BR verbatim (CopyStops)

| Chave | Valor |
|---|---|
| `copy_stops_header` | `"Reutilizar paradas"` |
| `copy_stops_option_from_hint` | `"De:"` |
| `copy_stops_option_to_hint` | `"Para:"` |
| `copy_stops_option_to_no_route_selected` | `"Nenhuma rota selecionada"` |
| `copy_stops_searchbar_placeholder` | `"Pesquisar"` |
| `copy_stops_failed_section_title` | `"Paradas não realizadas"` |
| `copy_stops_skipped_section_title` | `"Paradas puladas"` |
| `copy_stops_done_section_title` | `"Paradas feitas"` |
| `copy_stops_empty_failed_section_text` | `"Nenhuma parada não realizada nesta rota"` |
| `copy_stops_empty_skipped_section_text` | `"Nenhuma parada pulada nesta rota"` |
| `copy_stops_empty_done_section_text` | `"Nenhuma parada feita nesta rota"` |
| `copy_stops_empty_title` | `"Transfira as paradas perdidas facilmente"` |
| `copy_stops_empty_subtitle` | `"Selecione a rota onde quer colocar as paradas copiadas"` |
| `copy_stops_route_limit_title` | `"Mostrando as últimas %1$d rotas"` (valor: 50) |
| `copy_stops_route_limit_subtitle` | `"Volte à página da rota antiga para copiar paradas anteriores."` |
| `copy_stops_route_not_started_subtitle` | `"Não iniciada"` |
| `copy_stops_search_no_results_description` | `"Tente reformular sua busca ou selecione outra rota"` |
| `copy_stops_copy_button_disabled` | `"Copiar paradas"` |
| `copy_stops_skip_copy_button` | `"Pular cópia e criar rota"` |
| `copy_stops_skip_copy_and_duplicate_button` | `"Pular cópia e duplicar rota"` |
| `copy_stops_to_new_route_button` | `"Copiar paradas para uma nova rota"` |
| `create_new_route_button` | `"Criar nova rota"` |
| `search_no_results_title` | `"Nenhum resultado encontrado"` |
| `stop_sheet_copy_stops_button` | `"Copiar paradas de uma rota anterior"` |
| `more_options_copy_stops_title` | `"Copiar paradas..."` |
| `completed_route_copy_stops_button` | `"Copiar paradas para uma nova rota"` |

### Ícones (CopyStops)

| Drawable Spoke | Uso | Lucide sugerido (RotPro) |
|---|---|---|
| `parcel_fail` | seção "Não realizadas" | `PackageX` |
| `parcel` | seção "Puladas" | `Package` |
| `parcel_success` | seção "Feitas" | `PackageCheck` |
| `il_copy_stops_empty` | estado vazio (ilustração) | ilustração própria |
| `chevron_down` | dropdown de seleção de rota | `ChevronDown` |
| `plus` | botão criar nova rota | `Plus` |
| `check` | checkbox de seleção de parada | `Check` |

### Precisa-runtime

- Comportamento de seleção parcial de paradas (tripe-state checkbox na seção).
- Animação de colapsar/expandir seção (toggle On/Off/Indeterminate).
- Comportamento de busca: filtra lista de rotas ou filtra paradas dentro da rota?
- Comportamento do painel "De:" / "Para:" — são dropdowns separados ou mesclados na barra superior?
- Quantidade mínima de paradas para o botão "Copiar paradas" habilitar.

---

## 5. DuplicateRoute — tela de opção de progresso

**Nota:** A variante `DuplicateRoute` de `RouteCreateArgs` inclui o campo `keepProgress: Boolean`. O wizard em si não tem uma tela separada para isso — essa escolha é feita **antes** de chegar ao wizard (originada por um dialog ou item de menu que já resolve `keepProgress`). As strings relacionadas existem no APK:

| Chave | Valor |
|---|---|
| `duplicate_route_progress_keep` | `"Manter progresso da rota"` |
| `duplicate_route_progress_keep_description` | `"As paradas feitas continuarão na rota copiada."` |
| `duplicate_route_progress_clear` | `"Redefinir progresso da rota"` |
| `duplicate_route_progress_clear_description` | `"As paradas feitas serão marcadas como não feitas na rota copiada."` |

**Precisa-runtime:** identificar QUAL tela/dialog exibe essas strings (menu da rota completada? sheet de opções?). O RouteCreateFragment não as renderiza diretamente.

---

## Diagrama de navegação (create wizard)

```
[Home / Menu rota]
     │
     ▼
[RouteCreateScreen]  ─── "Escolher data" ──► [MaterialDatePicker]
     │                                              │ (confirma)
     │               ─── toca depósito ───► [DepotDialog]
     │                                              │ (seleciona)
     │
     ├─ (sem copyStops) ──► [Finish → RouteId de volta para origem]
     │
     └─ (com copyStops) ──► [CopyStopsScreen]
                                   │
                                   ├─ (copia) ──► [Finish → Home]
                                   ├─ (pula) ───► [Finish → Home]
                                   └─ (back) ───► [RouteCreateScreen]
```
