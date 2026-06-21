# Front blueprint — delivery

**Data:** 2026-06-21
**Fonte:** `jadx-out/sources/com/circuit/p016ui/delivery/` + `res/values-pt-rBR/strings.xml`
**Escopo Á8 RotPro:** tela de marcar entregue/falha, coleta de comprovante (assinatura/foto), diálogo de pagamento, visualizador de prova, diálogo de requisitos POD.

---

## 1. DeliveryFragment — Tela principal de conclusão de parada

**Classe:** `com.circuit.ui.delivery.DeliveryFragment` extends `AdaptiveModalFragment`
**Propósito:** Modal adaptativo que consolida todo o fluxo de conclusão de uma parada: selecionar resultado (entregue/falhou), coletar comprovante (assinatura + foto), inserir notas, cobrar pagamento e submeter.

### 1.1 Estrutura — 4 modos (`DeliveryDisplayMode`)

O fragment muda completamente de conteúdo conforme `DeliveryDisplayMode`:

| Enum | Significado |
|---|---|
| `OPTIONS` | Seletor de resultado (motivos de sucesso ou falha) |
| `INPUTS` | Campos do comprovante (assinatura, foto, nome, notas) |
| `PAYMENT_COLLECTION` | Seletor de forma de pagamento (Cobrado ao cliente) |
| `SELECT_FAIL_REASON` | Seleção do motivo POD (quando prova obrigatória não pôde ser coletada) |

### 1.2 Modo OPTIONS — Seletor de resultado

**Campos/controles (em ordem):**
1. Botão Fechar (topo-esquerdo) → `onBackClick()`
2. Botão X (topo-direito) → `onCloseClick()`
3. Lista de `PackageState` disponíveis (chips/RadioButton) → `onPackageStateSelected(PackageState)`
4. Rodapé: "As opções de entrega permitidas para esta parada são definidas pelo despachante." — `pod_options_delivery_footer` → **[B2B — cortar]** (desabilitado em B2C, mas a string existe)
5. Botão primário: Submit → `onSubmitButtonClick()` / `onDisabledSubmitButtonClick()`
6. Botão secundário: "Marcar como não realizada" — `pod_button_failed_title` → `onSubmitButtonClick()` no modo falha
7. Banner "Algo deu errado?" — `pod_collection_error_button` → `onDeliveryProofErrorClick()` / `onDisabledDeliveryProofErrorClick()`

**Strings PT-BR:**
- Título: calculado dinamicamente — vide §1.6 Títulos por estado
- `"Marcar como não realizada"` (`pod_button_failed_title`)
- `"Algo deu errado?"` (`pod_collection_error_button`)
- `"As opções de entrega permitidas para esta parada são definidas pelo despachante."` (`pod_options_delivery_footer`)

### 1.3 Modo INPUTS — Coleta de comprovante

**Campos/controles (em ordem):**
1. Cabeçalho: título dinâmico (PackageState selecionado)
2. Seção Assinatura:
   - Placeholder: `"Adicionar assinatura"` (`delivery_add_signature_placeholder`)
   - Botão Adicionar → `askForSignature()` → abre `SignatureActivity`
   - Miniatura da assinatura coletada (se `SignatureCollected`)
   - Botão excluir assinatura → `onDeleteSignatureClick()` — confirmação: `"Remover assinatura"` (`remove_signature_dialog_title`)
   - Badge `"Obrigatória"` (`pod_mandatory_label`) quando `EvidenceRequirementLevel.MANDATORY`
3. Seção Foto(s):
   - Placeholder: `"Adicionar foto"` (`delivery_add_photo_placeholder`)
   - Botão Adicionar → `askForPicture()` → abre câmera
   - Grid/carrossel de fotos coletadas (até `maxPhotos` — default 5 calculado via slot de turno)
   - Botão excluir foto → `onDeletePhotoClick(Uri)` — confirmação: `"Remover foto"` (`remove_photo_warning_alert_title`) / `"Esta foto será removida da parada permanentemente."` (`remove_photo_warning_alert_body`)
   - Aviso: `"Fotos são excluídas depois de 30 dias"` (`package_photo_cleanup_warning`)
   - Badge `"Obrigatória"` quando necessário
4. Campo "Recebido por" / "Fornecido por":
   - Label: `"Recebido por"` (`delivery_received_by`) quando StopActivity=DELIVERY
   - Label: `"Fornecido por"` (`delivery_provided_by`) quando StopActivity=PICKUP
   - Input: nome do recebedor → `onConsigneeNameChange(String)`
5. Campo "Nota para o destinatário":
   - Placeholder: `"Nota para o destinatário"` (`delivery_recipient_notes_placeholder`)
   - Input → `onNoteForRecipientChange(String)`
6. Campo "Nota para uso interno":
   - Placeholder: `"Nota para uso interno"` (`delivery_internal_notes_placeholder`)
   - Input → `onNoteForInternalUseChange(String)`
7. Botão primário: Submit → `onSubmitButtonClick()`
8. Toasts de bloqueio (POD faltando):
   - `"Adicione uma assinatura para continuar."` (`pod_blocking_toast_title_signature`)
   - `"Adicione fotos para continuar."` (`pod_blocking_toast_title_photos`)
   - `"Forneça o nome do recebedor para continuar."` (`pod_blocking_toast_consignee_name`)

### 1.4 Modo PAYMENT_COLLECTION — Cobrança de pagamento

**Campos/controles (em ordem):**
1. Título: `"Cobrança de pagamento"` (`payment_collection_dialog_title`)
2. Label: `"Forma de pagamento"` (`payment_collection_dialog_payment_methods_list_title`)
3. Lista de opções (`DeliveryInfo.PaymentMethod`):
   - `CASH` → `"Dinheiro"` (`payment_method_cash`)
   - `CHECK` → `"Cheque"` (`payment_method_check`)
   - → `onPaymentMethodSelect(PaymentMethod)`
4. Botão Submit → confirma pagamento

**Nota:** Ativado somente quando a parada tem `paymentCollectionMode=true` E `requiresProofOfDeliveryFlag=true`. Assinatura de pagamento: `"Assinar para pagamento"` (`payment_collected_signature_dialog_title`).

### 1.5 Modo SELECT_FAIL_REASON — Seleção de motivo POD

Delegado ao `RequirementsHintFragment` — vide §3.

### 1.6 Títulos dinâmicos por estado

| Estado | StopActivity | `success` | String |
|---|---|---|---|
| OPTIONS | DELIVERY | true | `"Entregue com sucesso"` (`delivery_successfully_title`) |
| OPTIONS | DELIVERY | false | `"Falha na entrega"` (`delivery_failed_title`) |
| OPTIONS | PICKUP | true | `"Coleta bem-sucedida"` (`picked_up_successfully_title`) |
| OPTIONS | PICKUP | false | `"Falha na coleta"` (`picked_up_failed_title`) |
| INPUTS | qualquer | — | Nome do `PackageState` selecionado (calculado via `UiFormatters.m8449j`) |
| PAYMENT | — | — | `"Cobrança de pagamento"` |
| SELECT_FAIL_REASON | — | — | `"Algo deu errado?"` (`pod_collection_error_button`) |

### 1.7 Estado / defaults

| Campo | Default |
|---|---|
| `packageState` | `null` (nenhum selecionado; inicializado via `m9224N` que prefere `DELIVERED_TO_RECIPIENT` ou `PICKED_UP_FROM_CUSTOMER`) |
| `photosState` | `PhotoEvidenceState.PhotosPending` |
| `signatureState` | `SignatureEvidenceState.SignaturePending` |
| `consigneeName` | `null` |
| `noteForRecipient` | `""` |
| `noteForInternalUse` | `""` |
| `paymentCollectionMode` | `false` |
| `requiresProofOfDeliveryFlag` | `false` |
| `maxPhotos` | 5 (computado do time-slot do turno; default hardcoded = 5) |

### 1.8 Navegação

- **Aberto por:** EditRouteFragment/HomeFragment ao tocar botão de ação de parada (Entregue/Não entregue/Coletado)
- **Abre:** `SignatureActivity` (para assinatura), câmera implícita (para foto), `RequirementsHintFragment` (para POD), `ProofViewerFragment` (ao tocar miniatura)
- **Fecha via:** back, `onBackClick()`, `onCloseClick()`, ou submit bem-sucedido

### 1.9 Ícones (drawable → Lucide sugerido)

- Fechar/Back: `ic_back` / `ic_close` → `ArrowLeft` / `X`
- Assinatura: drawable de caneta/assinatura → `PenTool`
- Câmera: `ic_camera` → `Camera`
- Excluir foto: `ic_delete` → `Trash2`
- Excluir assinatura: `ic_delete` → `Trash2`

### 1.10 Precisa-runtime

- Animação de transição entre modos (OPTIONS→INPUTS)
- Comportamento exato do AdaptiveModalFragment (altura inicial, drag)
- Ordem real dos campos de assinatura vs foto (pode variar por configuração POD)
- Se foto e assinatura ficam em seções colapsáveis ou sempre visíveis

---

## 2. PackageState — Enum de resultados de parada

**Classe:** `com.circuit.core.entity.PackageState`

### 2.1 Valores completos

**Grupo DELIVERY (StopActivity=DELIVERY):**

| Enum | String PT-BR | String key |
|---|---|---|
| `DELIVERED_TO_RECIPIENT` | `"Entregue ao destinatário"` | `delivery_to_recipient_title` |
| `DELIVERED_TO_THIRD_PARTY` | `"Entregue a um terceiro"` | `delivery_to_third_party_title` |
| `DELIVERED_TO_MAILBOX` | `"Entregue na caixa de correio"` | `delivery_to_mailbox_title` |
| `DELIVERED_TO_SAFE_PLACE` | `"Deixado em lugar seguro"` | `delivery_to_safe_place_title` |
| `DELIVERED_TO_PICKUP_POINT` | *(sem string PT-BR encontrada)* | — |
| `DELIVERED_OTHER` | *(sem string PT-BR encontrada)* | — |
| `FAILED_NOT_HOME` | `"Destinatário não estava em casa"` | `failed_not_home_title` |
| `FAILED_PAYMENT_NOT_RECEIVED` | `"Pagamento não recebido"` | `failed_no_payment` |
| `FAILED_CANT_FIND_ADDRESS` | `"Não encontrei o endereço"` | `failed_no_address_title` |
| `FAILED_NO_PARKING` | `"Sem estacionamento"` | `failed_no_parking_title` |
| `FAILED_NO_TIME` | `"Sem tempo"` | `failed_no_time_title` |
| `FAILED_OTHER` | `"Outro"` | `failed_other_title` |
| `FAILED_PACKAGE_NOT_AVAILABLE` | `"Pacotes indisponíveis"` | `failed_package_not_available_title` |
| `FAILED_MISSING_REQUIRED_PROOF` | *(automático — não selecionável pelo motorista)* | — |
| `UNATTEMPTED` | *(estado interno)* | — |

**Grupo PICKUP (StopActivity=PICKUP):**

| Enum | String PT-BR | String key |
|---|---|---|
| `PICKED_UP_FROM_CUSTOMER` | `"Coletado com o cliente"` | `picked_up_from_customer_title` |
| `PICKED_UP_UNMANNED` | `"Coletado sem o cliente"` | `picked_up_unmanned_title` |
| `PICKED_UP_FROM_LOCKER` | `"Coletado do armário"` | `picked_up_from_locker_title` |
| `PICKED_UP_OTHER` | `"Outro"` | `picked_up_other_title` |
| `FAILED_NOT_HOME` | `"Cliente não estava em casa"` | `failed_picked_up_not_home_title` |
| `FAILED_PAYMENT_NOT_RECEIVED` | `"Pagamento não recebido"` | `failed_no_payment` |

### 2.2 Grupos pré-definidos (conjuntos das listas mostradas na tela)

O ViewModel seleciona o conjunto correto baseado em `StopActivity` + `isB2B` (flag do time):

- `f23891h1` = DELIVERY success set: `{DELIVERED_TO_RECIPIENT, DELIVERED_TO_THIRD_PARTY, DELIVERED_TO_MAILBOX, DELIVERED_TO_SAFE_PLACE, DELIVERED_TO_PICKUP_POINT, DELIVERED_OTHER}`
- `f23892i1` = PICKUP success set: `{PICKED_UP_FROM_CUSTOMER, PICKED_UP_UNMANNED, PICKED_UP_FROM_LOCKER, PICKED_UP_OTHER}`
- `f23893j1` = DELIVERY fail set: `{FAILED_NOT_HOME, FAILED_PAYMENT_NOT_RECEIVED, FAILED_CANT_FIND_ADDRESS, FAILED_NO_PARKING, FAILED_NO_TIME, FAILED_OTHER}`
- `f23894k1` = PICKUP fail set (B2B): adiciona `FAILED_PACKAGE_NOT_AVAILABLE`

**Nota B2B:** Quando `isB2B=true`, o ViewModel aplica filtros adicionais de disponibilidade por POD (`C26197vv.m45674b`). Em B2C, todos os valores dos grupos acima são exibidos → [B2B — cortar] apenas o filtro de disponibilidade e `DELIVERED_TO_PICKUP_POINT`.

### 2.3 Precisa-runtime

- Ordem de exibição dos chips dentro de cada grupo
- Se os grupos success/fail aparecem em abas separadas ou em lista única

---

## 3. RequirementsHintFragment — Diálogo de requisitos POD

**Classe:** `com.circuit.ui.delivery.requirementshint.RequirementsHintFragment` extends `AdaptiveModalFragment`
**Propósito:** Modal exibido quando assinatura ou foto é obrigatória (`MANDATORY`) e o motorista não conseguiu coletar. Permite relatar o motivo.

### 3.1 Campos/controles (em ordem)

1. Título: `"Requisitos"` (`pod_hint_dialog_title`)
2. Botão Fechar → `onCloseClick()`
3. Seção 1 — Descrição do requisito:
   - Se `MANDATORY`: `"Inclua %1$s para esta parada, caso contrário ela será marcada como não realizada."` (`pod_hint_dialog_first_description_required`) onde `%1$s` é `"uma assinatura"` (`pod_hint_signature`) ou `"uma foto"` (`pod_hint_photo`)
   - Se `OPTIONAL`: `"Você poderá continuar depois de incluir %1$s."` (`pod_hint_dialog_first_description_requested`)
   - Badge `"Obrigatória"` (`pod_mandatory_label`) quando MANDATORY
4. Seção 2 — Relatar problema (quando prova já foi coletada e usuário quer mudar):
   - Título: `"Algo deu errado"` (`pod_hint_dialog_second_section_title`)
   - Descrição alternativa: `"Para selecionar uma opção abaixo, primeiro exclua o comprovante de %1$s obtido."` (`pod_hint_second_section_description_filled`) onde `%1$s` = `"entrega"` / `"coleta"`
   - Descrição normal: `"Explique por que não foi possível adicionar %1$s."` (`pod_hint_dialog_second_section_description`)
   - `"Selecione o motivo pelo qual o comprovante de entrega obrigatório não pôde ser adicionado:"` (`pod_select_reason_prompt_delivery`) — lista de `EvidenceCollectionFailureReason`
   - `"Selecione o motivo pelo qual a prova de coleta obrigatória não pôde ser adicionada:"` (`pod_select_reason_prompt_pickup`)
   - → `onFailureReasonClick(EvidenceCollectionFailureReason)`
5. Campo texto — Explicação:
   - Placeholder: `"Razão para não adicionar %1$s"` (`pod_hint_dialog_reason_placeholder`)
   - Título: `"Relatar um problema"` (`pod_hint_dialog_reason_title`)
   - Input → `onExplanationChange(TextFieldValue)`
6. Botão "Concluir" → `onExplanationDoneClick()`
7. Aviso (quando MANDATORY e sem opções): `"A parada precisa ser marcada como não realizada. Quaisquer notas também serão enviadas aos despachantes."` (`pod_mark_as_failed_disclaimer`)

### 3.2 EvidenceCollectionFailureReason — Enum de motivos POD

| Enum | String PT-BR | String key |
|---|---|---|
| `DEVICE_MALFUNCTION` | `"O dispositivo falhou"` | `pod_failure_reason_device_malfunction` |
| `BATTERY_DIED` | `"A bateria acabou"` | `pod_failure_reason_battery_died` |
| `APP_CRASHED` | `"O app travou"` | `pod_failure_reason_app_crashed` |
| `OTHER` | `"Outro"` | `pod_failure_reason_other` |
| `UNSUPPORTED` | *(não exibido ao usuário — apenas quando plataforma não suporta)* | — |

**Nota:** O conjunto exibido são apenas os 4 primeiros (`f23769b = {DEVICE_MALFUNCTION, BATTERY_DIED, APP_CRASHED, OTHER}`).

### 3.3 EvidenceType enum

| Enum | Uso |
|---|---|
| `SIGNATURE` | Para fluxos de assinatura obrigatória |
| `PHOTO` | Para fluxos de foto obrigatória |

### 3.4 EvidenceRequirementLevel enum

| Enum | Significado |
|---|---|
| `MANDATORY` | Obrigatório — se não coletado, parada marcada como `FAILED_MISSING_REQUIRED_PROOF` |
| `OPTIONAL` | Solicitado — pode pular sem penalidade |
| `IGNORED` | Ignorado — campo nem aparece |

### 3.5 Args (RequirementsHintArgs)

- `evidenceType: EvidenceType` — SIGNATURE ou PHOTO
- `requirementLevel: EvidenceRequirementLevel` — MANDATORY/OPTIONAL/IGNORED
- `evidenceCollectionFailure: EvidenceCollectionFailure?` — falha anterior (se houver)
- `optionsEnabled: Boolean` — se o seletor de motivo está habilitado
- `isPickupStop: Boolean` — para adaptar strings de "entrega" vs "coleta"

### 3.6 Navegação

- **Aberto por:** DeliveryFragment via `onDeliveryProofErrorClick()` / `onDisabledDeliveryProofErrorClick()`
- **Fecha via:** `onCloseClick()`, back, ou `onExplanationDoneClick()` → retorna `EvidenceCollectionFailureReason` para DeliveryFragment via `onSubmitFailedPodReason()`

### 3.7 Precisa-runtime

- Layout exato das seções (expansível ou fixo)
- Comportamento quando `optionsEnabled=false` (seção 2 desabilitada)

---

## 4. SignatureActivity — Coleta de assinatura

**Classe:** `com.circuit.ui.delivery.signature.SignatureActivity` extends Activity
**Propósito:** Tela dedicada de captura de assinatura à mão. Lançada como `ActivityResultLauncher` via `SignatureActivity.C3252a` (contrato).

### 4.1 Campos/controles (em ordem)

1. Título/instrução ao destinatário: `"Assine para receber"` (`signature_title`)
2. Campo nome (pré-preenchido se `SignatureRequest.consigneeName != null`):
   - Placeholder: *(vazio ou nome do destinatário)*
3. Instrução ao destinatário: `"Depois de preencher seu nome e assinar, devolva este dispositivo ao motorista."` (`recipient_signature_instructions`)
4. Área de desenho (`InkView`):
   - Placeholder: `"Assine aqui"` (`signature_pad_placeholder`)
   - Suavização: ratio 0.75, traço mín 1.5px, máx 5.0px
5. Botão Cancelar → `cancelAndFinish()` → retorna `SignatureResult=null`
6. Botão Confirmar → `saveResultAndFinish()` → retorna `SignatureResult(file: Uri)`

### 4.2 SignatureRequest args

- `consigneeName: String?` — nome pré-preenchido
- `maxNameLength: Int` — comprimento máximo do campo nome
- `showConsigneeName: Boolean` — se o campo nome é exibido
- `isForPayment: Boolean` — adapta título para `"Assinar para pagamento"` (`payment_collected_signature_dialog_title`)

### 4.3 Fluxo de retorno

- Cancelou → `SignatureResult = null` → ViewModel preserva estado `SignaturePending`
- Confirmou → `SignatureResult(file: Uri)` → ViewModel transita para `SignatureCollected(file: Uri)`
- Se `requiresProofOfDeliveryFlag=true` + `SignatureCollected` + todos campos preenchidos → submit automático (`submitDeliveryInfo`)

### 4.4 Navegação

- **Aberto por:** DeliveryFragment via `askForSignature()` usando `ActivityResultLauncher`
- **Fecha:** retorna resultado ao launcher, DeliveryFragment processa

### 4.5 Precisa-runtime

- Aparência exata da área de assinatura (cor de fundo, bordas)
- Comportamento do botão confirmar quando a área está em branco (desabilitado?)

---

## 5. ProofViewerFragment — Visualizador de provas

**Classe:** `com.circuit.ui.delivery.ProofViewerFragment` extends `CircuitDialogFragment`
**Propósito:** Dialog full-screen sem dimming (transparente) para visualizar foto(s) ou assinatura coletada, com swipe entre itens.

### 5.1 Campos/controles

1. Carrossel/pager de `ProofViewerItem` (foto ou assinatura)
2. Indicador de página (dots ou contador)
3. Botão Fechar → fecha o dialog
4. Opção Excluir → `onDeletePhotoClick(Uri)` / `onDeleteSignatureClick()`
5. Opção Compartilhar → dialog de share nativo

### 5.2 ProofViewerArgs

- `items: List<ProofViewerItem>` — lista de Uri + tipo (foto/assinatura)
- `initialIndex: Int` — índice do item a mostrar primeiro
- `canEdit: Boolean` — se botões de excluir ficam visíveis

### 5.3 Animação

- `Animation_FillDialogNoExit` — entrada sem animação de saída (fill/fade in, não sai com animação)

### 5.4 Navegação

- **Aberto por:** DeliveryFragment ao tocar miniatura de foto ou assinatura
- **Fecha via:** botão fechar, back

### 5.5 Precisa-runtime

- Layout exato do carrossel (gesto de swipe ou pager com tabs)
- Comportamento ao excluir o último item (fecha automaticamente?)

---

## 6. AdditionalCompletionActionsControllerFragment — Controlador pós-conclusão

**Classe:** `com.circuit.ui.delivery.controller.AdditionalCompletionActionsControllerFragment`
**Propósito:** Fragment invisível (tema transparente) que orquestra ações extras pós-marcação: para WAYPOINT dispara o scanner de código de barras ou abre app externo; para DEPOT_PICKUP fecha direto. Não tem UI própria visível.

### 6.1 Fluxo

- `StopType.WAYPOINT` → chama `markAsDone` + lança ext. app (se registrado) → fecha
- `StopType.DEPOT_PICKUP` → chama `markAsDone` → fecha diretamente
- Scanner para confirmar (`scan_to_confirm`) e para carregar veículo (`scan_to_load`) → `LabelScannerArgs.ScannerLaunchMode.BarcodeScanDelivery` / `BarcodeLoadVehicle`

### 6.2 Strings relevantes

- Fluxo de carregamento de veículo: `"Carregar veículo"` (`load_vehicle_button_title`), `"Tudo pronto para carregar o veículo?"` (`load_vehicle_dialog_title`) — **escopo de setup, não delivery**

### 6.3 Precisa-runtime

- Quando exatamente o app externo é lançado vs apenas fecha
- Comportamento do scanner timeout/cancel

---

## 7. Botões de ação no stop sheet (EditRouteFragment)

Contexto: o `EditRouteFragment` / stop sheet expõe os botões primários de ação antes de abrir o `DeliveryFragment`.

### 7.1 Botões de ação primária

| String PT-BR | String key | Ação |
|---|---|---|
| `"Entregue"` | `delivered_button` | Abre DeliveryFragment (StopActivity=DELIVERY, success=true) |
| `"Não entregue"` | `failed_button` | Abre DeliveryFragment (DELIVERY, success=false) |
| `"Coletado"` | `picked_up_button` | Abre DeliveryFragment (PICKUP, success=true) |
| `"Navegar"` | `navigate_to_stop_button` | Abre app de navegação externo |
| `"Recomeçar"` | `restart_navigation_button_short` | Reinicia navegação (após chegada) |

### 7.2 Botões na tela do carro (Android Auto)

| String PT-BR | String key |
|---|---|
| `"Concluir parada"` | `car_complete_stop_title` |
| `"Concluir intervalo"` | `car_complete_break_title` |
| `"Concluir rota"` | `car_complete_route_title` |
| `"Concluir"` | `car_complete_button` |

### 7.3 Toasts pós-marcação

| Trigger | String PT-BR | String key |
|---|---|---|
| Parada N marcada como entregue | `"Parada %1$d marcada como entregue"` | `stop_x_marked_as_delivered_message` |
| Parada N marcada como não realizada | `"Parada %1$d marcada como não realizada"` | `stop_x_marked_as_failed_message` |
| Parada N marcada como coletada | `"Parada %1$d marcada como feita"` | `stop_x_marked_as_picked_up_message` |
| Stop sheet simples | `"Marcado como entregue"` | `stop_marked_as_delivered` |
| Stop sheet simples | `"Marcada como não realizada"` | `stop_marked_as_failed` |
| Stop sheet simples | `"Marcado como coletado"` | `stop_marked_as_picked_up` |

---

## 8. Diálogo "Apagar status de entrega" (RevertDelivery)

Exibido quando o motorista quer reverter uma parada já marcada.

### 8.1 Campos

1. Título: `"Apagar status de entrega?"` (`delivery_delete_proof_dialog_title`)
2. Aviso 1: `"Esta parada será revertida para não tentada"` (`delivery_delete_proof_dialog_warning_1`)
3. Aviso 2: `"Assinaturas, fotos e notas de entrega serão excluídas"` (`delivery_delete_proof_dialog_warning_2`)
4. Botão Confirmar / Cancelar

### 8.2 Precisa-runtime

- Onde exatamente este diálogo é acessado (menu kebab da parada? botão no stop sheet?)

---

## 9. Diálogo "Coleta vinculada não realizada" (PickupFailedDialog)

Exibido quando se tenta marcar entrega de uma parada cuja coleta vinculada falhou.

### 9.1 Campos

1. Título: `"Coleta vinculada não realizada:"` (`pickup_failed_dialog_title`)
2. Corpo: `"A coleta vinculada a esta parada foi marcada como não realizada. Prossiga somente se você tiver os itens desta entrega."` (`pickup_failed_dialog_body`)
3. Botão `"Confirmar entrega"` (`pickup_required_confirm_anyway_button`)
4. Botão Cancelar

---

## 10. Indicadores de estado de comprovante (missing proof)

Exibidos no stop sheet/lista quando prova obrigatória não foi coletada.

| String PT-BR | String key | Uso |
|---|---|---|
| `"Falta comprovante de %s"` | `delivery_state_missing_proof` | Banner no stop |
| `"entrega"` | `delivery_state_missing_proof_delivery` | Substitui %s para delivery |
| `"coleta"` | `delivery_state_missing_proof_pickup` | Substitui %s para pickup |
| `"Comprovante de entrega"` | `proof_of_delivery_delivery` | Título da seção de prova |
| `"As fotos já foram obtidas."` | `pod_collected_photos_toast` | Toast quando tenta adicionar foto já coletada |
| `"A assinatura já foi obtida."` | `pod_collected_signature_toast` | Toast quando tenta adicionar assinatura já coletada |

---

## 11. Fluxo geral de estados (máquina de estados implícita)

```
Parada pendente
  │
  ├─ tap "Entregue" / "Não entregue" / "Coletado"
  │       ↓
  │   DeliveryFragment abre
  │       │
  │       ├─ Modo OPTIONS → seleciona PackageState
  │       │       ↓
  │       ├─ Modo INPUTS (se POD ativo) → coleta assinatura/foto/nome
  │       │       │
  │       │       ├─ tap miniatura → ProofViewerFragment
  │       │       ├─ tap assinatura → SignatureActivity → retorna Uri
  │       │       ├─ tap foto → câmera → retorna Uri
  │       │       └─ tap "Algo deu errado?" → RequirementsHintFragment
  │       │               ↓ retorna EvidenceCollectionFailureReason
  │       │
  │       ├─ Modo PAYMENT_COLLECTION (se pagamento ativo)
  │       │       ↓ seleciona PaymentMethod
  │       │
  │       └─ Submit → markAsDone → AdditionalCompletionActionsControllerFragment
  │               ↓
  │         Toast "Parada N marcada como entregue/não realizada/feita"
  │
  └─ Parada concluída (status atualizado na lista)
```

---

## 12. Contexto de navegação ativa (fora do escopo delivery)

Strings relevantes para Á8 que residem fora do pacote delivery:

| String PT-BR | String key | Contexto |
|---|---|---|
| `"Indo para a próxima parada"` | `background_navigating_next_stop_message` | Notificação background |
| `"Próxima parada"` | `map_action_toast_next_stop` | Toast ao avançar |
| `"Seguir"` | `map_action_toast_follow` | Modo câmera follow |
| `"Rota completa"` | `map_action_toast_full_route` | Modo câmera rota completa |
| `"Próximas paradas"` | `map_action_toast_upcoming_stops` | Modo câmera |
| `"Pausa"` | `map_action_toast_static_break` | Pausa no mapa |
| `"Parada"` | `map_action_toast_static_stop` | Parada no mapa |
| `"Satélite ativado"` / `"Satélite desativado"` | `map_action_toast_satellite_on/off` | Toggle satélite |
| `"Role a tela até a próxima parada"` | `scroll_to_next_stop` | Hint de scroll |
| `"App de navegação"` | `navigation_app_title` | Seletor de app nav |
| `"Outro"` | `navigation_app_other` | App de navegação genérico |

---

## Resumo de enums e seus valores (prontos para pinagem em testes)

```dart
// PackageState — valores B2C por StopActivity

// DELIVERY success (exibidos quando StopActivity=DELIVERY + não-falha):
enum DeliverySuccessPackageState {
  DELIVERED_TO_RECIPIENT,   // "Entregue ao destinatário"
  DELIVERED_TO_THIRD_PARTY, // "Entregue a um terceiro"
  DELIVERED_TO_MAILBOX,     // "Entregue na caixa de correio"
  DELIVERED_TO_SAFE_PLACE,  // "Deixado em lugar seguro"
  DELIVERED_TO_PICKUP_POINT,
  DELIVERED_OTHER,
}

// DELIVERY fail (exibidos quando StopActivity=DELIVERY + falha):
enum DeliveryFailPackageState {
  FAILED_NOT_HOME,             // "Destinatário não estava em casa"
  FAILED_PAYMENT_NOT_RECEIVED, // "Pagamento não recebido"
  FAILED_CANT_FIND_ADDRESS,    // "Não encontrei o endereço"
  FAILED_NO_PARKING,           // "Sem estacionamento"
  FAILED_NO_TIME,              // "Sem tempo"
  FAILED_OTHER,                // "Outro"
}

// PICKUP success:
enum PickupSuccessPackageState {
  PICKED_UP_FROM_CUSTOMER, // "Coletado com o cliente"
  PICKED_UP_UNMANNED,      // "Coletado sem o cliente"
  PICKED_UP_FROM_LOCKER,   // "Coletado do armário"
  PICKED_UP_OTHER,         // "Outro"
}

// PICKUP fail:
enum PickupFailPackageState {
  FAILED_NOT_HOME,             // "Cliente não estava em casa"
  FAILED_PAYMENT_NOT_RECEIVED, // "Pagamento não recebido"
}

// POD failure reasons:
enum EvidenceCollectionFailureReason {
  DEVICE_MALFUNCTION, // "O dispositivo falhou"
  BATTERY_DIED,       // "A bateria acabou"
  APP_CRASHED,        // "O app travou"
  OTHER,              // "Outro"
  // UNSUPPORTED — não exibido
}

// EvidenceRequirementLevel:
enum EvidenceRequirementLevel { MANDATORY, OPTIONAL, IGNORED }

// EvidenceType:
enum EvidenceType { SIGNATURE, PHOTO }

// DeliveryDisplayMode:
enum DeliveryDisplayMode { OPTIONS, INPUTS, PAYMENT_COLLECTION, SELECT_FAIL_REASON }

// PaymentMethod:
enum PaymentMethod {
  CASH,  // "Dinheiro"
  CHECK, // "Cheque"
}

// StopActivity:
enum StopActivity { DELIVERY, PICKUP }

// StopType (para AdditionalCompletionActionsControllerFragment):
enum StopType { START, WAYPOINT, END, DEPOT_PICKUP }
```
