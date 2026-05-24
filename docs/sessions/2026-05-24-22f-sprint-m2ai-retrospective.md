# Session 22f — M2-AI Harness sprint retrospective + Phase 7 closeout

## Metadata

- **Date**: 2026-05-24
- **Sequence**: 22f (sixth and final sub-session of the day for this sprint)
- **Agent**: Claude Code (Opus 4.7)
- **Human**: Eduardo
- **Topic**: Phase 7 (docs consolidate) + sprint retrospective
- **Duration**: ~25m
- **Related ADRs**: 0023, 0024, 0025, 0026, 0027, 0028, 0029 (full sprint)
- **Related sessions**: 19 (kickoff), 20 (Phase 1), 22 (Phase 2), 22b (Phase 3 + ADR-0026 housekeeping), 22c (Phase 4), 22d (Phase 5 rejection), 22e (Phase 6)

## Goal

Close the M2-AI Harness sprint: consolidate doc touches that span phases, write a sprint-level retrospective, mark SPRINT-MD as FECHADA. Last phase, no production code.

## What worked

- **Brainstorming-first via `superpowers:` + spec + plan templates (ADR-0019).** Session 19 locked 6 Q&As before writing a single hook or agent. Three of those Q&As (Q1 = adopt Dart MCP now, Q2 = PostToolUse not Stop for codegen, Q5 = sprint on parallel branch) determined the entire shape of the sprint — they would have been painful mid-sprint corrections.
- **Adopting the official Dart MCP first (Phase 1).** Every subsequent phase used `mcp__dart__resolve_workspace_symbol` / `pub_dev_search` / `hover` to validate symbols and dep versions before writing code. ADR-0023 paid for itself in Phase 6 alone when the MCP confirmed `alchemist`'s `PlatformGoldensConfig` / `goldenTest` / `GoldenTestScenario` existed in 0.14.0 — no training-memory guessing on a freshly-installed package.
- **`adr-guardian` at each phase boundary.** Caught the GH_DATA_DIR / extract-sp.sh gap (commit `bff1b6c` from another session had no ADR) immediately during Phase 3, instead of letting it hide until the PR audit. Result: ADR-0026 filed in the same commit set as Phase 3, no rollback or amended commits needed.
- **Karpathy §3 surgical changes.** No phase touched product code in `apps/mobile/lib/` (the `home_empty_page.dart` smoke flip in Phase 6 was reverted in the same shell line). Slice 2's microsprints (MS-15+, 7 Criticals remaining) are entirely undisturbed.
- **Read-only contracts enforced by tool allowlist** (Phase 4). Excluding Edit/Write/MultiEdit from `flutter-perf-auditor`'s tools makes "do not edit" mechanical, not just prompt-enforced. Mirrors `prototype-fidelity-checker` and `adr-guardian`'s shape.
- **ADR-0026 + planned-number shift.** When `adr-guardian` flagged the uncovered infra change mid-sprint, the move (file the housekeeping ADR-0026 + shift planned 0026→0027, 0027→0028, 0028→0029 via collision-safe `sed`) cost ~10 minutes and kept ADR numbering contiguous. Worth doing in the same commit, not a follow-up PR.
- **Enxuto ADR calibration mid-sprint.** Eduardo asked for shorter ADRs after Phase 4. ADRs 0028 + 0029 are ~60 and ~75 lines vs the ~190 of 0024–0027. No information lost — cut prose duplication between sections, kept frontmatter + decision + options table + consequences + rollback + verification. Will be the default shape for future ADRs.

## What got rejected (and the reason kept honest)

- **`mcp_flutter` adoption (Phase 5 → ADR-0028).** Plugin is healthy and Claude Code-supported. Rejected because the gap it would close (static fidelity-checker missing real device drifts, ADR-0021 row) is **already closed** by ADR-0021's device-E2E + per-step screenshot gate + ADR-0022's integration_test gate. Adopting now would duplicate without evidence the manual gate is failing. Documented re-evaluation trigger so the decision is auditable: iterations > 7/screen OR 2 consecutive device-E2E gates with > 2 Criticals each cleared by the static checker. **Not "maybe someday" — a measurable condition.**
- **`golden_toolkit` (Phase 6 spec's original choice).** WebFetch confirmed it's discontinued by eBay 3 years ago. Adopting a discontinued library on a new project violates the "Context7-mandatory before installing" precedence — same family of error as the MCP-server-format mistake the sprint draft made in Phase 1. Pivoted to `alchemist 0.14.0` (Betterment, MIT, active). ADR-0029 documents the pivot.
- **Initial `mcpServers` key in `.claude/settings.json` (Phase 1, never committed).** The Flutter docs show that format for Gemini CLI / OpenCode; Claude Code's settings schema validator rejected it. Pivoted to `.mcp.json` + `enabledMcpjsonServers` allowlist. Captured in ADR-0023 Options B/C.
- **Initial sprint topology "Phases 2–7 on a new branch off `develop`" (changed mid-sprint).** Owner explicitly redirected to keeping everything on `feat/m2-ai-harness` feeding PR #8. SPRINT-MD + CLAUDE.md drift fixes corrected before Phase 2 started. Lesson: re-validate handoff text after every owner conversation.
- **Hook automation for goldens (Phase 6).** Sprint anti-decision explicitly forbade it — golden regeneration is an intentional-change moment, not auto-triggered. Confirmed correct: turning it into a Stop hook would have rerun `--update-goldens` after every edit and corrupted baselines.

## Metrics (best-effort, not instrumented)

| Metric | Estimate | Source |
|---|---|---|
| Phases delivered | 7/7 | this MD |
| ADRs filed | 7 (0023–0029) | `docs/decisions/` |
| New files | 14 | `git diff --stat feat/m2-slice-2-telas-core...HEAD --diff-filter=A` |
| Modified files | 12 | same command, `--diff-filter=M` |
| Product code touched | 0 lines | every commit is `feat(harness)` / `docs(harness)` / `test(mobile)` / `chore(infra)` (the one from another session) |
| Tests added | 1 golden + sanity test (one-off, removed) | full suite 165/165 |
| Smoke validations deferred | 2 (subagent dispatches) | ADR-0025 + ADR-0027 §Verification |
| `--no-verify` uses | 0 | every commit passed lefthook + commitlint |
| Token cost vs pre-MCP | not measured but qualitatively lower | Dart MCP replaced ~5 `Read` calls per symbol lookup with 1 MCP call |
| API hallucination rate | qualitatively zero this sprint | the few cases where I almost guessed (e.g. mockito vs mocktail, `PlatformGoldensConfig` API) were caught by MCP `resolve_workspace_symbol` or `pub_dev_search` |

## Carry-overs (going to TODO)

1. **Smoke dispatches for `flutter-test-author` + `flutter-perf-auditor`** — Claude Code's agent registry only loads at session boot, so the session that authors the agent file cannot dispatch to it. Two exact prompts each are captured in ADR-0025 §Verification and ADR-0027 §Verification. Next session, post-reload, runs all 4 and writes a 1-paragraph session log.
2. **GraphHopper `:latest` → pinned tag (slice-3 entry blocker).** Inline `TODO(ADR)` in `infra/docker-compose.yml` since commit `bff1b6c`. Needs ADR-0008 amendment + config-compat revalidation (config uses `car_access` which is GH 9+). Already in `TODO.md` from session 21.
3. **Re-evaluation triggers (ADR-0028) for `mcp_flutter`.** No action needed unless either condition becomes true at slice 3+ entry — but next session reviewing slice-2 device-E2E reports should glance at them.
4. **Golden baselines per stable screen** — owned by each slice author at slice close. Sprint deliberately added only 1 (HomeEmptyPage) to avoid baseline churn.
5. **Re-run `adr-guardian` against the full PR #8 diff** just before merge — the per-phase sweeps were branch-base-relative; one consolidated sweep at merge time is cheap insurance.

## What I'd do differently next sprint

- **Phase 0's sprint draft assumed library versions and MCP server formats without checking them.** The Phase 1 ADR-0023 had to document a rejected Gemini-style format the draft suggested; Phase 6 had to pivot from a discontinued library the draft named. Cost ~30 min total to fix — cheap because spec-driven workflow surfaces drift early, but cheaper still if Phase 0 had spent 15 minutes per dep validating with Dart MCP / WebFetch before locking it into the spec.
- **The "(este commit)" placeholder pattern bit me once** in session 22b/22c (SPRINT-MD said `(este commit)` after the commit landed — caught by self-audit and fixed in `5cfa088`). Habit going forward: always close the loop on commit refs after the commit lands.
- **First golden test attempt failed Scaffold infinite-height assertion** because I forgot the `BoxConstraints.tightFor`. Cost ~3 min. Lesson encoded in ADR-0029 — but really it should be encoded in `flutter-test-author`'s prompt body so the next golden test the subagent writes doesn't repeat it.

## What changed in docs (Phase 7 audit summary)

| File | Change | Why |
|---|---|---|
| `CLAUDE.md` "Last updated" | Bumped to "sprint CLOSED, all 7 phases" | Sprint state |
| `CLAUDE.md` Executable Commands | +1 row for `flutter test --tags golden` | ADR-0029 introduces the command |
| `CLAUDE.md` §Context7 Mandatory | (Phase 1) +3-tier precedence rule | ADR-0023 |
| `CLAUDE.md` §In-Loop Auto-Validation | (Phase 2) +4th hook + split Stop/PostToolUse | ADR-0024 |
| `CLAUDE.md` §Verify Your Work | (Phase 3+4) +2 bullets on TDD subagent + perf auditor | ADR-0025 + ADR-0027 |
| `docs/02-ARCHITECTURE.md` | **No change** | Describes product topology (auth, webhook, route) — harness lives in `.claude/` + `.mcp.json` + ADRs |
| `docs/03-CONVENTIONS.md` §Testing | +2 bullets (TDD via subagent, golden tags) | ADR-0025 + ADR-0029 |
| `docs/M2-SLICE-CHECKLIST.md` §Verification | (Phase 4) perf-auditor bullet + (Phase 6) goldens bullet | ADR-0027 + ADR-0029 |
| `docs/10-CHANGELOG.md` | +1 dated entry covering the whole sprint | this file |
| `TODO.md` | All 7 sprint checkboxes ✅; new carry-over items added | progress |

## Files changed (Phase 7 specifically)

**Created**:
- `docs/sessions/2026-05-24-22f-sprint-m2ai-retrospective.md` (this file).

**Modified**:
- `CLAUDE.md` — "Last updated" + 1 Executable Commands row.
- `docs/03-CONVENTIONS.md` — §Testing 2 bullets.
- `docs/10-CHANGELOG.md` — sprint entry.
- `SPRINT-M2-AI-HARNESS.md` — header ✅ FECHADA + phase 7 status + handoff rewritten as "merge PR #8 + run deferred smoke + back to slice 2".
- `TODO.md` — Phase 7 + carry-overs.
- `docs/sessions/0001-INDEX.md` — entry added.

## Practical impact (plain language, full sprint)

A sprint **AI Harness** terminou hoje, depois de 7 fases num só dia (sessões 19 → 22f, branch `feat/m2-ai-harness`). O resultado: o app passou a ter uma camada de ferramentas de IA muito mais completa, sem nenhuma linha de código do produto ser tocada.

**O que o harness ganhou:**
1. **Servidor MCP oficial do Dart** — quando eu preciso saber a assinatura real de um método do Flutter ou Riverpod, eu pergunto pro analisador local, não chuto.
2. **Robô de codegen automático** — quando você edita um arquivo com `@riverpod`, o `.g.dart` se atualiza sozinho.
3. **Ajudante de testes (TDD)** — escreve o teste vermelho primeiro e se recusa a escrever a implementação.
4. **Ajudante de revisão de performance** — lê o código e devolve lista de problemas (lista que renderiza tudo, falta de `const`, etc.), sem poder editar.
5. **Foto de referência visual** — uma tela canário com PNG de referência; mudar 1 pixel sem querer faz o teste falhar.

**O que rejeitamos com motivo escrito:**
- O plugin `mcp_flutter` (boa ideia, mas duplicaria gate que já temos).
- O `golden_toolkit` original (descontinuado pela eBay — pivotamos pro `alchemist`).

**O que ficou pendente (rastreável):**
- Os dois ajudantes novos só aparecem no menu `/agents` depois que você reabre o Claude Code. Próxima sessão valida com os prompts já escritos nos ADRs.
- O pin de versão do GraphHopper continua aberto (slice 3 fecha esse).

**PR #8** (`feat/m2-ai-harness` → `feat/m2-slice-2-telas-core`) está pronto. Quando ele mergear, slice 2 retoma seus próprios microsprints (faltam 7 Criticals) com o harness completo.
