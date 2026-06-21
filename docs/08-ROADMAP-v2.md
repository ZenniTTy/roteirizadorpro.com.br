# 08 — Roadmap v2 (fonte única · eixo afiado 2026-06-20 · ADR-0052)

> **Esta é a fonte única de verdade do M2.** Reescrita limpa em 2026-06-06 sincronizada com o código real; **eixo afiado em 2026-06-20 (ADR-0052)** após o audit retroativo de paridade (`docs/audits/2026-06-20-dump-parity-retro-audit.md`). Versões anteriores: `docs/archive/2026-05-26-08-ROADMAP-v1-pre-pivot.md` (pré-pivot) e o histórico git desta `-v2`.
>
> **Estratégia (afiada 2026-06-20, [ADR-0052](./decisions/0052-faithful-dump-clone-and-per-phase-investigation.md)):** **CÓPIA FIEL COMPLETA** do **Spoke Route Planner B2C** dentro da nossa stack — front (layout/estrutura/hierarquia) e funcionalidade (fluxos/estados/gates/fallbacks) **idênticos** ao dump, reimplementados com as práticas mais modernas da nossa stack. A barra não é mais "modelar parecido", é **copiar fielmente**. **Identidade visual original (cores/ícones/tipografia + wording da microcopy) é a ÚLTIMA camada** (polish final, ADR-0035); até lá, cada string é fiel em SIGNIFICADO ao dump (proibido inventar capacidade que o app não tem). **Zero divergência deferida.** NÃO clonar o **Spoke Dispatch** (B2B) — ver §"Fronteira B2C/B2B".

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

- **Estrutura/fatos (O QUÊ existe — dump-first, ADR-0045):** [`docs/inventory/spoke-dump-v3.65.1/MASTER-TABLE.md`](./inventory/spoke-dump-v3.65.1/MASTER-TABLE.md) — dump estático do Spoke v3.65.1 (campos, defaults, enums, strings PT-BR verbatim, pacote de código das 20 telas antes "Não drilled"). **Consultar ANTES de qualquer inspeção runtime.**
- **Comportamento/UX dinâmico (COMO se comporta — confirma o dump):** Spoke ao vivo (M54) + catálogo [`docs/inventory/2026-05-26-spoke-vs-rotpro.md`](./inventory/2026-05-26-spoke-vs-rotpro.md) (§10/§11/§12/§13). Dispatch `spoke-parity-checker` para CONFIRMAR as hipóteses da MASTER-TABLE onde o campo `Precisa-runtime` indicar, não para descobrir do zero.
- **Identidade visual:** `prototipo/tokens.js` + `prototipo/ui.jsx`.
- **Tiebreaker:** cliente Ueslei.

## Fronteira B2C vs B2B (o que NÃO clonar)

Spoke ships dois produtos. Clonamos só o **Route Planner (B2C, motorista solo)**. NÃO clonamos o **Spoke Dispatch (B2B, frota/dispatcher)**: atribuir paradas a outros motoristas, GPS tracking de frota, gestão de equipe/membros, notificações automáticas ao cliente final, páginas de rastreio pro destinatário, dashboards de analytics de equipe, billing por assento. **B2C confirmado por doc oficial (NÃO cortar):** time-window e priority por parada são features do Route Planner solo. A única feature B2B do inventário (max-stops-per-plan) já foi cortada (ADR-0030).

> A sprint de reestruturação (`docs/superpowers/{specs,plans}/2026-06-06-restructure-b2c-clarity-and-harden.md`) cria o boundary doc canônico `docs/inventory/2026-06-06-spoke-b2c-vs-b2b-boundary.md` + ADR-0044. **Esse doc ainda NÃO existe** — até existir, decisões de corte usam os marcadores do inventário + diretivas §7.1. 4 widgets nas Áreas 7/9/11 ficam cortados/postergados por essa regra (ver cada área).

## Método de cópia fiel (dump-first por fase) — ADR-0052

> O dump é Android/Kotlin/Compose; nós somos Flutter. **Copiar ≠ copy-paste — é reimplementar fielmente o O QUÊ com o idiom moderno da nossa stack.** Cada Área futura (Á8+) e cada bloco de remediação seguem este gate, na ordem.

**Gate obrigatório por fase/área (não pular nenhum passo):**

1. **Investigação dump-first da ÁREA INTEIRA, ANTES de implementar.** Esgotar o dump da área num doc de design: fluxos + estados + gates + fallbacks + strings verbatim (`values-pt-rBR`) + pacote de código (`~/spoke-dump/jadx-out`). É o ADR-0045 **por área, não por microsprint** (memória `feedback_dump_map_per_area_before_implementing`). Runtime só onde `Precisa-runtime` indicar (D4 dump-only, ADR-0049).
2. **Implementar com a tradução moderna** (tabela abaixo) + validação **Dart MCP first** (símbolos instalados) → **Context7/WebSearch** (libs/APIs pós-cutoff). **NUNCA websearch para comportamento Spoke** (isso é o dump — ADR-0048).
3. **Cuidado nomeado com bugs silenciosos, drift, entropia e breaking changes** em cada tradução (o implementador tem cutoff Jan-2026; ver os 3 breaking changes do 3.44 acima).
4. **Validação de fechamento antes de "done":** re-grep do dump pelos enums/strings/gates da área + `spoke-parity-checker` D4 dump-only + testes que **pinam paridade** (enum com lista EXATA, microcopy 1:1 em significado). **Zero divergência deferida** — corrige no mesmo trabalho ou escala BLOCKED.

**Tabela de tradução Spoke (Android) → RotPro (Flutter 3.44 / Riverpod 3):**

| Spoke (Kotlin/Compose/Android) | RotPro (idiom moderno) | Cuidado (silent-bug / breaking change) |
|---|---|---|
| `ViewModel` + `StateFlow`/`MutableStateFlow` | `@riverpod` `Notifier`/`AsyncNotifier` (codegen) | `StateNotifier`/`ChangeNotifier` deprecados; `AsyncValue.guard` p/ mutações |
| `sealed class` de estado | `sealed class` Dart + `switch` exaustivo | **`AsyncValue` é selada (3.44) → `switch` sem `default`** |
| `@Composable` + `remember` | `Widget` + `ref.watch` granular (`.select`) | rebuild scoping; `const` onde der; `RepaintBoundary` em listas |
| Navigation Compose / Fragment destination | GoRouter (shell/branch routes) | **Flutter #155746** (push de sub-branch = no-op silencioso) → returns-intent pattern |
| `RadioButton` group (Compose) | **`RadioGroup<T>` ancestral (3.44)** | NÃO `groupValue`/`onChanged` por-`Radio` |
| `LazyColumn` reorder | **`ReorderableListView.onReorderItem` (3.44)** | correção de índice automática (≠ `onReorder`) |
| `SharedPreferences` / DataStore | `SharedPreferencesAsync` (wrapper em repository) | helper de teste com `tearDown` que restaura o platform instance |
| `R.string.*` (`values-pt-rBR`) | microcopy PT-BR **original, fiel em SIGNIFICADO** | nunca verbatim (ADR-0035); **nunca mentir capacidade** (ex.: "trânsito") |
| Vector/Material Icon | `LucideIcons` (prototipo) | identidade visual original (ADR-0035) |
| Coil image / camera | `image_picker` + `path_provider` (local-only) | Spoke não sobe foto (ADR-0050) |
| `GoogleMap` (Compose overlay) | `google_maps_flutter` em `Column{Expanded(map),sheet}` | NUNCA `Stack` (PlatformView rouba gesto — flutter#105994); `imagePixelRatio` no marker |

---

# Visão geral dos 7 slices

| Slice | O que é | Estado |
|---|---|---|
| **1** | APK distribuível (auth real + landing + GraphHopper + Login/Register + APK assinado) | ✅ shipped 2026-05-13 (`v1.0.0`) |
| **2** | Telas Core Spoke-aligned (cópia fiel completa) | 🟡 ~70% — Á2–Á6 fechadas, Á7 PR-A/B fechados (falta C/D); **Fase R** (remediação do audit 2026-06-20, 100%) → Á8–Á11 |
| **3** | Backend real (solver + geocoding + persistência + FCM + reset senha + Google backend) | ⏳ não iniciado |
| **4** | Stripe Pix paywall (R$ 25,90 / 30 dias, Connect 50/50) | ⏳ não iniciado |
| **5** | Sentido casa (endereço de casa + solver respeita) | ⏳ não iniciado |
| **6** | LGPD (export + excluir conta + privacy + terms + licenças) | ⏳ não iniciado |
| **7** | Painel admin (feature original RotPro — interno, NÃO o dashboard B2B Dispatch) | ⏳ não iniciado |

**Pós-slices:** polish visual final (microcopy PT-BR + decoração + assets + `prototype-fidelity-checker` sweep) → tag `vX.Y.0`.

---

# ⚠️ Fase R — Remediação retroativa de paridade (AGORA, antes da Á8)

> **Bloqueia a Área 8.** Decisão de Eduardo 2026-06-20: remediar **100%** (P0→P3) antes de abrir qualquer área nova (ADR-0052). Backlog completo (36 drifts, evidência impl×dump, fix por item): [`docs/audits/2026-06-20-dump-parity-retro-audit.md`](./audits/2026-06-20-dump-parity-retro-audit.md). **13 must-fix verificados adversarialmente (zero falso-positivo).**

Audit retroativo 2026-06-20 (workflow `wp6fupsv5`, 20 agentes dump-only) sobre as 6 áreas construídas (Á2–Á7): **paridade MÉDIA, dívida concentrada na Á7** (8 dos 13 must-fix — o PR-C inteiro é honest-stub e o usuário trava no PRE-CONFIRM). Esqueleto funcional fiel; nenhuma surpresa arquitetural. 4 blocos, na ordem:

- [ ] **R/P0 — destrava o ciclo de otimização (Á7 PR-C).** `ReadyToRunView` + `Confirmar` grava `confirmed:true` (A7-D5) · `IdLockDialog` one-shot `id_lock_ftue_v1` (A7-D6) · `DiscardChangesDialog` + `PopScope` guard `isEditing` (A7-D7) · "Pular otimização" → Ready-to-Run + banner "Otimização pendente" (A7-D8).
- [ ] **R/P1 — gates e fluxos não-cosméticos (Á2/Á3/Á6/Á7).** Kebab PRE-CONFIRM "Reotimizar rota…"/"Pular otimização" (A7-D4) · CTA wizard "Continuar para copiar paradas" (A2-D2) · 3ª linha "Pausa" no config summary sob gate Breaks (A3-D2) · pop do editor pós-remoção deferida (A6-D1) · gate "única rota" no delete + diálogo "Manter/Redefinir progresso" no duplicar (A2-D4/D3).
- [ ] **R/P2 — sweep de microcopy fiel-em-significado vs `values-pt-rBR` (Á7/Á5/Á2/Á3/Á6).** Fases de progresso sem "trânsito" + sheets Refinar/Reotimizar + diálogos FTUE (A7-D1/D2/D3/D9/D10) · CTAs/diálogos de pausa + subtitles reativos (A5-D1..D5) · 3 labels de seção do drawer (A2-D1) · toasts/semantics/placeholder da Á3 (A3-D1/D3/D5) · "Quer remover" (A6-D3).
- [ ] **R/P3 — nits e forma de apresentação.** debounce 500→800ms + placeholder por `stopCount` (A4-D1/D2) · ícones Lucide no RefineRouteSheet (A7-D11) · PackageCountDialog → bottom sheet (A6-D2) · profile card clickable + decisão drawer lateral (A2-D5/D6/D7). _A4-D3 (edição inline pós-add) permanece escopado p/ Á6 — não antecipar._

**Cada bloco fecha com `spoke-parity-checker` D4 dump-only + testes que pinam paridade.** `flutter analyze` clean (zerar os 23 lints pré-existentes neste passe) + `flutter test` verde + smoke E2E no M54. Só então a Área 8 abre.

---

## Slice 1 — APK distribuível ✅ shipped 2026-05-13 (`v1.0.0`)

Backend auth real + landing + GraphHopper SP self-hosted + Login/Register Flutter + APK assinado. Fechado.

---

## Slice 2 — Telas Core Spoke-aligned 🟡 em progresso

> **Sprint dedicada de execução:** [`docs/superpowers/specs/2026-06-06-slice2-completion.md`](./superpowers/specs/2026-06-06-slice2-completion.md) + [`docs/superpowers/plans/2026-06-06-slice2-completion.md`](./superpowers/plans/2026-06-06-slice2-completion.md). A sprint executa cada área restante com disciplina: websearch/Context7 (boas práticas modernas) → **[Áreas 6–11] consultar a MASTER-TABLE do dump estático (ADR-0045) para as hipóteses estruturais concretas** → dump live fresco da Spoke só daquela área para **CONFIRMAR** (não descobrir greenfield) onde o `Precisa-runtime` indicar → implementa → valida → integration_test. Este roadmap é o catálogo; a sprint é o passo-a-passo.

### Estado real por área (medido no código · atualizado 2026-06-20 pós-audit)

> **Á2–Á7 têm drifts de paridade rastreados na Fase R** (audit 2026-06-20). "✅ fechada" abaixo = construída e mergeada; a fidelidade fina é fechada na Fase R antes da Á8.

| Área | Tela | Estado |
|---|---|---|
| 1 | Auth (Login/Register) | ✅ pronto · ⏳ falta UI de recuperar-senha + botão Google |
| 2 | Drawer + lista + wizard + 3-dot popup + reutilizar paradas | ✅ pronto · 🔧 2 must-fix Fase R (A2-D1/D2) |
| 3 | Tela ativa de rota (mapa + sheet) | 🟡 ~90% — controles de mapa REAIS (MS-A3) + Copiar paradas wirado; faltam gatilhos Otimizar/kebab · 🔧 1 must-fix Fase R (A3-D2) |
| 4 | Adicionar parada (texto) | ✅ pronto (usa Google Places **live**, não stub) · ⏳ OCR/Voz/tap-mapa são stubs (Área 7/5) |
| 5 | Detalhes da rota (Partida/Destino/Pausa) | ✅ **fechada** — MS1–MS9 (ADR-0044/0046/0047/0049). 1º integration_test do app VERDE no M54 · 🔧 5 should-fix Fase R (A5-D1..D5) |
| 6 | Editar parada (página, 14 campos) | ✅ **fechada** (MS-A6, 2026-06-12) — 606 testes + integration_test verde no M54 · 🔧 1 must-fix Fase R (A6-D1) |
| 7 | Otimizar rota (3 estados + 3 modais FTUE) | 🟡 PR-A + PR-B1/B2 fechados (estado+solver+PRE-CONFIRM+mapa); **PR-C (Ready-to-Run) é honest-stub → R/P0** · 🔧 8 must-fix Fase R (A7-D1..D8) |
| 8 | Modo Delivery (running route) | ⏳ não iniciada (abre após a Fase R) |
| 9 | Conclusão de rota + telas core (ShareSheet, kebab, reordenar, RoutesList) | ⏳ não iniciada |
| 10 | Settings completas (13 rows) | ⏳ não iniciada |
| 11 | Notification settings (UI stub) | ⏳ não iniciada |

### Ordem de execução (forçada por dependências — NÃO é livre)

```
[✅ FECHADA]     Área 5 (MS6 Pausa ✅ → MS7 config-rows ✅ → MS8 persistência ✅ (FTUE-cut ADR-0047) → MS9 integration_test+D4+editar/remover pausa ✅ (ADR-0049))
       │        Finalizar gatilhos da Área 3 (Otimizar CTA, kebab/bottom-bar; tap no stop card ✅ MS-A6)
       ▼
[✅ FECHADA]   Área 6 (Editar parada — MS-A6 2026-06-12)  ──► chips A1/A2 e lista inline dependem dela
       ▼
[🟡 PR-A/B]    Área 7 (Otimizar rota)  ── PR-A+B fechados; PR-C/D + drifts → Fase R
       ▼
[⚠️ AGORA]     Fase R — Remediação retroativa 100% (P0 Á7 PR-C → P1 gates → P2 microcopy → P3 nits)
       ▼          (BLOQUEIA a Á8 — ADR-0052; backlog: docs/audits/2026-06-20-dump-parity-retro-audit.md)
   Área 8 (Modo Delivery)  ──► "Iniciar rota" da Á7/PR-C é o gateway; estado terminal alimenta Área 9
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
- [x] `apps/mobile/integration_test/` existe — **CRIADO** na Área 5 MS9: `area5_route_details_flow_test.dart` (back-stack dos sub-pickers + add/editar pausa, VERDE no M54). Idiom estabelecido (map-free stand-in p/ o deadlock GoogleMap×integration_test, `WidgetsBinding.handlePopRoute()` p/ system-back, font-free theme) p/ as próximas áreas.
- [ ] `flutter test` ≥ 249 (baseline atual).

### Área 1 — Auth (completar UI) · independente · SEM baseline Spoke

- [ ] **Recuperação de senha (UI)** — tela `/auth/forgot-password` (campo email + CTA "Enviar link"). Backend Slice 3. Hoje: SnackBar "em breve" em `login_page.dart:223`.
- [ ] **Google Sign-In (UI)** — botão "Continuar com Google" em `/login` + `/register`. Backend Slice 3. Apple+Facebook cortados (diretiva #2).

### Área 2 — Rotas (drawer + lista + wizard) ✅ pronto

Drawer (90% width, scrim, sem swipe-from-edge) + lista agrupada por 4 períodos dinâmicos + 3-dot popup (Definir nome e data / Duplicar / Excluir) + wizard criar/editar (reusado por `:routeId` path param) + tela Reutilizar paradas. Detalhe inventory §6.2 + §10.1–10.3 + §11.3/§11.6. **Duplicar/Excluir rota e Reutilizar paradas dependem de backend (Slice 3) pra persistir.**

### Área 3 — Tela ativa de rota (mapa + sheet) 🟡 ~90%

Pronto: GoogleMap base + sheet manual 3-snap (direction-based snap) + search pill + hamburger flutuante → drawer + **seção "Configuração de rota" (2 rows-resumo → página Detalhes; via Área 5 MS7, ADR-0046)** + **controles de mapa reais (MS-A3, 2026-06-11)** + **"Copiar paradas de uma rota anterior" → Reutilizar paradas (MS-A3)**.

- [x] **Controles de mapa** (layer toggle + recenter) ✅ **MS-A3 (2026-06-11)** — dump-first (`EditRouteFragment`/`MapController`/`MapToolbarControlsController` em `~/spoke-dump/jadx-out`). Layer toggle = `MapType` 2-estados persistido (`MapPrefsRepository` + `SharedPreferencesAsync`) + toast PT-BR original; recenter = follow-my-location via `LocationService` (geolocator wrapper, sealed `LocationResult`) + fallback gracioso sem permissão + contador pending-move p/ não derrubar o follow na própria animação. Estado em `MapControlsController` (`@riverpod` keepAlive). +24 testes (controller + service + widget). **Achado dump-first:** a nota §6.2bis "controles visíveis só com sheet collapsed" era inferência — o código prova visibilidade por **flow ativo**, não por altura do sheet (corrigido no inventário).
- [x] **"Copiar paradas de uma rota anterior"** ✅ **MS-A3** — empty-state secondary CTA agora faz `push('/home/routes/reuse-stops')` (rota já existia; matou o `_comingSoon`).
- [ ] **CTA "Otimizar rota"** sticky bottom → entra na Área 7. **Wirar como 1ª task do MS-A7** (é o entrypoint da Área 7; CTA ainda não existe no shell — nasce com a lista de stops).
- [x] **Tap no stop card** → abre Área 6 ✅ **MS-A6 (2026-06-12)** — lista de stops no sheet do shell (§10.5: header "N paradas" + nome clicável, cards com badge/rua/endereço/status-dot, auto-expand one-shot, footer some com ≥1 parada) + card inteiro pusha a página de edit. Entrypoints extras: Section A da add-stop (pop-intent) + toast pós-add "Ver" (F4/H9).
- [ ] **Kebab + bottom-bar actions** → Área 9 surfaces. **Wirar como 1ª task do MS-A9** (`route_shell_page.dart` kebab "Opções da rota").

> Layout crítico (lição travada): mapa + sheet em `Column { Expanded(GoogleMap), sheet }`, NUNCA `Stack` (o PlatformView do GoogleMap ganha toda arena de gesto).

### Área 4 — Adicionar parada (texto) ✅ pronto · demais métodos stub

Pronto: texto + autocomplete via **Google Places API live** (`places_repository.dart` — não é stub; herda dependência de API key em runtime). Sealed `AddStopUiState` 5-branch. **Stubs (cada um em PR isolado):**

- [ ] **OCR single-stop** (`/stops/ocr`, ML Kit) — Área 7 / PR isolado.
- [ ] **Voz single-stop** (`/stops/voice`, `speech_to_text` locale pt_BR) — Área 7 / PR isolado.
- [ ] **Tap no mapa** (`add_stop_map_page.dart` — hoje grey-box mock `:26`, reverse geocode não wirado) — Área 5 / PR isolado.
- [ ] **CSV upload** — Slice 3.

### Área 5 — Detalhes da rota ✅ FECHADA

Pronto (branch `feat/m2-slice-2-area-5-route-details`): shell (X flutuante, h1 body-level, sem AppBar) + Partida picker + TimePickerSheet **numpad 4×3** (ADR-0042, pivot do wheel ADR-0041) + Destino **bottom sheet 3-cards** (ADR-0043 — `RoundTrip` "Voltar ao ponto de partida" / `SpecificAddress` "Destino em outro endereço" / `NoDestination` "Não usar destino"; `BackToStart` removido) + Concluído sempre habilitado + checkbox "Salvar como padrão" **UNCHECKED** (ADR-0043 §Q8). **Falta:**

- [x] **MS6 Sub-tela Pausa** ✅ (2026-06-09, ADR-0044) — página full-screen "Configure a pausa" (NÃO sheet): janela de horário Entre/E (default 08:00–15:00) via numpad reusado + duração em minutos (dialog numérico, default 30; NÃO chips). `BreakConfig` virou janela (`fromTime`/`toTime`/`durationMinutes`). SnackBar interino removido. 261 testes.
- [x] **MS7 Seção "Configuração de rota" na tela ativa** ✅ (2026-06-10, ADR-0046) — Phase-2 halt corrigiu a premissa do plano: a tela ativa NÃO tinha rows de config (a Spoke mostra **2 rows-resumo** Início + Ida-e-volta, SEM Pausa) e elas abrem a **página Detalhes da rota** inteira, NÃO os sub-pickers direto. Criado `_ConfigSummarySection` em `route_shell_page.dart` (microcopy de resumo distinta da página Detalhes); `RouteDetailsPage` antes órfã agora tem entrypoint de produção. 272 testes.
- [x] **MS8 Persistência + FTUE-cut** ✅ (2026-06-10, ADR-0047) — DUMP-FIRST: o dump decompilado prova que a Spoke **não tem gate de "primeira rota"** (sem `firstRoute`/`isFirst` em `RouteSetupViewModel`; `ui/onboarding` é survey). **FTUE auto-show CORTADO** (era inferência). Wirado só persistência: "Salvar como padrão" → `merge()` no Concluído (best-effort) + seed da Detalhes do envelope `route_defaults_v1` ao abrir. Q8 UNCHECKED confirmado por pixels. 281 testes.
- [x] **MS9 integration_test + D4 + editar/remover pausa + PR** ✅ (2026-06-10, ADR-0049) — 1º `integration_test` do app (`area5_route_details_flow_test.dart`, back-stack 5-rotas + add/editar pausa) **VERDE no M54**. D4 **dump-only** (sem poluir conta licenciada) fechou 2 gaps NO MESMO MS: **GAP-1** editar/remover pausa (row existente reabre em edit mode + "Remover pausa" + diálogo de confirmação — dump `BreakSetupArgs.EditBreak`/`UpdateBreak` + strings `break_screen_remove_button`/`remove_break_confirmation_dialog_*`; resultado vira sealed `BreakSchedulerResult`); **GAP-2** "Salvar como padrão" sempre visível (sem gate de 1ª rota, mesmo achado do ADR-0047). 284 testes host. PR aberto.

> Nota §13.C.2 RE-RESOLVIDA (ADR-0047, dump-first): a hipótese "Detalhes da rota é FTUE one-time" era **inferência** — o dump decompilado prova que a Spoke **NÃO tem gate de primeira rota** (sem `firstRoute`/`isFirst`/`hasSeenSetup` em `RouteSetupViewModel`; `ui/onboarding` é survey, não setup). A Detalhes é **on-demand** (aberta pelo resumo "Configuração de rota" da Área 3, ADR-0046), não auto-mostrada. FTUE auto-show **cortado**.

### Área 6 — Editar parada (página, 14 campos) ✅ FECHADA (MS-A6, 2026-06-12)

Pronto (branch `feat/m2-slice-2-area-6-edit-stop`, 20 tasks TDD red→green): lista de stops no sheet do shell (§10.5, auto-expand one-shot H6, footer empty-state-only H5) + `EditStopPage` GoRouter full-screen (D1) com TODOS os campos: chips cor (5 cores F10) + ID (display) · card endereço · Instruções de acesso **sticky-ao-endereço** (F13/H18) · notas + **foto local** (`image_picker`+`path_provider` ADR-0050, `PackagePhotoStore` F12/H16/H17) · Localizador de pacotes completo (F11/H13 — chips dim/tipo + 3 eixos inline) · Pacotes stepper+dialog (F8/H3) · Ordem/Tipo segmented (F16/H21) · janela de chegada "Chegar entre"/"E" via numpad reusado (F7/H1/D8) · Tempo na parada min+seg com default do `SettingsRepository` (F9/H14) · Mudar endereço (`PickerMode.changeAddress` H10) · Duplicar (pushReplacement H11) · Remover (confirm F6). `Stop` migrado (`TimeOfDay?` janela, `_omit` em 11 nullables H2). 606 testes host + `integration_test/area6_edit_stop_flow_test.dart` verde no M54. D4 dump-only: 0 must-fix. Smoke E2E release achou e corrigiu 2 gaps fora da Á6: `MAPS_API_KEY` ausente no script de release + rota criada não virava ativa no wizard (paridade `RouteCreateFragment.java:186-193`).

#### Histórico do design (pré-fechamento) · dependia de Área 3 (tap stop card) + Área 4 (Mudar endereço reusa add-stop)

**Design aprovado (dump-first deep-grep): [`docs/superpowers/specs/2026-06-11-area6-edit-stop-design.md`](./superpowers/specs/2026-06-11-area6-edit-stop-design.md).** O deep-grep no jadx (2026-06-11) corrigiu a premissa: no Spoke, "Editar parada" é o `EditStopDialogFragment` (modal quase-full-screen, destination próprio) — NÃO um estado do sheet do shell; o `StopDetailSheet` pager é a surface de rota EM EXECUÇÃO (Área 8). **RotPro: página GoRouter full-screen** `/home/routes/active/:routeId/stops/:stopId/edit` (decisão D1 — idiom Á5, evita Flutter #155746). A MS-A6 também constrói a **lista de stops no sheet do shell** (seção "Paradas" per §10.5 — pré-requisito do tap; sem reorder=Á9, sem CTA Otimizar=Á7).

Topbar: Ajuda (stub) + "Editar parada" + "Concluído" primary (**só fecha — edits aplicados live por campo**, fato F3). Campos: chip cor (sheet, **exatamente 5 cores**) · chip package-ID (display "Pendente"; tela Formato do ID é Á10) · card endereço read-mostly · "Instruções de acesso" (2º sheet, **sticky AO ENDEREÇO** — §13.C.3 + F13) · notas + camera attach (**implementar local-only**: `image_picker` já no pubspec + `path_provider` novo → ADR curta; Spoke não sobe foto) · "Localizador de pacotes" (**estrutura completa no dump — implementar**, F11) · Pacotes (stepper inline + dialog 1–9999 no tap do número, F8) · SegmentedButton Ordem (Primeira/Automática/Última) · SegmentedButton Tipo (Entrega/Coleta) · "Horário de chegada" (**JANELA** "Chegar entre"/"E", F7 — reusa padrão janela+numpad da BreakScheduler) · "Tempo estimado na parada" (dialog **min+seg**, default do `SettingsRepository` mínimo criado nesta MS — 1 min, F9/D4) · "Mudar endereço" (PickerMode novo na AddStopPage) · "Duplicar parada" (imediato → abre editor da duplicata, F5) · "Remover parada" (VERMELHO + AlertDialog confirm, F6). Pós-add via texto: toast "Parada adicionada" + ação "Ver" (F4 — §11.5 amendado). **§13.C.1 RESOLVIDA: Pacotes/Ordem/Tipo sempre ativos.** SEM picker de razão de falha (Dispatch B2B). SEM Cliente/Destinatário/Valor-a-cobrar (feature-gated B2B, F14).

📊 **Dump (ADR-0045):** rows #4–#10 da [MASTER-TABLE](./inventory/spoke-dump-v3.65.1/MASTER-TABLE.md) **todas resolvidas por código** no Amendment 2026-06-11 (inclusive **#5** que era `low` → estrutura completa, e **#7** default global = 1 min). `Precisa-runtime` restante: 2 cliques no D4 (toast pós-add + tap-no-número dos Pacotes).

### Área 7 — Otimizar rota (3 estados + 3 modais FTUE) 🟡 PR-A + PR-B1/B2 fechados · PR-C + 8 must-fix → Fase R

Funil: modal FTUE "IDs ajustados" → estado PRE-CONFIRM (mapa metade + polyline + markers 1-N + sheet mid + summary "X min · N paradas · D km" + 3 CTAs: X min verde / Refinar / Confirmar) → modal FTUE "IDs definitivos" → modal FTUE "Carregar veículo?" → estado **Ready-to-Run** (CTAs: X min verde / Editar / **Iniciar rota** = gateway pro modo delivery). 3 flags FTUE em SharedPrefsAsync. Otimização é **grátis** (paywall só em "Navegar"). Detalhe §10.8–10.12.

- ⚠️ **CORTADO (B2B-adjacent):** "Compartilhar rota em tempo real" (live tracking pro cliente final) — OUT-OF-SCOPE Slice 2; postergado.
- ⚠️ **OUT-OF-SCOPE M2:** "Carregar veículo" (Load vehicle).
- 📌 **§13.C.4 PENDENTE:** opções do "Refinar" não inspecionadas. Live-inspect no MS; fallback = re-run simples do solver (1 botão), registrado como decisão explícita.
- 🔧 Usar `ReorderableListView.onReorderItem` (3.44), não `onReorder`.

📊 **Dump (ADR-0045) — consome #20 + #21/#22/#25-Voz da [MASTER-TABLE](./inventory/spoke-dump-v3.65.1/MASTER-TABLE.md):** **#20** Pular otimização (`medium`) — strings `optimization_failed_*` prontas; agrupar a confirmação do dialog no MESMO drill runtime do "Refinar" (§13.C.4). **#21** OCR / **#22** Importar CSV-PDF / **#25-Voz** — `high` em estrutura MAS dependem de ML Kit + gravação + upload assíncrono (timeout 240s = pressupõe backend Slice 3). **Manter stub no Slice 2; reavaliar pós-Slice 3** (são as features mais caras do app).

### Área 8 — Modo Delivery (running route) ⏳ depende de Área 7 (Iniciar rota)

Foco em UMA parada por vez. Mapa metade superior centrado na parada atual (following) + sheet mid (h1 nome rua + X close + subtitle "N/total, HH:MM"). **3 botões status (conditional por `Stop.type`):** "Navegar" (filled BLUE, sempre, handoff `url_launcher` geo: URI) · "Não entregue" (sempre, marca Failed **silenciosamente** + auto-advance, SEM picker de razão — §10.14) · "Entregue" (se delivery) / "Coletado" (se pickup). Lista inline + marker encoding por status. Estado "Destino final" (retorno Ida e volta): só 2 botões. **PAYWALL TRIGGER:** 1º "Navegar" verifica `user.isPaid` (Slice 4). Detalhe §10.13–10.17.

- 🔧 `AsyncValue.guard` pras mutações de status; `switch` exaustivo na AsyncValue selada.
- 🔧 Mapa following com `_followUser` flag + `distanceFilter`; pausar camera no pan do usuário.

📊 **Dump (ADR-0045):** o Modo Delivery não estava nas 20 telas "Não drilled", mas o dump REVELOU o `break_detail_sheet` (Pausa DURANTE a entrega: "Faça uma pausa" / "Pausa feita" / "Pular pausa" / "Editar pausa" / "Entre as paradas %1$d e %2$d") — uma surface desta Área que o ADR-0044 (agendamento) não cobre. Ver Achado #1 da [MASTER-TABLE](./inventory/spoke-dump-v3.65.1/MASTER-TABLE.md). Drillar ao vivo no MS da Área 8.

### Área 9 — Conclusão + telas core ⏳ depende de Área 8 (estado terminal)

- [ ] **Tela "Rota concluída!"** — markers congelados + summary + card central (check verde + stats "N paradas · M perdida") + CTA "Copiar paradas para nova rota". Spoke conta só Failed em "perdida". Reabrível trivialmente. Detalhe §10.18.
- [ ] **Kebab da rota concluída** — 3 opções do drawer. **RotPro oportunidade:** 4º item "Compartilhar resumo" (alinha ScreenShare). §10.20.
- [ ] **Reordenar paradas** — `ReorderableListView.onReorderItem` no sheet expanded. §10.5.
- [ ] **ShareSheet** (feature original RotPro, apagada no reset) — `/settings/share`: WhatsApp + copy link + QR. §4.
- [ ] **Menu kebab da rota ativa** — bottom sheet 5 opções. Slice 2: existe mas opções abrem "Em breve". §6.4.
- [ ] **RoutesListPage** — surface alternativa ao drawer. §6.2.

⚠️ **CORTADAS (B2B-adjacent, postergadas pós-M2):** "Compartilhar cópia da rota" (peer transfer driver-to-driver) + "Transferir paradas" — §6.4. 📌 **§13.C.5 PENDENTE** (semântica das duas).

📊 **Dump (ADR-0045) — consome #17/#18/#19/#23/#24/#25-Duplicar da [MASTER-TABLE](./inventory/spoke-dump-v3.65.1/MASTER-TABLE.md):** `high` (codar direto) → **#24** Remover paradas (2 branches todas/só-feitas, textos verbatim), **#19** Copiar paradas + **#25** Duplicar rota (fluxo "Manter/Redefinir progresso", alimenta o CTA "Copiar paradas para nova rota"). **#23** Imprimir rota (`high`, baixo esforço Android print) — item NOVO que o dump revelou; **decisão de Eduardo**: incluir como extra B2C ou cortar. **§13.C.5 PODE FECHAR:** o dump confirma que **#17** Compartilhar-cópia e **#18** Transferir são peer-transfer driver-to-driver ("outros usuários do Spoke" / QR code) — o corte está correto (≠ ShareSheet original RotPro em `/settings/share`).

### Área 10 — Settings completas (13 rows) ⏳ independente · precede Área 11

`ListView` + `ListTile`/`SwitchListTile.adaptive` + section headers (equivalente ao PreferenceActivity do Spoke). **Pickers radio: usar `RadioGroup<T>` ancestral (3.44), não groupValue por-Radio.**

- **Preferências de rota (7):** App de navegação (radio: GoogleMaps/Waze/Outro — NÃO Yandex nem "Navegação do Spoke") · Lado da parada (Qualquer/Direito/Esquerdo) · Tempo médio na parada (1/2/3/5/10/custom — alimenta default da Área 6) · Tipo de veículo (5 opções; Caminhão grande NÃO suportado) · Evitar pedágios (switch OFF) · ID de parada (Formato Moderno/Clássico + Atribuir Depois/Conforme) · Balão do modo de navegação (switch — disabled/removido se sem navegação interna; decidir no MS).
- **Assinatura (1):** Comparar planos — tela informacional do pass único R$ 25,90 (NÃO picker de tiers). Abre paywall (Slice 4).
- **Rodapé legal:** Endereço de casa (stub, real Slice 5) · Indicações (→ ShareSheet) · Licenças (Slice 6) · Privacidade (Slice 6) · Termos (Slice 6) · Versão (display) · **Sair** (VERMELHO).
- ❌ **Tema:** DESCARTADO (tema único). Section "Preferências gerais" removível.

📊 **Dump (ADR-0045):** Settings não tem linha-gap própria na [MASTER-TABLE](./inventory/spoke-dump-v3.65.1/MASTER-TABLE.md) (o dump focou no fluxo de rota; Settings é `PreferenceActivity` com XML extraível à parte). **Dependência:** o setting "Tempo médio na parada" (1/2/3/5/10/custom) **alimenta o default do #7** ("Tempo na parada" da Área 6) — implementar Área 10 antes/junto da Área 6 para o default ter origem real, não hard-coded.

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

## Slice 6 — LGPD ⏳ (desprioritizada — uma das últimas entregas, ADR-0052)

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
| §13.C.2 Detalhes da rota FTUE? | 🟡 | ✅ RESOLVIDO (ADR-0047) — SEM gate FTUE; Detalhes é on-demand (dump) | Área 5 |
| §13.C.3 Instruções de acesso UI | 🟡 | ✅ RESOLVIDO — 2º sheet sticky-ao-endereço | Área 6 |
| §13.C.4 "Refinar" CTA opções | 🟢 | 📌 PENDENTE — drillar no MS Área 7 | Área 7 |
| §13.C.5 Compartilhar cópia vs Transferir | 🟢 | 📌 PENDENTE — ambas postergadas | Área 9 |

---

## Validação contínua (subagents + gates)

- **`spoke-parity-checker`** ([ADR-0036](./decisions/0036-spoke-parity-checker-functional-gate.md), dump-first per ADR-0045/0049) — dispatch UPFRONT = **confirmar a baseline do dump** (MASTER-TABLE+amendments + jadx; runtime só o `Precisa-runtime`; screenshot pixels pra ícones Compose quando runtime rodar) + D4 closing = **dump-only por default** (runtime só os cliques listados; o `/verify-slice` dispatcha o D4 automaticamente desde 2026-06-11). **NÃO** pra Áreas 1 e 11 (sem baseline Spoke).
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
- **Dump-first por ÁREA antes de implementar (ADR-0052)** — esgotar o dump da área inteira (fluxos/estados/gates/fallbacks/strings) num doc ANTES de codar; runtime só confirma o `Precisa-runtime`. Ordem: mapear a área toda (dump) → implementar (tradução moderna) → validar (re-grep + D4 dump-only + testes que pinam paridade). Inferência entre microsprints foi o que vazou os 13 must-fix do audit 2026-06-20.
- **Zero tech debt por área** — nunca deferir divergência com `// TODO`/`// MS9`; corrigir no mesmo MS ou escalar como BLOCKED.
- Sem placeholders de cor/ícone "pra ajustar depois" — tokens prototipo desde commit 1.
- Tokens 3.44 (não memória Jan-2026): `onReorderItem`, `RadioGroup<T>`, `AsyncValue` selada.
