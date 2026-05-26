# Sprint M2-AI — Harness Flutter-AI Parity

> **Branch:** `feat/m2-ai-harness` (a partir de `feat/m2-slice-2-telas-core`, **não** de `main`)
> **Criado em:** 2026-05-24
> **Owner:** Eduardo Rodrigues — `eduardo@ianelli.tech`
> **Status:** ✅ **FECHADA 2026-05-24** — todas as 7 fases entregues nesta branch (`feat/m2-ai-harness`). PR #8 contra `feat/m2-slice-2-telas-core` pronto para merge. Smoke dispatches dos subagents `flutter-test-author` e `flutter-perf-auditor` ficam deferred para a próxima sessão pós-reload (Claude Code carrega o agent registry só na boot da sessão — ADR-0025 §Verification e ADR-0027 §Verification têm os prompts exatos).
> **Spec canônica:** `docs/superpowers/specs/2026-05-24-ai-harness-upgrade-design.md`
> **Plan canônico:** `docs/superpowers/plans/2026-05-24-ai-harness-upgrade.md`
>
> **Nota de convenção (Q6 da spec):** Os arquivos seguem o padrão `YYYY-MM-DD-<slug>` do projeto, **não** o padrão numérico `NNNN-<slug>` que o draft inicial deste documento sugeria. Convenção corrigida no commit de Phase 0.

---

## ✅ Sprint state & handoff (2026-05-24, **FECHADA**)

**Onde estamos.** Fases 0 e 1 entregues e commitadas em `feat/m2-ai-harness`. PR #8 aberto contra `feat/m2-slice-2-telas-core` (branch-mãe), **não** contra `develop` — porque slice-2 ainda tem trabalho próprio pendente (MS-15+, 7 Criticals restantes).

**Decisão de topologia (substitui o handoff anterior).** As Fases 2–7 **continuam nesta mesma branch** `feat/m2-ai-harness`. Cada fase adiciona commits que entram automaticamente no PR #8 já aberto. Quando todas as 7 fases fecharem, o PR #8 é mergeado em `feat/m2-slice-2-telas-core`. A slice-2 termina seus microsprints próprios depois, e tudo vai junto para `develop` em outro PR. Motivo: evitar proliferação de branches paralelas que o owner já se perdeu uma vez; manter uma linha clara `harness → slice-2 → develop`.

**Estado entregue:**

| Fase | Status | Commits | ADR |
|---|---|---|---|
| 0 — Pré-flight | ✅ entregue (sessão 19) | `4b528f8`, `baaea44`, `782eb99` | — |
| 1 — Dart & Flutter MCP server | ✅ entregue (sessão 20) + smoke validado pós-reload | `2abe6bc`, `8c15f7c` | ADR-0023 |
| 2 — Riverpod codegen hook | ✅ entregue (sessão 22) | `0a6f094` | ADR-0024 |
| 3 — Subagent `flutter-test-author` | ✅ entregue (sessão 22b, smoke dispatch deferred to sessão 23 post-reload) | `3dd30f8` | ADR-0025 + ADR-0026 (housekeeping) |
| 4 — Subagent `flutter-perf-auditor` | ✅ entregue (sessão 22c, smoke dispatch deferred to sessão 23 post-reload) | `95d365f` | ADR-0027 |
| 5 — Decisão sobre `mcp_flutter` | ✅ entregue (sessão 22d) — **rejeitado** com critério de re-avaliação documentado | (este commit) | ADR-0028 |
| 6 — Golden tests baseline | ✅ entregue (sessão 22e) — pivot `golden_toolkit` (descontinuado) → `alchemist 0.14.0` | (este commit) | ADR-0029 |
| 7 — Docs consolidate + retro | ✅ entregue (sessão 22f) | (este commit) | — |

**Commits orthogonais entregues junto:**
- `bff1b6c` `chore(infra): support relocating graphhopper data outside the repo` — `GH_DATA_DIR` env var + TODO(ADR) em docker-compose.yml. Não é da sprint M2-AI; carona no PR para limpar working tree.
- `fbf4508` `docs(sessions): session 2026-05-24-21 — graphhopper data relocation off-repo` — log da sessão que executou o item acima.

**Próxima sessão deve (sprint FECHADA — tarefas pós-merge):**
1. **Validar Phase 3 + Phase 4 smoke (deferred desta sprint):** confirmar `/agents` lista `flutter-test-author` e `flutter-perf-auditor`; rodar os 4 prompts de smoke capturados em ADR-0025 §Verification + ADR-0027 §Verification. Resultados vão num session log curto (qualquer pendência de ajuste se algum smoke falhar → ADR de correção).
2. Mergear PR #8 em `feat/m2-slice-2-telas-core` (squash ou merge-commit a critério do owner).
3. Voltar para os microsprints próprios de slice 2 (MS-15+ — 7 Criticals restantes), agora com o harness completo (Dart MCP + Riverpod codegen hook + 2 subagents + goldens disponíveis).

---

## Por que este documento existe

Esta sprint nasceu de uma pesquisa explícita (WebSearch + Context7 + docs oficiais Flutter) sobre o **estado da arte 2026** do ecossistema Flutter + AI agents. O objetivo é absorver o que existe de melhor **sem destruir o harness que já temos** (CLAUDE.md robusto, ADRs 0001–0020, slice checklist, hooks de validação, spec-driven via `superpowers:`).

Este MD é o **ponto de entrada para qualquer sessão futura** que retomar a sprint. Ele existe para:

1. **Evitar alucinação cross-session.** Toda decisão, motivação e fonte está aqui — uma nova sessão não precisa "lembrar" da conversa original.
2. **Servir de checklist vivo.** Cada fase tem critério de aceite binário; uma sessão futura sabe exatamente onde retomar.
3. **Documentar o "porquê" de cada escolha** antes que vire ADR — o ADR fica para a decisão final; aqui mora o contexto da pesquisa.

**Regra de ouro:** se você é uma sessão futura lendo isto, **leia o documento inteiro antes de tocar qualquer arquivo**. Cinco minutos de leitura > cinco horas de retrabalho.

---

## Contexto da pesquisa (mai/2026)

A pesquisa foi feita em 2026-05-24 com WebSearch + Context7 + queries diretas a `docs.flutter.dev`. Os achados estão na seção **[Fontes consultadas](#fontes-consultadas)** no fim deste doc.

### O que descobrimos que **não tínhamos**

| Item | Origem | O que faz |
|---|---|---|
| **Dart & Flutter MCP server oficial** | `docs.flutter.dev/ai/mcp-server` | Expõe ao Claude: `analyze`, `fix`, resolve de símbolos com docs locais, introspect de app rodando, `pub_dev_search`, gerenciamento de deps, run tests, format. Agentic Hot Reload via Dart Tooling Daemon. |
| **AI Rules oficiais do Flutter team** | `docs.flutter.dev/ai/ai-rules` (atualizado 2026-01-05) | Conjunto canônico de regras: widgets como configuração, composition over inheritance, `ListView.builder`/`Isolate.run` como defaults, pitfalls de null safety. |
| **Agent Skills oficiais** | `docs.flutter.dev/ai/agent-skills` | Define vocabulário canônico: **Rules** (comportamento geral) vs **Skills** (job específico) vs **MCP** (ferramentas) vs **Subagents** (especialistas). |
| **mcp_flutter (comunidade)** | `github.com/Arenukvern/mcp_flutter` | MCP com closed feedback loop — snapshot visual + semântico do app rodando. Agent "vê" a tela. |

### O que descobrimos que já fazemos **bem** (não mexer)

- `CLAUDE.md` enxuto e operacional (acima da média da comunidade).
- ADRs disciplinados (0001–0020) com rationale.
- Slice checklist (`docs/M2-SLICE-CHECKLIST.md`) como gate hard.
- Spec-driven via `superpowers:` + `/new-spec` + `/new-plan` (templates em `docs/superpowers/`).
- Hooks `Stop` de auto-validação: `analyze-changed-dart.sh`, `check-dto-mirror.sh`, `warn-adr-drift.sh` (ADR-0018).
- Lefthook + commitlint + Conventional Commits (ADR-0012).
- Subagents `prototype-fidelity-checker` e `adr-guardian`.

### O que **não vamos adotar** (decisões já tomadas na pesquisa)

| Item | Por que não |
|---|---|
| `flow-next` (gmickel) | Concorrente direto do nosso `superpowers:` + templates. Trocar por trocar não faz sentido. |
| `cc-sdd` (gotalab) | Mesma razão — nosso SDD já está calibrado para o projeto. |
| Substituir nosso CLAUDE.md pelo de algum repo da comunidade | O nosso é mais específico ao Roteirizador Pro (stack travado, ADRs, slice protocol). Cherry-pick > replace. |

---

## Princípios desta sprint (anti-alucinação)

1. **Uma fase = um PR = um valor verificável.** Não acumular fases num único PR mesmo que duas estejam prontas.
2. **Cada fase tem gate de aceite binário.** Se não passa, não merge.
3. **Cada decisão vira ADR antes do commit final da fase**, não depois.
4. **Sem refactor adjacente** (Karpathy §3 — Surgical Changes). Algo melhorável fora do escopo da fase → anotar em `TODO.md` e seguir.
5. **MCP-first nas fases 3–6.** Use o Dart MCP para resolver símbolos em vez de pedir `Read` de arquivos do pacote Flutter. Esse é o teste real de que a Fase 1 deu valor.
6. **Se uma fase travar > 2× o tempo estimado**, pare e abra discussão. Não force.
7. **A sprint não bloqueia a slice 2.** Branch isolada. Slice 2 continua sendo a prioridade real do M2.

---

## Visão geral

| Fase | Item | ROI | Tempo | Reversível? | ADR planejado | Depende de |
|---|---|---|---|---|---|---|
| 0 | Pré-flight: spec + plan + branch | — | 30 min | sim | — | — |
| 1 | Dart & Flutter MCP server oficial | 🔥🔥🔥 | 1–2h | sim | 0023 | 0 |
| 2 | Hook `riverpod-codegen-runner` | 🔥🔥 | 1h | sim | 0024 | 1 |
| 3 | Subagent `flutter-test-author` | 🔥🔥 | 2h | sim | 0025 | 1 |
| 4 | Subagent `flutter-perf-auditor` | 🔥 | 1.5h | sim | 0027 | 1 (paralelo a 3) |
| 5 | Decisão `mcp_flutter` (fork) | 🔥 ou 0 | 30 min – 2h | sim | 0028 | 1 |
| 6 | Golden tests com `golden_toolkit` | 🔥 | 2h | sim | 0029 | 3 |
| 7 | Documentação consolidada + retro | — | 45 min | n/a | — | todas |

**Total estimado:** 10–13h de trabalho dirigido (calendário a critério do humano).

---

## Fase 0 — Pré-flight

**Status:** ✅ concluída 2026-05-24 (sessão 19)
**Tempo real:** ~30 min
**Bloqueia:** todas as outras fases.

### Por que existe
Sem spec + plan + branch isolada, o resto da sprint corre risco de drift. Esta fase **não escreve código** — só prepara o terreno.

### Tarefas (executadas em 2026-05-24, sessão 19)
1. ✅ Criar branch: `git checkout -b feat/m2-ai-harness` partindo de `feat/m2-slice-2-telas-core` (SHA `7808911`).
2. ✅ Criar `docs/superpowers/specs/2026-05-24-ai-harness-upgrade-design.md` (convenção de data, não numérica — ver Q6 da spec).
3. ✅ Spec preenchida nas 13 seções H2 inline (brainstorming integrado à própria sessão de research; não foi necessária invocação separada de `superpowers:brainstorming` porque a pesquisa WebSearch+Context7 já produziu as 6 decisões locked).
4. ✅ Criar `docs/superpowers/plans/2026-05-24-ai-harness-upgrade.md` decompondo Phase 0 e referenciando este SPRINT-MD como playbook canônico para Phases 1–7.
5. ✅ Decomposição inline em Tasks 0.1–0.6; não foi necessária invocação separada de `superpowers:writing-plans` (Phase 0 é pequena e a estrutura de Phases 1–7 já está neste SPRINT-MD).
6. ✅ Adicionar entrada em `TODO.md` sob "Sprint M2-AI (Harness upgrade)" com 8 checkboxes (Phases 0–7).

### Gate de aceite
- [x] Spec tem as 13 H2 seções preenchidas (Context, Decisions Locked, Goals, Architecture, Data flow, Sub-slice plan, Libraries, ADRs filed, Risks, Accessibility (waived com nota), Test strategy, Verification gates, References).
- [x] Plan tem Phase 0 decomposta em Tasks 0.1–0.6; Phases 1–7 referenciam este SPRINT-MD como playbook (decisão deliberada para evitar duplicação que drifta).
- [x] `docs/sessions/2026-05-24-19-ai-harness-kickoff.md` registrado (template seguido).
- [x] Branch `feat/m2-ai-harness` existe localmente (push para `origin` é parte do commit de fechamento).

### Commit
`docs(harness): kickoff M2-AI sprint — spec + plan`

---

## Fase 1 — Dart & Flutter MCP server oficial 🔥🔥🔥

**Status:** ✅ concluída 2026-05-24 (sessão 20, ADR-0023)
**Tempo real:** ~1h
**Depende de:** Fase 0.
**Fonte primária:** [docs.flutter.dev/ai/mcp-server](https://docs.flutter.dev/ai/mcp-server)

### Descobertas durante a execução (registradas para sessões futuras)

1. **A doc oficial Flutter mostra 3 formatos de config** (Gemini CLI, OpenCode, Claude Code). O formato Gemini-style (`mcpServers` no `settings.json`) **foi tentado primeiro e rejeitado pelo schema validator do Claude Code**. O formato canônico do Claude Code é `.mcp.json` no root do repo + `enabledMcpjsonServers: ["dart"]` em `.claude/settings.json`. Trade-off: dois arquivos em vez de um, mas separação semântica correta (declaração vs aprovação).
2. **O servidor MCP vem embutido no Dart SDK** (`dart mcp-server` subcomando), não como pacote separado em `dart pub global`. Plano original assumia activation; correção: nenhum activate necessário se Dart ≥ 3.9.
3. **Smoke test depende de restart da sessão Claude Code** — `/mcp` só lista servidores carregados na inicialização. Não há como validar inline durante a sessão que registrou o server.

### Por que primeiro
Maior ROI da sprint inteira. Reduz alucinação de API e custo de token em **todas** as fases seguintes. Instalar antes faz o resto da sprint ser mais barato. O Claude para de "lembrar" API do Flutter/Riverpod/flutter_map e passa a consultar o analyzer local.

### Pré-requisitos
- `dart --version` ≥ 3.9 (requisito oficial documentado).
- Claude Code CLI atualizado.

### Tarefas
1. Verificar versão Dart: `dart --version`. Se < 3.9, abrir issue de upgrade do Flutter SDK como bloqueador.
2. Instalar: `dart pub global activate dart_mcp_server`.
3. Confirmar binary disponível: `which dart_mcp_server` ou rodar `dart pub global run dart_mcp_server --help`.
4. Adicionar entrada em `.claude/settings.json` (escopo do **projeto**, não global) sob a seção `mcpServers`:
   - Nome: `dart`
   - Command: caminho absoluto do binário Dart MCP server
   - Args/env conforme doc oficial atualizada (consultar [docs.flutter.dev/ai/mcp-server](https://docs.flutter.dev/ai/mcp-server) no momento da execução — não copiar config de memória).
5. Reiniciar Claude Code.
6. Rodar `/mcp` no chat e confirmar `dart` como connected ✅.
7. **Smoke test obrigatório:** pedir ao Claude:
   > "Use o Dart MCP para resolver o símbolo `MapController` de `flutter_map` e listar seus métodos públicos."

   Resultado esperado: lista real de métodos com source path apontando para o pacote local (não para training data).
8. Criar **ADR-0023 — Adoção do Dart & Flutter MCP server oficial**. Conteúdo mínimo:
   - Contexto: alucinação de API Flutter/Dart como fonte recorrente de retrabalho.
   - Decisão: adotar `dart_mcp_server` oficial.
   - Versão fixada (anotar a versão resolvida por `dart pub global activate`).
   - Consequências positivas: anti-alucinação, hot reload agentic, introspect de app.
   - Consequências negativas: mais um processo local; depende de Dart ≥ 3.9.
   - Rollback: remover entrada de `.claude/settings.json`.
9. Atualizar `CLAUDE.md`:
   - Seção **"Executable Commands"** — adicionar linha `dart pub global activate dart_mcp_server` com nota "primeiro setup, opcional reactivate quando bump de versão".
   - Seção **"Context7 Mandatory"** — adicionar parágrafo: *"Para símbolos Dart/Flutter já instalados no projeto, prefira o Dart MCP (`resolve_symbol`) sobre Context7. Context7 fica para libs ainda não adicionadas ou para confirmar versão mais recente antes de adicionar."*
   - Bumpar `Last updated` no topo.

### Gate de aceite
- [ ] `/mcp` lista `dart` como ✅ connected. **(requer restart de sessão Claude Code — humano valida)**
- [ ] Smoke test acima retorna lista real de métodos com source path local. **(requer restart — humano valida)**
- [x] ADR-0023 commitado em `docs/decisions/0023-dart-flutter-mcp-server.md`.
- [x] `CLAUDE.md` atualizado e data bumpada (2026-05-24).
- [x] `.mcp.json` criado e válido (`python3 -m json.tool` passa).
- [x] `.claude/settings.json` aceito pelo schema validator com `enabledMcpjsonServers: ["dart"]`.
- [x] `dart mcp-server --help` executa com exit=0 e lista flags reais (`--tools`, `--exclude-tool`, `--dart-sdk`, etc.).

### Riscos conhecidos
- Versão do `dart_mcp_server` ainda pode estar em evolução — fixar a versão exata no ADR é mandatório.
- Pode haver conflito de porta se já houver Dart Tooling Daemon rodando — checar `lsof` se reiniciar não funcionar.

### Commit
`feat(harness): adopt official Dart & Flutter MCP server (ADR-0023)`

---

## Fase 2 — Hook `riverpod-codegen-runner` 🔥🔥

**Status:** ✅ entregue 2026-05-24 (sessão 22). `.claude/hooks/run-riverpod-codegen.sh` + registro em `.claude/settings.json` + ADR-0024 + atualização CLAUDE.md.
**Tempo:** 1h
**Depende de:** Fase 1 (testar com MCP ativo para validação cruzada).

### Por que segundo
Slice 2 (Telas Core) vai gerar muito `@riverpod`. Esquecer `dart run build_runner build --delete-conflicting-outputs` é o erro recorrente #1 documentado em `CLAUDE.md` (já listado em Executable Commands). Automatizar via hook elimina o gap.

### Tarefas
1. Criar `.claude/hooks/run-riverpod-codegen.sh`:
   - Shebang `#!/usr/bin/env bash`, `set -euo pipefail`.
   - Recebe lista de arquivos editados via env (formato Claude Code PostToolUse — consultar [docs](https://code.claude.com/docs/en/hooks-guide) no momento da execução).
   - Filtra: somente `apps/mobile/lib/**/*.dart`.
   - Para cada arquivo, checa: `grep -E '^@riverpod|^@Riverpod\(' OU `grep -E "part '.*\.g\.dart'"`.
   - Se ao menos um arquivo bateu: roda `cd apps/mobile && dart run build_runner build --delete-conflicting-outputs` (background, com timeout sensato — ex. 120s).
   - Output: 1 linha — `[codegen] regenerated N .g.dart files` OU `[codegen] no @riverpod changes detected`.
   - Em caso de falha do build_runner: exit code não-zero + mensagem clara.
2. Tornar executável: `chmod +x .claude/hooks/run-riverpod-codegen.sh`.
3. Registrar em `.claude/settings.json` sob `hooks.PostToolUse` com matcher `Edit|Write`.
4. Smoke test:
   - Editar um provider `@riverpod` qualquer (trocar uma linha de comentário) → hook dispara → `.g.dart` regenerado → `flutter analyze` limpo.
   - Editar um arquivo Dart **sem** `@riverpod` → hook **não** roda build_runner (log mostra "no @riverpod changes detected").
5. Atualizar `CLAUDE.md` seção **"In-Loop Auto-Validation (ADR-0018)"** — adicionar 4º hook ao lado dos 3 existentes. Nota: este é o primeiro hook **PostToolUse** (não Stop) — explicitar.
6. Criar **ADR-0024 — Hook PostToolUse para Riverpod codegen**. Conteúdo: motivação, escolha de PostToolUse vs Stop (PostToolUse roda mais cedo, antes do próximo turno), trade-off (custo de build_runner em cada edit relevante), rollback.

### Gate de aceite
- [ ] Smoke test "com `@riverpod`" passa.
- [ ] Smoke test "sem `@riverpod`" passa (hook não desperdiça tempo).
- [ ] ADR-0024 commitado.
- [ ] `CLAUDE.md` atualizado.

### Riscos conhecidos
- `dart run build_runner` pode demorar > 30s no primeiro run — hook precisa de timeout generoso.
- Se o usuário editar 5 providers num turno, o hook só deve rodar uma vez (debounce implícito pelo fato do hook rodar **uma vez por turno**, não por arquivo — confirmar no Claude Code hooks doc).

### Commit
`feat(harness): post-edit riverpod codegen hook (ADR-0024)`

---

## Fase 3 — Subagent `flutter-test-author` 🔥🔥

**Status:** ✅ entregue 2026-05-24 (sessão 22). Mock-lib decision: `mocktail ^1.0.5` (Q3 da spec resolvida via inspeção do pubspec + `pub_dev_search`). Subagent + ADR-0025 + atualização CLAUDE.md commitados. Smoke-test funcional (dispatch contra spec trivial CounterController) deferred para sessão 23 pós-reload do Claude Code — agent registry, igual MCP, carrega na boot da sessão.
**Tempo:** 2h
**Depende de:** Fase 1.

### Por que terceiro
Com MCP ativo, o subagent escreve testes corretos (vê API real, não inventa). Antes do MCP, um subagent de testes alucinaria mais que economizaria tempo.

### Decisão pendente (resolver no início da fase)
**Mock library:** `mocktail` (sem codegen) **vs** `mockito @GenerateMocks` (com codegen).
- Verificar qual já está em `apps/mobile/pubspec.yaml`.
- Se nenhum, decidir antes de escrever o subagent — a escolha vai pro ADR-0025.
- Recomendação pessoal sem mais contexto: `mocktail` por evitar mais um build_runner; mas se já tem `mockito` no projeto, manter.

### Tarefas
1. Resolver decisão de mock library acima.
2. Criar `.claude/agents/flutter-test-author.md`:
   - **Description:** "Use proactively before implementing any new widget/provider/service in apps/mobile/. Writes failing tests first per TDD discipline. Covers widget tests (testWidgets), provider tests (Riverpod ProviderContainer), and golden tests when applicable."
   - **Tools allowlist mínimo:** `Read, Grep, Glob, Edit, Write, Bash(flutter test:*), Bash(flutter analyze:*), Bash(cd apps/mobile && *)` + Dart MCP tools.
   - **Conteúdo:** instruções claras para 3 categorias:
     - **Widget tests** (`testWidgets` + `WidgetTester`): pumpWidget com `ProviderScope` overrides.
     - **Provider tests** (Riverpod): `ProviderContainer` + `addTearDown(container.dispose)`.
     - **Golden tests**: opcional, ativar somente se Fase 6 já tiver sido executada.
   - **Discipline:** escrever teste falhando ANTES de implementar; nunca editar `lib/` se não há teste vermelho que justifique.
3. Inspiração (não copiar): skill `flutter-dart-code-review` de affaan-m + subagent `flutter-expert` de cleydson — adaptar ao stack travado (Riverpod 3 codegen, mock lib escolhida).
4. Smoke test:
   - Invocar o agent num provider novo trivial → ele gera teste falhando → você implementa stub → teste passa.
   - Confirmar que o agent **não** edita `lib/` antes de teste vermelho existir.
5. Atualizar `CLAUDE.md` seção **"Verify Your Work"** → mencionar `flutter-test-author` como caminho TDD canônico para mobile.
6. Criar **ADR-0025 — Subagent flutter-test-author + escolha de mock library**.

### Gate de aceite
- [ ] Smoke test "TDD provider" passa: teste vermelho → implementação → verde.
- [ ] Smoke test "discipline" passa: agent recusa editar `lib/` sem teste vermelho.
- [ ] ADR-0025 commitado (inclui decisão de mock lib).
- [ ] `CLAUDE.md` atualizado.

### Riscos conhecidos
- Subagent pode tentar usar `dart:io` em widget tests — instruir explicitamente contra.
- Riverpod 3 codegen exige `part 'foo.g.dart'` — agent precisa lembrar (MCP ajuda).

### Commit
`feat(harness): flutter-test-author subagent (ADR-0025)`

---

## Fase 4 — Subagent `flutter-perf-auditor` 🔥

**Status:** ✅ entregue 2026-05-24 (sessão 22c). `.claude/agents/flutter-perf-auditor.md` (read-only allowlist: Read/Grep/Glob/Bash + 3 Dart MCP tools — sem Edit/Write/MultiEdit) + ADR-0027 + atualização CLAUDE.md + `M2-SLICE-CHECKLIST.md` §Verification ganhou bullet do auditor. Smoke-test funcional (bad-screen + clean-screen) deferred para sessão 23 pós-reload — agent registry carrega na boot da sessão, igual MCP e Phase 3.
**Tempo:** 1.5h
**Depende de:** Fase 1. **Pode rodar em paralelo com Fase 3** (são independentes).

### Por que existe
Slice 2 (Telas Core) tem map (`flutter_map` + OSM tiles) + listas grandes de stops. Risco real e identificado de: rebuild excessivo, `ListView` em vez de `ListView.builder`, falta de `const`, `ref.watch` em objetos inteiros, parsing pesado no UI thread.

### Tarefas
1. Criar `.claude/agents/flutter-perf-auditor.md`:
   - **Description:** "Use after implementing any screen in slice 2 (Telas Core), before opening PR. Reports performance issues — does not edit code. Punch-list output."
   - **Tools allowlist:** `Read, Grep, Glob, Bash(flutter analyze:*)` — **somente leitura, não edita**.
   - **Checklist canônico** (escrever no body do agent):
     - `const` constructors onde possível (`flutter analyze` já reporta — agent confirma e prioriza).
     - `ListView.builder` / `GridView.builder` para listas dinâmicas (regex grep por `ListView(` sem `.builder`).
     - `ref.watch` granular: detectar `ref.watch(someProvider)` quando só um campo é usado → sugerir `ref.watch(someProvider.select((s) => s.field))`.
     - `Isolate.run` para JSON parsing > ~10kb / parse de matriz GraphHopper.
     - `RepaintBoundary` em map markers e em widgets que repintam frequentemente.
     - Image caching para tiles OSM (verificar se o provider de tiles tem cache configurado).
     - `keys` corretos em listas reordenáveis.
   - **Output:** Markdown punch-list categorizada por severidade (must-fix / should-fix / nit).
2. Smoke test:
   - Criar branch temporária com tela propositalmente ruim (`ListView` com children list + sem `const` + `ref.watch` amplo) → agent flagra todos os 3.
   - Rodar contra uma tela limpa já existente → "no issues found".
3. Atualizar `docs/M2-SLICE-CHECKLIST.md` seção **§Verification** → adicionar passo "run flutter-perf-auditor" entre os passos existentes (após `flutter analyze`, antes de `prototype-fidelity-checker`).
4. Criar **ADR-0027 — Subagent flutter-perf-auditor**.

### Gate de aceite
- [ ] Smoke test "tela ruim" detecta os 3 problemas plantados.
- [ ] Smoke test "tela limpa" retorna sem falsos positivos.
- [ ] ADR-0027 commitado.
- [ ] `docs/M2-SLICE-CHECKLIST.md` atualizado.

### Riscos conhecidos
- Falsos positivos em `ref.watch` amplo quando o uso é intencional — punch-list categorizada como "should-fix" ajuda a humano avaliar.

### Commit
`feat(harness): flutter-perf-auditor subagent (ADR-0027)`

---

## Fase 5 — Decisão `mcp_flutter` (visual snapshot) — **GATE DE DECISÃO**

**Status:** ✅ entregue 2026-05-24 (sessão 22d). **Decisão: REJEITAR para o ciclo M2.** Critério 2 (gap visual real) já está fechado por ADR-0021 + ADR-0022 (device-E2E + integration_test + screenshot manual). Adotar agora duplica o gate sem evidência de que o manual falha. Critério de re-avaliação documentado em ADR-0028 (acionável em slice 3+ se: iterações visuais > 7/tela OU 2 device-E2E consecutivos com > 2 Criticals que o checker estático perdeu).
**Tempo:** 30 min decisão + 2h se adotar
**Fonte:** [github.com/Arenukvern/mcp_flutter](https://github.com/Arenukvern/mcp_flutter)

### Por que é um fork explícito
**Não pule a decisão.** Esta é a única fase desta sprint onde o caminho não é óbvio. Adotar tem custo de instrumentação no `main.dart`; rejeitar é legítimo se `prototype-fidelity-checker` + screenshots manuais bastam.

### Sub-fase 5.0 — Decisão (obrigatória)

**Critérios de decisão (responder honestamente):**
1. Você está fazendo > 10 iterações visuais por tela na slice 2? (Sim → adote.)
2. O `prototype-fidelity-checker` está deixando passar drifts visuais que screenshots manuais pegariam? (Sim → adote.)
3. O custo de pequena instrumentação em `main.dart` (guard `kDebugMode`) é aceitável? (Não → rejeite.)
4. Há preocupação com APK release size por causa do plugin? (Avaliar — se instalado em `dev_dependencies` + tree-shake correto, não deveria afetar release.)

**Decisão registrada em ADR-0028** — adotar OU rejeitar. **Ambos viram ADR.** Uma rejeição com motivo documentado é tão valiosa quanto adoção.

### Sub-fase 5a — Se adotar

5a.1. Ler README de `Arenukvern/mcp_flutter` no momento da execução (não copiar config de memória — pode ter evoluído).
5a.2. Adicionar plugin no `apps/mobile/pubspec.yaml` em `dev_dependencies` (preferencial) ou `dependencies` com guard de tree-shake.
5a.3. Instrumentar `main.dart` somente em debug builds usando `kDebugMode` guard.
5a.4. Adicionar entrada do MCP server em `.claude/settings.json` sob `mcpServers`.
5a.5. Smoke test: app rodando em debug + pedir ao Claude um snapshot → recebe widget tree + screenshot.
5a.6. Verificar release build: `flutter build apk --release` → confirmar que código de instrumentação foi tree-shaked (ou ao menos não inicializa).
5a.7. Atualizar `CLAUDE.md` **"Flutter Hot-Reload Discipline"** → mencionar que snapshot visual está disponível via MCP em debug.

### Sub-fase 5b — Se rejeitar

5b.1. Apenas ADR-0028 registrando o "não" com motivo (qual critério acima falhou).
5b.2. Sprint segue direto para Fase 6.

### Gate de aceite
- [ ] ADR-0028 commitado (qualquer dos lados).
- [ ] Se adotado: snapshot funciona em debug; release build limpo (sem código de instrumentação ativo).
- [ ] Se rejeitado: motivo claro no ADR.

### Riscos conhecidos
- Plugin de comunidade — risco de manutenção menor que MCP oficial. Mitigação: usar versão fixa, ADR documenta versão.
- Risco de leakage para release: mitigado pelo `kDebugMode` guard + verificação no smoke test 5a.6.

### Commit
`docs(decisions): ADR-0028 mcp_flutter adoption decision`
(seguido de `feat(harness): mcp_flutter visual snapshot integration` se adotar)

---

## Fase 6 — Golden tests (pivot para `alchemist`) 🔥

**Status:** ✅ entregue 2026-05-24 (sessão 22e). **Pivot técnico:** `golden_toolkit` (descontinuado pelo eBay há 3 anos) → **`alchemist ^0.14.0`** (Betterment + Very Good Ventures, ativo, 237k downloads, inspirado em golden_toolkit). Baseline canário em `HomeEmptyPage` (400×930 PNG, 10 KB) sob `apps/mobile/test/features/stops/presentation/goldens/ci/`. Gate-de-aceite validado: pixel-flip → FAIL com diff PNG; revert → PASS. Suite full 165/165. ADR-0029 documenta pivot + setup CI-mode-only + reasoning anti-hook.
**Tempo:** 2h
**Depende de:** Fase 3 (subagent test-author precisa saber escrever golden).

### Por que último
Maior custo de manutenção (baselines). Só vale depois das telas estarem estáveis. Tentar adotar no meio do desenvolvimento gera baseline churn.

### Tarefas
1. Validar versão atual de `golden_toolkit` via Context7 (ou pub.dev se Dart MCP estiver up — preferir MCP).
2. Adicionar `golden_toolkit` em `dev_dependencies` no `apps/mobile/pubspec.yaml`.
3. Configurar `apps/mobile/test/flutter_test_config.dart` com `loadAppFonts()` no setup global (ver doc oficial do pacote — não copiar de memória).
4. Escrever golden para **1 tela representativa** da slice 2 já implementada (não as 15 de uma vez — começar pequeno).
5. Gerar baseline: `cd apps/mobile && flutter test --update-goldens`.
6. Commitar baseline (`*.png`) no repo. Confirmar `.gitattributes` se necessário para LFS — provavelmente não para 1 tela.
7. Verificar que CI/dev local reproduz o golden idêntico (Flutter golden é determinístico mas font rendering pode variar entre OSes — documentar no ADR).
8. Adicionar passo opcional em `docs/M2-SLICE-CHECKLIST.md`: *"se a slice toca UI, atualizar goldens com `flutter test --update-goldens` e revisar diff visual no PR".*
9. **Decisão consciente: NÃO virar hook.** Goldens são caros de rodar; deixar manual no checklist.
10. Criar **ADR-0029 — Adoção de golden_toolkit**. Escopo explícito: telas estáveis pós-slice, não durante desenvolvimento ativo. Trade-off: baseline maintenance vs regressão visual.

### Gate de aceite
- [ ] Mudar 1 pixel intencionalmente na tela alvo → `flutter test` falha apontando o golden.
- [ ] Reverter a mudança → passa.
- [ ] Baseline (`*.png`) commitado.
- [ ] ADR-0029 commitado.
- [ ] `docs/M2-SLICE-CHECKLIST.md` atualizado.

### Riscos conhecidos
- Font rendering entre macOS/Linux/CI pode divergir — `loadAppFonts()` mitiga mas não elimina. Documentar.
- Tentação de virar golden tests em hook automático — **resistir**, custo > benefício.

### Commit
`test(mobile): golden tests baseline (ADR-0029)`

---

## Fase 7 — Documentação consolidada + retro

**Status:** ✅ entregue 2026-05-24 (sessão 22f). CLAUDE.md (Last updated, 1 nova Executable Commands row pra goldens) + docs/03-CONVENTIONS.md §Testing (2 bullets — TDD subagent + goldens) + docs/10-CHANGELOG.md (1 entrada consolidada cobrindo as 7 fases). docs/02-ARCHITECTURE.md propositalmente não tocado — descreve arquitetura do produto (auth, webhook Pix, route), não tooling da IA; harness vive em `.claude/` + `.mcp.json` + ADRs. Retro session log em `docs/sessions/2026-05-24-22f-sprint-m2ai-retrospective.md`. Header deste MD marca ✅ FECHADA. Sprint pronta para PR #8 mergear.
**Tempo:** 45 min
**Depende de:** todas as fases anteriores.

### Tarefas
1. Atualizar `CLAUDE.md`:
   - **"Executable Commands"** — adicionar comandos novos (Dart MCP activate, golden update, etc.).
   - **"In-Loop Auto-Validation"** — refletir hook adicionado na Fase 2.
   - **"Verify Your Work"** — refletir `flutter-test-author` e `flutter-perf-auditor`.
   - Bumpar `Last updated` no topo.
2. Atualizar `docs/02-ARCHITECTURE.md` se a topologia de tooling mudou — adicionar nota/diagrama sobre Dart MCP server.
3. Atualizar `docs/03-CONVENTIONS.md` se convenção de teste mudou (TDD via subagent).
4. Atualizar `docs/10-CHANGELOG.md` com a sprint completa (1 entrada datada listando ADRs 0023–0028).
5. Atualizar `docs/sessions/0001-INDEX.md`.
6. Criar `docs/sessions/2026-05-XX-NN-ai-harness-complete.md` com retrospectiva:
   - O que funcionou?
   - O que descartou e por quê (especialmente Fase 5 se rejeitada)?
   - Métrica de antes/depois se mediu (token cost por turno, frequência de "erro de API alucinada", etc. — ideal mas opcional).
   - Próximos itens descobertos durante a sprint → vão pra `TODO.md`.
7. Atualizar este `docs/sprints/2026-05-24-m2-ai-harness.md` marcando todas as fases como ✅ no header.

### Gate de aceite
- [ ] `CLAUDE.md` "Last updated" reflete data de fechamento.
- [ ] `docs/10-CHANGELOG.md` tem entrada da sprint.
- [ ] ADRs 0023–0028 (menos os rejeitados) listados em `docs/decisions/`.
- [ ] Sessão de retro commitada e indexada.
- [ ] Este MD reflete status final.

### Commit
`docs(harness): consolidate AI harness sprint (M2-AI)`

---

## Histórico — leitura, não execução

A sprint **terminou em 2026-05-24** (todas as 7 fases entregues, PR #8 contra `feat/m2-slice-2-telas-core` aguardando merge). Este documento é **registro histórico**, não checklist de trabalho.

Se você é uma sessão Claude lendo isto:

- Não tente "retomar" nada deste MD — está fechado.
- Para entender o que cada fase entregou e por quê, leia os ADRs 0023–0029 em `docs/decisions/` (são o registro canônico das decisões).
- Para o resumo executivo da sprint (lições, métricas, carry-overs), `docs/sessions/2026-05-24-22f-sprint-m2ai-retrospective.md`.
- Trabalho pendente que sobrou desta sprint vive em `TODO.md` § "Carry-overs from M2-AI sprint".

---

## Fontes consultadas

A pesquisa que originou esta sprint foi feita em 2026-05-24 com WebSearch + Context7 (`/websites/flutter_dev`) + queries diretas a docs oficiais. Lista completa:

### Oficiais (Flutter team)
- [AI rules for Flutter and Dart](https://docs.flutter.dev/ai/ai-rules) — atualizado 2026-01-05
- [Dart and Flutter MCP server](https://docs.flutter.dev/ai/mcp-server)
- [Agent Skills for Flutter and Dart](https://docs.flutter.dev/ai/agent-skills)
- [Create with AI](https://docs.flutter.dev/ai/create-with-ai)
- [Coding assistants](https://docs.flutter.dev/ai/coding-assistants)

### Comunidade — fontes citadas como inspiração (cherry-pick, não copy)
- [cleydson/flutter-claude-code](https://github.com/cleydson/flutter-claude-code) — 19 subagents + 1 skill SDLC Flutter
- [evanca/flutter-ai-rules](https://github.com/evanca/flutter-ai-rules) — rules multi-IDE
- [VoltAgent/awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents/blob/main/categories/02-language-specialists/flutter-expert.md) — flutter-expert
- [affaan-m/everything-claude-code — flutter-dart-code-review](https://github.com/affaan-m/everything-claude-code/blob/main/skills/flutter-dart-code-review/SKILL.md)
- [Arenukvern/mcp_flutter](https://github.com/Arenukvern/mcp_flutter) — MCP visual + semantic snapshot (avaliado na Fase 5)

### Comunidade — fontes avaliadas e **descartadas** (não adotar)
- [gmickel/flow-next](https://github.com/gmickel/flow-next) — sobrepõe nosso spec-driven
- [gotalab/cc-sdd](https://github.com/gotalab/cc-sdd) — mesma razão

### Anthropic — docs canônicos do Claude Code
- [Best practices for Claude Code](https://code.claude.com/docs/en/best-practices)
- [Subagents](https://code.claude.com/docs/en/sub-agents)
- [Skills](https://code.claude.com/docs/en/skills)
- [Hooks](https://code.claude.com/docs/en/hooks-guide)

### Artigos secundários (contexto, não normativo)
- [MCP Servers for Dart and Flutter Developers (2026 guide) — Voxturrlabs](https://voxturrlabs.com/blog/mcp-servers-for-dart-and-flutter-developers-2026/)
- [.cursorrules vs CLAUDE.md vs AGENTS.md em 2026 — The Prompt Shelf](https://thepromptshelf.dev/blog/cursorrules-vs-claude-md/)
- [Very Good CLI MCP Server](https://verygood.ventures/blog/very-good-cli-mcp-server-flutter-ai-tools/)

---

## Changelog deste documento

- **2026-05-24** — Criação inicial. Sprint planejada, nenhuma fase executada.
