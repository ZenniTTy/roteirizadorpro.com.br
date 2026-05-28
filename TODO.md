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
- [ ] Implementar a próxima etapa da Slice 2 (adicionar parada, reordenar, navegar).
