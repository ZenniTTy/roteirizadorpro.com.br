# Área 6 — Editar parada: design dump-first (MS-A6)

> **Data:** 2026-06-11 · **Status:** aprovado por Eduardo (sessão 2026-06-11)
> **Método:** dump-first (ADR-0045/0048) — TODOS os fatos estruturais abaixo vêm do dump estático do Spoke v3.65.1 (`~/spoke-dump/jadx-out` + `res-decoded`), com evidência `arquivo:linha`. Zero runtime tocado nesta fase; runtime fica para 2 confirmações pontuais no D4 (lista no §Precisa-runtime).
> **Fontes:** MASTER-TABLE rows #4–#10 · inventário §10.5/§10.6/§11.1/§11.5/§13.C.1/§13.C.3 · grep jadx (workflow `wxcu78nhu`, 2 tópicos verificados adversarialmente + greps manuais desta sessão).
> **Disclaimer ADR-0010/0035:** strings PT-BR citadas são baseline de engenharia, NUNCA copiadas verbatim no produto. Identidade visual 100% original (tokens `prototipo/`).

## 1. Fatos novos do dump (corrigem inferências anteriores)

| # | Fato (v3.65.1) | Evidência | Corrige |
|---|---|---|---|
| F1 | **Duas surfaces distintas**: tap em stop WAYPOINT numa rota **em edição** → `EditStopDialogFragment` ("Editar parada", `AdaptiveModalFragment` quase-full-screen); rota **em execução** → `EditRoutePage.StopDetails` (pager interno do sheet — Área 8) | `EditRouteViewModel.m9465r0` (3331-3370: branch `w8c.m45786e()`), `m9461p0` (3277: ordinal 1 = WAYPOINT → evento `c0`), `StopType.java:30-55`, `nav_main.xml:39` (`<dialog .../EditStopDialogFragment>`) | MASTER-TABLE rotulava #4–#10 como "StopDetailSheet" (uma surface só) |
| F2 | "Editar parada" **NÃO é estado do sheet do shell** — é modal/dialog destination próprio com result `edit_stop_result → stop_edited: bool` | `EditStopDialogFragment.java:84-100`, `nav_main.xml:146` (`action_edit_stop`) | Inventário §11.5 "deve ser DraggableScrollableSheet inline" (inferência) |
| F3 | **Edits aplicados live por campo** (cada sub-dialog commit-on-dismiss → `StopChange.*`); "Concluído" apenas fecha | `owa.dismiss()` (77-81), `ide.dismiss()` (92-104), `fkd.*` sealed (`PackageCount`, `EstimatedTimeAtStop`…) | Suposição "Concluído = save+pop em 1 tap" (§10.6) |
| F4 | **Pós-add via texto = toast "Parada adicionada" + ação "Ver"** (abre o editor com badge); auto-open direto não existe na v3.65.1 | `nq0.java:285` (BottomToasts.kt, `added_stop_toast_message`), `kq0.java:37` (action = `duplicate_stop_toast_view_action` "Ver") | Inventário §11.5 "auto-mostra Editar parada da última adicionada" |
| F5 | **#9 Duplicar = imediato** (use-case + 250ms), **abre o editor da duplicata** com badge "Adicionada" (`showAddedBadge=true`) | `StopActionsController$onDuplicateStop$1.java:85-150`, `bkd.java` (toString `StopDuplicated`), `EditRouteViewModel:988` | MASTER-TABLE "Precisa-runtime: copia imediato vs dialog" |
| F6 | **#10 Remover: confirm com texto encontrado** — `remove_stop_confirmation_dialog_text` = "Quer remover \"%1$s\" da rota?" + título `remove_stop_title` | `strings.xml:1990-1992` | MASTER-TABLE "texto não achado no dump" |
| F7 | **#6 Horário de chegada é JANELA** — `TimeWindowPickerDialog` (`AdaptiveModalDialog`) com 2 `LocalTime?` ("Chegar entre" / "E"), vazio = "Qualquer momento", display parcial "Após %s"/"Antes de %s", validação "Hora informada inválida" | `DialogC3312c.java` (timewindowpicker), `strings.xml:448/783-784/1355/2373-2374` | MASTER-TABLE "Material3 hora:minuto" (single time) |
| F8 | **#4 Pacotes: row = stepper inline `CircuitStepper` [−/N/+] (0..9999) E tap no número abre dialog free-text** (placeholder "1", filtro 4 dígitos, coerceIn(1..9999), null quando ≤1, commit-on-dismiss sem botão OK) | `EditStopEditorKt.java:1971-1995` + `jy3.java` (CircuitStepper.kt) + `C3285a/pwa/owa/s85.m43910U` — verificado adversarialmente | MASTER-TABLE "diálogo com incrementor" (impreciso) + reconcilia §13.C.1 |
| F9 | **#7 Tempo na parada: dialog MIN+SEG livres** (`DurationInputField` compartilhado, max 5 dígitos/campo, clear-X, ambos vazios = null = herda default), label "Padrão (%1$s)"; **default global = setting "Tempo médio na parada", fallback 1 min** (`hj4.f104611a = Duration.ofMinutes(1)`); armazenado como `Duration?` nullable override | `ide.java`, `C2644a.java` (DurationInputField.kt), `UiFormatters.m8465u:882-890`, `C2857l.java` (StopData.estimatedTimeAtStop) — verificado | Roadmap "picker 1/2/3/5/10/custom" (essa é a UI do setting; o per-stop é min+seg) |
| F10 | **Cores: exatamente 5** — BLUE/TEAL/PURPLE/PINK/ORANGE ("Azul", "Verde-azulado", "Roxo", "Rosa", "Laranja"), sheet header Limpar/Cor/Concluído, swatch+check | `StopColor.java:38-44`, `okd.java` (StopColorPickerDialog.kt), `strings.xml:2222-2227` | §10.6.2 "5 observadas, pode haver mais no scroll" |
| F11 | **#5 Localizador de pacotes: estrutura COMPLETA** (era o único `low`) — dialog com (1) header "Localizador de pacotes" + Concluído/Limpar; (2) row "ID de parada" (valor = label ou "Pendente"); (3) "Descrição do pacote": chips Pequeno/Médio/Grande + Caixa/Sacola/Carta; (4) "Lugar no veículo": 3 eixos com ícones — Frente/Meio/Atrás · Esquerda/Direita · Chão/Prateleira. Armazena `PackageDetails(type?,dimension?)` + `PlaceInVehicle(x?,y?,z?)`; display "Não definido" → longo "Pequeno, Caixa, Frente, Esquerda, Chão" / curto "FEC". **É B2C** (`PlanFeature.PackageFinder`, distinto de `LoadVehicle`) | `C3290b.java` (packagedetails), `PackageDetails.java`, `PlaceInVehicle.java`, `k9b.java` (PlaceInVehicleSheet.kt), `fr0.java:145-171`, `EditStopEditorKt.java:2105-2114`, `strings.xml:1808-1892` | MASTER-TABLE `low` "não codar sem runtime" + hipótese de corte B2B |
| F12 | **Fotos de pacote: câmera in-app, storage 100% LOCAL** (`files/package_photos/<user>/<route>/<stop>`), thumbnails no editor de notas, worker de limpeza 30 dias, **sem upload** (proof-of-delivery é modelo separado/Dispatch) | `PackagePhotoManager.java:87-108`, `CleanupPackagePhotosWorker.java:73-80`, `zd0.java:86-91`, `PhotoDetail.java` (DeliveryInfo, separado) | — (campo novo mapeado) |
| F13 | **Instruções de acesso: sticky-ao-ENDEREÇO confirmado no código** — `onAccessInstructionsUpdated(texto, salvarComoPadrão)`; sheet header título+Salvar+Limpar, TextField "Adicionar instruções", switch "Salvar como padrão para este endereço" | `EditStopViewModel$onAccessInstructionsUpdated$1.java`, `C3263a.java` (accessinstructions), `strings.xml:412/888/2090` | Confirma §13.C.3 por via independente |
| F14 | **Campos Cliente / Destinatário / Valor a cobrar existem no editor mas são feature-gated** (Dispatch/B2B) — runtime B2C nunca os mostrou | `EditStopEditorKt.java:1042/2246` + gating `AppFeature`/`FeatureStatus`/`PlanFeature` por campo | — (NÃO implementar) |
| F15 | Ações do rodapé em `EditStopActions.kt`: Mudar endereço (`pin_outline_change`) / Duplicar (`pin_outline_duplicate`) / Remover (`delete_outline`, cor destrutiva, full-width), gated por `AppFeature.ChangeStopAddress/DuplicateStop/RemoveStop` | `ze6.java:85-87` | Confirma ordem §10.6; RotPro: sempre ativos (§13.C.1) |
| F16 | Ordem = `Primeira/Automática/Última` (`stop_setting_order_option_first/auto/last`); Tipo = `Entrega/Coleta` (`stop_activity_delivery/pickup`, enum `StopActivity`) | `strings.xml:2220-2257`, `EditStopEditorKt` `m9332k`/`m9322a` | Confirma §10.6 |

## 2. Decisões (Eduardo, 2026-06-11)

| # | Decisão | Racional |
|---|---|---|
| D1 | **Surface RotPro = página GoRouter full-screen** `/home/routes/active/:routeId/stops/:stopId/edit` | Idiom maduro da Á5; sub-pushes naturais (Mudar endereço → AddStopPage); evita Flutter #155746. O modal do Spoke ocupa ~tela toda em phone (§10.6) — divergência só no gesto de dismiss. |
| D2 | **Foto de pacote: implementar agora** (não stub) | `image_picker ^1.2.2` JÁ no pubspec; falta só `path_provider` (ADR curta) p/ persistir local. Espelha F12 (local-only, sem upload). |
| D3 | **Localizador de pacotes: implementar na MS-A6**, copiando a estrutura do dump (F11) | Estrutura virou fato; B2C; sem deps. |
| D4 | **Default do tempo-na-parada: `SettingsRepository` mínimo agora** (`defaultStopDuration`, 1 min) — Á10 pluga a UI depois | Zero hard-code, mesma origem que o Spoke (F9). |
| D5 | Tempo na parada = **minutos+segundos** (fidelidade F9) | Copiar do dump. |
| D6 | Pós-add = **toast + "Ver"** (F4); inventário §11.5 amendado | Dump ganha de inferência runtime antiga. |
| D7 | Campos B2B (F14) **não implementados**; chip ID = display + stub (tela "Formato do ID" pertence à Á10); botão Ajuda do header = stub | Fronteira B2C/B2B + dependência de área. |
| D8 | Janela de chegada reusa o **padrão janela+numpad da BreakSchedulerPage** (2 rows "Chegar entre"/"E" → numpad ADR-0042) | Consistência interna; mesmo shape estrutural do Spoke (2 campos de hora). |

## 3. Escopo da MS-A6

### 3.1 Domínio + estado

- `Stop` += `orderPolicy` (enum `StopOrderPolicy { first, auto, last }`, default `auto`), `packageDetails` (`PackageDimension? small/medium/large` + `PackageType? box/bag/letter`), `placeInVehicle` (`PlaceX? left/right`, `PlaceY? front/middle/back`, `PlaceZ? floor/shelf`), `photoPaths: List<String>`, `accessInstructions: String?` (instrução só-desta-parada; a sticky vive no repository por endereço), `estimatedTimeAtStop: Duration?` (substitui `customDurationMinutes`), `color: StopColor?` (enum 5 valores → tokens prototipo; substitui `colorHex`). Campos nullable: copyWith com sentinela `_omit` + teste clears-it (lição `lesson_copywith_nullable_field_pitfall`).
- `routesProvider` += `updateStop(routeId, Stop)`, `removeStop(routeId, stopId)`, `duplicateStop(routeId, stopId) → String` (cópia integral, status pendente, retorna id da duplicata).
- `AddressInstructionsRepository` (SharedPreferencesAsync, envelope `address_instructions_v1`): instruções por endereço normalizado + escrita condicionada ao switch (F13). Instrução só-desta-parada vive no `Stop.accessInstructions: String?`.
- `SettingsRepository` (SharedPreferencesAsync, envelope `settings_v1`): `defaultStopDuration` (default `Duration(minutes: 1)`).

### 3.2 Apresentação

1. **Lista de stops no sheet do shell** (`route_shell_page.dart`) — seção "Paradas" per §10.5: header + cards (badge numérico 2 dígitos, rua h6, endereço muted, dot de status à direita), card inteiro clicável → push edit-stop. Corpo do sheet achatado para `ListView.builder` (checklist: lista de dados = builder). **Auto-expand** do sheet quando a rota ativa tem ≥1 parada (§10.5). Sem reorder (Á9), sem CTA Otimizar (Á7), sem chip A1 no card (nasce na Á7 pós-otimização).
2. **`EditStopPage`** — header: Ajuda (stub SnackBar) + título + "Concluído" (pop; edits já aplicados live per F3). Badge "Adicionada" quando aberta via toast-"Ver"/Duplicar (query `?new=1`). Corpo na ordem §10.6/F8-F16: chips cor+ID → card endereço + botão Instruções de acesso → notas (TextField multiline) + botão câmera + thumbnails → rows: Localizador / Pacotes (stepper inline + dialog no tap do número) / Ordem (SegmentedButton 3) / Tipo (SegmentedButton 2) / Horário de chegada (janela, D8) / Tempo na parada (dialog min+seg) → ações: Mudar endereço / Duplicar parada / Remover parada (vermelho + AlertDialog confirm, microcopy original).
3. **Sub-surfaces**: ColorPickerSheet (5 cores, Limpar/Concluído, F10) · AccessInstructionsSheet (F13) · PackageCountDialog (F8) · TimeWindow via numpad (D8) · TimeAtStopDialog (F9) · PackageFinderSheet (F11) · câmera via `image_picker` → copia p/ dir do app (`path_provider`) → thumbnails.
4. **Entrypoints**: (a) tap stop-card do shell; (b) Section A da `add_stop_page` (`_onSectionATap` — mata o SnackBar "em breve"); (c) toast pós-add "Parada adicionada" + action "Ver" (F4); (d) pós-Duplicar abre o editor da duplicata (F5).
5. **Mudar endereço**: push `AddStopPage` em modo novo `PickerMode.changeAddress` (Section A omitida, header "Escolha o novo endereço") → pop com endereço → `updateStop` trocando apenas lat/lng/streetName/fullAddress.

### 3.3 Fora de escopo (registrado)

- Reorder de paradas (Á9) · CTA Otimizar (Á7) · chip A1 real + tela "Formato do ID de parada" (Á10/Á7) · campos B2B F14 · picker de razão de falha (não existe no B2C, §10.14) · upload de fotos (Spoke não sobe; POD é Dispatch) · worker de limpeza de fotos 30d (avaliar na Á8/Slice 3; registrar TODO).

### 3.4 ADRs

- **ADR nova (curta): `path_provider`** — única adição ao pubspec (first-party flutter.dev) para persistir fotos locais. Context7 check na implementação.
- Nenhuma outra mudança de stack.

## 4. Precisa-runtime (D4, dump-only + 2 cliques no M54)

1. Toast pós-add: confirmar visual/timing da action "Ver" (F4) — 1 add de parada.
2. Row Pacotes: confirmar que o tap no NÚMERO abre o dialog (F8) — 1 tap.

(Todo o resto da tabela virou fato de código; D4 segue dump-only per precedente ADR-0049.)

## 5. Gates

TDD (flutter-test-author antes de cada widget/provider novo) · `flutter analyze` sem lint novo (23 MS-DEBT intocados) · `flutter test` ≥ 308 · `integration_test` da cadeia de navegação (shell → edit → sub-pickers → Android-back) no M54 · perf-auditor na `EditStopPage` + lista do shell · D4 §4 · amendments inventário/MASTER-TABLE no mesmo commit set · branch `feat/m2-slice-2-area-6-edit-stop` → PR contra `develop`.
