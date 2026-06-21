# Front blueprint — home-drawer-routelist

**Data:** 2026-06-21
**Fonte:** jadx decompilado de Spoke v3.65.1 (Pairip-ofuscado)
**Pacote principal:** `com.circuit.ui.home` + `com.circuit.ui.home.drawer` + `com.circuit.ui.create`
**Escopo:** drawer lateral (menu hambúrguer), lista de rotas agrupada por data, header do drawer, criação de rota, diálogos de confirmação de delete/duplicate/import/route-changed.

---

## 1. HomeFragment — Tela raiz do home

**Propósito:** Fragment raiz que hospeda o `ModalNavigationDrawer` do Material 3 + conteúdo principal (mapa + sheet de rota ativa). Gerencia abertura/fechamento do drawer e roteia `DrawerEvent` e `HomeEvent`.
**Classe:** `com.circuit.ui.home.HomeFragment` (compilado de `HomeFragment.kt`)
**ViewModel:** `HomeViewModel`, `DrawerViewModel`, `RecordingUiViewModel`

### Estrutura

- `ModalNavigationDrawer` (`DrawerValue`: `Closed` / `Open`)
  - `drawerContent`: `RoutesDrawerContent` (ver §3)
  - `content`: conteúdo principal (mapa + shell da rota)
- Drawer abre via evento `HomeEvent.OpenDrawer` (singleton `C3364c`)
- Drawer fecha ao selecionar uma rota ou via gesto de swipe

### Strings PT-BR relevantes

- `"Fechar menu de navegação"` (key `close_drawer`) — accessibility label do drawer fechado
- `"Abrir gaveta de navegação"` (key `nav_app_bar_open_drawer_description`) — accessibility label do botão hambúrguer

### Navegação

- **Abre via:** botão hambúrguer no topo da tela de rota ativa (qualquer estado)
- **Fecha via:** toque fora do drawer, gesto de swipe para esquerda, seleção de rota

### HomeEvent — tipos

| Evento | Ação resultante |
|---|---|
| `OpenDrawer` | Abre o `ModalNavigationDrawer` |
| `StartCreateRoute` | Navega para `RouteCreateFragment` (args: `NewRoute`) |
| `ShowSubscriptionWarning(required, switchToTeam)` | Exibe dialog de assinatura exigida |
| `ShowMissingDriverRole(accountName, showSwitchToPersonalButton)` | Dialog sem papel de motorista |
| `ShowTeamTrialExpired(showSwitchToPersonalButton, accountName)` | Dialog trial de equipe expirado |
| `ShowLocationRequired` | Navega para tela de permissão de localização |
| `ShowPermissionDenied(retry)` | Dialog de permissão negada |
| `ShowPushMessage(genericMessage)` | Notificação push genérica em tela |
| `ShowSurvey(surveyType)` | Abre tela de pesquisa de satisfação |
| `AskAboutImport(name, confirmed)` | Dialog de importação (ver §8) |
| `ShowAppUpdate(forced, intent)` | Dialog de atualização do app |
| `ShowFailedToImportDialog` | Dialog de falha de importação |
| `ShowJoinedTeam` | Toast/dialog de ingresso em equipe |
| `ShowRouteChangedDialog(route, type, isStartToday, confirmed)` | Dialog de rota alterada (ver §9) |
| `CancelAppUpdateDialog` | Fecha dialog de update |

### Precisa-runtime

- Comportamento exato do swipe-to-close (velocidade de disparo, snap)
- Aparência do overlay semitransparente sobre o mapa ao abrir o drawer

---

## 2. DrawerViewModel — Estado do drawer

**Propósito:** Mantém o `DrawerUiState` reativo para o `RoutesDrawerContent`.
**Classe:** `com.circuit.ui.home.drawer.DrawerViewModel`

### DrawerUiState (`C3417c`)

```
DrawerUiState(
  routes: List<DrawerRouteGroup>,    // lista agrupada por data
  activeRouteId: RouteId?,           // rota atualmente selecionada
  stickyButtons: DrawerStickyButtons(showCreateRoute: Boolean),
  header: DrawerHeaderUiModel
)
```

**Default:** routes=vazio, activeRouteId=null, stickyButtons(showCreateRoute=true), header com todos os campos null/default.

### DrawerRouteGroup (`wz5`)

```
DrawerRouteGroup(
  title: StringResource,    // string localizada do grupo (ex.: "Hoje", "Próximas rotas")
  routes: ArrayList<DrawerRouteUiModel>,
  showCreateRoute: Boolean  // true APENAS no grupo "Hoje" quando a lista está vazia E o usuário tem permissão CreateRoute
)
```

### DrawerRouteUiModel (`yz5`)

```
DrawerRouteUiModel(
  route: Route,           // entidade da rota
  formattedDate: String,  // data formatada pelo UiFormatters
  title: String,          // nome da rota (obrigatório — default "Minha primeira rota")
  menu: DrawerRouteMenu?  // null se feature RouteDrawerOptions estiver desabilitada
)
```

### DrawerRouteMenu (`xz5`)

```
DrawerRouteMenu(
  setNameAndDateStatus: FeatureStatus,   // permissão de renomear/reconfigurar data
  duplicateStatus: FeatureStatus,         // permissão de duplicar
  showDeleteRoute: Boolean                // true se DeleteRoute.Enabled E rota NÃO criada por dispatcher
)
```

**FeatureStatus enum:** `Enabled` | `TeamRestriction` | `PlanRestriction`

### Grupos de rotas — seções em ordem (de cima para baixo)

| Seção | Condição | String PT-BR |
|---|---|---|
| **"Próximas rotas"** | rotas com data futura | `"Próximas rotas"` (key `route_group_upcoming_routes`) |
| **"Hoje"** | rotas de hoje | `"Hoje"` (key `today`) |
| **"Início desta semana"** | rotas passadas desta semana | `"Início desta semana"` (key `route_group_earlier_week`) |
| **"Início deste mês"** | rotas passadas deste mês | `"Início deste mês"` (key `route_group_earlier_month`) |
| **Data específica** | rotas de semanas anteriores (grupo por data) | data formatada por `UiFormatters` |

### Precisa-runtime

- Formato exato da data no grupo "data específica" (ex.: "Seg, 10 jun" vs "10 de junho")
- Número máximo de rotas exibidas antes de paginação (usa `GetPagedRoutes`)
- Comportamento de scroll ao abrir o drawer (snap para rota ativa?)

---

## 3. RoutesDrawerContent — Conteúdo do drawer

**Propósito:** Composable LazyColumn que renderiza header + grupos de rotas + botão sticky de criar rota.
**Classe:** `com.circuit.ui.home.drawer.C3419e` (compilado de `RoutesDrawerContent.kt`)
**Largura do drawer:** 110dp convertido para px (`eh4.m31545d(110.0f, ...)` — em dp, NÃO em fração da tela)

### Estrutura (ordem vertical, de cima para baixo)

1. **DrawerHeaderView** (ver §4) — fixo no topo
2. **LazyColumn** com `LazyListState`:
   - Para cada `DrawerRouteGroup`:
     - **Separador de seção** (componente `DrawerSectionHeader`) com o título do grupo; separador de linha acima exceto no primeiro grupo
     - Para cada `DrawerRouteUiModel` no grupo:
       - **DrawerRouteItem** (ver §5)
     - **Botão "Criar nova rota"** — exibido apenas no grupo "Hoje" quando `showCreateRoute=true` (grupo vazio + permissão)
   - `bottom-spacer` no fim da lista
3. **Botão sticky "Criar nova rota"** — exibido na base do drawer quando `stickyButtons.showCreateRoute=true`; sobrepõe a lista com padding `start=8dp`

### String PT-BR do estado vazio (grupo "Hoje" sem rotas)

- `"Ainda não há rotas"` (key `routes_drawer_today_empty`) — texto exibido dentro do item quando o grupo "Hoje" está vazio

### Strings PT-BR dos botões de criação

- `"Criar nova rota"` (key `create_new_route_button`) — botão inline no grupo vazio
- `"Criar nova rota"` (key `create_new_route_button`) — botão sticky no rodapé (mesma string)

### Comportamento do scroll

- `LazyListState` gerenciado externamente; scroll programático quando a rota ativa muda
- Fator de limite para recolher/expandir o header: `DrawerValue` (`Closed`/`Open`) do `DrawerState`

### Precisa-runtime

- Comportamento visual exato do separador de seção (linha divisória, espaçamento, cor)
- Animação de aparecimento/desaparecimento do botão sticky
- Comportamento de scroll automático ao abrir o drawer (scroll para a rota ativa?)

---

## 4. DrawerHeaderView — Header do drawer

**Propósito:** Header do drawer com avatar, nome, e-mail/equipe, perfil card, botão de assinatura, e atalhos de ajuda e configurações.
**Classe:** `com.circuit.ui.home.drawer.C3415a` (compilado de `DrawerHeaderView.kt`)

### Estrutura (ordem vertical)

1. **Fundo gradiente** — cor determinada por `DrawerHeaderColor`:
   - `Green` (0): gradiente verde (modo pessoal)
   - `Blue` (1): gradiente azul (modo equipe) — **default**
2. **Atalhos de ação** (linha horizontal, topo do header):
   - Ícone de Ajuda (`R.drawable.help_outline`) + label `"Ajuda e suporte"` (key `help_drawer_title`)
   - Ícone de Configurações (`R.drawable.baseline_settings_24`) + label `"Configurações"` (key `drawer_settings_action_title`)
   - O item de Ajuda tem um sub-menu expansível (ver §4.1)
3. **Avatar** (64dp, circular) — `Uri` do avatar do usuário; se null, placeholder/initials
4. **Linha 1 (firstLine)** — nome do usuário; default `""` (string vazia)
5. **Linha 2 (secondaryLine)** — e-mail ou nome da equipe; null = oculto
6. **Linha 3 (tertiaryLine)** — info extra (ex.: cargo); null = oculto; renderizado com `jqd` (StringResource formatado)
7. **Profile card** (opcional):
   - Se `Personal(title, subtitle)`: card de perfil pessoal com `R.drawable.personal_profile`; subtitle = `"Equipe"` (key `profile_switcher_team_subtitle`) quando em modo equipe
   - Se `Team(title)`: card de perfil de equipe com `R.drawable.teams_profile` + subtitle fixo `"Equipe"` (key `profile_switcher_team_subtitle`)
   - Se null: seção de profile card não renderizada
8. **Botão de assinatura** (opcional, null = oculto):
   - `Subscribe` → `"Assinar"` (key `drawer_header_subscribe_button_text`)
   - `Upgrade` → `"Fazer upgrade"` (key `drawer_header_upgrade_button`)
   - `Renew` → `"Renovar"` (key `drawer_header_renew_button_text`)
   - Ícone: `R.drawable.subscribe_lightning_bolt_20` (raio)

### 4.1 Sub-menu de Ajuda (expansível dentro do header)

Ao tocar no ícone de Ajuda, um painel se expande com dois itens:
- `Support` — abre suporte via Intercom
- `Record` — grava tela para suporte (feature de gravação)

**DrawerHeaderEvent.HelpSubMenuClicked.Type enum:** `Support` | `Record`

### 4.2 Botão de assinatura — eventos

**DrawerHeaderEvent.SubscribeButtonClicked.Type enum:** `Subscribe` | `Renew`
(O `Upgrade` não gera evento de clique distinto — navega diretamente para paywall)

### Strings PT-BR do header

| Chave | Valor |
|---|---|
| `help_drawer_title` | `"Ajuda e suporte"` |
| `drawer_settings_action_title` | `"Configurações"` |
| `drawer_header_subscribe_button_text` | `"Assinar"` |
| `drawer_header_upgrade_button` | `"Fazer upgrade"` |
| `drawer_header_renew_button_text` | `"Renovar"` |
| `profile_switcher_team_subtitle` | `"Equipe"` |
| `profile_switcher_options_title` | `"Perfis"` |
| `profile_switcher_options_subtitle` | `"Escolha o modo de direção"` |

### Ícones (Spoke drawable → Lucide sugerido)

| Spoke drawable | Propósito | Lucide sugerido |
|---|---|---|
| `help_outline` | Ajuda e suporte | `HelpCircle` |
| `baseline_settings_24` | Configurações | `Settings` |
| `personal_profile` | Perfil pessoal | `User` |
| `teams_profile` | Perfil de equipe | `Users` |
| `subscribe_lightning_bolt_20` | Botão assinar | `Zap` |

### Navegação

- Ajuda → expande sub-menu (Support / Record); Support → Intercom
- Configurações → navega para `SettingsFragment`
- Profile card → abre `ProfileSwitcherFragment` (tela de troca de perfil pessoal/equipe)
- Botão assinar → paywall de assinatura [B2B — cortar: `Upgrade` com preço de equipe]

### Precisa-runtime

- Altura exata do header e comportamento de collapse ao fazer scroll na lista
- Animação de expansão do sub-menu de Ajuda
- Formato exato do nome/e-mail quando o usuário está em modo equipe
- Comportamento do profile card ao tocar (abertura de ProfileSwitcher?)

---

## 5. DrawerRouteItem — Item de rota na lista

**Propósito:** Linha da lista de rotas no drawer; exibe data formatada + título + kebab de opções.
**Classe:** `com.circuit.ui.home.drawer.C3419e.m9380c` (método estático em `RoutesDrawerContent.kt`)

### Estrutura (horizontal)

1. **Data formatada** (`formattedDate`) — texto à esquerda; ellipsis em 1 linha; largura máxima 64dp
2. **Título da rota** (`title`) — texto principal; ellipsis em 1 linha; `weight(1f)` (ocupa restante)
3. **Kebab (⋮)** (`R.drawable.baseline_more_vert_24`) — botão de opções; exibido apenas se `menu != null`

### Estados visuais

- **Rota ativa** (`isActive=true`): background = `primaryContainer` do tema; texto com cor `onPrimaryContainer`
- **Rota inativa** (`isActive=false`): sem background especial; cor de texto padrão

### Ações ao tocar

- **Toque no item** → `DrawerViewModel.tappedRoute()` → `SetActiveRoute` (interactor `C2990y0`) → fecha drawer
- **Toque no kebab** → abre `DrawerRouteMenu` dropdown (ver §6)

### Precisa-runtime

- Comportamento exato do highlight da rota ativa (borda? círculo? row inteira?)
- Animação de transição ao selecionar rota

---

## 6. DrawerRouteMenu — Dropdown kebab do item de rota

**Propósito:** Menu de opções contextuais ao tocar no kebab (⋮) de um item de rota.
**Classe:** Inline em `C3419e.m9380c` via `DropdownMenu` / `fx3.m32595b` (Compose `DropdownMenu`)

### Itens do menu (em ordem)

| Item | Condição de exibição | Ação |
|---|---|---|
| **Renomear / Mudar data** (`SetNameAndDate`) | `setNameAndDateStatus.isEnabled()` — se `TeamRestriction`: mostra mas desabilitado (toast) | `DrawerEvent.NavigateToSetNameAndDate(routeId)` → abre `RouteCreateFragment(EditRoute)` |
| **Duplicar rota** (`Duplicate`) | `duplicateStatus.isEnabled()` — se `TeamRestriction`: mostra mas desabilitado (toast) | `DrawerViewModel.tappedDuplicateRoute()` → verifica features → `DrawerEvent.LaunchDuplicateDialogFlow` |
| **Excluir rota** (`Delete`) | `showDeleteRoute=true` (Enabled + NÃO criada por dispatcher) | `DrawerViewModel.tappedDeleteRoute()` → `DrawerEvent.ShowConfirmDeleteRoute` |

### Strings PT-BR (itens do menu kebab)

Não há strings específicas de rótulo no dump do drawer — os labels são derivados do componente `DropdownMenuItem` genérico. Os textos visíveis deduzidos por contexto e por referências ao `RouteCreateFragment` para o item "Renomear":
- **Renomear / Mudar data** → associado a `NavigateToSetNameAndDate` → abre tela `RouteCreateFragment` em modo edição (ver §7)
- **Duplicar rota** → key `duplicate_route`: `"Duplicar rota"`
- **Excluir rota** → key `delete_route`: `"Excluir rota"`

### Lógica de delete

- Se `DeleteRoute=Enabled` E rota criada por dispatcher → toast `"Esta rota foi criada por um despachante e só pode ser excluída por ele"` (key `cannot_delete_dispatcher_created_route_toast`)
- Se apenas 1 rota existir → toast `"Não é possível excluir a única rota"` (key `cannot_delete_only_route_title`)
- Se `PlanRestriction` → não deve ocorrer (asserte no código), log de erro
- Se `TeamRestriction` → exibe toast de recurso não habilitado (key `generic_error` ou similar)
- Se permission OK → `DrawerEvent.ShowConfirmDeleteRoute` → dialog de confirmação (ver §10)

### Precisa-runtime

- Posição exata do dropdown (acima ou abaixo do kebab?)
- Ícones nos itens do menu (icone ou apenas texto?)
- Ordem exata dos 3 itens em runtime (screenshot necessário)

---

## 7. RouteCreateFragment / RouteCreateScreen — Criar / Editar rota

**Propósito:** Tela de criação de nova rota OU edição de nome/data de rota existente.
**Classe:** `com.circuit.ui.create.RouteCreateFragment` + `RouteCreateScreenKt` (compilado de `RouteCreateScreen.kt`)
**Args:** `RouteCreateArgs` (sealed class: `NewRoute` | `EditRoute` | `DuplicateRoute`)

### RouteCreateArgs — modos

| Arg | Campos | Uso |
|---|---|---|
| `NewRoute(copyStopsOptionChecked, hasCopyStopsOption, resultKey)` | `hasCopyStopsOption: Boolean` = se há rota anterior para copiar paradas | Botão "Criar nova rota" |
| `EditRoute(id: RouteId)` | id da rota a editar | Kebab → Renomear/mudar data |
| `DuplicateRoute(id: RouteId, keepProgress: Boolean)` | `keepProgress` = se mantém progresso | Após seleção no dialog de duplicação |

### Estrutura da tela (NewRoute / EditRoute — campos idênticos)

1. **Campo: Nome da rota** — `TextField` com label `"Nome da rota (opcional)"` (key `route_name_optional_title`); placeholder = nome auto-gerado (ex.: data do dia)
2. **Campo: Data** — seletor de data (ver §7.1)
3. **Seção opcional: "Opções de início rápido"** — exibida apenas em `NewRoute` quando `hasCopyStopsOption=true`
   - Checkbox/toggle: `"Reutilizar paradas anteriores"` (key `route_copy_stops_option`)
   - Título da seção: `"Opções de início rápido"` (key `route_copy_stops_title`)
4. **Botão primário:**
   - `NewRoute` sem copyStops: `"Criar rota"` (key `route_create_button_title`)
   - `NewRoute` com copyStops selecionado: `"Continuar para copiar paradas"` (key `route_create_next_title`)
   - `EditRoute`: `"Criar rota"` (key `route_create_button_title`) — salva alterações

### 7.1 Seletor de data

- **Título do seletor:** `"Selecione a data"` (key `route_date_picker_title`)
- **Opção de data customizada:** `"Escolher data"` (key `route_date_picker_custom`) — abre DatePicker nativo
- Valores pré-definidos visíveis: `"Hoje"` (key `today`), `"Amanhã"` (key `tomorrow`); datas passadas bloqueadas (`FutureDateValidator`)

### Strings PT-BR

| Chave | Valor |
|---|---|
| `create_new_route_title` | `"Criar rota"` |
| `add_route_title` | `"Adicionar rota"` |
| `route_name_optional_title` | `"Nome da rota (opcional)"` |
| `route_date_picker_title` | `"Selecione a data"` |
| `route_date_picker_custom` | `"Escolher data"` |
| `route_create_button_title` | `"Criar rota"` |
| `route_create_next_title` | `"Continuar para copiar paradas"` |
| `route_copy_stops_title` | `"Opções de início rápido"` |
| `route_copy_stops_option` | `"Reutilizar paradas anteriores"` |
| `first_route_name` | `"Minha primeira rota"` (nome gerado para 1ª rota do usuário) |

### Navegação

- **Abre via:** botão "Criar nova rota" (drawer), kebab → Renomear, `DrawerEvent.NavigateToSetNameAndDate`
- **Fecha via:** botão voltar (descarta), botão "Criar rota" / "Continuar" (salva e fecha)
- **Após salvar `NewRoute`:** volta para drawer com nova rota na lista; se `copyStopsOptionChecked=true` navega para fluxo de cópia de paradas

### Precisa-runtime

- Comportamento exato do campo de nome (auto-preenchido com data? Limpa ao focar?)
- Aparência do date-picker (chips horizontais? lista vertical?)
- Comportamento do botão "Criar rota" quando o nome está vazio

---

## 8. AskUserImportDialog — Confirmação de importação de rota

**Propósito:** Dialog de confirmação ao receber rota importada de terceiro (ex.: manifesto).
**Classe:** `com.circuit.ui.home.dialogs.AskUserImportDialog`
**Tipo:** `AdaptiveModalDialog` (modal adaptativo — Bottom Sheet em telas pequenas, Dialog centrado em tablets)

### Estrutura

- Título: nome da rota recebida (`name: String` passado no constructor)
- Botão de confirmação: delega para `HomeEvent.AskAboutImport.confirmed`
- Botão de cancelar/dispensar: `dismiss()`

### Strings PT-BR

Não há strings dedicadas visíveis no dump para este dialog (o título é o nome da rota). Confirmar em runtime a presença de corpo/subtítulo.

### Navegação

- **Abre via:** `HomeEvent.AskAboutImport` emitido pelo `HomeViewModel` ao detectar Intent de importação
- **Confirmar:** importa a rota e exibe na lista
- **Cancelar:** descarta a importação

### Precisa-runtime

- Texto exato do botão de confirmação (pode ser `"Importar"` / `"Adicionar"`)
- Presença de subtítulo explicativo abaixo do título

---

## 9. RouteChangedDialog — Dialog de rota recebida/atualizada

**Propósito:** Dialog exibido quando o motorista recebe uma nova rota (today ou futura) ou uma rota existente é atualizada pelo dispatcher.
**Classe:** `com.circuit.ui.home.dialogs.RouteChangedDialog`
**Tipo:** `AdaptiveModalDialog`

### Parâmetros

- `route: Route` — rota recebida
- `isStartToday: Boolean` — true = rota para hoje; false = rota futura
- `type: RouteChangeType` — `Distributed` | `Updated`

### Lógica de título

| Condição | Título |
|---|---|
| `type=Distributed` AND `isStartToday=true` | `"Nova rota para hoje"` (key `new_route_dialog_title`) |
| `type=Distributed` AND `isStartToday=false` | `"Nova rota: %1$s"` (key `new_future_route_dialog_title`) com nome da rota |
| `type=Updated` | `"Rota atualizada: %1$s"` (key `route_update_received_dialog_title`) com nome da rota |

### Lógica de corpo (subtítulo)

- **Linha 1 (tempo de recebimento):**
  - Se recebido há menos de 2 min: `"Recebido agora."` (key `new_route_received_dialog_received_now`)
  - Se recebido há mais de 2 min: `"Recebido: %1$s."` (key `new_route_received_dialog_received_time`) com tempo relativo
- **Linha 2 (status):**
  - `isStartToday=true`: `"Salvo no seu dispositivo."` (key `new_route_received_dialog_saved`)
  - `isStartToday=false`: `"Para verificar a rota, toque no Menu ☰ no canto superior esquerdo do app."` (key `new_future_route_dialog_description`)
- As duas linhas são concatenadas com espaço

### Botões

- **Confirmar:** `"Abrir rota agora"` (key `new_route_received_dialog_button`) — abre a rota diretamente
- **Cancelar:** `"Depois"` (key `new_route_received_dialog_cancel`) — fecha o dialog

### Navegação

- **Abre via:** `HomeEvent.ShowRouteChangedDialog`
- **Confirmar:** navega para a rota recebida (`HomeEvent.ShowRouteChangedDialog.confirmed`)
- **Cancelar:** fecha dialog; rota permanece na lista do drawer

---

## 10. AskUserDeleteDialog — Confirmação de exclusão de rota

**Propósito:** Dialog de confirmação antes de excluir uma rota do drawer.
**Classe:** `com.circuit.ui.home.dialogs.AskUserDeleteDialog`
**Tipo:** `AdaptiveModalDialog`

### Parâmetros

- `name: String` — nome da rota a ser excluída

### Strings PT-BR

| Chave | Valor |
|---|---|
| `are_you_sure_you_want_to_delete` | `"Quer mesmo excluir %1$s?"` |
| `delete_route_button_title` | `"Excluir"` |

### Estrutura

- Título: `"Quer mesmo excluir %1$s?"` com nome da rota interpolado
- Botão destrutivo: `"Excluir"` → `DrawerEvent.ShowConfirmDeleteRoute.confirmed` → `tappedDeleteRoute()`
- Botão cancelar: `dismiss()`

### Navegação

- **Abre via:** `DrawerEvent.ShowConfirmDeleteRoute` emitido em `HomeFragment.handleDrawerEvent()`
- **Confirmar:** exclui a rota, rota some da lista do drawer
- **Cancelar:** fecha dialog, rota permanece

---

## 11. CopyRouteProgressDialog — Dialog de duplicação (seleção de progresso)

**Propósito:** Dialog intermediário do fluxo de duplicação: usuário escolhe se mantém ou descarta o progresso da rota original.
**Classe:** `com.circuit.ui.home.dialogs.CopyRouteProgressDialog`
**Tipo:** `AdaptiveModalDialog`

### Parâmetros

- Sem parâmetros no constructor — o estado é gerenciado externamente via `DrawerEvent.LaunchDuplicateDialogFlow`
- **LaunchDuplicateDialogFlow.Action enum:** `KeepProgress` | `DiscardProgress`

### Condição de exibição

- Só aparece quando a rota tem `AppFeature.ProofOfDelivery` desabilitado (rotas com POD não passam pelo fluxo de cópia de progresso)
- Quando POD está habilitado, a duplicação vai direto para `DuplicateRoute(keepProgress=null)`

### Strings PT-BR

| Chave | Valor |
|---|---|
| `duplicate_route` | `"Duplicar rota"` |
| `duplicate_route_progress_keep` | `"Manter progresso da rota"` |
| `duplicate_route_progress_keep_description` | `"As paradas feitas continuarão na rota copiada."` |
| `duplicate_route_progress_clear` | `"Redefinir progresso da rota"` |
| `duplicate_route_progress_clear_description` | `"As paradas feitas serão marcadas como não feitas na rota copiada."` |

### Estrutura

- Título: `"Duplicar rota"` (key `duplicate_route`)
- Opção 1 (radio/card): `"Manter progresso da rota"` + descrição `"As paradas feitas continuarão na rota copiada."`
- Opção 2 (radio/card): `"Redefinir progresso da rota"` + descrição `"As paradas feitas serão marcadas como não feitas na rota copiada."`
- Botão de confirmar: action = `KeepProgress` ou `DiscardProgress`
- Botão cancelar: `dismiss()`

### Navegação

- **Abre via:** `DrawerEvent.LaunchDuplicateDialogFlow` emitido em `HomeFragment.handleDrawerEvent()`
- **Confirmar:** navega para `RouteCreateFragment(DuplicateRoute(id, keepProgress))` que cria a cópia
- **Cancelar:** fecha dialog, nenhuma ação

### Precisa-runtime

- Aparência das opções (RadioButton? Cards com bordas? Lista simples?)
- Seleção padrão (KeepProgress ou DiscardProgress pré-selecionado?)

---

## 12. ProfileSwitcherFragment — Troca de perfil pessoal/equipe

**Propósito:** Permite ao usuário alternar entre perfil pessoal e perfis de equipe.
**Classe:** `com.circuit.ui.profileswitcher.*` (pacote separado, referenciado pelo header)

### Strings PT-BR

| Chave | Valor |
|---|---|
| `profile_switcher_options_title` | `"Perfis"` |
| `profile_switcher_options_subtitle` | `"Escolha o modo de direção"` |
| `profile_switcher_team_subtitle` | `"Equipe"` |
| `settings_logout` | `"Sair"` |
| `settings_title` | `"Configurações"` |

### Navegação

- **Abre via:** toque no profile card no header do drawer
- **Fecha via:** seleção de perfil (fecha e recarrega o drawer com novo perfil) ou botão voltar

### Nota para RotPro

Este componente é **B2B — parcialmente cortar**: a lógica de troca para perfil de Equipe/Dispatch não existe no RotPro (ADR-0035). Manter apenas o perfil pessoal. O botão de profile card no header pode ser removido ou simplificado para mostrar apenas o avatar do usuário.

---

## Fluxo de navegação completo do drawer

```
Home (mapa + sheet)
  └── botão hambúrguer (topo esq.) / swipe
        └── Drawer aberto
              ├── [Header]
              │     ├── Ajuda e suporte → Intercom / gravação
              │     ├── Configurações → SettingsFragment
              │     ├── Profile card → ProfileSwitcherFragment (B2B — simplificar)
              │     └── Botão assinar → Paywall (relevante para RotPro: paywall Pix/Stripe)
              │
              ├── [Lista de rotas — por grupo de data]
              │     └── Toque no item → SetActiveRoute → fecha drawer → Home com rota selecionada
              │           └── Kebab (⋮) → DropdownMenu
              │                 ├── Renomear/mudar data → RouteCreateFragment(EditRoute)
              │                 ├── Duplicar rota → CopyRouteProgressDialog → RouteCreateFragment(DuplicateRoute)
              │                 └── Excluir rota → AskUserDeleteDialog → excluída
              │
              └── [Botão "Criar nova rota"] (sticky rodapé OU inline no grupo vazio de hoje)
                    └── RouteCreateFragment(NewRoute)
```

---

## Notas de implementação para RotPro

1. **Drawer via `ModalNavigationDrawer`** (Material 3) — já confirmado na implementação atual.
2. **Largura do drawer:** 110dp (Spoke). RotPro pode usar `DrawerDefaults.MaximumDrawerWidth` ou definir custom.
3. **Grupos de data:** 5 categorias (Próximas / Hoje / Início desta semana / Início deste mês / Data específica). O `rac.AbstractC25563b` é o discriminador — implementar enum equivalente.
4. **Botão sticky "Criar nova rota":** visível apenas quando `showCreateRoute=true` (lógica: grupo "Hoje" vazio + feature `CreateRoute.Enabled`). Para RotPro: sempre visível para usuários com plano ativo.
5. **Kebab menu:** 3 itens (Renomear / Duplicar / Excluir). O item "Renomear" reutiliza `RouteCreateFragment` em modo `EditRoute` — mesma tela de criação pré-preenchida.
6. **Perfil de equipe / ProfileSwitcher:** [B2B — cortar]. Header pode exibir apenas avatar + nome + e-mail sem profile card.
7. **Botão assinar no header:** [adaptar para RotPro] — exibir quando usuário está no free tier; label = `"Assinar"` ou `"Renovar"` dependendo do status; navegar para paywall Pix/Stripe (Slice 4).
8. **Dialog de rota recebida (RouteChangedDialog):** relevante para Slice 3 (backend real + push FCM). Strings verbatim mapeadas acima.

---

## Precisa-runtime (consolidado)

| Item | O quê confirmar |
|---|---|
| DrawerRouteItem — highlight ativo | Fundo azul full-row? borda esquerda? chip? |
| DrawerSectionHeader — visual | Linha divisória acima? altura? cor? |
| DrawerRouteMenu — posição e ícones | Dropdown acima/abaixo do kebab; ícones nos itens? |
| CopyRouteProgressDialog — seleção default | `KeepProgress` ou `DiscardProgress` pré-selecionado? |
| RouteCreateScreen — date picker | Chips horizontais? lista? picker nativo? |
| DrawerHeaderView — collapse no scroll | Header colapsa ao fazer scroll na lista? |
| Scroll ao abrir drawer | Drawer scrolla automaticamente para a rota ativa? |
| Formato de data no grupo "data específica" | Ex.: "Seg, 10 jun" ou "10 de junho de 2026"? |
