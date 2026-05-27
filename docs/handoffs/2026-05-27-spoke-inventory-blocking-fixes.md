# Handoff: bloqueios §13 do inventário Spoke (resolver via Maestro MCP)

> **Created:** 2026-05-27
> **Target:** próxima sessão / outro agent que vá resolver os bloqueios do inventário Spoke
> **Status atual:** 3 bloqueios listados, 0 resolvidos
> **Tempo total estimado:** ~45 min de Maestro MCP no Samsung M54

---

## 0 — Contexto pra agent novo (zero context)

### Quem é Eduardo e o que é o projeto?

Eduardo Rodrigues é o desenvolvedor do **Roteirizador Pro** (RotPro), um app Android pra motoboys distribuído como APK em `roteirizadorpro.com.br`. O projeto é um **functional fork** do Spoke (ex-Circuit Route Planner): replica fluxos, comportamentos, telas — mas não copia identidade visual (cores/ícones/microcopy). Per [ADR-0010](../decisions/0010-clone-positioning.md).

Eduardo está no M2 (segundo milestone). Slice 1 (APK distribuível) shipped 2026-05-13 como `v1.0.0`. Slice 2 (Telas Core Spoke-aligned) está em progresso.

### O que é o inventário Spoke e por que existem bloqueios?

`docs/inventory/2026-05-26-spoke-vs-rotpro.md` é o **catálogo autoritativo** de paridade Spoke ↔ RotPro. Foi construído em 3 fases via inspeção live do app Spoke (`com.underwood.route_optimiser` v3.65.1) no Samsung M54 do Eduardo (device ID `RQCW401G33T`):

1. **Fase inicial (§1-§9):** bash + `adb shell uiautomator dump` + screencap
2. **Fase B (§10):** Maestro MCP `inspect_screen` (mais eficiente, paste-verbatim hierarchy)
3. **Fase B-followup (§11):** drills profundos via Maestro MCP em estado editável
4. **Audit 2026-05-26 (§12-§13):** cross-check sistemático com docs oficiais Spoke via WebSearch

Durante esses drills, identificamos **3 comportamentos da Spoke que não conseguimos validar empiricamente** porque exigiam estados específicos do device ou ações destrutivas que pulamos. Esses 3 itens viraram §13 do inventário e bloqueiam a spec de telas específicas do slice 2.

### O que é Maestro MCP?

Per [ADR-0037](../decisions/0037-maestro-mcp-for-spoke-inspection.md), Maestro CLI 2.6+ ships um servidor MCP (`maestro mcp`) que expõe primitivas como `inspect_screen` / `tap_on` / `take_screenshot` / `launch_app` como ferramentas MCP. Quando Claude Code está rodando, essas ferramentas ficam disponíveis como `mcp__maestro__*`.

**Pré-requisitos pra essa sessão funcionar:**

1. Samsung M54 conectado via USB
2. ADB autorizado (`adb devices` deve mostrar `RQCW401G33T device`)
3. Maestro CLI instalado (`MAESTRO_CLI_NO_ANALYTICS=1 maestro --version` deve retornar 2.6.0+)
4. App Spoke aberta no M54 com Eduardo logado (conta `eduardoteishoku@gmail.com` plano Standard)
5. `/mcp` no Claude Code deve listar `maestro ✅ connected`

Se algum desses falhar, consultar ADR-0037 + `MAESTRO_CLI_NO_ANALYTICS=1 maestro doctor`.

### Disclaimers legais (NÃO violar)

Per ADR-0010:
- ✅ **Permitido:** descrever estrutura (hierarquia, classes Android, bounds, content-description, IDs de recurso, gestos inferíveis), número/ordem de elementos, fluxos de navegação
- ❌ **Proibido:** copiar microcopy verbatim da Spoke (>5 palavras consecutivas) pro inventário ou roadmap
- ❌ **Proibido:** copiar ícones, ilustrações, paleta, tipografia
- ❌ **Proibido:** decompilar APK, extrair recursos
- ❌ **Proibido:** commit de screenshots (vive só em `/tmp/spoke-inspection/`, gitignored per ADR-0036)

### Autorização pré-concedida pelo Eduardo

> "Sim, autorizado tudo (criar rotas teste, deletar, taps em qualquer coisa)"
> Modo autônomo total — pode criar rotas teste, otimizar, marcar Failed/Delivered, deletar, etc., sem perguntar a cada passo.

---

## 1 — Os 3 bloqueios pra resolver

### 1.1 — Sumário

| ID | Severidade | Item | Tempo | Bloqueia área do Slice 2 |
|---|---|---|---|---|
| **§13.C.1** | 🔴 Crítico | Pacotes/Ordem/Tipo disabled em Editar parada (4 hipóteses) | 30 min | Área 6 (Editar parada — 14 campos) |
| **§13.C.2** | 🟡 Moderado | "Detalhes da rota" é FTUE one-time, per-route, ou per-session? | 5 min | Área 5 (Detalhes da rota — 5 sub-screens) |
| **§13.C.3** | 🟡 Moderado | "Instruções de acesso" tap não abriu UI nas tentativas anteriores | 10 min | Área 6 (Editar parada) |

**Recomendação de ordem:** C.2 → C.3 → C.1 (mais rápido pra mais demorado; C.1 precisa setup de rota teste maior).

### 1.2 — Por que esses bloqueios importam

Cada um afeta a **arquitetura do RotPro** de forma material:

- **C.1:** se Pacotes/Ordem/Tipo são gated por algum trigger (ex: pré-preenchimento de outro campo), RotPro precisa replicar o gating ou pode quebrar contratos do solver. Se for bug Spoke, RotPro implementa sempre ativos. Diferença = ~2 dias de retrabalho se descobrir errado em produção.

- **C.2:** se "Detalhes da rota" é per-route obrigatório, RotPro precisa implementar a tela inteira (5 sub-screens) como step mandatório. Se é FTUE one-time, RotPro pode pular e usar defaults hardcoded sensatos (economia de ~3 dias).

- **C.3:** "Instruções de acesso" é feature crítica do schema backend (sticky-to-address per ADR-0010). Se UI abre full-screen, RotPro implementa route separada. Se inline TextField, é só widget dentro do Editar parada sheet. Diferença = decisão arquitetural slice 2.

---

## 2 — Protocolo de resolução: §13.C.2 (Detalhes da rota — 5 min)

### Hipótese atual

Checkbox "Salvar como padrão" CHECKED by default sugere comportamento "abre primeira vez, depois pula" (FTUE one-time per account).

### Impacto se hipótese errada

- **Se per-route obrigatório:** RotPro implementa a tela inteira como step mandatório no Criar rota wizard (adiciona complexidade ao slice 2)
- **Se FTUE one-time:** RotPro pode pular essa tela inteiramente (defaults hardcoded)
- **Se per-session:** comportamento intermediário (uma vez por app open)

### Passos exatos

```
PRÉ-CONDIÇÃO: M54 conectado, Spoke aberta no drawer (lista de rotas).
Se Spoke não estiver aberta, dispatch: mcp__maestro__run com yaml:
  appId: com.underwood.route_optimiser
  ---
  - launchApp

PASSO 1 — Criar primeira rota teste:
  1. Tap no CTA "Criar rota" no rodapé do drawer (point: "524,2129")
  2. inspect_screen pra confirmar entrou no wizard
  3. Tap "Confirmar" (point: "540,2140") sem editar nada — usa defaults

PASSO 2 — Observar comportamento esperado:
  - SE "Detalhes da rota" abrir → FTUE no primeiro use, ou per-route, ou per-session (continuar)
  - SE direto na tela ativa de rota vazia → o flow original do drawer pula essa tela sob certas condições (interessante, mas inconclusivo — continuar)

PASSO 3 — Setar default (se Detalhes da rota apareceu):
  1. Confirmar checkbox "Salvar como padrão" está CHECKED (default)
  2. Tap CTA "Concluído" (point inferred from inspect — provavelmente próximo do bottom)
  3. inspect_screen pra confirmar entrou na tela ativa da Rota A

PASSO 4 — Voltar pro drawer e criar SEGUNDA rota:
  1. Tap hamburger menu da tela ativa (point: "80,260")
  2. Tap "Criar rota" no rodapé do drawer
  3. Tap "Confirmar" sem editar nada
  4. inspect_screen IMEDIATAMENTE após o "Confirmar"

PASSO 5 — Avaliar resultado:
  - SE Detalhes da rota PULA (vai direto pra tela ativa) → ✅ FTUE one-time confirmado (default config persistido)
  - SE Detalhes da rota ABRE de novo → per-route obrigatório (continuar PASSO 6 pra ter certeza)
  - SE comportamento ambíguo → per-session (continuar PASSO 7)

PASSO 6 — Validar per-route (se PASSO 5 inconclusivo):
  1. Repetir PASSO 4 mais 1 vez (Rota C)
  2. Se Detalhes da rota abre 3x seguidas → per-route confirmado
  3. Se abre 1x dentre 3 → comportamento irregular (provavelmente per-session)

PASSO 7 — Validar per-session (se suspeita):
  1. Force-stop a Spoke: dispatch Bash:
     adb shell am force-stop com.underwood.route_optimiser
  2. Re-launch: maestro launchApp
  3. Logar de novo se necessário (Eduardo já estava logado provavelmente persiste)
  4. Criar nova rota
  5. Se Detalhes da rota abre → per-session confirmado (resetou após kill)
  6. Se pula → FTUE one-time confirmado (persistido entre sessions)
```

### Cleanup ao fim

Apagar as rotas teste criadas (Rotas A, B, C):
- Drawer → 3-dot por rota → "Excluir rota" → confirmar
- Repetir pra cada rota teste

### Documentar resultado no inventário

Atualizar `docs/inventory/2026-05-26-spoke-vs-rotpro.md` §13.C.2 com:

```markdown
### §13.C.2 — RESOLVIDO 2026-MM-DD

**Comportamento confirmado:** [FTUE one-time | per-route | per-session]

**Evidência empírica:** [N rotas teste criadas; observação por rota]

**Decisão RotPro:**
- Se FTUE one-time → pular essa tela do slice 2 (defaults hardcoded; setting "Editar defaults" em settings)
- Se per-route → implementar tela inteira (5 sub-screens da Área 5)
- Se per-session → implementar tela mas com flag "Não mostrar nesta sessão" (defaults persistidos)
```

E atualizar `docs/08-ROADMAP-v2.md` Área 5 com a decisão.

---

## 3 — Protocolo de resolução: §13.C.3 (Instruções de acesso — 10 min)

### Hipótese atual (3 possibilidades)

Tap em "Instruções de acesso" NÃO abriu UI em 2 tentativas anteriores (durante Fase B-followup). Hipóteses:
- (a) Endereço fora do geocoder cache da Spoke (snackbar "endereço não pode ser identificado" sugere isso)
- (b) Hit area menor que assumi
- (c) Bug local v3.65.1

### Comportamento esperado (per docs oficiais Spoke)

Modal/bottom sheet com:
- TextField multiline (4-6 linhas) + label "Instruções de acesso"
- Checkbox "Salvar como padrão para este endereço" (sticky-to-address)
- CTAs Cancelar / Salvar

### Passos exatos

```
PRÉ-CONDIÇÃO: M54 conectado, Spoke aberta.

PASSO 1 — Criar rota teste com endereço CONHECIDO do geocoder Spoke:
  1. Drawer → "Criar rota" → "Confirmar" (defaults)
  2. Tap no TextField "Toque para adicionar" no bottom bar da tela ativa
  3. inputText: "Praça da Sé, São Paulo"
  4. Aguardar autocomplete results aparecerem
  5. Tap no PRIMEIRO resultado (provavelmente "Praça da Sé, Sé, São Paulo")
  6. inspect_screen pra confirmar parada adicionada com marker no mapa

PASSO 2 — Abrir Editar parada da Praça da Sé:
  1. Swipe-up no sheet pra expandir (gesture pode falhar — alternativa: tap no stop card no sheet collapsed)
  2. Tap no stop card "Praça da Sé"
  3. inspect_screen pra confirmar entrou em Editar parada

PASSO 3 — Tap em "Instruções de acesso" e observar:
  1. inspect_screen pra localizar bounds exatas do botão "Instruções de acesso"
     - Provavelmente é btn outlined-style com + icon na área ~y=600-700
  2. Tap usando bounds CENTER (não point arbitrário):
     - Exemplo: se bounds = [45,570][547,705], center = (296, 638)
  3. inspect_screen IMEDIATAMENTE após tap
  4. take_screenshot pra evidência visual

PASSO 4 — Avaliar resultado:
  - SE modal/bottom sheet abrir → ✅ UI revealed
    - Documentar componente: modal? bottom sheet? full-screen?
    - Documentar campos: TextField multi-line? checkbox? CTAs?
    - tap em "Salvar" pra ver behavior pós-save
    - Confirmar persistência: voltar pra mesma parada, ver se text persistiu
  - SE NÃO abrir → continuar PASSO 5

PASSO 5 — Hipótese (b) hit area: tentar long-press
  1. dispatch mcp__maestro__run com yaml:
     - longPressOn:
         point: "296,638"
  2. inspect_screen
  3. Se long-press abrir UI → reportar gesture necessária

PASSO 6 — Hipótese (b) selector ID: usar selector ID Maestro:
  1. inspect_screen → encontrar elemento com txt "Instruções de acesso"
  2. Capturar o ID do elemento pai clickable
  3. dispatch tapOn: { id: "<id>" }
  4. inspect_screen

PASSO 7 — Hipótese (c) bug v3.65.1:
  1. WebSearch: "Spoke Route Planner v3.65.1 'Instruções de acesso' not opening"
  2. Verificar se há versão mais recente da Spoke no Play Store
  3. Se sim, considerar atualizar ANTES de testar
  4. Se nenhum match → reportar à Spoke + documentar suspeita de bug; RotPro implementa baseado em docs oficiais (modal + multiline + checkbox + CTAs)

PASSO 8 — Se C.3 resolvido positivamente:
  - Drillar "Salvar como padrão" behavior: criar SEGUNDA parada com MESMO endereço em rota diferente
  - Verificar se "Instruções de acesso" pré-popula com texto salvo do primeiro use
  - Confirma sticky-to-address per ADR-0010
```

### Cleanup ao fim

Apagar rota teste:
- Drawer → 3-dot da rota → "Excluir rota"

### Documentar resultado no inventário

Atualizar `docs/inventory/2026-05-26-spoke-vs-rotpro.md` §13.C.3 + §11.1 com:

```markdown
### §13.C.3 — RESOLVIDO 2026-MM-DD

**UI observada:** [modal | bottom sheet | full-screen | inline]

**Estrutura:** [campos, CTAs, bounds aproximadas]

**Comportamento sticky-to-address:** [confirmado | não confirmado]

**Decisão RotPro slice 2:**
- Schema slice 3 modela `Address.accessInstructions: String?` (nullable)
- Slice 2 UI: [bottom sheet | modal | inline] com TextField multiline + checkbox "Salvar como padrão para este endereço" + CTAs
```

---

## 4 — Protocolo de resolução: §13.C.1 (Pacotes/Ordem/Tipo disabled — 30 min)

### Contexto

Em Editar parada (§10.6 + §11.5), 3 controles aparecem visualmente mas com `enabled:false`:
- **Pacotes** — stepper (- / contador / +)
- **Ordem** — segmented [Primeira | Automática✓ | Última]
- **Tipo** — segmented [Entrega✓ | Coleta]

Isso acontece tanto em rota pós-otimização quanto não-otimizada. Eduardo está no plano **Standard** (TOP TIER pago $20/mo) per pricing tiers Spoke (Free < Lite < Standard) — então NÃO é gating de plano.

### Hipóteses (4 possíveis)

- **(a)** Requer "Localizador de pacotes" preenchido primeiro
- **(b)** Requer rota com mínimo N paradas (ex: ≥3)
- **(c)** Requer pelo menos uma otimização anterior na rota
- **(d)** Bug Spoke v3.65.1

### Passos exatos

```
PRÉ-CONDIÇÃO: M54 conectado, Spoke aberta no drawer.

SETUP — Criar rota teste com 2 paradas:
  1. Drawer → "Criar rota" → "Confirmar" (defaults)
  2. Adicionar parada 1 via texto:
     - Tap TextField bottom bar
     - inputText: "Av Paulista 1000 Sao Paulo"
     - Tap primeiro resultado autocomplete
  3. Sheet auto-abre Editar parada da nova parada — tap "Concluído"
  4. Adicionar parada 2:
     - Tap TextField bottom bar
     - inputText: "Rua Augusta 500 Sao Paulo"
     - Tap primeiro resultado
  5. Tap "Concluído" no sheet de Editar parada
  6. Você deve estar na tela ativa de rota com 2 paradas, sheet collapsed

PASSO 1 — Hipótese (a): preencher "Localizador de pacotes"
  1. Swipe-up no sheet pra expandir
  2. Tap no primeiro stop card pra abrir Editar parada
  3. inspect_screen pra localizar row "Localizador de pacotes"
  4. Tap na row (bounds approx [0,996][1080,1132], center ~(540, 1064))
  5. inspect_screen pra ver UI que abre (TextField? grid de car layout?)
  6. Preencher valor qualquer ("Frente direita" por exemplo)
  7. Salvar/Concluir
  8. Voltar pra Editar parada raiz
  9. inspect_screen → verificar se Pacotes/Ordem/Tipo agora estão ENABLED

  SE ATIVARAM → ✅ hipótese (a) confirmada
    - Documentar que "Localizador de pacotes" é pré-condição
    - Pular pra PASSO 4 (validação cruzada)
  SE NÃO ATIVARAM → continuar PASSO 2

PASSO 2 — Hipótese (b): adicionar 3ª parada
  1. Tap "Concluído" pra sair da Editar parada
  2. Voltar pra tela ativa (sheet collapsed)
  3. Tap TextField bottom bar
  4. inputText: "Rua Iguape Ribeirao Preto"
  5. Tap primeiro resultado
  6. Tap "Concluído" no sheet auto-aberto
  7. Tap em qualquer stop card pra abrir Editar parada
  8. inspect_screen → verificar Pacotes/Ordem/Tipo state

  SE ATIVARAM → ✅ hipótese (b) confirmada
    - Documentar N=3 como mínimo (testar N=4, N=5 pra confirmar limite)
    - Pular pra PASSO 4
  SE NÃO ATIVARAM → continuar PASSO 3

PASSO 3 — Hipótese (c): otimizar uma vez + cancelar
  1. Tap "Concluído" da Editar parada
  2. Voltar pra tela ativa, sheet expanded com 3 paradas
  3. Tap CTA "Otimizar rota" sticky bottom
  4. Aguardar — modal FTUE "IDs ajustados" pode aparecer; tap "Entendi"
  5. Tela entra em estado pós-optimize §10.9
  6. NÃO tap "Confirmar" — tap back button do Android pra cancelar
  7. inspect_screen → verificar se voltou pra draft state
  8. Tap em stop card pra abrir Editar parada
  9. inspect_screen → verificar Pacotes/Ordem/Tipo state

  SE ATIVARAM → ✅ hipótese (c) confirmada
    - Documentar que precisa ter rodado solver ao menos 1x na rota
    - Pular pra PASSO 4
  SE NÃO ATIVARAM → hipótese (d) bug

PASSO 4 — Validação cruzada (se a/b/c confirmada):
  Pra confirmar CAUSALIDADE (não só correlação):
  - Se hipótese (a): remover "Localizador de pacotes" → verificar se controls voltam pra disabled
  - Se hipótese (b): deletar 1 parada (deixar < N) → verificar se controls voltam pra disabled
  - Se hipótese (c): não há como "des-otimizar" — assumir confirmado se controls ATIVARAM após PASSO 3
  Documentar resultado da validação cruzada.

PASSO 5 — Hipótese (d) bug:
  1. WebSearch: "Spoke Circuit Route Planner v3.65.1 'Pacotes' 'Ordem' 'Tipo' disabled bug"
  2. Procurar reports em community.spoke.com, Reddit /r/SpokeRoutePlanner
  3. Se nenhum match → reportar à Spoke + assumir bug isolado
  4. RotPro decision: implementar sempre ATIVOS (melhor UX que Spoke se bug)

PASSO 6 — Drillar comportamento ATIVADO (se hipótese a/b/c confirmada):
  Pra cada control:
  - **Pacotes stepper:**
    - Tap "+" → verificar incremento e bounds (max?)
    - Tap "-" abaixo de 1 → verifica se desabilita ou vai pra 0
  - **Ordem segmented:**
    - Tap "Primeira" → observar se afeta solver (próxima otimização coloca essa parada como #1?)
    - Tap "Última" → idem (#N?)
    - Tap "Automática" → reset
  - **Tipo segmented:**
    - Tap "Coleta" → entrar em modo delivery, verificar se botão muda pra "Coletado" (não "Entregue")
```

### Cleanup ao fim

Apagar rota teste:
- Drawer → 3-dot da rota → "Excluir rota"

### Documentar resultado no inventário

Atualizar `docs/inventory/2026-05-26-spoke-vs-rotpro.md` §13.C.1 + §11.5 com:

```markdown
### §13.C.1 — RESOLVIDO 2026-MM-DD

**Hipótese confirmada:** [a | b | c | d]

**Evidência empírica:**
- PASSO X: [observação]
- PASSO Y: [observação]
- Validação cruzada: [confirmou causalidade | só correlação]

**Pré-condição pra Pacotes/Ordem/Tipo ativarem (Spoke):**
[descrição clara]

**Decisão RotPro slice 2 Área 6:**
- [opção 1] Replicar gating idêntico ao Spoke
- [opção 2] Sempre ativar (melhor UX que Spoke; risco de divergência)

**Comportamento dos controles quando ativados (drillado em PASSO 6):**
- Pacotes stepper: [range, behavior]
- Ordem: [efeito no solver]
- Tipo Entrega vs Coleta: [efeito no modo delivery]
```

E atualizar `docs/08-ROADMAP-v2.md` Área 6 desbloqueando a tela "Editar parada".

---

## 5 — Fluxo final de commit

Após resolver os 3 bloqueios:

```
1. Working tree em chore/spoke-§13-fixes (criar branch fresh do develop)
2. git add docs/inventory/2026-05-26-spoke-vs-rotpro.md
3. git add docs/08-ROADMAP-v2.md  (se atualizou áreas 5 e 6)
4. git commit -m "docs(inventory): resolver §13.C.1/C.2/C.3 via Maestro MCP

   - §13.C.1 Pacotes/Ordem/Tipo: hipótese (X) confirmada via validação cruzada
   - §13.C.2 Detalhes da rota: [FTUE | per-route | per-session] confirmado
   - §13.C.3 Instruções de acesso: UI revealed — [modal | sheet | inline]
   - Áreas 5 e 6 do slice 2 desbloqueadas no ROADMAP-v2"
5. git push -u origin chore/spoke-§13-fixes
6. gh pr create --base develop --title "..." --body "..."
7. Esperar Eduardo revisar + mergear
```

---

## 6 — Quick reference: comandos Maestro úteis nesta sessão

```bash
# Pré-flight
MAESTRO_CLI_NO_ANALYTICS=1 maestro --version  # esperado 2.6.0+
adb devices                                    # esperado: RQCW401G33T device

# Listar device IDs
mcp__maestro__list_devices

# Inspect screen (sempre device_id="RQCW401G33T")
mcp__maestro__inspect_screen

# Take screenshot (só pra debug local; nunca commitar)
mcp__maestro__take_screenshot

# Run flow inline (preferir esta forma pra exploração)
mcp__maestro__run com:
  device_id: "RQCW401G33T"
  yaml: |
    appId: com.underwood.route_optimiser
    ---
    - tapOn:
        point: "X,Y"
    - inputText: "texto"
    - pressKey: Back
    - launchApp
```

**Sintaxe Maestro selectors aceitos:** `text`, `id`, `index`, e position matchers (`below`, `above`, `leftOf`, `rightOf`). NÃO usar `a11y` / `accessibilityText` como selector (mapear `a11y` → `text:` se precisar).

**Sintaxe `text:` é regex full-string com IGNORE_CASE.** Anchor com `.*` se quiser partial match.

---

## 7 — O que NÃO fazer nesta sessão

- ❌ Implementar código RotPro (não é o objetivo; objetivo é resolver bloqueios do inventário)
- ❌ Commitar screenshots (gitignored em `/tmp/spoke-inspection/`)
- ❌ Copiar microcopy verbatim >5 palavras da Spoke (paraphrase only)
- ❌ Decompilar APK / inspecionar recursos (só runtime UI state)
- ❌ Pushar direto pra `develop` (sempre branch + PR)
- ❌ Resolver §13.C.4/C.5 (menores; oportunisticamente quando chegar nas áreas)
- ❌ Mexer em `docs/decisions/` ou `apps/` (out of scope)

---

## 8 — Referências

- `docs/inventory/2026-05-26-spoke-vs-rotpro.md` — inventário Spoke completo (1684+ linhas; §13 é onde os bloqueios estão listados)
- `docs/08-ROADMAP-v2.md` — roadmap atual (PR #18 reescrita ainda em revisão; ler versão de develop OU do PR)
- `docs/BUSINESS-RULES.md` — modelo de monetização canônico (single paid tier R$ 25,90/30 dias)
- [ADR-0010](../decisions/0010-clone-positioning.md) — clone positioning (legal boundary)
- [ADR-0030](../decisions/0030-stripe-pix-30-day-access-pass.md) — Stripe Pix paywall
- [ADR-0035](../decisions/0035-spoke-functional-clone-prototype-creative-reference.md) — Spoke = canonical funcional
- [ADR-0036](../decisions/0036-spoke-parity-checker-functional-gate.md) — spoke-parity-checker subagent
- [ADR-0037](../decisions/0037-maestro-mcp-for-spoke-inspection.md) — Maestro MCP adoption

---

## 9 — Sucesso desta sessão = entregar:

1. `docs/inventory/2026-05-26-spoke-vs-rotpro.md` atualizado com §13.C.1/C.2/C.3 marcados como RESOLVIDO + decisão RotPro documentada
2. `docs/08-ROADMAP-v2.md` Áreas 5 e 6 desbloqueadas com nota sobre decisão tomada
3. Branch `chore/spoke-§13-fixes` + PR aberto pra Eduardo revisar
4. Cleanup: rotas teste apagadas do device

**Tempo total alvo:** ~45 min de Maestro MCP + ~15 min de documentação = ~1 hora total
