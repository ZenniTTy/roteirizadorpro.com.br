# Front blueprint — photo

**Data:** 2026-06-21
**Fonte:** `~/spoke-dump/jadx-out/sources/com/circuit/p016ui/photo/` + `com/circuit/p016ui/delivery/` + `com/circuit/components/dialog/` + `com/circuit/core/entity/` + strings PT-BR verbatim
**Escopo:** fotos de pacote e comprovante de entrega (POD) — fluxo B2C do motorista

---

## Visão geral da área

A área `photo` não é uma tela standalone navegável. É um conjunto de **componentes/diálogos** que surgem dentro do fluxo de entrega (tela Delivery/DetailSheet):

1. **PackagePhotoViewerFragment** — visor de foto(s) de pacote (diálogo full-screen sem dim)
2. **ProofViewerFragment** — visor de comprovante de entrega/coleta (diálogo full-screen sem dim, suporta múltiplos itens com paginação)
3. **ShutterButton** (composable) — botão disparador de câmera reutilizável
4. **CameraPermissionDeniedDialog** — diálogo de permissão de câmera negada
5. **DeleteProofDialog** — diálogo de confirmação de exclusão de comprovante

---

## 1. PackagePhotoViewerFragment

### Nome / propósito / classe
- Nome: **Visualizador de foto do pacote**
- Propósito: Exibe carrossel de fotos capturadas pelo motorista para uma parada específica. Permite navegar entre fotos e deletar individualmente.
- Classe: `com.circuit.ui.photo.PackagePhotoViewerFragment` extends `CircuitDialogFragment`
- ViewModel: `PackagePhotoViewerViewModel`

### Estrutura (em ordem)
O fragmento é um diálogo Compose full-screen. A composable raiz é chamada via `nya.m39857b(state, onCloseClick, onDeleteClick)`:

1. **Carrossel de fotos** — lista horizontal paginável de URIs (`List<Uri>`)
2. **Índice selecionado** — `selectedIndex: Int` (default: posição da `photoUri` nos args; fallback 0 se não encontrada)
3. **Botão fechar** — ícone X no canto superior (dispara `onCloseClick → PhotoViewerEvent.Close`)
4. **Botão deletar** — visível condicionalmente (`showDeleteButton: Boolean`); ao tocar dispara `PhotoViewerEvent.ShowConfirmDeleteDialog(uri)`

### Estado do ViewModel — `PhotoViewerState`
```
PhotoViewerState(
  photos:            List<Uri>   // URIs das fotos da parada (observadas via PackagePhotoManager)
  selectedIndex:     Int         // foto inicial a exibir
  showDeleteButton:  Boolean     // true quando o usuário pode deletar (controlado por AppFeature.ChangeStopNotes)
)
```
Default/construtor vazio: `photos = emptyList(), selectedIndex = 0, showDeleteButton = true`

### Eventos de saída (sealed class `PhotoViewerEvent` / `AbstractC3839b`)
- `Close` — fecha o diálogo (`k6f.m36879n` = dismiss)
- `ShowConfirmDeleteDialog(uri: Uri)` — abre diálogo de confirmação de deleção via `C2618r.m8440a`

### Argumentos de entrada — `PackagePhotoViewerArgs`
```
PackagePhotoViewerArgs(
  stopId:   BaseStopId<*>   // identifica a parada
  photoUri: Uri             // URI da foto a abrir inicialmente
)
```

### Comportamento de janela
- Background: transparente (`R.color.transparent`)
- Dim amount: **0.0f** (sem escurecimento de fundo)
- Animação: `Animation_FillDialogNoExit` (entra mas não anima saída)

### Strings PT-BR relevantes
- `"Remover foto"` (`remove_photo_warning_alert_title`)
- `"Esta foto será removida da parada permanentemente."` (`remove_photo_warning_alert_body`)
- `"Fotos são excluídas depois de 30 dias"` (`package_photo_cleanup_warning`)

### Drawables / ícones
- Botão câmera disparador: `camera_toggle_button_80` (círculo 80dp, branco sobre fundo semi-transparente escuro)
- Botão "Adicionar foto": `ic_add_photo_24` (ícone câmera Material 24dp, cor preta)
- Câmera 16dp: `photo_camera_16` (para thumbnails/contadores)
- Câmera 24dp: `photo_camera_24px` (para controles secundários, cor `#4a5874`)

Equivalência Lucide aproximada: `Camera` (Lucide) para os ícones de câmera padrão.

### Navegação
- Aberto de: DetailSheet / EditStopPage via `C2618r.m8440a` (open dialog)
- Fecha via: evento `Close` (dismiss) ou após confirmação de deleção
- Após deleção confirmada: fecha automaticamente (via `C2618r.m8440a` com `ShowConfirmDeleteDialog`)

### Precisa-runtime
- Layout exato do carrossel (paginação horizontal ou vertical, indicadores de página, gestos de swipe)
- Posicionamento do botão fechar e deletar no overlay
- Animação de transição entre fotos

---

## 2. ProofViewerFragment

### Nome / propósito / classe
- Nome: **Visualizador de comprovante de entrega/coleta**
- Propósito: Exibe comprovantes de entrega (fotos e/ou assinaturas) de uma parada. Suporta múltiplos itens, paginação, e deleção com retorno de resultado ao caller.
- Classe: `com.circuit.ui.delivery.ProofViewerFragment` extends `CircuitDialogFragment`
- ViewModel: `C3241h` (classe ofuscada = ProofViewerViewModel)

### Estrutura
Diálogo full-screen idêntico ao PackagePhotoViewerFragment em termos de janela.

1. **Carrossel de ProofViewerItems** — lista paginável
2. **Índice selecionado** — `selectedIndex: Int`
3. **Botão fechar** — dispara evento `ProofViewModelEvent.Close` (dismiss)
4. **Botão deletar** (condicional, `showDeleteButton: Boolean`) — dispara `ProofViewModelEvent.ShowDeleteConfirm`
5. **Retorno de resultado** — ao deletar, retorna via `NavigationExtensionsKt.m10092f(fragment, resultKey, value)` para o caller (resultado é `Boolean`)

### Argumentos de entrada — `ProofViewerArgs`
```
ProofViewerArgs(
  proofViewerItems:  ArrayList<ProofViewerItem>   // lista de comprovantes
  selectedIndex:     Int                          // item inicial
  showDeleteButton:  Boolean                      // exibir botão de deleção
  resultKey:         ProofViewerResultKey?        // chave para retornar resultado (nullable)
)
```

### Item do carrossel — `ProofViewerItem`
```
ProofViewerItem(
  uri:  Uri      // URI do comprovante (foto ou assinatura)
  tint: Boolean  // se true: aplica tint/filtro na imagem (usado para assinaturas)
)
```

### Eventos de saída (sealed class `AbstractC3240g` / `ProofViewModelEvent`)
- `a` (Close) — dismiss
- `b` → abre `DeleteProofDialog` via `C2618r.m8440a`
- `c` → abre outro diálogo via `C2618r.m8441b`
- `d(value: Boolean)` → retorna resultado ao caller via `resultKey`

### Comportamento de janela
Idêntico ao PackagePhotoViewerFragment: background transparente, dim 0.0f, animação `Animation_FillDialogNoExit`.

### Strings PT-BR relevantes
- `"Apagar status de entrega?"` (`delivery_delete_proof_dialog_title`)
- `"Esta parada será revertida para não tentada"` (`delivery_delete_proof_dialog_warning_1`)
- `"Assinaturas, fotos e notas de entrega serão excluídas"` (`delivery_delete_proof_dialog_warning_2`)
- `"Comprovante de entrega"` (`proof_of_delivery_delivery`)

### Precisa-runtime
- Layout do carrossel com tint para assinaturas (fundo branco? fundo escuro?)
- Posição dos botões fechar/deletar
- Como o caller recebe o resultado (back-stack entry vs fragment result API)

---

## 3. ShutterButton (Composable)

### Nome / propósito / classe
- Nome: **Botão disparador de câmera**
- Propósito: Composable reutilizável que renderiza o botão circular de captura de foto. Usa haptic feedback ao disparar.
- Arquivo: `ShutterButton.kt` (classe ofuscada `C3840c`)

### Estrutura
1. **Ícone** — drawable `camera_toggle_button_80` (80dp, círculo branco sobre fundo semi-transparente)
2. **Área clicável** — tamanho mínimo 40dp (`n7c.m39496a(40.0f, ...)`)
3. **Haptic feedback** — `HapticFeedbackType.LongPress` (ou similar) ao tocar
4. **Callback** — `onShutter: () -> Unit` invocado após haptic

### Comportamento
- Referência: `ShutterButton$onShutter` — chama `HapticFeedback.performHapticFeedback(type)` antes de invocar `onShutter()`
- O composable observa o `LocalHapticFeedback` via `CompositionLocalsKt`

### Precisa-runtime
- Tamanho visual exato (parece ser 80dp pelo drawable)
- Posicionamento dentro da câmera (bottom-center)

---

## 4. CameraPermissionDeniedDialog

### Nome / propósito / classe
- Nome: **Diálogo — Permissão de câmera negada**
- Propósito: Exibido quando o usuário tenta tirar foto mas a permissão de câmera foi negada. Oferece botão para ir às configurações do sistema.
- Classe: `com.circuit.components.dialog.CameraPermissionDeniedDialog` extends `AdaptiveModalDialog`
- Tamanho modal: `AdaptiveModalSize.Small` (mesmo tamanho em portrait, landscape e dialog)

### Estrutura (via `qj3.m43025a`)
1. **Título** — `"Permita acesso à câmera para usar o leitor"` (`label_scanner_camera_permission_dialog_title`)
2. **Descrição** — `"O %1$s usa sua câmera para ler endereços e tirar fotos."` (`label_scanner_camera_permission_dialog_description`)
3. **Botão primário** — `"Abrir configurações"` (`label_scanner_camera_permission_dialog_open_settings`) → abre configurações do sistema
4. **Botão secundário / dismiss** — fecha o diálogo (callback `dismiss`)

### Strings PT-BR verbatim
- Título: `"Permita acesso à câmera para usar o leitor"`
- Descrição: `"O %1$s usa sua câmera para ler endereços e tirar fotos."` (substituir `%1$s` pelo nome do app)
- Botão: `"Abrir configurações"`

### Navegação
- Aberto de: `LabelScannerFragment.checkPermissionsAndStartCamera` quando permissão `CAMERA` negada
- Callbacks: `onOpenSettings: () -> Unit`, `dismiss: () -> Unit`

### Precisa-runtime
- Aparência exata do `AdaptiveModalDialog` (sheet no portrait, diálogo centralizado no landscape)

---

## 5. DeleteProofDialog

### Nome / propósito / classe
- Nome: **Diálogo — Apagar status de entrega?**
- Propósito: Confirmação antes de apagar o comprovante de entrega. Informa o usuário que a parada volta para "não tentada" e que fotos, assinaturas e notas serão excluídas.
- Classe: `com.circuit.components.dialog.DeleteProofDialog` extends `AdaptiveModalDialog`
- Tamanho modal: `AdaptiveModalSize.Small`

### Estrutura (via `kh5.m37045b`)
1. **Título** — `"Apagar status de entrega?"` (`delivery_delete_proof_dialog_title`)
2. **Aviso 1** — `"Esta parada será revertida para não tentada"` (`delivery_delete_proof_dialog_warning_1`)
3. **Aviso 2** — `"Assinaturas, fotos e notas de entrega serão excluídas"` (`delivery_delete_proof_dialog_warning_2`)
4. **Botão de confirmação (destrutivo)** — `onConfirm: () -> Unit`
5. **Botão cancelar / dismiss** — `dismiss: () -> Unit`

### Assinatura do construtor
```kotlin
DeleteProofDialog(
  onConfirm: () -> Unit,  // wd5 = Function0 que executa a deleção
  context: Context
)
```

### Strings PT-BR verbatim
- `"Apagar status de entrega?"`
- `"Esta parada será revertida para não tentada"`
- `"Assinaturas, fotos e notas de entrega serão excluídas"`

### Precisa-runtime
- Texto exato do botão de confirmação (pode ser "Apagar" ou "Confirmar")
- Ordem dos botões (confirmar antes ou depois do cancelar)

---

## 6. Modelo de domínio — Comprovante (POD)

### PhotoDetail (entidade principal)
```
PhotoDetail(
  url:        Uri            // URI local ou remota da foto
  status:     UploadStatus  // Uploading | Uploaded
  type:       Type          // Proof | Signature
  strictness: Strictness    // REQUIRED | REQUESTED | UNSUPPORTED
)
```

### ProofOfDeliveryRequirement (enum)
`REQUIRED | NOT_REQUIRED`

### Strictness (enum — aplicado por nível de evidência)
`REQUIRED | REQUESTED | UNSUPPORTED`

### PhotoEvidenceState (sealed class — estado do carrossel na tela de entrega)
```
PhotosPending       — sem fotos ainda
PhotosCollected(files: List<Uri>)   — fotos capturadas
FailedToCollectPhotos(evidenceCollectionFailure: EvidenceCollectionFailure)
```

### EvidenceCollectionFailure
```
EvidenceCollectionFailure(
  reason:     EvidenceCollectionFailureReason   // DEVICE_MALFUNCTION | BATTERY_DIED | APP_CRASHED | OTHER | UNSUPPORTED
  message:    String?
  strictness: Strictness
)
```

### RequiredEvidenceState (enum — estado agregado de foto + assinatura)
`COLLECTED_OR_EMPTY | SIGNATURE_COLLECTION_FAILED | PHOTO_COLLECTION_FAILED | BOTH_FAILED`

---

## 7. PackagePhotoManager (repositório local)

### Propósito
Gerencia fotos de pacote armazenadas localmente no dispositivo. Organiza por `RouteId` e `StopId` em diretórios internos.

### Estrutura de pastas (inferida do código)
```
package_photos/
  {user-<userId>|team-<teamId>}/
    <routeId>/
      <stopId>/
        [fotos .jpg]
```

### Operações expostas (interface `iya`)
| Método | Ação |
|--------|------|
| `copyPackagePhotos(src, dst)` | copia fotos de uma parada para outra (ex: rota duplicada) |
| `deleteAllRoutePackagePhotos(routeId)` | apaga todas as fotos da rota |
| `getStopPackagePhotos(stopId)` | retorna `List<Uri>` das fotos de uma parada (suspend) |
| `countStopPackagePhotos(stopId)` | conta fotos (com LruCache de 1 slot+tamanho da rota) |
| `cleanup(cutoff: Instant)` | remove fotos mais antigas que `cutoff` |
| `onRouteUpdated(route)` | redimensiona o cache LRU |
| `deleteStopPackagePhoto(stopId, uri)` | apaga uma foto específica |
| `deleteAllStopPackagePhotos(stopId)` | apaga todas as fotos de uma parada |
| `createNewPackagePhotoFile(stopId, suffix)` | cria arquivo vazio para nova captura, invalida cache |
| `observeStopPackagePhotos(stopId)` | `Flow<List<Uri>>` reativo |
| `observeRoutePackagePhotos()` | `Flow<RouteId>` sinaliza qual rota teve fotos atualizadas |

### Política de retenção
- Fotos são **excluídas automaticamente após 30 dias** (`Duration.ofDays(30L)`)
- Worker `CleanupPackagePhotosWorker` executa com intervalo mínimo de **7 dias** entre limpezas
- String visível ao usuário: `"Fotos são excluídas depois de 30 dias"` (`package_photo_cleanup_warning`)

---

## 8. Fluxo de captura — onde fotos são tiradas

### Pontos de entrada (analytics `PackagePhotos.Source`)
| Fonte | Contexto |
|-------|---------|
| `AddressScanner` | "Address scanner" — câmera do leitor de etiquetas |
| `EditStop` | "Edit stop" — tela de edição da parada |
| `EditNote` | "Edit note" — edição de nota |
| `SDS` | "Stop detail sheet" — sheet de detalhes da parada |

### Contexto de embedding (analytics `PackagePhotos.EmbeddedContext`)
| Valor | Descrição |
|-------|-----------|
| `Standalone` | câmera aberta de forma independente |
| `AddressScanner` | embarcada no leitor de endereços |
| `Search` | embarcada na busca |

### Callback no DeliveryViewModel
- `askForPicture()` — dispara abertura da câmera (chamado pelo DeliveryFragment via `DeliveryFragment$Content$10$1`)
- `onDeletePhotoClick(uri: Uri)` — chamado para deletar foto específica (via `DeliveryFragment$Content$12$1`)
- `onDeliveryProofErrorClick()` / `onDisabledDeliveryProofErrorClick()` — erro no comprovante

### AutoOpenProof (enum — abertura automática de POD)
```
AutoOpenProof: Signature | Photo
```
Controla qual coletor de POD o app deve abrir automaticamente ao chegar em uma parada.

---

## 9. Strings PT-BR verbatim completas

### Câmera / captura
- `"Adicionar foto"` (`delivery_add_photo_placeholder`)
- `"Adicionar parada e tirar foto"` (`add_stop_and_take_photo`)
- `"Fotos são excluídas depois de 30 dias"` (`package_photo_cleanup_warning`)

### POD — Bloqueio / toasts
- `"Adicione fotos para continuar."` (`pod_blocking_toast_title_photos`)
- `"Adicione uma assinatura para continuar."` (`pod_blocking_toast_title_signature`)
- `"Forneça o nome do recebedor para continuar."` (`pod_blocking_toast_consignee_name`)
- `"As fotos já foram obtidas."` (`pod_collected_photos_toast`)
- `"A assinatura já foi obtida."` (`pod_collected_signature_toast`)
- `"Algo deu errado?"` (`pod_collection_error_button`)

### POD — Diálogo de requisitos (`pod_hint_dialog_*`)
- Título: `"Requisitos"` (`pod_hint_dialog_title`)
- Descrição solicitado: `"Você poderá continuar depois de incluir %1$s."` (`pod_hint_dialog_first_description_requested`)
- Descrição obrigatório: `"Inclua %1$s para esta parada, caso contrário ela será marcada como não realizada."` (`pod_hint_dialog_first_description_required`)
- Segunda seção — título: `"Algo deu errado"` (`pod_hint_dialog_second_section_title`)
- Segunda seção — descrição: `"Explique por que não foi possível adicionar %1$s."` (`pod_hint_dialog_second_section_description`)
- Placeholder razão: `"Razão para não adicionar %1$s"` (`pod_hint_dialog_reason_placeholder`)
- Título razão: `"Relatar um problema"` (`pod_hint_dialog_reason_title`)

### POD — Placeholders (%1$s)
- foto: `"uma foto"` (`pod_hint_photo`)
- assinatura: `"uma assinatura"` (`pod_hint_signature`)

### POD — Labels
- `"Obrigatória"` (`pod_mandatory_label`)
- `"Marcar como não realizada"` (`pod_button_failed_title`)
- `"A parada precisa ser marcada como não realizada. Quaisquer notas também serão enviadas aos despachantes."` (`pod_mark_as_failed_disclaimer`)
- `"Comprovante de entrega"` (`proof_of_delivery_delivery`)
- `"Falta comprovante de %s"` (`delivery_state_missing_proof`) — onde `%s` = `"entrega"` ou `"coleta"`

### POD — Motivos de falha de coleta
- `"O dispositivo falhou"` (`pod_failure_reason_device_malfunction`) → `DEVICE_MALFUNCTION`
- `"A bateria acabou"` (`pod_failure_reason_battery_died`) → `BATTERY_DIED`
- `"O app travou"` (`pod_failure_reason_app_crashed`) → `APP_CRASHED`
- `"Outro"` (`pod_failure_reason_other`) → `OTHER`

### POD — Seção preenchida
- `"Para selecionar uma opção abaixo, primeiro exclua o comprovante de %1$s obtido."` (`pod_hint_second_section_description_filled`)
  - `"entrega"` (`pod_hint_second_section_description_filled_delivery`)
  - `"coleta"` (`pod_hint_second_section_description_filled_pickup`)

### POD — Footer dispatcher [B2B — cortar]
- `"As opções de entrega permitidas para esta parada são definidas pelo despachante."` (`pod_options_delivery_footer`) — visível quando há dispatcher; irrelevante para B2C

### POD — Razão obrigatória [B2B — cortar]
- `"Selecione o motivo pelo qual o comprovante de entrega obrigatório não pôde ser adicionado:"` (`pod_select_reason_prompt_delivery`)

### Câmera — Erros
- `"Não foi possível iniciar a câmera"` (`label_scanner_error_camera_initialization_title`)
- `"Feche outros apps que possam estar usando a câmera. Reinicie seu dispositivo se o problema persistir."` (`label_scanner_error_camera_initialization_description`)
- `"Câmera não encontrada"` (`label_scanner_error_camera_not_found_title`)
- `"Este recurso requer uma câmera traseira funcional."` (`label_scanner_error_camera_not_found_description`)
- `"Não foi possível tirar a foto"` (`label_scanner_photo_capture_error_title`)
- `"Não foi possível tirar e salvar a foto da câmera. Veja se a câmera está funcionando e se o dispositivo tem espaço suficiente."` (`label_scanner_photo_capture_error_description`)

---

## 10. O que é B2B — cortar no RotPro

| Item | Motivo |
|------|--------|
| `pod_options_delivery_footer` (footer do dispatcher) | Requer dispatcher B2B |
| `pod_select_reason_prompt_delivery/pickup` | Requer policy B2B de razão obrigatória |
| `pod_mark_as_failed_disclaimer` (notas para despachantes) | Sem dispatcher no B2C |
| `notification_settings_pod_channel_title` ("Confirmação extra") | Notificação push de POD — deferida para Slice 3 backend |
| `teams_proof_of_delivery_description` | Texto de paywall Teams — irrelevante |

---

## 11. Arquitetura de upload (background)

- `UploadProofWorker` — worker do WorkManager que faz upload dos comprovantes em background
- `PendingPhotoUploadWorkData` / `PendingPhotosUploadMetadata` — dados serializados (Moshi) da fila de upload pendente
- `MoshiPhotoTypeAdapter` — adaptador de tipo para URIs de foto no JSON

O upload acontece de forma **assíncrona pós-captura**. A foto fica local com `UploadStatus.Uploading` até o worker concluir, então passa para `Uploaded`.

---

## Notas finais

A pasta `com/circuit/p016ui/photo/` contém **apenas** o `PackagePhotoViewerFragment` (foto do pacote — capturada pelo motorista) e o `ShutterButton`. O comprovante de entrega formal (com assinatura + foto + razão de falha) vive em `com/circuit/p016ui/delivery/` — `ProofViewerFragment` + `DeliveryViewModel.askForPicture()`.

A distinção no Spoke: **foto do pacote** = capturada qualquer hora para documentar o conteúdo; **comprovante de entrega** = capturada no momento da entrega com strictness configurável pelo dispatcher.

Para o RotPro B2C, ambas as funcionalidades são relevantes. O campo `strictness` deve ser tratado como `REQUESTED` (não obrigatório) por padrão na ausência de dispatcher — o motorista vê o prompt mas pode continuar sem foto.
