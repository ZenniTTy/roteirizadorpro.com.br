# Front blueprint — home-editroute

Data do dump: 2026-06-21
Fonte: `~/spoke-dump/jadx-out/sources/com/circuit/p016ui/home/editroute/`
Escopo: stopactions · optimization · toasts · lifecycle · components/detailsheet · mediaimport · orderstopgroup · formatter · map
Excluído: steplist (já documentado)

---

## 1. EditRouteFragment (shell da tela)

**Propósito:** fragmento raiz da tela de rota ativa; orquestra mapa + sheet + diálogos.
**Classe:** `com.circuit.ui.home.editroute.EditRouteFragment`

### Estrutura geral

A tela é composta por dois blocos verticais (Column, não Stack — ver lição MS-A3):

1. **MapSection** — mapa Google Maps que ocupa espaço variável (Expanded).
2. **DetailsSection** (sheet) — inclui o DragHandle, header com barra de busca, lista de paradas e footer com botões de ação.

### Enums de configuração de posição do sheet

- **SheetLocation:** `Main`, `Detail` (qual sheet está visível).
- **EditRouteSheetId:** distingue os sheets renderizados pelo SheetSwitcher.
- **MapContentCoverType:** estado de sobreposição do conteúdo do mapa (ex.: quando ordenação manual está ativa).

### Navegação

- Aberto a partir da `RouteListScreen` ao selecionar uma rota ou criar nova.
- Fecha de volta para `RouteListScreen` via `back` (com confirmação se houver alterações).
- Abre `EditRoutePage` (rota de configuração geral) via ação no header.

---

## 2. MainSheet — Header (barra de busca + título)

**Propósito:** cabeçalho do sheet principal; alterna entre campo de busca ativo e título compacto.
**Classe:** `com.circuit.ui.home.editroute.components.mainsheet.header.HeaderKt` + `SearchBarConfiguration`

### Estrutura

- **Título da rota** (linha compacta — colapsada).
- **Campo de busca** (`SearchTextField`) com placeholder:
  - Padrão: `"Insira um endereço"` (`add_stop_placeholder`)
  - Alternativo (quando rota tem paradas): `"Adicionar ou buscar paradas"` (`add_or_find_stop_placeholder`)
- Botão de câmera/microfone (acesso rápido ao MediaImport — ver §9).
- Botão de kebab (`⋮`) abre **RouteMenuActionsDialog** (ver §3).

### Enum SearchBarConfiguration

| Valor | Descrição |
|---|---|
| `Searching` | Campo expandido + teclado visível |
| `Expanded` | Campo expandido, sem teclado |
| `Collapsed` | Somente título visível |

### Strings PT-BR

- `"Insira um endereço"` — placeholder campo de busca (estado vazio)
- `"Adicionar ou buscar paradas"` — placeholder alternativo

### Navegação

- Digitar texto → abre SearchScreen.
- Botão kebab → abre RouteMenuActionsDialog.

---

## 3. RouteMenuActionsDialog (kebab menu da rota)

**Propósito:** bottom sheet modal com ações secundárias da rota (estilo `AdaptiveModalDialog`).
**Classe:** `com.circuit.ui.home.editroute.components.mainsheet.RouteMenuActionsDialog`

### Estrutura — lista de ações (`AbstractC3737w`)

Ações disponíveis (ordem do código + strings PT-BR):

| Ação | String PT-BR |
|---|---|
| Reotimizar rota | `"Reotimizar rota..."` (`more_options_reoptimize_route_title`) |
| Pular otimização | `"Pular otimização"` (`more_options_skip_optimization_title`) |
| Remover paradas | `"Remover paradas..."` (`more_options_remove_stops_title`) |
| Copiar paradas | `"Copiar paradas..."` (`more_options_copy_stops_title`) |
| Compartilhar cópia da rota | `"Compartilhar cópia da rota"` (`more_options_share_route_title`) |
| Imprimir rota | `"Imprimir rota"` (`more_options_print_route_title`) |
| Redefinir IDs de parada | `"Redefinir IDs de parada..."` (`more_options_reset_package_identification`) |

### Navegação

- Aberto pelo botão kebab `⋮` no header.
- "Reotimizar rota..." → fecha dialog, abre **ReoptimizationOptionsSheet** (ver §6).
- "Remover paradas..." → abre fluxo de remoção múltipla.
- "Compartilhar cópia da rota" → dispara `EditRouteViewModel.shareCopyOfRoute`.

### Estados/variações

- Itens podem aparecer desabilitados/ocultos conforme `FeatureStatus` (`AppFeature`).
- "Pular otimização" aparece somente quando otimização está pendente.

### Precisa-runtime

- Quais ações aparecem habilitadas/visíveis em cada estado da rota (pré-otimização, pós-otimização, em andamento).

---

## 4. MainSheet — Footer (botões de ação primária)

**Propósito:** barra de ação inferior do sheet; muda conforme o ciclo de vida da rota.
**Classe:** `com.circuit.ui.home.editroute.components.mainsheet.MainSheetFooterKt`

### Variações de estado (inferido de RouteLifecycleController + strings)

| Estado da rota | Botão primário | String PT-BR |
|---|---|---|
| Não otimizada (pré-start) | Otimizar rota | `"Otimizar rota"` (`stops_optimize_button_title`) |
| Otimizada, não iniciada | Iniciar rota | `"Iniciar rota"` (`start_button_title`) |
| Otimização pendente | Otimização pendente | `"Otimização pendente"` (`optimization_pending_button_title`) |
| Rota em andamento | — (footers do step) | — |
| Editando rota em andamento | Aplicar alterações (N) | `"Aplicar alterações (%1$d)"` (`apply_changes_button_title`) |
| Salvar alterações | Salvar alterações | `"Salvar alterações"` (`save_changes_button`) |
| Finalizar rota | Marcar rota como finalizada | `"Marcar rota como finalizada"` (`finish_route_button_title`) |
| Confirmar rota (package label) | Confirmar rota | `"Confirmar rota"` via lifecycle |

### Botões secundários (estado otimizada/editando)

- **"Refinar"** (`"Refinar"` — `refine_route_button_title`) → abre **RefineRouteDialog** (ver §5).
- **"Descartar"** (`"Descartar"` — `discard_changes_button_title`) → dispara confirmação de descarte.
- **"Iniciar antes…"** (`start_route_early_button`) — visível quando há horário de início futuro.
- **"Editar"** (`"Editar"` — `edit_route_button_title`) — visível na rota em andamento (volta ao modo edição).

### Precisa-runtime

- Quais combinações de botões aparecem simultaneamente (ex.: Refinar + Otimizar; Refinar + Iniciar).
- Animação de transição entre estados.

---

## 5. RefineRouteDialog (botão Refinar → sheet de opções)

**Propósito:** sheet de opções para refinar a rota manualmente sem reotimizar.
**Classe:** inferido de `refine_route_dialog_*` strings + `EditRouteViewModel.onEditRouteSetupClick`.

### Estrutura

Título: `"Refinar a rota"` (`refine_route_dialog_title`)

| Opção | Título | Descrição |
|---|---|---|
| Inverter a rota | `"Inverter a rota"` (`refine_route_dialog_reverse_title`) | `"Inverter a direção da rota"` (`refine_route_dialog_reverse_description`) |
| Ordenar a rota manualmente | `"Ordenar a rota manualmente"` (`refine_route_dialog_manual_title`) | `"Definir a ordem da rota desenhando no mapa"` (`refine_route_dialog_manual_description`) |

### Navegação

- Aberto pelo botão **"Refinar"** no footer do MainSheet.
- "Inverter a rota" → dispara `OptimizeDirection.REVERSE` → volta ao shell.
- "Ordenar a rota manualmente" → entra no modo **OrderStopGroups** (ver §10).

### ATENÇÃO — distinção crítica (lição Á7)

Este dialog (`RefineRouteDialog`) é o "Refinar"; NÃO é o kebab "Reotimizar rota..." que abre o **ReoptimizationOptionsSheet** (§6). Os dois são componentes distintos.

---

## 6. ReoptimizationOptionsSheet (kebab → Reotimizar rota)

**Propósito:** sheet com opções de reotimização (Atualizar rota / Reotimizar do zero).
**Strings-chave:** `reoptimization_options_view_title`, `optimization_explainer_*`

### Estrutura

Título: `"Alternativas de reotimização"` (`reoptimization_options_view_title`)

| Opção | Label | Badge | Descrição |
|---|---|---|---|
| Atualizar | `"Rota mais rápida"` (`optimization_explainer_faster_route`) — também: título via `optimization_dialog_update_route_subtitle`: `"Reordenar apenas as paradas alteradas"` | `"Menos alterações"` (`optimization_explainer_update_badge`) | `"Aplica as alterações preservando a estrutura da rota original o máximo possível."` (`optimization_explainer_update_description`) |
| Reotimizar | `"Reotimizar"` (`optimization_explainer_reoptimize`) | `"Economia de tempo"` (`optimization_explainer_reoptimize_badge`) | `"Recalcula a rota do zero para tentar achar uma ordem mais eficiente."` (`optimization_explainer_reoptimize_description`) |

Subtítulo comparativo: `"Compare as opções"` (`optimization_explainer_title`) — sugestão de subtítulo/caption acima das opções.
Texto de detalhe (Reotimizar): `"Reordenar todas as paradas para melhor eficiência"` (`optimization_dialog_reoptimize_route_subtitle`).
Texto de detalhe (Atualizar): `"Reordenar apenas as paradas alteradas"` (`optimization_dialog_update_route_subtitle`).

Observação: corpo do alerta de reotimização: `"A reotimização pode alterar a ordem de todas as paradas. Para pequenas alterações, use a opção %1$s."` (`reoptimize_dialog_body`)

### Navegação

- Aberto pelo item "Reotimizar rota..." do **RouteMenuActionsDialog** (§3).
- Qualquer opção selecionada → dispara `OptimizationController.performOptimise` → abre **OptimizingProgressDialog** (§7).

### Precisa-runtime

- Qual opção está pré-selecionada/destacada.
- Se existe botão de confirmação ou a seleção é imediata.

---

## 7. OptimizingProgressDialog (progresso da otimização)

**Propósito:** dialog/overlay exibido enquanto a otimização processa.
**Classe:** `OptimizationController` (eventos `ShowOptimizingDialog`, `CloseOptimizingDialog`)

### Estrutura (fases — 4 fases verbatim do dump `values-pt-rBR`)

Título: `"Otimizando a rota"` (`optimizing_route_title`)

| Fase | String PT-BR | Chave |
|---|---|---|
| 1 | `"Analisando suas paradas..."` | `optimizing_analysing` |
| 2 | `"Considerando o trânsito..."` | `optimizing_traffic` |
| 3 | `"Criando sua rota..."` | `optimizing_creating` |
| Reotimizando | `"Reotimizando a rota"` | `reoptimizing_route` |

### Campos do evento `ShowOptimizingDialog`

- `type: OptimizeType` — qual tipo de otimização está rodando.
- `direction: OptimizeDirection` — nulo exceto para REVERSE.
- `stopCount: Int` — quantidade de paradas.
- `hasPreviouslyOptimizedStops: Boolean`.
- `resetPackageLabels: Boolean`.
- `packageLabelFormat: PackageLabelFormat`.

### Navegação

- Aparece automaticamente após confirmar otimização.
- Fecha com `CloseOptimizingDialog(immediate=true/false)`.
- Em caso de erro → abre **OptimizationErrorDialog** (ver §8).
- Sucesso → fecha; footer muda para "Iniciar rota".

---

## 8. OptimizationErrorDialog (falha na otimização)

**Propósito:** dialog de erro exibido quando a otimização falha.
**Classe:** `EditRouteFragment.showOptimisationError` + eventos `ShowOptimizationError`

### Variações de erro (`OptimizationError` + strings)

| Cenário | Título | Corpo |
|---|---|---|
| Falha genérica de rede | `"Falha ao otimizar"` (`optimization_failed_title`) | `"Não foi possível concluir a otimização. Verifique sua conexão com a internet e tente de novo mais tarde."` (`optimization_failed_body`) |
| Não é possível criar rota (janela de tempo) | `"Não foi possível criar a rota"` (`optimisation_error_cant_create_route_title`) | `"Não foi possível criar a rota usando esses horários de início e término. Tente aumentar ou remover a janela de tempo."` (`optimisation_error_cant_create_route_message`) |
| Localização atual inválida | `"A rota não pode ser criada para sua localização atual"` (`optimisation_error_current_location_title`) | `"A reotimização funcionará quando você estiver perto, e não antes."` (`optimisation_error_current_location_message`) |
| Paradas inacessíveis | `"Não é possível criar uma rota"` (`optimisation_error_inaccessible_stops_title`) | `"Não é possível acessar algumas paradas"` (`optimisation_error_inaccessible_stops_message`) |

Botão de editar paradas (erro inacessível): `"Editar paradas"` (`optimisation_error_inaccessible_stops_edit_button`)

### Campos do evento `ShowOptimizationError`

- `error: OptimizationError`
- `type: OptimizeType`
- `address: Address?` — endereço problemático (se aplicável)
- `showDialog: Boolean` — se exibe dialog ou apenas toast
- `skippable: Boolean` — se permite pular

### Precisa-runtime

- Qual botão de ação aparece em cada variante de erro.

---

## 9. NotEnoughStopsDialog (mínimo de paradas para otimizar)

**Propósito:** dialog exibido ao tentar otimizar com paradas insuficientes.
**Strings:**

- Corpo: `"Para otimizar sua rota, adicione 1 ou mais paradas além do ponto de partida e destino."` (`optimize_route_minimum_stops_body`)
- Prompt adicional: `"Adicione mais paradas para otimizar sua rota"` (`add_more_stops_to_route`)

### Precisa-runtime

- Título exato e botão(ões) do dialog.
- Se é dialog ou toast/snackbar.

---

## 10. OrderStopGroups — Modo de ordenação manual (desenhar grupos no mapa)

**Propósito:** modo especial de edição onde o usuário desenha grupos de paradas diretamente no mapa.
**Classes:** `OrderStopGroupsController`, `OrderStopGroupsFlowController`, `StopGroup`

### Estrutura — modo ativo

Título/instrução quando sem grupos: `"Desenhar o primeiro grupo"` (`order_stop_groups_draw_first_group_message`)
Instrução quando já existe grupo: `"Desenhar o grupo seguinte"` (`order_stop_groups_draw_next_group_message`)

Botão principal de ação no mapa:
- `"Desenhar o primeiro grupo"` (`order_stop_groups_draw_first_group_button`)
- `"Desenhar o grupo seguinte"` (`order_stop_groups_draw_next_group_button`)

Botão Desfazer: `"Desfazer"` (`order_stop_groups_undo_button`)
Botão Confirmar rota: `"Confirmar rota"` (`order_stop_groups_confirm_route_button`)
Botão Continuar editando: `"Continuar editando"` (`order_stop_groups_continue_editing_button`)

Instrução passo a passo (explainer):
- Título: `"Como refinar sua rota"` (`order_stop_groups_explainer_title`)
- Passo 1: `"No mapa, desenhe um círculo em volta da região para onde você pretende ir primeiro"` (`order_stop_groups_explainer_step_1`)
- Passo 2: `"Circule quantas regiões forem necessárias, na ordem em que você pretende dirigir"` (`order_stop_groups_explainer_step_2`)
- Passo 3: `"Toque em \"%s\" para obter sua nova rota"` (`order_stop_groups_explainer_step_3`)

Botão de otimização desabilitado (< 2 grupos): `"Desenhe pelo menos dois grupos para otimizar"` (`order_stop_group_optimization_disabled_message`)

### Modelo de dados — StopGroup

```
StopGroup(
  order: Int,           // posição na sequência
  path: List<Point>,    // polígono desenhado
  markerLocation: Point // centro do grupo
)
```

### Eventos do FlowController

- `SetMapDefaultMode` — volta ao modo normal do mapa.
- `SetMapOrderStopGroupMode` — ativa o modo de desenho.
- `StartOptimizationInStopGroupsMode` — dispara otimização com os grupos.

### Enum OrderStopGroupsOptimizeButtonType

Controla tipo do botão de otimização exibido na toolbar do mapa durante este modo.

### Dialogs dentro do modo

| Dialog | Título | Botões |
|---|---|---|
| Descartar alterações | `"Descartar alterações?"` (`order_stop_groups_discard_changes_dialog_title`) | `"Continuar editando a rota"` / `"Descartar edições de rota"` |
| Aceitar rota atual | `"Aceitar rota atual?"` (`order_stop_groups_accept_current_route_dialog_title`) | `"Continuar editando a rota"` / `"Fechar e aceitar a rota"` |

Descrição do dialog aceitar: `"A rota atual será usada. Se esta rota não funcionar para você, continue editando e re-otimizando até que ela atenda às suas necessidades."` (`order_stop_groups_accept_current_route_dialog_description`)

### Ferramentas de edição de grupo (cluster_feature — variante avançada)

Tipo de ferramentas: `"Novo"` / `"Expandir"` / `"Apagar"` (`cluster_feature_drawing_tool_new/expand/erase`)
[B2B — cortar se for funcionalidade apenas da versão Dispatch do Spoke; verificar runtime se aparece no B2C]

### Navegação

- Ativado pelo botão "Ordenar a rota manualmente" no **RefineRouteDialog** (§5).
- Sair: botão back ou "Continuar editando" → volta ao shell com sheet normal.
- Confirmar rota → dispara otimização → fecha modo.

### Precisa-runtime

- Mecânica exata do gesto de desenho (drag freehand vs. pontilhado).
- Se o onboarding de 3 passos aparece sempre ou só na primeira vez.
- Se as ferramentas cluster_feature (Novo/Expandir/Apagar) aparecem no B2C.

---

## 11. StopActionsController — ações de parada individual

**Propósito:** controla ações de deleção e duplicação de parada individual; emite diálogos de confirmação.
**Classe:** `com.circuit.ui.home.editroute.stopactions.StopActionsController`

### Dialogs emitidos

| Evento | Propósito | Dados |
|---|---|---|
| `ShowConfirmDeleteStopDialog` | Confirmar remoção de parada | `stop: wd5` (stop model) |
| `ShowConfirmDeleteStopOnOptimizationDialog` | Remoção enfileirada para próxima otimização | `stop: wd5` |
| `ShowConfirmActionWithIncompletePickupDialog` | Navegar para parada com pickup pendente | `navigateStopId, pickupStop, confirmActionTitle` |
| `ShowLoadingVehiclePendingDialog` | Coleta no depósito ainda pendente | `depotPickupStopId` |

### Ações disponíveis

- **Deletar parada** (`onDeleteStopClick`) → emite `ShowConfirmDeleteStopDialog`.
- **Confirmar deleção** (`onConfirmDeleteStop`) → remove da rota.
- **Deletar na otimização** (`onConfirmDeleteStopOnOptimization`) → agenda remoção.
- **Duplicar parada** (`onDuplicateStop`, `baseStopId`) — duplica e exibe toast.
- **Desfazer deleção de parada** (`onConfirmUndoDeleteStop`) — restaura parada.
- **Deletar pausa** (`onConfirmDeleteBreak`) — remove break.
- **Desfazer deleção de pausa** (`onConfirmUndoDeleteBreak`).

### Strings PT-BR

- Título da ação "Remover parada": `"Remover parada"` (`delete_stop_action_title` / `remove_stop_title`)
- Confirmação de remoção: `"Quer remover \"%1$s\" da rota?"` (`remove_stop_confirmation_dialog_text`)
- Remoção enfileirada: `"A parada \"%1$s\" será removida da rota na próxima otimização."` (`remove_stop_on_optimization_confirmation_dialog_text`)
- Desfazer remoção: `"Desfazer remoção"` (`removed_stop_dialog_undo_delete`)
- Duplicar parada: `"Duplicar parada"` (`duplicate_stop_title`)
- Toast "Ver" após duplicar: `"Ver"` (`duplicate_stop_toast_view_action`)

---

## 12. RouteLifecycleController — eventos de ciclo de vida da rota

**Propósito:** controla transições de estado (Criar/Iniciar/Finalizar/Descartar) e emite dialogs.
**Classe:** `com.circuit.ui.home.editroute.lifecycle.RouteLifecycleController`

### Ações do usuário mapeadas

| Método | Ação |
|---|---|
| `onStartRouteClick` | Botão "Iniciar rota" |
| `onStartRouteConfirmed` | Confirma início após dialog |
| `onEditRouteClick` | Botão "Editar" (rota em andamento) |
| `onFinishRouteClick` | Botão "Marcar rota como finalizada" |
| `onConfirmRouteClick` | Botão "Confirmar rota" (package label mode) |
| `onDisabledStartClick` | Tap em "Iniciar rota" desabilitado |
| `onConfirmDiscardChanges` | Confirma descarte de alterações |
| `onPackageLabelIdLockConfirmed` | Confirma lock de IDs de pacote |

### Dialogs emitidos (AbstractC3589c)

| Evento | Dialog | Dados |
|---|---|---|
| `ShowApplyChangesDialog` | Confirmar aplicação de N alterações | `changesCount: Int` |
| `ShowDiscardConfirmationDialog` | Confirmar descarte de N alterações | `changeCount: Int` |
| `ShowPackageLabelIdLockDialog` | Confirmar lock de IDs de parada | `format: PackageLabelFormat` |
| `ShowPackageLabelLoadVehicleDialog` | Carregar veículo (package label mode) | — |
| `ShowStartRouteConfirmation` | Confirmar início (gate) | `type` |

### Eventos de resultado (AbstractC3588b)

| Evento | Significado |
|---|---|
| `ChangesDiscarded` | Alterações foram descartadas com sucesso |
| `ClearMakeNextSelection` | Limpa seleção "Make Next" |
| `RouteStarted(nextStepId)` | Rota iniciada; navega para próximo step |
| `ShowDisabledStartToast` | Toast de motivo do botão Iniciar desabilitado |

### Strings PT-BR — Discard Changes Dialog

- Título: `"Descartar alterações"` (`discard_changes_dialog_title`)
- Corpo: `"As alterações não salvas serão perdidas, e a rota reverterá para a versão otimizada mais recente."` (`discard_changes_dialog_body`)
- Confirmar: `"Descartar alterações (%1$d)"` (`discard_changes_dialog_confirmation_button`)
- Cancelar: `"Continuar editando"` (`discard_changes_dialog_cancel_button`)
- Toast de confirmação: `"Alterações descartadas"` (`discard_changes_confirmation_toast_message`)

### Strings PT-BR — Horário de início

- Toast bloqueio por horário: `"A rota só pode ser iniciada após %s"` (`unauthorized_toast_route_start_time`)
- Botão alternativo: `"Iniciar antes…"` (`start_route_early_button`)

### Feature gate — start antecipado

Usa `AppFeature.StartRouteBeforeStartTime` com margem `Duration.ofMinutes(N)` configurável (lido de `GetFeatures`).

---

## 13. BottomToastController (toasts do bottom sheet)

**Propósito:** exibe toasts temporários flutuantes na parte inferior da tela (dentro do contexto do sheet).
**Classe:** `com.circuit.ui.home.editroute.toasts.C3733a` (BottomToastController)
**Duração fixa:** 3000ms (`f31673c = 3000L`)

### Tipos de toast (InterfaceC3734b)

| Tipo | Classe interna | Dados | Quando |
|---|---|---|---|
| `ChangesDiscarded` | `a` | — | Após descartar alterações |
| `OptimizationPending` | `c` | — | Otimização ainda necessária |
| `OptimizationSaved` | `d` | `text: String` | Otimização salva com sucesso |
| `QuickReturnToStep` | `e` | `stepId, title, description` | Retorno rápido a uma parada |
| `StopAdded` | `f` | — | Parada adicionada |
| `UndoStopGroup` | `g` | `enabled: Boolean` | Estado do Undo no modo grupos |

### Hierarquia de prioridade

Ordem de renderização (maior prioridade sobrepõe menor):
`UndoStopGroup > OptimizationPending > ChangesDiscarded > (dismissível atual)`

O toast dismissível atual (b) é auto-dismissível após 3s; os persistentes (c, e, g) ficam enquanto o estado for válido.

### Strings PT-BR

- Desfazer: `"Desfazer"` (`stops_undo_button_title`, `order_stop_groups_undo_button`)
- Otimização pendente: `"Otimização pendente"` (`optimization_pending_button_title`)
- Desfazer otimização: `"Desfazer otimização"` (`undo_optimization_button_title`)

---

## 14. MapActionToastController (toasts de ação do mapa)

**Propósito:** exibe toasts rápidos de feedback quando o usuário interage com controles do mapa.
**Classe:** `com.circuit.ui.home.editroute.map.MapActionToastController`

### Strings PT-BR (map_action_toast_*)

| Ação | String |
|---|---|
| Seguir minha localização | `"Seguir"` (`map_action_toast_follow`) |
| Ver rota completa | `"Rota completa"` (`map_action_toast_full_route`) |
| Próxima parada | `"Próxima parada"` (`map_action_toast_next_stop`) |
| Satélite ativado | `"Satélite ativado"` (`map_action_toast_satellite_on`) |
| Satélite desativado | `"Satélite desativado"` (`map_action_toast_satellite_off`) |
| Pausa (no mapa) | `"Pausa"` (`map_action_toast_static_break`) |
| Parada (no mapa) | `"Parada"` (`map_action_toast_static_stop`) |
| Próximas paradas | `"Próximas paradas"` (`map_action_toast_upcoming_stops`) |

---

## 15. MapSection — Controles e modos da câmera do mapa

**Propósito:** controla o comportamento da câmera do Google Maps e os controles sobrepostos.
**Classe:** `com.circuit.ui.home.editroute.map.MapController` + `MapControllerMode` + `MapToolbarControlsState`

### Enum MapControllerMode (modos de câmera/exibição)

| Modo | Descrição |
|---|---|
| `Manual` | Usuário controlou a câmera manualmente |
| `DynamicRouteView` | Câmera mostra toda a rota ("Rota completa") |
| `NextStepsCluster` | Câmera foca nas próximas N paradas |
| `DynamicActiveStopView` | Câmera foca na parada ativa |
| `StaticStepView(stepId)` | Câmera foca em parada específica (detail sheet) |
| `FollowMyLocation` | Câmera segue o GPS do usuário |
| `SelectExactLocation` | Modo de seleção de ponto exato (long press) |

### MapToolbarControlsState

```
MapToolbarControlsState(
  fabMode: MapToolbarFabMode,       // Drawer | Close | Hidden
  fabEnabled: Boolean,
  toggleButtonsVisible: Boolean     // default: true
)
Default: fabMode=Drawer, fabEnabled=true, toggleButtonsVisible=true
```

### Enum MapToolbarFabMode

| Valor | Estado |
|---|---|
| `Drawer` | FAB de menu/drawer (modo normal) |
| `Close` | FAB de fechar (ex.: modo ordenação de grupos) |
| `Hidden` | FAB oculto |

### Enum MapToolbarMode (barra de navegação interna)

| Valor | Descrição |
|---|---|
| `Overview` | Visão geral da rota no mapa |
| `Navigation` | Navegação turn-by-turn ativa |

### Modo SelectExactLocation (long press no mapa)

Ativado por long press → mostra pin arrastável.
- Toast instrução: `"Arraste para definir a localização"` (`drag_to_set_location`)
- Botão ajuste: `"Ajustar localização"` (`adjust_pin_location_button`)

### Satélite

Toggle ligado/desligado — persiste em `MapTypePreferences`. Sem seleção de outros tipos (satélite = on/off).

### Precisa-runtime

- Botões de zoom visíveis ou ocultos durante navegação.
- Ordem exata dos controles na toolbar do mapa (satélite, localização, rota completa, próxima parada).
- Animação de transição entre modos de câmera.

---

## 16. InternalNavigationBar (barra de navegação interna — Spoke Navigation)

**Propósito:** barra sobreposta ao mapa durante navegação turn-by-turn via Google Navigation SDK.
**Classe:** `com.circuit.ui.home.editroute.map.InternalNavigationBarUiModel`

### Estrutura

```
InternalNavigationBarUiModel(
  infoSectionContentModel: InterfaceC3613a,
  secondaryActionButtonType: SecondaryActionButtonType,   // Settings | Navigation | Overview
  mapToolbarMode: MapToolbarMode,
  infoSectionClickAction: InternalNavigationBarAction
)
```

### Estados do conteúdo (InterfaceC3613a)

| Estado | Tipo | Dados exibidos |
|---|---|---|
| Navegação ativa | `ActiveNavigation` | `primaryInfo: String` (instrução atual), `secondaryInfoModel`, `navigatingToStopId` |
| Carregando | `ActiveNavigationLoading` | `loadingType: InternalNavigationLoadingType` |

### Enum InternalNavigationLoadingType

| Valor | String PT-BR |
|---|---|
| `Offline` | `"Não é possível navegar offline"` (`in_app_nav_offline_error`) |
| `FindingDirectionsOnline` | `"Procurando trajeto..."` (`in_app_nav_finding_directions`) |
| `ReroutingOnline` | — (recalculando) |

### SecondaryInfoModel (InterfaceC3614b)

| Tipo | Dados |
|---|---|
| `EtaInfo` | `secondaryTimeInfo: String`, `remainingDistance: String` |
| `OutOfOrder` | `message: String` |
| `CriticalInfo` | `content (primaryText + secondaryText)`, `color: StopColor`, `icon: CriticalInfoIcon` |

### Enum CriticalInfoIcon

| Valor | Drawable |
|---|---|
| `Pickup` | `pickup_16` → Lucide: `PackageOpen` ou `Warehouse` |
| `PackageCount` | `ic_multiple_packages_16` → Lucide: `Boxes` |

### InternalNavigationBarAction (ação ao clicar na barra)

| Valor | Comportamento |
|---|---|
| `ActionDisabled` | Sem ação |
| `OpenNavSettings` | Abre configurações de navegação |
| `NavigateToStepList` | Abre lista de steps (steplist) |
| `BackToInternalNavigation` | Volta para a navegação ativa |

### Strings PT-BR

- Nome do serviço: `"Navegação do Spoke"` (`circuit_internal_navigation`)
- Paradas fora de ordem: `"A parada %1$d foi pulada"` / `"As paradas %1$d e %2$d foram puladas"` / `"As paradas %1$d a %2$d foram puladas"` / `"Algumas paradas foram puladas"` (`in_app_nav_out_of_order_*`)

---

## 17. StopDetailSheet — sheet de detalhe de parada

**Propósito:** sheet expandido exibido ao tocar em uma parada na lista; mostra todas as propriedades e ações da parada.
**Classe:** `com.circuit.ui.home.editroute.components.detailsheet.StopDetailSheetKt` + `StopDetailSheetViewModel`

### Estrutura — TopActions (linha de botões topo)

Botões de ação no topo do sheet (inferido dos lambdas `TopActions$2$1` a `$7$1`):

1. **Editar parada** → `"Editar parada"` (`edit_stop_button`) → abre EditStopPage.
2. **Duplicar parada** → `"Duplicar parada"` (`duplicate_stop_title`).
3. **Remover parada** → `"Remover parada"` (`remove_stop_title` / `delete_stop_action_title`).
4. **Navegação interna** → inicia `Navegação do Spoke`.
5. **Entregue** (`"Entregue"` — `delivered_button`) → marca status.
6. **Não entregue** (`"Não entregue"` — `failed_button`) → marca status.

### Propriedades exibidas (RouteStepSheetPropertyUiModel)

Cada propriedade tem: `content (InterfaceC3513b)`, `icon (Int)`, `style (Style)`, `packagePhotoAttachments`.

| Tipo de conteúdo | Dados | Ação ao tocar |
|---|---|---|
| `Text` | `text, clickAction, linkifyText, secondaryText` | Variável (editar campo) |
| `ContactInfo` | `title, clickAction (OpenContactDialog)` | Abre app de telefone/e-mail |
| `Barcodes` | `remainingBarcodes, scannedBarcodes` | Abre scanner ou `ShowBarcodeCopiedToast` |
| `LinkedStops` | `value, context` | Abre parada vinculada |
| `NonEditableProperty` | `label, value`, ícone `service_outline` | Sem ação |

### Ações de propriedade (AbstractC3512a)

| Classe | Ação |
|---|---|
| `OpenStop` | Navega para parada vinculada (pickup link) |
| `OpenNotesEditor` | Abre editor de notas |
| `OpenTimeWindowDialog` | Abre seletor de janela de tempo |
| `OpenTimeAtStopDialog` | Abre seletor de tempo na parada |
| `OpenOptimizationOrderDialog` | Abre seletor de prioridade de otimização |
| `OpenPackageCountDialog` | Abre seletor de contagem de pacotes |
| `OpenPackageLabelSetting` | Abre configurações de ID de pacote |
| `OpenPackageFinder` | Abre Localizador de Pacotes |
| `OpenEditRetailerDialog` | Abre seletor de varejista |
| `OpenContactDialog` | Abre contato do destinatário |
| `OpenActivityIntent` | Abre app externo (navegação) |
| `OpenStopActivityDialog` | Abre histórico de atividade |
| `ShowBarcodeCopiedToast` | Toast `"Código de barras copiado"` (`barcode_copied`) |
| `DisabledFeature` | Ação bloqueada por plano |

### Style das propriedades

| Valor | Visual |
|---|---|
| `Default` | Texto normal clicável |
| `Placeholder` | Texto desbotado (valor vazio) |
| `Outlined` | Bordado (destaque) |

### Package Photo Attachments

```
PackagePhotoAttachments(
  photos: List<Uri>,
  editEnabled: Boolean,
  addMoreEnabled: Boolean
)
```

### StopSheetDeliveryType

| Valor | Uso |
|---|---|
| `Successful` | Sheet de comprovante de entrega bem-sucedida |
| `Failed` | Sheet de falha na entrega |

### Strings PT-BR — Status de entrega

- `"Entregue"` (`delivered_button`)
- `"Não entregue"` (`failed_button`)
- `"Marcado como entregue"` (`stop_marked_as_delivered`)
- `"Marcada como não realizada"` (`stop_marked_as_failed`)

### Strings PT-BR — Falha

| Motivo | String |
|---|---|
| Não estava em casa | `"Destinatário não estava em casa"` (`failed_not_home_title`) |
| Sem endereço | `"Não encontrei o endereço"` (`failed_no_address_title`) |
| Sem estacionamento | `"Sem estacionamento"` (`failed_no_parking_title`) |
| Sem tempo | `"Sem tempo"` (`failed_no_time_title`) |
| Pagamento não recebido | `"Pagamento não recebido"` (`failed_no_payment`) |
| Pacotes indisponíveis | `"Pacotes indisponíveis"` (`failed_package_not_available_title`) |
| Outro | `"Outro"` (`failed_other_title`) |
| Cliente não estava em casa (coleta) | `"Cliente não estava em casa"` (`failed_picked_up_not_home_title`) |

### Package/Barcode strings

- `"Códigos de barras"` (`stop_package_barcodes`)
- `"Quantidade"` (`stop_package_count`)
- `"Pacote"` (`stop_package_title`)
- `"Localizador de pacotes"` (`package_finder_title`)

### Navegação

- Aberto ao tocar em parada na steplist.
- "Editar parada" → abre `EditStopPage`.
- Back → fecha sheet, retorna para sheet principal.
- Ações de status → fecha sheet com confirmação de resultado.

### Precisa-runtime

- Quais propriedades aparecem para cada tipo de parada (entrega vs. pickup vs. depot).
- Ordem exata das propriedades na lista.
- Comportamento do pager (se há abas dentro do detail sheet).

---

## 18. BreakDetailSheet — sheet de detalhe de pausa

**Propósito:** sheet exibido ao tocar em uma pausa na lista de paradas.
**Classe:** `com.circuit.ui.home.editroute.components.detailsheet.breaks.BreakDetailSheetKt`

### Estrutura

Título: `"Faça uma pausa"` (`break_detail_sheet_title`)

**Campos de informação:**
- Posição: `"Entre as paradas %1$d e %2$d"` (`break_detail_sheet_stops_info`)
  - Variante início: `"Início da rota"` (`break_detail_sheet_stops_info_first`)
  - Variante fim: `"Fim da rota"` (`break_detail_sheet_stops_info_last`)
- Próxima parada: `"Próxima: %1$s"` (`break_detail_sheet_description`)
- Janela de tempo (se configurada): `"Entre %1$s e %2$s"` (`break_in_route_time_window`)

**Badges de status:**
- `"Feita"` (`detail_sheet_badge_break_done`) — estado `break_detail_sheet_break_done_card_title`
- `"Pulada"` (`detail_sheet_badge_break_skipped`) — estado `break_detail_sheet_break_skipped_card_title`

**Botões de ação (TopActions):**
1. `"Pausa feita"` (`break_detail_sheet_done_button`) — marca pausa como realizada.
2. `"Pular pausa"` (`break_detail_sheet_skip_button`) — pula a pausa.
3. `"Editar pausa"` (`break_detail_sheet_edit_button`) → abre `BreakSchedulerPage`.
4. `"Remover pausa"` (`break_detail_sheet_remove_button`) → abre dialog de confirmação.

### Dialog de remoção de pausa

- Título: `"Pausa removida"` (`undo_break_dialog_title`)
- Corpo: `"A pausa será removida durante a próxima reotimização"` (`undo_break_dialog_body`)
- Botão: `"Desfazer remoção de pausa"` (`undo_break_dialog_confirmation_button`)

### Precisa-runtime

- Se os botões de ação aparecem simultaneamente ou mudam conforme o estado (pendente/feita/pulada).

---

## 19. MediaImport — sheet de importação em lote (voz/foto)

**Propósito:** fluxo de importação de múltiplos endereços via gravação de voz ou foto.
**Classe:** `com.circuit.p016ui.home.editroute.mediaimport.MediaImportController` + `MediaImportStopsSheetContent`

### Subcomponentes

- **MediaImportAudioPlayer** — reproduz gravação de áudio capturada.
- **MediaImportActionsController** — edição de endereços da importação.
- **MediaImportStopsSheetContentKt** — sheet de revisão dos stops importados.

### Fluxo de importação de voz (bulk_audio_import_*)

| Etapa | String PT-BR |
|---|---|
| Botão de início | `"Fale vários endereços"` (`bulk_audio_import_button`) |
| Gravando | `"Pode continuar, estamos ouvindo..."` (`bulk_audio_import_message`) |
| Dica | `"Fale endereços e números. Pule os CEPs."` (`bulk_audio_import_tip`) |
| Pausada | `"Pausado.\nToque em Retomar para continuar."` (`bulk_audio_import_pause_message`) |
| Analisando | `"Analisando…"` (`bulk_audio_import_analyzing`) |
| Carregando | `"Carregando…"` (`bulk_audio_import_loading`) |
| Dica carregamento | `"Isso pode levar alguns minutos"` (`bulk_audio_import_uploading_tip`) |

Botões: `"Pausar"` / `"Retomar"` / `"Reiniciar"` (`bulk_audio_import_pause/resume/restart`)

### Dialogs da importação de voz

| Situação | Título | Corpo |
|---|---|---|
| Limite diário atingido | `"Limite de uso alcançado"` | `"Limite diário de importação de áudio alcançado. Tente novamente amanhã."` |
| Falha ao gravar | `"Falha ao gravar"` | `"Algo deu errado ao gravar..."` |
| Falha ao carregar | `"Falha ao carregar"` | `"Não conseguimos carregar sua gravação..."` |
| Cancelar importação | `"Descartar importação?"` | `"Os endereços capturados até agora serão descartados..."` |
| Baixo armazenamento | `"Falta de espaço de armazenamento"` | `"A gravação não pode prosseguir por falta de espaço..."` |
| Reiniciar? | `"Reiniciar?"` | — |

Botão cancelar: `"Descartar importação"` (`bulk_import_cancelation_button`)
Botão manter: `"Não. Continuar."` (`bulk_audio_import_dismiss_button`)

### Fluxo de importação de foto/texto (bulk_import_*)

| Erro | Título | Mensagem |
|---|---|---|
| Erro ao extrair (foto) | `"Algo deu errado"` | `"Ocorreu um erro ao extrair os endereços da foto."` |
| Erro ao extrair (gravação) | `"Algo deu errado"` | `"Ocorreu um erro ao extrair os endereços da gravação."` |
| Nenhum endereço encontrado (foto) | `"Nenhum endereço encontrado"` | `"Não conseguimos extrair nenhum endereço da foto."` |

### Sheet de revisão dos stops importados

Botão de conclusão: `"Pronto"` (`import_complete_button`)
Botão de confirmação (adicionar): `"Adicionar paradas"` (`add_stops_button_title`)

### Dialogs de cancelar/descartar sessão de importação

- **ConfirmCancelMediaImportSessionDialog** — confirmar cancelamento da sessão.
- **ConfirmRemoveMediaImportStopDialog** — confirmar remoção de uma parada da importação.
- **InvalidMediaStopsConfirmationDialogFragment** — paradas com endereços inválidos (endereços não confirmados).
  - Título: `"Não foi possível confirmar os seguintes endereços. Selecione as versões corretas."` (`import_error_cant_find_addresses_title`)

### Navegação

- Ativado pelo botão câmera/microfone no header do MainSheet.
- Conclui → retorna ao shell com paradas adicionadas.
- Cancela → retorna ao shell sem alterações.

### Precisa-runtime

- Se voz e foto compartilham o mesmo sheet de revisão ou são fluxos separados.
- Comportamento exato do `MediaImportStopsSheetContent` (paginação, edição inline).

---

## 20. OptimizationController — enum estrutural

**Propósito:** controlador de otimização; define enums centrais usados por múltiplos componentes.
**Classe:** `com.circuit.ui.home.editroute.optimization.OptimizationController`

### Enum OptimizeType

| Valor | Significado |
|---|---|
| `RESTART_ROUTE` | Reotimizar do zero (todos os stops) |
| `REMAINING_STOPS` | Otimizar apenas stops restantes |
| `SKIP_REORDER` | Pular reordenação (manter ordem atual) |
| `REORDER_FLEXIBLE` | Reordenar com flexibilidade (atualizar) |

### Enum OptimizeDirection

| Valor | Significado |
|---|---|
| `REVERSE` | Inverter direção da rota |

### PackageLabelModeDialogSource

| Valor | Quando |
|---|---|
| `IntroductoryDialog` | Primeira vez que Package Label Mode é ativado |
| `PackageLabel` | A partir das configurações de package label |

### Eventos adicionais do OptimizationController

- `OptimizationStarted` — otimização iniciou.
- `OptimizationFinishedInStopGroupsFlow` — otimização terminou dentro do modo grupos.
- `ShowOptimizationSavedMessage` — toast de sucesso após otimização.
- `OpenPackageLabelModeSettings` — abre configurações de modo de labels.
- `ShowPackageLabelIntroDialog` — dialog introdutório de package labels.

---

## 21. Formatter — RouteStepListGroups (grupos de alterações no Apply Changes)

**Propósito:** agrupa os steps da lista quando a rota está em modo "Aplicar Alterações".
**Classe:** `com.circuit.ui.home.editroute.formatter.RouteStepListGroups$RouteStepGroup`

### Enum RouteStepGroup

| Valor | Significado |
|---|---|
| `Added` | Paradas adicionadas |
| `Edited` | Paradas editadas |
| `Removed` | Paradas removidas |
| `Skipped` | Paradas puladas |
| `Ordered` | Paradas reordenadas |
| `DeleteTransferredStops` | Excluir paradas transferidas |
| `AddTransferredStops` | Paradas recebidas por transferência |

Cada grupo tem um `Comparator<tcc>` para ordenação interna.

### Strings PT-BR — Transferência de paradas

- `"Transferir paradas…"` (`transfer_stops`)
- `"Paradas recebidas"` (`transfer_stops_stoplist_section_received`)
- `"Excluir paradas transferidas"` (`transfer_stops_stoplist_section_delete`)
- `"Esta rota tem alterações que não foram salvas"` (`transfer_stops_unsaved_changes_title`)
- `"Implementar todas as alterações"` (`transfer_stops_unsaved_changes_apply_button_title`)

---

## Sumário de enums críticos

| Enum | Valores |
|---|---|
| `OptimizeType` | `RESTART_ROUTE`, `REMAINING_STOPS`, `SKIP_REORDER`, `REORDER_FLEXIBLE` |
| `OptimizeDirection` | `REVERSE` |
| `MapControllerMode` | `Manual`, `DynamicRouteView`, `NextStepsCluster`, `DynamicActiveStopView`, `StaticStepView`, `FollowMyLocation`, `SelectExactLocation` |
| `MapToolbarFabMode` | `Drawer`, `Close`, `Hidden` |
| `MapToolbarMode` | `Overview`, `Navigation` |
| `SearchBarConfiguration` | `Searching`, `Expanded`, `Collapsed` |
| `InternalNavigationLoadingType` | `Offline`, `FindingDirectionsOnline`, `ReroutingOnline` |
| `InternalNavigationBarAction` | `ActionDisabled`, `OpenNavSettings`, `NavigateToStepList`, `BackToInternalNavigation` |
| `InternalNavigationBarUiModel.SecondaryActionButtonType` | `Settings`, `Navigation`, `Overview` |
| `StopSheetDeliveryType` | `Successful`, `Failed` |
| `RouteStepSheetPropertyUiModel.Style` | `Default`, `Placeholder`, `Outlined` |
| `RouteStepListGroups$RouteStepGroup` | `Added`, `Edited`, `Removed`, `Skipped`, `Ordered`, `DeleteTransferredStops`, `AddTransferredStops` |
| `CriticalInfoIcon` | `Pickup`, `PackageCount` |

---

## Notas para implementação RotPro

- **B2B flags a cortar:** `copy_stops` (reutilizar paradas entre rotas), `transfer_stops` (transferência entre motoristas), `more_options_print_route_title` (impressão de rota). Verificar runtime se aparecem no B2C.
- **Package Label Mode:** usar `PackageLabelMode.NONE` por padrão (sem escaneamento); os dialogs de lock/intro são reais mas ligados a esta feature.
- **MediaImport:** a importação por voz (bulk_audio) requer serviço de transcrição de fala; a de foto/planilha requer OCR. Scope da Slice 3 (backend real).
- **InternalNavigation:** requer Google Navigation SDK licenciado. Na Slice 2, o shell mostra a barra mas delega a navegação ao app de mapas externo.
- **StopGroup / OrderStopGroups:** lógica de desenho de polígono freehand no mapa — usar `GestureDetector` + `Compose Canvas` para a Slice 2.
