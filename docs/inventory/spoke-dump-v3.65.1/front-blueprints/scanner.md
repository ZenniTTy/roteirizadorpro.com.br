# Front blueprint — scanner

Data: 2026-06-21
Fonte: `~/spoke-dump/jadx-out/sources/com/circuit/p016ui/scanner/` + `values-pt-rBR/strings.xml`
Classe principal: `LabelScannerFragment` (CircuitDialogFragment — abre como Dialog fullscreen sobre a tela de origem)
ViewModel: `LabelScannerViewModel`
State data class: `C3947q` (LabelScannerState)

---

## Visão geral

O scanner do Spoke é um **Dialog fullscreen com câmera** que concentra 6 modos de operação distintos, ativados via `ScannerLaunchMode`. Cada modo reconfigura header, instruções, resultados e ações de forma significativamente diferente. O Fragment é único (não há 6 Fragments separados); o `LabelScannerViewModel` trata o estado por sealed class.

---

## 1. Modos de lançamento (ScannerLaunchMode)

Enum sealed class passada como argumento `LabelScannerArgs(mode, resetFlashlightState)`:

| Valor | Propósito B2C |
|---|---|
| `Search(preselectRecognizerMode: RecognizerMode?)` | Scanner de endereço/barcode para **adicionar parada** (modo OCR ou barcode) |
| `ChangeAddress` | Reler etiqueta para **corrigir endereço** de parada existente |
| `CapturePackagePhoto(stopId, isNewStop, caller)` | Fotografar **pacote** (não lê texto/barcode — só câmera) |
| `BarcodeScanDelivery(stopId, deliverySuccess)` | **Confirmar entrega** lendo barcode da parada |
| `BarcodeLoadVehicle(pickupStopId?)` | Ler código para **carregar o veículo** [B2B — cortar] |
| `QrTransferStops` | Ler QR code para **receber paradas de outro motorista** |

> Modos prioritários para RotPro B2C: `Search`, `ChangeAddress`, `CapturePackagePhoto`, `BarcodeScanDelivery`.
> `BarcodeLoadVehicle` é funcionalidade de Dispatch/B2B — **cortar**.
> `QrTransferStops` é B2C mas depende de backend (Slice 3+).

---

## 2. Tela principal — LabelScannerScreen (modo Search / ChangeAddress)

**Classe:** `LabelScannerScreenKt` (Compose)
**Propósito:** câmera fullscreen com header de modo + resultado em sheet deslizante

### 2.1 Estrutura da tela (top → bottom)

```
[ Header ]
[ Preview câmera (PreviewView — CameraX) ]
[ ViewFinder overlay / guia de enquadramento ]
[ Sheet de resultado (deslizante, 3 posições) ]
```

#### Header (LabelScannerHeaderState)

Campos do estado:
- `showModeSelector: Boolean` — exibe ou não o segmented control de modos
- `selectedMode: RecognizerMode` — modo ativo (`Address` ou `Barcode`)
- `availableModes: List<RecognizerMode>` — lista de abas disponíveis
- `trailingActionButton: TrailingActionButton` — botão direito do header (`None`, `TypeCode`, `LanguageSelect`)
- `flashlightState: FlashlightState` — `NotAvailable`, `Off`, `On`
- `isOcrMode: Boolean`
- `language: LabelScannerLanguage`
- `languageDialogShown: Boolean`
- `showLanguageAndFlashlightButtons: Boolean` (campo calculado: `!showModeSelector && trailingButton == None && isOcrMode`)

Controles visíveis:
1. **Botão X fechar** (leading) — fecha o scanner
2. **SegmentedControl de modo** (centro, visível quando `showModeSelector = true`):
   - Aba "Endereço" — `"camera_scan_toggle_address"` → `"Endereço"`
   - Aba "Código de barras" — `"camera_scan_toggle_barcode"` → `"Código de barras"`
3. **Botão trailing** (direito, mutuamente exclusivo):
   - `TypeCode`: "Digitar o código" → `"camera_scan_code_input"` — abre diálogo de input manual de barcode
   - `LanguageSelect`: ícone de idioma → abre seletor de idioma
4. **Botão lanterna** (`ic_flashlight_off` / `ic_flashlight_on`): visível quando `showLanguageAndFlashlightButtons = true`

#### Reconhecedor de modo

`RecognizerMode` (enum):
- `Address` — OCR de endereço via ML (AddressTextExtractor)
- `Barcode` — leitor de código de barras via CameraX ImageAnalysis
- `TransferStopsQr` — QR code de transferência (modo QrTransferStops apenas)

#### Camera / Preview

- `PreviewView` (CameraX) — modo de implementação adaptável (COMPATIBLE quando flag ativada)
- `onTouch`: toque na preview dispara autofoco pontual com janela de 2000ms
- O analisador `DataRecognitionAnalyzer` processa frames: `DataRegionType.Text` (OCR) ou `DataRegionType.Barcode`
- Instrução de enquadramento — modo barcode: `"Aponte a câmera ao código de barras"` (`camera_scan_instructions_barcode`)

#### Sheet de resultado (SheetPosition)

Posições:
- `Dismissed` — sheet oculto
- `Default` — sheet em altura parcial
- `Expanded` — sheet expandido

---

## 3. Estados do resultado scanner (C3947q.c — ResultState)

Interface sealed `c` (dentro do state `C3947q`):

| Estado | Significado |
|---|---|
| `AddNewStop(searchResult, recognisedAddress)` | Endereço reconhecido, parada pronta para adicionar |
| `AddressNotFound` | OCR não encontrou endereço válido |
| `BarcodeImportDisabled` | Barcode desabilitado pelo despachante [B2B — cortar] |
| `BarcodeNotFound` | Barcode não corresponde a nenhuma parada |
| `g` (classe interna — estado de "edição de parada") | Sheet de edição da parada reconhecida aberto |

State `C3947q` completo (campos):
- `a: b` — modo atual do scanner (`OCR` ou `PackagePhoto(stopId)`)
- `b: LabelScannerLanguage` — idioma OCR selecionado
- `c: Int` — FPS do reconhecedor (exibido no debug overlay)
- `d: List<C3918b>` — regiões detectadas no frame (overlay visual)
- `e: evb` — progresso de busca de endereço
- `f: Boolean` — câmera inicializada com flash traseiro
- `g: Boolean` — câmera em execução
- `h: c` — estado do resultado (interface sealed acima)
- `i: FlashlightState` — estado da lanterna
- `j: List<RecognizerMode>` — modos disponíveis
- `k: RecognizerMode` — modo selecionado
- `l: Int` — contador de zoom
- `m: d` — dados do barcode de entrega (DeliveryBarcode)
- `n: Boolean` — internet disponível

---

## 4. Sheet de resultado de endereço reconhecido

Quando `ResultState = AddNewStop`:

### Ações visíveis:

1. **Endereço reconhecido** — exibido em texto grande
2. **Botão "Adicionar parada"** — primário → chama `addStop()`; emite `LabelScannerResult.NewStopAdded(stopId)`
3. **Link "Endereço incorreto?"** → `"label_scanner_wrong_address"` = `"Endereço incorreto?"` — reabre scanner para nova leitura
4. **Link "Não consegue achar o endereço?"** → `"label_scanner_cant_find_address"` = `"Não consegue achar o endereço?"` — navega para busca manual (`AddressNotFound`)

Quando `ResultState = AddressNotFound`:

- Texto: `"Endereço não encontrado"` (`label_scanner_address_not_found`)
- Texto: `"Leia outro endereço."` (`label_scanner_please_scan_another_address`)
- Botão "Adicionar a parada manualmente" → `"camera_scan_add_stop_manually"` = `"Adicionar a parada manualmente"` — navega para busca textual

---

## 5. EditStopSheet (sheet de edição pós-reconhecimento)

**Arquivo:** `EditStopSheetKt.kt` (Compose)
**Propósito:** sheet deslizante dentro do scanner que abre o formulário de edição da parada recém-reconhecida antes de confirmar a adição

`SheetPosition` (enum interno):
- `Dismissed`
- `Default`
- `Expanded`

O sheet usa `EagerAnchoredDraggableScrollingConnection` (nested scroll) e integra `EditStopEditor` da tela de edição de parada.

---

## 6. Diálogo de input manual de barcode (BarcodeInputDialog)

**Arquivo:** `BarcodeInputDialogKt` (Compose)
**Triggering:** botão "Digitar o código" no header (`TrailingActionButton.TypeCode`)

### Estrutura:

1. **Título:** `"ID do código de barras"` (`camera_scan_barcode_ID_title`)
2. **Campo de texto:** placeholder `"Insira o ID do código de barras"` (`camera_scan_barcode_ID_placeholder`)
3. **Mensagem de erro inline** (quando resultado for inválido): `"Não encontramos uma parada vinculada a este código de barras."` (`camera_scan_barcode_ID_error`)
4. **Botão "Adicionar a parada manualmente"** → `"camera_scan_add_stop_manually"` — fecha diálogo e abre busca textual
5. **Botão confirmar** (submete o código)

`CheckManualBarcodeResult` (enum — resultados possíveis da verificação do código digitado manualmente):
- `Success` — código encontrado
- `NoConnection` → exibe `"Sem conexão com a internet."` (`barcode_manual_input_no_internet_connection`)
- `NotFound` → exibe `"Nenhuma parada encontrada."` (`barcode_manual_input_no_stop_found`)
- `NotAuthorized` — barcode não autorizado pelo despachante [B2B — cortar]
- `BarcodeNoMatchAnyStop` — código não corresponde a nenhuma parada
- `WrongPackage` — código corresponde ao pacote errado

---

## 7. Modo CapturePackagePhoto

**Propósito:** tirar foto do pacote para prova de entrega (POD)

- Header sem segmented control de modo (showModeSelector = false)
- Camera preview igual ao modo Search
- **Botão shutter** (disparador) — tira foto via CameraX ImageCapture
- Foto salva localmente via `FileManager` (ly6) e associada ao `stopId`
- Caller enum (quem abriu): `SDS`, `Notes`, `EditStopSearch`, `EditStopStandalone`

Erros de captura de foto:
- Título: `"Não foi possível tirar a foto"` (`label_scanner_photo_capture_error_title`)
- Corpo: `"Não foi possível tirar e salvar a foto da câmera. Veja se a câmera está funcionando e se o dispositivo tem espaço suficiente."` (`label_scanner_photo_capture_error_description`)

---

## 8. Modo BarcodeScanDelivery (Confirmação de entrega por barcode)

**Propósito:** confirmar entrega de parada escaneando o barcode do pacote

### Tela (ScanConfirmation):

- Título: `"Leia o código para confirmar"` (`scan_confirmation_title`)
- Instrução: `"Aponte a câmera ao código de barras"` (`camera_scan_instructions_barcode`)
- **Botão "Pular"** → `"scan_confirmation_skip_button"` = `"Pular"`
  - Abre diálogo de confirmação de pular:
    - Título: `"Pular a leitura do código de barras?"` (`scan_confirmation_skip_dialog_title`)
    - Corpo: `"A leitura de códigos de barra é recomendada para evitar erros. Tem certeza que você deseja pular essa etapa?"` (`scan_confirmation_skip_dialog_body`)
    - Ação: `onSkipScanConfirmClick`

Erros de barcode (modo entrega):
- Barcode inválido:
  - Título: `"Código de barras inválido"` (`scan_error_invalid_barcode_title`)
  - Corpo: `"Este código de barras não corresponde a nenhuma parada."` (`scan_error_invalid_barcode_body`)
- Pacote incorreto:
  - Título: `"Pacote incorreto"` (`scan_error_wrong_package_title`)
  - Corpo: `"Verifique novamente o pacote e tente outra vez."` (`scan_error_wrong_package_body`)
- Input manual — pacote incorreto: `"Pacote incorreto. Por favor, verifique e tente novamente."` (`scan_input_error_wrong_package`)

Resultado: `LabelScannerResult.ScanBarcodeDeliveryComplete`

---

## 9. Modo QrTransferStops (Receber paradas por QR)

**Propósito:** receber paradas de outro motorista escaneando QR code

- Header com modo único: `TransferStopsQr`
- Hint: `"Leia para transferir paradas"` (`transfer_stops_scan_hint`)
- `"Leia o QR code para assumir paradas"` (`transfer_stops_receive_details`)
- Erro de QR inválido: `"Tente novamente usando um código de transferência válido do Spoke"` (`transfer_stops_scan_error`)
- Resultado: `LabelScannerResult.ScanTransferStopsQrCodeComplete(routeId, routeTitle, transferId, stopCount)`

Sheet pós-scan (confirmação de recebimento):
- Corpo: `"Adicionando à rota %1$s"` (`transfer_stops_receive_confirm_body`)
- Botão trocar rota: `"Escolher outra rota"` (`transfer_stops_receive_confirm_change_route`)

---

## 10. Diálogos de erro de câmera

Triggering: `ScannerCameraError(errorType: ScannerErrorType)`

`ScannerErrorType` (enum):
- `CameraPermissionDenied` →
  - Título: `"Permita acesso à câmera para usar o leitor"` (`label_scanner_camera_permission_dialog_title`)
  - Corpo: `"O %1$s usa sua câmera para ler endereços e tirar fotos."` (`label_scanner_camera_permission_dialog_description`)
  - Botão: `"Abrir configurações"` (`label_scanner_camera_permission_dialog_open_settings`)
- `DefaultCameraNotFound` →
  - Título: `"Câmera não encontrada"` (`label_scanner_error_camera_not_found_title`)
  - Corpo: `"Este recurso requer uma câmera traseira funcional."` (`label_scanner_error_camera_not_found_description`)
- `InitializationError` →
  - Título: `"Não foi possível iniciar a câmera"` (`label_scanner_error_camera_initialization_title`)
  - Corpo: `"Feche outros apps que possam estar usando a câmera. Reinicie seu dispositivo se o problema persistir."` (`label_scanner_error_camera_initialization_description`)
- Botão retry: `"Tentar novamente"` (`label_scanner_try_again_button`)

---

## 11. Diálogo de seleção de idioma OCR

Triggering: `TrailingActionButton.LanguageSelect` no header

- Título: `"Idioma"` (`label_scanner_language_dialog_title`)
- Lista de opções com radio button (single select, seleção prévia = idioma atual)
- Idioma padrão exibido como: `"Padrão"` (`label_scanner_default_language_name`)

`LabelScannerLanguage` (enum — 13 valores):

| Nome enum | Código ISO | Script |
|---|---|---|
| `Default` | `en` | Latin — exibido como "Padrão" |
| `English` | `en` | Latin |
| `Portuguese` | `pt` | Latin |
| `Dutch` | `nl` | Latin |
| `French` | `fr` | Latin |
| `German` | `de` | Latin |
| `Italian` | `it` | Latin |
| `Japanese` | `ja` | Japanese |
| `Korean` | `ko` | Korean |
| `Polish` | `pl` | Latin |
| `Chinese` | `zh` | Chinese |
| `Spanish` | `es` | Latin |
| `Turkish` | `tr` | Latin |

Padrão inicial: `Default` (código `en`, exibido como "Padrão").

---

## 12. Estado de sem conexão

Exibido quando `n = false` no state:
- Texto: `"Sem conexão com a internet"` (`label_scanner_no_internet_connection`)
- Texto: `"Verifique seus dados móveis ou Wi-Fi."` (`label_scanner_please_check_your_network`)
- Botão: `"Tentar novamente"` (`label_scanner_try_again_button`)

Diálogo barcode manual (sem conexão):
- `"Sem conexão com a internet."` (`barcode_manual_input_no_internet_connection`)

---

## 13. Resultados retornados ao chamador (LabelScannerResult)

Sealed class Parcelable retornada via FragmentManager result bundle com chave `"scanner_result"`:

| Resultado | Dados | Quando |
|---|---|---|
| `NewStopAdded(stopId)` | BaseStopId | Endereço ou barcode adicionado como nova parada |
| `WrongAddress(address)` | String | Usuário confirmou que o endereço está errado |
| `ChangeAddress(address)` | String | Novo endereço escolhido (modo ChangeAddress) |
| `ScannerCameraError(error)` | ScannerErrorType | Câmera falhou ao inicializar |
| `CancelScanBarcode` | — | Usuário cancelou scan de barcode |
| `ScanBarcodeDeliveryComplete` | — | Entrega confirmada por barcode |
| `ScanBarcodeLoadVehicleComplete` | — | [B2B — cortar] |
| `ScanTransferStopsQrCodeComplete(routeId, title, transferId, stopCount)` | — | QR de transferência lido com sucesso |
| `ManifestImportComplete(sessionId)` | MediaImportSessionId | Import de manifesto concluído |

---

## 14. Navegação

- **Abertura:** `action_label_scanner` (NavGraph `nav_main.xml`), argumento `LabelScannerArgs` (Parcelable)
- **Saída:** `finishFragment()` → popBackStack ou `k6f.m36879n`; resultado entregue via `FragmentManager.setFragmentResult`
- **Para busca manual:** `action_home` (retorna para tela de busca/home)
- **Para import de manifesto (câmera→galeria):** navega para `ImportManifestGallery(Mode.Scanner)`
- **Para ajuste de localização:** `EditStopFixAddressIssueAdjustLocationResult` passado via bundle `"edit_stop_fix_address_issue_adjust_location_result"`
- **Para detalhes de parada:** `EditRouteResultKeys.OpenStopDetailsPayload` via bundle `"stop_payload"`, contexto `OpenStopContextType`

---

## 15. Comportamentos e feedbacks

- **Vibração** ao reconhecer barcode (`VibrationEffect`)
- **Efeito sonoro** ao reconhecer endereço e ao adicionar parada (`SoundEffect`)
- **Autofoco pontual** via toque no PreviewView (janela 2000ms, cooldown para evitar coroutine dupla)
- **keepScreenOn = true** enquanto o scanner está aberto
- **Orientação forçada** durante uso; restaurada a `requestedOrientation = -1` em `onDestroy`
- **ScannerDialogAnimations** estilo aplicado à window do Dialog

---

## 16. Drawables mapeados

| Drawable | Lucide equivalente sugerido |
|---|---|
| `ic_flashlight_off` | `FlashlightOff` |
| `ic_flashlight_on` | `Flashlight` |
| `ic_barcode` | `ScanBarcode` |
| `ic_barcode_wrong_package` | `ScanBarcode` (com indicador de erro) |
| `ic_invalid_barcode` | `XCircle` |
| `photo_camera_24px` / `photo_camera_16` | `Camera` |
| `camera_toggle_button_80` | — (botão shutter customizado) |

---

## 17. Precisa-runtime

- Animação de entrada/saída do Dialog (`ScannerDialogAnimations` — slide)
- Comportamento exato do autofoco ao tocar na câmera (feedback visual do ponto de foco)
- Aparência visual do overlay de regiões detectadas (C3918b — bounded regions highlight)
- Layout exato do sheet de edição (EditStopSheet) dentro do scanner — posição âncora vs tela cheia
- Comportamento de snap do sheet (Dismissed → Default → Expanded)
- Posicionamento do botão de lanterna e de idioma relativos ao header quando `showModeSelector = false`
- Comportamento de "Ler o próximo" (`search_button_scan_next` = `"Ler o próximo"`) — botão que aparece após adicionar parada para escaner o próximo sem fechar o scanner

---

## Notas de corte para RotPro

1. `BarcodeLoadVehicle` — [B2B — cortar] completamente; a string `camera_scan_load_workflow_title` e `camera_scan_no_permission` não precisam de equivalente.
2. `camera_scan_no_permission` (despachante) — [B2B — cortar]; RotPro não tem despachante.
3. `LabelScannerLanguage` — manter pelo menos `Default` e `Portuguese`; outros idiomas são nice-to-have.
4. O scanner é um **Dialog fullscreen**, não uma rota de navegação separada. Em Flutter: `showDialog` com `barrierDismissible: false` + `Scaffold` interno com `WillPopScope`.
5. A câmera usa **CameraX** (`PreviewView` + `ImageAnalysis`). Em Flutter: `camera` package + `google_mlkit_text_recognition` para OCR + `google_mlkit_barcode_scanning` para barcode.
6. `AddressTextExtractor` usa ML Kit On-Device — não depende de backend para o OCR; o backend é chamado apenas para **geocodificar o texto reconhecido** em coordenadas (campo `performSearch`).
