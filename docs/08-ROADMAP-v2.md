# 08 — Roadmap v2 (fonte única · reescrito limpo 2026-06-06)

> **Esta é a fonte única de verdade do M2.** Reescrita limpa em 2026-06-06 sincronizada com o código real (não com descrições antigas). Versões anteriores: `docs/archive/2026-05-26-08-ROADMAP-v1-pre-pivot.md` (pré-pivot) e o histórico git desta `-v2` (reset 2026-05-26 → rewrite 2026-05-27 → esta limpeza 2026-06-06).
>
> **Estratégia (inalterada):** white-label funcional 100% do **Spoke Route Planner B2C** dentro da nossa stack. Quando funcionalmente equivalente, Eduardo aplica polish de identidade visual (microcopy PT-BR original + decoração). NÃO clonar o **Spoke Dispatch** (produto B2B de frota/dispatcher) — ver §"Fronteira B2C/B2B" abaixo.

## Stack travada

| Camada | Tech | Versão real instalada |
|---|---|---|
| Mobile | Flutter + Riverpod 3 (`@riverpod` codegen) + GoRouter + Material 3 | **Flutter 3.44.0 / Dart 3.12.0** (floor pubspec `>=3.24.0`) |
| Pacotes-chave | `flutter_riverpod` 3.0.0 · `go_router` 14.6.0 · `google_maps_flutter` 2.17.1 · `flutter_lints` 5.0.0 + `custom_lint` + `riverpod_lint` | |
| Backend | Node 20 LTS + Fastify v5 + TypeBox + Prisma 7 + PostgreSQL 16 | |
| Routing | GraphHopper self-hosted SP-Capital | |

> ⚠️ **3 breaking changes pós-cutoff (Flutter 3.44) que um implementador com cutoff Jan-2026 vai errar** — sempre verificar contra Dart MCP, não memória:
> 1. `ReorderableListView.onReorderItem` substitui `onReorder` (correção de índice automática) — **Área 7**.
> 2. `RadioGroup<T>` ancestral substitui `groupValue`/`onChanged` por-Radio — **Áreas 10/11**.
> 3. `AsyncValue` é selada → `switch` exaustivo sem `default` — **Áreas 7/8/9**.

## Restrições técnicas constantes

- **Distribuição:** APK-only per [ADR-0014](./decisions/0014-android-release-signing.md) (sem Play Store no M2).
- **Cobertura geográfica:** SP-Capital only per [ADR-0008](./decisions/0008-graphhopper-routing.md) + [ADR-0016](./decisions/0016-map-and-tile-policy.md).
- **Monetização:** tier único R$ 25,90 / 30 dias via Stripe Pix per [ADR-0030](./decisions/0030-stripe-pix-30-day-access-pass.md) + [`docs/BUSINESS-RULES.md`](./BUSINESS-RULES.md). Trigger paywall = tap em **"Navegar"** no modo delivery (NÃO "Otimizar rota" — otimização é grátis). Sem free trial.
- **Tokens visuais (per [ADR-0035](./decisions/0035-spoke-functional-clone-prototype-creative-reference.md)):** cores, spacing, radii, shadows, typography, ícones Lucide vêm de [`prototipo/tokens.js`](../prototipo/tokens.js) desde commit 1. Polish final só substitui microcopy + decoração.

## Fontes de verdade

- **Comportamento/UX/estrutura:** Spoke ao vivo (M54) + catálogo [`docs/inventory/2026-05-26-spoke-vs-rotpro.md`](./inventory/2026-05-26-spoke-vs-rotpro.md) (§10/§11/§12/§13). Em dúvida → dispatch `spoke-parity-checker`.
- **Identidade visual:** `prototipo/tokens.js` + `prototipo/ui.jsx`.
- **Tiebreaker:** cliente Ueslei.

## Fronteira B2C vs B2B (o que NÃO clonar)

Spoke ships dois produtos. Clonamos só o **Route Planner (B2C, motorista solo)**. NÃO clonamos o **Spoke Dispatch (B2B, frota/dispatcher)**: atribuir paradas a outros motoristas, GPS tracking de frota, gestão de equipe/membros, notificações automáticas ao cliente final, páginas de rastreio pro destinatário, dashboards de analytics de equipe, billing por assento. **B2C confirmado por doc oficial (NÃO cortar):** time-window e priority por parada são features do Route Planner solo. A única feature B2B do inventário (max-stops-per-plan) já foi cortada (ADR-0030).

> A sprint de reestruturação (`docs/superpowers/{specs,plans}/2026-06-06-restructure-b2c-clarity-and-harden.md`) cria o boundary doc canônico `docs/inventory/2026-06-06-spoke-b2c-vs-b2b-boundary.md` + ADR-0044. **Esse doc ainda NÃO existe** — até existir, decisões de corte usam os marcadores do inventário + diretivas §7.1. 4 widgets nas Áreas 7/9/11 ficam cortados/postergados por essa regra (ver cada área).

---

# Visão geral dos 7 slices

| Slice | O que é | Estado |
|---|---|---|
| **1** | APK distribuível (auth real + landing + GraphHopper + Login/Register + APK assinado) | ✅ shipped 2026-05-13 (`v1.0.0`) |
| **2** | Telas Core Spoke-aligned (white-label funcional 100%) | 🟡 ~55% — Áreas 1–4 prontas, 3+5 parciais, 6–11 não iniciadas |
| **3** | Backend real (solver + geocoding + persistência + FCM + reset senha + Google backend) | ⏳ não iniciado |
| **4** | Stripe Pix paywall (R$ 25,90 / 30 dias, Connect 50/50) | ⏳ não iniciado |
| **5** | Sentido casa (endereço de casa + solver respeita) | ⏳ não iniciado |
| **6** | LGPD (export + excluir conta + privacy + terms + licenças) | ⏳ não iniciado |
| **7** | Painel admin (feature original RotPro — interno, NÃO o dashboard B2B Dispatch) | ⏳ não iniciado |

**Pós-slices:** polish visual final (microcopy PT-BR + decoração + assets + `prototype-fidelity-checker` sweep) → tag `vX.Y.0`.

---

## Slice 1 — APK distribuível ✅ shipped 2026-05-13 (`v1.0.0`)

Backend auth real + landing + GraphHopper SP self-hosted + Login/Register Flutter + APK assinado. Fechado.

---

## Slice 2 — Telas Core Spoke-aligned 🟡 em progresso

> **Sprint dedicada de execução:** [`docs/superpowers/specs/2026-06-06-slice2-completion.md`](./superpowers/specs/2026-06-06-slice2-completion.md) + [`docs/superpowers/plans/2026-06-06-slice2-completion.md`](./superpowers/plans/2026-06-06-slice2-completion.md). A sprint executa cada área restante com disciplina: websearch/Context7 (boas práticas modernas) → dump live fresco da Spoke só daquela área → implementa → valida → integration_test. Este roadmap é o catálogo; a sprint é o passo-a-passo.

### Estado real por área (medido no código 2026-06-06)

| Área | Tela | Estado |
|---|---|---|
| 1 | Auth (Login/Register) | ✅ pronto · ⏳ falta UI de recuperar-senha + botão Google |
| 2 | Drawer + lista + wizard + 3-dot popup + reutilizar paradas | ✅ pronto |
| 3 | Tela ativa de rota (mapa + sheet) | 🟡 ~80% — controles de mapa e ações kebab/bottom-bar são stubs `_comingSoon` |
| 4 | Adicionar parada (texto) | ✅ pronto (usa Google Places **live**, não stub) · ⏳ OCR/Voz/tap-mapa são stubs (Área 7/5) |
| 5 | Detalhes da rota (Partida/Destino/Pausa) | 🟡 MS1–MS5+MS-FIX+MS6 Pausa prontos · ⏳ MS7 wire-rows, MS8 persistência+FTUE, MS9 integration_test+PR abertos |
| 6 | Editar parada (sheet, 14 campos) | ⏳ não iniciada |
| 7 | Otimizar rota (3 estados + 3 modais FTUE) | ⏳ não iniciada |
| 8 | Modo Delivery (running route) | ⏳ não iniciada |
| 9 | Conclusão de rota + telas core (ShareSheet, kebab, reordenar, RoutesList) | ⏳ não iniciada |
| 10 | Settings completas (13 rows) | ⏳ não iniciada |
| 11 | Notification settings (UI stub) | ⏳ não iniciada |

### Ordem de execução (forçada por dependências — NÃO é livre)

```
[em andamento]  Finalizar Área 5 (MS6 Pausa → MS7 wire rows → MS8 persistência+FTUE → MS9 integration_test+PR)
       │        Finalizar gatilhos da Área 3 (Otimizar CTA, tap no stop card, kebab/bottom-bar)
       ▼
   Área 6 (Editar parada)  ──► chips A1/A2 e lista inline dependem dela
       ▼
   Área 7 (Otimizar rota)  ──► "Iniciar rota" é o gateway pra Área 8
       ▼
   Área 8 (Modo Delivery)  ──► estado terminal alimenta Área 9
       ▼
   Área 9 (Conclusão + telas core)

[independentes — intercalar a qualquer momento]
   Área 1 (auth UI leftovers — SEM baseline Spoke, não dispatch parity-checker)
   Área 10 (Settings) ──► DEVE preceder Área 11 (row Notificações vive dentro de Settings)
   Área 11 (Notifications — SEM baseline Spoke, UI original derivada da diretiva #9)
```

> **2 áreas SEM equivalente Spoke** (Área 1 auth-leftovers + Área 11 notifications): NÃO dispatch `spoke-parity-checker` (não há o que inspecionar). São UI original/derivada — spec por inferência declarada, não por parity.

### Gates do Slice 2 (pré-existentes que bloqueiam "Done")

- [ ] `flutter analyze` clean — hoje **23 lints pré-existentes** (reuse_stops_page ×11, add_stop_map_page ×5, places_repository ×4, drawer ×2, test ×1). A sprint inclui um MS de burn-down OU aceita explicitamente fora-de-escopo.
- [ ] `apps/mobile/integration_test/` existe — hoje **ABSENTE** (gate blocking; várias áreas tocam navegação). 1º teste a criar: `area5_route_details_flow_test.dart` (Área 5 MS9).
- [ ] `flutter test` ≥ 249 (baseline atual).

### Área 1 — Auth (completar UI) · independente · SEM baseline Spoke

- [ ] **Recuperação de senha (UI)** — tela `/auth/forgot-password` (campo email + CTA "Enviar link"). Backend Slice 3. Hoje: SnackBar "em breve" em `login_page.dart:223`.
- [ ] **Google Sign-In (UI)** — botão "Continuar com Google" em `/login` + `/register`. Backend Slice 3. Apple+Facebook cortados (diretiva #2).

### Área 2 — Rotas (drawer + lista + wizard) ✅ pronto

Drawer (90% width, scrim, sem swipe-from-edge) + lista agrupada por 4 períodos dinâmicos + 3-dot popup (Definir nome e data / Duplicar / Excluir) + wizard criar/editar (reusado por `:routeId` path param) + tela Reutilizar paradas. Detalhe inventory §6.2 + §10.1–10.3 + §11.3/§11.6. **Duplicar/Excluir rota e Reutilizar paradas dependem de backend (Slice 3) pra persistir.**

### Área 3 — Tela ativa de rota (mapa + sheet) 🟡 ~80%

Pronto: GoogleMap base + DraggableScrollableSheet 3-snap (direction-based snap) + lista de stops + rows de config inline + hamburger flutuante → drawer. **Falta wirar (a sprint termina antes de 6/7/9):**

- [ ] **Controles de mapa** (layer toggle + recenter) — hoje visual-only stub (`route_shell_page.dart:17`, SnackBar `:205`).
- [ ] **CTA "Otimizar rota"** sticky bottom → entra na Área 7. Hoje stub.
- [ ] **Tap no stop card** → abre Área 6 (edit-stop sheet). Hoje SnackBar (`add_stop_page.dart:103`).
- [ ] **Kebab + bottom-bar actions** → Área 9 surfaces. Hoje `_comingSoon` (`:483`).

> Layout crítico (lição travada): mapa + sheet em `Column { Expanded(GoogleMap), sheet }`, NUNCA `Stack` (o PlatformView do GoogleMap ganha toda arena de gesto).

### Área 4 — Adicionar parada (texto) ✅ pronto · demais métodos stub

Pronto: texto + autocomplete via **Google Places API live** (`places_repository.dart` — não é stub; herda dependência de API key em runtime). Sealed `AddStopUiState` 5-branch. **Stubs (cada um em PR isolado):**

- [ ] **OCR single-stop** (`/stops/ocr`, ML Kit) — Área 7 / PR isolado.
- [ ] **Voz single-stop** (`/stops/voice`, `speech_to_text` locale pt_BR) — Área 7 / PR isolado.
- [ ] **Tap no mapa** (`add_stop_map_page.dart` — hoje grey-box mock `:26`, reverse geocode não wirado) — Área 5 / PR isolado.
- [ ] **CSV upload** — Slice 3.

### Área 5 — Detalhes da rota 🟡 MS1–MS5+MS-FIX prontos

Pronto (branch `feat/m2-slice-2-area-5-route-details`): shell (X flutuante, h1 body-level, sem AppBar) + Partida picker + TimePickerSheet **numpad 4×3** (ADR-0042, pivot do wheel ADR-0041) + Destino **bottom sheet 3-cards** (ADR-0043 — `RoundTrip` "Voltar ao ponto de partida" / `SpecificAddress` "Destino em outro endereço" / `NoDestination` "Não usar destino"; `BackToStart` removido) + Concluído sempre habilitado + checkbox "Salvar como padrão" **UNCHECKED** (ADR-0043 §Q8). **Falta:**

- [x] **MS6 Sub-tela Pausa** ✅ (2026-06-09, ADR-0044) — página full-screen "Configure a pausa" (NÃO sheet): janela de horário Entre/E (default 08:00–15:00) via numpad reusado + duração em minutos (dialog numérico, default 30; NÃO chips). `BreakConfig` virou janela (`fromTime`/`toTime`/`durationMinutes`). SnackBar interino removido. 261 testes.
- [ ] **MS7 Wire rows da Área 3** — as 3 rows de config inline (Início / Ida e volta / Pausa) clickáveis → reabrem sub-telas.
- [ ] **MS8 Persistência + FTUE** — `SharedPreferencesAsync` envelope `route_defaults_v1` + trigger FTUE. Re-confirmar Q8 "Salvar como padrão" default vs Spoke fresh.
- [ ] **MS9 integration_test + D4 + PR** — `area5_route_details_flow_test.dart` (5-route Android-back chain) + spoke-parity D4 + Maestro YAML + PR.

> Nota §13.C.2 RESOLVIDA: "Detalhes da rota" é FTUE one-time (rotas seguintes vão direto pro sheet). RotPro pode pular a tela no wizard com defaults sensatos.

### Área 6 — Editar parada (sheet, 14 campos) ⏳ depende de Área 3 (tap stop card) + Área 4 (Mudar endereço reusa add-stop)

`DraggableScrollableSheet` (NÃO route GoRouter; Área 4 e 6 compartilham a route `/home/routes/add-stop`). Topbar: Ajuda (esq) + "Editar parada" + "Concluído" primary (save+pop). Campos: chip cor (sheet 5 cores) · chip package-ID "A1" (display pós-otimização) · card endereço read-mostly · botão "Instruções de acesso" (2º sheet, **sticky AO ENDEREÇO** não à parada — §13.C.3 resolvida) · notas + camera attach · "Localizador de pacotes" · stepper Pacotes · SegmentedButton Ordem (Primeira/Automática/Última) · SegmentedButton Tipo (Entrega/Coleta) · "Horário de chegada" (B2C) · "Tempo estimado na parada" (default do setting global) · "Mudar endereço" · "Duplicar parada" · "Remover parada" (VERMELHO + AlertDialog confirm). Detalhe §10.6 + §11.1 + §11.5. **§13.C.1 RESOLVIDA: Pacotes/Ordem/Tipo sempre ativos.** SEM picker de razão de falha (é Dispatch B2B).

### Área 7 — Otimizar rota (3 estados + 3 modais FTUE) ⏳ depende de Área 6 (chips) + Área 3 (CTA Otimizar)

Funil: modal FTUE "IDs ajustados" → estado PRE-CONFIRM (mapa metade + polyline + markers 1-N + sheet mid + summary "X min · N paradas · D km" + 3 CTAs: X min verde / Refinar / Confirmar) → modal FTUE "IDs definitivos" → modal FTUE "Carregar veículo?" → estado **Ready-to-Run** (CTAs: X min verde / Editar / **Iniciar rota** = gateway pro modo delivery). 3 flags FTUE em SharedPrefsAsync. Otimização é **grátis** (paywall só em "Navegar"). Detalhe §10.8–10.12.

- ⚠️ **CORTADO (B2B-adjacent):** "Compartilhar rota em tempo real" (live tracking pro cliente final) — OUT-OF-SCOPE Slice 2; postergado.
- ⚠️ **OUT-OF-SCOPE M2:** "Carregar veículo" (Load vehicle).
- 📌 **§13.C.4 PENDENTE:** opções do "Refinar" não inspecionadas. Live-inspect no MS; fallback = re-run simples do solver (1 botão), registrado como decisão explícita.
- 🔧 Usar `ReorderableListView.onReorderItem` (3.44), não `onReorder`.

### Área 8 — Modo Delivery (running route) ⏳ depende de Área 7 (Iniciar rota)

Foco em UMA parada por vez. Mapa metade superior centrado na parada atual (following) + sheet mid (h1 nome rua + X close + subtitle "N/total, HH:MM"). **3 botões status (conditional por `Stop.type`):** "Navegar" (filled BLUE, sempre, handoff `url_launcher` geo: URI) · "Não entregue" (sempre, marca Failed **silenciosamente** + auto-advance, SEM picker de razão — §10.14) · "Entregue" (se delivery) / "Coletado" (se pickup). Lista inline + marker encoding por status. Estado "Destino final" (retorno Ida e volta): só 2 botões. **PAYWALL TRIGGER:** 1º "Navegar" verifica `user.isPaid` (Slice 4). Detalhe §10.13–10.17.

- 🔧 `AsyncValue.guard` pras mutações de status; `switch` exaustivo na AsyncValue selada.
- 🔧 Mapa following com `_followUser` flag + `distanceFilter`; pausar camera no pan do usuário.

### Área 9 — Conclusão + telas core ⏳ depende de Área 8 (estado terminal)

- [ ] **Tela "Rota concluída!"** — markers congelados + summary + card central (check verde + stats "N paradas · M perdida") + CTA "Copiar paradas para nova rota". Spoke conta só Failed em "perdida". Reabrível trivialmente. Detalhe §10.18.
- [ ] **Kebab da rota concluída** — 3 opções do drawer. **RotPro oportunidade:** 4º item "Compartilhar resumo" (alinha ScreenShare). §10.20.
- [ ] **Reordenar paradas** — `ReorderableListView.onReorderItem` no sheet expanded. §10.5.
- [ ] **ShareSheet** (feature original RotPro, apagada no reset) — `/settings/share`: WhatsApp + copy link + QR. §4.
- [ ] **Menu kebab da rota ativa** — bottom sheet 5 opções. Slice 2: existe mas opções abrem "Em breve". §6.4.
- [ ] **RoutesListPage** — surface alternativa ao drawer. §6.2.

⚠️ **CORTADAS (B2B-adjacent, postergadas pós-M2):** "Compartilhar cópia da rota" (peer transfer driver-to-driver) + "Transferir paradas" — §6.4. 📌 **§13.C.5 PENDENTE** (semântica das duas).

### Área 10 — Settings completas (13 rows) ⏳ independente · precede Área 11

`ListView` + `ListTile`/`SwitchListTile.adaptive` + section headers (equivalente ao PreferenceActivity do Spoke). **Pickers radio: usar `RadioGroup<T>` ancestral (3.44), não groupValue por-Radio.**

- **Preferências de rota (7):** App de navegação (radio: GoogleMaps/Waze/Outro — NÃO Yandex nem "Navegação do Spoke") · Lado da parada (Qualquer/Direito/Esquerdo) · Tempo médio na parada (1/2/3/5/10/custom — alimenta default da Área 6) · Tipo de veículo (5 opções; Caminhão grande NÃO suportado) · Evitar pedágios (switch OFF) · ID de parada (Formato Moderno/Clássico + Atribuir Depois/Conforme) · Balão do modo de navegação (switch — disabled/removido se sem navegação interna; decidir no MS).
- **Assinatura (1):** Comparar planos — tela informacional do pass único R$ 25,90 (NÃO picker de tiers). Abre paywall (Slice 4).
- **Rodapé legal:** Endereço de casa (stub, real Slice 5) · Indicações (→ ShareSheet) · Licenças (Slice 6) · Privacidade (Slice 6) · Termos (Slice 6) · Versão (display) · **Sair** (VERMELHO).
- ❌ **Tema:** DESCARTADO (tema único). Section "Preferências gerais" removível.

Detalhe §10.19 + §10.6.1.

### Área 11 — Notification settings (UI stub) ⏳ depende de Área 10 · SEM baseline Spoke

Tela `/settings/notifications` (row dentro de Settings). 3 toggles persistidos em SharedPrefsAsync: "Lembrete início rota" / "Atualização de status" / "Promoções". FCM real é Slice 3. **NÃO há baseline Spoke** (derivada da diretiva #9 + plano FCM). 📌 Confirmar com Eduardo: "Atualização de status" = self-notification (B2C), NÃO notificar cliente final (B2B).

### ✅ Slice 2 "Done"

Todas as Áreas 1–11 ✅ + `flutter analyze` clean (23 lints zerados) + `flutter test` verde + `integration_test/` existe e passa no M54 + smoke E2E release contra prod API. PR `feat/m2-slice-2-spoke-clone` → tag `v1.1.0`.

---

## Slice 3 — Backend real (Spoke parity) ⏳

Troca todos os stubs/mocks do Slice 2 por implementação real. Fastify v5 + TypeBox + Prisma 7 + PostgreSQL 16 + GraphHopper + Nominatim SP + FCM.

- [ ] **`POST /routes/optimize` real** — solver in-process (nearest-neighbor + 2-opt) contra GraphHopper matrix. <2s pra ≤20 paradas. Constraints: start/end_time, time_windows (per stop), priority (per stop), avoid_tolls, vehicle_profile, home_address (Slice 5). Hoje é **mock** (`apps/backend/src/routes/routes.ts:13` — devolve ordem de entrada, métricas zeradas).
- [ ] **`POST /geocode`** — proxy Nominatim SP-Capital + cache Redis 24h.
- [ ] **Routes/Stops/Addresses schema** — migrations Prisma (Stops inclui `time_window_*`, `priority`, `custom_stop_duration_min`, `pod_photo_url`; Addresses inclui `access_instructions` sticky-ao-endereço per Área 6).
- [ ] **Reutilizar paradas** (`POST /routes/:id/copy-stops`) + **Duplicar rota** (`POST /routes/:id/duplicate`).
- [ ] **Reset senha** (`POST /auth/forgot-password` + `/reset-password`) + **Google Sign-In backend**.
- [ ] **FCM push** — Firebase Admin SDK, 3 tópicos (route_reminders/status_updates/promotions).
- [ ] **Multi-stop Voz + OCR** (dictation N endereços + "ler manifesto").
- [ ] **CSV import** (`POST /routes/:id/import-stops`) + CSV export (opcional).

---

## Slice 4 — Stripe Pix paywall ⏳

Per [ADR-0030](./decisions/0030-stripe-pix-30-day-access-pass.md) + [`docs/BUSINESS-RULES.md`](./BUSINESS-RULES.md). Modelo fechado.

- [ ] **Stripe Connect** (conta RotPro + connected do cliente, Separate Charges and Transfers 50/50).
- [ ] **`POST /payments/create-pix-intent`** (QR + copia-e-cola) + **`POST /webhooks/stripe`** idempotente (`payment_intent.succeeded` → `User.paidUntil = now()+30d`).
- [ ] **Modal paywall** (full-screen, R$ 25,90 + QR + polling status).
- [ ] **Trigger logic** (`PaywallController` checa `paidUntil` antes de "Navegar") + **server-side enforcement** (middleware 402).
- [ ] **Modal upsell contextualizado** (ex-Área 12 — "{userFirstName}, chegar cedo a casa." + "Motoristas de {userCity}..."). Trigger: após otimizar se nunca pagou.

---

## Slice 5 — Sentido casa ⏳

- [ ] **Backend constraint** — solver respeita `user.homeAddress` como end-point quando `route.endNearHome == true`.
- [ ] **UI toggle por rota** — switch em Detalhes da rota (Área 5) "Terminar próximo de casa" (default false). Campo "Endereço de casa" já stubbed na Área 10.

---

## Slice 6 — LGPD ⏳

- [ ] **Exportar dados** (`GET /users/me/export`) · **Excluir conta** (`DELETE /users/me`, RED + double confirm, cascade + audit) · **Privacidade** + **Termos** (telas in-app Markdown) · **OSS licenses** (`flutter_oss_licenses`).

---

## Slice 7 — Admin panel ⏳ (feature ORIGINAL RotPro — NÃO o dashboard B2B Dispatch)

Subapp Next.js em `apps/admin/` (ou expansão de `apps/landing/`). Auth separada (admin role). Ferramenta interna pros 2 sócios — NÃO exposta ao motoboy, NÃO é o dashboard de frota do Spoke Dispatch.

- [ ] MRR (`payments.amount * 0.5`) · Usuários ativos (7d) · Paradas processadas/mês · Rotas otimizadas/mês · Taxa de conversão paywall.

---

## Bloqueios conhecidos (ler inventory §13)

| Item | Severidade | Estado | Bloqueia |
|---|---|---|---|
| §13.C.1 Pacotes/Ordem/Tipo gating | 🔴 | ✅ RESOLVIDO — sempre ativos | Área 6 |
| §13.C.2 Detalhes da rota FTUE? | 🟡 | ✅ RESOLVIDO — FTUE one-time | Área 5 |
| §13.C.3 Instruções de acesso UI | 🟡 | ✅ RESOLVIDO — 2º sheet sticky-ao-endereço | Área 6 |
| §13.C.4 "Refinar" CTA opções | 🟢 | 📌 PENDENTE — drillar no MS Área 7 | Área 7 |
| §13.C.5 Compartilhar cópia vs Transferir | 🟢 | 📌 PENDENTE — ambas postergadas | Área 9 |

---

## Validação contínua (subagents + gates)

- **`spoke-parity-checker`** ([ADR-0036](./decisions/0036-spoke-parity-checker-functional-gate.md)) — dispatch UPFRONT (baseline estrutural com tabela `bounds|desc|padrão|widget`, exigir screenshot pixels pra ícones Compose) + D4 closing. **NÃO** pra Áreas 1 e 11 (sem baseline Spoke).
- **`flutter-test-author`** ([ADR-0025](./decisions/0025-flutter-test-author-subagent.md)) — antes de widget/provider/service novo (TDD opcional).
- **`flutter-perf-auditor`** — após terminar tela, antes do PR (9-check read-only).
- **`adr-guardian`** — antes de PR que toca stack (pubspec/package.json/schema).
- **`prototype-fidelity-checker`** — SÓ no polish visual final.
- **Hooks automáticos:** `block-env` (PreToolUse, blocking), `format-dart` + `run-riverpod-codegen` (PostToolUse), `analyze-changed-dart` + `check-dto-mirror` + `warn-adr-drift` (Stop, signal-only).
- **M54 E2E** em cada PR substancial: `bash apps/mobile/scripts/build-release-apk.sh` (já wira `--dart-define`).

---

## Polish visual final (pós Slices 2–7)

Microcopy PT-BR original + diferenciações decorativas + assets finais (splash/icon/ilustrações) + `prototype-fidelity-checker` full sweep + revisão humana. Identidade base (cores/tipografia/ícones Lucide) já aplicada desde Slice 2 commit 1.

---

## Princípios operacionais

- Spoke decide comportamento/UX; prototipo decide visual; cliente desempata.
- **Live-inspect por feature no momento da implementação** — baseline de sessão anterior (mesmo existindo, não-zero, nomeado certo) NÃO é confiável (falhas MS4/MS5). Ordem: mapear → live-inspect → implementar → validar.
- **Zero tech debt por área** — nunca deferir divergência com `// TODO`/`// MS9`; corrigir no mesmo MS ou escalar como BLOCKED.
- Sem placeholders de cor/ícone "pra ajustar depois" — tokens prototipo desde commit 1.
- Tokens 3.44 (não memória Jan-2026): `onReorderItem`, `RadioGroup<T>`, `AsyncValue` selada.
