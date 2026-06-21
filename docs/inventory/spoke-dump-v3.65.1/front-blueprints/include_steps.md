# Front blueprint — include_steps

**Data:** 2026-06-21
**Pacote:** `com.circuit.ui.include_steps`
**Fontes:** jadx-out `p016ui/include_steps/` + strings `values-pt-rBR/strings.xml` + `values-pt-rBR/plurals.xml`
**Escopo B2C:** sim — ambas as telas (paradas + pausa) fazem parte do fluxo de otimização B2C.

---

## Visão geral

O pacote `include_steps` contém **dois** modais adaptativos independentes, ativados durante a otimização de rota quando itens ficaram de fora:

| Modal | Classe | Gatilho no EditRouteFragment |
|---|---|---|
| Paradas ignoradas | `IncludeSkippedStopsFragment` | `action_include_skipped_stops` (callback `mo9396f`) |
| Pausa ignorada | `IncludeSkippedBreakFragment` | `action_include_skipped_break` (callback `mo9397g`) |

Ambos estendem `AdaptiveModalFragment` com `AdaptiveModalSize.Medium` (tamanho "Medium" = 1 no enum `Small=0 / Medium=1 / Large=2`). O nav graph registra paradas como `<fragment>` e pausa como `<dialog>`.

---

## Tela 1 — IncludeSkippedStopsFragment

### 1. Nome / Propósito / Classe

**Nome:** "Paradas não adicionadas" (título dinâmico via plurals)
**Propósito:** Exibe as paradas que o otimizador ignorou, agrupadas por motivo, e permite ao usuário tentar incluí-las mesmo assim ou acessar a tela de parada para editar o problema.
**Classe:** `com.circuit.ui.include_steps.stops.IncludeSkippedStopsFragment`
**ViewModel:** `IncludeSkippedStopsViewModel`
**State (UI):** `b88` (IncludeSkippedStopsState) — campos:
  - `sections: List<g88>` (IncludedSkippedStopSectionUiModel) — lista de seções, cada uma com título `g3c` + lista de itens `C2676g` (RouteStepUiModel)
  - `title: jqd` (StringHolder — plurals dinâmico)
  - `tip: C1958br?` (AnnotatedString nullable — texto de dica clicável; null = sem dica)

### 2. Estrutura (em ordem)

O conteúdo é composto pelo `a88.m227b` (IncludeSkippedStopsScreen) + `a88.m226a` (botões de rodapé inline dentro do LazyColumn):

```
AdaptiveModal (Medium)
  └─ LazyColumn (vertical scroll)
       ├─ [Cabeçalho — composable `ig6` caso 1 / s09.m43799b]
       │    └─ Título (plurals): "%1$d parada(s) não pôde(ram) ser adicionada(s)"
       ├─ [Botões de rodapé — a88.m226a]
       │    ├─ Botão primário: "Incluir mesmo assim" (weight=1, filled)
       │    └─ Botão secundário: "Dispensar" (weight=1, outlined/text)
       ├─ [Dica opcional — C1958br AnnotatedString, padding 16dp H + 8dp T, clicável]
       │    └─ Texto: "Dica: Atualize o horário de término, se necessário"
       │         (parte "Atualize o horário de término" é span clicável → onTipClick → EditRouteSetup)
       └─ [Seções de paradas — forEach g88]
            ├─ Seção A — título: "Veículo sem capacidade suficiente"
            │    └─ Lista de RouteStepUiModel (paradas com problema de capacidade)
            ├─ Seção B — título: "Não pode ser alcançada a tempo"
            │    └─ Lista de RouteStepUiModel (paradas com janela de tempo inviável)
            └─ Seção C — título: "Após o horário de término (%1$s)" (horário formatado como argumento)
                 └─ Lista de RouteStepUiModel (paradas além do fim da rota)
```

Cada item da lista é um `RouteStepUiModel` (componente reutilizável de parada); toque num item → `onStepClicked(RouteStepListKey)` → navega para `EditStopDialogArgs` (tela de edição da parada).

### 3. Strings PT-BR verbatim

| Chave | Texto |
|---|---|
| `stops_couldnt_be_added_to_route_title` (plural one) | `"%1$d parada não pôde ser adicionada"` |
| `stops_couldnt_be_added_to_route_title` (plural other) | `"%1$d paradas não puderam ser adicionadas"` |
| `stops_cant_be_added_section_vehicle_capacity` | `"Veículo sem capacidade suficiente"` |
| `stops_cant_be_added_section_time_window` | `"Não pode ser alcançada a tempo"` |
| `stops_cant_be_added_section_after_end_time` | `"Após o horário de término (%1$s)"` |
| `stops_cant_be_added_tip_update_end_time` | `"Atualize o horário de término"` |
| `stops_cant_be_added_tip_wrapper_text` | `"Dica: %1$s, se necessário"` |
| `break_skipped_dialog_not_required_include_button` | `"Incluir mesmo assim"` *(botão primário)* |
| `generic_dismiss` | `"Dispensar"` *(botão secundário)* |

### 4. Navegação

| Ação | Destino |
|---|---|
| Botão "Incluir mesmo assim" (`onIncludeAnywayClick`) | Chama `C2950f0.m8819a()` (interactor IncludeSkippedStops) → emite evento `AbstractC4115a.d` (toast de sucesso) → fecha modal (`AbstractC3762a.a` = Close) |
| Botão "Dispensar" (`onDismissClick`) | Fecha modal (`AbstractC3762a.a` = Close) |
| Tap numa parada (`onStepClicked`) | `AbstractC3762a.b(stopId)` → `EditStopDialogArgs(stopId)` → EditStop sheet |
| Tap na dica (`onTipClick`) | `AbstractC3762a.c` (RouteSetup) → `R.id.action_setup` → tela de configuração da rota |
| Sem rota ativa no boot | Fecha modal imediatamente (`AbstractC3762a.a` via `mo42447a().m45787f()` = false) |

### 5. Estados / Defaults / Enums

**Estado inicial padrão (`b88()`):**
- `sections = emptyList()`
- `title = StringHolder.Loading` (jqd.C23645a.f110415b)
- `tip = null`

**Lógica de preenchimento das seções (ViewModel):**
1. Observa `GetActiveRouteSnapshot` + veículo ativo.
2. Paradas com problema de capacidade → seção "vehicle_capacity".
3. Paradas com janela de tempo: se a rota NÃO tem horário de fim → seção "time_window"; se a rota TEM horário de fim e a parada NÃO tem janela própria → seção "after_end_time" (com o horário formatado).
4. Tip aparece apenas se houver paradas na seção "after_end_time" (campo `tip` fica não-nulo).

**`BreakUnassignmentCode` (reutilizado na tela de pausa):**
- `IMPOSSIBLE_TIME_WINDOW` (ordinal 0) — janela impossível
- `NOT_REQUIRED_FIRST` (ordinal 1) — antes do início
- `NOT_REQUIRED_LAST` (ordinal 2) — após o fim

**`RouteStepListKey` (sealed, Parcelable):**
- `StopKeyId(stopId: BaseStopId)` — parada comum
- `BreakKeyId(breakId: BreakId)` — pausa
- `GroupHeader(groupId: RouteStepListGroup)` — cabeçalho de grupo
- `Break` — singleton pausa
- `Start` — singleton início
- `End` — singleton fim

**Eventos de navegação (AbstractC3762a — IncludeSkippedStopsState):**
- `a` (Close) — fechar modal
- `b(stopId: BaseStopId)` (EditStop) — abrir edição da parada
- `c` (RouteSetup) — ir para configuração da rota

### 6. Ícones

Nenhum ícone customizado identificado no composable principal do modal de paradas. Os itens de lista usam o `RouteStepUiModel` compartilhado (ícones de parada normais).

### 7. Precisa-runtime

- Animação de entrada/saída do modal (medium snap behavior).
- Comportamento exato do scroll quando múltiplas seções → confirmar se há sticky headers.
- Toast exato exibido ao "incluir mesmo assim" (`AbstractC4115a.d`).

---

## Tela 2 — IncludeSkippedBreakFragment

### 1. Nome / Propósito / Classe

**Nome:** "Pausa não adicionada"
**Propósito:** Informa ao usuário por que a pausa foi ignorada pela otimização (com texto de motivo dinâmico) e oferece ações: incluir mesmo assim, remover pausa, ou editar a pausa.
**Classe:** `com.circuit.ui.include_steps.breaks.IncludeSkippedBreakFragment`
**ViewModel:** `IncludeSkippedBreakViewModel`
**State (UI):** `q78` (IncludeSkippedBreakState) — campos:
  - `explainer: jqd` (StringHolder — texto dinâmico do motivo; campo `a`)
  - `breakStatus: jqd` (StringHolder — horário/status da pausa; campo `b`)
  - `hasIncludeAnywayButton: Boolean` (campo `c`) — controla visibilidade do botão "Incluir pausa"

### 2. Estrutura (em ordem)

Composable `p78.m42392b` (IncludeSkippedBreakScreen) = Column vertical:

```
AdaptiveModal (Medium) — <dialog> no nav graph
  └─ Column (fillMaxWidth, spacedBy 8dp vertical)
       ├─ [Seção de cabeçalho — p78.m42394d]
       │    ├─ Título: "Pausa não adicionada"  (titleLarge style)
       │    └─ Texto de motivo (explainer — dinâmico, ver §3)  (bodyMedium style, clicável → onDescriptionClick → EditBreak)
       ├─ Spacer
       ├─ [Linha de info da pausa — p78.m42391a]
       │    ├─ Ícone: ic_coffee_fill (drawable, 20dp, padding 40dp H + 24dp V)
       │    ├─ Texto principal: "Pausa"  (break_in_route_title, titleMedium style)
       │    ├─ Texto secundário: horário/status da pausa (breakStatus — StringHolder)
       │    └─ Chevron right (chevron_right drawable, end)
       └─ [Botões de ação — p78.m42393c]
            ├─ [Condicional] Botão "Incluir pausa"  (hasIncludeAnywayButton=true, weight=1, filled)
            └─ Botão "Remover pausa" (weight=1, outlined)
```

**Nota:** O botão "Incluir pausa" (`break_skipped_dialog_not_required_include_button`) só aparece quando `hasIncludeAnywayButton = true` (casos `NOT_REQUIRED_FIRST` e `NOT_REQUIRED_LAST`). Para `IMPOSSIBLE_TIME_WINDOW`, o botão é omitido (condição `z2 = q78Var.f127760c`, branching com `mo2546z` para composable diferente).

### 3. Strings PT-BR verbatim

| Chave | Texto |
|---|---|
| `break_skipped_dialog_title` | `"Pausa não adicionada"` |
| `break_skipped_dialog_explainer_conflict` | `"A pausa coincide com algumas paradas. Defina uma janela de tempo diferente para incluí-la na rota."` |
| `break_skipped_dialog_explainer_before_start` | `"A pausa está agendada para antes do início da rota. Defina um horário depois de %s ou inclua-a antes da primeira parada."` |
| `break_skipped_dialog_explainer_after_end` | `"A pausa está agendada para após o fim da rota. Defina um horário antes de %s ou inclua-a depois da última parada."` |
| `break_skipped_dialog_not_required_include_button` | `"Incluir pausa"` |
| `break_screen_remove_button` | `"Remover pausa"` |
| `break_in_route_title` | `"Pausa"` |
| `generic_dismiss` | `"Dispensar"` *(não usado neste modal; botão é "Remover pausa")* |

### 4. Navegação

| Ação | Destino |
|---|---|
| Tap na linha de pausa (`onBreakClick`) | `AbstractC3756a.b(breakId)` → `BreakSetupArgs.EditBreak(breakId)` → tela de edição da pausa |
| Tap no texto do motivo (`onDescriptionClick`) | mesmo que `onBreakClick` — navega para EditBreak |
| Botão "Incluir pausa" (`onIncludeAnywayClick`) | Chama `C2947e0.m8815a(breakId)` (interactor IncludeSkippedBreak com breakId) → fecha modal |
| Botão "Remover pausa" (`onRemoveBreakClick`) | `AbstractC3756a.c(breakId, breakInfo)` → abre `DialogC2604j` (confirmação de remoção) → se confirmado: `C2969o.m8858a(breakId)` (DeleteBreak) + fecha modal |
| Sem rota ativa no boot | Fecha modal imediatamente (`AbstractC3756a.a`) |

### 5. Estados / Defaults / Enums

**Estado inicial padrão (`q78()`):**
- `explainer = StringHolder.Loading`
- `breakStatus = StringHolder.Loading`
- `hasIncludeAnywayButton = true`

**Lógica por `BreakUnassignmentCode`:**

| Código | `hasIncludeAnywayButton` | Texto de motivo (explainer) |
|---|---|---|
| `IMPOSSIBLE_TIME_WINDOW` (0) | `false` | `"A pausa coincide com algumas paradas. Defina uma janela de tempo diferente para incluí-la na rota."` |
| `NOT_REQUIRED_FIRST` (1) | `true` | `"A pausa está agendada para antes do início da rota. Defina um horário depois de %s ou inclua-a antes da primeira parada."` (arg = horário da primeira parada ou horário de início da rota) |
| `NOT_REQUIRED_LAST` (2) | `true` | `"A pausa está agendada para após o fim da rota. Defina um horário antes de %s ou inclua-a depois da última parada."` (arg = horário da última parada ou horário de fim da rota) |

**Evento de navegação (AbstractC3756a — IncludeSkippedBreakState):**
- `a` (Close) — fechar modal
- `b(breakId: BreakId)` (EditBreak) — abrir edição da pausa
- `c(breakId: BreakId, breakInfo: String)` (ShowConfirmDeleteBreakDialog) — abrir diálogo de confirmação

### 6. Ícones

| Drawable | Mapeamento Lucide sugerido | Uso |
|---|---|---|
| `ic_coffee_fill` | `Coffee` (Lucide, filled) | Ícone da pausa na linha de info |
| `chevron_right` | `ChevronRight` (Lucide) | Seta no item da pausa (indica que é clicável) |

### 7. Precisa-runtime

- Texto exato de `breakStatus` (horário da pausa formatado): confirmar formatação PT-BR ("14:30" vs "2:30 PM").
- Animação de entrada modal.

---

## Sub-diálogo: Confirmar Remoção da Pausa (DialogC2604j)

Diálogo de alerta padrão (`CircuitAlertDialog`) ativado pelo `onRemoveBreakClick` dentro do `IncludeSkippedBreakFragment`.

**Classe:** `com.circuit.components.dialog.DialogC2604j`

| Campo | Valor |
|---|---|
| Título | `"Remover pausa"` (`remove_break_confirmation_dialog_title`) |
| Descrição | `"Quer remover a pausa de %1$s da sua rota?"` (`remove_break_confirmation_dialog_description`) — arg = `breakInfo` (e.g. "15 min") |
| Botão confirmar | `"Remover pausa"` (`break_detail_sheet_remove_button`) — `ActionStyle.Destructive` |
| Botão cancelar | `"Cancelar"` (`cancel`) — `ActionStyle.Secondary` |

**Ação ao confirmar:** `C2969o.m8858a(breakId)` (DeleteBreak interactor) + `AbstractC3756a.a` (Close modal pai).

---

## Diagrama de fluxo resumido

```
EditRoute (otimização concluída com itens ignorados)
  │
  ├─ paradas ignoradas → action_include_skipped_stops
  │    └─ IncludeSkippedStopsFragment (Modal Medium)
  │         ├─ "Incluir mesmo assim" → interactor + toast + fechar
  │         ├─ "Dispensar" → fechar
  │         ├─ tap parada → EditStop sheet
  │         └─ tap dica → RouteSetup
  │
  └─ pausa ignorada → action_include_skipped_break
       └─ IncludeSkippedBreakFragment (Dialog Medium)
            ├─ [se NOT_REQUIRED] "Incluir pausa" → interactor + fechar
            ├─ "Remover pausa" → DialogC2604j (confirm)
            │    └─ confirmar → DeleteBreak + fechar
            ├─ tap na linha da pausa → EditBreak
            └─ tap no texto do motivo → EditBreak
```

---

## Notas de implementação para RotPro

- **Dois modais distintos** — não unificar numa única tela.
- **`hasIncludeAnywayButton`** controla o botão via estado (não via `if` em UI); replicar com campo no `data class` de estado.
- **Seções de paradas são dinâmicas** — zero a três seções, dependendo dos motivos; a seção "after_end_time" só aparece se a rota tem horário de fim configurado.
- **Dica clicável** é `AnnotatedString` com span de click, não um `Button` separado.
- **`BreakUnassignmentCode.IMPOSSIBLE_TIME_WINDOW`** = botão "Incluir pausa" oculto; os outros dois códigos = botão visível.
- **Confirmar remoção de pausa** é diálogo de sistema (AlertDialog padrão), não outro modal adaptativo.
- **Ícone de pausa:** `ic_coffee_fill` → Lucide `Coffee` (filled variant).
