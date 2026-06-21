# Front blueprint — base

**Data:** 2026-06-21
**Fonte:** `com.circuit.p016ui.base` + `com.circuit.kit.p015ui` (jadx ofuscado via Pairip)
**Escopo:** componentes-base compartilhados da UI e grafo de navegação global

---

## Aviso de escopo

A pasta `com.circuit.p016ui.base` contém apenas **3 lambdas de infraestrutura ViewModel** (ViewModelExtensionsKt) — sem telas, diálogos, sheets ou componentes visuais próprios. Os componentes-base visuais reais residem em `com.circuit.kit.p015ui`. Este blueprint cobre ambos, mais o grafo de navegação global (`nav_main.xml`) que é a cola entre todas as áreas.

---

## 1. Infraestrutura ViewModel (com.circuit.p016ui.base)

**Propósito:** extensões Kotlin para criação de ViewModels com escopo de Fragment (padrão `circuitViewModel`).

**Classe:** `ViewModelExtensionsKt` — 3 lambdas anônimas (`C3144x51d970`, `C3146x51d972`, `C3147x51d973`)

**Estrutura:**
- `C3144x51d970` — lambda `() -> Fragment`: retorna o Fragment proprietário do ViewModel (owner para criação)
- `C3146x51d972` — lambda `() -> ViewModelStore`: resolve o `ViewModelStoreOwner` via `j09` lazy
- `C3147x51d973` — lambda `() -> CreationExtras`: resolve `CreationExtras` com fallback para `HasDefaultViewModelProviderFactory`

**Uso concreto (LoginFragment):**
```
ViewModelLazy(
    class = LoginViewModel,
    storeProducer = C3146x51d972(lazyOwner),
    factoryProducer = y6f(injectedFactory),
    extrasProducer = C3147x51d973(C3777a(), lazyOwner)
)
```

**Strings PT-BR:** nenhuma — infraestrutura pura.

**Navegação:** não navega — utilitário.

**Estados/defaults/enums:** nenhum — sem estado próprio.

**Ícones:** nenhum.

**Precisa-runtime:** Não — comportamento totalmente capturado pelo código.

---

## 2. LoadingMaterialButton (com.circuit.kit.p015ui.buttons)

**Propósito:** botão Material que substitui texto+ícone por um spinner animado durante carregamento, bloqueando toques enquanto `isLoading = true`.

**Classe:** `LoadingMaterialButton extends MaterialButton`

**Estrutura:**
- Estende `MaterialButton` (Material 3)
- Estado `isLoading: Boolean` (default `false`)
- Quando `isLoading = true`:
  - Salva: iconGravity, icon, texto atual, iconPadding
  - Substitui ícone por `@drawable/progress_bar_avd` (AnimatedVectorDrawable — spinner circular medium)
  - Define `iconGravity = CENTER` (valor 2)
  - Limpa o texto para `""`
  - Define `iconPadding = 0`
  - Inicia a animação do spinner
  - Bloqueia `onTouchEvent` retornando `false`
- Quando `isLoading = false`:
  - Restaura iconGravity, icon, texto e iconPadding salvos
  - Para a animação
- `setText()` override: quando em loading, salva o novo texto no buffer interno sem alterar o botão visualmente

**Drawable do spinner:** `@drawable/progress_bar_avd` — `<animated-vector>` wrapping `@drawable/vector_drawable_progress_bar_medium` com animações `@anim/progress_indeterminate_material` + `@anim/progress_indeterminate_rotation_material`

**Strings PT-BR:** nenhuma própria — texto vem do contexto de uso.

**Uso identificado:**
- `fragment_login.xml` — `@id/finish_primary_button` (tela "Concluir configuração" do login)
- Qualquer tela com ação assíncrona de submit

**Navegação:** não navega — componente de UI.

**Estados:**
| Estado | Aparência |
|---|---|
| `isLoading = false` (default) | texto + ícone opcional normais; toque habilitado |
| `isLoading = true` | spinner animado centralizado, texto invisível; toque desabilitado |

**Ícones:** `@drawable/progress_bar_avd` → sem equivalente Lucide (é spinner animado; usar `CircularProgressIndicator` do Material 3 no Flutter ou `CircularProgressIndicator` nativo do Dart).

**Precisa-runtime:** Não — comportamento totalmente capturado pelo código.

---

## 3. CircuitDialogFragment (com.circuit.kit.p015ui.dialog)

**Propósito:** classe-base para todos os diálogos do Spoke; bloqueia rotação da Activity enquanto o diálogo está visível.

**Classe:** `CircuitDialogFragment extends AppCompatDialogFragment`

**Estrutura:**
- Campo `f26759x1 = true` — flag "deve bloquear rotação" (hardcoded true)
- `onAttach()`: chama `p34.m42312z(activity)` → bloqueia rotação da Activity
- `onDetach()`: chama `p34.m42311y(activity)` → libera rotação

**Strings PT-BR:** nenhuma — infraestrutura pura.

**Navegação:** não navega — base class.

**Estados/defaults/enums:** nenhum estado próprio.

**Ícones:** nenhum.

**Precisa-runtime:** Não.

---

## 4. LinkTextView (com.circuit.kit.p015ui.text)

**Propósito:** TextView com suporte a links clicáveis e auto-link (URLs, e-mails, telefones); reaplica MovementMethod após cada mudança de texto para evitar perda do comportamento de clique.

**Classe:** `LinkTextView extends MaterialTextView`

**Estrutura:**
- `setLinksClickable(true)` no construtor
- `setAutoLinkMask(15)` → detecta PHONE | EMAIL_ADDRESSES | MAP_ADDRESSES | WEB_URLS
- `setMovementMethod(LinkMovementMethod)` via `fn6.f101074a`
- Dois `TextWatcher` internos (`C3045a`, `C3046b`) que chamam `m8997e()` após `onTextChanged` E após `afterTextChanged` — garantia dupla de que o MovementMethod sobrevive a qualquer troca de texto
- `onTouchEvent` delega ao `MovementMethod` para interceptar cliques em spans de link

**Uso identificado:** `bubble_navigation.xml` — `@id/line2View` (segunda linha de endereço na card de parada de navegação, que pode ser um link de mapa)

**Strings PT-BR:** nenhuma própria.

**Navegação:** delega cliques de link ao sistema (browser, discador, maps).

**Estados/defaults/enums:** stateless — comportamento determinado pelo conteúdo do texto.

**Ícones:** nenhum.

**Precisa-runtime:** Não.

---

## 5. ShrinkBeforeBreakTextView (com.circuit.kit.p015ui.views)

**Propósito:** TextView que reduz o tamanho da fonte progressivamente (de `largestSize` até `smallestSize`) antes de quebrar em mais linhas, priorizando caber em N linhas com fonte maior a ter N+k linhas com fonte padrão.

**Classe:** `ShrinkBeforeBreakTextView extends AutoSizeTextView (C25841sw)`

**Estrutura:**
- Atributos XML customizados via `fqb.f101313a`: `preferredLines` (int, default 1), `smallestSize` (dimension), `largestSize` (dimension)
- `onLayout()`: itera de `preferredLines` até 100 linhas; para cada N, decrementa a fonte de `largestSize` até `smallestSize` até achar o tamanho máximo que cabe em N linhas; quando acha, chama `setTextSize()` e para
- Fallback final: `1sp * scaledDensity` (texto de 1sp) se nenhum tamanho funcionar
- Android 8+ (`SDK_INT >= 27`): usa `getAutoSizeMinTextSize()` / `getAutoSizeMaxTextSize()` como defaults se dimensões XML não fornecidas
- Desabilita o autoSize do sistema (`setAutoSizeTextTypeWithDefaults(0)`) para controlar manualmente

**Uso identificado:** `fragment_login.xml` — `@id/finish_setup_title` (título da tela "Concluir configuração"), com `app:preferredLines="2"`

**Strings PT-BR:** nenhuma própria.

**Navegação:** não navega — componente visual.

**Estados/defaults/enums:** sem estados de negócio; layout recalcula toda vez que o conteúdo muda.

**Ícones:** nenhum.

**Precisa-runtime:** Não.

---

## 6. Grafo de Navegação Global (nav_main.xml)

**Propósito:** grafo único que conecta todas as telas e diálogos B2C do Spoke; usado pelo `MainActivity` com `R.navigation.nav_main`.

**Destino inicial:** `@+id/splash`

**Fragmentos principais (ordem no grafo):**

| ID | Classe | Tipo |
|---|---|---|
| `splash` | `Fragment` (anônimo) | Fragment |
| `login` | `LoginFragment` | Fragment |
| `tutorial` | `TutorialFragment` | Fragment |
| `onboarding_survey` | `OnboardingSurveyFragment` | Fragment |
| `home` | `HomeFragment` | Fragment |
| `settings` | `SettingsFragment` | Fragment |
| `dialogGallery` | `DialogGalleryFragment` | Fragment |
| `listRecordings` | `ListRecordingsFragment` | Fragment |
| `subscription` | `SubscriptionFragment` | Fragment |
| `cancel` | `CancelSubscriptionFragment` | Dialog |
| `loadVehicle` | `LoadVehicleFragment` | Fragment |
| `joinedTeam` | `JoinedTeamProfileFragment` | Fragment |
| `uploadRecording` | `UploadRecordingFragment` | Fragment |
| `recordingUploadSuccess` | `RecordingUploadSuccessFragment` | Fragment |

**Diálogos principais:**

| ID | Classe |
|---|---|
| `editStop` | `EditStopDialogFragment` |
| `addressPickerDialog` | `AddressPickerFragment` |
| `setup` | `RouteSetupFragment` |
| `breakSetup` | `BreakSetupFragment` |
| `comparePlansDialog` | `ComparePlansFragment` |
| `paywallDialog` | `PaywallDialogFragment` |
| `packageLabelModeSetting` | `PackageLabelModeDialogFragment` |
| `inAppNavigationSettings` | `InternalNavigationControlsDialogFragment` |
| `optimizationExplainerDialog` | `OptimizationExplainerDialogFragment` |
| `routeCreate` | `RouteCreateFragment` |
| `notesEditor` | `NotesFragment` |
| `profileSwitcher` | `ProfileSwitcherFragment` |
| `applyRouteChanges` | `ApplyRouteChangesDialogFragment` |
| `survey` | `SurveyDialogFragment` |
| `enableLocation` | `EnableLocationFragment` |
| `speechInput` | `SpeechInputFragment` |
| `includeSkippedStops` | `IncludeSkippedStopsFragment` |
| `includeSkippedBreak` | `IncludeSkippedBreakFragment` |
| `labelScanner` | `LabelScannerFragment` |
| `packagePhotoViewer` | `PackagePhotoViewerFragment` |
| `mediaImportImageCitationViewer` | `ImageCitationViewerDialogFragment` |
| `proofPhotoViewer` | `ProofViewerFragment` |
| `shareFeedbackDialog` | `StartRecordingDialogFragment` |
| `transferStopsSharingView` | `TransferStopsSharingFragment` |
| `acceptTransferStopsDialog` | `AcceptStopsFragment` |
| `chooseAnotherRouteFragment` | `ChooseAnotherRouteFragment` |
| `importRouteManifestGallery` | `ImportManifestGalleryFragment` |
| `selectExactLocationEditAddress` | `EditExactLocationAddressFragment` |
| `invalidMediaStopsConfirmation` | `InvalidMediaStopsConfirmationDialogFragment` |
| `depotPickup` | `EditDepotPickupFragment` |
| `routeOfferDetails` | `RouteOfferDetailsDialogFragment` |
| `acceptRouteOffer` | `AcceptRouteOfferDialogFragment` |
| `copyStops` | `CopyStopsFragment` |
| `delivery_graph` | (grafo incluído via `nav_additional_actions.xml`) |

**Fluxo principal (splash→home):**
```
splash
  ├─action_login──► login ──action_home──► home (popUpTo login inclusive)
  │                       ├─action_tutorial──► tutorial ──action_home──► home
  │                       └─action_onboarding_survey──► onboarding_survey ──action_tutorial──► tutorial
  └─action_home──► home (popUpTo splash inclusive)
```

**Ações globais registradas (acessíveis de qualquer destino):**
- `action_edit_stop` → `editStop` (popUpTo editStop inclusive)
- `action_open_speech` → `speechInput` (popUpTo speechInput inclusive)
- `action_survey` → `survey` (popUpTo survey inclusive)
- `action_enable_location` → `enableLocation` (popUpTo enableLocation inclusive)
- `action_subscription` → `subscription` (popUpTo home)
- `action_setup` → `setup`
- `action_break_setup` → `breakSetup`
- `action_settings` → `settings`
- `action_notes` → `notesEditor`
- `action_delivery` → `delivery_graph` (com args `AdditionalCompletionActionsArgs`)
- `action_view_package_photo` → `packagePhotoViewer`
- `action_view_media_import_image` → `mediaImportImageCitationViewer`
- `action_label_scanner` → `labelScanner`
- `action_picker_dialog` → `addressPickerDialog`
- `action_home` → `home` (popUpTo home)
- `action_apply_route_changes` → `applyRouteChanges`
- `action_optimization_explainer` → `optimizationExplainerDialog`
- `action_compare_plans` → `comparePlansDialog`
- `action_renew_subscription` → `cancel`
- `action_paywall` → `paywallDialog`
- `action_open_proof_viewer` → `proofPhotoViewer`
- `action_select_exact_location_edit_address` → `selectExactLocationEditAddress`
- `action_onboarding_survey` → `onboarding_survey`
- `action_package_label_mode` → `packageLabelModeSetting` (com args `PackageLabelModeDialogSource`)
- `action_upload_recording` → `uploadRecording`
- `action_route_offer_details` → `routeOfferDetails` (popUpTo home)
- `action_accept_route_offer` → `acceptRouteOffer` (popUpTo home)
- `action_accept_transfer_stops_dialog` → `acceptTransferStopsDialog` (popUpTo home)
- `action_invalid_media_stops_confirmation` → `invalidMediaStopsConfirmation`
- `action_depot_pickup` → `depotPickup`
- `action_import_route_manifest` → `importRouteManifestGallery`

**Argumentos com tipo não-nulo obrigatório:**
- `editStop`: `EditStopDialogArgs`
- `setup`: nenhum (abertura sem args)
- `breakSetup`: `BreakSetupArgs`
- `subscription`: `SubscriptionRequest?` (nullable, default `@null`) + `launchPurchase: Boolean` (default `false`)
- `copyStops`: `CopyStopsArgs`
- `labelScanner`: `LabelScannerArgs`
- `packagePhotoViewer`: `PackagePhotoViewerArgs`
- `survey`: `SurveyType` (enum)
- `notesEditor`: `NotesEditorArgs`
- `applyRouteChanges`: `ApplyRouteChangesArguments`
- `addressPickerDialog`: `AddressPickerArgs`
- `packageLabelModeSetting`: `PackageLabelModeDialogSource`
- `routeCreate`: `RouteCreateArgs`
- `proofPhotoViewer`: `ProofViewerArgs`
- `selectExactLocationEditAddress`: `EditExactLocationAddressArgs`
- `mediaImportImageCitationViewer`: `ImageCitationViewerArgs`
- `speechInput`: `showAddMultipleStops: Boolean` (default `true`) + `resultKey: SpeechInputResultKey`
- `invalidMediaStopsConfirmation`: `InvalidMediaStopsConfirmationArgs`
- `depotPickup`: `EditDepotPickupArgs`
- `loadVehicle`: `LoadVehicleArgs`
- `transferStopsSharingView`: `TransferStopsSharingArgs?` (nullable)
- `acceptTransferStopsDialog`: `AcceptStopsArgs?` (nullable)
- `chooseAnotherRouteFragment`: `ChooseAnotherRouteArgs`
- `importRouteManifestGallery`: `ImportManifestGalleryArgs`
- `delivery_graph` (ação global): `AdditionalCompletionActionsArgs`

**Grafo adicional incluído:** `@navigation/nav_additional_actions` — contém telas de delivery/prova (mapeadas em `delivery.md`).

**Strings PT-BR:** nenhuma no grafo em si — strings são dos fragmentos individuais.

**Precisa-runtime:** Não — grafo completamente capturado pelo XML.

---

## 7. MainActivity (com.circuit.p016ui)

**Propósito:** Activity raiz única do app; hospeda o NavController com `nav_main.xml`; gerencia ciclo de vida de `BatteryMonitor`, `NavigationBrightnessController`, `RouteOfferManager`, `SystemBarStyleController`, e gravação de tela.

**Classe:** `MainActivity extends jx3` (base Activity com suporte a NavController; `jx3` = classe ofuscada equivalente a `AppCompatActivity` + `NavHostActivity`)

**Estrutura (campos relevantes):**
- `f27631l1 = R.navigation.nav_main` — grafo de navegação
- `f27642w1` — `ViewModelLazy<MainViewModel>` (escopo da Activity)
- `f27634o1` — `om7` (provável `EventQueue` de toast/snackbar global)
- `f27635p1` — `BatteryMonitor`
- `f27636q1` — recorder de tela para feedback
- `f27637r1` — `SystemBarStyleController` (status bar / navigation bar)
- `f27638s1` — `RouteOfferManager` [B2B — cortar]
- `f27639t1` — `ecd` (deep link resolver)
- `f27640u1` — `fn5` (provável push-notification handler)
- `f27641v1` — `NavigationBrightnessController` (brilho durante navegação)

**Eventos do MainViewModel (`AbstractC3143a`):**
- `C31393` (lambda `onCreate$3`): observa eventos do MainViewModel e reage; inclui tratamento de `AbstractC2728e.j.a` (ação de toast com callback)
- Toast global: chamadas via `AbstractC2728e.j` — o toast central do app passa pelo MainViewModel

**Strings PT-BR:** nenhuma na Activity em si.

**Navegação:** é o host; não navega para si mesma.

**Precisa-runtime:** Não para estrutura; comportamentos de deep link e RouteOffer precisam de runtime.

---

## 8. BubbleNavigation card (bubble_navigation.xml)

**Propósito:** card flutuante de navegação em progresso — mini-view colapsada + expanded-view com dados completos da parada ativa; aparece sobre o mapa durante navegação.

**Layout raiz:** `MaterialCardView` — `cornerRadius=16dp`, `elevation=8dp`, `layout_width=wrap_content`

**Seção mini (colapsada):**
- Container: `LinearLayout` vertical `@id/miniView` — `padding=12dp`, `width=160dp`
  - `@id/miniLine1` — `MaterialTextView`, `maxLines=1`, `style=textAppearanceButtonHeavy` — endereço curto da parada
  - `@id/miniBubbleLabels` — `ComposeView` — chips/labels de pacote (Compose)

**Seção expandida (`@id/expandedView`, visibility=gone por default):**
- `@id/leadingContent` — `LinearLayout` horizontal
  - `@id/icon` — `AppCompatImageView` 32×32dp, `padding=4dp`, `visibility=gone` por default
  - `@id/stopNumberLarge` — `MaterialTextView`, `style=textAppearanceCaptionDefault`, `visibility=gone` por default
- `@id/lineLarge` — `MaterialTextView`, `maxLines=2`, `autoSizeTextType=uniform`, `autoSizeMinTextSize=18sp` — endereço completo
- `@id/packageLabelView` — `MaterialTextView`, `visibility=gone`, padding H=8dp V=4dp — label de pacote
- `@id/expandLess` — `MaterialButton` 24×24dp (icon only), `@drawable/expand_less` — colapsa o card
- `@id/line2View` — **`LinkTextView`** `style=textAppearanceCaptionDefault`, `fgDefaultMuted` — segunda linha (sub-endereço ou link)
- `@id/chipGroup` — `ChipGroup`, `visibility=gone` — chips de atributos
- `@id/topDivider` — `MaterialDivider` 1dp, `visibility=gone`
- `@id/propertiesView` — `ScrollView`, `visibility=gone`, `maxHeight=400dp`
  - `@id/inlineStopProperties` — `InlineStopPropertiesView` — propriedades inline da parada
- `@id/bottomDivider` — `MaterialDivider` 1dp, `visibility=gone`
- **Botões de ação (visibilidade condicional):**
  - `@id/done` — `MaterialButton`, `@drawable/check_circle` + texto, `visibility=gone` — marcar entregue
  - `@id/allStops` — `MaterialButton` outlined, texto "Abrir app", `@drawable/ic_open_app`, `visibility=gone` — abre lista completa (modo compacto)
  - `@id/allStopsLarge` — `MaterialButton` outlined, texto "Abrir app", `@drawable/ic_open_app`, `iconGravity=textTop`, `iconPadding=4dp`, `visibility=gone` — abre lista completa (modo amplo)
  - `@id/proofButtonGroup` — `LinearLayout` horizontal, `visibility=gone`
    - `@id/failed` — `MaterialButton` outlined, `iconGravity=textTop`, `iconTint=@null` — marcar falha
    - `@id/delivered` — `MaterialButton` outlined, `iconGravity=textTop`, `iconTint=@null` — marcar entregue

**Strings PT-BR verbatim:**
- "Abrir app" (`@string/open_app_label`)

**Ícones drawable → sugestão Flutter:**
- `@drawable/expand_less` → `Icons.expandLess` (Material) ou Lucide `chevron-up`
- `@drawable/check_circle` → Lucide `check-circle`
- `@drawable/ic_open_app` → Lucide `external-link`

**Navegação:** `@id/allStops` / `@id/allStopsLarge` → abre o app completo (deeplink ou `action_home`); `@id/expandLess` → colapsa o card.

**Estados:**
| Estado | Visibilidade |
|---|---|
| Colapsado (default) | `miniView` visível, `expandedView` gone |
| Expandido | `expandedView` visível, `miniView` visível (card cresce) |
| Com prova habilitada | `proofButtonGroup` + `allStopsLarge` visíveis; `done` + `allStops` gone |
| Sem prova | `done` + `allStops` visíveis; `proofButtonGroup` + `allStopsLarge` gone |

**Precisa-runtime:** Sim — transição colapsado/expandido, preenchimento de miniLine1/lineLarge, quais botões aparecem e em qual contexto (delivery widget externo vs. in-app). Confirmar se o card existe fora do app (Android Auto / widget) ou só dentro do home shell.

---

## Resumo de componentes base por responsabilidade

| Componente | Tipo | Onde reutilizar no RotPro |
|---|---|---|
| `LoadingMaterialButton` | Botão com spinner | Qualquer submit assíncrono (login, otimização, salvar rota) |
| `CircuitDialogFragment` | Base de diálogo | Todo `showDialog()` — bloquear rotação durante diálogo |
| `LinkTextView` | TextView clicável | Endereços secundários, e-mails, URLs em detalhes de parada |
| `ShrinkBeforeBreakTextView` | TextView auto-shrink | Títulos longos que precisam caber em N linhas sem truncar |
| `nav_main.xml` | Grafo global | Referência canônica para o `GoRouter` — toda ação global mapeada aqui |
| `BubbleNavigation card` | Card de navegação ativa | Widget de parada ativa (Área 8 — delivery follow-mode) |
