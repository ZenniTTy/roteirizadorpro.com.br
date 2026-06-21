# Front blueprint — setup

Data: 2026-06-21
Fonte: jadx decompilado de `com.circuit.p016ui.setup` (Spoke v3.65.1, Pairip ofuscado)
Escopo: RouteSetup (Detalhes da rota) + BreakSetup (Configurar pausa) + BreakDurationInputDialog

---

## 1. RouteSetupFragment (tela principal de configuração de rota)

**Propósito:** Modal bottom sheet que configura partida, destino, horários de início/fim e pausa da rota ativa.
**Classe:** `com.circuit.ui.setup.RouteSetupFragment extends AdaptiveModalFragment`
**ViewModel:** `com.circuit.ui.setup.RouteSetupViewModel`
**UI State:** `RouteSetupUiState` (classe ofuscada `lcc`, pacote `p000`)
**Modal size:** `AdaptiveModalSize.Medium` (50 % da tela, expansível)

### 1.1 Estrutura da tela (ordem de renderização, `RouteSetupScreen.kt`)

```
Título: "Detalhes da rota"               ← route_setup_title
────────────────────────────────────────
Seção "Partida"                          ← route_setup_start_title
  • Item: startLocation                  ← RouteSetupItemUiModel (C4073c)
  • Item: startTime                      ← RouteSetupItemUiModel

Seção "Destino"                          ← route_setup_end_title
  • Item: endLocation                    ← RouteSetupItemUiModel
  • Item: endTime                        ← RouteSetupItemUiModel

[Seção "Pausa" — condicional]            ← route_setup_break_title
  • Item: breakInfo                      ← RouteSetupItemUiModel (nullable; oculta se null)

Botão "Concluído"                        ← done (fullWidth, primary)

[Checkbox "Salvar como padrão" — condicional]
  → Visível somente quando saveAsDefaultVisible == true
  → String: "Salvar como padrão"         ← save_as_default_action
```

### 1.2 RouteSetupItemUiModel (`C4073c` / `RouteSetupItemUiModel`)

Cada linha da tela é renderizada por esse modelo:

| Campo      | Tipo        | Descrição |
|------------|-------------|-----------|
| title      | String      | Texto principal da linha |
| subtitle   | String?     | Texto secundário (nullable) |
| showClock  | Boolean     | Mostra relógio animado (para horário não definido) |
| showDelete | Boolean     | Mostra botão X de apagar |
| status     | FeatureStatus | Controla se o campo está habilitado/bloqueado |
| titleTextColor | Int    | Cor do título (primária ou terciária/placeholder) |
| icon       | Drawable   | Ícone à esquerda da linha |
| iconTint   | Int        | Tint do ícone |
| isDisabled | Boolean    | Derivado de `status == LOCKED` (campo não tappável) |

### 1.3 RouteSetupUiState (`lcc`)

| Campo             | Tipo            | Descrição |
|-------------------|-----------------|-----------|
| isLoading         | Boolean         | Carregando dados |
| startLocation     | RouteSetupItemUiModel | Ponto de partida |
| endLocation       | RouteSetupItemUiModel | Destino |
| startTime         | RouteSetupItemUiModel | Horário de saída |
| endTime           | RouteSetupItemUiModel | Horário de término |
| breakInfo         | RouteSetupItemUiModel? | Pausa (null = feature não habilitada ou plano sem breaks) |
| saveAsDefault     | Boolean         | Estado atual do toggle |
| saveAsDefaultVisible | Boolean      | Se o row de "Salvar como padrão" aparece |

### 1.4 Strings PT-BR verbatim

| Chave | Valor |
|-------|-------|
| `route_setup_title` | "Detalhes da rota" |
| `route_setup_start_title` | "Partida" |
| `route_setup_end_title` | "Destino" |
| `route_setup_break_title` | "Pausa" |
| `route_setup_header` | "Configuração de rota" |
| `route_setup_locations_title` | "Onde sua rota começa e termina?" |
| `route_setup_locations_button_title` | "Definir locais" |
| `done` | "Concluído" |
| `save_as_default_action` | "Salvar como padrão" |
| `save_as_default_for_this_address_action` | "Salvar como padrão para este endereço" |
| `use_current_location` | "Usar local atual" |
| `round_trip` | "Ida e volta" |
| `roundtrip_from_x` | "Ida e volta de %1$s" |
| `roundtrip_from_current` | "Viagem de ida e volta a partir do local atual" |
| `start_right_now` | "Iniciar agora mesmo" |
| `set_end_time_placeholder` | "Definir horário de término" |
| `set_break_placeholder` | "Adicionar pausa" |
| `no_end_location_placeholder` | "Nenhum destino" |
| `route_setup_break_option_title` | "Pausa de %1$d min" |
| `route_setup_break_option_subtitle` | "Entre %1$s e %2$s" |
| `start_location_placeholder_title` | "Ponto de partida" |
| `start_location_current_placeholder_title` | "Iniciar no local atual" |
| `start_location_gps_used_subtitle` | "Posição do GPS usada ao otimizar" |
| `start_location_use_gps_subtitle` | "Use a posição do GPS ao otimizar" |
| `end_location_set_subtitle` | "Toque para definir o destino e horário de término" |

### 1.5 Estados das linhas (mapeamento de dados → UI)

**startLocation:**
- Endereço definido: title = endereço, showDelete = true, icon = `start_team`
- Sem endereço: title = "Usar local atual", showDelete = false, icon = `baseline_my_location_24`

**endLocation:**
- roundTrip == true: title = "Ida e volta", subtitle = "Ida e volta de X" (ou "...a partir do local atual"), showDelete = false, icon = `ic_roundtrip`
- Endereço definido: title = endereço, showDelete = true, icon = `ic_end`
- Sem endereço: title = "Nenhum destino", showDelete = false, icon = `ic_end`, cor terciária

**startTime:**
- Sem horário: title = "Iniciar agora mesmo", showClock = true, showDelete = false, icon = `time_window`
- Com horário: title = HH:mm formatado, showClock = false, showDelete = true, icon = `time_window`

**endTime:**
- Sem horário: title = "Definir horário de término", showDelete = false, icon = `time_window`, cor terciária
- Com horário: title = HH:mm formatado, showDelete = true, icon = `time_window`, cor primária

**breakInfo (null se feature Breaks não habilitada):**
- Com pausa configurada: title = "Pausa de N min", subtitle = "Entre HH:mm e HH:mm", showDelete = true, icon = `ic_coffee_fill`
- Sem pausa: title = "Adicionar pausa", showDelete = false, icon = `ic_coffee_fill`, cor terciária

### 1.6 Enums utilizados

**`RouteSetupButtonType`** (enum, 5 valores):
```
START_TIME | START_LOCATION | END_TIME | END_LOCATION | BREAK
```
Passado em `tappedField(type, featureStatus)` ao tocar em qualquer linha.

**`RouteSetupEndOption`** (enum, 3 valores — sheet de Destino):
```
ROUND_TRIP | OTHER_ADDRESS | NO_END_LOCATION
```

**`FeatureStatus`** (controla se campo está tappável):
- `ENABLED` → campo tappável normal
- `LOCKED` → campo desabilitado visualmente (isDisabled = true), tap → `tappedDisabled` (mostra paywall/upsell)

**`AppFeature` relevantes para o setup:**
- `ChangeRouteStartLocation` — controla se partida é editável
- `ChangeRouteEndLocation` — controla se destino é editável
- `ChangeRouteStartTime` — controla se hora de saída é editável
- `ChangeRouteEndTime` — controla se hora de término é editável
- `Breaks` — controla se seção Pausa aparece
- `RouteSetupSaveAsDefault` — controla visibilidade do toggle "Salvar como padrão"

### 1.7 Eventos de UI (`RouteSetupUiEvent` / `AbstractC4074d`)

| Evento | Ação no Fragment |
|--------|-----------------|
| `ShowTimePicker(START)` | Abre `CircuitTimePickerDialog` com título "Definir primeiro horário" |
| `ShowTimePicker(END)` | Abre `CircuitTimePickerDialog` com título "Definir último horário" |
| `ShowAddressPicker(START/END)` | Navega para `AddressPickerFragment` |
| `ShowRouteEndPicker` | Abre bottom sheet com 3 opções de Destino (ver §3) |
| `ShowBreakPicker(breakDefault?)` | Navega para `BreakSetupFragment` (AddBreak ou UpdateBreak) |
| `Close` | Fecha o modal (pop backstack) |

### 1.8 Navegação

- **Quem abre:** Shell da rota ativa (via kebab ou botão de configuração)
- **O que abre:**
  - Tap em startLocation → `AddressPickerFragment` (global result key)
  - Tap em endLocation → Sheet de Destino (§3)
  - Tap em startTime → `CircuitTimePickerDialog`
  - Tap em endTime → `CircuitTimePickerDialog`
  - Tap em breakInfo → `BreakSetupFragment`
- **Back:** `OnBackPressedDispatcher` registrado; fecha o modal

### 1.9 Ícones

| Drawable Spoke | Contexto | Lucide sugerido (RotPro) |
|----------------|----------|--------------------------|
| `start_team` | Partida com endereço definido | `MapPin` |
| `baseline_my_location_24` | Partida = local atual | `Navigation` |
| `ic_roundtrip` | Destino = ida e volta | `RefreshCw` |
| `ic_end` | Destino | `MapPinOff` / `Flag` |
| `time_window` | Horário (início e fim) | `Clock` |
| `ic_coffee_fill` | Pausa | `Coffee` |

### 1.10 Precisa-runtime

- Animação do `showClock` (pulsação/ticker no relógio quando horário não definido)
- Comportamento exato do scroll dentro do modal (snapping vs livre)
- Ordem e estilo exato do header "Detalhes da rota" (se é AppBar ou Text composto)
- Se "Salvar como padrão" aparece em TODOS os planos B2C ou só quando há endereço de partida definido

---

## 2. RouteSetupEndOptionSheet (sheet de seleção de Destino)

**Propósito:** Bottom sheet com 3 opções de destino, aberto ao tocar na linha de Destino.
**Classe:** `zv3` (anônimo dentro de `RouteSetupFragment.onViewCreated`, não tem Fragment dedicado)
**Tipo de componente:** Custom bottom sheet com lista de opções (título + 3 linhas ícone+título+subtítulo)

### 2.1 Estrutura

```
Título: "Destino"                           ← route_setup_end_title

Opção 1: "Voltar ao ponto de partida"       ← end_round_trip_option_title
         "Ida e volta (recomendado)"        ← end_round_trip_option_subtitle
         Ícone: ic_roundtrip

Opção 2: "Destino em outro endereço"        ← end_address_option_title
         "Digite qualquer endereço"         ← end_address_option_subtitle
         Ícone: pin_outline

Opção 3: "Não usar destino"                 ← end_none_option_title
         "Não recomendado para transportadoras" ← end_none_option_subtitle
         Ícone: baseline_close_24
```

### 2.2 Navegação

- Aberto pelo evento `ShowRouteEndPicker` no `RouteSetupFragment`
- Seleção chama `setRouteEndOption(RouteSetupEndOption)` no ViewModel
- Selecionar opção 2 (outro endereço) → abre `AddressPickerFragment`

### 2.3 Strings PT-BR verbatim

| Chave | Valor |
|-------|-------|
| `end_round_trip_option_title` | "Voltar ao ponto de partida" |
| `end_round_trip_option_subtitle` | "Ida e volta (recomendado)" |
| `end_address_option_title` | "Destino em outro endereço" |
| `end_address_option_subtitle` | "Digite qualquer endereço" |
| `end_none_option_title` | "Não usar destino" |
| `end_none_option_subtitle` | "Não recomendado para transportadoras" |

### 2.4 Ícones

| Drawable Spoke | Lucide sugerido (RotPro) |
|----------------|--------------------------|
| `ic_roundtrip` | `RefreshCw` |
| `pin_outline` | `MapPin` |
| `baseline_close_24` | `X` |

### 2.5 Precisa-runtime

- Se a seleção atual fica marcada (checked) ou o sheet apenas apresenta opções sem estado selecionado
- Animação de dismiss após seleção

---

## 3. BreakSetupFragment (tela de configurar pausa)

**Propósito:** Modal bottom sheet para adicionar ou editar uma pausa na rota (horário e duração).
**Classe:** `com.circuit.ui.setup.breaks.BreakSetupFragment extends AdaptiveModalFragment`
**ViewModel:** `com.circuit.ui.setup.breaks.BreakSetupViewModel`
**UI State:** `BreakSetupUiState` (classe ofuscada `pt0`, pacote `p000`)
**Modal size:** `AdaptiveModalSize.Medium`
**Args:** `BreakSetupArgs` — `AddBreak` (singleton) ou `EditBreak(breakId)` ou `UpdateBreak(breakDefault)`

### 3.1 Estrutura da tela (`BreakSetupScreen.kt`)

```
Título: "Configure a pausa"                  ← break_screen_setup_title
Descrição: "Planeje suas pausas no Spoke..."  ← break_screen_description

────────────────────────────────────────
[Divisor horizontal com cor do tema]

Seção "Quando deseja fazer a pausa?"         ← break_screen_time_window_title
  Ícone: clock
  Linha "Entre":                             ← break_screen_time_window_start_title
    [valor do horário de início da janela]
  Linha "E":                                 ← break_screen_time_window_end_title (literalmente "E")
    [valor do horário de fim da janela]

────────────────────────────────────────
Seção "Qual será a duração da pausa?"        ← break_screen_time_duration_title
  Ícone: timer
  Linha "Duração da pausa":                  ← break_screen_duration_setting_title
    [valor em minutos]

────────────────────────────────────────
Botão primário (fullWidth):                  ← pt0.primaryButtonLabel
  → "Adicionar pausa" (AddBreak)             ← break_screen_add_break_button
  → "Concluído" (EditBreak)                  ← done

[Botão "Remover pausa" — condicional]        ← break_screen_remove_button
  → Visível somente no modo edição (pt0.isExistingBreak == true)
  → Cor do tema: destructive
```

### 3.2 BreakSetupUiState (`pt0`)

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `a` (timeWindowStart) | String | Horário de início da janela (formatado HH:mm) |
| `b` (timeWindowEnd) | String | Horário de fim da janela (formatado HH:mm) |
| `c` (duration) | StringHolder | Duração em minutos (como String formatado) |
| `d` (primaryButtonLabel) | StringHolder | Label do botão primário |
| `e` (isExistingBreak) | Boolean | true = modo edição, false = modo adição |

### 3.3 Defaults do BreakSetupViewModel

```kotlin
// Defaults definidos estaticamente no ViewModel:
val DEFAULT_DURATION = Duration.ofMinutes(30)   // 30 minutos
val DEFAULT_TIME_WINDOW_START = LocalTime.of(8, 0)   // 08:00
val DEFAULT_TIME_WINDOW_END = LocalTime.of(15, 0)    // 15:00
```
Esses valores são aplicados quando `BreakSetupArgs == AddBreak` (nova pausa).
Na edição (`EditBreak` / `UpdateBreak`), os valores carregados do `BreakDefault` existente.

### 3.4 Strings PT-BR verbatim

| Chave | Valor |
|-------|-------|
| `break_screen_setup_title` | "Configure a pausa" |
| `break_screen_description` | "Planeje suas pausas no Spoke para ter estimativas mais precisas de paradas e duração da rota." |
| `break_screen_time_window_title` | "Quando deseja fazer a pausa?" |
| `break_screen_time_window_start_title` | "Entre" |
| `break_screen_time_window_end_title` | "E" |
| `break_screen_time_duration_title` | "Qual será a duração da pausa?" |
| `break_screen_duration_setting_title` | "Duração da pausa" |
| `break_screen_add_break_button` | "Adicionar pausa" |
| `break_screen_remove_button` | "Remover pausa" |
| `edit_stop_set_earliest_time_title` | "Definir primeiro horário" |
| `edit_stop_set_latest_time_title` | "Definir último horário" |

### 3.5 Resultado retornado (`BreakSetupResult`)

Sealed class com 2 casos:
- `BreakChanged(duration: Duration, timeWindowEarliest: LocalTime, timeWindowLatest: LocalTime)` — pausa salva/editada
- `BreakRemoved` — pausa removida (botão "Remover pausa")

O resultado é propagado via `FragmentManager.setFragmentResult("break_setup_result", bundle)`, recebido pelo `RouteSetupFragment` que atualiza o ViewModel.

### 3.6 Navegação

- **Quem abre:** `RouteSetupFragment` ao evento `ShowBreakPicker`
- **O que abre:**
  - Tap em "Entre" → `CircuitTimePickerDialog` com título "Definir primeiro horário"
  - Tap em "E" → `CircuitTimePickerDialog` com título "Definir primeiro horário" [mesma string]
  - Tap em "Duração da pausa" → `BreakDurationInputDialog` (§4)
- **Back:** `popOrFinish` (pop ou finaliza o Fragment)
- **Resultado:** `setFragmentResult("break_setup_result")` → `RouteSetupFragment` recebe e processa

### 3.7 Ícones

| Drawable Spoke | Contexto | Lucide sugerido (RotPro) |
|----------------|----------|--------------------------|
| `clock` | Seção de janela de horário | `Clock` |
| `timer` | Seção de duração | `Timer` |

### 3.8 Precisa-runtime

- Se as linhas "Entre" / "E" são tappáveis por linha inteira ou apenas pelo valor formatado
- Layout exato das linhas de horário (Row ou ListTile, alinhamento do label + valor)
- Se botão "Remover pausa" tem confirmação adicional (diálogo) ou remove diretamente
- Se o CircuitTimePickerDialog é clock picker (analógico) ou numpad — ver ADR-0042 (resultado: numpad)

---

## 4. BreakDurationInputDialog (diálogo de duração da pausa)

**Propósito:** Diálogo modal para inserir a duração da pausa em minutos (campo numérico livre).
**Classe:** `com.circuit.ui.setup.breaks.BreakDurationInputDialog extends AdaptiveModalDialog`
**Modal size:** `AdaptiveModalSize.Small`

### 4.1 Estrutura

```
Título: "Duração da pausa (minutos)"        ← break_duration_dialog_title
[Campo de texto numérico]                    ← valor atual em minutos (String)
[Botão confirmar / Dismiss]
```

### 4.2 Comportamento

- Recebe o valor atual de minutos como String (ex: "30")
- Ao confirmar, chama `onDurationClicked(minutes: Int)` no `BreakSetupViewModel`
- Campo de entrada é numérico livre (sem chips ou pré-definidos)
- Dismiss fecha o diálogo sem salvar

### 4.3 Strings PT-BR verbatim

| Chave | Valor |
|-------|-------|
| `break_duration_dialog_title` | "Duração da pausa (minutos)" |

### 4.4 Precisa-runtime

- Se há botões "Cancelar" / "Confirmar" explícitos ou apenas dismiss via toque fora
- Validação de valor mínimo/máximo (ex: 1–999 minutos)
- Se o campo exibe teclado numérico automaticamente ao abrir

---

## 5. Diálogos de pausa pulada (contextuais, não da área de setup mas referenciados)

Estes diálogos aparecem APÓS otimização, não dentro do RouteSetup. Registrados aqui para não criar blueprint separado.

### 5.1 Strings PT-BR verbatim

| Chave | Valor |
|-------|-------|
| `break_skipped_dialog_title` | "Pausa não adicionada" |
| `break_skipped_dialog_explainer_before_start` | "A pausa está agendada para antes do início da rota. Defina um horário depois de %s ou inclua-a antes da primeira parada." |
| `break_skipped_dialog_explainer_after_end` | "A pausa está agendada para após o fim da rota. Defina um horário antes de %s ou inclua-a depois da última parada." |
| `break_skipped_dialog_explainer_conflict` | "A pausa coincide com algumas paradas. Defina uma janela de tempo diferente para incluí-la na rota." |
| `break_skipped_dialog_not_required_include_button` | "Incluir pausa" |

---

## 6. Resumo dos AppFeatures que gate o setup

| AppFeature | Impacto no Setup |
|------------|-----------------|
| `ChangeRouteStartLocation` | Linha de partida editável vs. LOCKED |
| `ChangeRouteEndLocation` | Linha de destino editável vs. LOCKED |
| `ChangeRouteStartTime` | Linha de hora de saída editável vs. LOCKED |
| `ChangeRouteEndTime` | Linha de hora de término editável vs. LOCKED |
| `Breaks` | Seção Pausa visível (breakInfo != null) vs. oculta |
| `RouteSetupSaveAsDefault` | Row "Salvar como padrão" visível vs. oculto |

**Nota B2C:** Todos esses features são verificados contra o plano do usuário via `C2847b.m8631b(AppFeature)`. No B2C free, `ChangeRouteStartTime` e `ChangeRouteEndTime` retornam `LOCKED` (campo aparece mas é não-tappável). No plano pago, todos retornam `ENABLED`.

[B2B — cortar]: `RouteSetupArgs.EditBreak` com `BreakId` referencia edição por ID de pausa persistida no backend — funcionalidade de Dispatch. No RotPro, pausa é sempre configurada como `BreakDefault` (sem ID de entidade persistida), equivalente ao `AddBreak`/`UpdateBreak`.

---

## 7. Fluxo completo de navegação

```
Shell (rota ativa)
  └─► RouteSetupFragment (Modal Medium)
        ├─► AddressPickerFragment [partida/destino]
        │     └─► (result AddressPickerResult.Key.Global → RouteSetupViewModel.setAddressChosen)
        ├─► RouteSetupEndOptionSheet [destino]
        │     ├─► ROUND_TRIP → atualiza ViewModel direto
        │     ├─► OTHER_ADDRESS → AddressPickerFragment
        │     └─► NO_END_LOCATION → atualiza ViewModel direto
        ├─► CircuitTimePickerDialog [hora de saída]
        │     └─► (numpad — ADR-0042)
        ├─► CircuitTimePickerDialog [hora de término]
        │     └─► (numpad — ADR-0042)
        └─► BreakSetupFragment (Modal Medium)
              ├─► CircuitTimePickerDialog [janela início]
              ├─► CircuitTimePickerDialog [janela fim]
              └─► BreakDurationInputDialog (Modal Small)
                    └─► (número livre de minutos)
```
