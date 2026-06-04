# Session Log Index (reset 2026-05-26)

Pre-cleanup logs (sessions 1-28, M1 + slice-2 pre-pivot + pivot ADR-0035 + MS-A1 reset attempt) foram arquivados em [`docs/archive/sessions-pre-cleanup-2026-05-26/`](../archive/sessions-pre-cleanup-2026-05-26/) durante o reset M2 que limpou ~150 arquivos de slice-2 + 12 ADRs microsprint-específicas + 10 specs/plans.

A partir daqui, sessions são opcionais — só vale criar uma quando o trabalho da sessão é não-óbvio do git log (decisão arquitetural relevante, débito técnico aceito, lição aprendida que outras sessões podem repetir). Commits bem-escritos cobrem a maior parte do "o que aconteceu". A regra anterior de "session log por commit" foi descartada per `~/.claude/plans/velvet-yawning-thacker.md` §"Princípio orientador pós-reset".

## How to Read This Index

- Most recent at the top.
- Format: `YYYY-MM-DD-NN — <topic>` followed by a one-line summary.
- For full context on any session, open the linked file.

## Sessions

- [2026-06-03-01-area5-ms1-ms4-numpad-pivot.md](./2026-06-03-01-area5-ms1-ms4-numpad-pivot.md) — Area 5 MS1-MS4: wheel_picker → numpad pivot (ADR-0042 supersedes ADR-0041) + reusable `area5-microsprint.js` workflow template + Spoke parity label collapse fix
- [2026-06-03-02-area5-ms5-destino-sheet.md](./2026-06-03-02-area5-ms5-destino-sheet.md) — Area 5 MS5: Destino bottom-sheet sub-picker + domínio 3-estados (ADR-0043, `BackToStart`→`NoDestination`); recurring mislabeled-baseline failure mode caught at Phase 1; workflow halt on my scope-error (app.dart omitido) → manual fix + 2 reviewers ✅; 240 testes
- [2026-06-04-01-area5-msfix-audit-remediation.md](./2026-06-04-01-area5-msfix-audit-remediation.md) — Area 5 MS-FIX: auditoria retrospectiva read-only (6 dimensões, 37 agentes, 30→21 achados) + remediação de 14 itens (M1 títulos time-picker, S2 Concluído sempre habilitado, S1 relógio ao vivo, S3 hints originais, S4 Pausa stub + 8 nits); process directive "live-inspect per feature" travada; 2 reviewers ✅ (1 must-fix auto-infligido na tabela ADR corrigido); 249 testes
- [2026-05-27-01-slice-2-area-2-wizard.md](./2026-05-27-01-slice-2-area-2-wizard.md) — Wizard Criar Rota (Área 2)
- [2026-05-27-02-slice-2-area-2-wizard-ui.md](./2026-05-27-02-slice-2-area-2-wizard-ui.md) — Wizard UI Polish and Harness Best Practices
- [2026-05-28-01-slice-2-area-25-3-map.md](./2026-05-28-01-slice-2-area-25-3-map.md) — Área 2.5/3 (Reutilizar Paradas/Mapa) e Route import pattern
- [2026-05-28-02-google-maps-migration-and-mcp.md](./2026-05-28-02-google-maps-migration-and-mcp.md) — Google Maps Migration & MCP Usage
- [2026-05-28-03-ui-polish-and-remember-me.md](./2026-05-28-03-ui-polish-and-remember-me.md) — UI Polish & Remember Me
- [2026-05-28-04-area4-add-stop-ms1.md](./2026-05-28-04-area4-add-stop-ms1.md) — Area 4 add-stop TEXT: discovery + spec + plan + MS1 Domain layer (sealed AddStopUiState + factory)
- [2026-05-29-01-area4-add-stop-ms2-ms3-ms4.md](./2026-05-29-01-area4-add-stop-ms2-ms3-ms4.md) — Area 4 add-stop TEXT: MS2 (State) + MS3 (Widgets) + MS4 (Device validation) + audit pós-implementação + D4 spoke-parity-checker retroativo (3 must-fix + 2 should-fix descobertos)
- [2026-05-29-02-area4-add-stop-ms5.md](./2026-05-29-02-area4-add-stop-ms5.md) — Area 4 add-stop TEXT: MS5 D4 fixes (Section B icon-free, Footer text-only, Section A pencil trailing, X=limpar input) — 7 commits + 4 reviewer fix loops
