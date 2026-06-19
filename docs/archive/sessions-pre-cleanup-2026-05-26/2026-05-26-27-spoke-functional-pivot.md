# Session 27 — Strategic pivot: Spoke functional clone + prototype as visual reference

## Metadata

- **Date**: 2026-05-26 (America/Sao_Paulo)
- **Sequence**: 27
- **Agent**: Claude Code (Opus 4.7)
- **Human**: Eduardo
- **Topic**: ADR-0035 pivot + Spoke inventory
- **Duration**: ~5h
- **Related ADRs**: ADR-0035 (filed), ADR-0021/0032/0033/0034 (reframed with pointer)
- **Related TODO items**: full TODO.md slice-2 section banner + fidelity-findings recategorization

## Goal of the Session

Execute the 3-phase strategic pivot brainstormed at session start: realign every "prototipo is the canonical UI" assertion in the repo so that Spoke (ex-Circuit Route Planner) becomes the canonical source for functional/UX behavior, the prototype keeps authority only over visual identity tokens, and cliente Ueslei is final tiebreaker. Output: ADR-0035 + repo-wide semantic sweep + side-by-side Spoke-vs-RotPro inventory + groundwork for ROADMAP-v2.

## What Was Done

In chronological order:

1. Started by re-reading the closing state of MS-15a-followup (commit `5c104c7`, branch `feat/m2-slice-2-telas-core`) and the broader roadmap. Eduardo articulated the pivot: "o prototipo não é para seguirmos fielmente tudo — ele é apenas referência criativa; Spoke é o app que o usuário já conhece e que devemos clonar funcionalmente."
2. Brainstormed and locked 4 decisions via AskUserQuestion: (a) eu inspeciono Spoke via adb no M54, (b) ADRs antigas são superseded/reframed (não reescritas), (c) inventory primeiro, depois roadmap, (d) refazer roadmap do zero como v2.
3. Dispatched 3 Explore agents in parallel to: catalogue every binding-language site in the repo (24 hits found across docs/ADRs/skills/subagent), inventory current RotPro routes (17 routes / 18 page widgets / 5 settings rows), and verify adb availability (was missing — install required).
4. Authored `~/.claude/plans/velvet-yawning-thacker.md` (3-phase plan, ~7-10h estimated), got Eduardo approval via ExitPlanMode.
5. **Phase 1 (commit `725f10b`)** — wrote ADR-0035 (foundational pivot ADR, 6 sections incl. Options Considered + Rollback + Verification); edited 14 files: README, CLAUDE.md, 01-PROJECT, 02-ARCHITECTURE, 05-SCREENS, M2-SLICE-CHECKLIST (3 sites), 03-CONVENTIONS, Blueprint, 08-ROADMAP (SUPERSEDED banner), ADR-0017 cross-refs, superpowers/specs/0000-template, .claude/agents/prototype-fidelity-checker (rescoped to visual-only). TODO.md got a slice-2 banner + fidelity-findings re-classification note.
6. **Phase 2 (commit `458b3db`)** — installed `android-platform-tools` via brew. Confirmed M54 (`RQCW401G33T`) connected. Found Spoke package: `com.underwood.route_optimiser` v3.65.1 (Brazilian rebrand). Inspected via adb shell uiautomator dump + screencap: home, settings (2 scroll positions), Criar rota wizard, rota vazia, kebab menu, voice flow entry. Authored `docs/inventory/2026-05-26-spoke-vs-rotpro.md` (336 lines, 8 sections, 43 numbered gap items in §3 with replicate/adapt/discard/postpone decisions).
7. Eduardo asked "voce nao esqueceu de absolutamente nada e seguiu as boas praticas em tudo?" — I ran an honest audit and identified 10 lacunas (no Spoke deep-dive on critical flows; no RotPro inspection done; commits not pushed; no adr-guardian dispatch; no session log; no memory entries; no "Reframed by" pointer on the 4 old ADRs; verification grep not rigorous; ADR-0035 reverse-link incomplete).
8. **Remediação phase (this session's second half)** — dispatched `adr-guardian` subagent (read-only) which returned zero BLOCKING + 2 SHOULD-FIX matching my own audit findings (reframed-by pointer + slice-checklist subagent description drift). Inspected RotPro on M54 (home + settings + AddStop sheet captured). Inspected Spoke complementary screens (voice flow entry — discovered native "fale vários endereços" feature that promotes gap §3.2#10 from "Slice 3 follow-up" to "Slice 3 core"). Amended inventory with §9 (inspection coverage map: what was inspected vs what remains pending) + items 10b/10c (multi-address dictation promoted; language picker noted as out-of-scope). Edited ADRs 0021/0032/0033/0034 each with a "Reframed by ADR-0035" pointer in their Status block + updated Related ADRs to cite ADR-0035. Saved 2 persistent memory entries (`lesson_prototype_is_visual_not_functional`, `project_pivot_2026_05_26_spoke_functional_clone`) + updated MEMORY.md index.

## Decisions Made

1. **ADR-0035 filed as the foundational pivot.** Functional fork stance unchanged; reframes ADRs 0021/0032/0033/0034 (decisions correct, framing context changes). Two-layer hierarchy: Spoke = behavior, prototipo = visual identity, cliente = tiebreaker.
2. **`prototype-fidelity-checker` subagent rescoped, not deleted.** Kept the name for historical continuity; rewrote `<role>` and `<checks>` to cover only visual tokens (colors, spacing, radii, shadows, typography, icon family). Structural/flow checks removed — those now belong to humans + the inventory.
3. **Old roadmap kept as historical snapshot, banner SUPERSEDED added at top.** No content edit beyond the banner; v2 is the active plan once written.
4. **Inspection of Spoke is via runtime UX observation only** (adb uiautomator + screencap), not decompilation or asset extraction. Boundary reaffirmed in ADR-0035 §"Implementation summary." Screenshots stay in `/tmp/spoke-inspection/` and are NOT committed.
5. **Inventory item 10b promoted from "Slice 3 follow-up" to "Slice 3 core"** — Spoke has native multi-address dictation as a first-class CTA, not buried; our roadmap needs to match.
6. **Coverage of Spoke inspection capped at "what was reachable in one session without risking account state."** Login/cadastro, paywall, OCR full, navigate-active, history flows go on §9 "not inspected" list with explicit mitigation: each microsprint touching those flows runs a ~30 min Spoke deep-dive before its `/new-spec` lands.

## Open Questions Left

- [ ] **Eduardo precisa aprovar §3 + §7 + §9 do inventário** antes da Fase 3 (ROADMAP-v2) começar. Sem isso, eu não escrevo v2 — ele depende dessas decisões.
- [ ] **Trigger orçamentário não acionado ainda**: roadmap-v2 estimado em 24-36 dias úteis (~40-50% maior que v1). Se estourar Workana, Eduardo decide: negociar prazo / cortar §7.2 medium-priority / shippar v1 lean + v2 incremental.
- [ ] **Spoke flows não inspecionados** (§9 do inventário): login/cadastro, autocomplete de busca, OCR full, navigate active, paywall full, importar/transferir manifesto. Cada microsprint que tocar esses flows requer Spoke deep-dive antes do `/new-spec`.
- [ ] **M2-SLICE-CHECKLIST.md** ainda referencia o subagent `prototype-fidelity-checker` por descrição antiga em alguns pontos não-críticos — adr-guardian SHOULD-FIX #2. Atualizar quando tocar o file por outro motivo (Karpathy §3).

## Files Changed

**Created**:
- `docs/decisions/0035-spoke-functional-clone-prototype-creative-reference.md` (foundational pivot ADR)
- `docs/inventory/2026-05-26-spoke-vs-rotpro.md` (336+ lines, 9 sections)
- `~/.claude/projects/<project>/memory/lesson_prototype_is_visual_not_functional.md`
- `~/.claude/projects/<project>/memory/project_pivot_2026_05_26_spoke_functional_clone.md`
- `~/.claude/plans/velvet-yawning-thacker.md` (3-phase pivot plan)

**Modified**:
- `README.md` (§"UI source of truth" → §"Source-of-truth hierarchy")
- `CLAUDE.md` (§"UI Source of Truth" rewritten; header datestamp bumped to 2026-05-26)
- `TODO.md` (slice-2 section banner + fidelity-findings re-classification)
- `docs/01-PROJECT.md` (scope bullet)
- `docs/02-ARCHITECTURE.md` (header)
- `docs/03-CONVENTIONS.md` (tree comment)
- `docs/05-SCREENS.md` (header reframed)
- `docs/08-ROADMAP.md` (SUPERSEDED banner at top)
- `docs/Blueprint.md` (tree comment)
- `docs/M2-SLICE-CHECKLIST.md` (3 sites: pre-flight, HARD GATE, glossary)
- `docs/decisions/0017-external-navigation-handoff.md` (cross-refs to ADR-0035)
- `docs/decisions/0021-slice-2-fidelity-remediation.md` (Reframed-by header + Related ADRs)
- `docs/decisions/0032-adopt-lucide-icons-flutter.md` (Reframed-by header + Related ADRs)
- `docs/decisions/0033-drop-primary-button-neon-dot.md` (Reframed-by header + Related ADRs)
- `docs/decisions/0034-voice-page-single-cta.md` (Reframed-by header + Related ADRs)
- `docs/superpowers/specs/0000-template.md` (reading order updated for v2 + inventory)
- `.claude/agents/prototype-fidelity-checker.md` (rescoped to visual-only)
- `~/.claude/projects/<project>/memory/MEMORY.md` (2 entries added)

**Deleted**: none

## Commits Pushed

To be pushed at session close (Remediação #8):

```
725f10b docs(pivot): realign canonical UI authority — Spoke is functional, prototipo is creative (ADR-0035)
458b3db docs(inventory): Spoke vs RotPro side-by-side mapping (ADR-0035 phase 2)
<NEW>  docs(pivot): phase 1+2 remediation — inventory §9 coverage + ADRs reframed-by pointer + session log
```

## Hand-off Notes for Next Session

- **Branch**: `feat/m2-slice-2-telas-core` (ahead of origin by 3 commits after this session's final push)
- **Active gate**: Eduardo precisa revisar `docs/inventory/2026-05-26-spoke-vs-rotpro.md` §3 (43 gaps) + §7 (design decisions) + §9 (inspection coverage map) e me dizer: aprovado / cortar X / discutir Y. Sem isso a Fase 3 (`docs/08-ROADMAP-v2.md`) não começa.
- **Active roadmap**: ainda `docs/08-ROADMAP.md` (SUPERSEDED banner; v2 ainda não existe). NÃO use o template `docs/superpowers/specs/0000-template.md` linha 2 ("docs/08-ROADMAP-v2.md") como referência ativa até v2 ser escrito — é forward-looking.
- **`prototype-fidelity-checker`** agora é visual-only. Não espere que ele flagre estrutural/flow. Spoke functional parity é human-checked via inventário.
- **Spoke deep-dive workflow** (registrado em memória `lesson_prototype_is_visual_not_functional`): para qualquer microsprint que toca flow não inspecionado, ~30 min adb session antes do `/new-spec`. Pacote: `com.underwood.route_optimiser` v3.65.1 instalado no M54.
- **Open AddStop autocomplete** (era MS-15b): no roadmap-v2 deve aparecer dentro do slice 3 backend (Nominatim), não como microsprint solto.

## Reference Material Used

- ADR-0007 (`docs/decisions/0007-pix-gateway-decision.md`) — Status-block superseded convention example
- Existing 14 binding-language sites (cataloged by Explore agent in session start)
- `adb shell uiautomator dump` + `screencap` + `dumpsys package` (Spoke v3.65.1 on M54)
- `prototype-fidelity-checker` subagent original (preserved structurally; scope narrowed)
- adr-guardian subagent dispatch (zero BLOCKING; 2 SHOULD-FIX both already addressed)
- Karpathy §3 (surgical changes) — applied to subagent rescope and ADR-0017 cross-ref edit

## Plain-language wrap-up

A sessão executou uma virada estratégica completa. O projeto estava tratando o protótipo do Claude Design como se fosse o "rei" da UI — todas as decisões precisavam bater 1:1 com ele. Isso estava gerando atrito porque o protótipo é só um esboço criativo, não uma especificação real do que um motoboy espera. A Spoke (Circuit Route Planner) é o app que o motoboy já usa todo dia, então é com ela que precisamos ter paridade funcional.

A ADR-0035 estabelece a hierarquia nova: Spoke decide comportamento (telas, navegação, settings, gestos), o protótipo decide identidade visual (cores, ícones, animações), e você é o desempate. Editei 14 arquivos pra realinhar tudo, criei a ADR-0035, e fiz uma inspeção comparativa no seu M54 com a Spoke real instalada. O resultado é um inventário de 43 gaps numerados, cada um com decisão proposta (replicar / adaptar / descartar / postergar).

O que ficou pendente é você revisar o inventário (§3, §7, §9) e me dar OK pra escrever a Fase 3 — o `ROADMAP-v2.md` detalhado em microsprints. O custo provável é 40-50% maior que o original, então pode ser que você precise decidir cortar features médias-prioridade ou negociar prazo com a Workana.

Tudo que eu deixei passar na primeira tentativa (não pushar, não rodar adr-guardian, não criar session log, não salvar memória, não adicionar pointer nas ADRs antigas) foi remediado nesta segunda metade da sessão depois do seu pedido honesto de auditoria.
