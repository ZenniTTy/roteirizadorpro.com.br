# 08 — Roadmap v2 (reset 2026-05-26)

> **Estratégia:** white-label do Spoke. Replicar 100% funcional+estrutural usando nossa stack (Flutter + Riverpod + GoRouter + SharedPrefsAsync no mobile; Fastify + TypeBox + Prisma 7 + PostgreSQL + GraphHopper no backend). Polish visual original (cores, ícones, microcopy) fica pro fim, em sweep dedicado.
>
> **Catálogo autoritativo de paridade:** [`docs/inventory/2026-05-26-spoke-vs-rotpro.md`](./inventory/2026-05-26-spoke-vs-rotpro.md). Quando houver qualquer dúvida estrutural → dispatch `spoke-parity-checker` subagent.
>
> **Princípio guia:** sem microsprint formal, sem ADR por tela, sem session log por commit. Cada tela = brainstorm leve → implementa → testa M54 → commit → próxima tela.

---

## Slice 1 — APK distribuível ✅ shipped 2026-05-13 (v1.0.0)

Backend auth real + landing + GraphHopper SP self-hosted + Login/Register Flutter + APK assinado. Closed.

---

## Slice 2 — Telas Core Spoke-aligned (em progresso)

Telas a replicar do Spoke (em qualquer ordem operacional — sem dependências artificiais entre elas exceto onde explicitamente marcado):

- [ ] **Drawer lateral** — lista de rotas agrupadas por período ("Hoje", "Início deste mês"); CTA "Criar rota" full-width pinned no rodapé; 3-dot por linha com renomear/duplicar/excluir. Detalhe em inventory §6.2.
- [ ] **Lista de rotas (RoutesListPage)** — surface alternativa ao drawer pra estados sem rota ativa.
- [ ] **Wizard criar rota** — tela cheia (não sheet); 3 zonas: nome opcional com auto-suggestion, data (Hoje/Amanhã/Escolher data → DatePickerDialog), checkbox "Reutilizar paradas anteriores". Detalhe em inventory §6.2.
- [ ] **Wizard editar rota** — mesma tela parametrizada por `Route?` (null=create, non-null=edit); sem zona "Opções de início rápido". Detalhe em inventory §3.2 item 7b.
- [ ] **Tela ativa de rota** — mapa placeholder full-screen + DraggableScrollableSheet com 2 snap points (collapsed bar + expanded full-screen) + hamburger float top-left + bottom bar (input endereço + OCR + voice + 3-dot kebab). Detalhe em inventory §6.2bis.
- [ ] **Adicionar parada — texto** — busca endereço com autocomplete stub (real autocomplete depende de Nominatim em slice 3).
- [ ] **Adicionar parada — voz** — captura voz, confirmar transcrição, secondary CTA "fale vários endereços" (multi-stop dictation per inventory §3.2 item 10b).
- [ ] **Adicionar parada — OCR** — câmera viewfinder, confirma extração, multi-stop OCR per inventory §3.2 item 10.
- [ ] **Adicionar parada — tap no mapa** — tap em ponto específico cria Stop com lat/lng.
- [ ] **Reordenar paradas** — drag-to-reorder dentro da expanded sheet.
- [ ] **Detalhe da parada** — status (Pendente/Entregue/Falhou + motivo), notas, POD stub (foto real em slice 3).
- [ ] **Editar parada** — modal/sheet com endereço + complemento + notas + tipo de parada.
- [ ] **Otimizar rota** — CTA + loading state + lista reordenada com badge "otimizada" (mock 200 retornando ordem de entrada até slice 3 plugar solver real).
- [ ] **Navegar (turn-by-turn handoff)** — entrega o próximo destino pro Waze/Google Maps via deeplink (ADR-0010, Google Maps default).
- [ ] **Rota concluída** — resumo com paradas entregues + falhas + métricas.
- [ ] **ShareSheet** — WhatsApp + copy link + QR Code (recriar feature original RotPro; existia no slice 1, foi apagada no reset 2026-05-26).
- [ ] **Settings completas** — Spoke tem ~12 settings: app de navegação (Waze/Google Maps), lado da parada (qualquer/direito/esquerdo), tempo médio na parada, tipo de veículo (Carro/Moto/Bicicleta/A pé), evitar pedágios, tema (Auto/Claro/Escuro), ID de parada estilo, balão modo navegação, endereço de casa (slice 5), assinatura (slice 4), indicações (link pra ShareSheet), versão do app. Detalhe em inventory §5.
- [ ] **Comparar planos** — pré-req paywall slice 4. Plano gratuito vs Plano Pago R$ 25,90/30 dias com bullets.
- [ ] **Notification settings** — pré-req FCM slice 3. Toggles: lembrete início rota, atualização status, promoções.
- [ ] **Recuperação de senha (UI)** — campo email + CTA; backend slice 3.
- [ ] **Google Sign-In (UI)** — botão "Continuar com Google" em Login + Register; backend slice 3.

**Done quando:** todas as caixas marcadas + `flutter analyze` + `flutter test` verdes + smoke E2E no Samsung M54 com APK release contra prod API. PR `feat/m2-slice-2-spoke-clone` → develop → tag `v1.1.0`.

---

## Slice 3 — Backend real

- [ ] `POST /routes/optimize` real — solver em-process Node TS (nearest-neighbor + 2-opt) contra GraphHopper matrix; latência alvo <2s pra ≤20 paradas
- [ ] Geocoding endpoint — Nominatim self-hosted SP-capital (per ADR-0008/0016 SP-only)
- [ ] Status de paradas persistido — Prisma migration (`stops` table com status enum + failure_reason + notes + pod_photo_url)
- [ ] Histórico de rotas + métricas (km, tempo, paradas entregues/falhas)
- [ ] Push notifications — FCM setup + 3 tipos: lembrete início, atualização status, promoções
- [ ] Reset senha — endpoint + email transacional
- [ ] Google Sign-In backend — Firebase Auth ou GIS direto (avaliar Context7 antes)
- [ ] Multi-address dictation — voice multi-stop parsing (per inventory §3.2 item 10b)
- [ ] Multi-address OCR — extract N endereços de uma foto (per inventory §3.2 item 10)

---

## Slice 4 — Stripe Pix paywall

Per [ADR-0030](./decisions/0030-stripe-pix-30-day-access-pass.md). R$ 25,90 grants 30 days. Connect 50/50 split via Separate Charges and Transfers. Webhook idempotente em `POST /webhooks/stripe`. Frontend: tela "Comparar planos" + flow Pix (QR + copia-e-cola).

---

## Slice 5 — Sentido casa

Toggle nas settings + campo "Endereço de casa". Solver respeita constraint "rota termina mais perto de casa".

---

## Slice 6 — LGPD

- Exportar dados (botão em settings → JSON download via endpoint backend)
- Excluir conta (cascade delete tudo do usuário + audit log)
- Página de Política de Privacidade (link em settings)
- Página de Termos de Uso (link em settings)
- OSS licenses (página gerada de `pubspec.lock` + npm deps)

---

## Slice 7 — Admin panel

Subapp Next.js (em `apps/landing/` ou novo `apps/admin/`). Auth separada (admin role). Dashboards: MRR, usuários ativos, paradas processadas no mês, rotas otimizadas, taxa de conversão paywall.

---

## Validação contínua

- **`spoke-parity-checker` subagent** ([ADR-0036](./decisions/0036-spoke-parity-checker-functional-gate.md)) — dispatch em qualquer dúvida estrutural (upfront durante brainstorming + closing no D4 de cada PR substancial).
- **`prototype-fidelity-checker` subagent** — só pra tokens visuais (cores/spacing/ícones/typography) no sweep final pós-features. **Não usar durante implementação das telas** — vai estar fora de sync com prototipo enquanto a gente prioriza paridade Spoke.
- **M54 device E2E** em cada commit substancial (`flutter run -d RQCW401G33T --release --dart-define=API_BASE_URL=https://api.roteirizadorpro.com.br --dart-define=APP_ENV=production`).

## Sem mais

- Sem microsprint formal (MS-Ax/MS-Bx)
- Sem ADR por slice (só pra mudanças de stack)
- Sem session log por commit
- Sem brainstorm pra cada decisão (Spoke decide; só perguntar quando Spoke não cobre)
- Sem `prototype-fidelity-checker` durante implementação (só no polish final)
