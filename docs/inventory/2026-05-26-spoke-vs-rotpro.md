# Spoke vs Roteirizador Pro — inventário comparativo

> **Data:** 2026-05-26
> **Fonte:** inspeção via adb no Samsung M54 (RQCW401G33T) — RotPro `br.com.roteirizadorpro.roteirizador_pro` + Spoke `com.underwood.route_optimiser` v3.65.1, ambos inspecionados em sessão única 2026-05-26 com uiautomator dump + screencap. Cobertura: ver §9 (telas inspecionadas vs pendentes).
> **Driver:** [ADR-0035](../decisions/0035-spoke-functional-clone-prototype-creative-reference.md) — Spoke é o guia funcional, prototipo é referência criativa, cliente Ueslei é desempate
> **Spoke instance inspecionado:** `com.underwood.route_optimiser` v3.65.1 (publisher Underwood, Brasil; rebrand do Circuit Route Planner)
> **Disclaimer legal:** este inventário descreve funcionalidades, navegação e estrutura de UX para fins de paridade funcional (per [ADR-0010](../decisions/0010-clone-positioning.md) — "functional fork with original visual identity"). Não reproduz microcopy verbatim, ícones, ilustrações, paletas, ou tipografia da Spoke. Screenshots de inspeção vivem apenas em `/tmp/spoke-inspection/` e NÃO são commitados.

---

## §1 — Mapa de Activities (Android) declaradas pela Spoke

Da inspeção `adb shell dumpsys package com.underwood.route_optimiser`:

| Componente | Tipo | Função |
|---|---|---|
| `com.circuit.ui.MainActivity` | Activity (LAUNCHER) | Activity única, navegação interna via Compose Navigation |
| `com.circuit.ui.intent.IntentHandlerActivity` | Activity | Roteia intents (deep links, share-to-app) |
| `com.circuit.importer.ImportActivity` | Activity | Importa manifestos de rota (CSV, planilhas, share-from-app) |
| `com.circuit.auth.apple.AppleSignInActivity` | Activity | Login com Apple ID |
| `com.facebook.CustomTabActivity` | Activity | OAuth Facebook |
| `com.google.firebase.auth.internal.GenericIdpActivity` | Activity | Identity provider genérico Firebase |
| `com.google.firebase.auth.internal.RecaptchaActivity` | Activity | reCAPTCHA Firebase Auth |
| `com.circuit.auto.CircuitCarAppService` | Service | Android Auto support |
| `com.circuit.push.MessagingService` | Service | Push notifications (delivery updates, route reminders) |
| `com.google.firebase.messaging.FirebaseMessagingService` | Service | FCM backbone |
| `io.intercom.android.sdk.IntercomFileProvider` + `IntercomFcmMessengerService` | Service / Provider | Suporte ao cliente in-app via Intercom |
| `com.bugsnag.android.internal.BugsnagContentProvider` | ContentProvider | Crash reporting |
| `com.google.mlkit.common.internal.MlKitInitProvider` | ContentProvider | ML Kit (OCR provavelmente) |
| `com.pairip.licensecheck.LicenseContentProvider` | ContentProvider | Verificação de licença Google Play |

**Observações estruturais:**
- **Single-Activity Compose** — confirma stack moderna (Compose Navigation). Nosso GoRouter + Flutter é equivalente funcional.
- **Bibliotecas terceiras notáveis que não temos:** Apple Sign-In, Facebook Auth, Intercom (chat de suporte), Bugsnag (error tracking), Android Auto, Pairip license check.
- **Bibliotecas que temos paridade:** Firebase Auth (não temos, usamos JWT próprio), ML Kit (temos `google_mlkit_text_recognition`), push (não temos, FCM seria adição).

---

## §2 — Mapa de rotas Roteirizador Pro atual

Do código em `apps/mobile/lib/app.dart:47-160` (GoRouter + StatefulShellRoute):

| Path | Page | Branch | Estado |
|---|---|---|---|
| `/login` | `LoginPage` | top-level | Live |
| `/register` | `RegisterPage` | top-level | Live |
| `/home` | `HomeListPageOrEmpty` (Empty/List conditional) | Branch 0 | Live |
| `/home/stops/add` | `AddStopPage` (transparent wrapper sobre `AddStopSheet`) | Branch 0 | Live (MS-15a) |
| `/home/stops/voice` | `VoiceCapturePage` | Branch 0 | Live (MS-15a-followup, com pulse + amplitude + auto-restart) |
| `/home/stops/ocr` | `OcrCapturePage` | Branch 0 | Live |
| `/home/stops/map` | `MapStopsPage` | Branch 0 | Live |
| `/home/stops/add-map` | `AddStopsMapPage` | Branch 0 | Live |
| `/home/stops/reorder` | `ReorderPage` | Branch 0 | Live |
| `/home/stops/:id` | `StopDetailPage` | Branch 0 | Live (corpo mínimo: Excluir/Editar) |
| `/home/stops/:id/edit` | `EditStopPage` | Branch 0 | Live |
| `/home/optimize` | `OptimizePage` (loading wrapper) | Branch 0 | Live (mock 200, ordem de entrada) |
| `/home/optimize/route` | `OptimizeRoutePage` | Branch 0 | Live |
| `/home/navigate` | `NavigatePage` | Branch 0 | Live (turn-by-turn shell — checklist sem mapa real) |
| `/home/route-complete` | `RouteCompletePage` | Branch 0 | Live |
| `/settings` | `SettingsPage` | Branch 1 | Live (5 rows: nav app toggle, sentido casa stub, indicações, pagamentos stub, sair) |
| `/settings/share` | `ShareSheet` | Branch 1 | Live (MS-12: WhatsApp + copy link + QR) |

**Total:** 17 rotas, 18 page widgets, 2 branches (Stops + Settings).

---

## §3 — Gap analysis: Spoke tem, Roteirizador Pro não tem

Cada item: descrição funcional Spoke → estado RotPro → decisão proposta (replicar / adaptar / descartar / postergar) → prioridade.

### 3.1 — Onboarding / Auth

| # | Spoke | RotPro hoje | Decisão proposta | Prioridade |
|---|---|---|---|---|
| 1 | Login com Apple ID | Só email/senha | **Postergar** — Apple Sign-In requer conta dev Apple ($99/ano) e não é prioridade BR | Pós-M2 |
| 2 | Login com Facebook | Só email/senha | **Descartar** — Facebook está em queda, baixo valor para motoboy BR | Não |
| 3 | Login com Google | Só email/senha | **Replicar** — Google Sign-In é padrão Android, baixo custo, melhora conversão | Slice 2 Spoke-align |
| 4 | Recuperação de senha (reset via email) | Não temos | **Replicar** — esperado de qualquer app sério; baixo esforço backend | Slice 3 backend |
| 5 | Verificação de email obrigatória? | Provável (não testado) | **Postergar** — overhead pra MVP; voltar pós-M2 se houver problema de fake accounts | Pós-M2 |

### 3.2 — Criar / abrir rota (entry flow)

| # | Spoke | RotPro hoje | Decisão proposta | Prioridade |
|---|---|---|---|---|
| 6 | Tela inicial: **lista de rotas históricas** ("Início deste mês" + entradas datadas) | Lista de paradas avulsa (sem conceito de "rotas separadas por dia") | **Replicar** — fundamental para UX motoboy; cada dia = uma rota distinta | Slice 2 Spoke-align (alto impacto) |
| 7 | **Tela cheia (não modal/sheet) "Criar rota"** (deep-inspecionado 2026-05-26 — MS-A1 upfront): (a) campo nome opcional com auto-sugestão como placeholder — placeholder é salvo se não editado (Spoke usa pattern "[dia-da-semana] Rota [N]"); (b) seletor de data em 3 radio-rows — "Hoje" pré-selecionado com data inline, "Amanhã" com data inline, "Escolher data" → `DatePickerDialog` nativo Android (NÃO chips); (c) seção "Opções de início rápido" com checkbox "Reutilizar paradas anteriores" — quando marcado, CTA muda de rótulo e navega para tela dedicada de seleção de paradas a copiar (não é parte da tela de criação) | Cria paradas diretamente, sem ato de "abrir nova rota" | **Replicar** — abre a porta pra (a) histórico, (b) sentido casa por rota, (c) métricas/admin | Slice 2 Spoke-align |
| 7b | **Editar nome/data de rota existente:** acessível via 3-dot em qualquer linha de rota no drawer. Abre tela estruturalmente idêntica ao wizard mas: título "Editar rota", campo nome pré-populado com valor atual (não placeholder), sem seção "Opções de início rápido", CTA "Salvar alterações" | Não temos rota como entidade, então não temos edit | **Replicar** — reuso da mesma tela do wizard parametrizada por Route? (null=create, non-null=edit) | Slice 2 Spoke-align (MS-A1) |
| 7c | **Duplicar rota:** acessível via 3-dot em qualquer linha de rota no drawer. Cria nova rota com cópia das paradas. UI: apenas menu item, sem tela intermediária observada | Não temos | **Replicar** | Slice 3 backend (depende de copy-stops endpoint) |
| 8 | Reutilizar paradas de rota anterior (via wizard checkbox → tela dedicada com 3 categorias de filtro: stops-not-completed / stops-skipped / stops-done + dropdown de rota fonte + ícone busca) | Não temos | **Replicar** — alto valor; motoboy refaz rotas semelhantes diariamente | Slice 3 backend |
| 9 | Importar manifesto de rotas (compartilhar planilha/CSV ao app) | Não temos | **Postergar** — exige parsing CSV/Excel + UI de mapeamento de colunas | Pós-M2 (slice 8?) |
| 10 | "Ler manifesto de rotas" (OCR multi-stop em uma foto de lista impressa) | Temos OCR single-stop | **Replicar (Slice 3 follow-up)** — já registrado como "Voice multi-address dictation" no roadmap atual; estender para OCR multi-stop é natural | Slice 3 follow-up |
| 10b | **Multi-address dictation nativa** (Spoke tem CTA secundário "fale vários endereços" dentro do flow de voz, confirmando que é feature first-class, não follow-up) | Temos single-stop voice | **Promover prioridade** — não é mais "Slice 3 follow-up", deveria ser parte da slice 3 core | Slice 3 backend |
| 10c | Seletor de idioma no flow de voz (Spoke mostra dropdown com idioma de reconhecimento) | Hardcoded `pt_BR` no `speech_to_text.listen()` | **Postergar** — único uso BR confirmado; voltar pós-M2 se houver demanda multi-idioma | Pós-M2 |
| 11 | Transferir paradas (entre rotas? entre usuários?) | Não temos | **Postergar** — feature complexa, baixo uso provável | Pós-M2 |
| 12 | Copiar paradas para clipboard | Não temos | **Replicar** — feature de baixo custo (text export); útil pra debug e backup do motoboy | Slice 2 Spoke-align |
| 13 | Compartilhar cópia da rota (sair do app) | Temos `ShareSheet` próprio (WhatsApp + link + QR) | **Manter o nosso** — é feature original RotPro e Eduardo confirmou que fica | — |

### 3.3 — Settings (preferências)

A inspeção da Spoke Settings revelou 2 seções: "Preferências de rota" e "Preferências gerais", + rodapé com Assinatura/Licenças/Privacidade/Termos/Sair.

| # | Spoke setting | RotPro hoje | Decisão proposta | Prioridade |
|---|---|---|---|---|
| 14 | App de navegação (escolha) | Temos toggle Waze/Google Maps | **Manter** — já implementado | — |
| 15 | Lado da parada (qualquer lado / direito / esquerdo do veículo) | Não temos | **Replicar** — sinal de profissionalismo; baixo esforço (1 enum + 1 toggle UI) | Slice 2 Spoke-align |
| 16 | Tempo médio na parada (default 1 min) | Não temos | **Replicar** — afeta cálculo de ETA agregado; precisa input numérico | Slice 2 Spoke-align |
| 17 | Tipo de veículo (Carro / Moto / Bicicleta / A pé) | Não temos | **Replicar** — afeta perfil GraphHopper (motorcycle vs car); já temos GH self-hosted | Slice 3 backend (acoplado ao solver) |
| 18 | Evitar pedágios (toggle) | Não temos | **Replicar** — feature GraphHopper trivial (`avoid=toll`); zero custo backend | Slice 3 backend |
| 19 | ID de parada (estilo) — "Moderno", "Por ordem de rota", outros? | Não temos (sempre numérico sequencial) | **Postergar** — preferência decorativa | Pós-M2 |
| 20 | Balão do modo de navegação (toggle "Veja info de entrega enquanto navega") | Não temos | **Postergar** — depende de termos turn-by-turn nativo (não temos) | Pós-M2 |
| 21 | Tema (Automático/Claro/Escuro) | Tema único (claro) | **Replicar** — esperado em qualquer app; baixo esforço; complementa ADR-0035 visual identity | Slice 2 Spoke-align |
| 22 | Endereço de casa | Stub "em breve" (slice 5) | **Manter slice 5** — já planejado | — |
| 23 | Indicações (referral) | Temos `/settings/share` | **Manter o nosso** | — |
| 24 | Pagamentos / Assinatura | Stub "em breve" (slice 4 Stripe Pix) | **Manter slice 4** — já planejado | — |
| 25 | Comparar planos (página de pricing) | Não temos | **Replicar** — necessário para CTA "Assinar" funcionar (slice 4) | Slice 4 dep |
| 26 | Licenças (página de OSS licenses) | Não temos | **Replicar** — exigência legal de qualquer app distribuível; baixo esforço | Slice 6 LGPD |
| 27 | Política de privacidade (link) | Stub no roadmap (slice 6) | **Manter slice 6** | — |
| 28 | Termos de uso (link) | Stub no roadmap (slice 6) | **Manter slice 6** | — |
| 29 | Sair (logout) | Temos no SettingsPage | **Manter** — já implementado | — |
| 30 | Versão do app exibida | Não exibida na UI | **Replicar** — trivia útil pra debug e suporte | Slice 2 Spoke-align (1 linha) |

### 3.4 — Execução da rota (navegação + entrega)

Áreas que não cheguei a inspecionar profundamente (precisa rota ativa com paradas reais), mas inferidas das telas + Activities + Android Auto support:

| # | Spoke | RotPro hoje | Decisão proposta | Prioridade |
|---|---|---|---|---|
| 31 | Status por parada (Pendente / Entregue / Falhou + motivo) — visualmente confirmado via §6.2bis: status aparece como pin colorido no mapa + ícone de status na row do stop dentro do expanded sheet | Não temos (Stop tem só `source`) | **Replicar** — fundamental para o app servir ao motoboy; afeta modelo `Stop` | Slice 2 Spoke-align (modelo) + Slice 3 backend |
| 32 | Notas por parada | Não temos | **Replicar** — esperado | Slice 2 Spoke-align |
| 33 | Foto de entrega (POD — proof of delivery) | Não temos | **Replicar** — Spoke certamente faz; é commodity em apps de delivery | Slice 3 backend (storage de imagem) |
| 34 | Assinatura digital do destinatário | Não temos | **Postergar** — feature avançada | Pós-M2 |
| 35 | Histórico de rotas concluídas + métricas (km, tempo, paradas, entregues, falhas) | Não temos | **Replicar** — depende de §3.4#31; backend precisa persistir rotas | Slice 3 backend |
| 36 | Push notifications (lembrete de início, atualização de rota) | Spoke tem FCM | **Postergar** — overhead infra (FCM setup) | Pós-M2 |
| 37 | Android Auto (controle pelo display do carro) | Spoke tem `CircuitCarAppService` | **Descartar** — fora de escopo M2; complexidade alta | Não |
| 38 | Chat de suporte (Intercom) | Spoke tem Intercom | **Postergar** — Intercom custa caro; usar email/WhatsApp pra suporte M2 | Pós-M2 |
| 39 | Crash reporting (Bugsnag/Sentry) | Não temos (já no tech debt) | **Postergar** — já anotado no TODO post-M2 | Pós-M2 |

### 3.5 — Otimização de rota

| # | Spoke | RotPro hoje | Decisão proposta | Prioridade |
|---|---|---|---|---|
| 40 | Otimização real (provavelmente proprietária / API paga) | Mock 200 retorna ordem de entrada | **Replicar com solver próprio** — já planejado slice 3 (nearest-neighbor + 2-opt) | Slice 3 backend |
| 41 | "Sentido casa" (terminar rota próximo a um ponto) | Stub no roadmap (slice 5) | **Manter slice 5** | — |
| 42 | Marcar parada como prioritária / janela de horário | Não temos | **Postergar** — feature avançada de VRP | Pós-M2 |
| 43 | Re-otimizar após marcação de "Falhou" | Não temos | **Postergar** — depende de §3.4#31 + solver iterativo | Pós-M2 |

---

## §4 — Gap analysis: features RotPro originais (não-Spoke)

| Feature | Origem | Decisão |
|---|---|---|
| `ScreenShare` (WhatsApp branded + copy link `roteirizadorpro.com.br/download` + QR code com `roteirizadorpro.com.br/download`) | Original Eduardo/cliente | **Manter** — é diferencial de aquisição (motoboy compartilha com outros); Spoke não tem equivalente direto |
| Stripe Pix paywall R$ 25,90 / 30 dias (sem subscription recorrente, renovação manual a cada ciclo) | Original (ADR-0030, BUSINESS-RULES.md) | **Manter** — modelo de monetização diferenciado pra BR (Spoke usa subscription mensal/anual padrão) |
| Stripe Connect 50/50 split entre 2 sócios | Original (ADR-0030) | **Manter** — modelo de receita do cliente; transparente pro usuário final |
| "Sentido casa" toggle | Original (slice 5) | **Manter** — feature simples, valor pro motoboy BR (volta pra casa no fim do dia) |
| Painel admin (sócios veem usuários, pagamentos, métricas) | Original (slice 7) | **Manter** — necessidade operacional do cliente |
| ADR-0033 (drop neon dot) + ADR-0034 (Voice single CTA) | Original Eduardo | **Manter** — visualmente alinhado com Spoke (que também tem CTAs limpos) |

---

## §5 — Inventário hierárquico de Settings da Spoke

Estrutura observada (sem reproduzir microcopy literal):

```
Settings/
├── Preferências de rota/
│   ├── App de navegação (default: Spoke próprio)
│   ├── Lado da parada (default: qualquer)
│   ├── Tempo médio na parada (default: 1 min)
│   ├── Tipo de veículo (default: Carro)
│   ├── Evitar pedágios (toggle, off)
│   ├── ID de parada (estilo de display)
│   └── Balão do modo de navegação (toggle, on)
├── Preferências gerais/
│   └── Tema (Automático/Claro/Escuro)
├── Conta/
│   ├── Assinatura → "Comparar planos" (CTA)
│   ├── Licenças
│   ├── Política de privacidade
│   ├── Termos de uso
│   └── Sair
└── Versão do app (rodapé: "Spoke-vX.Y.Z")
```

**Comparação com nosso SettingsPage atual** (`apps/mobile/lib/features/settings/presentation/settings_page.dart:84-142`):

```
Settings/
├── Aplicativo de navegação (SegmentedButton: Waze/Google Maps, default Waze per ADR-0017)
├── Endereço de casa (stub "em breve" — slice 5)
├── Indicações (→ /settings/share)
├── Pagamentos (stub "em breve" — slice 4)
└── Conta/
    └── Sair (vermelho)
```

**Gap:** 5 categorias inteiras ausentes (Preferências de rota completas, Tema, Comparar planos, Licenças, Privacidade/Termos, Versão).

---

## §6 — Flows críticos da Spoke (golden paths)

Mapeamento estrutural dos fluxos observados durante a inspeção. Cada flow descreve a sequência de estados navegacionais sem reproduzir copy verbatim.

### 6.1 — Login (não inspecionado profundamente; Eduardo já logado)
1. Tela login com opções: email/senha + Apple + Facebook + Google
2. Login bem-sucedido → home (lista de rotas)
3. Não-logado → tela de signup similar

### 6.2 — Criar nova rota (deep-inspecionado 2026-05-26 via spoke-parity-checker, MS-A1 upfront)

**Estrutura geral:** rotas vivem em um **drawer lateral** (hamburger no canto sup. esquerdo da rota ativa). Spoke **não tem BottomNav**. O drawer tem: card de perfil no topo (avatar + nome + email + badge de plano + CTA assinar), section header "Hoje" com rotas de hoje listadas, section header "Início deste mês" com rotas anteriores, botão full-width "Criar rota" pinned no rodapé do drawer, ícones Help + Settings no canto sup. direito do drawer.

**Cada linha de rota:** data abreviada à esquerda ("26 de mai."), nome à direita ("terça-feira" ou nome custom), 3-dot overflow na extrema direita.

**3-dot overflow de qualquer linha de rota:** (a) "Definir nome e data" (abre form de edição estrutura idêntica ao wizard mas sem zona C), (b) "Duplicar rota", (c) "Excluir rota" — sem confirm dialog observado (verificar com rota não-vazia).

**Wizard "Criar rota" (tela cheia, NÃO bottom sheet):**
1. Tap em "Criar rota" no rodapé do drawer → push de tela cheia com back-arrow no top-left (não X close)
2. **Zona A** — "Nome da rota (opcional)" + EditText. Placeholder = nome auto-gerado, pattern "[dia-da-semana] Rota [N]" onde N incrementa por rota do mesmo dia. Se o usuário não editar, o placeholder vira o nome salvo.
3. **Zona B** — "Selecione a data" + 3 radio-rows:
   - "Hoje" + data abreviada inline ("ter., 26 de mai."), pré-selecionado
   - "Amanhã" + data abreviada inline
   - "Escolher data" + chevron-right → abre `DatePickerDialog` nativo Android (grid de mês + ícone lápis pra modo text-input + ações CANCELAR/OK)
4. **Zona C** — "Opções de início rápido" + checkbox "Reutilizar paradas anteriores" (uncheck por default). Quando marcado, CTA muda label para algo como "continuar pra copiar paradas".
5. **CTA** full-width primary "Confirmar" no rodapé. Tap → cria rota, navega imediatamente pra mapa da nova rota vazia. **Sem modal de sucesso, sem banner.**

**Sub-flow "Reutilizar paradas" (se checkbox marcado):** tela cheia separada com (a) back-arrow + ícone busca no top-bar, (b) dropdown "De: [data + nome]" com chevron pra trocar rota fonte, (c) 3 seções colapsáveis com checkboxes por categoria (stops não-completas, stops puladas, stops feitas) cada uma com ícone próprio e empty-state quando categoria vazia, (d) CTA secundário text-style "pular cópia e criar rota vazia" no rodapé.

**Coexistência de rotas (CRÍTICO pra data model):**
- **N rotas por dia** confirmado por observação ("terça-feira" e "terça-feira Rota 2" ambas sob "Hoje" simultaneamente). Data NÃO é unique key — rotas têm `id` separado.
- **Switching:** tap em qualquer linha do drawer → rota tapped vira a view principal. Sem long-press, sem gesto especial, sem "set active" explícito.
- **Empty route lifecycle:** rotas vazias **persistem indefinidamente**. Spoke NÃO auto-deleta. Deleção é exclusivamente manual via 3-dot "Excluir rota".
- **Section grouping:** "Hoje" agrupa rotas com data == hoje; "Início deste mês" agrupa rotas mais antigas. Grouping é por períodos relativos legíveis, não por strings de data crua.

**Pós-criação:** navega imediatamente pra **tela ativa de rota** — ver §6.2bis.

### 6.2bis — Tela ativa de rota (mapa + sheet) — deep-inspecionada 2026-05-26 via spoke-parity-checker

**Arquitetura confirmada:** Spoke usa **Google Maps SDK** (TextureView + fragment_container) como **base layer full-screen**; toda UI é overlay Compose por cima. Sem Activity transitions dentro da rota.

**Estrutura geral do sheet (CRÍTICO):** os IDs `stepListHeader` (collapsed) e `stepList` (expanded) são a mesma view com Y diferente — equivalente a um `DraggableScrollableSheet`. **Exatamente 2 snap points confirmados:**
- **Collapsed:** y=[2013, 2265], ~14% da altura da tela. Só uma barra (bottom bar) visível; mapa ocupa o resto.
- **Expanded:** y=[160, 2400], full-screen abaixo da status bar. Cobre o mapa inteiro (mapa continua renderizado por baixo mas invisível).
- **Sem snap point intermediário.** Swipe de collapsed vai direto pra expanded.
- **Drag handle:** ~y=1985, centered, horizontal pill curto.

**Elementos da bottom bar collapsed (esquerda → direita):**
| Elemento | Bounds | Content-desc | Função |
|---|---|---|---|
| Ícone área (search/add indicator) | [0,2048][96,2183] | — | Decoração |
| `EditText` input endereço | [159,2048][674,2183] | — | Tap → abre busca autocomplete (texto) |
| OCR `IconButton` | [720,2081][788,2149] | "Ler etiqueta de endereço" | Tap → camera viewfinder (1 tap depth, não 3) |
| Voice `IconButton` | [833,2081][901,2149] | "Dite o endereço" | Tap → voice capture (1 tap depth) |
| 3-dot kebab `IconButton` | [968,2081][1036,2149] | "Menu" | Tap → bottom-sheet modal com 5 opções |

**Floating map controls (lado direito, visíveis só com sheet collapsed):**
- Map layer toggle [934,1699][1002,1767] — content-desc "Alternar modo de mapa" — tap troca padrão↔satélite; long-click pode expor mais opções.
- Map recenter button [934,1867][1002,1935] — content-desc "Alternar para o mapa" — recentra na GPS location.

**Hamburger:** floating button [46,138][181,273] content-desc "Menu" — abre o drawer lateral (§6.2).

**Empty-state da rota (expanded sheet com 0 stops):**
1. Ilustração + texto-prompt centralizado (microcopy paraphraseada: "Adicione as primeiras paradas para começar a criar sua rota")
2. **CTA primário:** full-width filled button "Adicionar paradas" em y~[1967, 2023]
3. **CTA secundário:** text-style link "Copiar paradas de uma rota anterior" em y~[2125, 2181] — navega pro sub-flow Reutilizar paradas (§3.2 item 8)

**Sem BottomNavigationBar em lugar nenhum da view ativa.** Settings se acessa via drawer header.

### 6.3 — Adicionar parada (3 métodos)
- **Texto:** tap na barra inferior → tela de busca com autocomplete (não inspecionado a fundo — depende de geocoding real)
- **Voz:** tap no ícone microfone → captura voz → confirmar transcrição
- **OCR (foto de etiqueta):** tap no ícone de leitura → câmera viewfinder → captura → confirma extração
- **Mapa:** tap no mapa em ponto específico → mint Stop com lat/lng tap (RotPro já faz isso)

### 6.4 — Menu kebab de rota ativa (deep-inspecionado 2026-05-26 via spoke-parity-checker)

**Apresentação:** bottom-sheet modal (meia-tela) ao tap no 3-dot da bottom bar.

**5 opções confirmadas por live dump (em ordem de aparição):**
1. Compartilhar cópia da rota — export pra outro app (Share Intent Android)
2. Transferir paradas — mover paradas pra outra rota (ou outro usuário?) — verificar em run dedicado
3. Copiar paradas... — text export pra clipboard (formato a confirmar)
4. Ler manifesto de rotas — OCR multi-stop de lista impressa
5. Importar manifesto de rotas — file picker pra CSV/planilha

**Nenhuma opção destrutiva neste menu.** "Excluir rota" fica no 3-dot do drawer (por linha de rota, ver §6.2).

### 6.5 — Otimizar + Iniciar navegação (não inspecionado)
Inferido:
1. Lista de paradas → CTA "Otimizar"
2. Loading state → lista reordenada com badge "otimizada"
3. CTA "Iniciar" → navegação ativa
4. Tela de navegação: parada atual em foco + ações Entregue / Falhou (com motivo) + Próxima
5. Hand-off ou turn-by-turn nativo via Spoke (App de navegação = "Spoke" no default)

### 6.6 — Configurações (inspecionado §5)

### 6.7 — Paywall / Assinatura (não inspecionado — exige tap em "Assinar")
Existência confirmada: botão "Assinar" no header da home, link "Comparar planos" em Settings.

---

## §7 — Decisões finais Eduardo (LOCKED 2026-05-26)

Eduardo locked the scope on 2026-05-26 with 7 directives + 3 answers. Strategy: **replicate everything functional from the Spoke inspection, then iterate on visual divergence afterwards** (fewer judgment calls now). The categorical buckets below are now locked, not proposals.

### 7.1 — Diretivas Eduardo (verbatim, traduzidas estruturalmente)

1. **Replicar tudo funcionalmente primeiro**, depois ajustar design pra não ficar idêntico
2. **Cortar Apple e Facebook auth** — manter email/senha + Google
3. **Identidade visual mantida** (tokens, paleta, ícones Lucide, tipografia, animações)
4. **Stripe Pix paywall mantida** (slice 4 + tudo que o cliente solicitou pro APK)
5. **ScreenShare original mantida** (QR + link + WhatsApp pra divulgação)
6. **Sem qualquer menção a "Spoke" na UI** — copy em PT-BR, original
7. **iOS descartado** — só Android M2
8. **Login + Register telas atuais mantidas** — sem refazer
9. **FCM push notifications** entram no escopo (gratuito até 1M/mês)
10. **Intercom, Bugsnag/Sentry, Android Auto** — fora (MVP enxuto, infra cara descartada)
11. **Estimativa real documentada, sem maquiar** — Eduardo decide se renegocia com Workana
12. **Quando houver qualquer dúvida estrutural/funcional, validar inspecionando o Spoke e seguir a estrutura observada** (com nossa identidade visual). Codificada via ADR-0036 amendment 2026-05-26 (dispatch upfront do `spoke-parity-checker` durante brainstorming). Aplica-se a slices 2 + 3; slices 4/5/6/7 ficam fora porque não têm equivalente Spoke. Adicionada 2026-05-26 durante MS-A1 brainstorming Q10, depois que Eduardo redirecionou "se tiver qualquer dúvida, valide usando o SPOKE, e siga como está lá".
13. **Objetivo M2 = white-label da Spoke com nossa stack — 100% idêntico funcionalmente AGORA, ajuste de UI fica pro final**. Não inventar arquitetura, não inventar UX, não criar opções. Tudo o que existe na Spoke (flow, tela, gesto, settings, comportamento) deve existir igual na RotPro, adequado à stack Flutter+Riverpod+GoRouter+SharedPrefsAsync. Adicionada 2026-05-26 durante MS-A1 design review, depois que Eduardo redirecionou "tudo está ficando tão complexo. Meu objetivo simplesmente é esse: trazer tudo igual, depois eu ajusto UI." **Implicação prática:** brainstorming agora só pergunta sobre (a) decisões que Spoke não cobre (migração de dados, features RotPro originais), (b) microcopy PT-BR (per legal boundary não copiamos Spoke), (c) confirmação de inspeção (M54 conectado, Spoke logado). NÃO perguntar mais "Opção A/B/C arquitetural" — Spoke decide; se Spoke ambíguo, dispatch o subagent.

### 7.2 — Replicar (em escopo M2)

Todos os 43 itens §3 que NÃO entram explicitamente em §7.3/§7.4 são **REPLICAR**, organizados em ROADMAP-v2 por slice.

**Auth (Slice 2 Spoke-align):**
- Google Sign-In (única opção social — Apple+Facebook cortados)
- Recuperação de senha via email (Slice 3 backend)

**Conceito de "Rota" como entidade (Slice 2 Spoke-align + Slice 3 backend):**
- Lista de rotas históricas separadas por dia
- Wizard "Criar rota" (nome opcional + data Hoje/Amanhã/Outra)
- Reutilizar paradas de rota anterior (Slice 3 backend)
- Histórico de rotas concluídas + métricas básicas (km, tempo, paradas, entregues, falhas)

**Stop model expandido (Slice 2 Spoke-align modelo + Slice 3 backend):**
- Status por parada (Pendente / Entregue / Falhou + motivo)
- Notas por parada
- Foto de entrega — POD (Slice 3 backend, storage de imagem)
- Copiar paradas para clipboard (Slice 2 Spoke-align)

**Settings completas (Slice 2 Spoke-align + alguns Slice 3 backend):**
- Lado da parada (qualquer / direito / esquerdo)
- Tempo médio na parada (default 1 min)
- Tipo de veículo (Carro / Moto / Bicicleta / A pé) — afeta perfil GraphHopper
- Evitar pedágios (toggle) — param GraphHopper
- Tema (Automático / Claro / Escuro)
- Comparar planos (página de pricing) — pré-req paywall
- Licenças (OSS licenses) — Slice 6 LGPD
- Versão do app exibida
- ID de parada (estilo de display) — também replicado (era postergado antes, agora replicar tudo)
- Balão do modo de navegação (toggle) — também replicado

**Otimização e navegação:**
- OCR multi-stop ("ler manifesto") — Slice 3 follow-up (extensão do OCR single-stop)
- Multi-address dictation (gap §3.2#10b) — Slice 3 core (Spoke trata como first-class)
- Otimização real (solver nearest-neighbor + 2-opt) — Slice 3 backend (já planejado)
- Re-otimização após "Falhou" — Slice 3 follow-up (depende de status por parada)
- Janela de horário por parada (Slice 3 follow-up)
- Importar manifesto (CSV/Excel) — Slice 3 follow-up (parser + UI de mapeamento)
- Transferir paradas (Slice 3 follow-up)

**Push notifications (NOVO):**
- FCM setup + endpoint backend + tela de preferências de notificação — Slice 3 backend

**Mantém sem mudança:**
- Slice 1 (APK distribuível) ✅ já entregue
- Slice 4 (Stripe Pix R$ 25,90 / 30 dias, ADR-0030)
- Slice 5 (Sentido casa)
- Slice 6 (LGPD: export, delete, termos, privacidade)
- Slice 7 (Painel admin)
- `ScreenShare` original RotPro (WhatsApp + link + QR)
- Login + Register telas atuais
- ADR-0017 (Waze default + Google Maps toggle)
- ADRs 0033 (sem neon dot) e 0034 (Voice single CTA) — reframed como Spoke-aligned

### 7.3 — Postergar para pós-M2

| Feature | Razão |
|---|---|
| Apple Sign-In | Cortado por diretiva Eduardo (#2) |
| Verificação de email obrigatória | Overhead pra MVP; voltar pós-M2 se houver problema de fake accounts |
| Assinatura digital do destinatário | Feature avançada; POD com foto cobre o caso essencial |
| Seletor de idioma no Voice flow | Single locale BR confirmado; voltar se houver demanda |
| Crash reporting (Sentry) | Cortado por diretiva Eduardo (MVP enxuto, infra cara fora) |
| Chat suporte in-app (Intercom) | Cortado por diretiva Eduardo (suporte via WhatsApp/email) |
| Android Auto | Cortado por diretiva Eduardo (complexidade vs benefício) |

### 7.4 — Descartar definitivamente

| Feature | Razão |
|---|---|
| Facebook Sign-In | Diretiva Eduardo (#2) — em queda, baixo valor BR |
| Apple Sign-In | Diretiva Eduardo (#2) — sem iOS, sem motivo |
| iOS support | Diretiva Eduardo (#7) — só Android no M2; ADR-0014 já cobre formalmente |
| Mentioning "Spoke" / "Circuit" anywhere in UI copy | Diretiva Eduardo (#6) — toda microcopy original PT-BR Roteirizador Pro |

### 7.5 — Estimativa real (sem maquiar, per diretiva #11)

**Roadmap original (pré-pivot):** Slice 2 ≈ 5-7d + Slice 3 ≈ 4-6d + Slice 4 ≈ 4-6d + Slice 5 ≈ 1d + Slice 6 ≈ 2-3d + Slice 7 ≈ 3-5d = **17-25 dias úteis**.

**Roadmap-v2 (replica tudo per diretiva #1):**

| Slice | Conteúdo expandido | Estimativa |
|---|---|---|
| 2 Spoke-align (UI/UX) | Conceito de Rota como entidade + Google Sign-In + 8+ settings novos + status/notas/POD por parada (modelo) + tema + copiar paradas + versão exibida + Stop model expansion + tela de preferências de notificação UI + página Comparar Planos UI | **12-16 dias** |
| 3 backend (Spoke parity) | Solver real (nearest-neighbor + 2-opt) + Nominatim self-hosted SP + reutilizar paradas + histórico + POD storage + tipo veículo + evitar pedágios + recuperação senha + OCR multi-stop + multi-address dictation + FCM setup + push endpoint + re-otimização após Falhou + janela de horário + importar manifesto + transferir paradas | **10-14 dias** |
| 4 Stripe Pix paywall | Sem mudança vs original (ADR-0030 + página Comparar Planos é dep do Slice 2) | **4-6 dias** |
| 5 Sentido casa | Sem mudança vs original | **1 dia** |
| 6 LGPD | Sem mudança vs original + Licenças OSS movida pra cá | **2-3 dias** |
| 7 Painel admin | Sem mudança vs original | **3-5 dias** |
| **Total v2** | | **32-45 dias úteis** (~80-90% maior que original) |

**Trigger orçamentário ativado:** estimativa v2 excede materialmente o original. Eduardo já decidiu **"Documentar e seguir"** — eu escrevo o ROADMAP-v2 com a estimativa real; ele decide se renegocia Workana, corta escopo em conversa separada, ou aceita o overrun. Sem cortes adicionais por mim.

### 7.6 — Cobertura de inspeção pendente (gate Spoke deep-dive por microsprint)

Per §9, vários flows Spoke críticos não foram inspecionados nesta sessão (login completo, autocomplete de busca, OCR full, Voice em modo ouvindo, navigate ativa, paywall completo, importar manifesto UI). Como agora **replicamos tudo**, cada microsprint que tocar esses flows DEVE rodar uma sessão dedicada de Spoke deep-dive (~30 min adb + screenshots) ANTES do `/new-spec` correspondente. O ROADMAP-v2 marca esse gate explicitamente em cada microsprint relevante.

---

## §9 — Cobertura da inspeção (telas inspecionadas vs pendentes)

Inspeção realizada 2026-05-26 via adb shell uiautomator dump + screencap. Captura sistemática mas não exaustiva — algumas telas exigem dados/estados específicos que não foram acessados nesta sessão.

### Spoke — inspecionado
- ✅ Home (lista de rotas históricas + CTA criar rota)
- ✅ Settings (rolagem completa: Preferências de rota, Preferências gerais, Conta, rodapé)
- ✅ Wizard "Criar rota" (nome + data + reutilizar paradas) — **deep-inspecionado 2026-05-26** via spoke-parity-checker MS-A1 upfront run #1: estrutura completa do drawer + 3-dot menu por rota + zonas A/B/C do wizard + coexistência multi-rotas + switching + empty-route lifecycle + sub-flow Reutilizar paradas + form de edição. Resultado registrado em §6.2 + §3.2 itens 7/7b/7c/8.
- ✅ **Tela ativa de rota — mapa + sheet (estados: collapsed, expanded, empty, kebab)** — **deep-inspecionado 2026-05-26** via spoke-parity-checker MS-A1 upfront run #2: DraggableScrollableSheet equivalent com 2 snap points confirmados; bottom bar collapsed elementos com bounds + content-desc; floating map controls; empty-state expanded com CTAs primário + secundário. Resultado registrado em §6.2bis. Gap remanescente: expanded sheet COM stops reais (rota inspecionada estava vazia).
- ✅ Menu kebab de rota (5 opções confirmadas via live dump §6.4)
- ✅ Voice flow entry (botão + seletor de idioma + CTA "fale vários endereços")

### Spoke — NÃO inspecionado (gaps de cobertura)
- ❌ Tela de login/cadastro completa (Eduardo já estava logado; sair e refazer login arriscaria perder estado)
- ❌ Tela de busca de endereço com autocomplete (texto)
- ❌ Tela completa de OCR (foto de etiqueta) e UI de confirmação
- ❌ Tela completa de Voice em modo "ouvindo" (não cheguei a granted-permission state)
- ❌ Flow de otimização de rota (lista com paradas reais + tap "Otimizar" + tela de loading + lista otimizada)
- ❌ Tela de navegação ativa (turn-by-turn, marcação Entregue/Falhou + motivo)
- ❌ Foto de entrega (POD) UI
- ❌ Histórico de rotas completas + métricas
- ❌ Paywall completo / "Comparar planos" / tela de assinatura
- ❌ Importar manifesto (UI do CSV picker + mapeamento de colunas)
- ❌ Transferir paradas (UI de target picker)

**Mitigação:** os gaps acima foram inferidos no §3 a partir de observação parcial e estrutura típica de apps de delivery. A Fase 3 (ROADMAP-v2) deve marcar microsprints sobre esses flows como "spec gate exige re-inspeção" antes de codar, pra não chutar UX. Alternativa: Eduardo navega comigo nos flows pendentes em uma sessão dedicada antes da slice 2 Spoke-align começar.

### Roteirizador Pro — inspecionado
- ✅ Home com paradas (TopBar, cards com grip handle, FAB Lucide, "Otimizar rota" sem neon dot, BottomNav)
- ✅ Settings (5 categorias confirmadas: nav app Waze/Google Maps, casa stub, indicações, pagamentos stub, sair)
- ✅ AddStop sheet (3 method buttons: Teclado/Voz/Câmera + scrim)

### Roteirizador Pro — NÃO inspecionado (sessão única; cobertura suficiente pra inventário inicial)
- ❌ Login/Register (já logado)
- ❌ Voice page (tentei tocar pelo sheet, tap não pegou)
- ❌ OCR page
- ❌ MapStops, AddStopsMap, Reorder
- ❌ Optimize loading + OptimizeRoute
- ❌ Navigate
- ❌ RouteComplete
- ❌ StopDetail + EditStop
- ❌ ShareSheet (já temos cobertura forte via MS-12 sessão 2026-05-23)

**Mitigação:** as telas RotPro pendentes são bem documentadas em código (`app.dart:47-160`, cada page em `apps/mobile/lib/features/*/presentation/`) e em sessions anteriores. O inventário §2 lista todas elas com path + page widget + estado, derivadas do código. Inspeção visual seria útil pra validar fidelidade visual no slice gate, não pra mapear estrutura.

### Implicação pra Fase 3

A ROADMAP-v2 deve ter um marco "Spoke deep-dive" no início de cada microsprint que toca um flow não inspecionado nesta sessão. Custo estimado: ~30 min por microsprint pra inspeção dedicada + screenshots + atualização inline do inventário antes do `/new-spec`.

---

## §8 — Próximos passos

1. **Eduardo revisa §3 + §7 + §9** e marca o que aprova / corta / discute.
2. Após aprovação: escrever `docs/08-ROADMAP-v2.md` com slices reorganizados. **Concluído 2026-05-26** (commit `7692c45`). **Reset 2026-05-26 pós-pivot:** v2 foi simplificado posteriormente removendo microsprints A/B (Eduardo redirecionou pra abordagem "white-label Spoke sem ceremonial"). Estado atual do roadmap em `docs/08-ROADMAP-v2.md`.
3. Cada microsprint do v2 ganha `/new-spec` + `/new-plan` no momento de execução.
4. `docs/08-ROADMAP.md` (v1) foi **arquivado 2026-05-26 em `docs/archive/2026-05-26-08-ROADMAP-v1-pre-pivot.md`**; o stub de redirecionamento foi deletado no reset 2026-05-26 (v2 é o único agora).

---

## Referências

- [ADR-0010](../decisions/0010-clone-positioning.md) — Functional fork positioning (cobre legalidade da inspeção)
- [ADR-0035](../decisions/0035-spoke-functional-clone-prototype-creative-reference.md) — Pivot foundational
- [`docs/08-ROADMAP-v2.md`](../08-ROADMAP-v2.md) — Roadmap pós-pivot (ATIVO)
- [`docs/archive/2026-05-26-08-ROADMAP-v1-pre-pivot.md`](../archive/2026-05-26-08-ROADMAP-v1-pre-pivot.md) — Roadmap pré-pivot (ARQUIVADO)
- [`docs/M2-SLICE-CHECKLIST.md`](../M2-SLICE-CHECKLIST.md) — Verification gates
- `apps/mobile/lib/app.dart:47-160` — GoRouter atual do RotPro
- `apps/mobile/lib/features/settings/presentation/settings_page.dart` — SettingsPage atual
- `/tmp/spoke-inspection/` — screenshots + XML dumps da inspeção (não-commitados; descartáveis)
- Spoke v3.65.1 (`com.underwood.route_optimiser`) inspecionada 2026-05-26 no Samsung M54 (RQCW401G33T) com conta Eduardo logada
