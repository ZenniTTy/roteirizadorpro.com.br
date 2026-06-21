# Front blueprint — dialogs

Data: 2026-06-21
Fonte: `~/spoke-dump/jadx-out/sources/com/circuit/p016ui/dialogs/` + `resources/res/values-pt-rBR/strings.xml`
Pacote original: `com.circuit.ui.dialogs.*`
Escopo: todos os 11 subdiretórios encontrados no jadx — catálogo exaustivo extraído puramente do dump estático (ADR-0045, dump-first).
Clone FUNCIONAL B2C: comportamento/estrutura replicados; identidade visual é original RotPro (ADR-0035).

---

## 1. AccessInstructionsSheet

**Classe:** `AccessInstructionsDialogKt` (Composable top-level function `AccessInstructionsSheet`)
**Pacote:** `com.circuit.ui.dialogs.accessinstructions`
**Tipo:** Bottom sheet adaptativo

### Propósito
Sheet para o motorista adicionar/editar instruções de acesso a um endereço de parada (ex.: "portão vermelho, campainha 3"). Oferece opção de salvar como padrão para aquele endereço.

### Estrutura (ordem visual, topo → baixo)
1. Cabeçalho: label "Instruções de acesso"
2. Campo de texto multilinha com placeholder "Adicionar instruções"
3. Botão primário: "Salvar"
4. Checkbox / toggle: "Salvar como padrão para este endereço"

### Strings PT-BR verbatim
- `"Instruções de acesso"` (`access_instructions_label`)
- `"Adicionar instruções"` (`instructions_placeholder`)
- `"Salvar"` (`settings_save_title`)
- `"Salvar como padrão para este endereço"` (`save_as_default_for_this_address_action`)

### Navegação
- Aberto por: tela de detalhes/edição de parada (EditStop / StopDetailSheet) ao tocar na propriedade "Instruções de acesso"
- Fecha: ao tocar "Salvar" (persiste) ou gesto de dismiss (descarta)

### Estados / defaults
- Campo inicia preenchido com o valor atual (ou vazio se não havia instrução)
- Toggle "Salvar como padrão" inicia desmarcado se for primeira edição; contrário se já havia padrão

### Ícones / drawables
- Nenhum ícone explícito no sheet confirmado pelo dump — Lucide sugerido para header: `FileText` ou `MapPin`

### Precisa-runtime
Não — estrutura completa derivada do dump; comportamento do toggle "padrão" pode ser confirmado em runtime se houver dúvida sobre persistência.

---

## 2. ApplyRouteChangesDialogFragment (Reoptimização de rota)

**Classe:** `ApplyRouteChangesDialogFragment`
**Pacote:** `com.circuit.ui.dialogs.applychanges`
**Tipo:** AdaptiveModalFragment (bottom sheet)

### Propósito
Sheet de reotimização exibido quando o motorista alterou paradas numa rota já otimizada. Apresenta duas opções: "Reotimizar rota" (recalcula tudo do zero) ou "Atualizar rota" (aplica só as mudanças). Quando o recurso de reotimização está bloqueado por plano, mostra ícone `help_outline` com ação de upgrade.

### Estrutura (ordem visual)
1. Cabeçalho dinâmico:
   - Se a feature está `Enabled`: título = "Alternativas de reotimização"
   - Se `PlanRestriction` ou `TeamRestriction`: título ainda "Alternativas de reotimização" + ícone `help_outline` (ação: abre `OptimizationExplainerDialogFragment`)
2. Opção A — "Reotimizar rota":
   - Ícone: `R.drawable.optimize` → Lucide `Zap` / `RotateCw`
   - Subtítulo: "Reordenar todas as paradas para melhor eficiência"
   - Estado: `Enabled` | `TeamRestriction` | `PlanRestriction`
3. Opção B — "Atualizar rota":
   - Ícone: `R.drawable.ic_arrow_right` → Lucide `ArrowRight`
   - Subtítulo: "Reordenar apenas as paradas alteradas"
   - Estado: `Enabled` | `TeamRestriction` | `PlanRestriction`
4. Botão primário (rodapé): "Aplicar alterações (%1$d)" — `%1$d` = número de paradas alteradas

### Strings PT-BR verbatim
- `"Alternativas de reotimização"` (`reoptimization_options_view_title`)
- `"Reotimizar rota"` (`reoptimize_title`)
- `"Reordenar todas as paradas para melhor eficiência"` (`optimization_dialog_reoptimize_route_subtitle`)
- `"Atualizar rota"` (`update_route`)
- `"Reordenar apenas as paradas alteradas"` (`optimization_dialog_update_route_subtitle`)
- `"Aplicar alterações (%1$d)"` (`apply_changes_button_title`)

### Navegação
- Aberto por: shell da rota ativa ao tocar "Aplicar alterações" / kebab "Reotimizar rota..."
- Ao tocar opção com `PlanRestriction` / `TeamRestriction`: emite evento `OpenOptimizationExplainer` → abre `OptimizationExplainerDialogFragment`
- Ao tocar botão "Aplicar alterações (N)": dispara reotimização e fecha o sheet (evento `Dismiss`)

### Estados / defaults / enums
- `FeatureStatus`: `Enabled` | `TeamRestriction` | `PlanRestriction`
- Argumento `changesCount` (Int): número de paradas alteradas exibido no botão
- Evento de saída (`AbstractC3270b`): `Dismiss` | `OpenOptimizationExplainer`
- Opções (`AbstractC3271c`): `ReoptimizeRoute(status)` | `UpdateRoute(status)`

### Ícones / drawables
- Reotimizar: `R.drawable.optimize` → Lucide `RotateCcw` ou `Zap`
- Atualizar: `R.drawable.ic_arrow_right` → Lucide `ArrowRight`
- Feature bloqueada: `R.drawable.help_outline` → Lucide `HelpCircle`

### Precisa-runtime
Sim — confirmar aparência visual dos estados `TeamRestriction` / `PlanRestriction` (lock visual ou badge).

---

## 3. OptimizationExplainerDialogFragment (Comparação de opções)

**Classe:** `OptimizationExplainerDialogFragment`
**Pacote:** `com.circuit.ui.dialogs.optimizationexplainer`
**Tipo:** AdaptiveModalFragment (bottom sheet / modal)

### Propósito
Explica ao motorista a diferença entre "Reotimizar" e "Atualizar rota". Tem animação Rive embutida com textos "Rota mais rápida" e "Pequenos desvios" como labels da animação. Permite selecionar qual modo usar.

### Estrutura (ordem visual)
1. Título: "Compare as opções"
2. Animação Rive interativa com duas legendas:
   - "Rota mais rápida" (label RUN = `SmallDeviationsRUN`) — para Reotimizar
   - "Pequenos desvios" (label RUN = `FasterRouteRUN`) — para Atualizar
3. Seletor de opção (dois itens, segmented-style):
   - "Atualizar rota" (`OptimizationType.UPDATE`) — badge: "Menos alterações"; ícone: `R.drawable.lock`
   - "Reotimizar" (`OptimizationType.REOPTIMIZE`) — badge: "Economia de tempo"; ícone: `R.drawable.priority`
4. Descrições por opção selecionada:
   - Reotimizar: "Recalcula a rota do zero para tentar achar uma ordem mais eficiente."
   - Atualizar rota: "Aplica as alterações preservando a estrutura da rota original o máximo possível."

### Strings PT-BR verbatim
- `"Compare as opções"` (`optimization_explainer_title`)
- `"Economia de tempo"` (`optimization_explainer_reoptimize_badge`)
- `"Menos alterações"` (`optimization_explainer_update_badge`)
- `"Reotimizar"` (`optimization_explainer_reoptimize`)
- `"Atualizar rota"` (`update_route`)
- `"Recalcula a rota do zero para tentar achar uma ordem mais eficiente."` (`optimization_explainer_reoptimize_description`)
- `"Aplica as alterações preservando a estrutura da rota original o máximo possível."` (`optimization_explainer_update_description`)
- `"Rota mais rápida"` (`optimization_explainer_faster_route`) — label da animação
- `"Pequenos desvios"` (`optimization_explainer_small_deviations`) — label da animação

### Navegação
- Aberto por: `ApplyRouteChangesDialogFragment` quando usuário toca opção com feature restrita (`onDisabledFeatureClick`)
- Fecha via dismiss (sem ação de seleção — é um explainer, não um seletor funcional quando aberto assim)
- Nota: quando aberto diretamente da shell (sem restrição), permite selecionar a opção

### Estados / defaults / enums
- `OptimizationType`: `REOPTIMIZE` (idx 0) | `UPDATE` (idx 1)
- Padrão selecionado: `UPDATE` (menos disruptivo)
- `selectedOption`: estado interno mutable
- Tem variante `LandscapeScreen` (classe interna) para layout horizontal

### Ícones / drawables
- Reotimizar: `R.drawable.priority` → Lucide `Zap`
- Atualizar: `R.drawable.lock` → Lucide `Lock`

### Precisa-runtime
Sim — confirmar comportamento da animação Rive e se o explainer também age como seletor quando aberto da shell principal.

---

## 4. ContactRecipientDialog

**Classe:** `ContactRecipientDialog`
**Pacote:** `com.circuit.ui.dialogs.contact`
**Tipo:** AdaptiveModalDialog (tamanho Small/compacto)

### Propósito
Modal de contato com o destinatário da parada. Exibe o nome do destinatário (ou "Destinatário" se não há nome) e botões de ação rápida: ligar, enviar mensagem, enviar e-mail.

### Estrutura (ordem visual)
1. Título: nome do destinatário (`recipient.name`) ou fallback `"Destinatário"`
2. Linha 1: ícone telefone + `"Ligação"` (ação: deep-link `tel:`)
3. Linha 2: ícone chat + `"Mensagem"` (ação: deep-link `sms:`)
4. Linha 3: ícone e-mail + `"E-mail"` (ação: deep-link `mailto:`)
   - Linhas de contato só aparecem quando o campo (`phone` / `email`) está preenchido no `Recipient`

### Strings PT-BR verbatim
- `"Destinatário"` (`stop_recipient_title`) — fallback do título
- `"Ligação"` (`contact_recipient_call`)
- `"Mensagem"` (`contact_recipient_text`)
- `"E-mail"` (`contact_recipient_email`)

### Navegação
- Aberto por: `EditStopCard` / `StopDetailSheet` ao tocar propriedade "Contato" (`stop_property_recipient_contact`)
- Fecha ao selecionar ação ou tocar fora

### Estados / defaults
- Recebe `Recipient(name: String?, phone: String?, email: String?)`
- Itens sem dados (phone=null, email=null) não são exibidos
- Se `name == null`: usa string fallback `"Destinatário"`

### Ícones / drawables
- Telefone: `R.drawable.phone_outline` → Lucide `Phone`
- Mensagem: `R.drawable.chat` → Lucide `MessageSquare`
- E-mail: `R.drawable.mail_outline` → Lucide `Mail`

### Precisa-runtime
Não — estrutura completa no dump.

---

## 5. EnableLocationFragment

**Classe:** `EnableLocationFragment` (extends `DialogFragment`)
**Pacote:** `com.circuit.ui.dialogs.location`
**Tipo:** AlertDialog nativo Android (`CircuitAlertDialog` / `DialogC2597f0`)

### Propósito
Alerta padrão que avisa o usuário que os serviços de localização estão desativados no dispositivo e solicita que os ative nas configurações do Android.

### Estrutura (ordem visual)
1. Título: "A localização está desativada no seu dispositivo"
2. Corpo: "Ative os \"Serviços de localização\" nas configurações do celular para continuar."
3. Botão primário: "Ativar localização" (abre configurações do sistema)
4. Sem botão cancelar (não cancelável)

### Strings PT-BR verbatim
- `"A localização está desativada no seu dispositivo"` (`location_is_turned_off_on_your_device_android`)
- `"Ative os \"Serviços de localização\" nas configurações do celular para continuar."` (`enable_location_services_in_your_phones_settings_android`)
- `"Ativar localização"` (`enable_location_android`)

### Navegação
- Aberto por: `HomeFragment` / qualquer tela que exija localização quando `locationProvider.isLocationEnabled() == false`
- Lógica: polling loop de 200 ms — quando localização volta a ser ativada, dismiss automático
- Não cancelável (`setCancelable(false)`)

### Estados / defaults
- Sem estados adicionais — exibido/fechado
- Fecha automaticamente quando localização é ativada (verifica a cada 200 ms)

### Ícones / drawables
- Nenhum ícone no conteúdo; usa estilo de AlertDialog padrão

### Precisa-runtime
Não — estrutura completa derivada.

---

## 6. PackageCountSheet

**Classe:** `PackageCountDialogKt` (Composable `PackageCountSheet`)
**Pacote:** `com.circuit.ui.dialogs.packagecount`
**Tipo:** Bottom sheet adaptativo

### Propósito
Sheet para o motorista definir a quantidade de pacotes em uma parada. Título "Pacotes", campo numérico "Número de pacotes".

### Estrutura (ordem visual)
1. Cabeçalho: "Pacotes"
2. Campo numérico com label: "Número de pacotes"
   - Quando parada tem entregas vinculadas (linked deliveries): campo desabilitado + toast "A quantidade de pacotes é definida pelas entregas vinculadas"

### Strings PT-BR verbatim
- `"Pacotes"` (`stop_setting_packages_title`)
- `"Número de pacotes"` (`stop_setting_package_count`)
- `"A quantidade de pacotes é definida pelas entregas vinculadas"` (`disabled_package_count_linked_deliveries_toast_body`)

### Navegação
- Aberto por: `EditStopCard` (evento `ShowPackageCountDialog(count)`) / `StopDetailSheet` (evento `OpenPackageCountDialog(count)`)
- Fecha ao confirmar (salva) ou dismiss

### Estados / defaults
- Input inicial = `count` recebido como argumento
- Estado desabilitado quando parada tem linked deliveries

### Ícones / drawables
- Nenhum ícone confirmado no dump

### Precisa-runtime
Não — mas confirmar comportamento do numpad (teclado numérico Android ou custom numpad estilo Á7).

---

## 7. PackageDetailsDialog

**Classe:** `PackageDetailsDialog`
**Pacote:** `com.circuit.ui.dialogs.packagedetails`
**Tipo:** AdaptiveModalDialog

### Propósito
Modal completo de detalhes de pacote. Combina: descrição do pacote (tipo + dimensão), identificação da parada (ID externo / barcode), localização no veículo (`PlaceInVehicle`), e integração com o "Localizador de Pacotes". Inclui botão "Definir lugar" para PlaceInVehicle.

### Estrutura (ordem visual)
1. Seção "Descrição do pacote":
   - Seletor de tipo (`PackageType`): "Caixa" | "Sacola" | "Carta"
   - Seletor de dimensão (`PackageDimension`): "Pequeno" | "Médio" | "Grande"
2. Seção "ID de parada" (`package_identification_feature_title`):
   - Status do label: badge "Pendente" se ainda não escaneado
   - Integração Localizador de Pacotes: "Localize os pacotes rapidamente com o Localizador de Pacotes" + botão "Localizador de pacotes"
3. Seção "Lugar no veículo":
   - Botão "Definir lugar" (abre PlaceInVehicle picker)
   - Valor atual exibido (ex.: "Frente / Esquerda / Chão")
4. Switch/toggle de confirmação de entrega (Precisa-runtime)

### Strings PT-BR verbatim
- `"Descrição do pacote"` (`package_description_title`)
- `"Caixa"` (`package_box`) | `"Sacola"` (`package_bag`) | `"Carta"` (`package_letter`)
- `"Pequeno"` (`package_small`) | `"Médio"` (`package_medium`) | `"Grande"` (`package_large`)
- `"ID de parada"` (`package_identification_feature_title`)
- `"Pendente"` (`package_label_status_pending`)
- `"Localize os pacotes rapidamente com o Localizador de Pacotes"` (`locate_packages_with_package_finder`)
- `"Localizador de pacotes"` (`package_finder_title`)
- `"Lugar no veículo"` (`place_in_vehicle`)
- `"Definir lugar"` (`set_place_in_vehicle_button`)
- **PlaceInVehicle X (lateral):** `"Esquerda"` | `"Direta"` (PT-BR usa "Direta" não "Direita")
- **PlaceInVehicle Y (frente/fundo):** `"Frente"` | `"Meio"` | `"Atrás"`
- **PlaceInVehicle Z (altura):** `"Chão"` | `"Prateleira"`
- Abreviaturas: `"E"` | `"D"` | `"F"` | `"M"` | `"A"` | `"C"` | `"P"`
- `"Não definido"` (`place_in_vehicle_not_set`)

### Navegação
- Aberto por: `StopDetailSheet` / `EditStopCard` ao tocar em propriedade de pacote
- Estado de retorno: `C3286a(packageDetails: PackageDetails, placeInVehicle: PlaceInVehicle)`
- Fecha com confirm → callback `onSave` / `onToggle`; dismiss → `onDismiss`

### Estados / defaults / enums
**PackageType** (enum): `BOX` | `BAG` | `LETTER`
**PackageDimension** (enum): `SMALL` | `MEDIUM` | `LARGE`
**PlaceInVehicle.X**: `LEFT` | `RIGHT`
**PlaceInVehicle.Y**: `FRONT` | `MIDDLE` | `BACK`
**PlaceInVehicle.Z**: `FLOOR` | `SHELF`
- Default: `PackageDetails(type=null, dimension=null)` / `PlaceInVehicle(null, null, null)`

### Ícones / drawables
- Nenhum ícone de seção explícito confirmado; usar Lucide `Box`, `Tag`, `MapPin` por inferência visual

### Precisa-runtime
Sim — confirmar layout do PlaceInVehicle picker (grade 3D? lista? radio?) e fluxo do ID de parada / scanner integrado.

---

## 8. EditRetailerDialog (Cliente/Retailer)

**Classe:** `EditRetailerDialogKt` (Composable)
**Pacote:** `com.circuit.ui.dialogs.retailer`
**Tipo:** Bottom sheet / modal adaptativo

### Propósito
Sheet para selecionar ou pesquisar um cliente (retailer/lojista) associado à parada. Exibe campo de busca com lista de clientes disponíveis.

### Estrutura (ordem visual)
1. Cabeçalho: "Cliente"
2. Campo de busca: placeholder "Pesquisar clientes…"
3. Lista de clientes filtrada (cada item: `ClientSearchRow`)
   - Toque em item → seleciona e fecha sheet

### Strings PT-BR verbatim
- `"Cliente"` (`stop_property_client_name`)
- `"Pesquisar clientes…"` (`stop_property_client_search_placeholder`)

### Navegação
- Aberto por: `EditStopCard` / `StopDetailSheet` ao tocar "Cliente" (evento `OpenEditRetailerDialog(selectedRetailer, allRetailers)`)
- Recebe: retailer selecionado atualmente + lista de todos os retailers disponíveis
- Fecha: ao selecionar item (chama callback) ou dismiss

### Estados / defaults
- Campo de busca inicia vazio (mostra todos os clientes)
- Item atualmente selecionado destacado na lista

### Ícones / drawables
- Nenhum ícone confirmado no dump

### Precisa-runtime
Sim — confirmar se há limite de lista, paginação, e se permite criar novo cliente inline.

---

## 9. OrderOfferExpiredDialog (Oferta expirada)

**Classe:** `OrderOfferExpiredDialog`
**Pacote:** `com.circuit.ui.dialogs.routeoffering`
**Tipo:** AdaptiveModalDialog (tamanho `Full` — ocupa mais espaço)

### Propósito
Informa ao motorista que uma oferta de rota do "Delivery Network" expirou antes que ele a aceitasse. Exibe título dinâmico com o nome/ID da oferta.

> **Nota B2C / Delivery Network:** este dialog pertence ao fluxo "Delivery Network" onde um dispatcher (empresa de logística no Spoke B2B) envia rotas a motoristas B2C. O RotPro não tem dispatcher B2B — avaliar com Ueslei se o fluxo de "aceitar oferta" entra no MVP.

### Estrutura (ordem visual)
1. Conteúdo dinâmico via composable `csa.m30507a(routeName, onDismiss)`:
   - Título: "A oferta %1$s expirou" (com nome/ID da rota)
   - Corpo: "As ofertas ficam disponíveis por tempo limitado. Como você não aceitou a tempo, ela expirou e foi oferecida a outros motoristas."
2. Botão de dismiss

### Strings PT-BR verbatim
- `"A oferta %1$s expirou"` (`route_offering_expiry_dialog_title`)
- `"As ofertas ficam disponíveis por tempo limitado. Como você não aceitou a tempo, ela expirou e foi oferecida a outros motoristas."` (`route_offering_expiry_dialog_body`)
- Confirm dialog (separado, não no expiry): `"Aceitar oferta %1$s"` / `"Ao aceitar esta oferta, você concorda em assumir total responsabilidade..."` / `"Confirmar"` / `"Cancelar"`

### Navegação
- Aberto por: push notification ou evento de expiração na rota ativa

### Estados / defaults
- Recebe `routeName: String` como argumento
- Sem seleção — apenas dismiss

### Ícones / drawables
- Nenhum ícone confirmado no dump (dialog informativo)

### Precisa-runtime
Sim, se o fluxo Delivery Network entrar no MVP — confirmar trigger (push vs. in-app) e confirm dialog separado.

---

## 10. SpeechInputFragment + Sub-diálogos de voz

**Classe principal:** `SpeechInputFragment` (FullScreen / modal grande)
**Pacote:** `com.circuit.ui.dialogs.speech`
**Feature gate:** `PlanFeature.SpeechInput` (restrito por plano — confirmar se B2C free tem acesso)

### Propósito
Interface de entrada de voz em lote ("Fale vários endereços"). O motorista grava um áudio ditando vários endereços de uma vez; o app faz upload e transcrição para adicionar paradas automaticamente.

### Estrutura principal (SpeechInputFragment)
1. Área de microfone / waveform animado (visualização de volume)
2. Prompt: "Fale todos os endereços de uma vez."
3. Dica: "Fale endereços e números.\nPule os CEPs."
4. Botão "Pausar" / "Retomar" (toggle)
5. Timer exibindo tempo gravado
6. Botão de cancelar / fechar
7. Estado "Analisando…" após gravar
8. Estado "Carregando…" durante upload
9. Dica de upload: "Isso pode levar alguns minutos"

#### Seletor de idioma (dropdown interno)
- Título: "Entrada de voz"
- Opções: "Automático" + lista de idiomas do sistema + "Sistema" (placeholder)
- Default: "Automático" quando `isAutomatic == true`, ou idioma selecionado

### Sub-diálogos disparados por `SpeechInputFragment`

#### 10a. Cancelar importação (Confirm Cancel)
- Classe: `wj4` (CircuitAlertDialog)
- Título: `"Descartar importação?"`
- Corpo: `"Os endereços capturados até agora serão descartados e não serão adicionados à sua rota."`
- Botão destrutivo: `"Descartar"`
- Botão secundário: `"Não. Continuar."`

#### 10b. Reiniciar gravação (Restart Dialog)
- Título: `"Reiniciar?"`
- Corpo: `"Os endereços capturados até agora serão descartados e não serão adicionados à sua rota."` (mesmo body de cancelamento)
- Botão primário: `"Reiniciar"`
- Botão secundário: `"Não. Continuar."`

#### 10c. Limite de uso atingido (Limit Dialog)
- Título: `"Limite de uso alcançado"`
- Corpo: `"Limite diário de importação de áudio alcançado. Tente novamente amanhã."`
- Botão: `"Dispensar"`

#### 10d. Falha ao carregar (Upload Error)
- Título: `"Falha ao carregar"`
- Corpo: `"Não conseguimos carregar sua gravação. Verifique sua conexão e tente de novo, ou cancele para descartá-la."`

#### 10e. Falta de espaço (Low Storage)
- Título: `"Falta de espaço de armazenamento"`
- Corpo: `"A gravação não pode prosseguir por falta de espaço de armazenamento. Libere espaço para continuar.\nGravações concluídas são excluídas automaticamente."`

#### 10f. Falha ao gravar (Recording Failed)
- Título: `"Falha ao gravar"`
- Corpo variante 1 (storage): mesmo de Low Storage
- Corpo variante 2 (erro genérico): `"Algo deu errado ao gravar. Tente novamente e reinicie o aplicativo se isso continuar ocorrendo."`

### Strings PT-BR verbatim (principais)
- `"Fale vários endereços"` (`bulk_audio_import_button`) — CTA que abre o fragment
- `"Fale todos os endereços de uma vez."` (`bulk_audio_import_prompt`)
- `"Fale endereços e números.\nPule os CEPs."` (`bulk_audio_import_tip`)
- `"Pode continuar, estamos ouvindo..."` (`bulk_audio_import_message`)
- `"Pausado.\nToque em Retomar para continuar."` (`bulk_audio_import_pause_message`)
- `"Pausar"` (`bulk_audio_import_pause`) | `"Retomar"` (`bulk_audio_import_resume`)
- `"Analisando…"` (`bulk_audio_import_analyzing`)
- `"Carregando…"` (`bulk_audio_import_loading`)
- `"Isso pode levar alguns minutos"` (`bulk_audio_import_uploading_tip`)
- `"Automático"` (`bulk_audio_automatic_language`)
- `"Sistema"` (`system_language`)
- `"Entrada de voz"` (`voice_input_title`)
- `"Descartar importação?"` (`bulk_audio_import_cancelation_title`)
- `"Os endereços capturados até agora serão descartados e não serão adicionados à sua rota."` (`bulk_audio_import_cancelation_body`)
- `"Descartar"` (`discard_changes_button_title`)
- `"Não. Continuar."` (`bulk_audio_import_dismiss_button`)
- `"Reiniciar?"` (`bulk_audio_import_restart_dialog_title`)
- `"Reiniciar"` (`bulk_audio_import_restart`)
- `"Limite de uso alcançado"` (`bulk_audio_import_limit_title`)
- `"Limite diário de importação de áudio alcançado. Tente novamente amanhã."` (`bulk_audio_import_limit_body`)
- `"Dispensar"` (`generic_dismiss`)
- `"Falha ao carregar"` (`bulk_audio_import_error_title`)
- `"Não conseguimos carregar sua gravação. Verifique sua conexão e tente de novo, ou cancele para descartá-la."` (`bulk_audio_import_error_body`)
- `"Falta de espaço de armazenamento"` (`bulk_audio_import_low_storage_title`)
- `"A gravação não pode prosseguir por falta de espaço de armazenamento. Libere espaço para continuar.\nGravações concluídas são excluídas automaticamente."` (`bulk_audio_import_low_storage_body`)
- `"Falha ao gravar"` (`bulk_audio_import_recording_failed_title`)
- `"Algo deu errado ao gravar. Tente novamente e reinicie o aplicativo se isso continuar ocorrendo."` (`bulk_audio_import_recording_failed_body`)

### Navegação
- Aberto por: botão "Fale vários endereços" na tela de adicionar paradas
- Resultado: `SpeechInputResult(speechToText: String?, mediaImportSessionId: MediaImportSessionId?)` retornado via `SpeechInputResultKey`
- Fecha com: sucesso (paradas adicionadas), cancelamento, ou erro fatal

### Estados / enums (`BulkAudioInputRecorder.State`)
`Idle` | `Recording` | `Analyzing` | `Uploading` | `UploadSuccess(sessionId)` | `UploadError`

### Ícones / drawables
- Nenhum ícone de UI confirmado — interface é dominada pelo waveform animado e microfone

### Precisa-runtime
Sim — confirmar animação do waveform, layout do seletor de idioma, e se o feature gate exige plano pago.

---

## 11. SpeechMicrophonePermissionDeniedDialog

**Classe:** `SpeechMicrophonePermissionDeniedDialog`
**Pacote:** `com.circuit.ui.dialogs.speech`
**Tipo:** AdaptiveModalDialog (tamanho Small)

### Propósito
Informa que o acesso ao microfone foi negado pelo sistema e solicita que o usuário o ative nas configurações. Exibido quando o usuário tenta usar entrada de voz sem permissão de microfone.

### Estrutura
1. Título: `"Permita o acesso ao microfone para usar comandos de voz"`
2. Corpo: `"%s usa seu microfone e reconhecimento de fala para você ditar endereços."` (com nome do app)
   - Variante "recording bug": `"O Spoke precisa acessar o microfone para gravar o áudio. Ative o acesso ao microfone nas configurações."`
3. Botão primário: abre configurações do app (sem string explícita confirmada — provavelmente `"Abrir configurações"` por padrão Android)

### Strings PT-BR verbatim
- `"Permita o acesso ao microfone para usar comandos de voz"` (`microphone_permission_dialog_title`)
- `"%s usa seu microfone e reconhecimento de fala para você ditar endereços."` (`microphone_permission_dialog_description`)
- `"Permita o acesso ao microfone"` (`recording_bug_microphone_permission_dialog_title`)
- `"O Spoke precisa acessar o microfone para gravar o áudio. Ative o acesso ao microfone nas configurações."` (`recording_bug_microphone_permission_dialog_description`)

### Navegação
- Aberto por: `SpeechInputFragment` quando permissão negada
- Fecha ao dismiss ou ao redirecionar para configurações

### Precisa-runtime
Não — estrutura completa derivada.

---

## 12. TimeWindowPickerDialog

**Classe:** `DialogC3312c` (`TimeWindowPickerDialog.kt`)
**Pacote:** `com.circuit.ui.dialogs.timewindowpicker`
**Tipo:** AdaptiveModalDialog (tamanhos compacto/médio adaptativos)

### Propósito
Modal para o motorista definir a janela de tempo de chegada a uma parada ("Chegar entre HH:MM e HH:MM"). Exibe dois campos de hora (início e fim), com suporte a formato 12h (AM/PM) e 24h dependendo da localidade.

### Estrutura (ordem visual)
1. Título de seção: "Horário de chegada" (modo `stop_setting_arrival_time_title`)
2. Campo "Chegar entre" (`time_window_start_title`) — hora de início
   - Placeholder / vazio: "Agora" (`now`)
3. Separador "E" (`time_window_end_title`)
4. Campo hora fim
   - Placeholder / vazio: "Qualquer momento" (`anytime`)
5. Seletor AM/PM (quando formato 12h): opções `["AM", "PM"]`
6. Mensagem de erro: "Hora informada inválida" (aparece quando usuário digita hora inválida)

### Strings PT-BR verbatim
- `"Horário de chegada"` (`stop_setting_arrival_time_title`)
- `"Chegar entre"` (`time_window_start_title`)
- `"E"` (`time_window_end_title`)
- `"Agora"` (`now`) — placeholder do campo início
- `"Qualquer momento"` (`anytime`) — placeholder do campo fim
- `"AM"` (`time_setting_am`) | `"PM"` (`time_setting_pm`)
- `"Hora informada inválida"` (`invalid_time_input_text`)

### Navegação
- Aberto por: `StopDetailSheet` (evento `OpenTimeWindowPickerDialog`) / `EditStopCard` ao tocar na propriedade de horário de chegada
- Argumento: `DialogC3312c.a(startTime: LocalTime?, endTime: LocalTime?)`
- Callback de retorno: `onConfirm(a)` com os novos horários

### Estados / defaults / enums
- `TimeField`: `Start` | `End`
- Formato de hora: `a` (12h com AM/PM) | `b` (24h `TwentyFourHours`)
- Detecta formato do sistema locale automaticamente
- Default quando nenhuma janela definida: `start = null` (→ "Agora"), `end = null` (→ "Qualquer momento")
- Erro de validação: campo fica vermelho + label "Hora informada inválida"

### Ícones / drawables
- Nenhum ícone confirmado no dump

### Precisa-runtime
Sim — confirmar se os campos de hora usam teclado numérico nativo ou custom numpad; confirmar animação de transição entre campos Start/End.

---

## Sumário de cobertura

| # | Diálogo | Tipo | B2C/B2B | Precisa-runtime |
|---|---------|------|---------|-----------------|
| 1 | AccessInstructionsSheet | Bottom sheet | B2C | Não |
| 2 | ApplyRouteChangesDialogFragment | Bottom sheet | B2C | Sim (estados locked) |
| 3 | OptimizationExplainerDialogFragment | Modal | B2C | Sim (Rive + seleção) |
| 4 | ContactRecipientDialog | Modal compacto | B2C | Não |
| 5 | EnableLocationFragment | AlertDialog | B2C | Não |
| 6 | PackageCountSheet | Bottom sheet | B2C | Sim (numpad) |
| 7 | PackageDetailsDialog | Modal | B2C | Sim (PlaceInVehicle picker) |
| 8 | EditRetailerDialog | Bottom sheet | B2C | Sim (lista/paginação) |
| 9 | OrderOfferExpiredDialog | Modal | B2C\* | Sim se Delivery Network entra |
| 10 | SpeechInputFragment + sub-diálogos | FullScreen + Alerts | B2C (plan-gated) | Sim (waveform, plan gate) |
| 11 | SpeechMicrophonePermissionDeniedDialog | Modal compacto | B2C | Não |
| 12 | TimeWindowPickerDialog | Modal | B2C | Sim (numpad / AM-PM) |

\* `OrderOfferExpiredDialog` = feature "Delivery Network" (B2C marketplace) — não entra no RotPro MVP sem dispatcher.
