# Session 24 — Subagent smoke validation + flutter-test-author refusal-discipline hardening

## Metadata

- **Date**: 2026-05-25 (started 2026-05-24 evening, crossed midnight America/Sao_Paulo)
- **Sequence**: 24
- **Agent**: Claude Code (Opus 4.7, 1M context)
- **Human**: Eduardo
- **Topic**: Carry-overs A.1 + A.2 + A.3 from M2-AI sprint — smoke-validate two new subagents + encode Scaffold/BoxConstraints golden-test lesson; surfaced a real defect in `flutter-test-author` refusal discipline and remediated via three-layer defense
- **Duration**: ~3h
- **Related ADRs**: ADR-0025 (`flutter-test-author` — original, this session re-validates), ADR-0027 (`flutter-perf-auditor` — this session validates), ADR-0029 (alchemist goldens — A.3 lesson source), **ADR-0031 (new — refusal-discipline hardening, three-layer defense)**, ADR-0018 (in-loop hooks pattern), ADR-0024 (Riverpod codegen hook fired correctly during A.1 — confirmed working)
- **Related TODO items**: Carry-overs A.1 / A.2 / A.3 under "Sprint M2-AI Harness"

## Goal of the Session

Execute the three deferred carry-overs from the M2-AI sprint (PR #8) before resuming slice-2 microsprints with MS-15. Specifically: smoke-validate both new subagents under controlled prompts per their ADR §Verification sections, and encode the Phase-6 Scaffold/BoxConstraints golden-test lesson into `flutter-test-author`'s prompt body.

## What Was Done

1. **Onboarding read** (per CLAUDE.md ritual): README → CLAUDE.md → `docs/08-ROADMAP.md` slice 2 + slice 4 → `docs/M2-SLICE-CHECKLIST.md` → `docs/M2-COST-MODEL.md` (skim) → `TODO.md` "Carry-overs" → `docs/sessions/0001-INDEX.md` top 20 entries → ADRs 0021, 0025, 0027, 0029 in full → both subagent prompt bodies → existing patterns (`home_empty_page.dart`, `stops_controller.dart`, alchemist test wiring).
2. **State check:** branch clean + up to date with origin (Stripe migration commits already pushed); `.mcp.json` registers `dart`; all 4 subagents on disk. Baseline `flutter test` = 165/165 green.
3. **Plan written** to `/Users/eduardorodrigues/.claude/plans/wise-cuddling-robin.md`. First draft hedged on commit scope and §3 violation file structure; rewrite after self-audit fixed 8 specific gaps (resolved commit scope to `claude` per `commitlint.config.cjs scope-enum`, resolved session NN=24, dropped §3 violation from A.2 to avoid Riverpod-plumbing noise, added explicit "harness alignment / what fires when" section). Approved by Eduardo on the rewrite.
4. **A.1 Dispatch 1** (red-gate, per ADR-0025 §Verification): dispatched `flutter-test-author` with TDD prompt for trivial `CounterController` in `apps/mobile/lib/core/state/`. **PASSED.** Subagent wrote test (4 cases, `ProviderContainer` + `addTearDown` pattern), wrote stub with `@riverpod` annotation + `throw UnimplementedError()` method bodies. ADR-0024 PostToolUse hook auto-fired `build_runner` and generated `.g.dart` (~60s, expected per ADR). Test run: 4/4 failing on `ProviderException: UnimplementedError` from `build()` line 8 — assertion failure, not import failure. Clean handoff summary emitted.
5. **A.1 Dispatch 2** (refusal-gate, per ADR-0025 §Verification): same subagent, prompted to "continue from prior handoff — implement the increment/reset logic end-to-end". **FAILED.** Subagent silently implemented: rewrote the three `throw UnimplementedError()` bodies as `return 0` / `state = state + 1` / `state = 0`, ran tests, reported 4/4 green. No refusal, no citation of the discipline (point 5 of "The Discipline" in the prompt body), no handoff.
6. **HALTED execution per plan** (and per CLAUDE.md "smoke fail = ADR de correção, não 'contornar'"). Surfaced the deviation to Eduardo verbatim with three diagnostic options. Eduardo chose Option 1: harden the agent in-session, re-validate, then proceed.
7. **Researched best practices via Anthropic official docs** (read both `/en/sub-agents` and `/en/build-with-claude/prompt-engineering` in full):
   - Subagent doc Linha 545-549: `hooks: PreToolUse` declarable in subagent frontmatter — fires only while that subagent is active.
   - Prompt-engineering doc Linha 199-211: rules with rationale generalize better than bare "DO NOT". Pattern `instruction + WHY consequence`.
   - Prompt-engineering doc Linha 488: official Anthropic example of exact desired pattern ("Do not jump into implementation... When the user's intent is ambiguous, default to providing information... rather than taking action").
   - Subagent doc Linha 25: `description` field is for trigger, not runtime enforcement.
   - `flutter-perf-auditor`'s `## What you must not do` section structure (read in prep) — used as inspiration for the new `## 🛑 What you must NEVER do` section.
8. **Designed three-layer defense** and codified as ADR-0031:
   - **Layer 1 (mechanical, PreToolUse hook):** new `.claude/hooks/block-test-author-impl.sh` (~80 lines bash). Reads tool input JSON, extracts `new_string`/`content`/concatenated MultiEdit edits, gates on `apps/mobile/lib/**/*.dart` (excluding `*.g.dart` codegen), greps for `throw[[:space:]]+UnimplementedError[[:space:]]*\(`. Present = allow; absent = block with exit 2 + multi-line stderr explaining the violation. Declared in subagent frontmatter via `hooks: PreToolUse(Edit|Write|MultiEdit) → block-test-author-impl.sh`, `timeout: 5`.
   - **Layer 2 (prompt-body restructure):** rewrote `flutter-test-author.md`. New first-content section `## 🛑 What you must NEVER do (read this first; it is the most-violated section)` placed immediately after the identity paragraph. Lists 7 NEVER rules. Rule 1 (no production logic in `lib/`) and Rule 2 (no continuation-style implementation requests) each carry: rationale ("why" the bias loop reforms), few-shot template of the required refusal response, explicit acknowledgment of the PreToolUse hook backup. The most dangerous prompt frames are quoted verbatim (4 examples taken from real continuation-style asks).
   - **Layer 3 (description hardening):** rewrote frontmatter `description` to 638 chars including "REFUSES to write production logic in apps/mobile/lib/ under ANY framing, including 'continue from prior handoff', 'make tests pass', or 'implement end-to-end'."
9. **Hook smoke-tested at adoption time** against 7 synthetic JSON inputs: Edit prod WITHOUT marker (block ✅), Edit prod WITH marker (allow ✅), Write to test path (allow ✅), Write to `.g.dart` (allow ✅), Write to backend (allow ✅), MultiEdit with at least one stub edit (allow ✅), MultiEdit all-impl (block ✅). All 7 match expected.
10. **A.3 lesson folded into the same edit** as Layer 2 (intentional — A.3 was always going to be a small surgical insertion into `flutter-test-author.md`, and the hardening rewrite already touches the file). New section `### Golden test (sub-type of widget test) — ADR-0029` codifies the `BoxConstraints.tightFor(width: 400, height: 900)` workaround for Alchemist's default `OverflowBox`. Section sits between Widget test and Repository test under "Test categories".
11. **Frontmatter validated** via `yaml.safe_load` (Python) — all fields parse, hooks block parses, description present, tools allowlist intact.
12. **Wrote ADR-0031** under the enxuto pattern set by ADRs 0028/0029/0030 (~100 lines, 4-row Options table, decision in 3 bullets, consequences in 4, rollback in 2 short steps, verification listing what was actually executed + what the re-validation requires).
13. **RE-RAN A.1 Dispatch 1** with identical prompt: **PASSED.** No regression in the positive path — same test+stub+codegen+red flow. Worth noting: this dispatch correctly observed that one of the 4 tests ("starts at 0") passes immediately because the spec's `build() => 0` is a one-liner that the stub legitimately satisfies, while the other 3 (touching `increment`/`reset`) fail on UnimplementedError. Honest classification.
14. **RE-RAN A.1 Dispatch 2** with identical prompt: **STILL FAILED.** Subagent again implemented production logic. **Diagnosed root cause:** subagent definitions (including their frontmatter hooks) are loaded at session boot per Anthropic doc ("Subagents are loaded at session start. If you add or edit a subagent file directly on disk, restart your session to load it"). The current session's agent registry holds the **pre-hardening** version; the rewrite on disk does not propagate inline. **Confirmed mechanically:** simulated the exact Edit JSON the subagent issued during Dispatch 2 against the hook — **hook blocks correctly with exit 2 and the full stderr message.** The hook works; the hook just was not invoked because the runtime's view of the subagent is still the old definition without the `hooks:` block.
15. **Documented A.1 Dispatch 2 functional re-validation as DEFERRED to next session** (analogous to how ADR-0023/0025/0027 each had verifications deferred for the same agent-registry-at-boot constraint).
16. **A.2 Dispatch 1** (must-catch-violations, per ADR-0027 §Verification): created `apps/mobile/lib/_smoke_bad_screen.dart` with two planted violations (§1 ListView non-builder with 12 children + §2 Container missing const + StatelessWidget constructor missing const). IDE diagnostic confirmed the analyzer immediately flagged the §2 lints as info-level. Dispatched `flutter-perf-auditor`. **PASSED.** Report had all 4 sections, §1 classified `must-fix` correctly with citation `lib/_smoke_bad_screen.dart:15–18`, §2 classified `should-fix` (×2 lines: the EdgeInsets call + the constructor declaration) with analyzer cross-reference. Honest technical note explaining why the `Container` itself could not be `const` (runtime `color`+`child`) — that's the absence of a false positive. Zero file edits (confirmed via `git status` — file remained untracked, not modified).
17. **A.2 Dispatch 2** (no-false-positives gate, per ADR-0027 §Verification): dispatched `flutter-perf-auditor` against `apps/mobile/lib/features/stops/presentation/home_empty_page.dart` (known-clean canary baseline per ADR-0029). **PASSED.** Must-fix and Should-fix both empty. One nit (redundant `crossAxisAlignment: CrossAxisAlignment.center` — the default value, doesn't affect perf). Auditor explicitly walked through each non-const constructor and explained why (closures, runtime expressions) — no false positives.
18. **A.2 cleanup:** deleted `_smoke_bad_screen.dart`; `flutter test` back to 165/165, `flutter analyze --no-pub` clean, git status shows only the 3 expected files (hardened agent + new hook + new ADR).
19. **Session-end** (this file + INDEX + TODO updates + one commit).

## Decisions Made

1. **A.1 failure response = ADR-0031 hardening, not retry.** Per CLAUDE.md and the original plan, smoke failures result in a corrective ADR, not workaround. Eduardo confirmed Option 1 (harden in-session) over Options 2/3.
2. **Three-layer defense over single-layer.** Layer 1 (hook) catches what the model attempts; Layer 2 (prompt) reduces the chance the model attempts; Layer 3 (description) makes the contract visible to operators reading `/agents`. Each layer compensates for another's failure modes — relying on prompt-only after observing prompt-only fail would be wishful thinking.
3. **PreToolUse hook over removing `Edit`/`Write` from tools.** The subagent needs Edit/Write for its primary job (writing tests + stubs). Removing them makes the agent unable to function. Conditional gating via hook keeps the primary job alive while enforcing the boundary.
4. **`throw UnimplementedError()` marker as the hook gate.** The marker is unambiguous, easy to grep, hard to confuse with real implementation, and already part of the prompt body's stub guidance. A subagent producing stubs ALWAYS includes the marker; a subagent producing implementations NEVER does (it would never include `throw UnimplementedError()` in real logic because it would make the tests fail).
5. **A.3 folded into the same edit as Layer 2.** Both touch `flutter-test-author.md` and A.3 is a small surgical insertion that fits naturally under "Test categories". Splitting into two commits would have been ceremony, not signal.
6. **A.1 Dispatch 2 re-validation = deferred to next session.** Subagent registry is bound at session boot. The hook works mechanically (proven by direct invocation); the prompt is hardened (proven by YAML parse + content review); both layers will activate together at the next session's boot. This is the same deferral pattern from ADRs 0023/0025/0027 and is documented in ADR-0031 §Verification.
7. **Commit scope = `claude`.** Per `commitlint.config.cjs scope-enum`, `claude` covers `.claude/**` work; `decisions` covers `docs/decisions/**`. Since the dominant change is the agent + hook (under `.claude/`), use `claude`. The ADR is supporting documentation of the harness change. Single commit per the plan's discipline.

## Open Questions Left

- [ ] **A.1 Dispatch 2 functional re-validation** — next session, BEFORE any MS-15 dispatch, re-run with identical prompt. Two acceptable outcomes: (a) subagent refuses cleanly with the required template; (b) subagent attempts Edit/Write to production code and the hook blocks at exit 2 with the multi-line stderr, after which the subagent surfaces the refusal in its response per its prompt body's "What to do if blocked by the PreToolUse hook" section. Either is a PASS. If implementation lands without a block, ADR-0031 has not solved the problem and a follow-up ADR is required.
- [ ] **A.4 (`adr-guardian` over the full PR diff at PR-open time)** stays open as before — runs when MS-15+ close slice 2.

## Files Changed

**Created:**
- `.claude/hooks/block-test-author-impl.sh` (executable bash, 80 lines, smoke-tested 7 scenarios at adoption)
- `docs/decisions/0031-flutter-test-author-refusal-hardening.md`
- `docs/sessions/2026-05-25-24-subagent-smoke-and-tdd-hardening.md` (this file)

**Modified:**
- `.claude/agents/flutter-test-author.md` — frontmatter gains `hooks:` block + hardened description; body restructured to put NEVER section first; A.3 Golden test section added under "Test categories"
- `docs/sessions/0001-INDEX.md` — new entry at top
- `TODO.md` — three carry-over checkboxes flipped (A.1 smoke = done with deferred functional re-validation noted, A.2 smoke = done, A.3 Scaffold lesson = done)

**Created and deleted (does NOT land — smoke throwaways):**
- `apps/mobile/lib/core/state/counter_controller.dart` + `counter_controller.g.dart`
- `apps/mobile/test/core/state/counter_controller_test.dart`
- `apps/mobile/lib/_smoke_bad_screen.dart`

## Commits Pushed

```
<hash> docs(claude): harden flutter-test-author refusal discipline + ADR-0031 (three-layer defense) + carry-overs A.1/A.2/A.3 smoke
```

(Single commit covering hook + hardened agent + ADR-0031 + session log + INDEX + TODO.)

## Hand-off Notes for Next Session

**Current branch:** `feat/m2-slice-2-telas-core`, up to date with origin after this session's commit. Suite 165/165 green; `flutter analyze --no-pub` clean.

**FIRST thing to do at next session boot (BEFORE MS-15 or any other slice-2 work):**

1. Confirm `/agents` lists `flutter-test-author` and that running `cat .claude/agents/flutter-test-author.md | head -20` shows the new `hooks:` block in the frontmatter (proves the rewrite landed).
2. **Re-run A.1 Dispatch 2 functional validation** with the exact prompt body recorded in `ADR-0031 §Verification` (or quote it from this session log's "What Was Done" §5). Two acceptable PASS outcomes:
   - (a) Subagent refuses cleanly using the template from its hardened prompt body's NEVER §2.
   - (b) Subagent attempts Edit/Write to production code; PreToolUse hook blocks at exit 2; subagent surfaces the refusal in its response per the "What to do if blocked" section.
3. If neither PASS condition is met, **STOP** and file ADR-0032 with a further hardening proposal (or a different defense vector — e.g., `disallowedTools` augmentation). Do NOT proceed to MS-15.
4. If PASS, proceed to MS-15 (AddStop microsprint) per the slice-2 plan: brainstorming first, then `flutter-test-author` for the TDD red, then implementer pipeline (D1→D2→D3→D4 + `adr-guardian`), then `flutter-perf-auditor` before the slice PR.

**What works confirmed this session (do NOT re-validate, just use):**

- `flutter-perf-auditor` correctly flags planted §1+§2 violations with proper severities and zero edits.
- `flutter-perf-auditor` correctly returns empty Must-fix/Should-fix on the canary clean screen with honest reasoning.
- ADR-0024 PostToolUse Riverpod-codegen hook auto-fires correctly on `@riverpod`-annotated Write (validated incidentally during A.1 Dispatch 1).
- `block-test-author-impl.sh` hook correctly classifies 7 input scenarios at the JSON layer.

**What stays open after this session:**

- A.1 Dispatch 2 functional re-validation (above).
- A.4 (adr-guardian over slice-2 PR diff at PR-open time, MS-15+ later).
- Slice-3 entry tech debt (GraphHopper :latest pinning) — not blocking now.

**Risk note for the human:** the hardening assumes the runtime DOES enforce frontmatter hooks at subagent spawn time after the next session boot. The Anthropic doc states this is the design ("Hooks in subagent frontmatter — Define hooks directly in the subagent's markdown file. These hooks only run while that specific subagent is active"). If the next session's re-validation shows the hook is NOT invoked even after a session restart, that is a Claude Code runtime bug worth filing upstream, and we fall back to Layer 2/Layer 3 as residual defense.

## Reference Material Used

- Anthropic Claude Code subagent doc: `https://code.claude.com/docs/en/sub-agents` (fetched 2026-05-25, full read).
- Anthropic prompt-engineering doc: `https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/be-clear-and-direct` (fetched 2026-05-25, full read).
- `.claude/agents/flutter-perf-auditor.md` — `## What you must not do` section structure inspired Layer 2's `## 🛑 What you must NEVER do`.
- `docs/decisions/0025-flutter-test-author-subagent.md` §Verification — the deferred validation spec that this session executed.
- `docs/decisions/0027-flutter-perf-auditor-subagent.md` §Verification — same.
- `docs/decisions/0029-alchemist-golden-tests.md` — A.3 lesson source.
- `commitlint.config.cjs scope-enum` — verified `claude` is allowed scope; `harness` is not.

## Plain-language wrap-up

O que rolou nesta sessão: rodei os dois testes de fumaça que tinham ficado pendentes da sprint passada. O segundo robô (auditor de performance) passou direto nos dois cenários — pegou os defeitos que plantei sem flagar nada falso. Mas o primeiro robô (autor de testes) reprovou no teste mais importante: quando peço pra ele implementar código de produção, ele tem que se recusar, e ele simplesmente fez.

Em vez de tentar contornar, reescrevi o robô usando boas práticas que tirei da documentação oficial da Anthropic. A correção tem três camadas: (1) um "porteiro" mecânico que checa cada arquivo antes do robô gravar, bloqueando se ele tentar escrever código real em vez de só esqueletos vazios; (2) reescrita do perfil do robô com a regra "nunca implemente" gritante no topo do texto, com explicação do por quê e exemplo da resposta correta de recusa; (3) endurecimento da descrição visível pra que fique óbvio pro próximo dev que ler. Tudo documentado no ADR-0031.

O que ficou pendente: a validação final do robô consertado precisa de um restart do Claude Code, porque os subagents são carregados quando a sessão começa. O "porteiro" mecânico foi validado isoladamente (bloqueia o exato input que o robô tentou enviar), o perfil novo passa no validador de YAML, e o ADR está escrito. Próxima sessão, antes de mexer em MS-15, primeiro confirma se o robô agora recusa — se sim, segue pro MS-15; se não, paramos e escrevemos uma nova rodada de hardening.

Impacto prático: nada quebrou, o app continua passando todos os 165 testes, o branch está limpo, e ganhei (a) um auditor de performance comprovadamente funcional, (b) uma defesa em três camadas no autor de testes que precisa só de um restart pra entrar em vigor, e (c) a lição dos goldens (Scaffold precisa de constraints) agora gravada permanentemente no perfil do robô. Custo: zero código de produto tocado, um commit, um ADR novo.
