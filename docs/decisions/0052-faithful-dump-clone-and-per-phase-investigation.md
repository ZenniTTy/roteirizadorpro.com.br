# ADR-0052: Cópia fiel completa do dump + reimplementação moderna + investigação dump-first por fase + audit retroativo

- **Status:** Accepted
- **Date:** 2026-06-20
- **Deciders:** Eduardo
- **Related ADRs:** ADR-0035 (white-label: Spoke=comportamento canônico, prototipo=identidade visual, shipped product 100% identidade original) — **este ADR AFIA, não contradiz**; ADR-0045 (dump estático como baseline; dump-first → runtime-confirm); ADR-0048 (dump-first como gate signal-only; websearch/Context7 só p/ libs); ADR-0049 (D4 dump-only); ADR-0041/0042/0043/0044 (os 4 retrabalhos por baseline inferido).

## Context

Eduardo relatou (2026-06-19/20) que o projeto está **"há mais de 1 mês basicamente no mesmo lugar, fazendo retrabalho em cima de retrabalho"**. A causa não é a estratégia (clone do Spoke já é a estratégia certa desde o pivot ADR-0035), e sim o **rigor e a ordem** com que ela é executada:

1. **A barra estava em "modelar", não em "copiar".** Cada área era reimplementada por interpretação da estrutura do Spoke, deixando divergências sutis (microcopy que muda significado, gates ausentes, estados terminais não montados). O audit retroativo 2026-06-20 (`docs/audits/2026-06-20-dump-parity-retro-audit.md`, workflow `wp6fupsv5`, 20 agentes dump-only) **confirmou 13 must-fix + 12 should-fix + 11 nits** nas 6 áreas já construídas — 13 de 13 must-fix verificados adversarialmente como reais (zero falso-positivo). Os 5 temas de causa-raiz são todos do tipo "fluxo feliz implementado, fidelidade fina não conferida".

2. **A investigação do dump acontecia tarde demais.** O ADR-0045 inverteu o método (dump-first), mas na prática o dump era consultado por microsprint, pontualmente, e a inferência ainda vazava (ver memória `feedback_dump_map_per_area_before_implementing`, Eduardo 2026-06-18: "esgotar o dump da área INTEIRA antes de implementar").

3. **O dump está em outra stack.** O Spoke é Kotlin/Compose/Android; nós somos Flutter 3.44 / Dart 3.12 / Riverpod 3. "Copiar" não é copy-paste — é **reimplementar fielmente** o O QUÊ (layout, fluxo, estados, gates, strings) com as **práticas mais modernas da nossa stack**, o que exige cuidado explícito com bugs silenciosos, drift, entropia e breaking changes pós-cutoff (o implementador tem cutoff Jan-2026; Flutter 3.44 tem 3 breaking changes que ele erraria de memória).

## Decision

**1. A barra sobe de "paridade funcional" para CÓPIA FIEL COMPLETA.** Todo front (layout/estrutura/hierarquia de telas) e toda funcionalidade (fluxos, estados, gates, fallbacks, máquinas de estado) são copiados **completamente e identicamente** ao Spoke, conforme o dump. **Zero divergência deferida** — uma divergência encontrada é corrigida no mesmo trabalho ou escalada como BLOCKED, nunca adiada com `// TODO`.

**2. A identidade visual continua ORIGINAL e é a ÚLTIMA camada (ADR-0035 intacto).** Cores, tipografia, ícones (Lucide) e o **wording** da microcopy PT-BR permanecem originais e entram no polish visual final. **Reconciliação da microcopy (a tensão real):** até o polish, cada string deve ser **fiel em SIGNIFICADO/função** ao dump (`values-pt-rBR` é a referência semântica) — proibido inventar capacidade que o app não tem (ex.: "Avaliando o trânsito" quando o solver on-device não lê trânsito). O *wording* é original; o *significado* é cópia fiel. O dump é a referência semântica, não a fonte literal de texto.

**3. Investigação dump-first por FASE/ÁREA é gate obrigatório ANTES de implementar.** Para cada Área futura (Á8+) e para cada bloco de remediação, o primeiro passo é **esgotar o dump da área inteira** num doc de design (fluxos + estados + gates + fallbacks + strings verbatim + pacote de código), DEPOIS implementar. Não é "consultar o dump quando travar" — é mapear a área toda primeiro. Fonte: MASTER-TABLE + `~/spoke-dump/jadx-out` deep-grep; runtime só onde `Precisa-runtime` indicar (D4 dump-only por ADR-0049). É o ADR-0045 aplicado **por área, não por microsprint**.

**4. Reimplementação com as práticas mais modernas da nossa stack, validadas.** Como o dump é Android e nós somos Flutter, a tradução usa o idiom moderno (Riverpod 3 `@riverpod` codegen / `AsyncNotifier` / `AsyncValue.guard`; GoRouter; Material 3; `RadioGroup<T>`, `ReorderableListView.onReorderItem`, `AsyncValue` selada do Flutter 3.44). **Validação obrigatória via Dart MCP (símbolos instalados) → Context7/WebSearch (libs/APIs pós-cutoff)** — NUNCA websearch para comportamento Spoke (isso é o dump, ADR-0048). Cuidado explícito e nomeado com **bugs silenciosos, drift, entropia e breaking changes** em cada tradução.

**5. Audit retroativo de tudo já feito, remediado a 100% antes de qualquer área nova (Fase R).** O audit 2026-06-20 é o baseline. Sua remediação (P0 destrava Á7 PR-C → P1 gates/fluxos → P2 sweep de microcopy semântica → P3 nits) é executada **integralmente antes da Área 8** (decisão de Eduardo 2026-06-20: "100% agora"). Validação de paridade (`spoke-parity-checker` D4 dump-only) fecha cada bloco.

**6. Validação antes de finalizar CADA implementação.** Nenhuma implementação é considerada "done" sem a conferência dump-first de fechamento (re-grep do dump pelos enums/strings/gates da área + `spoke-parity-checker` D4). É o passo que faltava e deixou os 13 must-fix passarem.

**7. LGPD desprioriza para o fim.** Slice 6 (LGPD) é uma das últimas entregas — depois das telas core, backend, paywall e sentido-casa. Não bloqueia nada do clone funcional.

## Consequences

- **Positive (mata o failure mode na raiz):** a fidelidade vira fato verificado, não interpretação. O audit retroativo + Fase R zeram a dívida acumulada antes de empilhar área nova sobre base divergente. A investigação por área antes de codar elimina o ciclo "implementa por inferência → susto no smoke → refaz".
- **Positive (tradução moderna explícita):** os 3 breaking changes do 3.44 (+ os patterns Riverpod 3) viram checklist consciente, não armadilha de memória.
- **Positive (legal inalterado):** copiar estrutura/comportamento + significado de microcopy ≠ copiar identidade visual. Cores/ícones/tipografia/wording permanecem originais (ADR-0035). O dump é artefato de engenharia interno; o shipped product mantém identidade 100% original.
- **Negative (Fase R adia a Área 8):** remediar 12 must-fix acionáveis + 12 should-fix + 11 nits antes da Á8 custa tempo de relógio. Aceito explicitamente por Eduardo em troca de zero dívida acumulada — alinhado a "não fazer retrabalho em cima de retrabalho".
- **Negative (custo da investigação por área):** o doc de design dump-first por área é trabalho upfront. Mitigação: é mais barato que o retrabalho que ele previne (o audit provou o custo do atalho).
- **Neutro (microcopy):** mantém o wording original; só garante que o significado não mente. Se Eduardo decidir depois ir verbatim no PT-BR, é mudança de ADR-0035, registrada à parte.

## Alternatives considered

1. **Manter "paridade funcional" (status quo ADR-0035 puro).** Rejeitado — o audit provou que "funcional" sem rigor de cópia fiel deixa 13 must-fix passarem por área. A barra precisa subir.
2. **Remediar só o que destrava (P0) e seguir pra Á8, resto vira backlog.** Rejeitado por Eduardo (escolheu "100% agora") — adiaria gates funcionais e reintroduziria o "deferir divergência" que é o anti-pattern.
3. **Copiar microcopy verbatim do `values-pt-rBR`.** Rejeitado (por ora) — conflita com a identidade original do ADR-0035. A reconciliação (significado fiel, wording original) preserva ambos. Reaberto só por decisão explícita de Eduardo.
4. **Investigar o dump por microsprint (ADR-0045 como estava).** Insuficiente — a inferência vazava entre microsprints. Elevado a investigação por área inteira antes de implementar.

## References

- Audit retroativo: `docs/audits/2026-06-20-dump-parity-retro-audit.md` (workflow `wp6fupsv5`, 20 agentes, dump-only, 13/13 must-fix verificados).
- Baseline de fato: `docs/inventory/spoke-dump-v3.65.1/MASTER-TABLE.md` + `~/spoke-dump/jadx-out` (ADR-0045).
- Roadmap operacional: `docs/08-ROADMAP-v2.md` §"Fase R" + §"Método de cópia fiel (dump-first por fase)".
- Memórias relacionadas: `feedback_dump_map_per_area_before_implementing`, `lesson_spec_does_not_replace_reverifying_dump`, `feedback_spoke_parity_zero_debt_per_ms`.
