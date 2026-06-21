# Inventário de front Spoke v3.65.1 (B2C) — blueprints por área

> **Data:** 2026-06-21 · **Método:** dump-first (ADR-0045) — extração ESTRUTURAL do jadx decompilado (`~/spoke-dump/jadx-out`, ofuscado via Pairip), strings PT-BR verbatim de `values-pt-rBR/strings.xml`. **Não é código copiado** (Compose↔Flutter não traduz): são FATOS (telas, campos, strings, enums, defaults, navegação, ícones→Lucide) pra reimplementar na nossa stack com identidade visual própria (ADR-0035). Maestro não serve no Spoke (blindspot Compose). Harvest via workflows (3 lotes).

## Blueprints por área (22 áreas B2C)

| Área | Blueprint | Slice/Área RotPro provável | Resumo |
|---|---|---|---|
| home (shell+mapa) | [home-shell-map.md](home-shell-map.md) | Á2/Á3 (shell ativo) | Shell da rota ativa, controles de mapa, bottom sheet arrastável |
| home (drawer+rotas) | [home-drawer-routelist.md](home-drawer-routelist.md) | Á2 (nav) | Drawer/menu lateral, lista de rotas, header |
| home (editroute) | [home-editroute.md](home-editroute.md) | Á6/Á7 | Edit route: stop actions, funil de otimização, detail sheet, toasts |
| edit | [edit.md](edit.md) | Á6 | Editar parada (EditStopDialog, 7 seções) + editar endereço |
| create | [create.md](create.md) | Á4 | Wizard criar/editar/duplicar rota, copiar paradas, depósito |
| setup | [setup.md](setup.md) | Á5 | Detalhes da rota: partida, destino (3 opções), horários, pausa |
| search | [search.md](search.md) | Á3 | Busca/autocomplete de endereço (AddStops + Picker), 6 estados |
| scanner | [scanner.md](scanner.md) | Á3 | OCR de endereço (ML Kit) + scan de código de barras, 6 modos |
| photo | [photo.md](photo.md) | Á6/Á8 | Visor de foto de pacote + comprovante (POD), strictness |
| notes | [notes.md](notes.md) | Á6 | Modal de notas da parada/pausa + fotos (gate de plano) |
| delivery | [delivery.md](delivery.md) | **Á8** | Modo entrega: 4 modos, 19 PackageState, assinatura, POD |
| settings | [settings.md](settings.md) | Á10 | Configurações (tema, rota, ID de parada, nav-app, veículo) |
| login | [login.md](login.md) | Á1 | Auth state machine (email/phone), pós-login bifurca onboarding |
| onboarding | [onboarding.md](onboarding.md) | Á1/Á11 | Survey de perfil + follow-up + tutorial (vídeo 15s) |
| tutorial | [tutorial.md](tutorial.md) | Á11 | Survey de perfil + tutorial em vídeo |
| dialogs | [dialogs.md](dialogs.md) | transversal | Catálogo dos 12+ diálogos (pickers, education, package, speech) |
| include_steps | [include_steps.md](include_steps.md) | Á7 | Modais "Paradas não adicionadas" / "Pausa não adicionada" |
| loading | [loading.md](loading.md) | Á8 | "Carregar veículo" (lugar no veículo 3D), 4 estados de sheet |
| survey | [survey.md](survey.md) | Á11 | Survey binário de rota + onboarding de perfil |
| copy | [copy.md](copy.md) | Á3 | "Reutilizar paradas" (modal com 3 seções, checkbox tri-estado) |
| base | [base.md](base.md) | infra | Componentes-base + grafo de navegação (`nav_main.xml`) |
| intent | [intent.md](intent.md) | infra | Deep-links/intents (15 DeepLinkAction; B2C vs B2B) |

## Já blueprintado à parte (mais profundo)

- **editroute/steplist (lista de paradas da rota ativa):** [`docs/superpowers/specs/2026-06-21-active-route-steplist-design.md`](../../../superpowers/specs/2026-06-21-active-route-steplist-design.md) — anatomia das 5 linhas (GroupHeader/Start/Break/Stop/End), 3 branches, plano de assembly. Implementado (Branch B+C) nesta sprint.

## Excluído (B2B / Spoke Dispatch — NÃO clonar, ver fronteira B2C)

- **transfer_stops** — transferência peer-to-peer de paradas entre motoristas (QR code).
- **depot** — gestão de depósitos de frota.
- **profileswitcher** — troca entre contas/perfis de equipe.
- **routeoffering** — ofertas de rota (Delivery Network / dispatcher).
- **manifest_import** — importação de manifesto B2B.
- **billing** — billing/assinatura nativa do Spoke (nosso é Stripe Pix, ADR-0030).

Marcadores `[B2B — cortar]` dentro de áreas B2C (ex.: "Carregar veículo" team-restriction, scanner BarcodeLoadVehicle, settings Assinatura) indicam features a omitir pontualmente.
