# Session 2026-05-29-02 — Area 4 (add-stop TEXT) MS5: D4 fixes + visual parity polish

## Metadata

- **Date:** 2026-05-29 (America/Sao_Paulo) — janela noite (sequência da sessão 01 que fez audit + D4 retroativo)
- **Sequence:** 02
- **Agent:** Claude Code (Opus 4.7, ultracode on)
- **Human:** Eduardo
- **Topic:** MS5 — aplicar 3 must-fix do D4 spoke-parity-checker + 1 fix descoberto na validação visual M54
- **Related ADRs:** ADR-0035 (Spoke parity hierarchy), ADR-0036 (parity gate), ADR-0037 (Maestro MCP inspection)
- **Related TODO items:** Slice 2 Area 4 — TEXT method (MS5 ✅ código + tests; MS4 verification ainda pendente)

## TL;DR

MS5 shipped 7 commits aplicando 3 must-fix do D4 (Section B icon-free, Footer text-only, Section A pencil trailing) + 1 fix descoberto durante validação visual ao vivo no M54 (X = limpar input em vez de fechar tela). +14 testes (89 → 91 all green). Disciplina subagent-driven-development com 2-stage review por task respeitada — reviewer encontrou 4 issues importantes (não-bloqueantes pra produção) durante o ciclo; 3 foram aceitos como fixes e aplicados em commits separados. 1 concern aceito como `DONE_WITH_CONCERNS` (test cobre comportamento end-to-end mas não isola a linha defensiva `_onClear.search('')` — over-engineering remove redundância contratual).

**Status real pós-MS5:** código pronto, mas **NÃO pronto pra PR** até:
1. Re-validação visual no M54 confirmar os 3 fixes (compromisso com a sessão 01 que descobriu os gaps via inspeção visual).
2. Smoke Maestro YAML standalone substituir o integration_test brittle (`add_stop_flow_test.dart` continua falhando em fresh install, mas agora é menos crítico — UI pode ser validada por YAML stateless).
3. Final code reviewer dispatch.

## Context

Continuação direta da sessão `2026-05-29-01` que executou audit + dispatch retroativo do `spoke-parity-checker` D4. Resultado D4: 3 must-fix + 2 should-fix descobertos. Eduardo decidiu (registrado em commit `1f598f5`) manter os 2 should-fix (ícones decorativos em empty/zero-results) como "RotPro additive" — não bloqueiam parity funcional. Os 3 must-fix nasceram MS5.

Após validação visual no M54 (durante a mesma sessão 01), apareceu **uma 4ª descoberta**: o botão X no canto direito da search bar estava chamando `context.pop()` (fecha a tela). Comportamento esperado per Spec Goal #10: X = limpar input. Eduardo confirmou que MS5 ganha esse 4º fix.

Plan formal MS5 = não criado (3 tarefas bite-sized, escopo claro do D4 amendment + validação visual). A inventory amendment §11.4 items 5/6/7 + Spec Goal #10 ESTÃO o spec; cada task tem TodoWrite entry.

## What Was Done

### Task 1: Section B icon-free + Footer text-only (3 commits)

**Spec:** inventory §11.4 amendments items 5 + 7 (D4 2026-05-29).

- `16ee368` — Production: remove `leading:` de Section B `ListTile`; remove `leading:` + `trailing:` do Footer `ListTile`. Test: 3 assertions adicionadas ao test existente `'WithResults renders Section A header + Section B header + Footer'`.
- **Code quality reviewer flagou Important:** bundling de 3 assertions em 1 `testWidgets` viola convenção do projeto (1 behavior per test, ex: `route_kebab_menu_test.dart`, `drawer_route_tile_test.dart`).
- `1b9cafa` — Fix #1: split de 3 → 2 testWidgets (preservar test original com 3 header assertions, criar `'WithResults footer has no trailing chevron icon'`, criar `'WithResults Section B ListTile has no leading icon; Section A keeps leading icon'`).
- **Reviewer re-flagou:** o último test ainda tem semicolon no nome + 2 expects independentes. Convenção do `drawer_route_tile_test.dart` mostra inverse states sendo split.
- `ddbc290` — Fix #2: split adicional do test com semicolon em 2 testes single-`expect` (`'Section B ListTile has no leading icon'` + `'Section A keeps leading icon'`).
- **Reviewer aprovou.**

### Task 2: Section A trailing pencil affordance (2 commits)

**Spec:** inventory §11.4 amendment item 6 (D4 2026-05-29).

- `2da3359` — Production: adiciona `trailing: const Icon(LucideIcons.pencil, size: 16, color: AppColors.textMuted)` na Section A `ListTile`. Test: novo `testWidgets` com `find.ancestor + .trailing != null`.
- **Code quality reviewer flagou Important:** assertion `isNotNull` é fraca — não verifica que o ícone é especificamente `pencil`; um swap acidental pra outro ícone ainda passaria.
- `4e43fce` — Fix: usa `find.descendant(of: find.ancestor(...), matching: find.byIcon(LucideIcons.pencil))` + `findsOneWidget`. Sanity-check executado: produção temporariamente trocada pra `LucideIcons.x`, test falhou com mensagem específica de IconData; revertido.
- **Reviewer aprovou.**

### Task 3: Search bar X clears input (2 commits)

**Spec:** Spec Goal #10 + §11.4 amendment 2026-05-29 (descoberta visual M54 sessão 01).

- `972c933` — Production: cria `_onClear()` method chamando `_controller.clear()` + `setQuery('')` + `placeAutocompleteProvider.notifier.search('')`. Tooltip: `'Fechar'` → `'Limpar'`. Remove `import 'package:go_router/go_router.dart'` (não-usado após remover `context.pop()`). Test: novo `testWidgets` com 4 assertions (query reset, scanLine reappear, mic reappear, controller text empty).
- **Code quality reviewer flagou Important:** o `placeAutocompleteProvider` reset não é asserted pelo test — uma regressão futura que remova `search('')` do `_onClear` passaria silenciosamente.
- `9ab267a` — Fix: adiciona `expect(isA<AsyncData<...>>())` + `expect(state.value, isEmpty)` no test (forma robusta — `const AsyncData<...>([])` não funciona por causa de equality do Riverpod). Sanity-check: linha defensiva temporariamente comentada na produção, test ainda passa porque `_controller.clear()` notifica `TextField.onChanged` que chama `search('')` transitivamente. Subagent flagou como `DONE_WITH_CONCERNS` — concern #2 indica que o teste cobre comportamento end-to-end mas não isola a linha defensiva específica.
- **Decisão controller:** aceitar `DONE_WITH_CONCERNS` (não dispatch terceira fix loop). Rationale: a redundância em `_onClear` é defensive code legítimo (explicita o contrato pro leitor — 3 mutações observáveis); transformar em unit test de notifier seria over-engineering pra um widget test de UI.

## Decisions Made (with rationale)

1. **`isA + isEmpty` em vez de `const AsyncData<List<...>>([])`** — `AsyncData` em Riverpod não faz deep equal de payload `List`. A forma robusta é checar tipo + valor isoladamente. Lição: pinning de Riverpod async state requer pattern explícito, não literal const.
2. **Manter linha defensiva `search('')` em `_onClear`** mesmo que o `_controller.clear()` já dispare via `onChanged` — explicita o contrato de 3 mutações. Trade-off: redundância contractual aceita; remove o code seria YAGNI mais puro mas reduz leitura sem ganho mensurável.
3. **Bundling de 3 → 1 testWidgets é anti-pattern neste projeto** — todos os widget tests em `apps/mobile/test/features/routes/presentation/widgets/` (`route_kebab_menu_test.dart`, `drawer_route_tile_test.dart`, `app_drawer_test.dart`) usam 1 behavior per `testWidgets`. Persisted lesson: futuras adições de assertions seguem split per behavior.
4. **`find.byIcon(specific)` > `isNotNull`** quando o teste promete identidade — nome do test "trailing pencil icon" deve ser falsificável por swap de ícone. Lição: assertion semantics deve casar com test name promise.
5. **`go_router` import removido** quando `context.pop()` saiu — lefthook teria flagrado como warning eventualmente, mas explicit cleanup no commit é cleaner.
6. **Tooltip `'Fechar'` → `'Limpar'`** — accessibility label deve refletir comportamento real. Grep cross-codebase confirmou que `'Fechar'` é usado em outros lugares (`app_drawer.dart`, `wizard_route_page.dart`) com semântica correta para AQUELES contextos — não foi tocado.
7. **Ícones decorativos `plusCircle` (empty) + `searchX` (zero-results) MANTIDOS** per Eduardo (commit `1f598f5`). Não bloqueia parity funcional; toque RotPro aceito.

## Open Questions / Carry-over (atualizados 2026-05-29 noite)

- ✅ **Re-validação visual no M54** concluída. App reinstalado com código MS5. Confirmados visualmente: Section B text-only ✅, Footer text-only sem chevron ✅, Section A com pencil trailing ✅, X = limpar (tooltip "Limpar") ✅, Section A tap = SnackBar "Editar parada em breve" ✅.
- ✅ **Smoke Maestro YAML standalone** (`apps/mobile/scripts/add_stop_text_flow.yaml`) — rodou 100% green em `RQCW401G33T` 2026-05-29 12:38. Cobre login → drawer → criar rota → empty state → typing morph → results header/footer → zero-results state → Android back.
- ✅ **Final code reviewer dispatch** concluído via workflow `wq54n3bfn` (5 reviewers paralelos + adversarial verify + synthesis). Verdict: APPROVE-WITH-FIXES (3 quick wins). Findings aplicados em fix commits.
- ⚠️ **Maestro YAML NÃO cobre tap-then-network** — Section A tap = SnackBar e Section B tap = create-stop-then-pop são pulados no YAML. Per Maestro docs ([docs.maestro.dev/get-started/supported-platform/flutter.md](https://docs.maestro.dev/get-started/supported-platform/flutter.md)): tap em `ListTile` via text matcher é unreliable porque Maestro acerta o `TextView` interno em vez do `ListTile` clickable parent. **Best practice moderna:** envolver `ListTile` com `Semantics(identifier: 'add-stop-section-b-row')` no widget de produção, depois usar `tapOn: { id: "..." }` no YAML. Custo: 4 linhas em `add_stop_results_section.dart`. **Decisão atual:** adiar pra próxima iteração — widget tests cobrem tap-then-callback via override (`'Section A tap shows SnackBar'`, `'Footer tap navigates to /home/routes/add-stop/map'`). Spec Goals #7/#8 não regredem silenciosamente.
- 🔍 **Spoke comparison follow-up (sugestão Eduardo 2026-05-29):** comparar dump uiautomator do flow "Add stop" do Spoke (`com.underwood.route_optimiser`) vs RotPro pra ver como o Spoke estrutura suas rows clickáveis. Maestro pode estar funcionando pro Spoke porque ele usa estrutura nativa Android (Compose ou View tradicional) em vez de Flutter accessibility tree. Tracked como follow-up Area 6 (quando edit-stop sheet for implementada, o spoke-parity-checker já vai fazer dump comparativo).
- **Quando abrir PR** — agora.

## Files Changed

**Production (1 file, modified twice):**
- `apps/mobile/lib/features/routes/presentation/widgets/add_stop_results_section.dart` — Tasks 1 + 2 (Section B/Footer cleanup + Section A pencil)
- `apps/mobile/lib/features/routes/presentation/widgets/add_stop_search_bar.dart` — Task 3 (X clear behavior)

**Tests (2 files):**
- `apps/mobile/test/features/routes/presentation/pages/add_stop_page_test.dart` — Tasks 1 + 2 (+5 new testWidgets)
- `apps/mobile/test/features/routes/presentation/widgets/add_stop_search_bar_test.dart` — Task 3 (+1 new testWidgets)

**Inventory (1 file):**
- `docs/inventory/2026-05-26-spoke-vs-rotpro.md` — §10.21 items 6+7 marcados decidido por Eduardo (commit `1f598f5`)

## Process Lições Reforçadas (sem novos memory entries — todas já cobertas)

1. **Spec compliance review + code quality review per task** — disciplina respeitada. Reviewer encontrou issues reais (4 importantes), não decoração. Custo: 3 fix loops em 3 tasks (Task 1: 2 splits, Task 2: 1 assertion strengthening, Task 3: 1 coverage gap). Tempo extra: ~20% sobre dispatch-único-e-aprovar. ROI: cada fix evitou shipping de débito técnico (test bundle, weak assertion, missing coverage).
2. **`lesson_checkpoint_discipline_between_microsprints` aplicada** — final do MS5: TODO.md atualizado, este session log criado, vai pro push no próximo commit.
3. **DONE_WITH_CONCERNS é status válido** — Task 3 final fix expôs concern que poderia ter virado 3ª fix loop. Decisão controller (não-subagent) avaliou o ROI: redundância contractual aceita > over-engineering test isolation. Lesson informal: nem todo concern do reviewer precisa virar fix; controller pode aceitar com rationale documentado.
