# Front blueprint — home-shell-map

**Data:** 2026-06-21
**Fonte:** `jadx-out/sources/com/circuit/p016ui/home/` (pacotes: raiz, `drawer/`, `dialogs/`, `editroute/map/`, `editroute/components/mainsheet/`, `editroute/components/mainsheet/header/`)
**Escopo:** Shell da rota ativa (mapa + sheet arrastável + controles do mapa + drawer lateral). Exclui `editroute/steplist` e `editroute/components/detailsheet` (telas de parada individual — blueprints separados).

---

## 1. HomeFragment (shell raiz)

**Propósito:** Fragment único que hospeda o drawer lateral + o conteúdo de rota ativa (mapa + sheet). Ponto de entrada da tela principal.
**Classe:** `com.circuit.ui.home.HomeFragment` (compilado de `HomeFragment.kt`)

### Estrutura
- `DrawerLayout` envolvendo tudo.
  - Conteúdo principal: `EditRouteFragment` (mapa + sheet).
  - Conteúdo lateral (gaveta): `RoutesDrawerContent` (lista de rotas + cabeçalho de perfil).
- Escuta `HomeEvent` do `HomeViewModel` e `DrawerEvent` do `DrawerViewModel`.

### Navegação
- **Abre este Fragment:** boot do app após login.
- **Abre a partir daqui:** `RouteCreateArgs` (criar nova rota), telas de configurações, telas de assinatura/upgrade.
- **Drawer:** aberto por botão FAB (modo `Drawer`) ou gesto de swipe da borda esquerda.

### Estados / variações
- Sem rota ativa → vazio, aguarda criação.
- Com rota ativa → exibe `EditRouteFragment`.
- Drawer aberto / fechado.

### HomeEvent (eventos tratados em HomeFragment)
| Evento (nome decompilado) | Significado |
|---|---|
| `ShowRouteChangedDialog` | Rota distribuída ou atualizada pelo despachante — tipo `Distributed` ou `Updated` |
| `AskAboutImport` (`C3362a`) | Confirmação de importação de rota |
| `OpenDrawer` (`C3364c`) | Abre o drawer |
| `ShowAppUpdate` (`C3365d`) | Atualização do app (forçada ou opcional) |
| `ShowFailedToImportDialog` (`C3366e`) | Falha na importação |
| `ShowLocationRequired` (`C3368g`) | Localização não concedida |
| `ShowMissingDriverRole` (`C3369h`) | Usuário sem papel de motorista |
| `ShowPermissionDenied` (`C3371j`) | Permissão negada com botão de retry |
| `ShowSubscriptionWarning` (`C3373l`) | Assinatura expirada/necessária |
| `StartCreateRoute` (`C3376o`) | Inicia fluxo de criação de rota |

### Precisa-runtime
- Animação de abertura/fechamento do drawer.
- Comportamento do drawer quando a tela é rotacionada (tablet vs phone).

---

## 2. EditRouteFragment / Shell de rota ativa

**Propósito:** Fragment que compõe mapa + sheet arrastável num `Column` (não `Stack`) — o mapa ocupa o espaço acima, o sheet cresce de baixo diminuindo o mapa (padrão Spoke confirmado via jadx profundo `kr4.java`).
**Classe:** `com.circuit.ui.home.editroute.EditRouteFragment`

### Estrutura de layout
```
Column {
  Box(weight = 1f) {          // mapa — ocupa espaço restante
    EditRouteMap(...)
    MapToolbars(...)           // controles flutuantes sobre o mapa
  }
  VerticalDraggableSheet {    // sheet — empurra o mapa para cima
    DragHandle
    MainSheetContent(...)
  }
}
```

### Altura do sheet (DraggableSheetPosition)
| Posição | Ordinal | Altura padrão |
|---|---|---|
| `Collapsed` | 0 | Apenas alça visível |
| `Default` | 1 | `screenHeight * 0.5` (50%) — âncora padrão ao abrir |
| `Expanded` | 2 | Quase tela inteira |

**Default ao entrar na rota ativa:** `Default` (50%). Implementado via `initState` no `onResume`/`LaunchedEffect`.

### Snap (direção de arraste)
- Arraste para cima → próxima posição maior.
- Arraste para baixo → próxima posição menor.
- Sem flick (velocidade < 50 px/s) → posição mais próxima.

### EditRoutePage (telas dentro do shell — controlam o conteúdo do sheet)
| Página | Quando ativa |
|---|---|
| `Loading` | Rota carregando |
| `SetupLocations` | Configurar início/destino |
| `Stops` | Lista de paradas (estado principal da rota) |
| `Search` | Busca de endereço para nova parada |
| `RouteStepDetails` / `StopDetails` / `BreakDetails` | Detalhe de parada ou pausa |
| `SelectExactLocation` | Overlay de ajuste manual de pin no mapa |
| `OrderStopGroups` / `DrawingOrderStopGroups` / `ConfirmOrderStopGroups` / `ReoptimizeOrderStopGroups` / `OrderStopGroupsExplainer` | Fluxo de ordenação manual por grupos |
| `MediaImportStops` | Importação por câmera/voz |

---

## 3. EditRouteMap (componente de mapa)

**Propósito:** Mapa Google Maps (NavigationView) que exibe a rota, markers de paradas e controles flutuantes.
**Classe:** `com.circuit.ui.home.editroute.map.EditRouteMapKt` (Kotlin Composable `EditRouteMap` / `EditRouteMapInternal`)

### Estrutura visual sobre o mapa (de cima para baixo, da esquerda para direita)
1. **Botão FAB (topo-esquerda)** — modo `Drawer` (ícone menu) ou `Close` (ícone fechar) ou `Hidden` (invisível).
2. **Barra de navegação interna (topo, largo)** — presente durante `InternalNavigation` (Navegação do Spoke). Ver §5.
3. **Botões de toggle (topo-direita)** — visíveis quando `toggleButtonsVisible = true`:
   - Botão tipo de mapa (DEFAULT ↔ HYBRID/satélite).
   - Botão de modo de câmera (follow / overview).
4. **Toast de ação do mapa (flutuante centralizado)** — surgem temporariamente ao mudar modo. Ver §6.
5. **Overlay de pin flutuante** — visível quando `EditRoutePage = SelectExactLocation`. Ver §7.
6. **Markers de paradas** — renderizados como bitmap com label. Ver §8.
7. **Polyline da rota** — linha sobre o mapa.

### MapControllerMode (modo da câmera do mapa)
| Modo | Descrição |
|---|---|
| `Manual` | Usuário controlou o mapa; câmera livre |
| `DynamicRouteView` | Câmera mostra rota completa |
| `DynamicActiveStopView` | Câmera centralizada na parada ativa |
| `NextStepsCluster` | Câmera agrupa próximas paradas |
| `StaticStepView(stepId)` | Câmera fixa numa parada específica |
| `FollowMyLocation` | Câmera segue GPS |
| `SelectExactLocation` | Modo overlay de pin |

**`isDynamic()`** → `true` para `DynamicRouteView`, `DynamicActiveStopView`, `NextStepsCluster`.

### MapType (tipo do mapa)
| Valor | Mapa Google |
|---|---|
| `DEFAULT` | Mapa normal (ruas) |
| `HYBRID` | Satélite com ruas |

### MapToolbarMode
| Modo | Descrição |
|---|---|
| `Overview` | Visão geral da rota (padrão fora de navegação) |
| `Navigation` | Modo navegação ativa (InternalNavigation) |

### MapToolbarFabMode
| Modo | FAB visível | Ícone |
|---|---|---|
| `Drawer` | Sim | Menu hambúrguer → abre drawer |
| `Close` | Sim | X → fecha fluxo ativo (ex.: SelectExactLocation) |
| `Hidden` | Não | — |

**Default:** `Drawer`, `fabEnabled = true`, `toggleButtonsVisible = true`.

### MapToolbarControlsState (estado do toolbar)
Campos: `fabMode: MapToolbarFabMode`, `fabEnabled: Boolean`, `toggleButtonsVisible: Boolean`.

### Flows que sobrescrevem o toolbar
Stack-based controller (`MapToolbarControlsController`):
- `OrderGroup` flow → sobrescreve para `Close` sem toggle.
- `SelectExactLocation` flow → sobrescreve para `Close` sem toggle.
Ao sair do flow, restaura o estado anterior.

### Ícones de drawable → Lucide sugerido
| Função | Drawable Spoke (inferido) | Lucide RotPro |
|---|---|---|
| FAB — menu | ic_menu / hamburger | `Menu` |
| FAB — fechar | ic_close | `X` |
| Satélite ativo | ic_satellite / ic_layers | `Layers` |
| Satélite inativo | ic_map | `Map` |
| Seguir localização | ic_my_location / ic_gps_fixed | `Navigation` |
| Overview (rota completa) | ic_route / ic_directions | `Route` |

### Precisa-runtime
- Threshold de velocidade de flick para snap (observado visualmente: ~50 px/s).
- Animações de câmera (`CameraAnimationSpeed`).
- Comportamento do mapa quando sheet está em `Expanded` (padding inferior do mapa).

---

## 4. MainSheet — Estrutura do sheet arrastável

**Propósito:** Sheet arrastável que contém cabeçalho de busca + lista de paradas + rodapé de ações.
**Classe:** `com.circuit.ui.home.editroute.components.mainsheet.C3550h` (SheetContent.kt)

### Estrutura interna (de cima para baixo)
1. **DragHandle** — alça de arraste (pill/retângulo central no topo do sheet). Dois tipos: `DragHandle.Top` (alça simples) ou `DragHandle.Bottom` (alça diferenciada — usado em algum modo).
2. **MainSheetHeader** — barra de busca + título da rota + ações. Ver §4a.
3. **MainSheetContent** (AnimatedContent por `EditRoutePage`):
   - `Stops` → `StepsPage` (lista de paradas via `RouteStepList`).
   - `Search` → `SearchScreen` (resultados de busca).
   - Outros → conteúdo dedicado.
4. **MainSheetFooter** — ações na parte inferior do sheet. Ver §4b.

---

## 4a. MainSheetHeader (cabeçalho do sheet)

**Propósito:** Barra de busca + controles de nome de rota + indicadores de status.
**Classe:** `com.circuit.ui.home.editroute.components.mainsheet.MainSheetHeaderKt`

### SearchBarConfiguration (estado da barra de busca)
| Estado | Quando ativo |
|---|---|
| `Searching` | `EditRoutePage = Search` (barra expandida em modo busca) |
| `Expanded` | Sheet em `Default` ou `Expanded` sem busca ativa + rota não compartilhada |
| `Collapsed` | Sheet em `Collapsed`, ou tablet landscape, ou rota compartilhada |

### Campos e controles do cabeçalho (quando `Expanded`)
1. **Campo de busca** — placeholder: `"Insira um endereço"` (string `add_stop_placeholder`).
2. **Título / nome da rota** — clicável para renomear.
3. **Badge "Otimização pendente"** — string: `"Otimização pendente"` (`optimization_pending_button_title`). Visível quando `hasOptimizationPending = true` E sheet não está em `Expanded`.
4. **Botão kebab (3 pontos)** — abre `RouteMenuActionsDialog`. Ver §9.
5. **Indicador de rota não otimizada** — quando rota nunca foi otimizada.
6. **Botão de paradas com problema** (`onAddressesWithIssuesClick`) — visível quando há endereços inválidos.

### Campos do cabeçalho (quando `Searching`)
1. **Campo de busca ativo** com foco + botão de cancelar/limpar.
2. Placeholder: `"Insira um endereço"`.

### Ações do cabeçalho ligadas ao ViewModel
| Callback | Ação |
|---|---|
| `onQueryChanged` | Atualiza busca de endereço |
| `onOptimizationPendingWarningClick` | Toca no badge de otimização pendente |
| `onEditRouteSetupClick` | Abre configuração da rota (início/destino) |
| `onShareProgressClick(FeatureStatus)` | Compartilha progresso (feature-gated) |
| `onLoadVehicleClick(FeatureStatus)` | Carrega veículo (feature-gated) |
| `onMakeNextClearClick` | Limpa próxima parada |
| `onAddressesWithIssuesClick` | Acessa paradas com endereço problemático |
| `onCancelTransferStopsClick` | Cancela transferência de paradas em andamento |

### Precisa-runtime
- Animação de transição entre `Searching`, `Expanded` e `Collapsed`.
- Comportamento do campo de busca com foco automático ao entrar em `Search`.

---

## 4b. MainSheetFooter (rodapé do sheet)

**Propósito:** Ações primárias da rota exibidas na parte inferior do sheet.
**Classe:** `com.circuit.ui.home.editroute.components.mainsheet.MainSheetFooterKt`

### Botões (ordem de exibição da esq. para dir., conforme `EditRoutePage = Stops`)

| Botão | String PT-BR | Visível quando |
|---|---|---|
| **Otimizar rota** (primário) | `"Otimizar rota"` (`stops_optimize_button_title`) | Rota não otimizada e tem paradas suficientes |
| **Refinar** (secundário) | `"Refinar"` (`refine_route_button_title`) | Rota já otimizada |
| **Adicionar paradas** | `"Adicionar paradas"` (`add_stops_button_title`) | Sempre |
| **Iniciar antes…** | `"Iniciar antes…"` (`start_route_early_button`) | Quando há horário agendado de início |
| **Carregar veículo** | `"Carregar veículo"` (`load_vehicle_button_title`) | Feature-gated |
| **Compartilhar progresso** | (via `onShareProgressClick`) | Feature-gated |

**Observação:** Os lambdas 3..17 no decompilado correspondem a diferentes combinações de estado — o botão principal muda conforme `optimizationState`. O botão "Refinar" abre `RefineRouteDialog` (ver §10); o kebab "Reotimizar rota..." abre `ReoptimizeOptionsSheet` (fluxo separado — ADR-0007/Á7).

### Precisa-runtime
- Qual combinação exata de botões aparece quando rota está `Em andamento` (vs. não iniciada vs. concluída).
- Ordem de exibição no rodapé (primário à direita ou esquerda).

---

## 5. InternalNavigationBar (barra de navegação interna)

**Propósito:** Barra de navegação turn-by-turn do Spoke (powered by Google Navigation SDK) exibida no topo do mapa durante `MapToolbarMode = Navigation`.
**Classe:** `com.circuit.ui.home.editroute.map.InternalNavigationBarUiModel` + `InternalNavigationBarKt`

### Estrutura da barra
```
Row {
  [Seção info primária]   // manobra + distância + parada destino
  [Botão secundário]      // Settings | Navigation | Overview
}
```

### InternalNavigationBarUiModel
| Campo | Tipo | Descrição |
|---|---|---|
| `infoSectionContentModel` | `InterfaceC3613a` | Conteúdo da seção de info (ver abaixo) |
| `secondaryActionButtonType` | `SecondaryActionButtonType` | Botão direito da barra |
| `mapToolbarMode` | `MapToolbarMode` | `Overview` ou `Navigation` |
| `infoSectionClickAction` | `InternalNavigationBarAction` | O que acontece ao tocar na seção de info |

### Conteúdo da seção de info (union type)
| Tipo | Campos | Quando |
|---|---|---|
| `ActiveNavigation` | `primaryInfo: String`, `secondaryInfoModel`, `navigatingToStopId` | Navegando ativamente |
| `ActiveNavigationLoading(loadingType)` | `loadingType: InternalNavigationLoadingType` | Carregando rota |

### InternalNavigationLoadingType
- `Offline` — sem conexão.
- `FindingDirectionsOnline` — buscando direções.
- `ReroutingOnline` — recalculando rota.

### SecondaryInfoModel (sub-union)
| Tipo | Campos | Quando |
|---|---|---|
| `CriticalInfo` | `content(primaryText, secondaryText?)`, `color: StopColor`, `icon: CriticalInfoIcon` | Alerta crítico na parada |
| `EtaInfo` | `secondaryTimeInfo: String`, `remainingDistance: String` | ETA normal |
| `OutOfOrder` | `message` | Parada fora de ordem |

### SecondaryActionButtonType
| Valor | Ação ao tocar |
|---|---|
| `Settings` → `OpenNavSettings` | Abre configurações de navegação |
| `Navigation` → `BackToInternalNavigation` | Retorna à navegação ativa |
| `Overview` → `NavigateToStepList` | Vai para lista de paradas |

**Default:** `secondaryActionButtonType = Overview`, `mapToolbarMode = Navigation`, `infoSectionClickAction = ActionDisabled`.

### InternalNavigationBarAction (ação ao tocar na seção de info)
- `ActionDisabled` — toque não faz nada.
- `OpenNavSettings` — abre configurações.
- `NavigateToStepList` — vai para lista de paradas.
- `BackToInternalNavigation` — retorna à navegação.

### Strings PT-BR
- `"Navegação do Spoke"` (`circuit_internal_navigation`) — label da feature.
- `"Chegando à parada %1$d"` (`internal_navigation_arriving_stop`) — info ao chegar.
- `"Destino"` (`internal_navigation_arriving_end`) — ao chegar ao destino final.
- `"Centralizar"` (`in_app_nav_terms_recenter_button_title`) — botão de re-centralizar.

### Ícones → Lucide sugerido
| Função | Lucide |
|---|---|
| Configurações de navegação | `Settings` |
| Voltar à navegação | `Navigation` |
| Ir para lista | `List` |

### Precisa-runtime
- Formato exato da string `primaryInfo` (distância + rua).
- Animações de manobra (ícone de curva/reto).
- Comportamento da barra quando conexão cai (transição para `Offline`).

---

## 6. MapActionToast (toast de ação do mapa)

**Propósito:** Toast flutuante (aparece sobre o mapa) que confirma mudanças de modo feitas pelos botões de toggle.
**Classe:** `com.circuit.ui.home.editroute.map.MapActionToastController`

### Strings PT-BR (verbatim)
| Ação | String |
|---|---|
| Câmera segue localização | `"Seguir"` (`map_action_toast_follow`) |
| Rota completa em vista | `"Rota completa"` (`map_action_toast_full_route`) |
| Foca próxima parada | `"Próxima parada"` (`map_action_toast_next_stop`) |
| Satélite desativado | `"Satélite desativado"` (`map_action_toast_satellite_off`) |
| Satélite ativado | `"Satélite ativado"` (`map_action_toast_satellite_on`) |
| Foca pausa ativa | `"Pausa"` (`map_action_toast_static_break`) |
| Foca parada ativa | `"Parada"` (`map_action_toast_static_stop`) |
| Próximas paradas em cluster | `"Próximas paradas"` (`map_action_toast_upcoming_stops`) |

### Comportamento
- Exibido por coroutine com cancel do anterior (não fila). Duração: confirmada como 3 s no PR-B2 (Á7) do RotPro.
- Posição: central-superior, acima do sheet (floating).

### Precisa-runtime
- Posição exata do toast (distância do topo / do sheet).

---

## 7. SelectExactLocationMapOverlay (overlay de pin flutuante)

**Propósito:** Overlay ativado quando `EditRoutePage = SelectExactLocation`. Exibe um pin centralizado na tela que o usuário arrasta para ajustar a localização exata de uma parada.
**Classe:** `com.circuit.ui.home.editroute.map.toolbars.SelectExactLocationMapOverlayKt` + `SelectExactLocationUiModel`

### Estrutura
```
Box {
  [FloatingPin no centro da tela]  // pin que segue o centro do mapa
  [Botão "Ajustar localização"]    // bottom-center
}
```

### Strings PT-BR
- Pin em arraste: `"Arraste para definir a localização"` (`drag_to_set_location`).
- Botão de confirmação: `"Ajustar localização"` (`adjust_pin_location_button`).
- (Também: `"Editar localização"` — `UBI_sheet_action_adjust_pin` — versão alternativa para contexto de importação).

### FAB neste modo
- `MapToolbarFabMode = Close` (botão X cancela o overlay).
- `toggleButtonsVisible = false`.

### Precisa-runtime
- Animação do pin ao soltar (rebote).
- Comportamento quando mapa é pan-eado vs. pin fixo.

---

## 8. StopMarkerLabel (markers de parada no mapa)

**Propósito:** Markers customizados desenhados como Bitmap e colocados no `GoogleMap` via `BitmapDescriptor`.
**Classe:** `com.circuit.map.labels.StopMarkerLabel` + `StopMarkerLabelOverlayKt`

### Campos do StopMarkerLabel
| Campo | Tipo | Descrição |
|---|---|---|
| `stepId` | `DefaultStopId` | ID da parada |
| `position` | `LatLng` | Coordenadas |
| `status` | `Status` | Status visual |
| `icon` | `Icon` | Ícone sobre o marker |
| `primaryText` | `String` | Número da parada ou texto principal |
| `secondaryText` | `String` | Texto secundário |
| `tertiaryText` | `String` | Texto terciário (ex.: horário) |
| `quaternaryText` | `String` | Texto quaternário |
| `markerSize` | `MarkerSize` | Tamanho baseado no zoom |

### StopMarkerLabel.Icon
- `Check` — parada concluída.
- `Cross` — parada com falha/pulada.
- `None` — parada pendente.

### StopMarkerLabel.Status (enum inferido do campo)
Controla o visual do marker (cor do fundo, borda). Precisa-runtime para valores exatos.

### StopMarkerLabel.MarkerSize (4 breakpoints por zoom)
| Enum | largura px | altura px |
|---|---|---|
| `Size1` | 22 | 27 |
| `Size2` | 27 | 32 |
| `Size3` | 32 | 38 |
| `Size4` | 38 | 47 |

**Âncora:** `(0.5, 1.0)` — base centralizada no pin (base-center). `imagePixelRatio = devicePixelRatio` obrigatório.

### StopMarkerLabelContext.MapStyle
- `Light` — mapa normal (claro).
- `Dark` — mapa escuro.
- `Satellite` — mapa satélite.

### StopMarkerLabelIcon (ícone no overlay de label, interno)
- `Check` — ícone de check.
- `Cross` — ícone de X.

### Precisa-runtime
- Thresholds de zoom exatos que mapeiam para `Size1`..`Size4`.
- Cores de fundo do marker por status (`StopColor`).
- Forma do marker: gota vs. círculo (pins de Á8 futura planejados como gota+número per memória `project_status_colored_pins_area8.md`).

---

## 9. RouteMenuActionsDialog (menu kebab da rota)

**Propósito:** Diálogo de ações avançadas da rota ativa, aberto pelo botão kebab (3 pontos) no cabeçalho do sheet.
**Classe:** `com.circuit.ui.home.editroute.components.mainsheet.RouteMenuActionsDialog` (extends `AdaptiveModalDialog`)

### Estrutura
- Lista de itens de ação (`List<AbstractC3737w>`), cada um com título e estado (feature-gated via `FeatureStatus`).
- Tamanho adaptativo: `AdaptiveModalSize.Small`.

### Itens do menu (strings PT-BR verbatim)
| Ordem | String | Chave |
|---|---|---|
| 1 | `"Reotimizar rota..."` | `more_options_reoptimize_route_title` |
| 2 | `"Copiar paradas..."` | `more_options_copy_stops_title` |
| 3 | `"Remover paradas..."` | `more_options_remove_stops_title` |
| 4 | `"Imprimir rota"` | `more_options_print_route_title` |
| 5 | `"Compartilhar cópia da rota"` | `more_options_share_route_title` |
| 6 | `"Redefinir IDs de parada..."` | `more_options_reset_package_identification` |
| 7 | `"Pular otimização"` | `more_options_skip_optimization_title` |
| 8 | `"Transferir paradas…"` | `transfer_stops` |

**Nota B2C:** `"Transferir paradas"` e `"Pular otimização"` são features gated. `"Reotimizar rota..."` (kebab) abre `ReoptimizeOptionsSheet` — distinto de `"Refinar"` (footer) que abre `RefineRouteDialog` (ADR-0007/Á7, memória `lesson_area7_refinar_vs_reotimizar_two_dialogs.md`).

### Navegação
- Aberto por: botão kebab no `MainSheetHeader`.
- Ações resultam em: fechar o diálogo + disparar ação correspondente no `EditRouteViewModel`.

### Precisa-runtime
- Quais itens aparecem para usuário B2C free vs. pago.
- Ordem definitiva (pode variar por estado da rota).

---

## 10. RefineRouteDialog ("Refinar a rota")

**Propósito:** Diálogo aberto pelo botão `"Refinar"` no rodapé do sheet (não pelo kebab). Oferece duas opções de refinamento manual.
**Strings PT-BR (verbatim):**
- Título: `"Refinar a rota"` (`refine_route_dialog_title`).
- Opção 1 — título: `"Inverter a rota"` (`refine_route_dialog_reverse_title`), descrição: `"Inverter a direção da rota"` (`refine_route_dialog_reverse_description`).
- Opção 2 — título: `"Ordenar a rota manualmente"` (`refine_route_dialog_manual_title`), descrição: `"Definir a ordem da rota desenhando no mapa"` (`refine_route_dialog_manual_description`).
- Botão no rodapé do sheet: `"Refinar"` (`refine_route_button_title`).

### Navegação
- Aberto por: botão `"Refinar"` no `MainSheetFooter`.
- "Ordenar a rota manualmente" → abre fluxo `DrawingOrderStopGroups` (mapa de desenho).
- "Inverter a rota" → aplica inversão e fecha.

---

## 11. RoutesDrawerContent (gaveta lateral — lista de rotas)

**Propósito:** Conteúdo do `DrawerLayout` à esquerda. Lista de rotas do usuário agrupadas por data + cabeçalho de perfil.
**Classe:** `com.circuit.ui.home.drawer.RoutesDrawerContentKt`

### Estrutura (de cima para baixo)
1. **DrawerHeader** — perfil do usuário. Ver §11a.
2. **Lista de rotas** — agrupadas por data (hoje, amanhã, datas passadas/futuras).
3. **Botão "Criar nova rota"** — string: `"Criar nova rota"` (`create_new_route_button`).
4. **Botão de Configurações** — string: `"Configurações"` (`drawer_settings_action_title`).
5. **Botão de Ajuda** — string: (via Intercom/Help).

### Estado vazio
- String: `"Ainda não há rotas"` (`routes_drawer_today_empty`).

### Item de rota na lista
- Nome da rota (padrão primeira rota: `"Minha primeira rota"` — `first_route_name`).
- Data formatada (hoje: `"Hoje"` / amanhã: `"Amanhã"` / outras: data local).
- Ações no item: swipe ou long-press para `"Excluir rota"` / `"Duplicar rota"`.

### DrawerEvent (ações no drawer)
| Evento | Descrição |
|---|---|
| `NavigateToSetNameAndDate` (`C3407a`) | Toque num item de rota → vai para editar nome/data |
| `ShowConfirmDeleteRoute` (`C3408b`) | Confirma exclusão |
| `LaunchDuplicateDialogFlow` | Duplicar (KeepProgress / DiscardProgress) |
| `Toast` (`C3409c`) | Toast genérico de erro/ação |

### DrawerHeaderColor
- `Green` — padrão B2C (usuário pessoal).
- `Blue` — equipe/B2B (irrelevante para RotPro B2C).

---

## 11a. DrawerHeader (cabeçalho do drawer)

**Propósito:** Área de perfil no topo do drawer.
**Classe:** `com.circuit.ui.home.drawer.DrawerHeaderUiModel`

### Campos
| Campo | Tipo | Descrição |
|---|---|---|
| `firstLine` | `String` | Nome do usuário ou organização |
| `icon` | `Uri` | Avatar/foto de perfil |
| `secondaryLine` | `String` | Email ou papel |
| `tertiaryLine` | `String` | Info adicional (ex.: plano) |
| `backgroundColor` | `DrawerHeaderColor` | `Green` (B2C) / `Blue` (B2B) |
| `profileCard` | `AbstractC3416b` | Card de perfil (pode ser null) |
| `subscribeButton` | `SubscribeButton?` | Botão de assinatura (nullable) |

### Strings do cabeçalho
- Botão assinar: `"Assinar"` (`drawer_header_subscribe_button_text`).
- Botão renovar: `"Renovar"` (`drawer_header_renew_button_text`).
- Botão upgrade: `"Fazer upgrade"` (`drawer_header_upgrade_button`).

### DrawerHeaderEvent
- `SubscribeButtonClicked` — clique no botão de assinatura/upgrade.
- `HelpSubMenuClicked` — clique em ajuda.

---

## 12. RouteChangedDialog (diálogo de rota atualizada)

**Propósito:** Diálogo que aparece quando o despachante atualizou ou distribuiu uma nova rota para o motorista.
**Classe:** `com.circuit.ui.home.dialogs.RouteChangedDialog`

### Estrutura
- Tamanho: `AdaptiveModalSize.Small`.
- Tipo `Distributed` → nova rota recebida.
- Tipo `Updated` → rota existente atualizada.

### Strings PT-BR
| Campo | String |
|---|---|
| Nova rota — título | `"Nova rota para hoje"` (`new_route_dialog_title`) |
| Nova rota — botão principal | `"Abrir rota agora"` (`new_route_received_dialog_button`) |
| Nova rota — botão secundário | `"Depois"` (`new_route_received_dialog_cancel`) |
| Rota atualizada — título | `"Rota atualizada: %1$s"` (`route_update_received_dialog_title`) |
| Recebido agora | `"Recebido agora."` (`new_route_received_dialog_received_now`) |
| Recebido em hora | `"Recebido: %1$s."` (`new_route_received_dialog_received_time`) |
| Salvo no dispositivo | `"Salvo no seu dispositivo."` (`new_route_received_dialog_saved`) |

### Navegação
- `isStartToday: Boolean` — indica se a rota é para hoje.
- Botão "Abrir rota agora" → abre a rota recebida.
- Botão "Depois" → dispensa o diálogo.

**Contexto RotPro:** Este diálogo é Spoke-B2B (despachante → motorista). Para RotPro B2C (sem despachante), este fluxo **[B2B — cortar para a Slice 2]**; manter apenas se/quando implementar backend com push.

---

## 13. AskUserDeleteDialog (confirmação de exclusão de rota)

**Propósito:** Confirmação antes de excluir uma rota.
**Classe:** `com.circuit.ui.home.dialogs.AskUserDeleteDialog`

### Strings PT-BR
- Título: `"Quer mesmo excluir %1$s?"` (`are_you_sure_you_want_to_delete`).
- Botão confirmar: `"Excluir"` (`delete_route_button_title`).
- Botão cancelar: padrão (não há string dedicada encontrada no dump — provavelmente "Cancelar").

---

## 14. AskUserImportDialog (confirmação de importação)

**Propósito:** Confirma a importação de uma rota recebida por link/share.
**Classe:** `com.circuit.ui.home.dialogs.AskUserImportDialog`

**Contexto RotPro:** **[B2B — avaliar]** — importação de rotas compartilhadas é B2C também (link de compartilhamento). Manter se RotPro suportar importação via link.

---

## 15. DuplicateRouteDialog (fluxo de duplicar rota)

**Propósito:** Diálogo que pergunta se mantém ou descarta o progresso ao duplicar uma rota.
**Classe:** Disparado por `DrawerEvent.LaunchDuplicateDialogFlow`

### Strings PT-BR
| Opção | Título | Descrição |
|---|---|---|
| `KeepProgress` | `"Manter progresso da rota"` | `"As paradas feitas continuarão na rota copiada."` |
| `DiscardProgress` | `"Redefinir progresso da rota"` | `"As paradas feitas serão marcadas como não feitas na rota copiada."` |

---

## Resumo de Precisa-runtime por componente

| Componente | O que falta do dump |
|---|---|
| Sheet snap | Velocidade de flick exata e animação |
| Markers | Zoom thresholds para MarkerSize 1..4; cores de status |
| InternalNavigation | Formato de string de manobra; animação de ícone |
| MainSheetFooter | Combinações exatas de botões por estado de rota |
| SelectExactLocation | Animação do pin ao soltar |
| DrawerHeader | Comportamento do card de perfil clicável |
| RouteChangedDialog | Conteúdo exato quando `type = Updated` (campos mostrados) |
