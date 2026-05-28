# Session Log

## Metadata

- **Date**: 2026-05-27 (America/Sao_Paulo)
- **Sequence**: 02
- **Agent**: Google Antigravity
- **Human**: Eduardo
- **Topic**: Wizard UI Polish and Harness Best Practices
- **Duration**: ~2h
- **Related ADRs**: none
- **Related TODO items**: none

## Goal of the Session

Finalize the Route Wizard (Área 2) UI to match the Spoke prototype perfectly, fix the authentication offline persistence issue, and document harness anti-patterns committed during this session to prevent recurrence.

## What Was Done

- Analyzed and updated the TokenStorage and AuthController logic to correctly handle offline login by falling back to cached user data instead of forcefully logging out the user when the backend is unreachable.
- Polished the Wizard Route Creation UI: added borders to date options, changed icons, improved checkboxes size and squared them, and implemented a tooltip for quick start options.
- Adjusted text copies to be distinct from Spoke while keeping the exact same meaning ("Selecione a data" -> "Data de partida", "Hoje" -> "Ainda hoje", etc).
- Corrected critical Harness violations regarding tool usage.

## Decisions Made

1. **Offline fallback on startup:** Fallback to cached user data when the backend fails during the `auth/me` check on startup. This prevents the user from being logged out randomly when offline or when the server is temporarily down.
2. **Distinct UI Texts:** Decided to not perfectly copy Spoke's texts in the Wizard, but rather adapt them to fit the Roteirizador Pro identity, while maintaining Spoke's layout architecture.

## Harness Mistakes & Learned Patterns

During this session, several Anti-Patterns were observed and corrected. Future agents MUST strictly avoid these:
1. **Never use `cat` inside `run_command` to view files.** Use the `view_file` tool instead.
2. **Never use `cat` or `echo` inside `run_command` to create or append to files.** Use `write_to_file` or `replace_file_content`.
3. **Never use `ls` or `grep` inside `run_command` for exploration.** Use `list_dir` or `grep_search` instead.
4. **Never run `sed` inside `run_command` to modify code.** Use `replace_file_content` or `multi_replace_file_content`.
*These rules are non-negotiable for Google Antigravity.*

## Open Questions Left

- [ ] Move to Área 2.5 - Integração do mapa / Search UI.

## Files Changed

**Modified**:
- `apps/mobile/lib/features/auth/data/token_storage.dart`
- `apps/mobile/lib/features/auth/state/auth_controller.dart`
- `apps/mobile/lib/features/routes/presentation/wizard_route_page.dart`

## Commits Pushed

```
84d4fb9 style(mobile): refine wizard date picker UI to match Spoke/Prototipo
060c163 style(mobile): improve quick start UI and enlarge checkboxes
4f898ab style(mobile): differentiate texts from Spoke and use square checkboxes
```

## Hand-off Notes for Next Session

The Route Wizard UI (Área 2) is polished and completed. The Auth fallback logic is also working. The branch `feat/m2-slice-2-area-2-drawer` is still active. The next session can either merge this or move to Área 2.5 (Integração do mapa e adicionar parada) on the same branch.
