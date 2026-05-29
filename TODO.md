# TODO

> **Last reset:** 2026-05-26. Estratégia M2 = **white-label do Spoke** (replicar 100% funcional/estrutural com nossa stack; polish visual no final). Catálogo autoritativo de paridade: [`docs/inventory/2026-05-26-spoke-vs-rotpro.md`](./docs/inventory/2026-05-26-spoke-vs-rotpro.md). Roadmap simplificado: [`docs/08-ROADMAP-v2.md`](./docs/08-ROADMAP-v2.md). Plano da limpeza que originou esse reset: `~/.claude/plans/velvet-yawning-thacker.md`.

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

Spec autoritativa: [`docs/superpowers/specs/`](./docs/superpowers/specs/). Plan autoritativo: [`docs/superpowers/plans/`](./docs/superpowers/plans/). Status canônico desta lista, código canônico nos commits.

- [x] **Area 1 (Auth)** — fora de escopo Slice 2; recuperação senha/Google sign-in vão pra Slice 3.
- [x] **Area 2 (Drawer + Shell + Wizard + Popup 3-dot)** — shipped via `cd37a65` (branch `feat/m2-slice-2-area-2-drawer`, mergeada).
- [ ] **Area 3 (Tela ativa de rota — mapa + sheet)** — já 80% pronta; polish + bug fixes ficam pra polish pass.
- [ ] **Area 4 (Adicionar parada)** — TEXT method **em andamento** na branch `feat/m2-slice-2-area-4-add-stop-text`:
  - [x] MS1 Domain (sealed `AddStopUiState` + 5-branch `from` factory) — commits `d0331a3`, `220479d`, `bc27ba7`, `19abe5e`. 14 unit tests pinning invariants.
  - [x] MS2 State (`searchQueryProvider` + `currentRouteStopsProvider` + `addStopUiStateProvider`) — commits `3a603af`, `fe6d05d`, `0672635`. +9 unit tests.
  - [x] MS3 Widgets (refactor Stack→Column + 3 estados + 2 seções + footer + search bar reativo) — commits `db0600a`, `6804615`, `f9a0f72`. +11 widget tests.
  - [ ] **MS4 (REABERTO 2026-05-29 pós-audit)** — integration_test atual é brittle (assume device com rota ativa pré-logada; confirmado falhando em fresh install). D4 spoke-parity-checker dispatched retroativo: **3 must-fix + 2 should-fix** estruturais descobertos. Ver session log `2026-05-29-01`. MS4 não fecha até MS5 aplicar D4 fixes + rerun verification.
  - [x] **MS5 (D4 fixes — shipped 2026-05-29)** — Section B sem leading icon + Footer sem leading/trailing (commits `16ee368` + `1b9cafa` + `ddbc290`). Section A trailing pencil affordance (commits `2da3359` + `4e43fce`). Search bar X = limpar input (descoberta visual M54 — antes fechava a tela; agora limpa + restaura OCR/Voice) (commits `972c933` + `9ab267a`). Decisão Eduardo: `plusCircle` e `searchX` decorativos MANTIDOS como "RotPro additive" (commit `1f598f5`). +14 testes (89 → 91). Re-validação M54 + smoke Maestro standalone + final review = pré-PR.
  - **Out of scope deste PR** (cada um vai pra PR isolado): Voz (Area 7), OCR (Area 7), tap-no-mapa (Area 5), CSV upload (Slice 3+), edit-stop sheet (Area 6 — BIG FIND auto-open per inventory §11.4 fica adiado, documentado no spec).
- [ ] **Area 5 (Detalhes da rota — pré-flight Partida/Destino/Pausa)**.
- [ ] **Area 6 (Editar parada — 14 campos)** — reverte o `context.pop()` deste PR e implementa inline DraggableScrollableSheet (BIG FIND §11.4).
- [ ] **Area 7 (Otimizar rota — 3 estados + FTUE modals)**.
- [ ] **Area 8 (Modo delivery — stop focused + status buttons)**.
- [ ] **Area 9 (Conclusão de rota)**.
- [ ] **Area 10 (Polish visual + microcopy final + transições)**.
