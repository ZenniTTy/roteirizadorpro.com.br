# Auditoria do inventário Spoke vs Roteirizador Pro

> **Data:** 2026-05-26 — audit pós §11 (B-followup)
> **Inventário auditado:** `docs/inventory/2026-05-26-spoke-vs-rotpro.md` (1684 linhas, §1-§11)
> **Fontes cruzadas:** 8 WebSearches em help.spoke.com + spoke.com/route-planner + spoke.com/dispatch (App Store/Play Store listings) + observação empírica Maestro
> **Método:** cross-check cada área funcional documentada × docs oficiais Spoke; flagar (A) discrepâncias documentado-X-mas-faz-Y, (B) features oficiais não mapeadas, (C) ambiguidades, (D) duplicações no inventário

---

## ÍNDICE

- A. Discrepâncias críticas (documentado X, mas docs/empirico diz Y)
- B. Features oficiais Spoke NÃO mapeadas no inventário
- C. Ambiguidades por resolver
- D. Duplicações dentro do inventário
- E. Recomendação consolidada

---

## A. Discrepâncias críticas (documentado X, faz Y)

### A.1 — 🔴 CRÍTICO: "Spoke usa Google Maps SDK" (§6.2bis, §10.5, §11.4) é PARCIALMENTE FALSO

**Inventário diz** (§10.5):
> "Arquitetura confirmada: Spoke usa Google Maps SDK (TextureView + fragment_container) como base layer full-screen"

**Inventário diz** (§11.4):
> "Autocomplete é Google Places API (Spoke usa Google Maps SDK)"

**Docs Spoke dizem:**
> "Google-powered navigation has been rolled out on Spoke Route Planner for all plans" + "drivers using Spoke's Internal Navigation automatically receive real-time traffic alerts on their route, with live crowdsourced data **from Spoke, Waze, and Google Maps**"

**Realidade:** Spoke tem **NAVEGAÇÃO INTERNA PRÓPRIA** ("Navegação do Spoke" — picker §10.19.1 opção #1 default). É *Google-powered* (provavelmente usa Google Directions API por baixo dos panos), mas a UI/UX de navegação é construída pela Spoke. O mapa base usa Google Maps SDK, MAS o autocomplete e a navegação não são "Google Places diretamente".

**Por que importa pra RotPro:** a decisão de produto do RotPro é "Google Maps default + Waze toggle" — mas no Spoke real, a opção default não é Google Maps, é Spoke Internal. RotPro pode legitimamente usar Google Maps puro (não temos navegação interna; legal e diferente da Spoke). **Não muda decisão, mas corrige expectativa.**

**Correção sugerida no inventário:** atualizar §6.2bis + §11.4 pra "mapa base Google Maps SDK; navegação default usa Spoke Internal (proprietário); autocomplete provavelmente é Google Places por trás".

---

### A.2 — 🔴 CRÍTICO: Eduardo "Standard" tier — interpretação errada de pricing tiers Spoke

**Inventário diz** (§11.5):
> "Eduardo está no plano 'Standard' (visível no drawer), então NÃO é gating de plano"

**Inventário diz** (§10.6.2):
> "Single monthly plan presentation with 7-day free trial + optimize up to 500 stops per route no plano pago"

**Docs Spoke (confirmado em 2 WebSearches):**
> "Spoke offers three versions: **Free, Lite, and Standard** plans"
> - Free: unlimited features, limit 10 stops/route
> - Lite: limited features, unlimited routes/stops
> - **Standard: $20/month, unlimited features, unlimited routes/stops**

**Conclusão:** o plano "Standard" do Eduardo é o **TOP TIER pago** (mais caro). Então `Pacotes/Ordem/Tipo` disabled NÃO é gating de plano — Eduardo tem acesso a TUDO. **Inventário §11.5 está CORRETO** que não é gating de plano, mas usou raciocínio errado: assumiu "Standard" = tier intermediário (Lite). Na verdade Standard = top tier.

**Implicação:** as 4 hipóteses de §11.5 pro disabled state continuam válidas (precisa pacote ID, mínimo N stops, requer otimização, ou bug). **Adicionar 5ª hipótese:** (e) **trial expirado / billing pending** — `Standard • Renova-se em ter. 09 de jun.` no drawer sugere conta em ciclo normal, mas vale checar se "Renova-se" = "vai expirar em" (negativo) vs "tem licença válida até" (positivo).

**Correção sugerida no inventário:** atualizar §11.5 com pricing tier hierarchy correta (Free < Lite < Standard) + adicionar hipótese (e).

---

### A.3 — 🟡 MODERADA: "Não entregue SEM picker" (§10.14) — docs falam de Reasons

**Inventário diz** (§10.14):
> "tap em 'Não entregue' do modo delivery NÃO abre picker de razão. Stop marcado Failed silenciosamente + sheet auto-advances"
> "Divergência crítica vs documentação oficial Spoke: docs explícitos ('você pode adicionar uma razão de uma lista pré-definida ou customizada') sugerem picker"

**Docs Spoke (validado em 4 WebSearches diferentes):**
- Nenhuma das 4 buscas atuais confirmou existência de picker pré-set + custom como inventário citou.
- Docs mencionam "Failed" como status, mas não detalham UI de razão.
- Snippets recentes (2026): "Confirm whether stop was delivered, failed, or picked up" — sem menção a picker.

**Hipótese mais provável (revisada):** Spoke individual (Route Planner) NÃO tem picker de razão. Picker de razão pode ser feature exclusiva da Spoke Dispatch (B2B tier — onde dispatcher precisa relatar razão pro fim). Quote da §10.6.2 que mencionou "pre-set list" provavelmente veio de doc da Spoke Dispatch ou de marketing genérico.

**Correção sugerida no inventário:** §10.14 está CORRETA na observação empírica. Atualizar §10.6.2 pra remover ou flagar que a fonte "pre-set + custom" pode ser da Dispatch (B2B), não da Route Planner (B2C que o Eduardo usa). **Implicação pra RotPro slice 2: confirmado picker não é necessário.**

---

### A.4 — 🟡 MODERADA: "App de navegação: 5 opções" (§10.19.1) — opção #4 é confusa

**Inventário diz** (§10.19.1):
> "Picker: 'App de navegação' (5 opções): Navegação do Spoke (default) / Google Maps / Waze / Navegador Yandex / Outro"

**Realidade observada:** Yandex aparece porque a Spoke é app **internacional** — incluem Yandex pra cobrir mercado russo + leste europeu. Pra usuário BR (Eduardo), Yandex aparece mas é irrelevante.

**Docs Spoke confirmam:** "use favorite GPS apps (Waze, Google Maps **and more**)" — não específicam Yandex publicamente.

**Implicação pra RotPro:** correto excluir Yandex (escopo RotPro — só GMaps + Waze). Mas inventário deve flagar que **a opção "Outro"** abre `Android intent chooser` (ACTION_VIEW geo: URI) pra que o usuário escolha qualquer app de mapa instalado. RotPro pode replicar essa opção pra dar flexibilidade ao usuário com 1 linha de código (Spoke faz isso "de graça" via Android intent system).

**Correção sugerida no inventário:** adicionar nota em §10.19.1 sobre "Outro" = ACTION_VIEW intent fallback + sugestão RotPro pra incluir como opção 3.

---

### A.5 — 🟡 MODERADA: "Compartilhar cópia da rota" (§3.2 item 13, §6.4 item 1) — função possivelmente confundida

**Inventário diz** (§3.2 item 13):
> "Compartilhar cópia da rota (sair do app) | Temos ShareSheet próprio (WhatsApp + link + QR) | Manter o nosso — é feature original RotPro e Eduardo confirmou que fica"

**Inventário diz** (§6.4 item 1):
> "Compartilhar cópia da rota — export pra outro app (Share Intent Android)"

**Docs Spoke (NOVA descoberta nesta auditoria):**
> "share your route with **real time updates** as to the deliveries you have made and the **forecasted time for the rest of your deliveries** which is updated with every delivery"
> "drivers can quickly and easily send and receive stops from other Spoke Route Planner users in just a few clicks, using a **QR code, link, sharing, or by downloading**"

**Realidade:** "Compartilhar" na Spoke tem **2 funções distintas que podem estar misturadas no inventário:**

1. **Compartilhar cópia da rota** (§6.4 item 1) → enviar paradas pra OUTRO USUÁRIO Spoke (motoboy passa rota pra colega via QR/link). Equivalente ao "transferir paradas" (§6.4 item 2)? Possível overlap.

2. **Compartilhar rota em tempo real** (§10.12) → live tracking pra CLIENTE/DESTINATÁRIO ver ETA. Confirmado em docs como "share your route with real time updates" — vinculado a notifications.

3. **Compartilhar resumo de rota concluída** (§10.20) — Spoke NÃO tem isso (gap real, RotPro pode adicionar como feature original).

**Implicação pra RotPro:**
- ScreenShare RotPro original = #3 (compartilhar `roteirizadorpro.com.br/download` pra captar novos motoboys) — NÃO é equivalente a nenhum dos 3 Spokes.
- §3.2 item 13 decisão "Manter o nosso" está OK, mas misnomenclatura: NÃO é "manter no lugar de" a função Spoke porque são funções diferentes.
- **Real time sharing** (#2) e **Send stops to driver** (#1) são features Spoke NÃO mapeadas explicitamente como gaps no inventário.

**Correção sugerida no inventário:**
- Atualizar §6.4 item 1 + §3.2 item 13 pra distinguir os 3 conceitos:
  - "Compartilhar rota com cliente em tempo real" (live tracking)
  - "Enviar paradas pra outro motoboy" (peer transfer)
  - "Compartilhar app pra novos usuários" (RotPro ScreenShare — não tem equivalente Spoke)
- Adicionar Real time sharing + Send to driver como gaps em §3 ou §11 (decisão: replicar? postergar?).

---

### A.6 — 🟢 MENOR: "Adicionar parada via 4 métodos" (§3.2/§6.3/§10.21) — falta scanner OCR explicitamente

**Inventário diz** (§10.21):
> "4 métodos no total: Texto (autocomplete), Mapa (tap-no-mapa), Leitor (OCR), Voz"

**Docs Spoke confirmam:**
> "find and add stops easily using **keypad, voice, or spreadsheet upload**" (oficial Spoke)
> "scan addresses with the phone's camera" (snippet)

**Realidade:** Spoke documenta 4-5 métodos: keypad (texto), voice, spreadsheet upload (CSV import), camera scan (OCR), e tap-on-map. **Inventário está completo** mas mistura tap-on-map (single stop) com CSV upload (bulk import) — são features diferentes.

**Correção sugerida no inventário:**
- §10.21 menciona 3 method buttons (Mapa/Leitor/Voz) + Texto (input no header) = 4 métodos.
- **Faltou explicitamente:** CSV upload (Spoke documenta `.csv/.tsv/.xls/.xlsx/.xlm/.txt`). Aparece como "Importar manifesto" no kebab §6.4 item 5 + §11.7 gap #22 — então NÃO foi totalmente perdido, só não conectado.
- Adicionar cross-ref entre §10.21 e §6.4 item 5 explicitando CSV como 5º método de bulk.

---

### A.7 — 🟢 MENOR: "Editar rota" (§3.2 item 7b, §10.3) — pode estar enganando o nome real

**Inventário diz** (§10.3):
> "Form 'Editar rota' (parametrização do wizard — confirma §3.2 item 7b). Acesso: drawer → 3-dot de qualquer rota → 'Definir nome e data'"

**Docs Spoke:**
> "Edit route button at the top of the panel, which will open the route builder where you can add or remove stops"

**Realidade:** Spoke tem 2 "edit route" diferentes:
1. **"Definir nome e data"** (kebab popup §10.2) — só metadata (nome + data), não adiciona/remove stops. Esse é o que §10.3 mapeou.
2. **"Edit route" button no topo do panel** (docs) — abre route builder pra **adicionar/remover stops**. Possivelmente o "Editar" CTA do estado Ready-to-Run §10.12.

**Confusão potencial:** "Editar rota" o nome também aparece em §10.12 mas é diferente de §10.3 ("Definir nome e data").

**Correção sugerida no inventário:**
- Renomear §10.3 pra "Form 'Definir nome e data'" pra evitar confusão.
- Adicionar nota em §10.12 que "Editar" (outline CTA) provavelmente abre route builder pra editar **stops** (diferente do "Definir nome e data" do kebab).

---

## B. Features oficiais Spoke NÃO mapeadas no inventário

### B.1 — 🔴 CRÍTICO: Disruption alerts (live traffic crowdsourced) — TOTALMENTE AUSENTE

**Docs Spoke:**
> "If drivers encounter a traffic issue that has yet to be reported, they can **add information about the disruption**, which will instantly become visible on the map, helping other drivers avoid the same problem. Drivers can report different types of disruptions including **crash, congestion, police, mobile speed camera, roadworks, lane closure, stalled vehicle or object on road**"
> "Drivers using Spoke's Internal Navigation automatically receive real-time traffic alerts on their route, with live crowdsourced data from Spoke, Waze, and Google Maps"

**Inventário:** **ZERO menção.** Nenhuma seção (§1-§11) menciona disruption alerts.

**Implicação pra RotPro:** este é um diferencial competitivo da Spoke (e similar ao Waze). Slice 2 NÃO precisa, mas é gap real do white-label.

**Decisão proposta:** **Postergar pós-M2** (depende de infraestrutura de crowdsourced events + tier de usuários ativos pra dados serem úteis). Adicionar como item §3.4 novo + §7.3 ("Postergar").

---

### B.2 — 🔴 CRÍTICO: Battery saver mode — TOTALMENTE AUSENTE

**Docs Spoke:**
> "A battery saver option in Navigation Settings keeps your device cooler and extends battery life during navigation"
> "Battery saver mode reduces map motion/screen updates and dims screen brightness when using Internal Navigation"

**Inventário:** §10.19 (Settings completas) lista 13 items mas **NENHUM é Battery saver**. Pode ser sub-section de "App de navegação" ou estar em Settings raiz que não inspecionamos no nível certo.

**Implicação pra RotPro:** se temos navegação interna no futuro (não temos no escopo M2 — usamos handoff Waze/GMaps), battery saver é dep. **Pra escopo M2 atual: irrelevante.**

**Decisão proposta:** **Descartar** (pré-requisito é navegação interna, que está fora de escopo). Adicionar como item §7.4 ("Descartar definitivamente").

---

### B.3 — 🟡 MODERADO: Roundtrip / "Return to starting location" — REFERENCIADO mas não drilled

**Docs Spoke:**
> "Spoke recommends selecting Roundtrip if you are a courier — make your start and end location the same place"
> "you can hit 'Return to starting location', and Spoke will populate the end location address automatically"

**Inventário:** §10.4 menciona "Ida e volta" (Row no Detalhes da rota) mas não drilled o picker. §10.17 mostra estado "Destino final" como resultado de roundtrip ativo. Conectado mas underspec.

**Implicação pra RotPro:** **isto é exatamente o que slice 5 ("Sentido casa") faz** — roundtrip = end at start location. RotPro nosso é mais granular (end at *home* address, não necessariamente start). Slice 5 é melhor que Spoke roundtrip pra UX motoboy BR.

**Decisão proposta:** **Manter slice 5 (Sentido casa) como está**, mas adicionar opção "Ida e volta" (roundtrip simples) como sub-opção no Detalhes da rota se replicarmos essa tela. **Não conflita com slice 5.**

---

### B.4 — 🟡 MODERADO: Start time + Driving speed + Delivery speed (route-level settings) — AUSENTE

**Docs Spoke:**
> "You can edit the route start/end location, start/end time, **maximum number of stops, driving speed and delivery speed**, and these changes will be **automatically saved and will only apply to that route**"

**Inventário:** §3.3 settings tem "Tempo médio na parada" (item 16) mas é **global setting**, não per-route override. **Spoke permite override per-route** desses parâmetros + adiciona "driving speed" + "delivery speed" + "max stops" que NÃO estão no inventário.

**Implicação pra RotPro:**
- "Tempo médio na parada" per-route override = adicionar à tela "Detalhes da rota" §10.4 quando replicarmos
- "Driving speed" / "Delivery speed" = parâmetros pro solver (slice 3 backend) — útil pra motoboy ajustar ETA baseado em condições reais
- "Max stops" = enforce no front (UX warning quando rota passa de N)

**Decisão proposta:** **Adicionar como opcional slice 3 backend** (depende do solver). Per-route override no §10.4 Detalhes da rota é nice-to-have. Adicionar como item §3.5 ou §3.4 novo.

---

### B.5 — 🟢 MENOR: CSV import / Export — REFERENCIADO mas underspec

**Docs Spoke:**
> "Spoke accepts CSV, TSV, XLS, and XLSX file formats for importing stops, and during import Spoke will ask questions to verify your data is correct"
> "Every plan type provides options to **print a manifest or export route data as a CSV file**, including route date, route name, stop ETA, stop number, address, driver, and package count"

**Inventário:** §6.4 item 5 ("Importar manifesto") + §3.2 item 9 ("Importar manifesto de rotas — postergar"). Mas **NÃO documenta exportar CSV** (oposto da importação). Print manifest também underspec.

**Implicação pra RotPro:**
- Export CSV é trivial técnico (transformar `Stop[]` em CSV) mas valioso pro motoboy (backup/relatório fiscal)
- Print manifest = gerar PDF formatado pra impressora — Spoke faz, RotPro não

**Decisão proposta:**
- **Export CSV:** adicionar slice 3 ou pós-M2 (1 dia esforço, valor real)
- **Print manifest:** postergar (requer Cloud Print ou similar, baixo valor BR onde motoboys raramente imprimem)

---

### B.6 — 🟡 MODERADO: POD (Proof of Delivery) granularidade — FALTA SIGNATURE

**Inventário diz** (§3.4 item 33):
> "Foto de entrega (POD — proof of delivery) — Replicar — Slice 3 backend (storage de imagem)"

**Inventário diz** (§3.4 item 34):
> "Assinatura digital do destinatário — Postergar — Feature avançada"

**Docs Spoke:**
> "Proof of Delivery (POD) can be either a **signature or a photo** of where your driver left the package"
> "With **signature capture**, your delivery driver can use their smartphone to collect the customer's signature. You don't need any kind of smart pen, the customer can just use their finger to sign"
> "Planners can choose what kinds of proof of delivery to accept (photo and/or signature), and **whether POD is optional or not**"

**Realidade:** Spoke trata POD como sistema unificado com 2 modos (foto / assinatura) + setting "obrigatório vs opcional". Inventário separa em 2 features distintas (foto = replicar, assinatura = postergar).

**Implicação pra RotPro:** decisão atual está OK (foto é 80% do valor; assinatura é nice-to-have pra B2B). Mas conceitualmente são parte do mesmo sistema, não 2 features separadas.

**Decisão proposta:** **manter decisão atual** mas reagrupar no roadmap como "POD slice 3 = foto MVP; assinatura = pós-M2 extension". Atualizar §3.4 pra refletir essa unificação conceitual.

---

### B.7 — 🟢 MENOR: Time windows + Priority por parada — AUSENTE

**Docs Spoke:**
> "You can set **delivery time windows** and **priority levels** for specific stops, and customize the amount of time to spend at each stop"
> "When the app optimizes a route, it checks stops and pickups labeled as time-sensitive and creates a course that makes sure you get to the **top-priority addresses before or on time**"

**Inventário:** §10.6 (Editar parada) menciona "Horário de chegada — Qualquer momento" — confirmado field existe mas **comportamento de janela** (start-end vs single time) não drilled. **"Priority" totalmente ausente.**

**Implicação pra RotPro:**
- Time window por parada = útil pra rotas com cliente "só recebe entre 10-12h" — afeta solver
- Priority por parada = útil pra entregas urgentes/premium — afeta solver

**Decisão proposta:** **Slice 3 backend follow-up** (depende do solver suportar constraints). Adicionar:
- §10.6 atualizar com hipótese: "Horário de chegada" pode ser **range picker** (start-end), não single time picker
- §3.4 ou §3.5 novo item: "Janela de horário por parada" + "Prioridade por parada"

---

### B.8 — 🟢 MENOR: "Set delivery time windows" no nível ROUTE também — AUSENTE

**Docs Spoke:**
> "Adding a **start and end time** will help Spoke Route Planner take expected traffic into account when optimizing routes"

**Inventário:** §10.4 (Detalhes da rota) menciona "Definir horário de término" (placeholder, não drilled). Mas **não há "Definir horário de início"** explícito — assume-se "Iniciar agora mesmo" sempre.

**Implicação pra RotPro:** start time per-route é dep pra solver considerar traffic patterns por hora. Slice 3 importante.

**Decisão proposta:** drillar §10.4 picker "Iniciar agora mesmo" pra confirmar se aceita "Iniciar às HH:MM" no futuro. Atualizar §10.4 inventário quando drilled.

---

### B.9 — 🟢 MENOR: Picked up status (terceiro estado) — POUCO DEVELOPADO

**Inventário diz** (§10.6.2):
> "Status de entrega tem TRÊS estados (não dois): Spoke confirma Delivered, Failed, Picked up"

**Inventário diz** (§10.13 obs #4):
> "Sem botão 'Picked up' visível. Hipótese confirmada: appears only quando Stop.tipo == Coleta"

**Status real no inventário:** documentado como **hipótese**, não validado empiricamente.

**Implicação pra RotPro:** se hipótese certa, é simples render conditional. Se errada (ex: Picked up é setting global ou aparece em outra UI), arquitetura muda.

**Decisão proposta:** **Spoke deep-drill quando slice 2 chegar no Delivery mode** — criar Stop com `type: Coleta` e verificar UI no modo delivery.

---

### B.10 — 🟢 MENOR: Maximum stops setting — AUSENTE

**Docs Spoke:**
> "You can edit the route start/end location, start/end time, **maximum number of stops**, driving speed and delivery speed"

**Inventário:** zero menção a "maximum stops" como setting per-route ou global. **Spoke Free tier limita 10 stops** (mencionado em pricing) — então isto pode ser **enforce de plan, não setting**.

**Implicação pra RotPro:** slice 4 (Stripe Pix) pode usar similar — usuário free vê limite, paga R$ 25,90 = ilimitado. Ou usuário paga sempre, ilimitado sempre. Decisão de produto, não engenharia.

**Decisão proposta:** **discutir com Eduardo na slice 4 planning** — RotPro free trial gating? Ou tudo gated pela paywall sem free? ADR-0030 não detalha. Adicionar como gap pra resolver antes do slice 4.

---

## C. Ambiguidades por resolver

### C.1 — 🔴 CRÍTICO: "Pacotes / Ordem / Tipo disabled" — hipóteses não validadas (§11.5)

5 hipóteses listadas (a-e per esta auditoria). **Nenhuma testada.** Bloqueio: requer ciclo de teste no device.

**Próximo passo proposto:** sessão dedicada de 30 min:
1. Preencher "Localizador de pacotes" → reabrir Editar parada → verificar se Pacotes ativa
2. Criar rota com ≥3 paradas → verificar se Ordem/Tipo ativam
3. Otimizar uma vez + cancelar → verificar se controls ficam ativos pós-flush
4. Trocar pra account Lite/Free → verificar se tier afeta

---

### C.2 — 🟡 MODERADO: "Detalhes da rota" — opcional ou obrigatório? (§10.4)

**Inventário diz** (§10.4):
> "Trigger: ao tocar em uma rota com paradas no drawer pela primeira vez (não toda vez? requer verificação — pode ser comportamento 'uma vez por sessão' ou 'até salvar como padrão'). O checkbox 'Salvar como padrão' na parte de baixo da tela (default CHECKED) sugere que após primeira config, próximas entradas pulam esta tela."

**Não validado empiricamente.** Pode ser FTUE (one-time per account), per-route, ou per-session.

**Implicação pra RotPro:** se FTUE, slice 2 pode pular essa tela inicial (Eduardo + cliente decidem). Se obrigatória per-route, é flow mandatório.

**Próximo passo proposto:** entrar em rota existente JÁ COM paradas, ver se "Detalhes da rota" abre novamente ou pula direto pra tela ativa de rota.

---

### C.3 — 🟡 MODERADO: "Instruções de acesso" tap não abriu (§11.1) — UI real desconhecida

**3 hipóteses listadas no inventário.** Não testada validação em endereço diferente, hit-area maior, ou versão diferente do Spoke.

**Próximo passo proposto:** criar Stop com endereço **bem dentro da cidade do Eduardo** (não Ribeirão Preto distante) + tap "Instruções de acesso". Se ainda não abrir, abrir via tap-and-hold ou inspecionar via Maestro `tapOn: id` (não `point`).

---

### C.4 — 🟢 MENOR: "Refinar" CTA pós-otimização (§10.9) — opções não drilled

**Inventário diz** (§10.9):
> "Refinar: re-roda otimização (talvez com opções pra ajustar configurações)"

**Especulação.** Não drilled.

**Próximo passo proposto:** tap "Refinar" em rota otimizada de teste; capturar UI (provavelmente sheet com checkboxes/sliders pra ajustar prioridades).

---

### C.5 — 🟢 MENOR: "Mudar endereço" e "Duplicar parada" em §10.6 — sem drill

Listados como pendentes em §11.7. **Comportamento provável** (re-abrir search + clone stop) **não confirmado.**

---

## D. Duplicações dentro do inventário

### D.1 — 🟡 Editar parada documentado 3x (§6.2bis indireto, §10.6, §11.1, §11.5)

**Não é problema** — cada seção adiciona contexto:
- §6.2bis (inferido) — não documentou explicitamente
- §10.6 — primeira tela completa (pós-otimização)
- §11.1 — drill chip cor + docs "Instruções acesso"
- §11.5 — drill em rota não-otimizada + critical finding de disabled controls

**Recomendação:** consolidar numa única §X.Y "Editar parada (canonical)" com cross-refs pra histórico de drills. Reduz risco de leitura pular informação chave de uma das 4 seções.

---

### D.2 — 🟡 Settings documentado 4x (§3.3, §5, §10.19, §10.19.1-3)

**Similar a D.1** — cada vez agregando profundidade. Aceitável mas:
- §3.3 = decisões (replicar/postergar/descartar) com 17 items
- §5 = árvore hierárquica
- §10.19 = inspecionado real (13 rows + 4 sections — **divergence: 17 ≠ 13**)
- §10.19.1-3 = pickers individuais

**Discrepância numérica:** §3.3 menciona 17 items; §10.19 documenta 13 rows + 4 sections (= 17 elementos totais? Aritmética não bate). Conferir.

**Recomendação:** criar §X.Y "Settings tree (canonical)" com hierarquia única + decisões inline (replicar/postergar/descartar) por item. Eliminar §3.3 + §5 ou referenciar a §10.19.

---

### D.3 — 🟢 Tela ativa de rota documentada em §6.2bis + §10.5

**§6.2bis** documentou estado vazio (sheet collapsed default).
**§10.5** corrigiu pra dizer que com stops, sheet abre auto-expanded.

**§6.2bis está semi-deprecada.** Mantém valor histórico mas leitor pode confundir.

**Recomendação:** adicionar header em §6.2bis: "⚠️ Esta seção descreve estado VAZIO; pra estado com paradas ver §10.5."

---

### D.4 — 🟢 Drawer documentado 3x (§6.2, §10.1, §11.6)

Similar a D.1-D.3. Aceitável.

**Recomendação:** mesma lógica D.1.

---

## E. Recomendação consolidada

### Prioritárias (fazer antes do próximo slice de implementação)

1. **A.1** — Corrigir "Spoke usa Google Maps SDK puro" em §6.2bis, §10.5, §11.4 → mapa base sim, navegação não.
2. **A.2** — Corrigir hierarchy pricing (Free < Lite < Standard) em §11.5 e §10.6.2.
3. **A.3** — Reconciliar "Não entregue picker" — provavelmente Dispatch-only feature, RotPro slice 2 NÃO precisa.
4. **A.5** — Distinguir 3 conceitos de "compartilhar" no inventário (peer transfer / live tracking / app share) com sub-decisões.
5. **B.1** — Adicionar "Disruption alerts" como gap mapeado (descartar formal pós-M2).
6. **C.1** — Sessão dedicada de 30 min pra testar 5 hipóteses do "Pacotes/Ordem/Tipo disabled".

### Médias (resolver no slice que tocar a área)

7. **A.4** — Adicionar "Outro" como opção real do nav app picker.
8. **A.7** — Renomear §10.3 pra "Definir nome e data" pra evitar confusão com §10.12 "Editar".
9. **B.3-B.4** — Mapear Roundtrip + Start time + Driving/delivery speed quando drillarmos §10.4.
10. **B.7** — Confirmar se "Horário de chegada" é range picker; adicionar Priority por parada como gap.
11. **C.2-C.5** — Drillar Detalhes da rota / Instruções de acesso / Refinar / Mudar endereço / Duplicar parada quando slice respectivo chegar.

### Baixas (cosmético / consolidação)

12. **D.1-D.4** — Refactor inventário pra ter sections canonicalizadas (Editar parada / Settings / Tela ativa / Drawer) com cross-refs pros drills históricos.
13. **B.5-B.6** — Conceituar POD como sistema unificado (foto + assinatura + obrigatoriedade).
14. **B.9-B.10** — Decidir pricing tier model RotPro (free trial gating sim/não).

### Não-acionáveis (descartar)

15. **B.2** — Battery saver = só faz sentido se RotPro tiver navegação interna. **Descartar** definitivamente.

---

## Resumo numérico

- **A. Discrepâncias críticas:** 7 (2 críticas, 3 moderadas, 2 menores)
- **B. Features Spoke ausentes do inventário:** 10
- **C. Ambiguidades por resolver:** 5
- **D. Duplicações:** 4 (todas aceitáveis mas refactoráveis)

**Decisão geral:** inventário está **estruturalmente saudável** mas tem **erros pontuais críticos** (A.1, A.2, A.3) que devem ser corrigidos imediatamente pra não enviesar decisões de implementação. As features ausentes (B) majoritariamente caem em "postergar pós-M2" ou "descartar" — poucos gaps reais bloqueiam slice 2.

**Próximo passo proposto:**
1. Aplicar correções A.1-A.5 inline no inventário (30 min)
2. Adicionar §10.X coverage map V3 com features B.1-B.10 categorizadas
3. Sessão dedicada de 30 min pra resolver C.1 (validar 5 hipóteses Pacotes/Ordem/Tipo)
4. Refactor D.1-D.2 (consolidar Editar parada + Settings sections) — opcional, ganho de legibilidade

Tudo committed na branch `chore/spoke-inventory-b-followup` ou em novo PR de correção.
