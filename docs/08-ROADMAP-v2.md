# 08 — Roadmap v2 (reset 2026-05-26 · rewrite 2026-05-27 white-label completo)

> **Estratégia:** **white-label completo do Spoke funcionando 100%** dentro da nossa stack (Flutter + Riverpod + GoRouter + SharedPrefsAsync no mobile; Fastify + TypeBox + Prisma 7 + PostgreSQL + GraphHopper SP-Capital no backend). Quando o app estiver funcionalmente equivalente ao Spoke, Eduardo aplica polish de identidade visual (microcopy PT-BR original + ajustes decorativos + diferenciações de UI) pra não ficar idêntico.
>
> **Catálogo autoritativo de paridade:** [`docs/inventory/2026-05-26-spoke-vs-rotpro.md`](./inventory/2026-05-26-spoke-vs-rotpro.md). Quando houver qualquer dúvida estrutural → dispatch `spoke-parity-checker` subagent. **Leitura obrigatória antes de qualquer microsprint:** §10/§11 da feature respectiva + §12 (features ausentes do inventário inicial) + §13 (ambiguidades pendentes).
>
> **Tokens visuais (per ADR-0035):** cores, spacing, radii, shadows, typography, **ícones Lucide** vêm de [`prototipo/tokens.js`](../prototipo/tokens.js) e devem ser usados **desde commit 1** de cada tela. Polish final só substitui microcopy + decoração. NÃO implementar tela com cores/ícones genéricos pra "ajustar depois" — vira retrabalho.
>
> **Restrições técnicas constantes:**
> - Distribuição: **APK-only** per [ADR-0014](./decisions/0014-apk-distribution.md) (sem Play Store no M2; sem Google Play Billing forçado)
> - Cobertura geográfica: **SP-Capital only** per [ADR-0008](./decisions/0008-graphhopper-self-hosted.md) + [ADR-0016](./decisions/0016-tile-server-strategy.md) (GraphHopper + Nominatim self-hosted). Expansão pra Sudeste fica pós-slice-7.
> - Monetização: **single paid tier R$ 25,90 / 30 dias via Stripe Pix** per [ADR-0030](./decisions/0030-stripe-pix-30-day-access-pass.md) + [`docs/BUSINESS-RULES.md`](./BUSINESS-RULES.md). Trigger paywall = tap em "Iniciar Navegação" (não "Otimizar rota"). Sem free trial, sem free tier limitado.
>
> **Princípio guia:** spec leve por tela (NÃO microsprint formal), dispatch `spoke-parity-checker` no D1 brainstorming + D4 review de cada PR substancial, smoke E2E no Samsung M54 antes de mergear. Commits pequenos, frequentes, descritivos.

---

## Slice 1 — APK distribuível ✅ shipped 2026-05-13 (v1.0.0)

Backend auth real + landing + GraphHopper SP self-hosted + Login/Register Flutter + APK assinado. Closed.

---

## Slice 2 — Telas Core Spoke-aligned (em progresso · objetivo: white-label 100% funcional)

> **Objetivo:** replicar 100% das telas/fluxos Spoke descobertos na inspeção (inventário §10 + §11 + §12) usando nossa stack + tokens visuais do prototipo. Microcopy PT-BR original. Bypass de paywall durante slice 2 (slice 4 implementa paywall real).
>
> **Ordem das áreas:** flexível (sem dependências artificiais exceto onde marcado). Sugestão de ordem operacional: Área 1 → Área 2 → Área 3 → Área 4 → Área 5 → Área 6 → Área 7 → Área 8 → Área 9 → Área 10 (polish final).

### Área 1 — Auth (completar UI)

- [ ] **Recuperação de senha (UI)** — tela `/auth/forgot-password` com campo email + CTA "Enviar link". Backend slice 3.
- [ ] **Google Sign-In (UI)** — botão "Continuar com Google" em `/login` + `/register`. Backend slice 3.

### Área 2 — Rotas (drawer + lista + wizard) — base de tudo

- [ ] **Drawer lateral** — width 90% da tela, scrim 10% direita ("Fechar menu de navegação"). Body com 3 zonas: (a) header user card (avatar + nome + email + plano "Standard · Renova-se em DD/MM/AAAA") + 2 IconButtons topo-direito (Help, Settings) + CTA secundário "Assinar"; (b) lista de rotas agrupadas por período dinâmico ("Próximas rotas" / "Hoje" / "Início deste mês" — ver §11.6); cada item = data abreviada + nome opcional + 3-dot kebab; rota ativa em cor primary (azul); (c) CTA filled primary "Criar rota" pinned no rodapé. Detalhe em inventory §6.2 + §10.1 + §11.6.

- [ ] **Popup 3-dot por rota** — PopupMenu ancorado (não bottom sheet) com 3 ações: "Definir nome e data" / "Duplicar rota" / "Excluir rota". Sem ícones, sem cor destrutiva diferenciada pra "Excluir". Detalhe em inventory §6.2 + §10.2.

- [ ] **Wizard "Criar rota"** — full-screen (NÃO sheet), back-arrow topo-esquerdo. 3 zonas:
  - Zona A: label "Nome da rota (opcional)" + TextField. Placeholder = auto-gerado pattern "[dia-da-semana] Rota [N]" (incrementa por rota do mesmo dia). Se não editar, placeholder vira nome salvo.
  - Zona B: label "Selecione a data" + 3 radio-rows: "Hoje" (pré-selecionado, com data inline) / "Amanhã" (data inline) / "Escolher data" + chevron-right → `showDatePicker` Material 3 PT-BR (ver §11.2 pra confirmação que widget nativo replica visual Spoke).
  - Zona C: label "Opções de início rápido" + checkbox "Reutilizar paradas anteriores" (uncheck default). Quando marcado, CTA muda label e navega pra Área 2.5 (Reutilizar paradas).
  - CTA filled primary "Confirmar" full-width no rodapé. Tap → cria rota, navega imediatamente pra tela ativa (Área 3). Sem modal de sucesso.
  - Detalhe em inventory §6.2 + §10.3 (corrected naming).

- [ ] **Form "Definir nome e data"** — reuso da tela Wizard parametrizada por `Route?` (null=create, non-null=edit). Diferenças quando edit: X close (não back-arrow), título "Editar rota", TextField pré-populado com nome atual, sem Zona C, CTA "Salvar alterações". Detalhe em inventory §10.3.

- [ ] **Tela "Reutilizar paradas" + picker rota fonte** — tela full-screen separada acessada via checkbox marcado no wizard OU via CTA secundário "Copiar paradas de uma rota anterior" no empty state da tela ativa. Body: dropdown "De: [data + nome]" (tap → dialog floating com lista DESC todas rotas + status badge) + 3 ExpansionTile com checkbox por categoria ("Paradas não realizadas" / "Paradas puladas" / "Paradas feitas") + microcopy de empty-state quando categoria vazia + CTA "Copiar paradas" pinned no rodapé (disabled se nenhum item selecionado). RotPro deve **excluir rota corrente do picker** (UX melhor que Spoke). Detalhe em inventory §11.3.

- [ ] **Duplicar rota** — ação do popup 3-dot (Área 2 item 2). Backend slice 3 endpoint `POST /routes/:id/duplicate`. UI: tap → cria cópia em estado draft + navega pra tela ativa da nova rota. Sem confirmação visual.

- [ ] **Excluir rota** — ação destrutiva do popup 3-dot. **Comportamento Spoke não confirmado** (gap §13 — confirmar se abre confirm dialog ou delete imediato). RotPro decision: **SIM, abrir AlertDialog** com Cancelar/Excluir (melhor UX que Spoke se Spoke não tiver).

### Área 3 — Tela ativa de rota (mapa + sheet) — core da app

- [ ] **Mapa Google Maps SDK como base layer full-screen** — `google_maps_flutter` package. SP-Capital bounds. Sem navegação interna RotPro (handoff Waze/GMaps per ADR-0010). Detalhe em inventory §10.5.

- [ ] **DraggableScrollableSheet com 2 snap points (estado VAZIO)** — collapsed (~14% altura, só bottom bar visível) + expanded (full-screen abaixo da status bar). Drag handle horizontal pill centered. Detalhe em inventory §6.2bis.

- [ ] **Sheet AUTO-EXPANDED ao entrar rota com paradas** — quando navega pra rota com `route.stops.isNotEmpty`, sheet abre EXPANDED automaticamente (não collapsed). **Correção crítica vs assumption inicial.** Detalhe em inventory §10.5.

- [ ] **Bottom bar collapsed (estado vazio + estado com stops)** — sticky no topo do sheet collapsed E sticky no topo do sheet expanded. Elementos (esq→dir): hamburger float separado (abre drawer) + TextField "Toque para adicionar" + IconButton OCR (a11y "Ler etiqueta de endereço") + IconButton Voice (a11y "Dite o endereço") + IconButton kebab 3-dot (abre menu Área 6). Detalhe em inventory §6.2bis + §10.5.

- [ ] **Floating map controls** — 2 IconButtons no lado direito visíveis com sheet collapsed: (a) Layer toggle "Alternar modo de mapa" (padrão/satélite); (b) Recenter "Alternar para o mapa" (centra no GPS). Detalhe em inventory §6.2bis.

- [ ] **Empty state expanded (rota sem paradas)** — ilustração + microcopy centralizada + 2 CTAs: filled primary "Adicionar paradas" + text-style "Copiar paradas de uma rota anterior". Detalhe em inventory §6.2bis.

- [ ] **Lista de stops expanded (rota com paradas)** — `ListView.builder` com stop cards. Cada card: número badge esquerda (tabular, "01"/"02"...) + título h6 (nome rua) + subtítulo body2 muted (endereço completo) + status icon direita (color dot pending / ✓ delivered / × failed). Container clickable inteiro (tap abre Área 4 Editar parada). **Long-press e swipe NEGATIVOS confirmado** (§10.7 — tap é única gesture). Detalhe em inventory §10.5.

- [ ] **Section "Configuração de rota" inline no sheet** — 3 rows acima da lista de stops (refletem state da Área 5 Detalhes da rota): "Iniciar no local atual" + clock-with-time + home icon; "Ida e volta" + flag icon; "Sem pausa" + coffee-cup icon. Cada row clickable → reabre sub-tela respectiva. Detalhe em inventory §10.5.

- [ ] **Counter "N paradas" no header sheet** — abaixo da bottom bar, h6. Detalhe em inventory §10.5.

- [ ] **CTA "Otimizar rota" sticky bottom** — filled primary full-width, ícone circular-arrows. Sempre visível mesmo com sheet rolando. Tap → entra no flow Área 7 (Otimização). Detalhe em inventory §10.5.

### Área 4 — Adicionar parada (5 métodos)

- [ ] **Tela "Adicionar parada" entry** — full-screen sheet com header sticky (X close + TextField + OCR + Voice IconButtons) + empty state encorajador (3 method shortcut buttons grandes: Mapa / Leitor / Voz). 3 buttons visíveis SÓ quando input vazio + autocomplete sem resultados. Detalhe em inventory §10.21.

- [ ] **Adicionar parada — texto + autocomplete inline** — typing no TextField triggera autocomplete (debounced 300ms). Slice 2 = stub 4-5 endereços hardcoded SP-Capital quando `input.length >= 3`. Slice 3 = Nominatim SP query real. Tap em resultado → cria Stop + fecha sheet + retorna pra tela ativa com marker no mapa + **auto-abre Editar parada via swipe-up sheet** (per §11.4 BIG FIND). Detalhe em inventory §11.4.

- [ ] **Adicionar parada — voz (single-stop)** — tela dedicada `/stops/voice`. Estado idle → recording (com pulse + amplitude) → transcrito (preview editável + confirm/recapture). Use `speech_to_text` package, locale `pt_BR` hardcoded. CTA secundário "fale vários endereços" leva pra multi-stop dictation (slice 3). Detalhe em inventory §3.2 item 10b.

- [ ] **Adicionar parada — OCR single-stop** — tela `/stops/ocr` com camera viewfinder full-screen + capture button + ML Kit text recognition (`google_mlkit_text_recognition`) + tela de confirmação com endereço extraído editável. CTA secundário "ler manifesto" leva pra multi-stop OCR (slice 3). Detalhe em inventory §3.2 item 10.

- [ ] **Adicionar parada — tap no mapa** — tela `/stops/add-map` com full-screen map + crosshair central + bounds SP-Capital + CTA "Adicionar este ponto" pinned bottom. Tap → reverse geocode (Nominatim slice 3 ou stub slice 2) → cria Stop com lat/lng + endereço resolvido. Detalhe em inventory §10.21.

- [ ] **Adicionar parada — CSV upload (postergado pra slice 3)** — kebab da rota → "Importar manifesto de rotas" → file picker (`.csv/.tsv/.xls/.xlsx`) → parser + UI de mapeamento de colunas. Tracking aqui só pra completude do roadmap; **implementação real em slice 3**. Detalhe em inventory §12.A.6.

### Área 5 — Detalhes da rota (pré-flight Partida/Destino/Pausa)

> **Bloqueio §13.C.2:** confirmar se essa tela é FTUE one-time, per-route ou per-session via Maestro MCP (30 min). Se per-route obrigatório, implementar todo o flow. Se FTUE/per-session, RotPro pode pular essa tela (defaults hardcoded sensatos).

- [ ] **Tela "Detalhes da rota"** — full-screen com X close + título "Detalhes da rota" + 3 seções (Partida / Destino / Pausa) + checkbox "Salvar como padrão" CHECKED default + CTA "Concluído" pinned bottom. Detalhe em inventory §10.4.

- [ ] **Sub-tela Partida — "Usar local atual" picker** — escolha entre GPS atual OU endereço custom (abre search picker tipo Área 4 texto). Detalhe em inventory §13.C.2.

- [ ] **Sub-tela Partida — "Iniciar agora mesmo" time picker** — `showTimePicker` Material 3 PT-BR pra setar horário de início diferente do atual. Útil pra solver considerar traffic patterns. Detalhe em inventory §10.4 + §12.B.8.

- [ ] **Sub-tela Destino — "Ida e volta" toggle + endereço** — switch on/off; quando off, mostra endereço custom picker. Quando on, end-point = start-point automaticamente. Detalhe em inventory §10.4 + §12.B.3.

- [ ] **Sub-tela Destino — "Definir horário de término"** — `showTimePicker` Material 3 PT-BR opcional. Hard deadline; solver tenta respeitar. Detalhe em inventory §10.4.

- [ ] **Sub-tela Pausa — "Adicionar pausa" picker** — sheet com (a) horário início pausa via `showTimePicker`; (b) duração (15min/30min/1h/custom). Solver inclui pausa na otimização. Detalhe em inventory §10.4.

### Área 6 — Editar parada (sheet bottom) — 14 campos

> **Bloqueio §13.C.1:** confirmar antes de finalizar spec se Pacotes/Ordem/Tipo são gated por alguma pré-condição (5 hipóteses listadas). **30 min Maestro pra resolver.** RotPro decision se Spoke ambíguo: implementar SEMPRE ativos.

- [ ] **Sheet "Editar parada"** — DraggableScrollableSheet (NÃO route separada do GoRouter). Auto-expanded ao tap em stop card. Top bar do sheet: IconButton "Ajuda e suporte" esquerda + título "Editar parada" centro + CTA "Concluído" primary direita (save + close). Detalhe em inventory §10.6 + §11.1 + §11.5.

- [ ] **Chip color picker (cor da parada)** — chip clickable horizontal-pill com cor selecionada + label cor. Tap → showModalBottomSheet com 5 opções verticais (Azul/Verde-azulado/Roxo/Rosa/Laranja) + CTAs "Limpar" / "Concluído" no topo + tap-to-dismiss area. Detalhe em inventory §11.1.

- [ ] **Chip package ID display** — chip somente display após otimização (ex: "A1"). Pré-otimização provavelmente picker de format (Moderno A1/A2 vs Clássico 1/2 per setting global §3.3 item 19). Gap §13 pra confirmar.

- [ ] **Card endereço (read-mostly)** — título h6 (nome rua) + subtítulo (endereço completo). Não editável inline; usar "Mudar endereço" abaixo.

- [ ] **Botão "Instruções de acesso"** — outlined-style com + icon. Tap → modal/bottom sheet com TextField multiline (4-6 linhas) + label "Instruções de acesso" + checkbox "Salvar como padrão para este endereço" + CTAs Cancelar/Salvar. **CRÍTICO: instruções ficam sticky NO ENDEREÇO, não na parada** — schema slice 3 precisa modelar `address_defaults` table OU `JSONB meta` em `addresses`. Detalhe em inventory §11.1 + docs Spoke.

- [ ] **TextField "Adicionar notas" + IconButton camera attach** — multi-line input livre + botão pra anexar foto (slice 3 POD). Detalhe em inventory §10.6.

- [ ] **Row "Localizador de pacotes"** — tap → picker visual de posição no veículo (gap não drilled; provavelmente grade representando carro). Slice 2: implementar como input texto livre ("Frente direita" / "Atrás esquerda" / etc.). Slice 3+: melhorar pra picker visual. Detalhe em inventory §10.6.2 item 6.

- [ ] **Stepper "Pacotes"** — - / contador / + (default 1, range 1-99). Detalhe em inventory §10.6.

- [ ] **SegmentedButton "Ordem"** — 3 opções: Primeira / **Automática** (default) / Última. Detalhe em inventory §10.6.

- [ ] **SegmentedButton "Tipo"** — 2 opções: **Entrega** (default) / Coleta. Afeta render dos botões de status no modo delivery (Entregue para Entrega, Coletado para Coleta). Detalhe em inventory §10.6 + §12.B.9.

- [ ] **Row "Horário de chegada"** — valor display "Qualquer momento" default. Tap → time range picker (start-end) pra time window constraint do solver. Slice 2: stub picker. Slice 3: solver respeita constraint. Detalhe em inventory §10.6 + §12.B.7.

- [ ] **Row "Tempo estimado na parada"** — valor display "Padrão (1 min)" default (vem do setting global). Tap → picker de minutos (1/2/3/5/10/custom). Override per-stop do setting global. Detalhe em inventory §10.6.

- [ ] **Row "Mudar endereço"** — search icon + chevron right. Tap → re-abre Área 4 (Adicionar parada) em modo "replace existing". Detalhe em inventory §10.6.

- [ ] **Row "Duplicar parada"** — plus icon + chevron right. Cria cópia da Stop + opens Editar da nova. Detalhe em inventory §10.6.

- [ ] **Row "Remover parada"** — trash icon + **texto VERMELHO** + chevron right. **Única ação com cor destrutiva no inventário.** Tap → AlertDialog confirm "Excluir esta parada?" Cancelar/Excluir. Detalhe em inventory §10.6.

### Área 7 — Otimizar rota (3 estados sequenciais)

- [ ] **Modal FTUE "IDs ajustados" (one-time per account)** — full-screen overlay com hero illustration (3 cartões A1/A2/A3) + título h4 + body explicativo + CTA "Entendi" primary + CTA secundário "Configurar..." (abre setting ID format). Flag `bool hasSeenOptimizeFtue` em SharedPrefsAsync. Detalhe em inventory §10.8.

- [ ] **Estado pós-otimização (PRE-CONFIRM)** — mapa ocupa metade superior, polyline azul conectando markers numerados 1-N, auto-zoom na bounding box. Sheet posição mid (não expanded). Nova linha summary acima do título: "X min · N paradas · D km". Section "Configuração de rota" reduzida (Partida + Destino fundidos numa row "Ponto de partida"). Lista de stops em ORDEM OTIMIZADA com chip "A1"/"A2"/"AN" à direita. Detalhe em inventory §10.9.

- [ ] **3 CTAs especializados (substituem "Otimizar rota" do draft)** — Row no rodapé: "X min" (text verde, não-clickable) / "Refinar" (outline, re-roda otimização) / "Confirmar" (filled primary, lock IDs + transita pra Ready-to-Run). Detalhe em inventory §10.9.

- [ ] **Modal FTUE "IDs definitivos" (one-time per account)** — hero illustration (cadeado + ID badges) + título "Os IDs serão definitivos" + body + CTA "Continuar" primary + CTA "Cancelar" text. Flag `bool hasSeenConfirmFtue` em SharedPrefsAsync. Detalhe em inventory §10.10.

- [ ] **Modal FTUE "Carregar veículo?" (one-time per account)** — hero + título "Tudo pronto para carregar o veículo?" + body + CTA "Continuar" primary (abre Load vehicle — OUT-OF-SCOPE M2; deferred) + CTA "Pular" text (skip pra Ready-to-Run state). Flag `bool hasSeenLoadVehicleFtue` em SharedPrefsAsync. Detalhe em inventory §10.11.

- [ ] **Estado "Ready-to-Run"** — sheet ganha 2 botões em row abaixo do título: "Compartilhar rota em tempo real" (outline com share icon — OUT-OF-SCOPE slice 2; postergado pra slice 3 follow-up live tracking) + "Carregar veículo" (outline com truck icon — OUT-OF-SCOPE M2). CTAs bottom: "X min" verde / "Editar" (outline; abre route builder pra add/remove stops) / **"Iniciar rota"** (filled primary; GATEWAY pro modo delivery). Detalhe em inventory §10.12.

### Área 8 — Modo Delivery (running route)

- [ ] **Tela "Modo delivery" — current stop focused** — mapa top metade centrado na parada atual + polyline + 2 markers visíveis (current + finish flag). Hamburger top-left + ETA finish badge top-right "HH:MM" + flag-finish icon. Floating layer + recenter controls mantêm. Detalhe em inventory §10.13.

- [ ] **Sheet "Stop focused"** — topbar: título h1 (nome rua atual) + X close direita (sair do modo delivery, com AlertDialog confirm). Subtitle: "N/total, HH:MM" (progress + horário atual). Detalhe em inventory §10.13.

- [ ] **3 botões status (render conditional por `Stop.type`)** — Row com 3 botões grandes:
  - **"Navegar"** (filled primary BLUE, SEMPRE renderiza, default selected) — tap → handoff `url_launcher` com `geo:lat,lng?q=address` URI (resolve via Android intent chooser conforme setting "App de navegação" — opções RotPro: GoogleMaps/Waze/Outro per §10.19.1 corrigido).
  - **"Não entregue"** (outline, SEMPRE renderiza) — tap → marca Failed silenciosamente + auto-advance pra próxima parada pending. **SEM picker de razão** (confirmado §10.14). Slice 3: backend persiste `failureReason: String?` editável retroativamente.
  - **"Entregue"** (outline, conditional `stop.type == StopType.delivery`) OU **"Coletado"** (outline, conditional `stop.type == StopType.pickup`) — tap → marca Delivered/PickedUp + auto-advance. Sem confirmation.
  - **PAYWALL TRIGGER:** primeiro tap em "Navegar" verifica `user.isPaid` — se inativo, abre paywall modal slice 4 ANTES de fazer handoff. Per BUSINESS-RULES §5.
  - Detalhe em inventory §10.13 + §12.B.9.

- [ ] **Lista inline abaixo dos botões** — rows clickable: "Adicionar notas" (note icon) / endereço (map icon) / "A1 Originally Nst" (ID badge + posição original) / "Editar parada" (pencil icon) / "Duplicar parada" / "Remover parada" (red). Detalhe em inventory §10.13.

- [ ] **Marker visual encoding no mapa** — pending = N (azul), failed = Nx (escuro), delivered = N✓ (verde), current = N grande destacado + flag-finish nearby. Use `BitmapDescriptor.fromBytes` com SVG render dinâmico. Detalhe em inventory §10.15.

- [ ] **Estado "Destino final" (Ida e volta retorno)** — após todas paradas marcadas, sheet mostra ponto de retorno: título h1 (endereço start), subtitle "Destino, HH:MM", APENAS 2 botões ("Navegar" filled primary + "Rota concluída" outline com check). Lista inline reduzida (só CEP + "Editar destino"). Detalhe em inventory §10.17.

### Área 9 — Conclusão de rota + outras telas core

- [ ] **Tela "Rota concluída!"** — markers do mapa congelados em estado final (4 paradas com ✓/× indicators). Sheet topbar: summary "Término: HH:MM · 0 parada · 0 m" + IconButton add/search (reabre rota pra adicionar mais paradas) + kebab. Lista de stops com timestamps de conclusão. Card central "Rota concluída!" com check verde + título h2 + stats "N paradas · M perdida(s)" + CTA "Copiar paradas para uma nova rota". Detalhe em inventory §10.18.

- [ ] **Kebab da rota concluída** — exatamente as mesmas 3 opções do popup drawer (§10.2), sem opção extra como "Exportar PDF" ou "Compartilhar resumo". **RotPro OPORTUNIDADE:** adicionar 4º item "Compartilhar resumo" (gap Spoke + alinha com ScreenShare RotPro). Detalhe em inventory §10.20.

- [ ] **Reordenar paradas manual** — drag-to-reorder dentro do sheet expanded (pré-otimização). Use `ReorderableListView`. Slice 2 stub: reordena visualmente; slice 3 persiste no backend. Detalhe em inventory §10.5.

- [ ] **ShareSheet (feature original RotPro)** — recriar tela que existia no slice 1 e foi apagada no reset 2026-05-26. Path: `/settings/share`. WhatsApp send + copy link `roteirizadorpro.com.br/download` + QR code com mesmo link. Detalhe em inventory §4 (feature original).

- [ ] **Menu kebab da rota ativa** — bottom sheet modal com 5 opções: "Compartilhar cópia da rota" (peer transfer pra outro motoboy via QR/link — POSTERGAR pós-M2) / "Transferir paradas" (POSTERGAR) / "Copiar paradas..." (clipboard text export — slice 3) / "Ler manifesto de rotas" (OCR multi-stop — slice 3) / "Importar manifesto de rotas" (CSV upload — slice 3). Slice 2: tela existe mas opções abrem snackbar "Em breve". Detalhe em inventory §6.4 + §12.A.5.

- [ ] **Lista de rotas (RoutesListPage)** — surface alternativa ao drawer pra estados sem rota ativa. Tela full-screen com mesma agrupação dinâmica do drawer + CTA "Criar rota". Detalhe em inventory §6.2.

### Área 10 — Settings completas (13 rows + 4 sections via PreferenceActivity-like)

> **Atenção arquitetural:** Spoke usa PreferenceActivity tradicional Android (não Compose). RotPro implementa equivalente com `ListView` + `ListTile` + `SwitchListTile.adaptive` + section headers via `Padding(Text(...))`. Detalhe em inventory §10.19.

- [ ] **Tela Settings raiz** — Scaffold + AppBar "Configurações" + back arrow. ListView com sections + rows. Detalhe em inventory §10.19.

#### Section "Preferências de rota" (7 rows)

- [ ] **Row "App de navegação"** — picker modal radio list 3 opções RotPro: GoogleMaps (default per ADR-0017) / Waze / **Outro** (Android `ACTION_VIEW` com `geo:` URI = activity chooser do sistema). NÃO replicar "Navegação do Spoke" nem Yandex (§10.19.1 corrigido).

- [ ] **Row "Lado da parada"** — picker modal radio list 3 opções: Qualquer (default) / Direito / Esquerdo. `enum StopSidePreference`.

- [ ] **Row "Tempo médio na parada"** — picker numérico, default 1 min. Valores: 1/2/3/5/10/custom. `int avgStopDurationMinutes`. Override per-stop em Editar parada (Área 6).

- [ ] **Row "Tipo de veículo"** — picker modal radio list **5 opções com ícones + subtitle de restrição**: Bicicleta (subtitle "Somente Google Maps") / Scooter / Carro (default) / Caminhão pequeno / **Caminhão grande NÃO suportado** (GraphHopper SP atual não tem perfil truck-large; pós-M2). Detalhe em inventory §10.19.2.

- [ ] **Row "Evitar pedágios" (switch)** — toggle OFF default. Slice 3 backend: passa `avoid=toll` pro GraphHopper.

- [ ] **Row "ID de parada"** — picker tela com 2 radio groups: "Formato" (Moderno A1/A2 default / Clássico 1/2) + "Atribuir IDs" (Depois da otimização default / Conforme as paradas são adicionadas). Detalhe em inventory §10.6.1.

- [ ] **Row "Balão do modo de navegação" (switch)** — toggle ON default. Mostra overlay com info de entrega durante navegação. **RotPro: SE não temos navegação interna, esse setting fica disabled OU é removido.** Decidir no D1 brainstorming.

#### Section "Preferências gerais" (1 row — OUT-OF-SCOPE)

- [ ] ~~Tema~~ — **DESCARTADO per Eduardo 2026-05-26.** RotPro tem tema único do prototipo (dark per ADR-0035 visual identity). Section "Preferências gerais" inteira pode ser removida se sobrar 0 rows.

#### Section "Assinatura" (1 row)

- [ ] **Row "Comparar planos"** — tela informacional (NÃO picker entre tiers). Mostra: preço único R$ 25,90/30 dias + bullets do que está incluído (acesso ilimitado, suporte, atualizações) + CTA "Assinar agora" (abre paywall slice 4). Per ADR-0030. Detalhe em inventory §12.B.10.

#### Section sem header — rodapé legal (4-5 rows)

- [ ] **Row "Endereço de casa"** — picker de endereço via search (tipo Área 4 texto). Stub slice 2 ("Em breve"), implementação real slice 5.

- [ ] **Row "Indicações"** — leva pra ShareSheet (`/settings/share`).

- [ ] **Row "Licenças"** — tela gerada de `pubspec.lock` + npm deps via `flutter_oss_licenses` package. Slice 6 LGPD.

- [ ] **Row "Política de privacidade"** — link externo ou tela in-app. Slice 6 LGPD.

- [ ] **Row "Termos de uso"** — idem privacidade. Slice 6 LGPD.

- [ ] **Row "Versão"** — display only "RotPro vX.Y.Z" (não-clickable). Versão lida de `package_info_plus`.

- [ ] **Row "Sair" (TEXTO VERMELHO)** — destructive logout. Limpa secure storage + invalida session + navega pra `/login`.

### Área 11 — Notification settings (UI stub slice 2; FCM real slice 3)

- [ ] **Tela "Notificações"** — `/settings/notifications`. 3 toggles: "Lembrete início rota" / "Atualização de status" / "Promoções". Persiste em SharedPrefsAsync. FCM topic subscribe/unsubscribe slice 3.

### Área 12 — Modal upsell contextualizado (OUT-OF-SCOPE slice 2; slice 4)

- [ ] **Modal "Termine mais cedo"** — paywall promotion contextual. Template: "{userFirstName}, chegar cedo a casa." + "Motoristas de {userCity} terminam o trabalho mais cedo com as rotas otimizadas do RotPro." + CTA "Termine mais cedo" (abre paywall) + CTA "Cancelar". Trigger a definir (após N opens? após otimizar?). Detalhe em inventory §10.24.

### ✅ Done quando Slice 2 (TODAS as áreas 1-11) marcadas + `flutter analyze` clean + `flutter test` verdes + smoke E2E completo no Samsung M54 com APK release contra prod API. PR `feat/m2-slice-2-spoke-clone` → develop → tag `v1.1.0`.

---

## Slice 3 — Backend real (Spoke parity)

> **Objetivo:** trocar todos os stubs/mocks do slice 2 por implementação real. Backend Fastify v5 + TypeBox + Prisma 7 contra PostgreSQL 16 + GraphHopper SP-Capital + Nominatim SP-Capital + FCM.

### Backend core

- [ ] **`POST /routes/optimize` real** — solver in-process Node TS (nearest-neighbor + 2-opt) contra GraphHopper matrix API. Latência alvo <2s pra ≤20 paradas. Constraints suportadas: start_time, end_time, time_windows (per stop), priority (per stop), avoid_tolls (boolean), vehicle_profile (car/bike/motorcycle/small_truck), home_address (slice 5).

- [ ] **`POST /geocode` endpoint** — proxy Nominatim self-hosted SP-Capital. Limite N requests/min por user. Cache Redis 24h.

- [ ] **Routes schema** — Prisma migration: `routes` table (id, user_id, name, date, status enum, completed_at, total_stops_count, failed_stops_count, duration_minutes, distance_km, optimized_at, confirmed_at, started_at, vehicle_type, avoid_tolls).

- [ ] **Stops schema** — Prisma migration: `stops` table (id, route_id, position_in_route, delivery_id [A1/1 format], type enum [delivery/pickup], status enum [pending/delivered/failed/picked_up], failure_reason, notes, color, packages_count, time_window_start, time_window_end, priority, custom_stop_duration_min, address_id FK, pod_photo_url, status_changed_at, lat, lng).

- [ ] **Addresses schema (sticky data)** — Prisma migration: `addresses` table com `access_instructions` field per ADR-0010 + meta JSONB column. Tabela `address_defaults` opcional ou JSONB embedded.

- [ ] **Reutilizar paradas endpoint** — `POST /routes/:id/copy-stops` aceita source_route_id + filter categories (not_completed/skipped/done). Dedupe por endereço.

- [ ] **Duplicar rota endpoint** — `POST /routes/:id/duplicate`. Copia metadata + stops; reset status pra draft.

### Auth completion

- [ ] **Reset senha** — endpoint `POST /auth/forgot-password` (gera token + envia email transacional via Resend ou similar) + endpoint `POST /auth/reset-password` (valida token + atualiza hash).

- [ ] **Google Sign-In backend** — Firebase Auth ou Google Identity Services direto (avaliar Context7 antes). Issuer + audience validation; auto-create User se não existir.

### Comunicação

- [ ] **FCM push notifications** — setup Firebase Admin SDK no backend. 3 tópicos: `route_reminders` (lembrete início rota) / `status_updates` (atualização status no app) / `promotions` (paywall upsell). Subscribe/unsubscribe via Notification settings (Área 11 slice 2).

### Voice + OCR multi-stop

- [ ] **Multi-address dictation** — parser de transcript pra extrair N endereços de uma frase ("Av Paulista 1000, Rua Augusta 500, Rua Iguape 100..."). Splitter por vírgula/conector + geocode batch + UI de confirmação lista.

- [ ] **Multi-address OCR ("Ler manifesto")** — extrair N endereços de uma foto de lista impressa. ML Kit text recognition + parser de linhas + geocode batch + UI de confirmação.

### CSV import

- [ ] **CSV upload endpoint** — `POST /routes/:id/import-stops` aceita multipart file (`.csv/.tsv/.xls/.xlsx`). Parser SheetJS ou similar + UI de mapeamento de colunas (cliente seleciona qual coluna = endereço, qual = notes, etc.) + geocode batch.

### CSV export (opcional slice 3 ou pós-M2)

- [ ] **CSV export endpoint** — `GET /routes/:id/export.csv`. Schema: route_date, route_name, stop_number, stop_address, stop_eta, driver_name, package_count. Per §12.B.5.

---

## Slice 4 — Stripe Pix paywall

Per [ADR-0030](./decisions/0030-stripe-pix-30-day-access-pass.md) + [`docs/BUSINESS-RULES.md`](./BUSINESS-RULES.md). **Modelo já fechado, sem decisões pendentes.**

- [ ] **Stripe Connect setup** — conta principal RotPro + connected account do cliente. Separate Charges and Transfers (50/50 split).

- [ ] **`POST /payments/create-pix-intent`** — cria PaymentIntent Stripe com `payment_method_types: ['pix']`. Retorna QR code + copia-e-cola code.

- [ ] **`POST /webhooks/stripe` (idempotente)** — recebe `payment_intent.succeeded` + valida signature + atualiza `User.paidUntil = now() + 30 days` + log audit. Idempotência via `Webhook.eventId` unique.

- [ ] **Modal paywall flow** — full-screen overlay (NÃO sheet). Hero ilustração + título "Roteirizador Pro" + preço "R$ 25,90" hero text + bullets do que inclui + CTA "Pagar com Pix" (gera Pix intent) + tela de QR/copia-e-cola + polling status (`GET /payments/:intent_id/status` cada 3s até succeeded).

- [ ] **Paywall trigger logic** — `PaywallController` checa `user.paidUntil > now()` antes de cada tap em "Navegar" (Área 8). Se inativo, abre modal paywall ANTES de fazer handoff. Per BUSINESS-RULES §5.

- [ ] **Server-side enforcement** — middleware nas rotas críticas (`GET /routes/:id`, `POST /optimize`, etc.) verifica `user.paidUntil`. Se inativo, retorna 402 Payment Required. UI trata 402 → abre paywall.

- [ ] **Modal upsell contextualizado** — implementar §10.24 (template "{userFirstName}, chegar cedo a casa." + "Motoristas de {userCity}..."). Trigger: após otimizar rota se `user.paidUntil == null` (nunca pagou).

---

## Slice 5 — Sentido casa

Toggle nas settings + campo "Endereço de casa" (já stubbed em Área 10 slice 2). Solver respeita constraint "rota termina mais perto de casa". Per §12.B.3 — feature mais granular que Spoke Roundtrip.

- [ ] **Backend constraint** — solver respeita `user.homeAddress` como end-point quando `route.endNearHome == true`.

- [ ] **UI toggle por rota** — switch em Detalhes da rota (Área 5 slice 2) "Terminar próximo de casa" (default false).

---

## Slice 6 — LGPD

- [ ] **Exportar dados** — botão em settings → `GET /users/me/export` retorna JSON com tudo do usuário (routes + stops + addresses + payments).

- [ ] **Excluir conta** — botão em settings (RED + confirm dialog double) → `DELETE /users/me`. Cascade delete tudo + audit log com timestamp + reason.

- [ ] **Página de Política de Privacidade** — tela in-app (não link externo) com Markdown renderizado de `apps/mobile/assets/legal/privacy-policy-pt-BR.md`.

- [ ] **Página de Termos de Uso** — idem privacy.

- [ ] **OSS licenses** — tela gerada via `flutter_oss_licenses` package + npm deps via custom script.

---

## Slice 7 — Admin panel

Subapp Next.js 14 + Tailwind em `apps/admin/` (novo) ou expansão de `apps/landing/`. Auth separada (admin role no User table). Dashboards:

- [ ] MRR (Monthly Recurring Revenue) — total pago no mês baseado em `payments.amount * 0.5` (split RotPro)
- [ ] Usuários ativos — usuários com `lastActiveAt` nos últimos 7 dias
- [ ] Paradas processadas no mês — sum `stops.count` em rotas do mês
- [ ] Rotas otimizadas — count `routes.optimizedAt IS NOT NULL` do mês
- [ ] Taxa de conversão paywall — `count(users.paidUntil IS NOT NULL) / count(users)`

---

## ⚠️ Bloqueios conhecidos antes de implementar (ler invent §13)

### Resolver ANTES de spec da tela respectiva:

- **§13.C.1 (🔴 crítico)** — Pacotes/Ordem/Tipo disabled em Editar parada (Área 6). **30 min Maestro** pra testar 4 hipóteses. Bloqueia Área 6.
- **§13.C.2 (🟡 moderado)** — Detalhes da rota é FTUE ou per-route? **5 min Maestro.** Bloqueia decisão Área 5 (replicar ou pular).
- **§13.C.3 (🟡 moderado)** — Instruções de acesso UI real desconhecida. **10 min Maestro com endereço conhecido.** Afeta Área 6.

### Resolver oportunisticamente:

- **§13.C.4 (🟢 menor)** — "Refinar" CTA opções. Drillar quando chegar na Área 7.
- **§13.C.5 (🟢 menor)** — "Compartilhar cópia" vs "Transferir paradas" semântica. Drillar quando chegar na Área 9 kebab.

---

## Validação contínua

- **`spoke-parity-checker` subagent** ([ADR-0036](./decisions/0036-spoke-parity-checker-functional-gate.md)) — dispatch em qualquer dúvida estrutural (upfront durante brainstorming + closing no D4 de cada PR substancial). Per ADR-0037, prefere Maestro MCP pra inspeção (bash fallback).

- **`prototype-fidelity-checker` subagent** — usar **durante implementação** pra validar tokens visuais (cores/spacing/ícones/typography do prototipo) per ADR-0035. NÃO esperar polish final — tokens devem estar corretos commit 1.

- **`flutter-test-author` subagent** — antes de qualquer widget/provider/service novo, dispatch pra escrever failing test primeiro per ADR-0025 + ADR-0031.

- **`flutter-perf-auditor` subagent** — após terminar tela, antes de PR, dispatch pra audit de performance.

- **`adr-guardian` subagent** — antes de PR que toca stack (pubspec/package.json/schema), dispatch pra confirmar ADR existe.

- **M54 device E2E** em cada PR substancial:
  ```bash
  bash apps/mobile/scripts/build-release-apk.sh
  # OR
  flutter run -d RQCW401G33T --release \
    --dart-define=API_BASE_URL=https://api.roteirizadorpro.com.br \
    --dart-define=APP_ENV=production
  ```

---

## Polish final (pós Slice 2-7 completos)

Quando white-label completo estiver funcionando, Eduardo aplica manualmente:

- **Microcopy PT-BR original** — substituir labels/CTAs paraphraseados por copy de marca RotPro
- **Diferenciações decorativas de UI** — animations extras, microinterações, easter eggs que não existem no Spoke
- **Asset finais** — splash screen, app icon, ilustrações de empty state, marketing screenshots
- **Validação visual final** — `prototype-fidelity-checker` full sweep + revisão humana de cada tela

> **Importante:** identidade visual base (cores/tipografia/ícones Lucide) já está aplicada desde slice 2 commit 1 per ADR-0035. Polish final é só ajuste fino, não rework de styling do zero.

---

## Sem mais (princípios operacionais)

- Sem microsprint formal (MS-Ax/MS-Bx) — overhead desnecessário
- Sem ADR por slice (só pra mudanças de stack)
- Sem session log por commit (commits descritivos cobrem isso)
- Sem brainstorm pra cada decisão (Spoke decide; só perguntar quando Spoke não cobre — ver §12 inventory)
- Sem placeholders genéricos de cor/ícone "pra ajustar depois" — tokens prototipo desde commit 1
