# Session Log Index (reset 2026-05-26)

Pre-cleanup logs (sessions 1-28, M1 + slice-2 pre-pivot + pivot ADR-0035 + MS-A1 reset attempt) foram arquivados em [`docs/archive/sessions-pre-cleanup-2026-05-26/`](../archive/sessions-pre-cleanup-2026-05-26/) durante o reset M2 que limpou ~150 arquivos de slice-2 + 12 ADRs microsprint-específicas + 10 specs/plans.

A partir daqui, sessions são opcionais — só vale criar uma quando o trabalho da sessão é não-óbvio do git log (decisão arquitetural relevante, débito técnico aceito, lição aprendida que outras sessões podem repetir). Commits bem-escritos cobrem a maior parte do "o que aconteceu". A regra anterior de "session log por commit" foi descartada per `~/.claude/plans/velvet-yawning-thacker.md` §"Princípio orientador pós-reset".

## How to Read This Index

- Most recent at the top.
- Format: `YYYY-MM-DD-NN — <topic>` followed by a one-line summary.
- For full context on any session, open the linked file.

## Sessions

- [2026-05-27-01-slice-2-area-2-wizard.md](./2026-05-27-01-slice-2-area-2-wizard.md) — Wizard Criar Rota (Área 2)
- [2026-05-27-02-slice-2-area-2-wizard-ui.md](./2026-05-27-02-slice-2-area-2-wizard-ui.md) — Wizard UI Polish and Harness Best Practices
- [2026-05-28-01-slice-2-area-25-3-map.md](./2026-05-28-01-slice-2-area-25-3-map.md) — Área 2.5/3 (Reutilizar Paradas/Mapa) e Route import pattern
- [2026-05-28-02-google-maps-migration-and-mcp.md](./2026-05-28-02-google-maps-migration-and-mcp.md) — Google Maps Migration & MCP Usage
- [2026-05-28-03-ui-polish-and-remember-me.md](./2026-05-28-03-ui-polish-and-remember-me.md) — UI Polish & Remember Me
- [2026-05-28-04-area4-add-stop-ms1.md](./2026-05-28-04-area4-add-stop-ms1.md) — Area 4 add-stop TEXT: discovery + spec + plan + MS1 Domain layer (sealed AddStopUiState + factory)
- [2026-05-29-01-area4-add-stop-ms2-ms3-ms4.md](./2026-05-29-01-area4-add-stop-ms2-ms3-ms4.md) — Area 4 add-stop TEXT: MS2 (State) + MS3 (Widgets) + MS4 (Device validation) + audit pós-implementação + D4 spoke-parity-checker retroativo (3 must-fix + 2 should-fix descobertos)
