# Front blueprint — intent

Data: 2026-06-21
Fonte: `com/circuit/p016ui/intent/`, `com/circuit/core/DeepLinkAction.kt`, `com/circuit/utils/DeepLinkManager.kt`, `com/circuit/links/LinkBuilder.kt`, `AndroidManifest.xml`, `values-pt-rBR/strings.xml`
Scope: camada de entrada via deep-link / intent do Android (não é tela; é roteador de intenções)

---

## Visão geral

O Spoke B2C usa **uma única Activity de despacho** para tratar todos os deep-links e notificações: `IntentHandlerActivity`. Ela não tem UI própria — resolve o intent recebido em um `DeepLinkAction` tipado e redireciona o app para a tela correta, depois se encerra (`noHistory=true`).

Não há tela, diálogo ou sheet a implementar no RotPro para este pacote. O que existe é:

1. Um conjunto de **URLs registradas** no Manifest que o SO direciona para esta Activity.
2. Um conjunto de **ações tipadas** (`DeepLinkAction`) que o `DeepLinkManager` resolve e despacha via `EventQueue`.
3. Um **roteador de intent extra** que permite que notificações push, Android Auto e outros serviços internos injetem ações diretamente como `Parcelable` extras.

---

## 1. IntentHandlerActivity

**Classe:** `com.circuit.ui.intent.IntentHandlerActivity`
**Propósito:** Activity transparente/sem-UI que age como portão de entrada universal para todos os deep-links e intents externos.

### Configuração no Manifest

```
android:launchMode="singleTask"
android:noHistory="true"
android:exported="true"
```

Três filtros de intent registrados:

**Filtro 1 — URLs verificadas (app links):**
- Schemes: `http` e `https`
- Hosts: `getcircuit.com`, `spoke.com`
- Path patterns:
  - `/routes/..*`
  - `/invite/..*`
  - `/upgrade/..*`
  - `/open-on-phone`
- `android:autoVerify="true"` (App Links verificados)

**Filtro 2 — Domínio Firebase legado:**
- Scheme: `https`
- Host: `crp.circu.it` (valor de `@string/legacy_deep_link_domain`)
- `android:autoVerify="true"`

**Filtro 3 — Domínio Firebase atual:**
- Scheme: `https`
- Host: `rp.spoke.com` (valor de `@string/deep_link_domain`)
- `android:autoVerify="true"`

### Fluxo de execução

```
IntentHandlerActivity.onCreate()
  └─> DeepLinkManager.dispatch(intent)
        ├─ intent.getParcelableExtra("action")  →  DeepLinkAction já embutido (notificações push, intents internos)
        ├─ intent.getBooleanExtra("finishRoute", false)  →  DeepLinkAction.FinishRoute (legado)
        ├─ se action == OpenWebsite  →  tenta re-resolver a URI via LinkBuilder
        └─ se action == null  →  UrlIntentProvider.getActionFromUrlIntent(intent)
              └─> FirebaseUriProvider.getActionFromUrlIntent()
                    └─> DeepLinkResolver.resolve(uri)  [HEAD request p/ seguir redirects; timeout 10s]
                          └─> LinkBuilder.m42408a(uri)  [parseia a URI final → DeepLinkAction]

  Após resolver:
    DeepLinkManager.m10074c(action)  →  enfileira via EventQueue<DeepLinkAction>
    startActivity(MainActivity)  →  retorna à tela principal
    IntentHandlerActivity se encerra (noHistory)
```

**Estados pendentes persistidos (SharedPreferences):**
- `pending_distributed_route_id_path` — persiste `RouteDistributed.routeId` quando usuário não está logado; republicado após login.
- `pending_updated_route_id_path` — mesmo padrão para `RouteUpdated`.

### Strings PT-BR relevantes

Nenhuma string PT-BR própria desta Activity (sem UI). As strings de feedback ao usuário pertencem às telas de destino.

---

## 2. DeepLinkAction — enum sealed class

**Classe:** `com.circuit.core.DeepLinkAction` (Parcelable)
**Propósito:** tipo discriminado que representa toda ação de entrada possível.

### Variantes e campos

| Variante | Campos | Origem típica |
|---|---|---|
| `OpenMainScreen` | — | push, QR interno |
| `OpenDrawer` | — | push |
| `OpenNewRoute` | URL `?action=open_search_new_route` | web, QR, Android Auto |
| `FinishRoute` | — | extra boolean legado `finishRoute=true` |
| `ImportRoute` | `routeId: RouteId`, `title: String?` | URL `/routes/{userId}/{routeId}` ou `/open-on-phone?action=import_shared_route` |
| `RouteDistributed` | `routeId: RouteId` | URL `/open-on-phone?action=route_distributed&routeId=X&teamId=Y` — **[B2B — cortar]** |
| `RouteUpdated` | `routeId: RouteId` | URL `/open-on-phone?action=route_updated` — **[B2B — cortar]** |
| `ShowPaywall` | `feature: AppFeature` | intents internos (gate de feature) |
| `UpgradeLink` | `request: SubscriptionRequest?`, `launchPurchase: Boolean` | URL `/upgrade/{sku}` ou `/open-on-phone?action=open_upgrade_screen` ou `?action=launch_subscription` |
| `OpenWebsite` | `link: Uri` | intent interno que depois é re-resolvido |
| `OpenRouteOfferDetails` | `offerId: String` | notificação push "Delivery Network" — **[B2B — cortar]** |
| `OpenSearchFromCarIntentHandler` | `query: String` | Android Auto `open-on-phone` — **[cortar; não temos AA]** |
| `StartRecordingSession` | — | URL `/open-on-phone?action=start_recording_session` (feedback de bugs) |
| `SendStopsToTransfer` | `transferId: TransferStopsId`, `stopCount: Int` | URL `/open-on-phone?action=transfer-stops&...` |
| `Install.Email` | `email: String`, `password: String?` | URL `/open-on-phone?action=install&email=X` (onboarding) |
| `Install.Phone` | `phone: String` | URL `/open-on-phone?action=install&phone=X` (onboarding) |

**RouteId:** `id: String` (routeId da rota), `collection: RouteCollection` (Personal ou Team).
`RouteId.m8620a(routeId, userId)` = rota pessoal; `RouteId.m8621b(routeId, teamId)` = rota de equipe.

---

## 3. LinkBuilder — mapeamento URL → DeepLinkAction

**Classe:** `p000.p99` (compilado de `LinkBuilder.kt`)

### Padrões de URL reconhecidos

**Path `/open-on-phone` + query `?action=`:**

| Valor de `action` | DeepLinkAction | Query params extras |
|---|---|---|
| `import_shared_route` | `ImportRoute` | `routeId`, `userId`, `title?` |
| `route_distributed` | `RouteDistributed` **[B2B]** | `routeId`, `teamId` |
| `open_search_new_route` | `OpenNewRoute` | — |
| `open_upgrade_screen` | `UpgradeLink(request, launchPurchase=false)` | `androidSku`/`sku`, `androidOffer`/`offer`; compat: `"annual"` → `"unlimited_late_oct_2021_annual"` |
| `launch_subscription` | `UpgradeLink(null, launchPurchase=true)` | — |
| `open_main_screen` | `OpenMainScreen` | — |
| `install` | `Install.Email` ou `Install.Phone` | `email`, `password?`, `phone` |
| `start_recording_session` | `StartRecordingSession` | — |
| `transfer-stops` | `SendStopsToTransfer` | `userId`, `transferId`, `stopCount` |

**Path `/routes/{userId}/{routeId}`:**
→ `ImportRoute(routeId=RouteId(routeId, userId), title=null)`

**Path `/upgrade/{sku}`:**
→ `UpgradeLink(SubscriptionRequest(sku, null), launchPurchase=false)`

**Redirect resolution:** se a URI inicial é `http`/`https`, o `DeepLinkResolver` faz um `HEAD` com timeout de 10 s para seguir redirects (Firebase Dynamic Links → URL final).
**Exceção:** paths com último segmento `open-on-phone` são passados diretos sem HEAD.

---

## 4. DeepLinkManager — despachante central

**Classe:** `com.circuit.utils.C4119c` (compilado de `DeepLinkManager.kt`)

### Intent extras reconhecidos

| Extra key | Tipo | Uso |
|---|---|---|
| `"action"` | `DeepLinkAction` (Parcelable) | ação pré-resolvida (notificações push) |
| `"finishRoute"` | `Boolean` | legado; injeta `FinishRoute` |
| `"analytics"` | `PushMessageAnalytics` (Parcelable) | rastreamento de abertura via push |

### PendingIntents produzidos (para notificações)

O `DeepLinkManager` também **produz** intents para outros sistemas:

- `d(action, analytics)` → `PendingIntent` para notificação push → abre `IntentHandlerActivity` com extra `"action"`.
- `e(args, showOnLockScreen)` → intent para `AdditionalActionsTransparentActivity` (ações pós-entrega como foto/assinatura).
- `f()` → `PendingIntent` de serviço para fechar `ExternalNavigationService`.
- `g(stepId, success, via)` → `PendingIntent` para concluir parada via notificação de navegação.
- `i()` → `PendingIntent` para abrir `MainActivity` diretamente (`action="open-app"`).

---

## 5. UrlIntentProvider / FirebaseUriProvider

**Classe:** `com.circuit.links.C3050b` (compilado de `UrlIntentProvider.kt`)
**Propósito:** resolve intents com `getData()` (android.intent.action.VIEW) para URI final.

**FirebaseUriProvider** (`com.circuit.links.C3049a`):
- Implementa `getActionFromUrlIntent` → lê `intent.getData()`, chama `DeepLinkResolver.resolve()`.
- Implementa `getRecordingLink(uri)` → resolve via Firebase Dynamic Links.
- Implementa `getRouteProgressLink(route)` → monta `https://progress.spoke.com/?type={userId}&route={routeId}&displayName={name?}` e cria Firebase Dynamic Link.

**Strings PT-BR de compartilhamento de progresso de rota:**
- `"Veja o andamento da entrega em tempo real aqui: %1$s"` (`share_route_progress_message`)
- `"Compartilhar %1$s"` (`share_route_x` — título do chooser)

---

## 6. Atividades auxiliares (sem UI própria / transparentes)

### ImportActivity

**Classe:** `com.circuit.importer.ImportActivity`
**Propósito:** recebe arquivos de planilha compartilhados de outros apps.

Intent-filters registrados:
- `ACTION_VIEW` + `ACTION_SEND`
- MIMEs aceitos: `.xlsx`, `.xls`, `.csv`, `.tsv`, `text/comma-separated-values`, `text/tab-separated-values`

String PT-BR: `"Importar manifesto de rotas"` (`manifest_import_import_route_manifest`)

### AdditionalActionsTransparentActivity

**Classe:** `com.circuit.p016ui.delivery.background.AdditionalActionsTransparentActivity`
**Propósito:** Activity transparente mostrada sobre lock screen para ações pós-entrega (foto, assinatura).

Flags: `taskAffinity=""`, `launchMode=singleTop`, `showWhenLocked=true`, `showForAllUsers=true`, `autoRemoveFromRecents=true`.
Extra `"show_on_lock_screen": Boolean` controla visibilidade sobre tela bloqueada.

---

## 7. O que é B2B e deve ser cortado no RotPro

| Variante/Feature | Motivo do corte |
|---|---|
| `RouteDistributed` | Rota distribuída por dispatcher B2B (Circuit Teams) |
| `RouteUpdated` | Atualização de rota pelo dispatcher |
| `OpenRouteOfferDetails` | "Delivery Network" — ofertas de rota B2B |
| `RouteOfferManager` inteiro | Gerencia ofertas de rota B2B |
| `routeoffering/` inteiro | UI de aceite/recusa de oferta B2B |
| `StartRecordingSession` | Gravação de tela para feedback interno (Spoke Dev) — irrelevante para B2C |
| `OpenSearchFromCarIntentHandler` | Android Auto — fora de escopo |
| `TransferStopsId` / `SendStopsToTransfer` | Transferência de paradas entre motoristas — B2B dispatch |

---

## 8. O que o RotPro deve implementar

### Obrigatório (funcional B2C)

1. **`ImportRoute`**: abrir rota compartilhada recebida via link `spoke.com/routes/{userId}/{routeId}` ou equivalente RotPro. Parâmetros: `routeId` (string), `userId` (string), `title` (opcional).
2. **`OpenMainScreen`**: garantir que link genérico abre a tela inicial.
3. **`OpenDrawer`**: link que abre o drawer lateral.
4. **`OpenNewRoute`**: link que inicia criação de nova rota.
5. **`FinishRoute`**: ação de concluir rota via notificação/widget externo.
6. **`Install.Email` / `Install.Phone`**: auto-preenchimento de credenciais no onboarding via link de convite.

### Opcional / Slice posterior

7. **`UpgradeLink` / `ShowPaywall`**: equivale ao paywall do Slice 4 (Stripe Pix). A lógica de SKU/offer do Spoke não se aplica; o RotPro usa Pix. Manter a estrutura de despacho mas apontar para a tela de paywall própria.
8. **`OpenWebsite`**: abrir URL externa no browser — trivial.
9. **`StartRecordingSession`**: pode ser adaptado para "iniciar feedback" (out of scope inicial).

### Não implementar

Tudo marcado `[B2B — cortar]` na seção 7.

---

## 9. Strings PT-BR de contexto (transfer stops — se implementado)

As strings abaixo pertencem ao fluxo de transferência de paradas. Listadas aqui por completude; a feature em si é B2B conforme ADR-0035.

- `"Transferir paradas…"` (`transfer_stops`)
- `"Receber paradas"` (`transfer_stops_receive`)
- `"Leia o QR code para assumir paradas"` (`transfer_stops_receive_details`)
- `"Adicionando à rota %1$s"` (`transfer_stops_receive_confirm_body`)
- `"Escolher outra rota"` (`transfer_stops_receive_confirm_change_route`)
- `"Paradas recebidas"` (`transfer_stops_stoplist_section_received`)
- `"Leia para transferir paradas"` (`transfer_stops_scan_hint`)
- `"Tente novamente usando um código de transferência válido do Spoke"` (`transfer_stops_scan_error`)
- `"Quer mesmo cancelar?"` (`transfer_stops_cancel_add_dialog_title`)
- `"As paradas recebidas não serão adicionadas à sua rota. Essa ação não pode ser desfeita."` (`transfer_stops_cancel_add_dialog_body`)
- `"Esta rota tem alterações que não foram salvas"` (`transfer_stops_unsaved_changes_title`)
- `"As alterações precisam ser implementadas ou descartadas antes da transferência de paradas.\n\nEssa ação não pode ser desfeita."` (`transfer_stops_unsaved_changes_text`)
- `"Implementar todas as alterações"` (`transfer_stops_unsaved_changes_apply_button_title`)
- `"Código QR salvo no seu dispositivo"` (`transfer_stops_code_stored`)

---

## 10. Precisa-runtime

| Item | Precisa runtime? | Motivo |
|---|---|---|
| URLs que o SO reconhece como app links | Não | Manifest completo extraído |
| Fluxo de resolução de redirect (Firebase Dynamic Links) | Não | HEAD request bem documentado |
| Comportamento de cada DeepLinkAction (qual tela abre) | **SIM** | O `EventQueue` é consumido em `MainActivity`/`HomeViewModel` — consumidores não foram completamente rastreados no dump |
| `ShowPaywall(AppFeature)` → qual tela de paywall | Não (Slice 4 define o paywall do RotPro) | — |
| `pending_distributed_route_id_path` — quando e onde lido | Não (B2B — cortar) | — |

---

## 11. Ícones

Nenhum ícone nesta camada (sem UI). Os drawables de notificação push pertencem aos blueprints de `home` e `delivery`.

---

## Resumo estrutural

```
EntryPoint: IntentHandlerActivity (noHistory, singleTask)
  ↓ resolve
DeepLinkManager
  ↓ parse URL ou extra Parcelable
DeepLinkAction (sealed)
  ├── B2C: OpenMainScreen | OpenDrawer | OpenNewRoute | FinishRoute
  │         ImportRoute(routeId, userId, title?) | Install.Email | Install.Phone
  │         UpgradeLink(sku?, offer?, launchPurchase) | ShowPaywall(feature)
  │         OpenWebsite(uri) | StartRecordingSession
  ├── B2B [cortar]: RouteDistributed | RouteUpdated | OpenRouteOfferDetails
  │                  SendStopsToTransfer | OpenSearchFromCarIntentHandler
  └── Aliases externos: ImportActivity (planilhas) | AdditionalActionsTransparentActivity (ações pós-entrega)
  ↓ enfileira
EventQueue<DeepLinkAction>  →  consumido em MainActivity / HomeViewModel
```
