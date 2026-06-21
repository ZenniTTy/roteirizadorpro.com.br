# Front blueprint — edit

**Data:** 2026-06-21
**Pacote principal:** `com.circuit.ui.edit` + `com.circuit.ui.home.editroute.addstopatexactlocation.editaddress`
**Escopo:** edição de parada (EditStopDialogFragment + EditStopEditor) + edição de endereço (EditExactLocationAddressFragment)

---

## 1. EditStopDialogFragment — modal "Editar parada"

**Propósito:** Dialog/modal adaptativo (bottom-sheet no celular, dialog centrado em tablet) que exibe todos os campos editáveis de uma parada.
**Classe:** `com.circuit.ui.edit.EditStopDialogFragment` estende `AdaptiveModalFragment`

### 1.1 Estrutura geral

O modal é composto por `EditStopEditor` (o conteúdo principal). No modo pager (`EditStopPager`), múltiplas paradas navegáveis horizontalmente por swipe são exibidas com um divider animado entre elas.

**Ordem dos blocos dentro de EditStopEditor (de cima para baixo):**

1. **Cabeçalho de cor / badge de parada** — `cf6` (stopBadges): chip de cor + badge de status (ex.: "Pendente") + quantidade de pacotes em badge
2. **Nome da parada (addressLine1)** — campo de texto principal (ex.: "Rua Paulista, 100")
3. **Linha 2 do endereço (addressLine2)** — opcional, exibida abaixo do nome se preenchida
4. **Banner de "localização não está clara"** — visível quando `showMissingStreetNumberButton = true`
5. **Aviso de localização + mapa miniatura (unclearLocationMap)** — animado (fade in/out) com botões "Sim, está correto" / "Corrigir localização"
6. **Instruções de acesso (accessInstructions)** — seção com ícone `attachment`
7. **Notas** — área de texto livre com ícone `notes_16` e botão câmera (`ic_add_photo_24`) para adicionar foto
8. **Fotos de pacote** — lista horizontal de fotos (max 3); visível somente se `packagePhotos` não vazio
9. **Seção de Destinatário** — ícone `person_outline`; label = nome do destinatário (ou texto padrão "Destinatário"); sub-label = "Contato" se houver phone/email
10. **Seção de configurações (SettingsSection)** — contém os toggles abaixo em ordem:
    - Localizador de pacotes (PackageFinder) — ícone `find_package`
    - Pacotes (quantidade) — ícone `ic_multiple_packages_24px`
    - Ordem de otimização — ícone `optimization_order` / `optimization_order_first` / `optimization_order_last`
    - Tipo de atividade — ícone `activity_type_delivery` / `activity_type_pickup`
    - Horário de chegada (time window) — ícone `time_window`
    - Tempo estimado na parada — ícone `timer`
    - Valor a cobrar (CoD) — ícone numérico (drawable dinâmico)
11. **Seção de informações extras (stopProperties)** — linhas dinâmicas de propriedades customizadas (tipo "attachment") e da categoria especial (tipo `AbstractC2715e.b`)
12. **Seção de cliente/retailer** — ícone `store_outline`; label = "Cliente" + nome do cliente (ou "Nenhum cliente"); visível somente quando `showRetailerInfoRow = true`
13. **Propriedades custom (barcodes / ClientId)** — lista de chips / linhas com ClientId quando `barcodes` não vazio
14. **Parada vinculada (linkedStopsInfo)** — ícone `linked_stop`; exibe parada relacionada com botão de navegação para ela

### 1.2 Strings PT-BR verbatim

| Chave | Valor |
|---|---|
| `edit_stop_title` | "Editar parada" |
| `edit_stop_button` | "Editar parada" |
| `save_changes_button` | "Salvar alterações" |
| `add_notes_placeholder` | "Adicionar notas" |
| `edit_stop_no_notes_placeholder` | "Nenhuma nota adicionada" |
| `stop_setting_activity_type_title` | "Tipo" |
| `stop_activity_delivery` | "Entrega" |
| `stop_activity_pickup` | "Coleta" |
| `stop_setting_packages_title` | "Pacotes" |
| `package_label_status_pending` | "Pendente" |
| `package_finder_title` | "Localizador de pacotes" |
| `place_in_vehicle_not_set` | "Não definido" |
| `stop_setting_arrival_time_title` | "Horário de chegada" |
| `stop_property_time_at_stop` | "Tempo estimado na parada" |
| `stop_property_cash_on_delivery` | "Valor a cobrar" |
| `stop_setting_order_title` | "Ordem" |
| `stop_setting_order_option_first` | "Primeira" |
| `stop_setting_order_option_last` | "Última" |
| `stop_setting_order_option_auto` | "Automática" |
| `stop_property_client_name` | "Cliente" |
| `stop_property_client_no_client` | "Nenhum cliente" |
| `stop_property_recipient_contact` | "Contato" |
| `stop_recipient_title` | "Destinatário" |
| `stop_status_not_loaded` | "Não carregado" |
| `access_instructions_label` | "Instruções de acesso" |
| `barcode_copied` | "Código de barras copiado" |
| `delete_stop_action_title` | "Remover parada" |
| `remove_stop_title` | "Remover parada" |
| `remove_stop_confirmation_dialog_text` | `"Quer remover \"%1$s\" da rota?"` |
| `remove_stop_on_optimization_confirmation_dialog_text` | `"A parada \"%1$s\" será removida da rota na próxima otimização."` |
| `duplicate_stop_title` | "Duplicar parada" |
| `duplicate_stop_toast_view_action` | "Ver" |
| `fix_address_button` | "Corrigir endereço" |
| `unclear_location_warning` | "A localização não está clara" |
| `unclear_location_dismiss_button` | "Sim, está correto" |
| `unclear_location_fix_button` | "Corrigir localização" |
| `stop_color_title` | "Cor" |
| `stop_color_blue` | "Azul" |
| `stop_color_orange` | "Laranja" |
| `stop_color_pink` | "Rosa" |
| `stop_color_purple` | "Roxo" |
| `stop_color_teal` | "Verde-azulado" |
| `edit_stop_set_earliest_time_title` | "Definir primeiro horário" |
| `edit_stop_set_latest_time_title` | "Definir último horário" |

### 1.3 Ícones (Spoke drawable → Lucide sugerido para RotPro)

| Drawable Spoke | Seção | Lucide sugerido |
|---|---|---|
| `activity_type_delivery` | Tipo = Entrega | `PackageCheck` ou `Truck` |
| `activity_type_pickup` | Tipo = Coleta | `PackagePlus` |
| `ic_multiple_packages_24px` | Pacotes | `Package` |
| `find_package` | Localizador de pacotes | `ScanSearch` |
| `optimization_order` | Ordem = Automática | `ArrowUpDown` |
| `optimization_order_first` | Ordem = Primeira | `ArrowUp` |
| `optimization_order_last` | Ordem = Última | `ArrowDown` |
| `time_window` | Horário de chegada | `Clock` |
| `timer` | Tempo na parada | `Timer` |
| `notes_16` | Notas | `FileText` |
| `ic_add_photo_24` | Adicionar foto | `Camera` |
| `person_outline` | Destinatário | `User` |
| `store_outline` | Cliente | `Store` |
| `attachment` | Propriedades / Instruções | `Paperclip` |
| `linked_stop` | Parada vinculada | `Link` |

### 1.4 Navegação

- **Quem abre:** toque em parada na lista (route shell), toque em marcador do mapa, ou ação "Editar parada" do kebab da parada
- **Args de entrada:** `EditStopDialogArgs { stopId: BaseStopId, scrollToNewStop: Boolean }`
- **Retorno:** bundle com chave `"edit_stop_result"` (boolean `stop_edited`)
- **O que este modal abre:**
  - Toque em "Corrigir endereço" → `EditExactLocationAddressFragment`
  - Toque em campo de endereço → `AddressPickerFragment` (busca de endereço)
  - Toque em cor → color picker sheet (inline no `C2682b.m8521a`)
  - Toque em "Localizador de pacotes" → `PackageFinderSheet`
  - Toque em "Horário de chegada" → time-window picker (Área 5 — ADR-0044)
  - Toque em "Tempo na parada" → time-at-stop picker (Área 5)
  - Toque em "Pacotes" (quando habilitado) → `PackageDetailsDialog`
  - Toque em "Duplicar parada" → cria cópia e exibe toast com link "Ver"
  - Toque em "Remover parada" → dialog de confirmação com texto `remove_stop_confirmation_dialog_text`

### 1.5 Estados e variações

**Estado do dialogo:**
- `showAddedBadge`: badge "nova parada" visível
- `showUpdatedBadgeOnChange`: badge atualiza ao editar
- `showLoadedBadge`: badge carregado visível

**Estado de `EditStopState` (C3353k):**

| Campo | Tipo | Significado |
|---|---|---|
| `addressLine1` | `String` | Linha 1 do endereço (sempre presente) |
| `addressLine2` | `String?` | Linha 2 opcional |
| `notes` | `String?` | Notas livres |
| `packagePhotos` | `List<Uri>` | Fotos de pacote (max 3) |
| `optimizationOrder` | `OptimizationOrder?` | `null`, `FIRST`, `AUTO`, `LAST` |
| `activity` | `StopActivity?` | `DELIVERY` (default), `PICKUP` |
| `packageDetailsText` | `twa?` | Localização no veículo (2 strings: compartimento/posição) |
| `timeAtStopText` | `xv7?` | Texto formatado do tempo estimado |
| `timeWindowText` | `xv7?` | Texto formatado do time window |
| `stopBadges` | `cf6` | Cor + badge de status + chip de quantidade |
| `featureEnablement` | `fg6` | Flags de features habilitadas por plano |
| `stopProperties` | `gfc` | Propriedades dinâmicas (custom props) |
| `accessInstructions` | `re6?` | Duas strings: linha1, linha2 |
| `packageCount` | `Integer?` | null = sem pacotes, 1 = sem label, >1 = "Nx" |
| `packageCountReadOnly` | `Boolean` | true = B2B (não editável) [B2B — cortar] |
| `barcodes` | `List<df6>` | Códigos de barras vinculados |
| `chips` | `List<ChipDescription>` | Chips de status na UI |
| `showMissingStreetNumberButton` | `Boolean` | Exibe aviso de número de rua ausente |
| `unclearLocationMap` | `dh6?` | Mapa miniatura de localização imprecisa |
| `showRetailerInfoRow` | `Boolean` | Exibe seção de cliente/retailer |
| `retailerInfo` | `z5c?` | Info do cliente (nome + ID) |
| `linkedStopsInfo` | `ga9?` | Info de parada vinculada |

**OptimizationOrder enum:**
- `FIRST` (índice 0) → "Primeira" → ícone `optimization_order_first`
- `AUTO` (índice 1) → "Automática" → ícone `optimization_order`
- `LAST` (índice 2) → "Última" → ícone `optimization_order_last`

**StopActivity enum:**
- `DELIVERY` (índice 0, default) → "Entrega" → ícone `activity_type_delivery`
- `PICKUP` (índice 1) → "Coleta" → ícone `activity_type_pickup`

**StopColor enum:**
- `BLUE`, `ORANGE`, `PINK`, `PURPLE`, `TEAL`

**Visibilidade condicional por `featureEnablement` (fg6):**
- `f100486a` → feature PackageFinder: controla visibilidade do localizador de pacotes
- `f100487b` → feature OptimizationOrder: habilita/bloqueia toggle de ordem
- `f100488c` → feature PackageCount: habilita contador de pacotes editável
- `f100489d` → feature ActivityType: habilita/bloqueia toggle de tipo
- `f100490e` → feature ChangeStopArrivalTime: habilita/bloqueia horário de chegada
- `f100491f` → feature ChangeStopTimeAtStop: habilita/bloqueia tempo na parada
- `f100495j` → feature StopColor: habilita seletor de cor
- `f100497l` → FeatureStatus usado pelo campo de ordem
- `f100499n` → controla exibição de barcode/scanner B2B [B2B — cortar]
- `f100500o` → feature AssignRetailerToStop: controla seção de cliente

Quando uma feature está desabilitada por plano (`FeatureStatus.DISABLED_PLAN`), o campo aparece em modo read-only com texto em cinza; toque chama `onDisabledFeatureClicked` que provavelmente abre paywall.

### 1.6 Modo pager (EditStopPager)

Quando aberto via swipe na lista de paradas, o mesmo dialog usa `EditStopPager`:
- Suporta navegação horizontal entre paradas adjacentes
- Divider animado entre cards (animação de alpha)
- **Classe:** `com.circuit.ui.edit.pager.EditStopPagerKt` + `EditStopPagerViewModel`
- **Args:** `EditStopPagerArgs { initialPage: BaseStopId, eventContext: EmbeddedContext }`

---

## 2. EditStopDialogArgs — args de entrada do dialog

**Propósito:** Parcelable que carrega os argumentos ao abrir o dialog de edição.
**Classe:** `com.circuit.ui.edit.EditStopDialogArgs`

### Campos

| Campo | Tipo | Significado |
|---|---|---|
| `stopId` | `BaseStopId<?>` | ID da parada a editar |
| `showAddedBadge` | `Boolean` | Exibir badge "adicionado" |
| `showUpdatedBadgeOnChange` | `Boolean` | Badge muda ao editar |
| `showLoadedBadge` | `Boolean` | Exibir badge "carregado" |

**Result key:** `"edit_stop_result"` com Boolean `stop_edited`

---

## 3. ConfirmRemoveStopDialog — diálogo de confirmação de remoção

**Propósito:** Diálogo de confirmação ao tentar remover uma parada da rota.
**Classe:** chamado diretamente em `EditStopCardKt` via `ConfirmRemoveMediaImportStopDialog` ou via evento `onConfirmDeleteStopClick`

### 3.1 Estrutura

- Título: inferível como "Remover parada"
- Corpo: `"Quer remover \"%1$s\" da rota?"` (interpolado com nome da parada)
- Variante quando rota está otimizada: `"A parada \"%1$s\" será removida da rota na próxima otimização."`
- Botão confirmar: "Remover parada" (ação destrutiva)
- Botão cancelar: presente (texto não confirmado pelo dump, Precisa-runtime)

### 3.2 Navegação

- Aberto por: toque em "Remover parada" no editor
- Resultado: fecha modal de edição ao confirmar

---

## 4. EditExactLocationAddressFragment — modal "Editar endereço"

**Propósito:** Modal adaptativo para corrigir/editar o endereço de uma parada manualmente (duas linhas de texto editáveis).
**Classe:** `com.circuit.ui.home.editroute.addstopatexactlocation.editaddress.EditExactLocationAddressFragment` estende `AdaptiveModalFragment`

### 4.1 Estrutura

Layout vertical com:

1. **Barra de título** — texto "Editar endereço" + botão esquerdo (Cancelar / Limpar conforme estado)
2. **Campo addressLine1** — TextField editável, obrigatório; placeholder não confirmado pelo dump (Precisa-runtime)
3. **Botão de limpeza (X)** — aparece sobre/ao lado do campo quando o campo tem conteúdo (`showClearButton` = `!isEmpty(addressLine1)`)
4. **Campo addressLine2** — TextField editável, opcional
5. **Botão done "Salvar alterações"** — ativo quando addressLine1 preenchido

**Nota sobre layout orientação:** o conteúdo muda de Column (portrait) para Row (landscape) usando `BreakpointOrientation`.

### 4.2 Strings PT-BR verbatim

| Chave | Valor |
|---|---|
| `edit_address_title` | "Editar endereço" |
| `cancel` | "Cancelar" |
| `clear_button_title` | "Limpar" |
| `save_changes_button` | "Salvar alterações" |

O botão esquerdo da barra usa `clear_button_title` quando `q96.hasEdits = true` (campo foi editado), `cancel` caso contrário.

### 4.3 Ícones

Nenhum ícone específico neste modal além dos ícones de teclado/UI padrão do sistema.

### 4.4 Navegação

- **Quem abre:** toque em "Corrigir endereço" no `EditStopEditor` (botão `fix_address_button`), ou toque em "Corrigir localização" no aviso de localização imprecisa
- **Args:** `EditExactLocationAddressArgs` com stopId e endereço atual
- **Resultado:** `EditExactLocationAddressResult` retornado via `EditExactLocationAddressResultKey`
- O modal intercepta o botão Back do Android (registra `OnBackPressedDispatcher`)

### 4.5 Estado (q96 / ViewModel C3498c)

| Campo | Tipo | Significado |
|---|---|---|
| `addressLine1` | `o8e` (TextFieldValue) | Campo principal |
| `addressLine2` | `o8e` (TextFieldValue) | Campo secundário |
| `hasEdits` | `Boolean` | True = usuário editou ao menos um campo |

**Callbacks do ViewModel (C3498c):**
- `onCancelClick()` — fecha o modal sem salvar
- `onClearClick()` — limpa campos
- `onDoneClick()` — salva e fecha
- `onAddressLine1Change(TextFieldValue)` — atualiza campo 1
- `onAddressLine2Change(TextFieldValue)` — atualiza campo 2

---

## 5. StopBadge / ColorPicker (inline no EditStopEditor)

**Propósito:** Seção no topo do editor que exibe a cor atual da parada e permite troca; também exibe chips de status.
**Classe:** `com.circuit.components.stops.C2682b` chamada inline em `EditStopEditorKt`

### 5.1 Estrutura

- **Círculo de cor** — toque abre seletor de cor (5 cores: BLUE, ORANGE, PINK, PURPLE, TEAL)
- **Badge de status** — ex.: "Pendente" (string `package_label_status_pending`) — `AbstractC3343a.a` = pending, `AbstractC3343a.b` = outro estado com texto dinâmico
- **Chip de quantidade** — ex.: "2×" se packageCount > 1

### 5.2 Ícones

Ícone de cor é o próprio círculo colorido sem drawable específico (cor da entidade).

---

## 6. AccessInstructions — seção de instruções de acesso

**Propósito:** Linha no editor mostrando instruções de acesso ao local da entrega.
**Classe:** inline em `EditStopEditorKt` via `ze6.m47093a`

### 6.1 Estrutura

- Ícone: `attachment` (Paperclip)
- Label linha 1: texto das instruções (`re6.b`)
- Label linha 2: sub-texto (`re6.a`)
- Quando vazio: visível mas com estado desabilitado (toque chama `onDisabledAccessInstructionsClicked`)
- Quando habilitado: toque chama `onAccessInstructionsClicked`

### 6.2 Strings

- `access_instructions_label` → "Instruções de acesso"

---

## 7. LinkedStopRow — linha de parada vinculada

**Propósito:** Exibe a parada vinculada (parceiro de pickup/delivery) dentro do editor.
**Classe:** inline em `EditStopEditorKt` via `m9329h` + `ja9.m36303a`

### 7.1 Estrutura

- Ícone: `linked_stop` (Link)
- Label: nome/endereço da parada vinculada (`ga9.b`)
- Toque: navega para a parada vinculada (`onLinkedStopClicked(DefaultStopId)`)
- Dimensões do widget de parada: `56dp` altura, `48dp` largura

---

## 8. PackageCountRow — linha de contagem de pacotes

**Propósito:** Linha no editor mostrando e permitindo editar o número de pacotes.
**Classe:** inline em `EditStopEditorKt` via `m9333l` (editável) e `m9327f` (read-only/B2B)

### 8.1 Variantes

**Modo read-only (B2B — cortar):** exibe apenas ícone + label + valor sem toque.
**Modo editável (B2C):** toque abre spinner/stepper com valor mínimo = 1, máximo = 9999.

### 8.2 Lógica de exibição

- `packageCount == null` → exibe 0
- `packageCount == 1` → sem chip de quantidade (não exibe "1×")
- `packageCount > 1` → badge "Nx" (ex.: "2×") usando formato `String.format("%d×", count)`

### 8.3 Strings + Ícone

- Label: `stop_setting_packages_title` → "Pacotes"
- Ícone: `ic_multiple_packages_24px` → Lucide `Package`

---

## Precisa-runtime

Os seguintes comportamentos NÃO são resolvíveis apenas pelo dump estático:

1. **Ordem exata de abertura dos pickers** quando feature está desabilitada (paywall vs. tela de plano)
2. **Animação e snap** do modal adaptativo em phones vs. tablets (altura exata do bottom-sheet)
3. **Placeholder visual dos TextFields** de addressLine1/addressLine2 no `EditExactLocationAddressFragment` (textos de hint não encontrados em strings.xml)
4. **Comportamento do botão Back** ao sair do editor com alterações não salvas (dialog de descarte ou auto-save)
5. **Ordem dos items no color picker** (circular ou lista?)
6. **Transição ao duplicar parada** (toast + scroll para nova parada ou abre o editor?)
7. **Texto do botão de cancelar** no dialog de remoção (confirm_button_title = "Confirmar" mas o cancel não foi localizado no dump)
8. **Comportamento do barcode scanner** quando offline (string `barcode_manual_input_no_internet_connection` sugere fallback mas fluxo completo não resolvido)
