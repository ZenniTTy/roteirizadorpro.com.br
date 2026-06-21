# Front blueprint — loading

Data: 2026-06-21
Fonte: `jadx-out/sources/com/circuit/p016ui/loading/` + `values-pt-rBR/strings.xml` + `values-pt-rBR/plurals.xml`
Package canônico: `com.circuit.ui.loading`
Classes principais: `LoadVehicleFragment`, `LoadVehicleViewModel`, `LoadVehicleScreenKt` (ofuscado como `C3776e`), `LoadVehicleEmptySheets` (ofuscado como `wc9`)

---

## Visão geral da área

A área "loading" abrange um único fluxo: **Carregar veículo** — o processo pelo qual o entregador carrega fisicamente os pacotes no veículo, organizando-os em ordem reversa de entrega. É acionada antes do início da rota, a partir do botão "Carregar veículo" na tela de rota. Contém:

1. **Tela principal Carregar Veículo** (`LoadVehicleFragment`) — tela de tela inteira com duas abas.
2. **Diálogo "Tudo pronto para carregar?"** — gate de entrada que aparece antes de abrir a tela.
3. **Diálogo "Carregamento pendente"** — mostrado quando o usuário tenta iniciar a rota sem ter carregado.
4. **Notificação de carregamento** — canal de notificação de sistema (canal, não tela).

Funcionalidades de câmera/leitor de código de barras para carregar o veículo existem no package `com.circuit.ui.scanner` (não neste package) — ver blueprint `scanner.md`.

---

## 1. Diálogo "Tudo pronto para carregar o veículo?"

**Propósito:** Gate de confirmação exibido antes de abrir a tela de carregar veículo. O usuário confirma que está no depósito e pronto para carregar.

**Estrutura:**
- Título: `"Tudo pronto para carregar o veículo?"`
- Corpo: `"O Spoke ajuda você a carregar o veículo para que os pacotes fiquem organizados por ordem de entrega"`
- Botão primário: `"Carregar veículo"` → abre `LoadVehicleFragment`
- Sem botão de cancelar explícito (dismiss por tap fora ou voltar)

**Strings PT-BR verbatim:**
- `load_vehicle_dialog_title` = `"Tudo pronto para carregar o veículo?"`
- `load_vehicle_dialog_body` = `"O Spoke ajuda você a carregar o veículo para que os pacotes fiquem organizados por ordem de entrega"`
- `load_vehicle_button_title` = `"Carregar veículo"`

**Navegação:** tap em "Carregar veículo" → `LoadVehicleFragment` (Fragment com `postponeEnterTransition` + animação de entrada/saída via `Fade`).

**Estados/defaults:** Sempre aparece como diálogo modal. Sem estados internos.

**Ícones:** `ic_barcode` (drawable vector 24×24dp, estilo linha — ícone de código de barras) aparece na barra de ações associada ao fluxo de carregar veículo em outras superfícies; `vehicle_outline` (drawable vector 24×24dp — silhueta de veículo furgão) também é usado em botões associados. Nenhum dos dois está confirmado dentro do diálogo em si (Precisa-runtime para confirmar ícone no diálogo).

**Precisa-runtime:** Confirmar se o diálogo usa ícone de ilustração ou é puramente texto.

---

## 2. Diálogo "Carregamento pendente"

**Propósito:** Alerta exibido quando o entregador tenta iniciar a rota sem ter completado o carregamento do veículo.

**Estrutura:**
- Título: `"Carregamento pendente"`
- Corpo: `"Você precisa carregar o veículo no depósito antes de iniciar as entregas."`
- Botão primário: `"Verificar depósito"` → navega de volta para `LoadVehicleFragment`
- Sem botão de cancelar (Precisa-runtime: confirmar se há dismiss implícito)

**Strings PT-BR verbatim:**
- `loading_pending_dialog_title` = `"Carregamento pendente"`
- `loading_pending_dialog_body` = `"Você precisa carregar o veículo no depósito antes de iniciar as entregas."`
- `loading_pending_dialog_button` = `"Verificar depósito"`

**Navegação:** Botão "Verificar depósito" → abre/reexibe `LoadVehicleFragment`.

**Estados/defaults:** Disparado a partir do estado da rota quando `loadVehicleStatus = FeatureStatus.Enabled` mas carregamento ainda não foi concluído.

**Ícones:** Nenhum confirmado no diálogo (Precisa-runtime).

**Precisa-runtime:** Confirmar se há botão "Cancelar"/"Ignorar" ou apenas o botão primário.

---

## 3. Tela Carregar Veículo (`LoadVehicleFragment` / `LoadVehicleScreen`)

**Propósito:** Tela de tela inteira (Fragment Compose) que guia o entregador no processo de carregar o veículo. Divide o trabalho em duas abas: (1) identificação de paradas por ID e (2) lugar no veículo por parada.

**Classe:** `com.circuit.ui.loading.LoadVehicleFragment` + composable raiz `LoadVehicleScreen` (em `LoadVehicleScreenKt` / `C3776e`)

**Args:** `LoadVehicleArgs(pickupStopId: DefaultStopId?)` — quando `pickupStopId != null`, a tela abre com foco naquela parada de coleta específica; quando `null`, mostra todas as paradas da rota ativa.

### 3.1 Estrutura geral da tela

```
LoadVehicleScreen
├── [Aviso de coletas ocultas] (condicional — visível quando há coletas na lista)
│     "As coletas estão ocultas na lista"  [ícone info_outline]
│
├── TabRow — 2 abas
│     Aba 0: "ID de parada"            (Tabs.StopId)
│     Aba 1: "Lugar no veículo"        (Tabs.PlaceInVehicle)
│
├── HorizontalPager — conteúdo das abas (trocado via onTabChanged)
│     Página 0: StopIdTab  (m9803i)
│     Página 1: PlaceInVehicleTab  (m9802h)
│
└── BottomSheet animado — varia por LoadVehicleSheetType (ver §3.3)
```

### 3.2 Aba 0 — "ID de parada" (StopId)

**Composable:** `m9803i(pd9, onStopIdStopClick, ...)`

**Modelo de dados:** `LoadVehicleStopIdsTabUiModel` (`pd9`) — lista de `items: List<vec>` onde cada item é uma linha de parada com seu ID de parada.

**Estrutura:**
- Lista `LazyColumn` de paradas, cada uma exibindo:
  - Número de ordem na rota
  - ID de parada (formato "moderno" ou "clássico" conforme configuração global de Stop IDs)
  - Nome/endereço da parada
  - Botão de interação por parada: `"Carregar %1$d"` (onde `%1$d` é o número de ordem)

**Strings PT-BR verbatim:**
- `package_identification_feature_title` = `"ID de parada"` (label da aba)
- `load_vehicle_stop_load_x` = `"Carregar %1$d"` (botão por linha, onde %1$d = número da parada)
- `skipped_stops` = `"Paradas puladas"` (cabeçalho de seção para paradas puladas)

**Ícones:** Nenhum ícone específico de aba confirmado (Precisa-runtime).

**Navegação:** Tap em parada → `onStopIdStopClick(RouteStepListKey)` → atualiza estado no ViewModel.

### 3.3 Aba 1 — "Lugar no veículo" (PlaceInVehicle)

**Composable:** `m9802h(xc9, onPlaceInVehicleStopClick, onSaveClick, onPlaceInVehicleClick, onTabChanged, onDeselectClick, onClearClick, onNavigateUp, ...)`

**Modelo de dados:** `LoadVehicleLoadVehicleTabUiModel` (`xc9`) com campos:
- `items: List<vec>` — lista de paradas (grupos por lote)
- `placeInVehicle: PlaceInVehicle` — lugar atualmente selecionado
- `isPlaceInVehicleInClearMode: Boolean` — se o seletor de lugar está em modo "remover"
- `selectedCount: Int` — quantas paradas estão selecionadas
- `loadedCount: Int` — quantas paradas já foram carregadas
- `scrollTo: qm4<BaseStopId<?>>` — scroll programático para parada específica
- `sheetType: LoadVehicleSheetType` — estado atual do sheet inferior
- `showCompletedDoneButton: Boolean` — se mostra botão "concluído" no estado Completed
- `totalCount: Int` (derivado) — número de grupos de carregamento = `items.count { it is C2676g }`

**Estrutura:**
```
PlaceInVehicleTab
├── PlaceInVehicleStopList (LazyColumn das paradas, m9801g)
│     Cada linha: parada com checkbox de seleção, nome, número
│     Seção "Paradas puladas" se houver
│
└── BottomSheet animado (transição por LoadVehicleSheetType, m9795a)
      Estado NoneSelected  → EmptySheet (m9880c)
      Estado SelectingStops → PlaceInVehicleSelector (m9799e)
      Estado PartiallyLoaded → ProgressSheet (m9881d)
      Estado Completed     → CompletedSheet (m9879b)
```

### 3.4 BottomSheet — 4 estados via `LoadVehicleSheetType`

#### Estado 0: `NoneSelected` — Sheet vazio

**Composable:** `wc9.m45880c`

**Estrutura:**
```
Column (centralizado, padding 32dp topo)
├── Imagem: il_place_in_vehicle_loading (230dp largura, ilustração vetorial de veículo + pacotes)
├── Espaço 32dp
├── Título: "Nenhuma parada selecionada"
└── Subtítulo: "Selecione uma ou mais paradas para definir um lugar no veículo"
```

**Strings PT-BR verbatim:**
- `loading_vehicle_empty_title` = `"Nenhuma parada selecionada"`
- `loading_vehicle_empty_subtitle` = `"Selecione uma ou mais paradas para definir um lugar no veículo"`

**Ícones/Ilustrações:** `il_place_in_vehicle_loading` (vector drawable 200×107.7dp, ilustração de caixas num veículo com código de barras).

---

#### Estado 1: `SelectingStops` — Seletor de lugar no veículo

**Composable:** `C3776e.m9799e(placeInVehicle, isInClearMode, onSaveClick, onClearClick, onDeselectClick, ...)`

**Sub-composables:**
- `m9798d` — botão "Desmarcar" + count de selecionados
- `m9800f` — grade de seleção PlaceInVehicle (eixos X/Y/Z)
- `m9801g` (bottom action) — botão "Definir lugar" ou "Remover lugar"

**Estrutura:**
```
Column
├── Row de ação superior (m9798d)
│     "Desmarcar" (botão texto)    [conta: N selecionadas, formatado como "N de N"]
│
├── Grade PlaceInVehicle (m9800f)
│     Eixo Y (frente-trás, 3 colunas): Frente | Meio | Atrás
│     Eixo X (esquerda-direita, filtrado por Y): Esquerda | (Direita — quando aplicável)
│     Eixo Z (chão-prateleira): Chão | Prateleira
│
└── Botão primário:
│     Modo normal: "Definir lugar" → onSaveClick
│     Modo clear:  "Remover lugar" → onSaveClick
│
└── Botão secundário: "Limpar" → onClearClick (desfaz seleção de lugar)
```

**Strings PT-BR verbatim:**
- `deselect` = `"Desmarcar"`
- `set_place_in_vehicle_button` = `"Definir lugar"`
- `remove_place` = `"Remover lugar"`
- `clear_button_title` = `"Limpar"`

**PlaceInVehicle — modelo 3D (enums):**

Eixo X (`PlaceInVehicle.X`):
- `LEFT` → `"Esquerda"` / abrev `"E"`
- `RIGHT` → `"Direta"` / abrev `"D"`

Eixo Y (`PlaceInVehicle.Y`):
- `FRONT` → `"Frente"` / abrev `"F"`
- `MIDDLE` → `"Meio"` / abrev `"M"`
- `BACK` → `"Atrás"` / abrev `"A"`

Eixo Z (`PlaceInVehicle.Z`):
- `FLOOR` → `"Chão"` / abrev `"C"`
- `SHELF` → `"Prateleira"` / abrev `"P"`

Estado especial não-definido: `PlaceInVehicle(null, null, null)` → `"Não definido"`

Strings completas PT-BR verbatim:
- `place_in_vehicle` = `"Lugar no veículo"`
- `place_in_vehicle_back` = `"Atrás"` / `place_in_vehicle_back_short` = `"A"`
- `place_in_vehicle_floor` = `"Chão"` / `place_in_vehicle_floor_short` = `"C"`
- `place_in_vehicle_front` = `"Frente"` / `place_in_vehicle_front_short` = `"F"`
- `place_in_vehicle_left` = `"Esquerda"` / `place_in_vehicle_left_short` = `"E"`
- `place_in_vehicle_middle` = `"Meio"` / `place_in_vehicle_middle_short` = `"M"`
- `place_in_vehicle_not_set` = `"Não definido"`
- `place_in_vehicle_right` = `"Direta"` / `place_in_vehicle_right_short` = `"D"`
- `place_in_vehicle_shelf` = `"Prateleira"` / `place_in_vehicle_shelf_short` = `"P"`

**Precisa-runtime:** Layout exato da grade (linear ou grid 3D); como X/Y/Z são apresentados conjuntamente (seletores independentes, combinados, ou sequencial).

---

#### Estado 2: `PartiallyLoaded` — Progresso

**Composable:** `wc9.m45881d(selectedCount, totalCount, progress, ...)`

**Estrutura:**
```
Column (padding 32dp topo)
├── ProgressIndicator circular animado (m9882e) — progresso normalizado (selectedCount/totalCount)
├── Espaço 24dp
├── Título plural: "%1$d de %2$d parada(s) carregada(s)"
└── Subtítulo: "Selecione uma ou mais paradas para definir um lugar no veículo"
```

**Strings PT-BR verbatim (plural):**
- `loading_vehicle_loaded_title` (plural):
  - `one`: `"%1$d de %2$d parada carregada"`
  - `other`: `"%1$d de %2$d parada(s) carregada(s)"`
- `loading_vehicle_empty_subtitle` = `"Selecione uma ou mais paradas para definir um lugar no veículo"` (reutilizado como subtítulo)

**Animação:** `progress` é um valor Float animado (`AnimateAsState`) — anima suavemente de 0→1 conforme paradas são marcadas como carregadas.

---

#### Estado 3: `Completed` — Concluído

**Composable:** `wc9.m45879b(selectedCount, onCompleteClick, showDoneButton, ...)`

**Estrutura:**
```
Column (padding 32dp topo)
├── Ícone de check animado (m9878a): load_vehicle_check (48dp, círculo com check)
│     Animação: ícone encolhe de 48→36dp conforme completado; stroke desaparece
├── Espaço 24dp
├── Título: "Todas as paradas foram carregadas"
├── Subtítulo: "Você está pronto para começar a rota"
├── Espaço 24dp
└── [Botão "Concluído"] — AnimatedVisibility, aparece com delay 300ms
      Visível apenas quando showCompletedDoneButton = true
      Tap → onSaveClick → popOrFinish (fecha Fragment)
```

**Strings PT-BR verbatim:**
- `loading_vehicle_completed_title` = `"Todas as paradas foram carregadas"`
- `loading_vehicle_completed_subtitle` = `"Você está pronto para começar a rota"`

**Ícones:**
- `load_vehicle_check` (vector 49×48dp, círculo com checkmark, usa `?attr/bgSuccessSubdued` como cor do círculo) — o ícone de check aplica animação de transição de tamanho (48→36dp) e fade do stroke.

**Comportamento do delay:** `moveToCompletedSheet()` aguarda 300ms (via `delay(300L)`) antes de setar `showCompletedDoneButton = true` — o botão "Concluído" aparece com atraso proposital.

---

### 3.5 Aviso de coletas ocultas

**Condicional:** visível quando `qd9.showPickupWarning = true` (há coletas na rota).

**Estrutura:**
```
Row (padding horizontal 8dp)
├── Ícone: info_outline (24×24dp, vector linha)
└── Texto: "As coletas estão ocultas na lista"
```

**Strings PT-BR verbatim:**
- `loading_vehicle_pickup_warning` = `"As coletas estão ocultas na lista"`

**Ícones:** `info_outline` (vector drawable 24dp, ícone de informação — "i" em círculo, estilo outline).

---

### 3.6 Barra de progresso horizontal (método `m9806l`)

Exibida acima da lista de paradas quando `loadedCount > 0`. Mostra progresso visual do carregamento como barra horizontal colorida proporcional a `loadedCount / totalCount`.

---

## 4. ViewModel — `LoadVehicleViewModel`

**Estado reativo:** `StateFlow<LoadVehicleUiModel>` (`qd9`) composto por:
- `loadVehicleTab: LoadVehicleLoadVehicleTabUiModel` (`xc9`) — estado da aba "Lugar no veículo"
- `stopIds: LoadVehicleStopIdsTabUiModel` (`pd9`) — estado da aba "ID de parada"
- `showPickupWarning: Boolean` — se há coletas ocultas na lista

**Ações públicas:**
- `onPlaceInVehicleStopClick(RouteStepListKey)` — seleciona/deseleciona parada na lista
- `onStopIdStopClick(RouteStepListKey)` — marca parada como carregada na aba StopId
- `onSaveClick()` → chama `savePlaceInVehicle()` — persiste o PlaceInVehicle selecionado para as paradas selecionadas
- `onClearClick()` — limpa a seleção de PlaceInVehicle sem salvar
- `onPlaceInVehicleClick(PlaceInVehicle)` — seleciona um lugar na grade 3D
- `onTabChanged(Boolean)` — alterna entre abas
- `onDeselectClick()` — deseleciona todas as paradas selecionadas na lista

**Back-press:** Quando o ViewModel tem `r1` (lista de selecionados) não vazia, o botão voltar limpa a seleção e reseta `t1 = false` em vez de fechar a tela. Quando `r1` está vazio, o voltar fecha o Fragment (`popOrFinish`).

**Dados iniciais:** `GetActiveRouteSnapshot` (use case) carrega o snapshot da rota ativa no `init`. Rota é agrupada em lotes ordenados via `KitStopActivity` + `C3066a` (algoritmo de agrupamento por veículo).

---

## 5. Enums e estados

### `LoadVehicleSheetType` (4 valores)
```
NoneSelected    — nenhuma parada selecionada (estado inicial)
SelectingStops  — 1+ paradas selecionadas, aguardando definição de lugar
PartiallyLoaded — progresso: algum(as) paradas carregadas, não todas
Completed       — todas as paradas carregadas
```

### `FeatureStatus` — controla visibilidade do recurso no shell
```
Enabled         — recurso disponível para o usuário (mostra botão "Carregar veículo")
TeamRestriction — restrito por regra de equipe [B2B — cortar]
PlanRestriction — restrito por plano [B2B — cortar: disponível em planos pagos Spoke]
```

> Nota B2C: `TeamRestriction` e `PlanRestriction` existem mas são contexto de equipe (B2B Dispatch). No clone B2C, o recurso Carregar Veículo está sempre habilitado (equivale a `Enabled` fixo).

### Tabs (2 valores, enum interno de `LoadVehicleScreen`)
```
StopId         (índice 0) → label: "ID de parada"
PlaceInVehicle (índice 1) → label: "Lugar no veículo"
```

---

## 6. Navegação

| De | Ação | Para |
|---|---|---|
| Shell da rota (detalhe) | Botão `"Carregar veículo"` | Diálogo de confirmação |
| Diálogo de confirmação | Tap `"Carregar veículo"` | `LoadVehicleFragment` |
| Qualquer lugar da rota | Rota inicializada sem carregar | Diálogo `"Carregamento pendente"` |
| Diálogo pendente | Tap `"Verificar depósito"` | `LoadVehicleFragment` |
| `LoadVehicleFragment` (Completed) | Tap `"Concluído"` | popOrFinish (volta ao shell) |
| `LoadVehicleFragment` | Back (lista vazia) | popOrFinish |
| `LoadVehicleFragment` | Back (com seleção ativa) | limpa seleção (permanece na tela) |

Também há um ponto de entrada via **notificação de sistema** (`notification_channel_loading_title` = `"Carregando"`) — a notificação tem título `"Como navegar com o Spoke"` e mensagem `"Como obter informações da rota"`, servindo como link para a tela de carregamento em contexto de background.

---

## 7. Ícones — mapeamento drawable → Lucide

| drawable | Tipo | Propósito | Lucide equivalente |
|---|---|---|---|
| `ic_barcode` | vector 24dp linha | Scanner de código de barras | `ScanBarcode` |
| `vehicle_outline` | vector 24dp linha | Silhueta de veículo/furgão | `Truck` |
| `load_vehicle_check` | vector 48dp círculo+check | Conclusão do carregamento | `CircleCheck` (com círculo explícito) |
| `il_place_in_vehicle_loading` | vector 200dp ilustração | Estado vazio da aba de lugar no veículo | Sem equivalente Lucide — ilustração customizada (caixas + barras em veículo) |
| `info_outline` | vector 24dp linha | Info sobre coletas ocultas | `Info` |

---

## 8. Precisa-runtime (resumo)

| Item | Por quê |
|---|---|
| Layout exato da grade PlaceInVehicle (X/Y/Z) | Os 3 eixos têm 2+3+2 valores — não está claro se são apresentados em 3 seletores horizontais independentes ou como uma grade 2D+extra |
| Ícone/ilustração no diálogo de confirmação | Diálogo `load_vehicle_dialog` — código decompilado não mostra drawable; pode ter ilustração ou só texto |
| Botão cancelar no diálogo "Carregamento pendente" | Só confirmado o botão "Verificar depósito"; cancelar implícito não confirmado |
| Animação exata do `load_vehicle_check` | O círculo tem animação de shrink (48→36dp) + stroke fade — comportamento visual precisa de screenshot |
| Comportamento do TabRow na mudança de aba | Se usa `HorizontalPager` com scroll horizontal ou `AnimatedContent` com fade |
