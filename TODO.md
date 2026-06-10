# TODO

> **Estratégia M2 = white-label do Spoke** (replicar 100% funcional/estrutural com nossa stack; polish visual no final). Roadmap canônico (fonte única, reescrito limpo 2026-06-06): [`docs/08-ROADMAP-v2.md`](./docs/08-ROADMAP-v2.md). Catálogo de paridade (paráfrase): [`docs/inventory/2026-05-26-spoke-vs-rotpro.md`](./docs/inventory/2026-05-26-spoke-vs-rotpro.md). **Baseline de FATO (dump estático v3.65.1, ADR-0045): [`docs/inventory/spoke-dump-v3.65.1/MASTER-TABLE.md`](./docs/inventory/spoke-dump-v3.65.1/MASTER-TABLE.md)** — consultar primeiro. Sprint de execução do Slice 2: [`docs/superpowers/specs/2026-06-06-slice2-completion.md`](./docs/superpowers/specs/2026-06-06-slice2-completion.md).

## M1 — closed 2026-05-09 (BRL 2.000 escrow)

- [x] Backend auth (JWT + refresh + secure storage)
- [x] Landing page + APK distribution (`roteirizadorpro.com.br`)
- [x] GraphHopper SP self-hosted
- [x] Login + Register Flutter screens
- [x] APK `v1.0.0` shipped 2026-05-13

## M2 — em progresso (reset 2026-05-26, BRL 2.000)

Slices restantes (detalhe em [`docs/08-ROADMAP-v2.md`](./docs/08-ROADMAP-v2.md)):

- [ ] **Slice 2** — Telas Core Spoke-aligned (replicar drawer + lista de rotas + wizard criar/editar + tela ativa de rota com mapa+sheet + adicionar parada 3 métodos + reordenar + otimizar + navegar + paradas concluídas + share + settings completas)
- [ ] **Slice 3** — Backend real (optimization solver + geocoding Nominatim SP + status persistido + histórico + push FCM + reset senha + Google Sign-In backend)
- [ ] **Slice 4** — Stripe Pix paywall (per ADR-0030: R$ 25,90 / 30 dias, Connect 50/50 split, webhook idempotente)
- [ ] **Slice 5** — Sentido casa (toggle + endereço de casa + solver respeita "termina perto de casa")
- [ ] **Slice 6** — LGPD (export dados + excluir conta + privacy + terms + OSS licenses)
- [ ] **Slice 7** — Admin panel (MRR + usuários ativos + paradas processadas)

## Discovered while working

- [x] Implementado: Wizard de Criação de Rota (Área 2) com testes e UI fiel ao protótipo Spoke.
- [x] Implementado: Reutilizar Paradas (Área 2.5) e Tela Ativa da Rota com mapa e controles (Área 3).
- [x] Validar UI via emulador / build local (Requer hot-restart do usuário).
- [x] Migrado: flutter_map para google_maps_flutter no Android, ajustado Safe Area e UI da bottom sheet (ADR-0039).
- [x] UI Polish: Ajustes visuais no Menu Hambúrguer, correção do Remember-me via SharedPreferencesAsync e margens do Mapa.

## Slice 2 — em andamento por área

Roadmap canônico: [`docs/08-ROADMAP-v2.md`](./docs/08-ROADMAP-v2.md) (reescrito limpo 2026-06-06). Sprint de execução do Slice 2: [`docs/superpowers/{specs,plans}/2026-06-06-slice2-completion.md`](./docs/superpowers/specs/2026-06-06-slice2-completion.md). Spec/plan da Área 5 (parcialmente supersedidos, referência MS6–9): `docs/superpowers/{specs,plans}/2026-06-02-area5-route-details.md`. Status canônico desta lista, código canônico nos commits.

> **Ordem FORÇADA por dependência (não é livre):** terminar Área 5 (MS6→MS9) + gatilhos da Área 3 → Área 6 → Área 7 → Área 8 → Área 9. Áreas 1, 10, 11 são independentes (Á10 precede Á11). **Gates do Slice 2:** `integration_test/` AINDA NÃO EXISTE (hard gate; 1º teste = `area5_route_details_flow_test.dart` no MS9); 23 lints pré-existentes a zerar; `flutter test` ≥ 249. **Áreas 1 e 11 NÃO têm baseline Spoke** → sem dispatch `spoke-parity-checker`.

- [ ] **Area 1 (Auth — completar UI, SEM baseline Spoke)** — Login/Register prontos; FALTA UI: tela `/auth/forgot-password` + botão "Continuar com Google" (backend ambos Slice 3). NÃO é fora-de-escopo — é UI restante do Slice 2.
- [x] **Area 2 (Drawer + Shell + Wizard + Popup 3-dot)** — shipped via `cd37a65` (branch `feat/m2-slice-2-area-2-drawer`, mergeada).
- [ ] **Area 3 (Tela ativa de rota — mapa + sheet)** — ~80% pronta. FALTA wirar 4 stubs FUNCIONAIS (não é polish): controles de mapa (layer/recenter), CTA "Otimizar rota"→Á7, tap no stop card→Á6, kebab/bottom-bar→Á9. Estão no caminho forçado pras Áreas 6/7/9.
- [ ] **Area 4 (Adicionar parada)** — TEXT method **em andamento** na branch `feat/m2-slice-2-area-4-add-stop-text`:
  - [x] MS1 Domain (sealed `AddStopUiState` + 5-branch `from` factory) — commits `d0331a3`, `220479d`, `bc27ba7`, `19abe5e`. 14 unit tests pinning invariants.
  - [x] MS2 State (`searchQueryProvider` + `currentRouteStopsProvider` + `addStopUiStateProvider`) — commits `3a603af`, `fe6d05d`, `0672635`. +9 unit tests.
  - [x] MS3 Widgets (refactor Stack→Column + 3 estados + 2 seções + footer + search bar reativo) — commits `db0600a`, `6804615`, `f9a0f72`. +11 widget tests.
  - [ ] **MS4 (REABERTO 2026-05-29 pós-audit)** — integration_test atual é brittle (assume device com rota ativa pré-logada; confirmado falhando em fresh install). D4 spoke-parity-checker dispatched retroativo: **3 must-fix + 2 should-fix** estruturais descobertos. Ver session log `2026-05-29-01`. MS4 não fecha até MS5 aplicar D4 fixes + rerun verification.
  - [x] **MS5 (D4 fixes — shipped 2026-05-29)** — Section B sem leading icon + Footer sem leading/trailing (commits `16ee368` + `1b9cafa` + `ddbc290`). Section A trailing pencil affordance (commits `2da3359` + `4e43fce`). Search bar X = limpar input (descoberta visual M54 — antes fechava a tela; agora limpa + restaura OCR/Voice) (commits `972c933` + `9ab267a`). Decisão Eduardo: `plusCircle` e `searchX` decorativos MANTIDOS como "RotPro additive" (commit `1f598f5`). +14 testes (89 → 91). Re-validação M54 + smoke Maestro standalone + final review = pré-PR.
  - **Out of scope deste PR** (cada um vai pra PR isolado): Voz (Area 7), OCR (Area 7), tap-no-mapa (Area 5), CSV upload (Slice 3+), edit-stop sheet (Area 6 — BIG FIND auto-open per inventory §11.4 fica adiado, documentado no spec).
- [ ] **Area 5 (Detalhes da rota — pré-flight Partida/Destino/Pausa)** — em andamento na branch `feat/m2-slice-2-area-5-route-details`:
  - [x] MS1 Domain + State (sealed `RouteConfig`, `RouteDefaults`, 2 controllers, `PickerMode`) — base ✅.
  - [x] MS2 Shell `RouteDetailsPage` (3 seções + Concluído + checkbox Salvar como padrão) — Spoke parity (sem AppBar, X flutuante topo-esquerda, body-level h1).
  - [x] MS3 Partida picker reusing `AddStopPage(mode: startLocation)` — commits `52e9211`, `95c0eaf`.
  - [x] MS4 TimePickerSheet (numpad 4×3 + FAB + backspace + buffer) — pivot crítico: ADR-0041 (wheel_picker) ➜ ADR-0042 (numpad) após re-inspeção live Spoke 2026-06-03. Commits `bf89e63` (widget + 14 testes), `413713f` (wire 2 rows + 4 testes), `bc236ff` (style), `23ff0ff` (Spoke parity fix: Partida-Início collapses to `'HH:MM'` após confirm). Template `area5-microsprint.js` criado e validado.
  - [x] MS5 Sub-tela Destino — **bottom sheet com 3 cards** (NÃO radio/página — spec original veio de baseline mislabeled; re-inspeção live Spoke 2026-06-03 corrigiu, ADR-0043). Cards: Voltar ao ponto de partida (`RoundTrip`) / Destino em outro endereço (`SpecificAddress` → push end-location search) / Não usar destino (`NoDestination`). Domínio realinhado aos 3 estados Spoke (`BackToStart` removido, `NoDestination` adicionado). `add_stop_page` endLocation de-stubado (pop `SpecificAddress`). Card-2 usa returns-intent pattern (Flutter #155746). Commit `5dea345`. 240 testes (+18). Workflow `w29si5x7y` halt em scope-error meu (`app.dart` faltava na allowlist) → corrigido manualmente + 2 reviewers ✅. Débito: card-2 on-device golden path fica pro MS9.
  - [x] MS-FIX Audit remediation (MS1–MS5) — auditoria retrospectiva read-only (6 dimensões + verificação adversarial: 30→21 achados; relatório `docs/audits/2026-06-03-area5-ms1-ms5-retro-audit.md`). Corrigidos: M1 títulos time-picker ("Definir primeiro/último horário"), S2 Concluído sempre habilitado, S1 relógio ao vivo na linha Início, S3 hints originais, S4 row Pausa tappável (stub), + nits (catch log, merge doc+test, docstring, divergence-table ADR-0043, Q8 note, docs app_router→app.dart + scroll-wheel→numpad). 249 testes (+9). Commits `21d43c4` (código), `6e1f738` (docs). 2 reviewers ✅. Débito mantido: integration_test + confirmar que o default UNCHECKED se mantém vs Spoke fresh (per ADR-0043 §Q8) + Pausa scheduler → MS6/MS9.
  - [x] MS6 Sub-tela Pausa ✅ (2026-06-09, ADR-0044) — live-dump achou estrutura ≠ inferência: página full-screen "Configure a pausa" (NÃO sheet) + janela de horário Entre/E (default 08:00–15:00, numpad reusado) + duração em minutos (dialog numérico, default 30; NÃO chips 15/30/60). `BreakConfig` virou janela (`fromTime`/`toTime`/`durationMinutes`); JSON `route_defaults_v1` atualizado; SnackBar interino removido. Phase-2 halt → escalado → Eduardo escolheu match-Spoke. analyze limpo no escopo, 261 testes (+12). Débito mantido: integration_test (MS9) + confirmar default UNCHECKED vs Spoke fresh (MS8).
  - [ ] MS7 Wire Area 3 sheet rows clickable.
  - [ ] MS8 Persistência SharedPreferencesAsync + FTUE trigger.
  - [ ] MS9 D4 closing parity + Maestro YAML + PR.
- [ ] **Area 6 (Editar parada — 14 campos)** — inline DraggableScrollableSheet (BIG FIND §11.4); depende de Á3 (tap stop card) + Á4 (Mudar endereço reusa add-stop).
- [ ] **Area 7 (Otimizar rota — 3 estados + 3 FTUE modals)** — depende de Á6 (chips A1/A2) + Á3 (CTA Otimizar). Usar `onReorderItem` (3.44).
- [ ] **Area 8 (Modo delivery — stop focused + status buttons)** — depende de Á7 ("Iniciar rota"). Mapa following em Column (não Stack).
- [ ] **Area 9 (Conclusão + telas core: ShareSheet, kebab rota ativa, reordenar, RoutesList)** — depende de Á8 (estado terminal).
- [ ] **Area 10 (Settings completas — 13 rows)** — independente; precede Á11. Usar `RadioGroup<T>` (3.44).
- [ ] **Area 11 (Notification settings — UI stub, SEM baseline Spoke)** — row dentro de Settings (depende de Á10); 3 toggles; FCM real Slice 3.

> **Polish visual + microcopy PT-BR final + transições** = passe pós-Slices (NÃO é uma área numerada). `prototype-fidelity-checker` sweep + tag `v1.1.0`.
