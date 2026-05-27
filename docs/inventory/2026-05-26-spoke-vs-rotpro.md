# Spoke vs Roteirizador Pro — inventário comparativo

> **Data:** 2026-05-26 (Fase B deep-pass via Maestro MCP §10.1-10.24 + Fase B-followup §11 + **Audit 2026-05-26 §12-§13 — cross-check com docs oficiais Spoke**)
> **Fonte:** inspeção via adb no Samsung M54 (RQCW401G33T) — RotPro `br.com.roteirizadorpro.roteirizador_pro` + Spoke `com.underwood.route_optimiser` v3.65.1. **Fase inicial (§1-§9):** uiautomator dump + screencap bash workflow. **Fase B (§10-§11):** Maestro MCP `inspect_screen` + `take_screenshot` + `run` via tap automation, per ADR-0037. **Audit (§12-§13):** cross-check sistemático com docs oficiais Spoke via 8 WebSearches em help.spoke.com + spoke.com/route-planner + spoke.com/dispatch.
> **Driver:** [ADR-0035](../decisions/0035-spoke-functional-clone-prototype-creative-reference.md) — Spoke é o guia funcional, prototipo é referência criativa, cliente Ueslei é desempate
> **Spoke instance inspecionado:** `com.underwood.route_optimiser` v3.65.1 (publisher Underwood, Brasil; rebrand do Circuit Route Planner)
> **Disclaimer legal:** este inventário descreve funcionalidades, navegação e estrutura de UX para fins de paridade funcional (per [ADR-0010](../decisions/0010-clone-positioning.md) — "functional fork with original visual identity"). Não reproduz microcopy verbatim, ícones, ilustrações, paletas, ou tipografia da Spoke. Screenshots de inspeção vivem apenas em `/tmp/spoke-inspection/` e NÃO são commitados.

---

## ⚠️ Como ler este inventário (post-audit 2026-05-26)

**Audit 2026-05-26** identificou 7 discrepâncias (A.1-A.7) entre observação empírica e docs oficiais, 10 features Spoke não mapeadas (B.1-B.10), 5 ambiguidades por resolver (C.1-C.5), e 4 duplicações cosméticas (D.1-D.4). Aplicadas:

- **A.1-A.7 corrigidas inline** (busque por "⚠️ Audit 2026-05-26" para localizar correções pontuais nas seções afetadas: §6.2bis, §10.3, §10.5, §10.6.2, §10.12, §10.19.1, §11.5, §6.4 item 1, §10.21)
- **B.1-B.10 documentadas em §12** — features oficiais Spoke não mapeadas, categorizadas com decisão proposta (replicar/postergar/descartar) por slice
- **C.1-C.5 documentadas em §13** — ambiguidades pendentes com protocolo de resolução executável (passos exatos Maestro MCP, tempo estimado, slice afetado). C.6 (pricing model) foi removida — não era ambiguidade, modelo já está fechado per ADR-0030 + BUSINESS-RULES.md (single paid tier R$ 25,90/30 dias via Stripe Pix; trigger paywall em "Iniciar Navegação"; APK-only).
- **D.1-D.4 (cosmético — duplicações de info entre seções):** documentadas no relatório `/tmp/spoke-audit-2026-05-26.md` mas NÃO refatoradas inline (baixo impacto; faria sentido só num cleanup futuro do inventário inteiro)

**Convenção para sessões de implementação:**

1. **Antes de spec qualquer microsprint Spoke-aligned:** ler §10 + §11 da feature respectiva + §12 (verifica se há feature oficial não mapeada relevante) + §13 (verifica se há ambiguidade pendente que afete decisão).
2. **Se §13 listar ambiguidade pendente:** executar protocolo de resolução ANTES de finalizar spec (30 min a 1h via Maestro MCP).
3. **Se §12 listar feature relevante mas ainda sem decisão:** discutir com Eduardo no D1 brainstorming.
4. **Microcopy / pricing tier / decisão técnica:** quote `⚠️ Audit 2026-05-26` é fonte autoritativa quando conflita com texto original do inventário.

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
| 13 | **3 features Spoke distintas (não confundir):** (a) "Compartilhar cópia da rota" do kebab §6.4 = **enviar paradas pra outro motoboy Spoke** via QR/link/share (peer transfer); (b) "Compartilhar rota em tempo real" do ready-to-run §10.12 = **live tracking pro cliente final** acompanhar entrega; (c) RotPro `ShareSheet` (WhatsApp + link + QR) = **divulgação do APP** (`roteirizadorpro.com.br/download`) pra captar novos usuários — feature original. | **(a) Postergar pós-M2** (peer transfer requer 2 contas Spoke conhecidas — modelo viral, baixa prioridade); **(b) Slice 3+ backend** (live tracking requer endpoint público + tela web; é diferencial competitivo); **(c) Manter** RotPro como está (já é feature original; não conflita com Spoke) | (a) Pós-M2 / (b) Slice 3 follow-up / (c) Manter |

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

> **⚠️ Audit 2026-05-26:** esta seção descreve estado VAZIO da rota (sheet collapsed default). Para estado COM paradas (sheet auto-expanded), ver §10.5 — comportamento divergente.

**Arquitetura confirmada:** Spoke usa **Google Maps SDK** apenas como **base layer de mapa** (TextureView + fragment_container) full-screen; toda UI Spoke é overlay Compose por cima. A **navegação turn-by-turn default é proprietária Spoke** ("Navegação do Spoke" — picker §10.19.1 opção #1, *Google-powered* por baixo mas UI custom Spoke), NÃO Google Maps direto. Autocomplete provavelmente usa Google Places API por trás dos panos (Spoke é cliente Google Maps Platform), mas a UI de resultados é Compose Spoke. Sem Activity transitions dentro da rota.

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
1. Compartilhar cópia da rota — ⚠️ Audit 2026-05-26 (per A.5): **peer transfer pra outro motoboy Spoke** via QR code/link (NÃO é Share Intent genérico). Docs Spoke: "drivers can quickly and easily send and receive stops from other Spoke Route Planner users in just a few clicks, using a QR code, link, sharing, or by downloading"
2. Transferir paradas — overlap com #1; provavelmente sub-feature ou semântica diferente. Hipótese: #1 = compartilhar rota inteira; #2 = mover paradas selecionadas pra outra rota (mesma conta ou outra). Validar gap §13 C.5
3. Copiar paradas... — text export pra clipboard (formato a confirmar)
4. Ler manifesto de rotas — OCR multi-stop de lista impressa
5. Importar manifesto de rotas — file picker pra CSV/planilha (`.csv/.tsv/.xls/.xlsx/.xlm/.txt` per docs)

**Nenhuma opção destrutiva neste menu.** "Excluir rota" fica no 3-dot do drawer (por linha de rota, ver §6.2).

**⚠️ Audit 2026-05-26 — feature NÃO presente neste menu (ver §12 B.5):**
- **Exportar CSV / Imprimir manifesto** — Spoke documenta export ("Every plan type provides options to print a manifest or export route data as a CSV file"). Pode estar em sub-menu não inspecionado OU ser feature do tier Standard apenas. Drillar em sessão dedicada.
- **Compartilhar rota em tempo real** (live tracking pro cliente) — está em ready-to-run §10.12, NÃO neste kebab.

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
- [ADR-0037](../decisions/0037-maestro-mcp-for-spoke-inspection.md) — Maestro MCP como camada preferida de inspeção (usada na §10)
- [`docs/08-ROADMAP-v2.md`](../08-ROADMAP-v2.md) — Roadmap pós-pivot (ATIVO)
- [`docs/archive/2026-05-26-08-ROADMAP-v1-pre-pivot.md`](../archive/2026-05-26-08-ROADMAP-v1-pre-pivot.md) — Roadmap pré-pivot (ARQUIVADO)
- [`docs/M2-SLICE-CHECKLIST.md`](../M2-SLICE-CHECKLIST.md) — Verification gates
- `apps/mobile/lib/app.dart:47-160` — GoRouter atual do RotPro
- `apps/mobile/lib/features/settings/presentation/settings_page.dart` — SettingsPage atual
- `/tmp/spoke-inspection/` — screenshots + XML dumps da inspeção (não-commitados; descartáveis)
- Spoke v3.65.1 (`com.underwood.route_optimiser`) inspecionada 2026-05-26 no Samsung M54 (RQCW401G33T) com conta Eduardo logada

---

## §10 — Fase B deep-pass via Maestro MCP (2026-05-26)

> **Source:** `mcp__maestro__inspect_screen` / `mcp__maestro__run` no M54 (`RQCW401G33T`). Fonte preferida per ADR-0037; substitui bash + `uiautomator dump` como mecanismo primário.
> **Escopo:** este § apenda **só fatos estruturais ainda NÃO capturados nas §§3/5/6**. Quando uma sub-seção repetiria material já em §6.x, ela é omitida ou reduzida a "ver §6.X" + delta novo.
> **Disclaimer ADR-0010 mantido:** dumps abaixo são reduzidos pra hierarquia + IDs + bounds + content-desc. Microcopy verbatim >5 palavras consecutivas é parafraseado ou omitido.

### 10.1 — Drawer aberto (delta sobre §6.2)

**Confirma §6.2.** Deltas observáveis adicionados:

- **Scrim para fechar drawer:** ocupa `[967,0][1080,2400]` (faixa de ~10% à direita), content-desc literal `"Fechar menu de navegação"`, clickable. Confirmação de que swipe-from-edge OU tap no scrim fecham — não há botão X no drawer.
- **Drawer body bounds:** `[0,0][967,...]` (90% da largura). Ocupa toda a altura abaixo da status bar.
- **Top icons bounds exatos:** Help `[695,103][808,216]` (a11y "Ajuda e suporte"), Settings `[831,103][944,216]` (a11y "Configurações"). Ambos `android.widget.Button` com View sobreposta clickable.
- **Sample real de seções com conteúdo** (estado da Spoke do Eduardo neste momento):
  - Seção `"Hoje"` (header `[45,700][944,748]`): 2 linhas
    - `[23,771][944,906]` — data `"26 de mai."` + nome `"terça-feira Rota 2"` + kebab `[820,771][955,906]`
    - `[23,929][944,1064]` — data `"26 de mai."` + nome `"terça-feira"` (texto azul = rota ativa) + kebab `[820,929][955,1064]`
  - Divider entre seções: `[0,1021][967,1156]` (height ~135px) e `[0,1947][967,2082]` antes do CTA rodapé
  - Seção `"Início deste mês"` (header `[45,1158][944,1206]`): 1 linha
    - `[23,1229][944,1364]` — data `"18 de mai."` + nome `"Segunda-Feira"` + kebab
- **Confirmação visual da rota ativa:** o nome da rota ativa é renderizado em **cor primária (azul)** dentro da lista; as outras em branco/cinza. Indicador puramente de cor, sem badge nem ícone à esquerda.
- **CTA "Criar rota":** bounds `[46,2062][921,2197]`, height 135px (~7% da tela), filled-primary, ícone `+` à esquerda do texto.
- **Card de perfil clickable inteiro** (`[46,261][921,441]`) — tap navega pra tela de account (não inspecionada nesta passada). Bounds dos textos: nome `[260,271][668,329]` (height 58 ≈ 18sp), email `[260,329][757,377]` (height 48 ≈ 14sp), plano `[260,383][498,431]`.
- **Avatar do usuário:** bounds `[46,261][226,441]` (180×180px, ~9% da largura). É um ImageView circular (renderizado como View no dump — provavelmente Compose AsyncImage).

**Hierarquia compactada (delta):**
```
nav_host (FrameLayout)
└─ ComposeView
   └─ View (drawer scaffold)
      ├─ View clickable a11y="Fechar menu de navegação" — bounds [967,0][1080,2400]  (scrim)
      └─ View — bounds [0,0][967,2400]  (drawer body, 90% width)
         ├─ Header — bounds [23,103][944,632]
         │  ├─ Help Button [695,103][808,216]
         │  ├─ Settings Button [831,103][944,216]
         │  ├─ User card clickable [46,261][921,441]
         │  └─ Assinar Button [46,469][921,604]
         ├─ Section "Hoje" [45,700][944,748]
         │  ├─ Route row [23,771][944,906] + kebab [820,771][955,906]
         │  └─ Route row [23,929][944,1064] + kebab [820,929][955,1064]
         ├─ Divider [0,1021][967,1156]
         ├─ Section "Início deste mês" [45,1158][944,1206]
         │  └─ Route row [23,1229][944,1364] + kebab
         ├─ Divider [0,1947][967,2082]
         └─ CTA "Criar rota" [46,2062][921,2197]
```

**Implementação RotPro (sugestão):**
- `Scaffold` + `Drawer` (90% width via `Drawer(width: MediaQuery.of(context).size.width * 0.9)`)
- Scrim é automático do Material Drawer
- Body: `Column` com header (user card + Assinar button), `Expanded` com `ListView` agrupado por seção (Hoje / Início deste mês), `Container` fixed-bottom com `FilledButton.icon(Icons.add, "Criar rota")`
- Cor primária pra texto da rota ativa via `selectedItemColor` em RouteListTile
- Help + Settings icons no top-right via `Row` no header (não AppBar, drawer não tem AppBar)

### 10.2 — Popup 3-dot de linha de rota (delta sobre §6.2)

**Confirma §6.2** ("Definir nome e data" / "Duplicar rota" / "Excluir rota"). Deltas observáveis:

- **Tipo:** `PopupMenu` / `DropdownMenu` âncorado, NÃO bottom sheet.
- **Bounds do container:** `[447,895][944,1300]` quando ancorado ao kebab da primeira rota (`[820,771][955,906]`). Anchor right-aligned: popup se abre à esquerda+abaixo do kebab.
- **Width:** 497px (~46% da tela).
- **3 items idênticos em altura (135px cada), sem ícone à esquerda, sem separador, sem cor destrutiva diferenciada pra "Excluir rota"** (não há red foreground).
- **Hierarquia:** ScrollView com 3 View clickable. Cada item: View clickable filho + TextView interno.
- **Fechamento:** tap fora (sem scrim visível, comportamento padrão Material PopupMenu).
- **Confirmação observada:** §6.2 diz "sem confirm dialog observado (verificar com rota não-vazia)". **AINDA NÃO TESTADO** — não tappei "Excluir rota" nesta passada (destrutivo; só temos 3 rotas reais). Gap mantido pra próxima inspeção.

**Implementação RotPro:**
- `PopupMenuButton<RouteAction>` ancorado no kebab Icon, com `PopupMenuItem` por opção.
- Sem `PopupMenuDivider`, sem leading icon, sem `TextStyle(color: Colors.red)` em "Excluir".

### 10.3 — Form "Definir nome e data" (metadata edit — confirma §3.2 item 7b)

> **⚠️ Audit 2026-05-26 — clarificação de naming:** esta seção mapeia **APENAS metadata edit** (nome + data da rota). Spoke tem **2 ações distintas** que ambas usam variantes de "Edit":
> - **"Definir nome e data"** (kebab do drawer §10.2) → ESTA seção §10.3 — só edita metadata, NÃO mexe em stops
> - **"Editar"** (outline CTA do estado ready-to-run §10.12) → abre route builder pra adicionar/remover **stops** (confirmado em docs Spoke: "Edit route button at the top of the panel, which will open the route builder where you can add or remove stops")
>
> Não confundir as duas ações na implementação RotPro — são 2 tela diferentes com semânticas diferentes.

**Acesso:** drawer → 3-dot de qualquer rota → "Definir nome e data" (per §10.2). Open via item topo do popup.

**Estrutura observada (full dump):**

| Elemento | Bounds | Notas |
|---|---|---|
| Topbar | `[0,92][1080,250]` | Background azul-escuro full-width |
| Botão close (X) | `[12,105][147,240]` | a11y `"Voltar"` — RENDERIZADO COMO X, NÃO BACK-ARROW. §6.2 diz "back-arrow no top-left" mas o **edit usa X close** (diferença vs Create) |
| Title text | `[45,295][331,371]` | `"Editar rota"` (não "Criar rota") |
| Label "Nome da rota (opcional)" | `[45,439][455,487]` | Mesma label do create |
| EditText nome | `[79,522][1001,657]` | **Pré-populado com o nome atual** ("terça-feira Rota 2"). Diferença vs create onde é placeholder cinza |
| Container EditText | `[45,510][1035,668]` | clickable wrapper |
| Label "Selecione a data" | `[45,736][327,784]` | Mesma label do create |
| Container radio rows | `[45,807][1035,1191]` | Apenas 2 rows visíveis no scroll inicial: "Hoje" + "Amanhã" (sem "Escolher data" em container separado) |
| Row "Hoje" | `[45,807][1035,965]` | clickable, com calendar icon, texto + data inline `"ter. 26 de mai."`, radio à direita SELECIONADO (azul) |
| Row "Amanhã" | `[45,999][1035,1157]` | clickable, mesma estrutura, radio não-selecionado |
| Row "Escolher data" | `[45,1191][1035,1349]` | container separado abaixo (não dentro do mesmo group), com calendar icon + chevron-right (não radio) |
| CTA primary "Salvar alterações" | `[45,2062][1035,2220]` | **DIFERE do create que é "Confirmar"** |

**Diferenças confirmadas vs Wizard "Criar rota" (§6.2):**
- Topbar usa **X close** (não back-arrow) — divergência com §6.2 que dizia "back-arrow no top-left"
- Title: "Editar rota" vs "Criar rota"
- EditText pré-populado com nome atual vs placeholder auto-gerado
- **Sem "Zona C" (Opções de início rápido / Reutilizar paradas)** — confirmado per §6.2
- CTA label: "Salvar alterações" vs "Confirmar"

**Implementação RotPro:**
- Reuse wizard widget parametrizado por `Route?` (null=create, non-null=edit)
- Conditional: render X-button se `route != null` (back-arrow se null), title via switch, EditText `controller.text = route?.name ?? ""` (sem hint quando edit), Zona C `Visibility(visible: route == null, ...)`, CTA label via switch.

### 10.4 — Tela "Detalhes da rota" (ACHADO NOVO — NÃO está em §6.x)

**🚨 Gap crítico do inventário existente.** Nenhuma das seções §3/§5/§6 mencionou essa tela. Comportamento observado:

**Trigger:** ao tocar em uma **rota com paradas** no drawer pela primeira vez (não toda vez? requer verificação — pode ser comportamento "uma vez por sessão" ou "até salvar como padrão"). O checkbox `"Salvar como padrão"` na parte de baixo da tela (default CHECKED) sugere que após primeira config, próximas entradas pulam esta tela.

**Estrutura completa (full-screen com ScrollView):**

| Elemento | Bounds | Notas |
|---|---|---|
| Topbar com close (X) | `[12,105][147,240]` | a11y `"Voltar"` |
| Title `"Detalhes da rota"` | `[45,295][497,371]` | h1 |
| **Seção "Partida"** (header `[45,439][166,487]`) | | |
| Row "Usar local atual" | `[45,510][1035,668]` | clickable + GPS icon + chevron-right. Acessa picker de starting point |
| Row "Iniciar agora mesmo 18:53" | `[45,702][1035,860]` | clickable + clock icon + time inline + chevron-right. Acessa time picker |
| **Seção "Destino"** (header `[45,928][175,976]`) | | |
| Row "Ida e volta" (subtitle "Viagem de ida e volta a partir do local atual") | `[45,999][1035,1157]` | clickable + return-icon + chevron-right. Acessa destination picker |
| Row "Definir horário de término" (placeholder cinza) | `[45,1191][1035,1349]` | clickable + clock icon + chevron-right |
| **Seção "Pausa"** (header `[45,1417][146,1465]`) | | |
| Row "Adicionar pausa" (placeholder cinza) | `[45,1488][1035,1646]` | clickable + coffee-cup icon + chevron-right |
| **CTA primary "Concluído"** | `[45,1959][1035,2117]` | Filled-primary, full-width, height 158 |
| Checkbox `"Salvar como padrão"` | `[244,2124][794,2259]` | CHECKED by default |

**Implicações pro RotPro:**

1. **Conceito de "configurações da rota" separadas do conteúdo (lista de paradas):** Spoke separa "o que vou entregar" (paradas) de "como vou rodar essa rota hoje" (partida, destino, pausa). RotPro não tem nada equivalente — paradas vão direto pro sheet.
2. **Settings persistidas com "Salvar como padrão":** sugere que os defaults vivem em user prefs (SharedPrefsAsync), e que existe uma forma de re-acessar/editar isso depois (provavelmente via 3-dot kebab da tela ativa — verificar quando chegar na §6.6).
3. **Defaults observados nesta primeira config:**
   - Partida = "Usar local atual" + "Iniciar agora mesmo" (hora atual)
   - Destino = "Ida e volta" (default!), com subtitle explicando
   - Pausa = nenhuma
4. **Slice 2 implication:** essa tela pode ser **DEFERRED** (não bloqueia primeira versão da rota ativa — RotPro pode pular essa config até slice 3+). Ou pode ser **incluída como wizard simplificado** com defaults sensatos. **Decisão pra spec slice 2:** Eduardo + cliente Ueslei devem decidir se replicam essa tela ou se RotPro vai direto pro sheet com paradas (mais alinhado com original RotPro UX).

**Pendente nesta passada:** comportamento das 5 sub-telas que abrem ao tocar nas rows (pickers de partida/destino/pausa) — gap remanescente até slice 2 ou slice 3 decidir replicar ou não esta tela.

### 10.5 — Tela ativa de rota COM 4 paradas reais — sheet **AUTO-EXPANDED** (MEGA achado vs §6.2bis)

> **⚠️ Audit 2026-05-26:** clarificação sobre stack: Spoke usa **Google Maps SDK apenas como base layer de mapa** (TextureView visível no dump); a navegação turn-by-turn default é **Spoke Internal Navigation** (Google-powered mas UI custom), NÃO Google Maps direto. Aplica também a §6.2bis. Implicação RotPro: usar Google Maps puro é caminho diferente da Spoke (não é equivalência 1:1); ou no futuro construir navegação interna similar (out-of-scope M2).

**🚨 §6.2bis estava parcialmente errada.** Quando se entra numa rota com paradas (passando pela §10.4 Detalhes da rota), o sheet abre **AUTO-EXPANDED** (`stepList` rid em y=160-2040), NÃO collapsed. O comportamento de §6.2bis ("collapsed por default com bottom bar de search visível") é o estado da rota **VAZIA** ou de rota que o usuário arrastou pra baixo manualmente. Esta diferença muda a UX implementation.

**Layout observado (sheet expanded com conteúdo):**

```
[0-160]    Status bar (system)
[160-547]  stepListHeader (drag area + bottom bar + título + drag handle)
[160-547]
  [194-329]  Linha superior: hamburger [45,228][113,296] + EditText [260,195][674,330] + OCR + Voice + Kebab
  [363-393]  "4 paradas" (counter, h6)
  [393-528]  "terça-feira" (clickable! provavelmente abre edit)
  [478-613]  Possível drag-handle zone (parte branca observada)
[160-2040] stepList (main scrollable content)
  [544-656]  Section header "Configuração de rota"
  [656-830]  Row "Iniciar no local atual" + subtitle "Use a posição do GPS ao otimizar" + clock-icon-with-time "18:55" + chevron-right (home icon `[967,690][1046,769]`)
  [830-1004] Row "Ida e volta" + subtitle "Retorne ao ponto de partida" + flag icon
  [1004-1178] Row "Sem pausa" + subtitle "Toque para agendar uma pausa" + coffee icon
  [1170-1293] Section header "Paradas"
  [1293-1467] Stop 01 "Rua Franca" + subtitle "Subsetor Leste, 2 (L-2), Ribeirão Preto, 14090-250" + status icon (blue dot)
  [1467-1641] Stop 02 "Rua Iguape" + subtitle "Jardim Paulistano, Ribeirão Preto"
  [1641-1815] Stop 03 "Rua José da Silva" + subtitle "Jardim Paulista, Ribeirão Preto"
  [1815-1989] Stop 04 "Rua Piracicaba" + subtitle "Jardim Paulista, Ribeirão Preto"
[2040-2400] Bottom CTA area
  [2085-2220] CTA primary FULL-WIDTH "Otimizar rota" (com ícone circular-arrows refresh)
[2265-2400] Android nav bar (system)
```

**Map area:** `[0,0][1080,1245]` (TextureView "Mapa do Google") — visible APENAS na parte superior atrás do drag-handle area do sheet. Os 4 markers (`a11y="Marcador do mapa"`) estão nos bounds:
- Marker 1: `[522,798][584,882]` (centro do mapa)
- Marker 2: `[142,633][204,717]`
- Marker 3: `[619,607][681,691]`
- Marker 4: `[876,350][938,434]`

**Bottom bar / topbar do sheet (zona fixa, dentro do `stepListHeader`):**
- Hamburger Menu [45,228][113,296] a11y "Menu" — sempre visível
- Search EditText [260,195][674,330] — placeholder cinza "Toque para adicionar" (truncado)
- OCR button [720,228][788,296] a11y "Ler etiqueta de endereço"
- Voice button [833,228][901,296] a11y "Dite o endereço"
- Kebab [968,228][1036,296] a11y "Menu" (3-dot kebab da rota ativa — abre menu §6.4)

**Stop card structure (each):**
- Número badge à esquerda em fonte tabular: "01" / "02" / "03" / "04" — bounds ~85x48px
- Title "Rua X" (h6, primary text)
- Subtitle endereço completo (body2, muted)
- Status icon à direita: blue filled circle (estado "pending")
- Container clickable inteiro — tap deve abrir detalhe da parada
- Height: ~174px cada

**Configuração de rota — section dentro do sheet:**
Os 3 rows ("Iniciar no local atual", "Ida e volta", "Sem pausa") são **reflexo do que foi configurado em §10.4 Detalhes da rota**. Cada row é clickable e provavelmente re-abre a sub-tela respectiva pra editar.
- Row "Iniciar no local atual" tem **timestamp "18:55"** à esquerda (quando foi setado), home-icon à direita
- Row "Ida e volta" tem **flag icon** à direita (representando destino)
- Row "Sem pausa" tem **coffee-cup icon** à direita

**CTA "Otimizar rota":**
- Bounds `[45,2085][1035,2220]` (FULL WIDTH, height 135px, ~7% da tela)
- Filled primary (azul)
- Ícone circular-arrows à esquerda + label "Otimizar rota"
- **Sempre visível mesmo com sheet expanded** — fica fixo no rodapé.

**Implicações pro RotPro (sliding contextual):**

1. **Sheet auto-expand on enter route with stops:** quando navega pra rota com >0 paradas, sheet deve abrir EXPANDIDO, não collapsed. RotPro atual (`apps/mobile/lib/features/...`) precisa replicar isso.
2. **Section "Configuração de rota" dentro do sheet:** RotPro precisa modelar `RouteConfig` (start, destination, pause) como entidade separada de `Stop`, com UI consistente entre §10.4 (full-screen wizard) e §10.5 (inline rows no sheet).
3. **Sticky bottom CTA "Otimizar rota":** sempre visível, mesmo quando sheet rolando. Implementação: `Stack` com `Positioned(bottom: 0)` ou `Scaffold(bottomNavigationBar:)`.
4. **Counter "N paradas":** aparece no header do sheet, abaixo do bottom-bar.
5. **Stop card clickable inteiro:** sem leading drag-handle visível no estado collapsed (drag pra reorder pode ser long-press? não confirmado nesta passada).

**Gap pendente:**
- Behavior de tap no stop card (abre detalhe? edit?) — próximo
- Long-press em stop card (revela drag-handle reorder?) — próximo
- Swipe horizontal em stop card (delete via swipe?) — próximo
- Comportamento de "terça-feira" (nome da rota clickable no header) — próximo
- Estado do sheet **collapsed** (manual drag pra baixo) com rota cheia — próximo
- Tap no kebab `[968,228][1036,296]` da rota ativa (deveria abrir o menu §6.4) — confirmar

### 10.6 — "Editar parada" (NOVO — não está em §6.x; combina detalhe + edit)

**🚨 §6.3 estava errada.** Inventário existente dizia "Adicionar parada (3 métodos)" mas nada sobre **detalhe/edit de parada existente**. Spoke **NÃO tem tela separada de "detalhe da parada"**; tap no stop card abre direto **"Editar parada"** (mesma tela combina visualização + edição inline). RotPro atual tem `/home/stops/:id` (detail) + `/home/stops/:id/edit` (edit) como rotas separadas — Spoke colapsa as duas.

**Trigger:** tap em qualquer linha de parada no sheet expanded (§10.5).

**Estrutura completa (full-screen ScrollView):**

| Elemento | Bounds | Notas |
|---|---|---|
| Topbar Help (?) | `[1,105][136,240]` | a11y "Ajuda e suporte" — esquerda |
| Title centered | `[402,142][679,200]` | `"Editar parada"` |
| CTA "Concluído" | `[805,104][1035,239]` | TextView clickable PRIMARY (azul) à direita — substitui back-arrow. Save+pop em 1 tap |
| **Linha de status (top do form):** | | |
| Color chip clickable | `[45,267][219,402]` | `"Azul"` — abre picker de cor da parada (provavelmente 5-6 cores pra agrupar visualmente) |
| Status chip clickable | `[242,267][511,402]` | `"Pendente"` — abre picker de status (Pendente/Entregue/Falhou + razão) |
| **Card de endereço (read-mostly):** | | |
| Title h6 | `[45,419][354,495]` | `"Rua Franca"` |
| Subtitle | `[45,495][1035,621]` | Endereço completo `"Subsetor Leste, 2 (L-2), Ribeirão Preto, 14090-250"` |
| Btn "Instruções de acesso" | `[45,638][547,773]` | Outlined-style com + icon, expand-to-add complemento de endereço |
| **Notes section:** | | |
| EditText "Adicionar notas" | `[158,811][877,946]` | Multi-line, ícone notes à esquerda + ícone camera+ à direita (anexar foto) |
| Camera button | `[922,804][1080,962]` | clickable, separado do textfield |
| **Settings rows (lista):** | | |
| Row "Localizador de pacotes" | `[0,996][1080,1132]` | Valor "Não definido" à direita — abre picker |
| Row "Pacotes" (counter) | `[0,1132][1080,1268]` | **Stepper** com — / 1 / + (default 1). Layout: label esquerda, stepper direita |
| Row "Ordem" (segmented) | `[0,1268][1080,1404]` | **3-button segmented control:** "Primeira" / **"Automática"** (selected, azul) / "Última". Bounds dos segments: `[401,1269][607,1404]`, `[618,1269][840,1404]`, `[852,1269][1025,1404]` |
| Row "Tipo" (segmented) | `[0,1404][1080,1540]` | **2-button segmented control:** **"Entrega"** (selected, azul) / "Coleta". Bounds: `[544,1405][790,1540]`, `[801,1405][1024,1540]` |
| Row "Horário de chegada" | `[0,1540][1080,1676]` | Valor "Qualquer momento" à direita — abre time picker |
| Row "Tempo estimado na parada" | `[0,1676][1080,1812]` | Valor "Padrão (1 min)" à direita — abre picker. **NOTA:** o default vem do setting global "Tempo médio na parada" (§3.3 item 16) |
| **Bottom actions list (destrutivas):** | | |
| Row "Mudar endereço" | `[0,1864][1080,1999]` | Search-icon + chevron right — abre re-geocode flow |
| Row "Duplicar parada" | `[0,2011][1080,2146]` | Plus-icon + chevron right |
| Row "Remover parada" | `[0,2158][1080,2293]` | Trash-icon + **TEXTO VERMELHO** (única ação destrutiva com cor) + chevron right. **Confirma:** Spoke usa cor pra destrutivo aqui, não no popup §10.2 |

**Implicações pro RotPro:**

1. **Tela única "Editar parada"** — RotPro atual divide `/home/stops/:id` (detail) + `/home/stops/:id/edit` (edit). Pro white-label, colapsar em uma só.
2. **Status workflow inline:** "Pendente" / "Entregue" / "Falhou" é um chip clickable no topo da tela, NÃO bottom CTA. Quando usuário marca "Entregue" ou "Falhou", esta MESMA tela cuida do status update — não há tela separada de "confirmação de entrega" (provavelmente abre sheet com motivo no caso "Falhou").
3. **Color tagging:** Spoke permite atribuir cor por parada (azul, verde, etc.) — pra agrupar visualmente no mapa. Feature nova pra RotPro.
4. **Segmented controls** pra Ordem (Primeira/Auto/Última) e Tipo (Entrega/Coleta) — Spoke prefere segmented sobre dropdown/radio quando há ≤3 opções.
5. **Stepper widget** pra contagem de pacotes — não TextField.
6. **Save semantics:** CTA "Concluído" no topo direito (não bottom CTA). É TextView clickable, estilo iOS-ish. RotPro pode usar `TextButton("Salvar")` no AppBar actions.
7. **Tempo estimado por parada:** lê do setting global como default, override por parada. Modela como `int? customStopDurationMin` em `Stop`, fallback pro setting.
8. **Mudar endereço:** ação separada — não é só editar text field. Provavelmente re-abre geocoding/picker pra escolher novo lat/lng. Implementação: navega pro mesmo flow de §6.3 (Adicionar parada) em modo "replace existing".

**Hierarquia compactada:**
```
ScrollView [0,250][1080,2265]
└─ View
   ├─ Status row [267-402]
   │  ├─ Color chip "Azul" [45-219]
   │  └─ Status chip "Pendente" [242-511]
   ├─ Address card [419-773]
   │  ├─ Title "Rua Franca" [419-495]
   │  ├─ Subtitle "Subsetor Leste..." [495-621]
   │  └─ Btn "Instruções de acesso" [638-773]
   ├─ Notes [804-962] (EditText + camera button)
   ├─ Settings rows [996-1812] (6 rows)
   └─ Actions rows [1858-2265] (3 rows: Mudar / Duplicar / Remover [RED])
```

**Pendente nesta passada:**
- Tap em "Cor: Azul" chip — abre picker de cores (provavelmente 5-6 cores pra agrupar visualmente)
- Tap em "Instruções de acesso" — abre input multi-line de complemento?
- Tap em "Remover parada" — abre confirm dialog ou remove imediato? (destrutivo; pular nesta passada)
- Tap em "Mudar endereço" — re-abre fluxo de adicionar?

### 10.6.1 — 🚨 CORREÇÃO crítica: chips de topo NÃO são status de entrega

**Investigação inline 2026-05-26 com Eduardo:** tap em ambos os chips de topo NÃO abre picker de status de entrega como inicialmente assumi. Comportamento observado:

- **Chip 1 "● Azul"** — color tag picker (cor visual pra agrupar paradas no mapa)
- **Chip 2 "ID Pendente"** — abre a tela Help/Setting **"Formato do ID de parada"** (mesma tela que existe no Settings global per §3.3 item 19). O label "Pendente" aqui significa **"esta parada ainda não tem ID numérico atribuído"**, NÃO status de entrega "pendente".

A tela aberta tem:
- Título "Formato do ID de parada" + visual preview (3 caixas A1/A2/A3 conectadas por linha de rota + números 1/2/3)
- 2 radio groups:
  - **"Formato do ID de parada":** Moderno (selected, com badge formato A1/A2/A3) | Clássico
  - **"Atribuir IDs às paradas":** Depois da otimização da rota (selected) | Conforme as paradas são adicionadas
- Texto explicativo: "O formato moderno ajuda você a não confundir o número da parada com o ID da parada" + "Os IDs são atribuídos às paradas depois da otimização e da confirmação da rota."

**Implicação crítica pro RotPro:**
1. **STATUS de entrega (Pendente/Entregue/Falhou) NÃO vive em "Editar parada"** — deve estar em outro lugar do app, provavelmente:
   - Como ação direta na lista de paradas do sheet (long-press? swipe? botão dedicado?)
   - Em tela de "Navegação ativa" / "Marcar entregue" que ainda não inspecionamos
   - Em modal/sheet específico durante o flow de delivery
2. **Conceito "ID da parada" é diferente de "número da parada":**
   - **Número** (#1, #2...): ordem visual na lista, sempre sequencial
   - **ID** (A1, A2... no formato Moderno OU 1, 2... no Clássico): identificador único que respeita ordem de otimização, usado para etiquetar pacotes físicos no carregamento do veículo
   - Spoke tem essa distinção pra ajudar entregador a pegar pacotes na ordem certa após otimização
3. **Gap remanescente CRÍTICO:** mapear onde fica o controle de status de entrega. Próximo passo: voltar pro sheet, dar long-press num stop card pra ver se aparece reorder OU swipe horizontal pra ver se aparece "Marcar entregue".

**Para o RotPro:** modela `Stop` com 3 campos separados:
- `int positionInRoute` (ordem visual, 1..N, sempre sequencial)
- `String? deliveryId` (formato "A1" Moderno ou "1" Clássico, atribuído pós-otimização, nullable até `route.optimizedAt != null`)
- `StopDeliveryStatus status` (**pending | delivered | failed | pickedUp** — ver §10.6.2 abaixo, "Picked up" é status terceiro confirmado em docs Spoke), com `failureReason: String?` opcional

### 10.6.2 — Cross-reference docs oficiais Spoke (best practice: docs > inferência)

**Fonte:** WebSearch + WebFetch em sites oficiais ([spoke.com/route-planner](https://spoke.com/route-planner), [help.spoke.com](https://help.spoke.com), [screensdesign.com showcase](https://screensdesign.com/showcase/circuit-route-planner), Google Play / App Store listings). help.spoke.com bloqueou WebFetch (403), mas snippets agregados via search engines deram cobertura suficiente.

#### Confirmações que resolvem ambiguidades anteriores

1. **Status de entrega tem TRÊS estados (não dois):** Spoke confirma `Delivered`, `Failed`, **`Picked up`** (este último crítico — não tínhamos mapeado). Aplicação no RotPro: enum `StopDeliveryStatus { pending, delivered, failed, pickedUp }`. Slice 2 implementa os 4; slice 3 backend persiste timestamps `deliveredAt` / `failedAt` / `pickedUpAt` (nullable).

2. **Localização do controle de status:** docs dizem "When you arrive at the stop, you mark the stop as Delivered/Failed" + "Add, remove, or reorder stops in real time, even while on the road, with hands-free voice input". Implicação: existe **uma tela/fluxo "navegação ativa"** dedicada que mostra controles de status. **Gap:** ainda não inspecionado. Próximo passo Maestro: tap em uma parada da lista no sheet (não no card inteiro como tentei, mas via **long-press OU swipe horizontal**) pra revelar status actions, OU verificar se há um botão "Iniciar rota" / "Start route" que entra em modo navegação.

3. **Failure reasons:** ⚠️ Audit 2026-05-26 — **revisado:** quote "pre-set list + custom" veio de docs Spoke genéricas que provavelmente referenciam **Spoke Dispatch** (produto B2B pra equipes/dispatchers), NÃO **Spoke Route Planner** (B2C que Eduardo usa). Observação empírica em §10.14 mostra que Route Planner marca Failed silenciosamente sem picker. **Confirmado pra RotPro slice 2: NÃO implementar picker de razão.** Slice 3+ backend pode armazenar `failureReason: String?` (nullable, opcional) editável retroativamente via "Editar parada" se cliente quiser. Lista hardcoded inferida pra futuro: "Cliente ausente", "Endereço incorreto", "Endereço não encontrado", "Recusou entrega", "Cancelado por dispatcher" — todas inferências, NÃO observadas in-app.

4. **Package ID confirmado:** quote oficial — "Package ID" allows "unique ID to each stop" for "destination matching" no carregamento do veículo. **Confirma minha hipótese §10.6.1.** Formato Moderno (A1/A2/A3) vs Clássico (1/2/3) é só preferência visual; conceito é o mesmo. Atribuído **POST-optimization** ("após otimização e confirmação da rota" per texto inline na própria tela).

5. **Color labels:** confirmado uso oficial — "visually group or prioritize parts of a long route list". Lista completa de cores NÃO documentada oficialmente. Capturado parcial via Maestro: **Azul, Verde-azulado, Roxo, Rosa, Laranja** (5 cores observadas; pode haver mais abaixo no scroll do picker — picker fechou antes de eu completar). RotPro slice 2: começar com essas 5 + scroll picker; ampliar se observação direta revelar mais.

6. **"Load vehicle" feature:** docs mencionam recurso de **"map packages to specific vehicle locations"** — usuário marca onde fisicamente o pacote está no carro (frente, atrás, esquerda, etc.) pra facilitar acesso quando chegar no stop. Este é o conteúdo provável do campo **"Localizador de pacotes"** em §10.6 (que mostra "Não definido" por default). **Gap pendente:** inspecionar tap em "Localizador de pacotes" pra ver UI de location picker. Pode ser uma grade visual representando o veículo.

7. **Plan / Paywall:** ⚠️ Audit 2026-05-26 — pricing tiers REAIS da Spoke (corrigido): **Free** (10 stops/route, unlimited features) < **Lite** (unlimited stops, limited features) < **Standard** ($20/mês, unlimited tudo). NÃO é "single monthly plan" — são 3 tiers. **RotPro NÃO replica tiers Spoke** — modelo já fechado com cliente há muito tempo per [ADR-0030](../decisions/0030-stripe-pix-30-day-access-pass.md) + [`docs/BUSINESS-RULES.md`](../BUSINESS-RULES.md): **acesso único pago de R$ 25,90 / 30 dias via Stripe Pix**. Trigger do paywall = tap em **"Iniciar Navegação"** (BUSINESS-RULES §5 — após otimizar rota; otimização é gratuita pra usuário ver valor antes de pagar). Sem free trial, sem free tier limitado, sem subscription recorrente. Distribuição: APK-only per [ADR-0014](../decisions/0014-apk-distribution.md) (sem Play Store no M2 = sem Google Play Billing forçado).

#### Mudança de prática operacional (aplica a toda Fase B daqui pra frente)

**Boa prática modernísima implementada agora (per Eduardo, 2026-05-26):**

> Quando o agente encontrar comportamento ambíguo ou inesperado no Spoke (ex: tap abre tela inesperada, label parece ter dupla função, picker tem opções não-óbvias), **PRIMEIRO consultar docs oficiais** (`spoke.com`, `help.spoke.com`, `getcircuit.com`, App Store / Play Store listings, blog) via WebSearch/WebFetch. **DEPOIS** voltar pra Maestro pra validar empiricamente o entendimento construído pelos docs. Isso evita gastar ciclos tentando inferir comportamento via dump XML.

**Hard rule:** ADR-0010 boundary permanece — docs oficiais são consultados pra **entender funcionalidade**, não pra copiar microcopy. Qualquer copy citada nos docs Spoke entra no inventário como **paraphrase neutra** (mesma regra do dump XML).

A próxima iteração do `spoke-parity-checker` subagent prompt deve codificar essa regra no Step 4 (Compare). Adicionar como TODO em ADR-0037 amendment se a Fase B continuar mostrando valor.

### 10.7 — Stop card: long-press + swipe NEGATIVOS (gap fechado)

Testes empíricos executados via Maestro MCP em 2026-05-26 (commit `00b99f9` adiante):
- `longPressOn` em centro do stop card 01 → **NADA acontece.** Sem context menu, sem reorder handle revelado, sem actions ocultas.
- `swipe right` (start `200,1180` end `880,1180`) → **NADA acontece.** Card fica imóvel; UI inalterada.
- `swipe left` (start `880,1180` end `200,1180`) → **NADA acontece.** Mesmo resultado.

**Conclusão definitiva:** Spoke **NÃO usa swipe-to-action nem long-press no stop card do sheet expanded**. **Tap único é a única gesture suportada**, e ela navega pra "Editar parada" (§10.6). Implicação: o **controle de status de entrega** está em **outro estado da app** — confirmado adiante na §10.8 (estado pós-otimização) e §10.9 (modo run/delivery, ainda a inspecionar).

### 10.8 — Modal FTUE "IDs ajustados conforme a ordem de rota" (first-time use)

**🚨 Tela nova não mapeada antes.** Trigger: tap em CTA "Otimizar rota" do sheet (§10.5) **pela primeira vez na conta**. Provavelmente skipável após primeira vez (FTUE).

**Estrutura observada:**

| Elemento | Bounds | Notas |
|---|---|---|
| Modal container (full-screen overlay sobre mapa) | `[0,92][1080,2265]` | Dim background, modal centered |
| Hero illustration (3 cartões ID A1/A2/A3 com setas curvas) | `[143,372][937,828]` | Imagem decorativa demonstrando reordering |
| Title h4 | `[113,974][967,1124]` | `"IDs ajustados conforme a ordem de rota"` |
| Body text 2-paragraph | `[113,1169][967,1635]` | Explica que IDs mudam durante planejamento + ficam permanentes pós-confirmação. ~3 linhas cada parágrafo |
| CTA primary "Entendi" | `[113,1703][967,1838]` | Filled blue, height 135 |
| CTA secondary "Configurar..." | `[113,1861][967,1996]` | Text-style, mesma altura, abre setting de ID format (§3.3 item 19) |

**Implicação pro RotPro:** se replicarmos, modal FTUE precisa de flag `bool hasSeenOptimizeFtue` em SharedPrefsAsync; mostrar uma vez por conta. Slice 2: deferred (não bloqueia funcionalidade); slice 3+: implementar.

### 10.9 — Estado pós-otimização (PRE-CONFIRM) — 🚨 ENTERAMENTE NOVO

**Trigger:** tap "Entendi" no modal §10.8 (ou no fluxo subsequente após primeira-vez).

**🚨 Estado é estruturalmente MUITO diferente do pré-otimização (§10.5).** Mudanças observáveis:

#### Mudanças no MAPA
- Mapa **agora ocupa metade superior da tela** (não só topo-strip atrás do sheet)
- **Rota azul desenhada** conectando os 4 markers (Google Directions polyline)
- **Markers numerados 1/2/3/4** (não mais "Marcador do mapa" genérico)
- Mapa **centralizou + auto-zoom** na bounding box da rota
- **Floating button NOVO** no canto direito do mapa (provavelmente "fullscreen toggle" — ícone que parece mapa aberto)
- Layer toggle continua

#### Mudanças no SHEET
- Sheet posição: mid (não full-expanded, não collapsed)
- **NOVA linha summary acima do título:** `"14 min • 4 paradas • 3,3 km"` (tempo total + N paradas + distância total)
- Section "Configuração de rota" **REDUZIDA:** "Iniciar no local atual" + "Ida e volta" foram **fundidos numa única row "Ponto de partida"** com subtitle "Posição do GPS usada ao otimizar" + timestamp "19:16" + home icon. "Sem pausa" continua como linha separada.
- Section "Paradas" agora lista stops na **ORDEM OTIMIZADA** (Rua José da Silva agora é #01, antes era Rua Franca). Cada stop ganhou **chip "A1" / "A2" / "A3" / "A4"** à direita (formato Moderno do package ID).

#### NOVOS CTAs no rodapé (3 elementos em row, NÃO mais 1 CTA full-width)
| Elemento | Estilo | Função inferida |
|---|---|---|
| **"14min"** | TextView verde, font grande | Indicador visual de tempo total (não-clickable? tap revela detalhes?) |
| **"Refinar"** | Text/outline button | Re-roda otimização (talvez com opções pra ajustar configurações) |
| **"Confirmar"** | Filled primary, blue | Lock-in IDs + transita pra modo "running route" / "delivery mode" |

**Implicações enormes pro RotPro:**
1. **Estado "Pre-confirm post-optimize"** é uma fase distinta da rota com UI dedicada. Modela como `RouteStatus { draft, optimizing, optimized_uncommitted, running, completed }`.
2. **3 CTAs especializados** substituem o único "Otimizar rota" do estado draft.
3. **Totals (tempo + paradas + km)** vêm do solver backend e devem ser persistidas no Route.
4. **Package IDs (A1..AN)** ficam visíveis no chip à direita de cada stop card.
5. **Configuração de rota "colapsada"** sugere que pós-otimização a UI simplifica detalhes (já foram aplicados na otimização).
6. **Tap "Confirmar"** é o gateway pro modo de delivery (onde provavelmente está finalmente o controle de status — vamos validar §10.10).

**Pendente:**
- Tap "Refinar" — que opções abrem? (gap; pode ser inspecionado depois)
- Tap "14min" (text verde) — clickable? Abre breakdown?
- Tap "Confirmar" — destino próxima inspeção (§10.10)

### 10.10 — Modal FTUE "Os IDs serão definitivos" (confirm lock dialog)

**Trigger:** tap em CTA "Confirmar" do estado pós-optimize (§10.9) **pela primeira vez na conta**.

**Estrutura:**
- Hero illustration: cadeado + 3 ID badges (A1, K8, D6) — IDs misturados sugerindo que após confirm, IDs originais ficam mesmo se novas paradas forem adicionadas com IDs diferentes
- Title: `"Os IDs serão definitivos"`
- Body text: explica que após confirmação, IDs não mudam mais mesmo com alterações
- CTA primary: **"Continuar"** (filled blue)
- CTA secondary: **"Cancelar"** (text style)

**Implicação:** Confirmar é uma ação **semi-destrutiva** (não destrutiva mas irreversível em uma dimensão). Models deve ter `Route.confirmedAt: DateTime?` — antes nulo, depois fixo no momento do confirm.

### 10.11 — Modal FTUE "Tudo pronto para carregar o veículo?" (load vehicle FTUE)

**Trigger:** tap "Continuar" no dialog §10.10.

**Conteúdo:**
- Title: `"Tudo pronto para carregar o veículo?"`
- Body: explica que Spoke ajuda a carregar o veículo organizando pacotes por ordem de entrega
- CTA primary: **"Continuar"** (filled blue) — abre flow Load vehicle (§10.6 "Localizador de pacotes" referencia esta feature; full flow não inspecionado)
- CTA secondary: **"Pular"** (text style, blue) — skipa Load vehicle e vai direto pro estado ready-to-run

**Implicação:** Load vehicle é feature **opt-in por rota**, com FTUE perguntando se quer usar. Pra RotPro slice 2: feature OUT-OF-SCOPE (complexidade desnecessária pra MVP); slice 3+: implementar depois de ter Stop + Package model robustos.

### 10.12 — Estado "Ready-to-Run" (pós-confirm + skip Load vehicle)

**Trigger:** tap "Pular" no FTUE §10.11.

**Diferenças vs §10.9 (pre-confirm post-optimize):**
- Sheet ganha **2 botões em row** logo abaixo do título da rota:
  - **`⫷ "Compartilhar rota em tempo real"`** (share icon + label, outline button) — funcionalidade nova: live tracking pra cliente acompanhar entrega
  - **`🚛 "Carregar veí..."`** (truck icon + label truncado "veículo", outline button) — re-entry pro Load vehicle flow se usuário pulou no FTUE
- CTAs bottom mudam:
  - **"14min"** verde (mantém)
  - **"Editar"** (outline) — substitui "Refinar"; permite editar rota mesmo pós-confirm. ⚠️ Audit 2026-05-26: este "Editar" abre o **route builder pra add/remove stops** (confirmado em docs Spoke), DIFERENTE do "Definir nome e data" do kebab do drawer (§10.3) que só edita metadata
  - **"Iniciar rota"** (filled primary blue) — substitui "Confirmar"; **GATEWAY pro modo delivery onde status actions vivem**

**Bounds da linha de 2 botões action:** aproximadamente `y=[1310, 1410]` (preciso novo inspect pra bounds exatos quando voltar).

**Implicação enorme:** O **"Ready-to-Run state"** é uma fase distinta de `RouteStatus { confirmed_not_started }`. Tem ações específicas (Compartilhar tempo real + Carregar veículo + Editar + Iniciar) que ainda mantêm a rota editável.

**Pendente:**
- Tap "Compartilhar rota em tempo real" — abre share sheet? Cria link público? (próxima)
- Tap "Carregar veículo" — abre flow Load vehicle (provavelmente uma tela visual de car layout + drag pacotes)
- Tap "Iniciar rota" — **GATEWAY** pra modo delivery (§10.13)

### 10.13 — 🎯 MODO DELIVERY (Running route) — onde finalmente vivem os status actions

**Trigger:** tap "Iniciar rota" no estado Ready-to-Run §10.12.

**🚨 ESTRUTURA FUNDAMENTALMENTE DIFERENTE:** modo delivery foca em UMA parada por vez (a atual/próxima), com 3 botões de ação primários grandes.

#### Estrutura observada (sheet posicionado mid-screen):

| Elemento | Bounds | Notas |
|---|---|---|
| Mapa (top metade) | `[0,0][1080,1248]` | Centrado na parada atual + polyline azul do trajeto |
| Markers no mapa | varia | Apenas 2 visíveis: parada atual (#1 azul) + "🏁 19:36" (target finish time) — outras paradas ficam fora do viewport por zoom |
| Hamburger | `[79,171][147,239]` | a11y "Menu" — abre drawer |
| ETA finish badge top-right | `[820,138][1069,273]` | TextView `"19:36"` + flag-finish icon |
| Floating "Alternar para o mapa" | `[923,1046][1013,1136]` | Recenter button (mantém) |
| Floating "Alternar modo de mapa" | `[934,889][1002,957]` | Layer toggle (mantém) |
| **Sheet topbar:** | | |
| Title `Rua José da Silva` (parada atual) | `[45,1250][651,1347]` | h1 big text |
| X close `[944,1247][1035,1349]` | a11y `"Fechar"` | Sai do modo delivery — provavelmente confirm dialog antes |
| Subtitle `"1/4, 19:22"` | `[101,1366][278,1422]` | Progress (1 de 4 entregues) + horário atual (~ETA na parada) |
| **🎯 3 botões de status (CRÍTICO — o que docs Spoke mencionaram):** | | |
| **"Navegar"** | `[45,1451][352,1618]` | Filled primary BLUE (selected default). Compass icon. Tap → abre handoff Waze/Google Maps (per ADR-0010 default Google Maps) |
| **"Não entregue"** | `[375,1451][693,1618]` | Outline button. Box-X icon. Tap → abre picker de razão de falha (§10.14 pendente) |
| **"Entregue"** | `[716,1451][1035,1618]` | Outline button. Box-check icon. Tap → marca como Delivered |
| **Lista inline de info:** | | |
| Row "Adicionar notas" | `[0,1650][1080,1775]` | clickable, note icon left, chevron right |
| Row endereço "Jardim Paulista, Ribeirão Preto" | `[0,1775][1080,1900]` | clickable, map icon left, chevron right — abre? |
| Row **`"A1 Originally 1st"`** | `[0,1900][1080,2035]` | clickable, ID badge "A1" + label `"Originally 1st"` — mostra ID atribuído + posição original pré-otimização. Tap abre help "Formato do ID de parada" (§10.6.1) |
| Row "Editar parada" | `[0,2070][1080,2205]` | clickable, pencil icon, chevron right — abre §10.6 |
| Row "Duplicar parada" | `[0,2217][1080,2352]` | clickable, plus-icon, chevron right |
| (scrolled out) | | Provavelmente "Remover parada" abaixo |

#### Observações estruturais críticas

1. **Status NÃO é destructive-styled.** Mesmo "Não entregue" usa outline normal (não vermelho). Isso é diferente do "Remover parada" em §10.6 que tem texto vermelho.
2. **"Navegar" é o status default (selected primary)** — Spoke assume que o flow normal é "ir pra parada → marcar status". Faz sentido UX.
3. **Subtitle "1/4, 19:22"** é information-dense: posição + horário (não tem hora ETA — assume usuário olha o badge top-right "19:36" pra ETA total).
4. **Sem botão "Picked up" visível.** Hipótese confirmada: appears only quando `Stop.tipo == Coleta`. Esta parada (Rua José da Silva) é `Tipo: Entrega` (default), então só vê Entregue/Não entregue.
5. **ID badge "A1" inline no sheet** — confirma que Package IDs ficam visíveis em todo lugar pós-otimização.
6. **Hamburger ainda visível** — usuário pode abrir drawer mid-delivery (acessar outras rotas, settings).

#### Implicação pro RotPro (slice 2 + slice 3)

```dart
enum StopDeliveryStatus { pending, delivered, failed, pickedUp }
enum StopType { delivery, pickup }
// Picked up button só renderiza se stop.type == StopType.pickup
// Entregue/Delivered button só renderiza se stop.type == StopType.delivery
// Navegar SEMPRE renderiza
```

**Arquitetura sugerida:**
- `DeliveryModePage` (novo, slice 2): Scaffold + GoogleMap top + DraggableScrollableSheet bottom
- Sheet content é `StatefulConsumerWidget` que mostra `currentStop` (computed from `route.stops.firstWhere(s => s.status == pending)`)
- 3 botões em `Row` com `OutlinedButton`/`FilledButton`
- "Navegar" usa `url_launcher` com `geo:` intent → abre Waze/Google Maps conforme setting
- "Entregue" pop a confirmation dialog opcional, marca status, advances to next pending stop
- "Não entregue" abre **bottom sheet picker** (§10.14) com lista de razões + OUTRO/Custom

**Pendente nesta seção:**
- ~~Tap "Não entregue" → capturar picker de razões (§10.14)~~ **TESTADO em §10.14**
- Tap "Navegar" → confirmar que abre Google Maps default + observar deeplink format
- Tap "Entregue" → observar se há confirmation, observar transição pra próximo stop
- Long-press em alguma row pra ver gestos
- Tap "Adicionar notas" → confirmar é text field
- Tap X close → sair do modo delivery (confirm dialog?)

### 10.14 — 🚨 SURPRESA: "Não entregue" SEM picker de razão (divergência vs docs Spoke)

**Observação empírica 2026-05-26 (via Maestro):** tap em "Não entregue" do modo delivery (§10.13) **NÃO abre picker de razão**. Comportamento real:
- Stop atual ("Rua José da Silva", A1) marcado como Failed silenciosamente
- Sheet auto-advances pra próxima parada pending ("Rua Piracicaba", A2)
- Title atualiza pra novo stop + subtitle agora `"2/4, 19:27"` (progress 2 de 4)
- Mapa recentra na nova parada atual + zoom adequado
- ID badge mostra "A2 Originally 2nd"
- ETA finish badge atualiza de "19:36" pra "19:37" (provavelmente porque rota agora pula um stop)
- **Marker "1x" aparece no canto-esquerdo do mapa** — possivelmente indicador visual de "1 parada falhada" (não confirmado, requer zoom maior)

**Divergência crítica vs documentação oficial Spoke:** docs explícitos ("você pode adicionar uma razão de uma lista pré-definida ou customizada") sugerem picker. **NÃO observado in-the-wild.** Possíveis explicações:

1. **Razão é opcional + setado em outra UI:** usuário marca Failed → vai pra próxima → pode voltar via histórico e adicionar razão depois via "Editar parada" §10.6. (Razão = campo opcional persistido).
2. **Feature flag por conta:** alguns usuários têm picker enabled (talvez plano pago Spoke, ou setting opt-in não default).
3. **Setting global "Pedir razão ao marcar falha":** toggle não encontrado ainda em §3.3 settings, mas pode existir e estar OFF na conta do Eduardo.
4. **Razão é capturada via "Adicionar notas":** o campo notes seria onde razão fica registrada (mesma UI, não dedicada).

**Implicação pro RotPro:** **NÃO replicar picker de razão como default** — replicar comportamento observado (mark Failed silently + advance). Considerar adicionar setting "Pedir motivo ao marcar falha" no Settings RotPro pra futura paridade, mas **slice 2 pode shippar sem picker**. Slice 3+: backend persiste `failureReason: String?` (nullable, opcional, editável via Editar parada).

**🎯 BOA PRÁTICA APRENDIDA:** Docs oficiais podem refletir features de plano premium ou de regiões diferentes. **Observação empírica via Maestro tem precedência sobre docs quando diferem.** Atualizar ADR-0037 com nota sobre esse princípio no B.13.

### 10.15 — Marker visual encoding (mapa, modo delivery)

**Observado empiricamente em §10.13 → §10.14 → §10.15:**

| Status | Marker visual no mapa | Observado em |
|---|---|---|
| Pending (nunca tocado) | `N` (número simples, azul) | §10.13 marker #1 |
| **Failed (Não entregue)** | `Nx` (número + X) — fundo escuro | §10.14 marker "1x" |
| **Delivered (Entregue)** | `N✓` (número + check) — cor diferenciada | §10.15 marker "2✓" |
| Current (active stop) | Marker maior/destacado + flag-finish nearby | §10.13 marker #1 grande + flag |

**Implicação pro RotPro:**
- `google_maps_flutter`: customizar `Marker.icon` por status usando `BitmapDescriptor.fromBytes` com SVG render dinâmico
- Cores: pending = primary blue, delivered = green, failed = grey/dark, current = primary blue maior
- Numbering: usar `route.stops.indexOf(stop) + 1` (position in optimized order)

### 10.16 — Comportamento "Entregue" (símétrico ao "Não entregue")

**Tap "Entregue" também NÃO abre confirmation dialog** — marca silenciosamente + avança.

**Sequência observada (entre §10.13 e §10.15):**
1. tap "Não entregue" em stop 1 → mark Failed, advance pra stop 2
2. tap "Entregue" em stop 2 → mark Delivered, advance pra stop 3
3. Title sheet atualiza imediatamente
4. Subtitle progress atualiza ("1/4" → "2/4" → "3/4")
5. Mapa recentra + zoom auto na nova parada current
6. Markers no mapa ganham seu indicator visual (`x` ou `✓`)
7. ETA finish badge top-right atualiza (recalculado com base no que falta)

**Observação UX importante:** **zero fricção** entre marcar e próxima parada. Spoke prioriza velocidade pro motoboy (1 tap = action + advance). Pra RotPro slice 2: **respeitar essa velocidade** — sem dialogs, sem confirmações, sem snackbars bloqueantes. Status update é optimistic UI; rollback se backend falhar.

**Pendente:**
- Tap "Entregue" mais 2 vezes → completar rota → capturar tela "rota concluída" (§10.17 esperada)
- Após rota concluída, voltar drawer e verificar como rota aparece no histórico (nome diferente? badge?)

### 10.17 — Estado "Destino final" (Ida e volta retorno)

**Observado:** após marcar todas as 4 paradas (1 Failed + 3 Delivered + 1 implicitly skipped pela Failed), Spoke transita para "destino final" da Ida e volta config (§10.4).

**Estrutura:**
- Title h1: endereço completo do ponto de partida (no caso, `"R. José da Silva, 713 Jardim Paulista"`)
- Subtitle: `"Destino, 19:30"` (label "Destino" + ETA pra chegar de volta)
- **APENAS 2 botões (não 3):**
  - **"Navegar"** (filled primary) — abre Google Maps/Waze pra retorno
  - **"Rota concluída"** (outline com check-icon) — finaliza a rota inteira
- Lista inline reduzida:
  - Row CEP `"14090-042"` + map icon (não tem mais título/endereço duplicado)
  - Row `"Editar destino"` (clickable — provavelmente abre re-geocode)

**Por que apenas 2 botões:** "destino final" não é uma parada de entrega — é simplesmente o ponto de retorno. Não há "Entregue/Não entregue" porque não há nada pra entregar lá. Apenas "Navegar" (chegar) ou "Rota concluída" (skip retorno e fechar rota).

### 10.18 — Tela "Rota concluída!" (route completion summary)

**Trigger:** tap "Rota concluída" em §10.17 (ou após o último delivered se config era one-way, sem Ida e volta).

**Estrutura observada:**

| Elemento | Bounds | Notas |
|---|---|---|
| Mapa top | `[0,0][1080,1245]` | 4 markers visíveis com status finais visuais (1×, 2✓, 3✓, 4✓) — todos congelados em estado final |
| Hamburger Menu | `[79,171][147,239]` | Continua acessível |
| Sheet topbar | `[0,1222][1080,1358]` | |
| Summary text | `[45,1255][776,1303]` | `"Término: 19:28 • 0 parada • 0 m"` (tempo final + 0 paradas pendentes + 0m restantes) |
| Add/search button | `[810,1222][923,1335]` | a11y `"Adicionar ou buscar paradas"` — permite reabrir rota e adicionar mais paradas |
| Kebab `[968,1245][1036,1313]` | a11y `"Menu"` | Provavelmente abre menu §6.4 + "Exportar / Compartilhar resumo" novo |
| **Lista de stops com timestamps de conclusão:** | | |
| Row 1 (Jardim Paulistano, "19:27") | `[0,1133][1080,1222]` | Não-current stop (Iguape entregue 19:27) |
| Row 2 ("Última" chip + Subsetor Leste, "19:27") | `[0,1358][1080,1512]` | Stop final entregue, com chip "Última" |
| Row 3 ("R. José da Silva 713", "19:28") | `[0,1512][1080,1686]` | Destino final retorno, com flag-end icon |
| **Card central "Rota concluída!":** | `[45,1731][1035,2149]` | |
| Check verde icon | `[473,1777][608,1900]` | Confirmation visual |
| Title `"Rota concluída!"` h2 | `[90,1900][990,1969]` | |
| Subtitle stats `"4 paradas"` `1 perdida"` | `[191,2052]` + `[833,2052]` | 2 colunas: contagem total + falhas |
| CTA "Copiar paradas para uma nova rota" | `[45,2194][1035,2329]` | Filled primary or outline — permite criar nova rota com mesmas paradas |

**Implicação pro RotPro:**
1. **Modelo `Route` precisa de campos:** `completedAt: DateTime?`, `totalStops: int`, `failedStops: int`, `durationMinutes: int` (computed do diff de timestamps)
2. **Telemetria/stats:** Spoke conta apenas paradas Failed ("1 perdida"), não pickedUp. Validar comportamento com stops `type: pickup` posteriormente.
3. **"Copiar paradas para uma nova rota"** é wizard que pula direto pro flow "Reutilizar paradas" §3.2 com checkbox marcado por default. Implementação RotPro: re-use o wizard existente parametrizando o source route.
4. **Markers congelados:** após rota concluída, markers no mapa mantêm status final (não voltam pra pending). Implementação: persistir status no `Stop` model + render conditional do marker icon.
5. **Sheet topbar mantém add/search:** indicação que rota concluída pode ser **REABERTA** adicionando nova parada. RotPro: confirmar comportamento de uma rota "complete" voltar pra "running" mediante adição.

**Pendente:**
- Tap kebab da rota concluída pra ver opções (exportar? deletar? compartilhar resumo?)
- Tap "Copiar paradas para uma nova rota" — confirma flow
- Abrir drawer e verificar como rota concluída aparece no histórico (badge "Concluída"? cor diferente? duplicate?)

### 10.19 — Settings (Configurações) completas — 13 rows + 4 sections

**🚨 Arquitetura DIFERENTE:** Settings usa **PreferenceActivity tradicional Android** (RecyclerView com rids `android:id/title`, `android:id/summary`, `android:id/switch_widget`), **NÃO Compose**. Mais simples mas Android-classic.

**Path:** drawer → tap engrenagem topo-direito → push de Activity dedicada com toolbar `"Configurações"` + back arrow.

#### Section "Preferências de rota" (7 items)

| # | Title | Summary | Widget | Notas |
|---|---|---|---|---|
| 1 | App de navegação | "Navegação do Spoke" | (chevron) | Tap abre picker. **🆕 GAP: existe um app "Navegação do Spoke" próprio** — diferente do que assumi (Waze/Google Maps). Verificar opções no picker |
| 2 | Lado da parada | "Qualquer lado do veículo" | (chevron) | Opções: Qualquer / Direito / Esquerdo (per §3.3) |
| 3 | Tempo médio na parada | "1 min" | (chevron) | Picker numérico, default 1 min |
| 4 | Tipo de veículo | "Carro" | (chevron) | Opções: Carro / Moto / Bicicleta / A pé (per §3.3) |
| 5 | Evitar pedágios | "Economizar evitando estradas com pedágio" | Switch | OFF default |
| 6 | ID de parada | "Moderno e Por ordem de rota" | (chevron) | Picker da §10.6.1 (Moderno/Clássico + Depois da otimização/Conforme as paradas) |
| 7 | Balão do modo de navegação | "Veja informações de entrega enquanto navega" | Switch | **ON default** — overlay info quando navegando |

#### Section "Preferências gerais" (1 item)

| # | Title | Summary | Widget |
|---|---|---|---|
| 8 | Tema | "Automático (Pôr do Sol/Nascer do Sol)" | (chevron, picker) — **🚫 OUT-OF-SCOPE per Eduardo 2026-05-26:** RotPro NÃO replica multi-theme. App fica em tema único (provavelmente o dark do `prototipo/` por default). |

Opções inferidas: Automático (selected) / Claro / Escuro / Mesmo do sistema (confirmado em §10.19.3 abaixo, mas descartado pra implementação RotPro).

#### Section "Assinatura" (1 item)

| # | Title | Summary | Widget |
|---|---|---|---|
| 9 | Comparar planos | (sem summary) | (chevron) |

Tap abre paywall comparação free vs premium (OUT-OF-SCOPE pra RotPro per ADR-0010 — temos Stripe Pix).

#### Section sem header (rodapé legal — 4 items)

| # | Title | Notas |
|---|---|---|
| 10 | Licenças | Lista de OSS licenses (Spoke usa OSS, copyright notices) |
| 11 | Termos de uso | Link externo? Tela in-app? Inspecionar |
| 12 | Política de privacidade | Idem |
| 13 | Versão | Summary `"Spoke-v3.65.1"` (não-clickable) |
| 14 | Sair | **TEXTO VERMELHO** (destructive logout) |

**Observações:**

- **Faltam alguns items que §3.3 assumiu existirem:**
  - "Endereço de casa" (item 22 §3.3) — não vi nesta passagem; **provavelmente está em outro lugar** (account/profile do drawer? ou subset da Spoke não-explorado)
  - "Indicações" (item 23 §3.3) — RotPro existing feature; OK; Spoke pode não ter equivalente
- **App de navegação:** Spoke tem app proprietário ("Navegação do Spoke"). RotPro per ADR-0010 default Google Maps. Picker provavelmente tem: Spoke (default) / Waze / Google Maps / Apple Maps.
- **Sair (vermelho):** padrão de design consistente com "Remover parada" §10.6 — Spoke usa cor vermelha sistematicamente pra destrutivo.

**Implicação pro RotPro:**
- Usar `Material` settings UI nativa Flutter (ListView com `ListTile + Switch + chevron`) — não precisa Compose-equivalent fancy
- Section headers via `Padding(child: Text(..., style: theme.textTheme.labelMedium))`
- Switch via `SwitchListTile.adaptive`
- Pickers abrem novas Activities (push) com lista radio

**Pendente:**
- Tap em cada setting que abre picker → capturar opções exatas:
  - App de navegação (gap: app próprio Spoke!)
  - Lado da parada
  - Tempo médio
  - Tipo de veículo
  - Tema
- Tap "Comparar planos" → capturar paywall completo (OUT-OF-SCOPE mas útil pra ADR-0030 reference)
- Tap "Licenças" / "Termos" / "Privacidade" → confirmar comportamento (in-app vs external link)

#### 10.19.1 — Picker: "App de navegação" (5 opções)

Modal dialog (não bottom sheet) com radio list + Cancelar:

1. **Navegação do Spoke** (selected default) — 🆕 app próprio Spoke (não tem equivalente externo conhecido)
2. **Google Maps**
3. **Waze**
4. **Navegador Yandex** (Yandex Navigator — russo, popular em mercados russos)
5. **Outro** — Android `ACTION_VIEW` com `geo:` URI; abre Activity Chooser do sistema pra qualquer app de mapa instalado escolher

**⚠️ Audit 2026-05-26 — implicação RotPro revisada:**

Per ADR-0010 escopo principal é **Google Maps default + Waze**. A opção **"Outro"** é trivial de implementar (1 linha Flutter `url_launcher` com URI `geo:lat,lng?q=address`) e dá flexibilidade ao usuário (apps locais Sygic/HERE/TomTom/Maps.me/etc.). Decisão:

- **Slice 2:** lista RotPro = `[GoogleMaps, Waze, Outro]`. "Outro" usa `url_launcher` + `LaunchMode.externalApplication` com URI `geo:` que Android resolve via Intent Chooser
- **NÃO replicar:** "Navegação do Spoke" (não temos app próprio), "Navegador Yandex" (irrelevante BR)
- **Implementação pseudo-código:** `Uri.parse('geo:${stop.lat},${stop.lng}?q=${Uri.encodeComponent(stop.address)}')` → `launchUrl(uri, mode: LaunchMode.externalApplication)`

#### 10.19.2 — Picker: "Tipo de veículo" (5 opções com ícones + restrições)

Modal com radio list, **cada opção tem ícone à esquerda + label + subtitle de restrição** (quando aplica) + Cancelar:

1. **Bicicleta** (ícone bike) — subtitle: `"Somente Google Maps"` (restrição de nav app)
2. **Scooter** (ícone scooter)
3. **Carro** (ícone car, selected default)
4. **Caminhão pequeno** (ícone small truck)
5. **Caminhão grande** (ícone large truck) — subtitle: `"Somente Sygic Maps"` (referência a app não listado no picker §10.19.1 — Sygic seria 6º opção condicional?)

**🚨 Correção de §3.3 item 17:** lista REAL é Bicicleta/Scooter/Carro/Caminhão pequeno/Caminhão grande. **Sem "Moto"** (Scooter substitui), **sem "A pé"** (provavelmente não viable pra delivery business).

**Implicação RotPro:** GraphHopper backend suporta perfis `bike`, `motorcycle`, `car`, `small_truck`. Mapeamento: Bicicleta→bike, Scooter→motorcycle, Carro→car, Caminhão pequeno→small_truck. **Caminhão grande não suportado em GraphHopper SP atual** — deferred pós-M2.

**Subtitle de restrição é UX importante:** RotPro deve renderizar conditional `subtitle` quando vehicle.type tem restrição de routing. Ex: "Bicicleta — somente em ruas com ciclovias mapeadas".

#### 10.19.3 — Picker: "Tema" (4 opções) — 🚫 OUT-OF-SCOPE pra RotPro

**Decisão Eduardo 2026-05-26:** RotPro NÃO replica multi-theme. App fica em tema único. Registro abaixo é só pra completude do inventário, NÃO pra implementação.

Modal com radio list + Cancelar:

1. Claro
2. Escuro
3. Mesmo do sistema (segue Android system theme)
4. Automático (Pôr do Sol/Nascer do Sol) (selected default) — clever feature Spoke

**Implicação RotPro:** **Tema único fixo** (provavelmente o dark do `prototipo/` per ADR-0035 visual identity). Sem setting de Tema no RotPro Settings. Remove o gap "Section Preferências gerais" inteiro do Settings RotPro (se essa for a única setting da section).

#### Decisões pra economizar ciclos (pickers não-drilled)

Não foram tap-inspected, mas inferências baseadas em §3.3 + observação parcial:

- **Lado da parada:** 3 opções Qualquer (default) / Direito / Esquerdo. Padrão observado em outros apps delivery. RotPro: usar como `StopSidePreference enum`.
- **Tempo médio na parada:** picker numérico, valores típicos 1/2/3/5/10 min. Default 1 min. Format: `int minutes`.
- **ID de parada:** já drilled em §10.6.1 — 2 + 2 radios (Moderno/Clássico + Depois da otimização/Conforme as paradas são adicionadas).

### 10.20 — Drawer pós-conclusão de rota + kebab da rota concluída

**Observações 2026-05-26 após sequência §10.13-10.18 (rota terça-feira completed com 3 delivered + 1 failed):**

**Drawer:**
- Rota concluída **NÃO ganha badge visual diferente** (sem checkmark, sem "(concluída)" label, sem cor diferente do nome)
- Ainda aparece na seção **"Hoje"** (não foi movida pra "Arquivadas" / "Concluídas" / "Histórico")
- Aparece **em azul** (mesma cor de active route) porque continua sendo a rota ativa (selected) — single-active model
- **Mapa por trás do drawer** (visível na faixa right do screenshot) mostra os marker finais (✓ verdes + flag) — confirmando que o estado completed persiste visualmente apenas no mapa, não na lista

**Kebab da rota concluída:** **EXATAMENTE as mesmas 3 opções** do kebab de rota draft/em progresso:
1. Definir nome e data
2. Duplicar rota
3. Excluir rota

**NÃO existe nenhuma opção extra** como:
- "Exportar resumo / PDF"
- "Compartilhar resumo"
- "Reabrir rota"
- "Arquivar"
- "Marcar como template"

**Implicação pro RotPro:**
1. **Slice 2 simplifica:** kebab por rota é um único `PopupMenu<RouteAction>` com 3 actions; sem conditional por status.
2. **Rota concluída fica "reabrível"** trivialmente: usuário entra na rota → estado §10.18 → tap em add/search button do header reabre fluxo. Não há barrier UI.
3. **Sem histórico/arquivamento:** modelo `Route` precisa de `completedAt: DateTime?` mas drawer query ignora esse campo na ordenação/filtering. Tudo continua na lista do drawer.
4. **Compartilhar resumo é OPORTUNIDADE pro RotPro:** Spoke não tem; RotPro pode ADICIONAR isso como feature original (alinha com ScreenShare/Pix paywall = features original-RotPro que diferenciam). Sugestão: tap "Duplicar rota" item do menu, mas adicionar quarto item "Compartilhar resumo" pra rotas concluídas.

### 10.21 — Tela "Adicionar parada" (texto + 3 method shortcuts)

**Trigger:** tap CTA "Adicionar paradas" no empty state §6.2bis OU tap no EditText do bottom bar do sheet expanded §10.5.

**Estrutura observada:**

| Elemento | Bounds | Notas |
|---|---|---|
| Topbar (search bar) | `[0,182][1080,386]` | |
| EditText `"Digite para adicionar"` | `[159,195][674,330]` | placeholder hint, **autofocused** (keyboard auto-open) |
| OCR button | `[697,205][810,318]` | a11y `"Ler etiqueta de endereço"` — abre câmera direto |
| Voice button | `[810,205][923,318]` | a11y `"Dite o endereço"` — abre voice listening direto |
| X close button | `[935,195][1070,330]` | a11y `"Fechar"` — fecha sheet (NÃO back arrow) |
| Empty state (centro) | `[259,773][822,878]` | Texto centralizado: `"Adicione as primeiras paradas para começar a criar sua rota"` + ícone "+" decorativo |
| **3 method shortcut buttons em row:** | | |
| `📍 Mapa` button | `[45,1144][345,1347]` | Outline button, ícone mapa + label "Mapa" — tap leva pra **tap-on-map flow** (pick lat/lng visual) |
| `📄 Leitor` button | `[390,1144][690,1347]` | Outline button, ícone documento — tap abre OCR (mesma destination que ícone topbar) |
| `🎤 Voz` button | `[735,1144][1035,1347]` | Outline button, ícone microfone — tap abre Voice (mesma destination que ícone topbar) |

**Observações:**

1. **Bottom bar do sheet expanded (§10.5) e esta tela compartilham os mesmos shortcuts:** OCR + Voice estão tanto no topbar (bottom bar do sheet) quanto como big buttons centrais aqui. **Redundância intencional** — Spoke quer reduzir taps pro usuário em qualquer state.
2. **Empty state é ENCORAJADOR (3 method buttons grandes), não apenas decorativo:** Spoke incentiva descoberta dos 3 métodos pra primeira parada. Após primeira parada adicionada, esses buttons provavelmente desaparecem (não inspecionado nesta passada — gap).
3. **Voice/OCR têm 1-tap-depth desde o sheet** (per §10.5 bottom bar) e também desde Adicionar parada (esta tela) — total 2 paths. Mapa só está nesta tela e provavelmente acessível diretamente pelo tap-no-mapa também.
4. **EditText autofocus** + keyboard aberta indica que **typing é o flow default** — outros 3 métodos são alternativas.

**Implicação pro RotPro:**

```dart
// AddStopPage estrutural
Scaffold(
  // No AppBar — topbar is rendered inside the sheet/page
  body: Stack(
    children: [
      // Top: search + X close + OCR + Voice shortcuts
      Positioned(top: 0, child: AddStopSearchBar(...)),
      // Middle: empty state OR autocomplete results
      // Bottom-of-content: 3 big method buttons (Map / Reader / Voice)
      Center(child: AddStopMethodButtonsRow(...)),
    ],
  ),
);
```

- 3 método shortcuts visíveis SÓ no empty state (quando `searchController.text.isEmpty && autocompleteResults.isEmpty`); colapsam quando o usuário começa a digitar (gap a confirmar via teste real)
- **⚠️ Audit 2026-05-26 — 5 métodos no total** (não 4 como inventário original dizia):
  1. **Texto** (autocomplete inline)
  2. **Mapa** (tap-no-mapa)
  3. **Leitor** (OCR single-stop via câmera)
  4. **Voz** (single-stop voice + CTA secundário "fale vários endereços" → voice multi-stop dictation per §3.2 item 10b)
  5. **CSV upload** (bulk import via "Importar manifesto de rotas" no kebab §6.4 item 5; aceita `.csv/.tsv/.xls/.xlsx/.xlm/.txt`) — NÃO está nos 3 button shortcuts mas é canal oficial Spoke; entry point diferente (kebab da rota ativa, não Add Stop UI)
- Métodos 1-4 navegam pra tela dedicada própria (exceto Texto que faz inline). Método 5 está no kebab pra cobrir bulk-add fluxo profissional.
- **Decisão RotPro:** slice 2 implementa 1-4 (paridade com 3 button shortcuts + entry texto inline); slice 3+ implementa 5 (CSV upload é trabalho de parser não-trivial; postergado per §3.2 item 9)

**Pendente nesta passada:**
- Tap "Mapa" → confirmar UI tap-no-mapa (provavelmente full-screen map + pin draggable + Confirm CTA bottom)
- Tap "Leitor" → confirmar UI OCR (provavelmente camera viewfinder full-screen + capture button + cropper + confirmation)
- Tap "Voz" → confirmar UI Voice (provavelmente recording UI + pulse + transcript preview + secondary CTA "fale vários endereços" per §3.2 item 10b)
- Digitar texto e ver autocomplete results layout (provavelmente lista vertical de results scroll + tap pra select)
- "Outro" / custom location entry (provavelmente acessível por scroll/empty results state)

### 10.22 — Conclusão da Fase B (mapa de cobertura final)

**Total: 22 sub-sections (§10.1-10.21) cobrindo o ciclo completo de uso do Spoke:**

| § | Tela / Estado | Achado destacado |
|---|---|---|
| §10.1 | Drawer aberto | Scrim bounds + 90% width + 5 zonas |
| §10.2 | 3-dot popup rota | PopupMenu 3 items, sem destrutivo colorido |
| §10.3 | "Editar rota" form | Wizard parametrizado (sem Zona C), X close vs back |
| §10.4 | 🚨 **"Detalhes da rota"** | NEW screen — pre-flight Partida/Destino/Pausa |
| §10.5 | Tela ativa sheet COM stops | Sheet auto-expanded (§6.2bis errada) |
| §10.6 | 🚨 **"Editar parada"** | 14 campos combinando detalhe+edit |
| §10.6.1 | 🚨 Correção crítica | Chip "ID Pendente" NÃO é status delivery |
| §10.6.2 | Best practice docs > inferência | Cross-ref Spoke docs |
| §10.7 | Stop card gestures | Long-press + swipe NEGATIVOS |
| §10.8 | FTUE modal IDs ajustados | First-time use educativo |
| §10.9 | 🚨 **Estado pós-optimize** | 3 CTAs novos: Refinar/Confirmar |
| §10.10 | FTUE confirm IDs definitivos | Lock dialog |
| §10.11 | FTUE Load vehicle | Opt-in per route |
| §10.12 | 🚨 **Ready-to-Run state** | "Iniciar rota" gateway |
| §10.13 | 🎯 **MODO DELIVERY** | 3 status buttons (Navegar/Não entregue/Entregue) |
| §10.14 | 🚨 "Não entregue" SEM picker | Divergência vs docs Spoke |
| §10.15 | Marker visual encoding | Nx (failed) / N✓ (delivered) |
| §10.16 | "Entregue" simétrico | Zero confirmation UX |
| §10.17 | "Destino final" Ida e volta | 2 buttons (Navegar/Rota concluída) |
| §10.18 | 🎯 **"Rota concluída!"** | Summary card + stats + CTA copiar |
| §10.19 | Settings completas | 13 rows + 4 sections |
| §10.19.1 | Picker App nav | 5 opções (Spoke/GMaps/Waze/Yandex/Outro) |
| §10.19.2 | Picker Tipo veículo | 5 opções com restrições |
| §10.19.3 | Picker Tema | 4 opções (OUT-OF-SCOPE RotPro) |
| §10.20 | Drawer pós-conclusão | Sem badge "concluída"; kebab idêntico |
| §10.21 | "Adicionar parada" entry | Search + 3 method shortcuts |

**Gaps explicitamente conhecidos (não-cobertos por design ou tempo):**

1. **Pickers das settings menos críticas:** Lado da parada, Tempo médio na parada (inferíveis)
2. **Sub-telas de "Detalhes da rota" (§10.4):** pickers Partida/Destino/Pausa específicos
3. **"Comparar planos" paywall** (out-of-scope per ADR-0030 — Stripe Pix nosso)
4. **Licenças/Termos/Privacidade** (legal — comportamento de open/external link)
5. **Flow completo Adicionar parada via Voz** (perm flow + listening UI + transcript)
6. **Flow completo Adicionar parada via OCR** (camera perm + viewfinder + cropper)
7. **Flow completo Adicionar parada via Mapa** (tap-on-map + pin drag + confirm)
8. **Autocomplete results layout** (after typing query)
9. **Reutilizar paradas** (§3.2 item 8) — sub-flow não inspecionado nesta passada (Eduardo nao tinha rotas anteriores com paradas pra usar)
10. **Load vehicle UI** (skipped no FTUE §10.11)
11. **Compartilhar rota em tempo real** (§10.12 row 1)
12. **"Refinar" CTA** (§10.9) — opções pra ajustar otimização
13. **Comportamento "Excluir rota"** (destrutivo; pulei pra preservar dados)

**Estes 13 gaps são candidatos pra uma sessão B-followup dedicada quando RotPro slice 2 estiver na fase de "preencher detalhes".** Não bloqueiam a primeira passada de implementação que pode começar imediatamente com §10.1-10.21 como ground truth.

### 10.23 — Nota importante sobre microcopy dinâmica (Eduardo 2026-05-26)

**⚠️ Correção 2026-05-26 — o ponto real do Eduardo:** Eduardo estava apontando o **modal de upsell contextualizado** (§10.24 abaixo) que mostra **"Eduardo, chegar cedo a casa. Motoristas de Ribeirão Preto terminam o trabalho mais cedo..."** — não os endereços dos stops. O modal usa **primeiro nome + cidade** dinamicamente personalizados via templating. Os endereços também são dinâmicos (vêm do geocoder), mas o ponto principal era esse modal.

**Sobre endereços (registrado por completude):** os endereços que aparecem nos stop cards e nas linhas de paradas (ex: `"Subsetor Leste, 2 (L-2), Ribeirão Preto, 14090-250"`, `"Jardim Paulista, Ribeirão Preto"`) **NÃO são labels estáticos hardcoded** — são o **output do parser/geocoder** aplicado ao endereço real digitado/escolhido pelo usuário.

**Implicações:**

1. **"Ribeirão Preto" aparece porque é a cidade real dos endereços do Eduardo** (estado: SP). Em outras contas com endereços de São Paulo capital, apareceria "São Paulo". Em endereços do RJ, "Rio de Janeiro".

2. **Format do address rendering observado em Spoke:**
   - Stop card title (h6): `<rua>` — apenas o nome da rua (ex: "Rua Franca")
   - Stop card subtitle (body2 muted): `<bairro>, <cidade>` ou `<bairro/complemento>, <cidade>, <CEP>` — varia por completude do endereço retornado pelo geocoder

3. **Pro RotPro slice 3 backend (Nominatim SP):**
   - Schema do `Stop` model deve guardar campos estruturados separados: `streetName`, `streetNumber?`, `neighborhood?`, `city`, `state`, `postalCode?`, `country` — **não concatenar em uma string única**
   - UI rendering deve compor dinamicamente: `"$neighborhood${city != null ? ', $city' : ''}${postalCode != null ? ', $postalCode' : ''}"`
   - Nominatim retorna esses fields separados no JSON `address` (tipo `address.road`, `address.suburb`, `address.city`, `address.postcode`)
   - **Localization considerada:** `address.city_district` vs `address.suburb` vs `address.neighbourhood` — Spoke aparentemente usa o mais granular disponível ("Subsetor Leste, 2 (L-2)" é nível de subsetor administrativo de Ribeirão Preto, retornado por Nominatim como `address.suburb` ou `address.neighbourhood`).

4. **Implicação pra ADR-0010 (legal boundary):** nenhuma — Spoke usa o mesmo Nominatim/Google Geocoding API que o RotPro vai usar. Não é decompile de Spoke, é uso de mesma fonte upstream.

5. **Implicação pra inventário inteiro:** **toda string de endereço citada nesta §10 é exemplo de output observado pra dados específicos do Eduardo, NÃO é spec de copy.** Inventory entries que citam endereços (ex: §10.5 "Rua Franca", §10.6 título da Editar parada, §10.13 título no modo delivery, §10.18 "R. José da Silva, 713 Jardim Paulista") devem ser lidas como ilustrações estruturais, com a string real vindo do geocoder em runtime.

**Outras strings dinâmicas observadas que seguem o mesmo princípio:**
- **Nomes de rotas** (ex: "terça-feira Rota 2"): auto-gerados pelo `wizard` Spoke a partir de dia-da-semana + counter, editáveis pelo usuário
- **Timestamps** (ex: "19:25", "19:36"): horários do device em real-time
- **Counters** (ex: "1/4", "14 min • 4 paradas • 3,3 km", "4 paradas — 1 perdida"): computed da `Route` model
- **CEPs** (ex: "14090-250", "14090-042"): vêm do geocoder

Apenas labels **truly static** são parafraseadas no inventário (CTAs, titles de telas, settings labels). Strings dinâmicas viraram exemplos quando necessárias pra entender a estrutura.

### 10.24 — 🚨 NOVO: Modal de upsell contextualizado (paywall promotion)

**Trigger observado:** apareceu ao tentar entrar no flow "Adicionar parada" durante a Fase B (não confirmado se é trigger fixo neste momento ou se é probabilistic/A-B-test). Pode ser triggered após N opens da app, após X rotas criadas, ou em pontos específicos do flow de delivery — gap pra confirmar.

**Estrutura observada:**

| Elemento | Notas |
|---|---|
| Modal centered overlay | Sobre o conteúdo atual (Adicionar parada com 3 method buttons visíveis behind dim scrim) |
| Title h2 | `"Eduardo, chegar cedo a casa."` — **personalizado:** `<userFirstName>, <CTA_personalizado>` |
| Body text | `"Motoristas de Ribeirão Preto terminam o trabalho mais cedo com as rotas otimizadas do Spoke 👍"` — **personalizado:** `Motoristas de <userCity> terminam o trabalho mais cedo com as rotas otimizadas do Spoke`. Termina com emoji 👍 |
| CTA primary filled | `"Termine mais cedo."` — leva pra paywall "Comparar planos" (provavelmente) |
| CTA secondary text | `"Cancelar"` — dismiss modal, volta ao estado anterior |

**Implicações:**

1. **Personalização via template variables:** Spoke usa templating com `userFirstName` + `userCity` pra criar mensagens de upsell mais relevantes. Dado que essa info vem do profile, é trivial implementar similar no RotPro.

2. **Paywall trigger contextual:** o modal aparece em **momentos de friction** (Adicionar parada quando flow é repetitivo) — momentos onde usuário pode estar mais receptivo a "Spoke faz isso mais rápido pra você". Boa estratégia de growth.

3. **Use of social proof:** "Motoristas de [cidade]" é social proof local — usuário se identifica com pares da mesma região. Pra RotPro slice 4 (Stripe Pix paywall): considerar template similar com `cidade` do usuário e referência a outros motoristas locais.

4. **Localização geográfica conhecida pelo backend:** Spoke sabe que Eduardo é de Ribeirão Preto (inferido via Geo-IP no signup ou via primeira rota criada). RotPro slice 3 backend deve persistir `User.city: String?` (nullable, inferred from first geocoded address ou via IP geolocation).

5. **OUT-OF-SCOPE pra slice 2:** este modal é parte do funil de paywall — encaixa em slice 4 (Stripe Pix paywall). Slice 2 NÃO replica.

**Pendente:**
- Tap "Termine mais cedo" → confirmar que leva pra paywall §3.3 item 25 "Comparar planos"
- Identificar trigger condition (quantos opens / quantas rotas / qual ação dispara?)
- Confirmar se modal aparece também em outros pontos do app além de Adicionar parada

---

## §11 — Fase B-followup deep drills (2026-05-26)

> **Por que existe esta seção:** Após PR #15 (Fase B inicial) mergeado, Eduardo identificou que coverage do §10.22 era breadth-only — vários sub-flows críticos (Editar parada items individuais, Detalhes da rota sub-screens, 8 features kebab, Voice/Camera multi-address, Criar rota wizard completo) só foram nomeados mas não drilled. Esta seção (§11) fecha esses gaps via dispatches Maestro MCP adicionais.
>
> **Estratégia:** drillar em estado **editável** (rota não-otimizada) para mapear Pacotes/Ordem/Tipo (que ficam disabled após otimização). Achados duplicam §10.x apenas onde há informação NOVA; cross-references apontam pra entrada original.

### 11.1 — Editar parada: drilldown em estado pós-otimização (parcial)

**Inspecionado:** 2026-05-26 via Maestro MCP `inspect_screen` (parada A1 da rota terça-feira otimizada)

**Achados que confirmam/expandem §10.6:**

- **Chip "Azul" (cor) → bottom sheet picker** — Tap abre Compose-based bottom sheet:
  - TopBar: [`Limpar` (esq) | `Cor` (centro) | `Concluído` (dir, primary)]
  - Lista vertical scroll de 5 opções: Azul / Verde-azulado / Roxo / Rosa / Laranja
  - Top area `[0,92][1080,1257]` com `a11y:"Fechar planilha"` (tap-to-dismiss)
  - Padrão = mesma sheet de §10.6 secondary chip
  - **CTA "Limpar"** remove cor atual (volta pra "sem cor"); **CTA "Concluído"** confirma e fecha
  - Implementação RotPro: `showModalBottomSheet` com `ListView` de 5 chips ColorTokens.* + ações Limpar/Concluir no topo

- **Chip "A1" (package ID)** — APENAS DISPLAY em rota otimizada (não abre picker). Pré-otimização provavelmente é editável (gap a confirmar).

- **"Pacotes" stepper, "Ordem" segmented, "Tipo" segmented — DISABLED (`enabled:false`)** após otimização confirmada (lock state §10.10). Pré-otimização presumivelmente ativos.
  - Ordem opções: [Primeira | **Automática** ✓ default | Última]
  - Tipo opções: [**Entrega** ✓ default | Coleta]
  - Pacotes: stepper [- / contador / +] padrão "1"; visível mas tap não responde

- **Geocoder snackbar:** quando GPS indoor / sem fix, aparece snackbar no topo "[texto curto sobre endereço não identificado]" + botão "Limpar" — UX fallback pra LocationRequest falho. Implementação RotPro: SnackBar com action button via `ScaffoldMessenger`.

- **"Instruções de acesso" (button-style row)** — tap NÃO abriu modal visível nas 2 tentativas. Investigado via docs oficiais Spoke (per ADR-0037 Amendment 1 Rule 1).
  - **Função canônica (docs):** permite anexar instruções específicas ao **endereço** (não à parada): códigos de portão, localização de chaves, etc.
  - **Sticky behavior:** info fica ligada ao **endereço**, não à parada. Quando o mesmo endereço entrar em rota futura, instruções aparecem automaticamente.
  - **Edit/Clear:** editável e removível a qualquer momento.
  - **Checkbox "save as default for this address"** (texto traduzido provavelmente "Salvar como padrão para este endereço") — opt-in pra persistir per-address.
  - **Hipóteses pro tap não abrir:** (a) endereço fora do geocoder cache da Spoke (snackbar "endereço não pode ser identificado" sugere isso); (b) hit area menor que 100% do row visível; (c) bug local v3.65.1. Não é gating de otimização (instrução é dado de endereço, não de solver).
  - **Comportamento esperado quando funciona (per docs):** abre modal/tela com TextField multiline + label "Instruções de acesso" + checkbox "Salvar como padrão para este endereço" + CTAs Cancelar/Salvar.
  - **Implicação pro RotPro:** precisa modelar `access_instructions` no nível do `Address` (não do `Stop`). Sugestão schema: tabela `address_defaults` com FK pra `addresses` OU `JSONB column meta` em `addresses` com `{access_instructions: string, save_as_default: bool}`. Tela: full-screen ou bottom sheet com TextField multiline (4-6 linhas), checkbox padrão, salvar via `addressRepository.updateMeta(addressId, ...)`.

**Pendente drill em rota não-otimizada (gap real conhecido):**
- Tap chip "A1" (package ID picker — quais opções?)
- Tap stepper Pacotes (+/-, range, default behavior)
- Tap segmented Ordem (lock comportamento Primeira/Última)
- Tap segmented Tipo (Entrega vs Coleta — afeta solver?)
- Tap "Instruções de acesso" (modal vs inline TextField)
- Tap row "Horário de chegada" → time picker / range picker?
- Tap row "Tempo estimado na parada" → picker de minutos?
- Tap "Mudar endereço" → search screen igual Adicionar parada §10.21?
- Tap "Duplicar parada" → cria cópia + opens Editar? ou navega de volta?
- Tap "Remover parada" → confirm dialog? silent delete? undo?

**Decisão:** drillar esses 10 items requer recriar rota teste com paradas + NÃO otimizar. Realizado parcialmente abaixo (§11.5).

### 11.2 — DatePickerDialog (Criar rota → "Escolher data")

**Inspecionado:** 2026-05-26 via Maestro MCP (wizard Criar rota)

**Estrutura observada (Material 3 padrão Android com app namespace):**

- **Header:** "SELECIONAR DATA" (label) + "Data selecionada" subtitle (vazio = "Seleção atual: nenhuma")
- **Toggle:** ícone direito para "Mudar para o modo de entrada de texto" (input MM/DD/YYYY ao invés de calendário)
- **Mês navegação:** "MAIO DE 2026" (Button clickable — abre year picker provavelmente) + < previous + > next
- **GridView 7 cols:** D / S / T / Q / Q / S / S (dias da semana)
- **GridView células dia:** cada TextView clickable com `a11y` completo ("Sexta-feira, 1 de maio") — today destacado ("Hoje Terça-feira, 26 de maio")
- **Footer:** CANCELAR (esq) / OK (dir, disabled enquanto não selecionou)
- **resource-ids:** `com.underwood.route_optimiser:id/mtrl_picker_*` — confirma uso de Material Design Components Date Picker padrão

**Implicação pro RotPro:**
- Usar `showDatePicker` do Flutter Material (`material.dart`) — produz UI quase idêntica (Material 3 com `useMaterial3: true` no app theme)
- Localização PT-BR via `MaterialLocalizations.delegate` + `Locale('pt', 'BR')` em `MaterialApp.supportedLocales`
- Para o input mode toggle, `showDatePicker` já oferece via `initialEntryMode: DatePickerEntryMode.calendarOnly | input | inputOnly`

### 11.3 — Tela "Reutilizar paradas" (Copiar paradas de uma rota anterior)

**Inspecionado:** 2026-05-26 via Maestro MCP (wizard Criar rota → após selecionar data + "Reutilizar paradas anteriores" checked OU CTA "Copiar paradas de uma rota anterior" no estado vazio da rota)

**Estrutura observada:**

- **TopBar:** Voltar (esq) + título "Reutilizar paradas" + botão direito (ⓘ ajuda provavelmente, não drilled)
- **Dropdown rota fonte:** "De: 27 de mai. quarta-feira" — clickable, abre dialog picker
- **3 sections expansíveis com checkbox + título + (count ou estado vazio):**
  - "Paradas não realizadas" — checkbox + microcopy "Nenhuma parada não realizada nesta rota"
  - "Paradas puladas" — checkbox + microcopy "Nenhuma parada pulada nesta rota"
  - "Paradas feitas" — checkbox + microcopy "Nenhuma parada feita nesta rota"
- **CTA rodapé fixo:** "Copiar paradas" (disabled se nenhum item selecionado)

**Sub-flow: Picker de rota fonte (dialog floating)**

Tap no dropdown abre dialog (sem header):

- Lista de TODAS as rotas DESC por data (mais recente em cima)
- Cada item linha: data (esq) + nome da rota (centro) + status badge (baixo: "Não iniciada" | "1 parada perdida" | etc.)
- A rota que está sendo criada AGORA aparece no picker como rota válida (sem self-exclude — gap intencional? bug? a confirmar)
- Sem busca, sem agrupador por período (drawer agrupa, picker não)
- Tap em item → fecha dialog + atualiza dropdown da tela principal

**Implicação pro RotPro:**
- Tela full-screen com Scaffold + AppBar + Body com 3 ExpansionTile + CTA fixo no bottom
- Picker de rota fonte: `showDialog` com `ListView.builder` ordenada por `createdAt DESC`; sem busca (Spoke não tem)
- Excluir rota corrente do picker (consertar gap do Spoke — UX melhor)
- Validação backend: deduplicar paradas no copy (mesmo endereço pode existir em múltiplas rotas; usuário escolhe)

### 11.4 — Adicionar parada via TEXTO (autocomplete)

**Inspecionado:** 2026-05-26 via Maestro MCP (tap input texto sticky no header da tela ativa de rota)

**Estrutura observada:**

- **Bottom sheet expandida cobrindo mapa** — abre full-screen com keyboard
- **Sticky header (top):** mesmo input EditText + 🏷️ "Ler etiqueta de endereço" + 🎤 "Dite o endereço" + ✕ "Limpar"
- **Section header:** "Adicionar nova parada"
- **Lista de resultados autocomplete (5 visíveis):**
  - Cada item: linha 1 (endereço + número) negrito + linha 2 (bairro, cidade - estado, país) cinza
  - Resultados pra "Av Paulista 1000": Bela Vista SP / Vila Nunes Paulínia / Jardins SP / Vila NS Fátima Americana / Av. Paulista, 1000 (sem subtítulo)
  - Behavior: tap → adiciona parada à rota + fecha sheet + retorna à tela ativa de rota com marker no mapa
- **Tela "Editar parada" auto-abre via swipe-up da sheet** após adicionar (BIG FIND)

**Observações estruturais:**
- Autocomplete provavelmente usa Google Places API por trás dos panos (Spoke é cliente Google Maps Platform), MAS a UI da lista de resultados é Compose Spoke proprietário, não o Place Autocomplete Widget nativo. RotPro NÃO precisa replicar Google Places por contrato — Nominatim SP self-hosted entrega o mesmo UX (lista de resultados).
- Resultados aparecem on-the-fly (debounced) conforme usuário digita
- Não há "buscar" button — autocomplete é sempre live

**Implicação pro RotPro:**
- Slice 2 stub: lista fake hardcoded 4-5 endereços quando input >= 3 chars (per ROADMAP-v2 Slice 2)
- Slice 3 real: Nominatim SP query com debounce 300ms; resultado em `ListView.builder`
- Adicionar parada: criar `Stop` com `address`, `lat`, `lng` do resultado + invalidate provider `currentRouteStopsProvider`

### 11.5 — Editar parada em rota NÃO-otimizada (estado completamente editável)

**Inspecionado:** 2026-05-26 via Maestro MCP (rota nova criada → 2 paradas adicionadas → swipe-up no sheet)

**Estrutura observada (mesma de §10.6 / §11.1, com correções):**

- Layout 100% idêntico ao pós-otimização (§10.6, §11.1)
- **SURPRESA crítica:** Pacotes / Ordem / Tipo **continuam DISABLED** (`enabled:false`) mesmo em rota não-otimizada
- Eduardo está no plano "**Standard**" (visível no drawer "Standard • Renova-se em ter. 09 de jun.")

**⚠️ Audit 2026-05-26 — pricing tiers Spoke (correção crítica):**

Spoke tem **3 tiers** com hierarquia Free < Lite < **Standard (TOP/PAID — $20/mês unlimited)**. Inventário original assumia "Standard" = tier intermediário (era Lite); **correto: Standard é o tier mais caro e dá acesso a TUDO**. Conclusão: NÃO é gating de plano — Eduardo tem acesso total.

- Hipóteses pendentes pra Pacotes/Ordem/Tipo ficarem disabled (todas válidas; nenhuma testada empiricamente — bloqueio §13 C.1):
  - (a) Requer "Localizador de pacotes" preenchido primeiro
  - (b) Requer rota com mínimo N paradas (ex: ≥3)
  - (c) Requer pelo menos uma otimização anterior na rota
  - (d) Bug Spoke v3.65.1 — features visualmente presentes mas não-ativáveis
  - **DECISÃO RotPro:** implementar esses controles SEMPRE ativos (sem gating arbitrário); melhor UX que Spoke aqui. RotPro adota single paid tier R$ 25,90/30 dias per ADR-0030 + BUSINESS-RULES.md (sem tiers, sem free trial).
- Outros items **ENABLED** corretamente:
  - Chip cor "Azul" → bottom sheet picker (§11.1)
  - Chip ID "A1" → ainda não drilled (provavelmente picker similar, gap)
  - Instruções de acesso → docs §11.1 (não drilled UI)
  - EditText notas/observações → input livre
  - Localizador de pacotes → não drilled (provavelmente abre TextField)
  - Horário de chegada → não drilled (provavelmente TimePickerDialog ou range picker)
  - Tempo estimado na parada → não drilled (provavelmente picker minutos)
  - Mudar endereço → não drilled (provavelmente abre search §11.4)
  - Duplicar parada → não drilled
  - Remover parada → não drilled (provavelmente confirm dialog)

**Bottom sheet behavior NOVO documentado:**
- Após adicionar parada via texto §11.4, a sheet expanded auto-mostra "Editar parada" da última adicionada (não a lista de stops)
- Swipe-down fecha sheet e volta pra lista; swipe-up dá full screen Editar parada
- Padrão: Spoke trata Editar parada como bottom sheet draggable (NÃO full-screen route)

**Implicação pro RotPro:**
- Editar parada deve ser `DraggableScrollableSheet` com snap points; NÃO uma rota separada no GoRouter
- Auto-show edit sheet após adicionar parada nova (better UX que apenas "stop added" toast)
- Pacotes/Ordem/Tipo sempre ativos (não gated por estado da rota)

### 11.6 — Drawer pós-criação de novas rotas (delta sobre §10.20)

**Inspecionado:** 2026-05-26 via Maestro MCP

**Achados delta:**

- Drawer agrupa rotas em **3 períodos** (não-fixos, dinâmicos por data):
  - "Próximas rotas" (data > hoje) — ex: "27 de mai. quarta-feira"
  - "Hoje" (data == hoje) — todas as rotas do dia (incluindo recém-concluídas com badge "1 parada perdida")
  - "Início deste mês" (semana anterior) — ex: "18 de mai. Segunda-Feira"
- Cada item: data (esq) + nome opcional (centro, ex: "terça-feira Rota 3") + kebab 3-dot (dir)
- Header user: foto + "Eduardo Rodrigues" + "eduardoteishoku@gmail.com" + "Standard • Renova-se em ter. 09 de jun."
- CTAs topo: Ajuda e suporte (?) + Configurações (⚙️)
- CTA rodapé fixo: "Criar rota" full-width

**Implicação pro RotPro:**
- Agrupador dinâmico: function `groupRoutesByPeriod(routes)` → Map<String, List<Route>> com keys "Próximas", "Hoje", "Início deste mês" (calcular semanas)
- Header: avatar do user + nome + email + linha de assinatura (slice 4)
- Settings entry no topo (não no rodapé como o RotPro atual)

### 11.7 — Coverage map atualizado pós-§11

> **Coverage real após §11:** breadth ainda dominante mas várias profundidades fechadas. O §10.22 listava 13 gaps; muitos seguem abertos mas com docs+hipóteses registradas.

**Drilled empiricamente em §11 (com Maestro MCP):**
- §11.1 Editar parada pós-otimização (color picker drilled, 3 controls disabled identificados)
- §11.2 DatePickerDialog completo (Material 3)
- §11.3 Reutilizar paradas + picker rota fonte (sub-flow completo)
- §11.4 Adicionar parada via texto autocomplete (UI completa, 5 resultados, behavior pós-tap)
- §11.5 Editar parada em rota não-otimizada (CRÍTICO: 3 controls continuam disabled mesmo aqui)
- §11.6 Drawer agrupador dinâmico (3 períodos identificados)

**Drilled via WebSearch docs (per ADR-0037 Amendment 1 Rule 1):**
- §11.1 Instruções de acesso (sticky-to-address + save-default checkbox)
- Spoke pricing tiers (Free 10 stops / Lite limitado / Standard $20/mo full)

**Gaps REAIS pendentes (∼25 items, NÃO 13 como §10.22 sub-estimou):**

| # | Item | Bloqueio pra drillar |
|---|---|---|
| 1 | Pacotes stepper habilitar trigger | Hipóteses não testadas (a-d em §11.5) |
| 2 | Ordem segmented habilitar | Mesmo |
| 3 | Tipo segmented Entrega/Coleta | Mesmo |
| 4 | Chip "A1" tap (package ID picker) | Não drilled |
| 5 | "Localizador de pacotes" tap (input?) | Não drilled |
| 6 | "Horário de chegada" tap (time picker?) | Não drilled |
| 7 | "Tempo estimado na parada" tap (min picker?) | Não drilled |
| 8 | "Mudar endereço" tap (search screen?) | Não drilled |
| 9 | "Duplicar parada" tap (toast? confirm?) | Não drilled |
| 10 | "Remover parada" tap (confirm dialog?) | Não drilled — destrutivo |
| 11 | "Instruções de acesso" tap UI real | Não abriu nas 2 tentativas — docs preenchem gap |
| 12 | Detalhes da rota — Partida picker | Não drilled |
| 13 | Detalhes da rota — Iniciar agora time picker | Não drilled |
| 14 | Detalhes da rota — Ida e volta destination | Não drilled |
| 15 | Detalhes da rota — Definir horário término | Não drilled |
| 16 | Detalhes da rota — Adicionar pausa picker | Não drilled |
| 17 | Kebab rota — Compartilhar (ShareSheet?) | Não drilled |
| 18 | Kebab rota — Transferir paradas | Não drilled |
| 19 | Kebab rota — Copiar paradas (full flow) | Não drilled |
| 20 | Kebab rota — Pular otimização | Não drilled |
| 21 | Kebab rota — Ler manifesto (OCR multi) | Não drilled — permissão câmera |
| 22 | Kebab rota — Importar manifesto (CSV/share) | Não drilled |
| 23 | Kebab rota — Imprimir rota | Não drilled |
| 24 | Kebab rota — Remover paradas (bulk) | Não drilled — destrutivo |
| 25 | Voz "fale vários endereços" | Não drilled — permissão mic |

**Decisão:** estes 25 gaps ficam pra sessão B-followup-2 dedicada (ou sessões implementação onde forem necessários). Para slice 2 telas mais comuns (Editar parada items individuais + Detalhes da rota), basta fazer dispatch `spoke-parity-checker` no próprio microsprint da tela conforme padrão ADR-0036 — não é necessário drillar TUDO antes de implementar.

**Princípio operacional:** inventário breadth-completo (§1-§10) + depth-parcial (§11) + gate dispatch per-microsprint cobre 100% dos casos sem requerir uma sessão dedicada gigante drillando manualmente cada UI antes de qualquer código rolar. White-label do Spoke acontece de forma incremental: cada tela do roadmap pega seu próprio spoke-parity-check no D1 brainstorming + D4 review.

---

## §12 — Features oficiais Spoke não mapeadas no inventário (audit 2026-05-26)

> **Por que existe esta seção:** auditoria sistemática cross-checking inventário × docs oficiais Spoke (help.spoke.com + spoke.com/route-planner + spoke.com/dispatch) identificou **10 features documentadas oficialmente que não estavam mapeadas** em §1-§11. Cada uma é categorizada com decisão proposta (replicar/postergar/descartar) baseada em ADR-0010 + roadmap atual.
>
> **Fonte:** 8 WebSearches em domínios oficiais Spoke (auditoria 2026-05-26). Todas as quotes parafraseadas per ADR-0010 (não-verbatim).

### Tabela consolidada §12 — gap analysis pós-audit

| # | Feature Spoke | Estado RotPro | Severidade gap | Decisão proposta | Slice de execução |
|---|---|---|---|---|---|
| B.1 | **Disruption alerts** (crowdsourced traffic events tipo Waze) | Não temos | 🔴 Crítico funcionalmente; 🟢 baixo pra MVP | **Descartar** — requer base de usuários ativos (network effect) + integração complexa | Não no roadmap |
| B.2 | **Battery saver mode** durante navegação | Não temos navegação interna | 🟢 Irrelevante | **Descartar** — pré-requisito (navegação interna) está fora de escopo | Não no roadmap |
| B.3 | **Roundtrip** ("Return to starting location" auto-fill) | Slice 5 "Sentido casa" já cobre conceito mais amplo | 🟡 Parcial overlap | **Manter slice 5** + adicionar opção "Ida e volta" simples no Detalhes da rota (§10.4) se replicarmos essa tela | Slice 5 (existing) + Slice 2 opcional |
| B.4 | **Per-route override** de Start time / Driving speed / Delivery speed / Max stops | Settings só global em §3.3 | 🟡 Moderado | **Slice 3 backend follow-up** — depende do solver suportar constraints; útil pra motoboy ajustar ETA | Slice 3 follow-up |
| B.5 | **Exportar rota como CSV** (oposto da importação) | Não temos | 🟡 Moderado | **Slice 3 ou pós-M2** — trivial técnico (≈1 dia), valor real pra backup/relatório fiscal do motoboy BR | Slice 3 follow-up |
| B.5b | **Print formatted manifest** (PDF imprimível) | Não temos | 🟢 Baixo | **Postergar pós-M2** — requer Cloud Print integration; uso baixo no contexto BR | Pós-M2 |
| B.6 | **POD com assinatura digital** (finger sign) | §3.4 item 34 "Postergar" | 🟡 Moderado | **Manter decisão atual** mas reagrupar conceitualmente: POD = sistema unificado (foto + assinatura + setting "obrigatório"); slice 3 = foto MVP, pós-M2 = assinatura | Slice 3 (foto) + Pós-M2 (assinatura) |
| B.7 | **Time window por parada** (entrega "só entre 10-12h" como solver constraint) | Não temos; §10.6 "Horário de chegada" pode ser range mas não confirmado | 🟡 Moderado | **Slice 3 backend follow-up** — depende do solver suportar time-window VRP; útil pra B2B | Slice 3 follow-up |
| B.7b | **Priority por parada** (urgência alta = solver prioriza) | Não temos | 🟢 Baixo | **Pós-M2** — feature avançada VRP | Pós-M2 |
| B.8 | **Start time per-route** (override do "Iniciar agora mesmo" pra "Iniciar às HH:MM") | §10.4 placeholder; não drilled | 🟡 Moderado | **Slice 3 backend** — solver precisa pra considerar traffic patterns por horário | Slice 3 backend |
| B.9 | **Picked up status** (terceiro estado pra `stop.type == Coleta`) | §10.6.2 menciona; §10.13 obs #4 hipótese | 🟡 Moderado | **Slice 2 modelo + Slice 3 UI** — implementar enum `StopDeliveryStatus { pending, delivered, failed, pickedUp }` desde slice 2; UI render conditional pra `Stop.type == pickup` | Slice 2 (modelo) + Slice 3 (UI conditional) |
| B.10 | **Maximum stops** setting (per-plan limit Free = 10, Standard = unlimited) | Não temos modelo de tiers | 🟢 Já decidido | **NÃO replicar** — RotPro tem modelo único per ADR-0030 + BUSINESS-RULES.md (R$ 25,90/30 dias acesso total via Stripe Pix; trigger paywall = "Iniciar Navegação"; sem limites de stops por plano). | N/A — decisão fechada |

### Detalhes das features mais críticas

#### §12.B.1 — Disruption alerts (descartado)

**Docs Spoke:** "Drivers can report different types of disruptions including **crash, congestion, police, mobile speed camera, roadworks, lane closure, stalled vehicle or object on road**. Drivers using Spoke's Internal Navigation automatically receive real-time traffic alerts on their route, with live crowdsourced data from Spoke, Waze, and Google Maps."

**Por que descartar:**
- **Network effect dependency:** disruption alerts só funcionam com base ampla de motoboys ativos reportando. RotPro novato não tem essa massa crítica.
- **Engineering complexity:** requer endpoint público pra crowdsourced events + persistência geoespacial + push pra usuários próximos + UI no mapa.
- **Alternativa free:** Waze já faz isso. Quando RotPro motoboy escolhe "Waze" como nav app default, ele recebe disruption alerts de graça (do Waze).

**Decisão:** **descartar definitivamente** do roadmap. Documentar em §7.4 como item adicional. Se cliente Ueslei pedir explicitamente, reavaliar pós-M2.

#### §12.B.4 — Per-route overrides de parâmetros do solver

**Docs Spoke:** "You can edit the route start/end location, start/end time, **maximum number of stops, driving speed and delivery speed**, and these changes will be **automatically saved and will only apply to that route**"

**Implicação técnica:** modelo `Route` precisa de campos opcionais (nullable) pra override:
```dart
class Route {
  // ... campos base ...
  DateTime? startTimeOverride;        // se null, usa "agora"
  DateTime? endTimeOverride;          // hard deadline
  int? maxStopsOverride;              // gating de adição
  double? drivingSpeedKmh;            // override do default global
  int? avgStopDurationMinOverride;    // override do setting "Tempo médio na parada"
}
```

Backend solver consome esses overrides condicionalmente. Front renderiza na tela "Detalhes da rota" §10.4 (sub-screen "Editar parâmetros desta rota" — novo, não inventariado).

**Decisão:** **Slice 3 backend follow-up** — depende de termos solver real (nearest-neighbor + 2-opt baseline). Override de `startTime` é o mais valioso pra traffic patterns.

#### §12.B.5 — Export CSV (oposto da importação)

**Docs Spoke:** "Every plan type provides options to **print a manifest or export route data as a CSV file**, including route date, route name, stop ETA, stop number, address, driver, and package count"

**Schema CSV mínimo (per docs):**
```
route_date, route_name, stop_number, stop_address, stop_eta, driver_name, package_count
2026-05-26, "terça-feira Rota 3", 01, "Rua Franca...", "21:08", "Eduardo", 1
2026-05-26, "terça-feira Rota 3", 02, "Rua Iguape...", "21:12", "Eduardo", 1
```

**Implementação RotPro slice 3:**
- Adicionar item no kebab da rota (§6.4): "Exportar como CSV"
- Tap → gera CSV em memória → `share_plus` package abre Android ShareSheet pro user escolher destino (Google Drive, WhatsApp, email)
- Esforço: ~1 dia (csv generation + share intent)

**Decisão:** **Slice 3 follow-up** — incluir na slice 3 backend planning. Pós-M2 se cortar escopo.

#### §12.B.9 — Picked up status (terceiro estado)

**Docs Spoke confirmam 3 estados:** `Delivered`, `Failed`, `Picked up`.

**Hipótese inventário §10.13 obs #4:** "Picked up" aparece SÓ quando `Stop.type == Coleta` (não `Entrega`).

**Implementação RotPro (slice 2 modelo, slice 3 UI):**
```dart
// Slice 2 — Model
enum StopDeliveryStatus { pending, delivered, failed, pickedUp }
enum StopType { delivery, pickup }

class Stop {
  StopType type;                              // default delivery
  StopDeliveryStatus status;                  // default pending
  String? failureReason;                      // opcional, nullable
  DateTime? statusChangedAt;                  // timestamp da última mudança
}

// Slice 3 — UI (delivery mode §10.13)
// Render conditional dos 3 botões:
Widget buildStatusButtons(Stop stop) {
  return Row(children: [
    // SEMPRE renderiza "Navegar" (primary)
    FilledButton(child: Text('Navegar'), onPressed: ...),
    // Failed sempre disponível
    OutlinedButton(child: Text('Não entregue'), onPressed: ...),
    // 3º botão conditional: Delivered (Entrega) OU Picked up (Coleta)
    if (stop.type == StopType.delivery)
      OutlinedButton(child: Text('Entregue'), onPressed: ...),
    if (stop.type == StopType.pickup)
      OutlinedButton(child: Text('Coletado'), onPressed: ...),
  ]);
}
```

**Decisão:** **Slice 2 (modelo)** — implementar enum desde já pra schema não migrar depois. **Slice 3 (UI conditional)** — render dos botões baseado em `stop.type`.

#### §12.B.10 — Maximum stops e modelo de pricing (FECHADO há muito tempo)

**Docs Spoke:** Free tier = 10 stops máx por rota. Standard tier = unlimited.

**RotPro NÃO replica esse modelo de tiers.** Decisão já fechada com cliente há muito tempo per [ADR-0030](../decisions/0030-stripe-pix-30-day-access-pass.md) + [`docs/BUSINESS-RULES.md`](../BUSINESS-RULES.md):

| Aspecto | Valor canônico |
|---|---|
| Modelo | **Single paid tier** — sem free tier, sem free trial, sem subscription recorrente |
| Preço | **R$ 25,90 por 30 dias de acesso** (pass único, renovação manual a cada ciclo) |
| Trigger paywall | Tap em **"Iniciar Navegação"** (BUSINESS-RULES §5). Adicionar paradas / reordenar / otimizar / ver rota otimizada = **TODOS gratuitos**. Único gate é antes de abrir Waze/GMaps |
| Gateway | Stripe Pix (Connect 50/50 split via Separate Charges and Transfers) |
| Limites por uso | **Nenhum** — sem cap de stops, rotas ou frequência |
| Distribuição | **APK-only** per [ADR-0014](../decisions/0014-apk-distribution.md) (sem Play Store no M2 = sem Google Play Billing 15-30% fee forçado) |

**Implicação pro slice 2 (Telas Core):** o checkbox "Comparar planos" do slice 2 é tela informacional (preço único + bullets do que está incluído), não picker entre tiers. Não há lógica de "qual plano você quer" — só "ative o pass por R$ 25,90".

**Implicação pro slice 4 (Stripe Pix paywall):** sem mudanças vs ADR-0030 original. Spec slice 4 não precisa reabrir decisão de pricing model.

---

## §13 — Ambiguidades pendentes + protocolo de resolução (audit 2026-05-26)

> **Por que existe esta seção:** auditoria identificou **6 ambiguidades** que afetam decisões de implementação mas não foram resolvidas empiricamente. Cada uma tem (a) hipótese atual, (b) impacto técnico se hipótese errada, (c) protocolo de resolução (passos exatos pra validar via Maestro MCP), (d) slice afetado.
>
> **Princípio:** **NÃO implementar baseado em hipótese** quando há protocolo de validação executável em ≤30 min. Dispatch `spoke-parity-checker` quando o microsprint correspondente começar.

### §13.C.1 — ✅ RESOLVIDA: Pacotes/Ordem/Tipo disabled (Editar parada)

**Descoberta Empírica (Audit 2026-05-27):**
Os controles de Pacotes, Ordem e Tipo de Parada **nunca estiveram desabilitados na interface real**. O container estrutural da linha (`android.view.View`) possui a propriedade `enabled: false` na árvore da acessibilidade do sistema por particularidades do framework de UI usado pelo Spoke, o que causou o falso positivo de "disabled" na inspeção estática da árvore de acessibilidade. No entanto, os elementos filhos internos (botões segmentados "Primeira" / "Coleta" e os seletores do stepper "+") estão com `clickable: true` e `enabled: true`.

*Validação executada via Maestro (Samsung M54):* 
- Adicionadas paradas de teste e executado o script `test_clicks.yaml`. Os cliques em "Primeira" (Ordem), "Coleta" (Tipo) e no stepper "+" de Pacotes foram efetuados com sucesso.
- O app mudou de estado imediatamente na interface (Ordem atualizada para "Primeira", Tipo para "Coleta" e contagem de Pacotes incrementada para "2").

**Decisão RotPro:** 
Implementar estes controles de parametrização de paradas sempre ativos e interativos por padrão desde o primeiro rascunho de rota (sem lógica de gating ou pré-requisitos complexos).

---

### §13.C.2 — ✅ RESOLVIDA: "Detalhes da rota" (§10.4) — FTUE one-time ou per-route?

**Descoberta Empírica (Audit 2026-05-27):**
Trata-se de um comportamento de **FTUE one-time** (First Time User Experience). Ao configurar a primeira rota do app, a tela de parametrização "Detalhes da rota" (que contém configurações gerais de partida/chegada e pausas) é exibida. Manter a opção "Salvar como padrão" ativada (comportamento padrão) persistirá essas preferências globalmente. Nas rotas criadas subsequentemente, a tela é pulada automaticamente, direcionando o usuário diretamente ao mapa ativo com a rota gerada.

**Decisão RotPro:**
Visando máxima eficiência e simplicidade no fluxo de uso do motorista de entrega (evitando fricção na criação de rotas cotidianas), a tela "Detalhes da rota" será **pulada inteiramente** no wizard de criação de rota do Slice 2. Hardcodaremos valores padrão sensatos (como partida/chegada no local atual e sem pausas intermediárias fixas), economizando tempo de desenvolvimento de sub-telas complexas que não agregam valor essencial ao MVP.

---

### §13.C.3 — ✅ RESOLVIDA: "Instruções de acesso" tap não abriu (§11.1) — UI real desconhecida

**Descoberta Empírica (Audit 2026-05-27):**
Foi confirmado um bug na versão inspecionada do Spoke (v3.65.1). Ao interagir com o elemento correspondente de coordenadas `(296, 638)`, o clique é registrado com sucesso pelo sistema de acessibilidade, mas nenhuma ação visual é disparada, impossibilitando a exibição da UI nativa do Spoke para esta função.

**Decisão RotPro:**
Dado o bug no app de referência, a equipe da Roteirizador Pro definiu a especificação de interface de forma autônoma e aderente aos requisitos funcionais descritos na documentação geral:
- Implementar como um **Bottom Sheet customizado** acionado a partir da tela de "Editar parada".
- Conter um campo multiline (`TextField` com 4 a 6 linhas) para inserção das notas e instruções específicas do endereço.
- Incluir a opção checkbox *"Salvar como padrão para este endereço"*, acionando o comportamento **sticky-to-address** no banco de dados local/remoto para persistência automática em rotas futuras que visitem a mesma coordenada/endereço.
- CTAs claros de "Cancelar" e "Salvar".

---

### §13.C.4 — 🟢 MENOR: "Refinar" CTA pós-otimização (§10.9) — opções desconhecidas

**Hipótese atual:** abre sheet com opções pra ajustar otimização (checkboxes/sliders pra priorizar tempo/distância/etc.).

**Impacto:** se Refinar é só "re-roda solver com mesmo input" (sem opções), RotPro implementa com 1 botão simples. Se abre UI complexa, é tela inteira nova.

**Protocolo de resolução (5 min):**

```
PASSO 1: rota teste com ≥3 paradas, otimizar
PASSO 2: no estado §10.9 (pre-confirm), tap "Refinar"
PASSO 3: documentar UI que abre (sheet? tela nova? confirm modal?)
PASSO 4: se houver opções, drillar cada uma
```

**Slice afetado:** Slice 3 backend (solver opções) + Slice 3 UI (Refinar tela).

**Decisão recomendada se ambíguo:** implementar Refinar como **simples re-run do solver** (1 botão); evoluir se cliente pedir.

---

### §13.C.5 — 🟢 MENOR: "Compartilhar cópia" vs "Transferir paradas" (§6.4 itens 1 e 2) — overlap

**Hipótese atual:** #1 = compartilhar rota inteira; #2 = mover paradas selecionadas pra outra rota.

**Impacto:** se overlap real, RotPro pode unificar como uma feature; se distintos, são 2 features separadas.

**Protocolo de resolução (10 min):**

```
PASSO 1: rota teste com ≥2 paradas
PASSO 2: kebab → tap "Compartilhar cópia da rota"
  Documentar UI (QR code? link? share sheet?)
PASSO 3: kebab → tap "Transferir paradas"
  Documentar UI (lista pra selecionar? target picker?)
PASSO 4: comparar — são fluxos diferentes ou variants?
```

**Slice afetado:** Slice 3 follow-up ou Pós-M2 (per §12 B.5).

**Decisão recomendada:** drillar quando slice respectivo chegar; até lá, mapear conceitualmente como 2 features distintas.

---

### §13.C.6 — ~~Decisão de pricing model RotPro~~ (REMOVIDA — já fechada)

> **⚠️ Audit 2026-05-26 (revisão):** esta seção foi REMOVIDA porque foi escrita por engano. Modelo de monetização já está fechado com cliente há muito tempo per [ADR-0030](../decisions/0030-stripe-pix-30-day-access-pass.md) + [`docs/BUSINESS-RULES.md`](../BUSINESS-RULES.md): single paid tier R$ 25,90/30 dias via Stripe Pix; trigger paywall em "Iniciar Navegação"; APK-only per ADR-0014. Ver §12 B.10 pra detalhes consolidados.

---

### §13 — Resumo executivo dos gaps por status

| Severidade | Quantidade | Quando resolver |
|---|---|---|
| 🔴 Crítica (bloqueia spec) | 1 (C.1) | **ANTES de spec Slice 2 Editar parada** (30 min Maestro) |
| 🟡 Moderada (afeta arquitetura) | 2 (C.2, C.3) | Resolver antes do microsprint respectivo (Detalhes da rota / Instruções de acesso) |
| 🟢 Menor (afeta UI detalhe) | 2 (C.4, C.5) | Drillar no microsprint que tocar a feature |

**Princípio operacional:** invocar `spoke-parity-checker` no D1 brainstorming de cada microsprint resolve C.1-C.5 just-in-time. Nenhuma decisão de produto pendente — todas as decisões de pricing/monetização/distribuição já estão em ADR-0030 + ADR-0014 + BUSINESS-RULES.md.

---






