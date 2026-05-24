# Session 22d — M2-AI Phase 5: `mcp_flutter` REJECTED for M2

## Metadata

- **Date**: 2026-05-24
- **Sequence**: 22d
- **Agent**: Claude Code (Opus 4.7)
- **Human**: Eduardo
- **Topic**: Phase 5 — decision gate on `mcp_flutter` visual snapshot plugin
- **Duration**: ~15m
- **Related ADRs**: ADR-0028 (new — rejection), ADR-0021 (closes criterion 2 gap), ADR-0022 (integration_test gate), ADR-0023 (official Dart MCP, unaffected)

## Goal

Apply Sub-fase 5.0 four-criterion decision gate honestly with evidence. Adopt OR reject — both produce ADR-0028.

## Evidence collected

- `WebFetch` on `Arenukvern/mcp_flutter`: v3.0.7 (2026-05-20), 847 commits, Claude Code officially supported, debug-only by design (zero release risk).
- Slice 2 history review: session 13 shipped 7 screens in ~22 commits (~3 iterations/screen); MS-01b had 3 PopScope attempts. Real pattern: 3–5 visual iterations/screen, not 10+.
- ADR-0021 review: `prototype-fidelity-checker` (static) passed clean on a screen with 4 Criticals that device-E2E caught. Gap is real and documented.
- ADR-0021's remediation: device-E2E + per-step screenshot + integration_test (ADR-0022) added as hard gates in `M2-SLICE-CHECKLIST.md`.

## Decision

**REJECT for M2 cycle.** Criterion 2 alone would justify adoption, but ADR-0021 + ADR-0022 already close the gap with hard gates. Adopting now duplicates the visual-fidelity gate without evidence the manual one fails.

Re-evaluation trigger documented in ADR-0028: iterations > 7/screen OR 2 consecutive device-E2E gates surface > 2 Criticals each that the static checker cleared.

## Bonus calibration

ADR-0028 was written under a new "enxuto" pattern at Eduardo's direction: ~60 lines vs ~190 in ADRs 0024–0027. Cut: long Options-Considered prose (replaced by a 4-row evidence table), repeated rationale across sections, expansive References. Kept: frontmatter, Context (2 sentences), Decision (1 sentence + table), Consequences (3 bullets), Rollback (1 sentence), Re-evaluation trigger (2 bullets), References (5 lines). Phases 6 + 7 ADRs will follow the same shape.

## Files changed

**Created**:
- `docs/decisions/0028-mcp-flutter-rejected-for-now.md`
- `docs/sessions/2026-05-24-22d-phase-5-mcp-flutter-rejected.md` (this file)

**Modified**:
- `CLAUDE.md` — "Last updated" footer.
- `SPRINT-M2-AI-HARNESS.md` — phase table row 5 + Fase 5 status block + "Próxima sessão deve" pointing at Fase 6.
- `TODO.md` — Phase 5 checkbox done.
- `docs/sessions/0001-INDEX.md` — new entry at top.

## What did NOT happen, and why

- No `apps/mobile/pubspec.yaml` edit, no `main.dart` change, no `.mcp.json` addition. Rejection = no install, no code touched.
- No subagent dispatch needed — decision gate, not a smoke test.
- adr-guardian sweep run before commit (next step).

## Practical impact (plain language)

Decidi **não adotar** o mcp_flutter agora. O plugin é bom, ativo e seguro (só roda em modo debug). Mas o problema que ele resolveria — "checker estático passou e o device tinha 4 bugs visuais" — já foi resolvido em maio quando criamos o gate de teste no aparelho real com screenshot por passo (ADR-0021) e o gate de integration_test (ADR-0022). Adotar agora seria dois cintos de segurança fazendo a mesma coisa.

A decisão tem **gatilho de reabertura escrito**: se na slice 3 a gente começar a precisar de mais de 7 iterações visuais por tela, OU se em dois fechamentos seguidos o teste no aparelho real revelar bugs visuais que o checker estático não pegou, abrimos um ADR novo e instalamos. Não é "talvez algum dia" — é uma régua medível.

**Custo da decisão:** zero. Sem instalação, sem código novo, sem dependência nova.
