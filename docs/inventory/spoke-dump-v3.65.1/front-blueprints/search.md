# Front blueprint — search

Data: 2026-06-21
Fonte: `com.circuit.p016ui.search` + `values-pt-rBR/strings.xml`
Escopo: tela de busca/autocomplete de endereço para adicionar ou editar parada.

---

## 1. SearchScreen (tela principal de busca)

**Nome:** SearchScreen / HeadlessSearchScreen
**Propósito:** Tela full-screen de busca de endereço para adicionar parada à rota ativa.
**Classe:** `SearchScreenKt` (Composable Kotlin); ViewModel: `SearchViewModel`.

### 1.1 Estrutura (ordem de cima para baixo)

```
Column(fillMaxSize)
  ├── SearchBar                    ← campo de texto + ícones de ação
  ├── [corpo central — switch de step]
  │   ├── WaitingForQuery          ← estado inicial (sem query)
  │   ├── Loading (skeletons)      ← aguardando resposta da API
  │   ├── Results                  ← lista de resultados
  │   └── NoResults                ← sem resultado
  └── Footer (attributions)        ← "powered by Google & GraphHopper API"
```

### 1.2 SearchBar

Barra de busca no topo da tela.

**Campos/controles (da esquerda para a direita):**
- Ícone de localização/pin (drawable `ic_autocomplete`, 24 dp) — à esquerda do campo de texto.
- Campo de texto (`TextFieldValue`) — texto da query; suporta destaque de substring (span colorido no texto digitado).
- Ícones de ação (trailing) — condicionais por `SearchBarEndIcon`:

| `SearchBarEndIcon` | Ícone exibido | Condição |
|---|---|---|
| `Default` | ícone de câmera/scanner + ícone de lupa (clear) | estado normal |
| `MicrophoneDefault` | microfone (sem lupa) | voz ativa (idle) |
| `MicrophoneHighlighted` | microfone destacado | gravando |
| `LabelScanner` | scanner (sem lupa) | scanner de etiqueta ativo |
| `None` | nenhum | picker mode |

**Placeholders dinâmicos** (`SearchBarPlaceholder`, muda conforme estado da rota):

| Enum | Focused | Unfocused | Quando |
|---|---|---|---|
| `FindStops` | `"Encontrar paradas"` | `"Encontrar paradas"` | sem permissão para adicionar |
| `NoStops` | `"Digite para adicionar"` | `"Toque para adicionar"` | rota vazia (0 paradas) |
| `FewStops` | `"Digite para adicionar"` | `"Toque para adicionar"` | 1–5 paradas |
| `ManyStops` | `"Adicione ou busque"` | `"Adicione ou busque"` | 6+ paradas |
| `EditAddress` | `"Insira um endereço"` | `"Insira um endereço"` | modo picker (editar endereço) |
| `VoiceInputOn` | `"Entrada por voz ativada"` | `"Entrada por voz ativada"` | entrada por voz ativa |

**Threshold de placeholder:** 0 paradas = NoStops; 1–5 = FewStops; ≥ 6 = ManyStops (lógica em `m10001X`).

### 1.3 Botões de ação (abaixo da SearchBar)

Fila horizontal de botões de modo alternativo de entrada, visíveis quando o campo está vazio ou tem foco (condicionais por `FeatureStatus`):

| Drawable | String key | String PT-BR | `FeatureStatus` |
|---|---|---|---|
| `map_outline` (só se não-picker) | `map` | `"Mapa"` | `selectExactLocationFeatureStatus` |
| `ic_scan_24` | `search_button_scan` | `"Leitor"` | `scanFeatureStatus` |
| `mic_outline` | `search_button_voice` | `"Voz"` | `speechInputFeatureStatus` |

Cada botão tem comportamento de enabled/disabled via `FeatureStatus`.

Botão adicional quando scanNext ativo:
- `search_button_scan_next` → `"Ler o próximo"` (aparece após adicionar parada com scanner; oculta o teclado automaticamente quando ativo).

### 1.4 Estados do corpo (SearchStep / `AbstractC3986f`)

#### Estado A — WaitingForQuery (`AbstractC3986f.b.e`)

Exibido quando a query está vazia. Mostra mensagem central.

**Mensagem central** (`WaitingForQueryMessage`, enum):

| Enum | String key | String PT-BR | Quando |
|---|---|---|---|
| `SearchFindStops` | `search_emptystate_cant_add_stop` | `"Encontrar paradas nesta rota"` | sem permissão de adicionar |
| `SearchNoStops` | `search_emptystate_nostops` | `"Pesquise um endereço para adicionar a primeira parada"` | rota vazia |
| `SearchEmptyRoute` | `search_empty_state_text` | `"Adicione as primeiras paradas para começar a criar sua rota"` | rota sem paradas (B) |
| `SearchManyStops` | `search_emptystate_morestops` | `"Adicione novas paradas ou encontre paradas na rota"` | rota com muitas paradas |
| `Update` | `search_update_empty_state` | `"Digite o novo endereço para esta parada"` | modo picker (editar parada) |

Também pode exibir link "Escolher no mapa" (`search_list_choose_on_map` → `"Escolher no mapa"`) se `showMapOption = true` e o step for WaitingForQuery com a opção habilitada.

#### Estado B — Loading (skeletons)

3 linhas de skeleton animado (placeholder visual) enquanto a busca retorna. Não exibe texto.

#### Estado C — Results (`AbstractC3986f.b.d`)

Lista de resultados. Estrutura da lista:

1. **Seção "Desta rota"** (se `matchingStops` não vazio):
   - Header: `search_list_from_this_route` → `"Desta rota (%1$d)"` (contagem entre parênteses).
   - Cada item: componente `RouteStepListItem` (mesmo widget do shell de rota — tap navega para edição da parada existente, não adiciona nova).

2. **Seção de sugestões de autocomplete** (se `suggestions` não vazio):
   - Header determinado por `SearchSuggestionHeader`:
     - `AddNewStop` → sem header visível (adição normal).
     - `UpdateHeader` → sem header (modo picker de endereço).
   - Cada item de sugestão (`qpc`): ícone + nome de endereço + subtítulo de cidade/bairro.
     - Ícone: `SearchSuggestionIcon.Add` → drawable `pin_squared_plus` (modo addStop).
     - Ícone: `SearchSuggestionIcon.Update` → drawable `pin_squared` (modo picker).
   - Tap na sugestão → chama `addStop`.

3. **Sugestões de autocomplete Google Places** (`autocompleteSuggestions`, lista de `loc`):
   - Cada item `loc` tem: ícone de pin local + texto de endereço + distância estimada.
   - Renderizados como linhas de lista abaixo das sugestões da rota.

4. **Linha fixa no final da lista (se Results):**
   - `search_list_add_new_stop` → `"Adicionar nova parada"` — aparece no final da lista como item clicável.
   - `search_list_choose_on_map` → `"Escolher no mapa"` — item com drawable `map` + chevron direito; ícone 24 dp.

5. **Botão de pesquisa expandida** (condicional):
   - Aparece quando `showExtendedSearchOption = true` e `addStopEnabled = true`.
   - String com HTML bold: `deep_search_button` → `"Veja resultados da <b>pesquisa expandida</b>"`.
   - Ícone: `ic_search_24` (24 dp).
   - Tap → dispara `performExtendedSearch` (chama API diferente, 800 ms de delay antes de mostrar loading).

6. **Banner offline** (se `showIsOfflineBanner = true`):
   - `no_internet_connection_error_message` → `"Verifique seus dados móveis ou Wi-Fi."`.

#### Estado D — NoResults (`AbstractC3986f.b.c`)

Exibido quando a busca retornou, mas sem correspondências.

Estrutura:
```
Column
  ├── Título: search_no_results_title → "Nenhum resultado encontrado"
  ├── [se addStopEnabled]:
  │   └── Subtítulo: search_no_results_subtitle → "Tente reformular a pesquisa"
  ├── [se NOT addStopEnabled]:
  │   └── Subtítulo: search_no_results_cant_add_stop_subtitle → "O despachante não permite adicionar paradas"
  ├── [se addStopEnabled AND showExtendedSearchOption]:
  │   └── Botão pesquisa expandida (mesmo do Results §5 acima)
  └── [se showMapOption]:
      └── "Escolher no mapa" (mesmo item do Results §4 acima)
```

#### Estado E — Loading de pesquisa expandida

Texto centralizado: `deep_search_loading` → `"Expandindo a pesquisa"` (exibido durante `performExtendedSearch`).

#### Estado F — EditingStop (`AbstractC3986f.a`)

Modo de edição de endereço de parada existente. Exibe o pager de edição da parada (`C3359a`) acima dos resultados — painel compacto da parada sendo editada com query atual populada.

### 1.5 Rodapé de atribuição (sempre visível)

```
Row
  ├── Image: drawable "powered_by_google"
  ├── Spacer (2 dp)
  └── Text: "& GraphHopper API"
```

---

## 2. Strings PT-BR verbatim (completo)

| Chave | Valor |
|---|---|
| `search_placeholder_cant_add_stops` | `"Encontrar paradas"` |
| `search_placeholder_nostops_focused` | `"Digite para adicionar"` |
| `search_placeholder_nostops_unfocused` | `"Toque para adicionar"` |
| `search_placeholder_fewstops_focused` | `"Digite para adicionar"` |
| `search_placeholder_fewstops_unfocused` | `"Toque para adicionar"` |
| `search_placeholder_morestops_focused` | `"Adicione ou busque"` |
| `search_placeholder_morestops_unfocused` | `"Adicione ou busque"` |
| `add_stop_placeholder` | `"Insira um endereço"` |
| `voice_input_on_placeholder` | `"Entrada por voz ativada"` |
| `map` | `"Mapa"` |
| `search_button_scan` | `"Leitor"` |
| `search_button_voice` | `"Voz"` |
| `search_button_scan_next` | `"Ler o próximo"` |
| `search_emptystate_cant_add_stop` | `"Encontrar paradas nesta rota"` |
| `search_emptystate_nostops` | `"Pesquise um endereço para adicionar a primeira parada"` |
| `search_empty_state_text` | `"Adicione as primeiras paradas para começar a criar sua rota"` |
| `search_emptystate_morestops` | `"Adicione novas paradas ou encontre paradas na rota"` |
| `search_update_empty_state` | `"Digite o novo endereço para esta parada"` |
| `search_list_from_this_route` | `"Desta rota (%1$d)"` |
| `search_list_add_new_stop` | `"Adicionar nova parada"` |
| `search_list_choose_on_map` | `"Escolher no mapa"` |
| `search_no_results_title` | `"Nenhum resultado encontrado"` |
| `search_no_results_subtitle` | `"Tente reformular a pesquisa"` |
| `search_no_results_cant_add_stop_subtitle` | `"O despachante não permite adicionar paradas"` |
| `deep_search_button` | `"Veja resultados da <b>pesquisa expandida</b>"` (HTML) |
| `deep_search_loading` | `"Expandindo a pesquisa"` |
| `search_empty_state` | `"Adicione ou busque paradas nesta rota"` |
| `added_stop_toast_message` | `"Parada adicionada"` |
| `address_not_identifiable_toast` | `"O endereço não pode ser identificado agora."` |
| `adding_stops_loading_title` | `"Encontrando endereço..."` |
| `adding_stops_loading_subtitle` | `"Localizando..."` |
| `adding_stops_error` | `"Não encontrado. Toque para corrigir."` |
| `no_internet_connection_error_message` | `"Verifique seus dados móveis ou Wi-Fi."` |
| `duplicate_stop_title` | `"Duplicar parada"` |
| `duplicate_stop_toast_view_action` | `"Ver"` |
| `duplicated_badge_title` | `"Duplicada"` |
| `add_or_find_stop_placeholder` | `"Adicionar ou buscar paradas"` |
| `voice_input_title` | `"Entrada de voz"` |

---

## 3. Navegação

### Abre a partir de:
- **RouteShellPage** (shell da rota ativa) — botão "+" ou campo de busca no rodapé/sheet da rota → push da SearchScreen com `SearchArgs.ScreenMode.AddStops`.
- **EditStopPage** (editar parada) — botão "Mudar endereço" → abre `AddressPickerFragment` com `SearchArgs.ScreenMode.Picker(prefillAddressText, stopId, isUpdateRoute)`.

### A partir da SearchScreen, navega para:
- **SelectExactLocation** (escolher no mapa) — ao tocar "Escolher no mapa" → retorna `AddressPickerFragment.SelectExactLocationForStopResult` via Bundle key `address_picker_choose_on_map_for_stop_result`.
- **EditStopPage** (editar parada da rota existente) — ao tocar em item "Desta rota" → push para edição.
- **Nenhuma tela** ao confirmar um endereço de sugestão — chama `addStop` e emite evento `onPickedResult`; o shell recebe e fecha a SearchScreen com toast `"Parada adicionada"`.
- **ScannerFragment** — ao tocar "Leitor" (se `scanFeatureStatus` habilitado). [B2B se for scan de workflow — cortar; scanner de endereço de etiqueta é B2C]
- **SpeechInputFragment** — ao tocar "Voz" (se `speechInputFeatureStatus` habilitado).

### Retorno de resultado:
- `AddressPickerResult.Key.Global` — chave `"address_picker_global_result_key"` — resultado global (adição de parada via picker).
- `AddressPickerResult.Key.StopAddress(stopId)` — chave `"address_picker_stop_result_key_<stopId>"` — resultado de endereço para parada específica.
- `AddressPickerResult` encapsula um `Address`.

---

## 4. Estados / Defaults / Enums

### SearchArgs.ScreenMode

| Valor | Quando | Comportamento diferente |
|---|---|---|
| `AddStops` (singleton) | fluxo normal de adição de parada | sugestões mostram ícone `pin_squared_plus`; header "AddNewStop" |
| `Picker(prefillAddressText, stopId, isUpdateRoute)` | editar endereço de parada existente | campo pré-preenchido; sugestões mostram ícone `pin_squared`; header "UpdateHeader"; sem botão "Mapa"; `waitingMessage = Update` |

### SearchMode (para a API de busca)
- `ALL` — modo AddStops com permissão de adicionar.
- `EXISTING_ONLY` — sem permissão de adicionar parada (só busca nas paradas da rota).
- `SUGGESTED_ONLY` — modo Picker.

### SearchStep (AbstractC3986f)

| Subclasse | Significado |
|---|---|
| `b.e(showMessage, showMapOption)` | WaitingForQuery — query vazia |
| `b.Loading` (singleton) | carregando |
| `b.d(matchingStops, suggestions, header, showMapOption, showExtendedSearch, showOfflineBanner, showLoadingPlaceholders, autocompleteSuggestions)` | Results |
| `b.c(addStopEnabled, showMapOption, showExtendedSearch)` | NoResults |
| `b.Failure` (singleton) | erro irrecuperável |
| `a(stopId, isNewStop, query)` | EditingStop — edição de parada existente em andamento |

### FeatureStatus (para os 3 botões de ação)
- `Enabled` / `Disabled` / `Hidden` — controlam se o botão aparece e está clicável.

### SearchBarEndIcon (enum, 5 valores)
`Default`, `MicrophoneDefault`, `MicrophoneHighlighted`, `LabelScanner`, `None`.

### WaitingForQueryMessage (enum, 5 valores)
Ver tabela §1.4 Estado A acima.

### SearchBarPlaceholder (enum, 6 valores)
Ver tabela §1.2 acima.

### SearchSuggestionHeader (enum, 2 valores)
`AddNewStop` / `UpdateHeader` — controla o ícone dos itens de sugestão.

### SearchSuggestionIcon (enum, 2 valores)
`Add` → `pin_squared_plus` / `Update` → `pin_squared`.

---

## 5. Ícones (drawable → Lucide sugerido)

| Drawable Spoke | Uso | Lucide sugerido |
|---|---|---|
| `ic_autocomplete` | ícone de localização à esquerda do campo | `MapPin` |
| `map_outline` | botão "Mapa" | `Map` |
| `ic_scan_24` | botão "Leitor" + pesquisa expandida | `ScanLine` |
| `mic_outline` | botão "Voz" | `Mic` |
| `map` | item "Escolher no mapa" | `Map` |
| `chevron_right` | seta direita em itens de lista | `ChevronRight` |
| `ic_search_24` | ícone de pesquisa expandida | `Search` |
| `pin_squared_plus` | sugestão modo AddStop | `MapPinPlus` |
| `pin_squared` | sugestão modo Picker | `MapPin` |
| `powered_by_google` | atribuição rodapé | (imagem fixa) |

---

## 6. Comportamentos observados no dump (sem runtime)

### Fluxo de adição de parada (AddStops mode)
1. Usuário digita query → debounce na `C24052g` (canal de buffer) → `performQuery`.
2. Se query vazia → `m9996S()` limpa resultados → volta para WaitingForQuery.
3. Se sem internet → `performQuery` não dispara API; usa resultados offline (paradas da rota local).
4. Se online, query length == 1 → dispara evento analytics "Searched".
5. Busca padrão (`performDefaultSearch`) usa modo `ALL` / `EXISTING_ONLY` / `SUGGESTED_ONLY`.
6. Busca expandida (`performExtendedSearch`) — chamada diferente (`mo8291d`) — delay 800 ms via `kotlinx.coroutines.delay(800)` antes de mostrar Loading.
7. Parada adicionada com sucesso → `addedStopSuccessfully` → toast `"Parada adicionada"` + eventos analytics + atualiza speechInput state se ativo.
8. Parada duplicada → `onStopDuplicated` → chama `addedStopSuccessfully` (mesma lógica — a duplicação é tratada como adição bem-sucedida).

### Modo Picker (editar endereço)
- Campo pré-preenchido com `prefillAddressText`.
- Ao confirmar → retorna `AddressPickerResult` para o fragmento pai via Bundle (não push de rota).
- Não mostra botão "Mapa" nem "Leitor" (condicionais no `m9962c` — o branch `!z` pula o botão Mapa).

### Efeito teclado
- `HideKeyboardScrollingEffect` — quando o usuário rola a lista (mobile compacto), o teclado é escondido automaticamente.
- `HideKeyboardWhenScanNextEnabledEffect` — quando `showScanNextButton = true`, teclado é ocultado imediatamente.

---

## 7. AddressPickerFragment (variante modal)

**Propósito:** Versão modal (bottom sheet / dialog adaptativo) da SearchScreen para editar o endereço de uma parada existente.
**Classe:** `AddressPickerFragment extends AdaptiveModalFragment`.

Reutiliza o mesmo `SearchViewModel` com `SearchArgs.ScreenMode.Picker`.

**Args:** `AddressPickerArgs(resultKey, currentAddressText?, stopId?, isUpdateRoute)`.

**Resultado emitido via Fragment Result:**
- Chave: `AddressPickerResult.Key.Global` ou `AddressPickerResult.Key.StopAddress(stopId)`.
- Payload: `AddressPickerResult(address: Address)`.
- Resultado de "escolher no mapa" retornado via Bundle key `"address_picker_choose_on_map_for_stop"`.

---

## 8. Precisa-runtime

| Item | Motivo |
|---|---|
| Animação de entrada/saída da tela de busca | dump não revela a transição (push vs slide vs fade) |
| Altura do sheet quando AddressPickerFragment abre como modal | `AdaptiveModalFragment` tem breakpoints condicionais |
| Posição exata do banner offline na lista | ordem relativa entre banner e itens |
| Comportamento do teclado ao abrir (auto-focus no campo) | sem runtime não é possível confirmar |
| Comportamento do "Ler o próximo" + scan flow em sequência | timing entre scanner e campo de texto |
| Debounce exato em ms do campo de busca | `C24052g` com buffer mas valor não explícito no dump |

---

## 9. Notas de implementação RotPro (B2C apenas)

- **Cortar [B2B]:** `SearchMode.EXISTING_ONLY` (quando despachante bloqueia adição) — RotPro não tem despachante; sempre usar `SearchMode.ALL` equivalente.
- **Cortar [B2B]:** `search_no_results_cant_add_stop_subtitle` e `search_emptystate_cant_add_stop` — essas strings são para o modo dispatch-controlled; não exibir no RotPro.
- **Cortar [B2B]:** `SearchBarPlaceholder.FindStops` — só aparece quando dispatcher bloqueia; não usar.
- **Manter B2C:** scanner de etiqueta (`LabelScanner`) é B2C (entrega física); manter como feature futura.
- **Manter B2C:** pesquisa expandida (deep search) é B2C — usuário pode expandir quando sem resultados.
- **Manter B2C:** modo Picker (`AddressPickerFragment`) — usado para editar endereço de parada em `EditStopPage`.
- **GraphHopper:** rodapé deve incluir "& GraphHopper API" além do "powered by Google" — já presente no dump.
- **Threshold de placeholders:** implementar a lógica exata: 0 = NoStops, 1–5 = FewStops, ≥ 6 = ManyStops.
