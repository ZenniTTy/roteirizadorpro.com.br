# M2 Slice Execution Checklist (reset 2026-05-26)

Per [ADR-0035](./decisions/0035-spoke-functional-clone-prototype-creative-reference.md) (Spoke white-label) + Diretiva #13 do `docs/inventory/2026-05-26-spoke-vs-rotpro.md` §7.1: **replicar Spoke 1:1 funcionalmente, ajustar visual no final**. Sem microsprint formal. Sem ADR por tela. Sem session log por commit.

## Antes de qualquer trabalho num slice

- [ ] Ler `CLAUDE.md`, `docs/08-ROADMAP-v2.md` (a seção do slice), `docs/inventory/2026-05-26-spoke-vs-rotpro.md` (as seções funcionalmente relevantes).
- [ ] M54 conectado (`adb devices` mostra `RQCW401G33T`). Spoke logado pra inspeção.
- [ ] `git status` em develop está limpo. Branch nova `feat/m2-slice-N-<topic>`.

## Implementação

- [ ] **Tela por tela.** Cada tela do Spoke vira um ciclo curto: olha como Spoke faz → implementa com nossa stack → testa no M54 → commit. Sem subdividir em microsprints A/B.
- [ ] **Inventário descreve, Spoke decide.** Antes de escrever spec de QUALQUER tela Spoke-aligned, dump live obrigatório do Spoke no estado-alvo (collapsed/expanded/empty/populated). Comando padrão:
  ```bash
  adb -s RQCW401G33T shell uiautomator dump /sdcard/spoke-<state>.xml
  adb -s RQCW401G33T pull /sdcard/spoke-<state>.xml /tmp/
  adb -s RQCW401G33T exec-out screencap -p > /tmp/spoke-<state>.png
  ```
  Extrair tabela `bounds | content-desc/text | padrão visual | widget Flutter`. Quotes verbatim dos bounds — não paraphraseia. Coluna do widget Flutter precisa nomear widget específico (`Positioned(top: X, left: Y) FloatingActionButton.small`, `DraggableScrollableSheet`, `showModalBottomSheet(isScrollControlled: true)`), não família genérica ("um drawer", "um sheet"). Se inventário e dump conflitarem, dump ganha; inventário é amendado no mesmo commit do spec.
- [ ] **Em qualquer dúvida estrutural** → dispatch [`spoke-parity-checker`](../.claude/agents/spoke-parity-checker.md) subagent ([ADR-0036](./decisions/0036-spoke-parity-checker-functional-gate.md)) upfront. É a fonte de verdade pra "como Spoke faz isso". **Dispatch description deve pedir explicitamente a tabela `bounds | desc | padrão | widget`** — não só "edge cases". Edge cases vêm depois da baseline estrutural.
- [ ] **Em qualquer dúvida visual** → consultar `prototipo/tokens.js` + `prototipo/ui.jsx` (cores, ícones Lucide, tipografia). Sem dispatch de `prototype-fidelity-checker` durante implementação — só no polish final (ver §"Polish visual" abaixo).
- [ ] **TDD opcional.** Use [`flutter-test-author`](../.claude/agents/flutter-test-author.md) ([ADR-0025](./decisions/0025-flutter-test-author-subagent.md)) pra lógica complexa; widget tests opcionais. Não bloqueante — não atrasar entrega por test.
- [ ] **DTO mirror obrigatório** ([ADR-0013](./decisions/0013-api-contract-source-of-truth.md)): qualquer edit em `apps/backend/src/<feature>/schemas.ts` requer mirror Dart em `apps/mobile/lib/features/<feature>/data/dto/` no mesmo commit.

## Regras gerais de qualidade (estabelecidas 2026-05-27 pós-auditoria do drawer)

- **Sem `onTap: () {}` silenciosos.** Affordance visível precisa de callback que dispara algo observável — mesmo que seja só `SnackBar` "em breve" stub. Botão "vazio" parece app quebrado.
- **`AsyncValue` sempre branch 3 estados.** Provider que deriva de `AsyncValue<T>` NÃO usa `.value` direto (colapsa loading/error/null). Use `if (asyncVal.hasError) ... if (asyncVal.isLoading) ... final v = asyncVal.value; if (v == null) ...`. ViewModels com sentinelas distintas: `empty()` vs `unavailable()`. UI renderiza visualmente distinto.
- **`ListView` em UI com lista de dados → sempre `ListView.builder`.** Para listas que vêm de provider. Achata pra `List<_Row>` (sealed class) com headers + tiles como linhas únicas. Sem nested `ListView`, sem `shrinkWrap`.
- **Sem fluxo morto.** Toda feature em que o usuário pode "entrar" precisa de caminho de "saída" — mesmo que temporário/debug. Ex: enquanto Settings real (Área 10) não chega, logout fica num PopupMenu temporário.

## Antes de PR

- [ ] `cd apps/mobile && flutter analyze` clean.
- [ ] `cd apps/mobile && flutter test` passa.
- [ ] `cd apps/backend && bun run typecheck` clean (se mexeu backend).
- [ ] `spoke-parity-checker` D4 dispatch — punch list resolvida. Must-fix bloqueia merge; should-fix vira tech debt explícita no TODO; nit ignora.
- [ ] **Smoke E2E no Samsung M54** — golden path do slice funciona com APK release contra prod API:
  ```bash
  flutter run -d RQCW401G33T --release \
    --dart-define=API_BASE_URL=https://api.roteirizadorpro.com.br \
    --dart-define=APP_ENV=production
  ```
- [ ] `aapt2 dump permissions <built APK>` se mudou permissões Android.
- [ ] `apksigner verify` se publicou APK novo.

## Polish visual (último slice antes do tag final)

- [ ] `prototype-fidelity-checker` sweep — cores, spacing, ícones Lucide, tipografia
- [ ] Eduardo + designer revisam telas finais
- [ ] Sweep de microcopy PT-BR original (sem cópia verbatim de Spoke per [ADR-0010](./decisions/0010-clone-positioning.md))
- [ ] Tag `vX.Y.0`

## Sem mais

- Sem microsprints pré-decompostos
- Sem ADR por tela (só ADR pra mudança de stack)
- Sem session log por commit (commit message conta a história)
- Sem `prototype-fidelity-checker` durante implementação (paridade Spoke prioriza)
- Sem brainstorm pra cada decisão (Spoke decide; só perguntar quando Spoke não cobre)

## Glossário rápido

- **Spoke** — `com.underwood.route_optimiser` v3.65.1 (Brazilian rebrand do Circuit Route Planner). Instalado no M54 de Eduardo. Fonte canônica de comportamento/UX.
- **prototipo/** — Claude Design output, client-approved 2026-05-07. Fonte de tokens visuais (cores, spacing, ícones Lucide, tipografia). NÃO é fonte de estrutura/flow (essa é Spoke per [ADR-0035](./decisions/0035-spoke-functional-clone-prototype-creative-reference.md)).
- **Cliente Ueslei** — desempate final em qualquer conflito.
- **Inventory** — `docs/inventory/2026-05-26-spoke-vs-rotpro.md` é o catálogo lado-a-lado autoritativo de paridade Spoke↔RotPro.
