# Spec — Area 5 (Slice 2): Detalhes da rota Spoke-aligned

> **Date:** 2026-06-02
> **Author:** Claude Code (with Eduardo)
> **Status:** Approved 2026-06-02
> **Branch:** `feat/m2-slice-2-area-5-route-details` (off `develop` at `b4d2d0a`)
> **Source of truth:** `docs/08-ROADMAP-v2.md` "Área 5" + `docs/inventory/2026-05-26-spoke-vs-rotpro.md` §11.4. ROADMAP wins on disagreement.
> **Spoke baseline captured:** 21 artefatos `/tmp/spoke-a5-*` (XML + PNG; ADR-0037 path = Bash + uiautomator dump fallback).

---

## Context

Slice 2 Area 4 (Add Stop via TEXT) shipped via PR #24 (squash merge 2026-06-01). Area 3 (tela ativa de rota com mapa + sheet) já tem 3 rows de "Configuração de rota" no shell sheet, mas elas são apenas decorativas (sem onTap). Esta Area 5 implementa:

1. A tela "Detalhes da rota" full-screen Spoke-aligned com 3 sections (Partida, Destino, Pausas).
2. 5 sub-pickers acessíveis dessa tela (Partida-Local, Início-Horário, Destino, Término-Horário, Pausa).
3. O wire das 3 rows do Area 3 sheet (boundary tocando Area 3, mas escopo Area 5).
4. Persistência de defaults com `SharedPreferencesAsync` (forward-compat Slice 3).
5. FTUE trigger — abre "Detalhes da rota" automaticamente ao concluir primeira rota.

**Não implementa nesta Area:** otimização real (Slice 3 solver), "Sentido casa" (Slice 5), tela de edição de parada inline (Area 6 BIG FIND §11.4 — reverte `context.pop()` futuro).

**Validação empírica:** Spoke inspecionado ao vivo no Samsung M54 em 2026-06-01 (sessão de validação pre-approval). 5 sub-pickers + FTUE behavior confirmados antes desta spec.

## Decisions locked

| # | Question | Decision | Rationale |
|---|---|---|---|
| Q1 | FTUE — abrir Detalhes da rota automático após primeira rota concluída? | **A — Implementar** | Spoke faz exatamente isso (validado §13.C.2). Aceitação rider: 1 toque a mais na 1ª rota da vida do usuário, 0 toques nas subsequentes. |
| Q2 | Re-entrada via 3 rows do Area 3 sheet? | **A — Tornar clickable** | Spoke usa essas mesmas rows como gatilho secundário. Boundary tocando Area 3 (3 linhas de código por row). |
| Q3 | Time picker — custom scroll wheel ou Material 3 nativo? | **B — Custom scroll wheel via `wheel_picker ^0.3.0`** | Paridade Spoke (drum picker vertical). Material 3 dial picker afasta visual+UX. Package validado em Context7 (pub.dev `/jaweii/flutter_wheel_picker`, queried 2026-06-01). |
| Q4 | Persistência defaults | **A — `SharedPreferencesAsync` com JSON envelope `schemaVersion: 1`** | Mesmo padrão Area 3 (remember-me) e Area 4 (search history). Schema forward-compat com Slice 3 backend RouteDefaults table. |
| Q5 | Wire 3 rows Area 3 — agora ou polish depois? | **A — Agora (MS7)** | ~3 linhas por row, custo zero. Postergar = risco de esquecer + Eduardo vê app "quebrado" durante demo. |
| Q6 | Sub-picker Partida — reusar `AddStopPage` ou nova rota? | **A — Reusar com `PickerMode` enum** | Spoke literalmente faz isso (mesma tela de search). Economia ~3h. |
| Q7 | Pausa — chips de duração hardcoded? | **A — 15/30/60min + "Personalizar..."** | Paridade Spoke. Personalizar abre numeric picker mesmo wheel_picker. |
| Q8 | Checkbox "Salvar como padrão" — checked default? | **A — Replicar 1:1 (true)** | Spoke marca checked por default. Muscle memory rider. |
| Q9 | Back gesture de Detalhes da rota? | **A — GoRouter padrão (sem lógica custom)** | Spoke usa back nativo Android = pop route. Custom orchestration = risco. |
| Q10 | Validação "Concluído" — apenas tempo coerente? | **C — Validar só `endTime > startTime`** | Validações de capacidade temporal (drive time vs paradas) deferidas pro Slice 3 solver (não é responsabilidade do client). |

## Goals (acceptance — testável M54)

Um install do APK `v1.1.0-area5` pode, contra produção:

1. Concluir wizard "Criar Rota" pela primeira vez → tela "Detalhes da rota" abre automaticamente (FTUE).
2. Tap em qualquer row "Configuração de rota" do Area 3 sheet (Partida/Início/Destino) → mesma tela "Detalhes da rota" abre.
3. Topbar "Detalhes da rota" tem botão "X" (esquerda) que pop pra Area 3, e botão "Concluído" (direita) habilitado quando time é coerente.
4. Section "Partida": 2 rows — "Local de início" (atualmente: `Usar local atual`) + "Início" (atualmente: `08:00`). Tap em "Local de início" → AddStopPage em PickerMode.startLocation; tap em "Início" → time picker sheet.
5. Section "Destino": 1 row "Destino" (atualmente: `Voltar ao local de início`). Tap → sub-tela de 3 radio options (Voltar ao local de início / Selecionar endereço / Ida e volta).
6. Section "Pausas": 0..N rows + CTA "+ Adicionar pausa". CTA abre sub-tela "Configure a pausa" com 2 chip groups (horário + duração).
7. Checkbox "Salvar como padrão para próximas rotas" (default: marcado) abaixo de cada section.
8. Tap "Concluído" → persiste config no estado da rota ativa + (se checkbox marcado) atualiza `RouteDefaults` no SharedPrefs → pop pra Area 3 → 3 rows do sheet refletem novos valores.
9. Criar 2ª rota → wizard pula Detalhes (rota usa defaults persistidos); abrir Detalhes via row do sheet → valores defaults pré-preenchidos.
10. Time picker "Início" mostra scroll wheel HH:MM (24h) + chips :00/:30 abaixo (paridade Spoke).
11. Time picker "Término" idêntico ao "Início" (mesmo widget reused).
12. Sub-tela "Destino" tem 3 RadioListTile + AppBar com X + "Confirmar"; "Selecionar endereço" abre AddStopPage em PickerMode.endLocation.
13. Sub-tela "Adicionar pausa" tem 2 ChoiceChip Wrap (horário: 11:00/12:00/13:00 + Personalizar; duração: 15/30/60min + Personalizar) + Confirmar.
14. Back gesture Android (3-finger swipe ou botão back) em qualquer sub-picker pop pra "Detalhes da rota"; back em "Detalhes da rota" pop pra Area 3.

### Non-goals

- Backend solver respeitando time windows / break windows (Slice 3).
- "Sentido casa" toggle ou home address (Slice 5).
- FTUE modal "primeira rota" tipo onboarding overlay (não tem no Spoke — só abre a tela).
- Edição de parada inline (Area 6 BIG FIND §11.4 — reverte `context.pop()` no futuro).
- Multi-route defaults (este app é single active route).
- Capacidade de pausa custom-duration < 5min ou > 4h (Spoke não tem; defer).
- Animation transitions custom (paridade Spoke usa `MaterialPageRoute` padrão).

## Architecture

### Mobile feature module (`apps/mobile/lib/features/route_config/`)

```
apps/mobile/lib/features/route_config/
├── domain/
│   ├── route_config.dart                  // sealed (StartLocation, TimeStart, TimeEnd, Destination, BreakConfig)
│   └── route_defaults.dart                // SharedPrefs envelope class
├── data/
│   └── route_defaults_repository.dart     // SharedPreferencesAsync read/write
├── state/
│   ├── route_config_controller.dart       // @riverpod active route's config
│   ├── route_defaults_controller.dart     // @riverpod defaults from SharedPrefs
│   └── picker_mode.dart                   // enum { startLocation, endLocation }
├── presentation/
│   ├── pages/
│   │   ├── route_details_page.dart        // shell full-screen
│   │   ├── destination_picker_page.dart   // 3 radio options
│   │   └── break_picker_page.dart         // chips horário + duração
│   └── widgets/
│       ├── route_details_section.dart     // section card with title + rows + checkbox
│       ├── route_config_row.dart          // ListTile-equivalent label + trailing value
│       ├── time_picker_sheet.dart         // wheel_picker drum + chips
│       └── break_chip_groups.dart         // 2 ChoiceChip Wraps
```

Tests mirror under `apps/mobile/test/features/route_config/`.

### Other touch points

- **`apps/mobile/lib/features/routes/presentation/pages/add_stop_page.dart`** — extend with optional `PickerMode? mode` constructor parameter. When non-null, alters AppBar title + button labels but reuses entire search/typeahead pipeline.
- **`apps/mobile/lib/features/routes/presentation/widgets/route_sheet.dart`** (Area 3) — wire 3 rows of "Configuração de rota" `onTap: () => context.push('/home/routes/active/details')`.
- **`apps/mobile/lib/app_router.dart`** — 6 new GoRoutes:
  - `/home/routes/active/details` (shell)
  - `/home/routes/active/details/start-location` → `AddStopPage(mode: startLocation)`
  - `/home/routes/active/details/time-start` (modal sheet)
  - `/home/routes/active/details/time-end` (modal sheet)
  - `/home/routes/active/details/destination`
  - `/home/routes/active/details/break/:breakIndex?` (`?` = nullable for add-new)
- **`apps/mobile/lib/features/routes/state/route_creation_controller.dart`** (Area 2 wizard) — after wizard `complete()`, check `routeDefaultsControllerProvider.firstRoute` flag → if true, route to `/home/routes/active/details`.

### Architecture principles

1. **Sealed `RouteConfig` family** — exhaustive switch over 5 sub-states; compiler enforces handling new types if added.
2. **`RouteDefaults` is a plain immutable class** (not sealed) — single envelope serialized to one SharedPrefs key `route_defaults_v1`.
3. **`PickerMode` enum + nullable constructor param** — extends existing `AddStopPage` without forking. Behavior changes at AppBar level only.
4. **Riverpod 3 codegen** for every controller. `family + autoDispose` on per-route config to prevent state leak when switching routes.
5. **No premature backend coupling** — `RouteDefaults` serialization uses field names identical to future TypeBox schema (Slice 3), but no API call yet.

## Data flow

### Time-coherent validation flow

User changes Início or Término → `routeConfigControllerProvider.notifier.update*()` → state has new `startTime`/`endTime` → derived provider `isRouteConfigValidProvider` recomputes (`endTime > startTime`) → "Concluído" button `onPressed` set to `null` if invalid (Material 3 disabled state) else dispatches save.

### Save flow

User taps "Concluído" → if `salvarComoPadrao` checkbox marcado per-section → for each true section, build partial `RouteDefaults` patch → `routeDefaultsControllerProvider.notifier.merge(patch)` → write JSON to SharedPrefs under key `route_defaults_v1` → close screen via `context.pop()`.

### FTUE flow

Wizard "Criar rota" completes → `routeCreationControllerProvider.complete()` → reads `routeDefaultsControllerProvider.firstRoute` → if `true` (defaults SharedPrefs envelope absent), pushes `/home/routes/active/details` after route creation, sets flag `firstRoute=false` on first save → subsequent routes skip this push.

### `AddStopPage` reuse flow

`AddStopPage(mode: PickerMode.startLocation)` → AppBar title = "Local de início", action button = "Selecionar"; search pipeline identical (existing Area 4 typeahead). On selection → `Navigator.pop(context, GeocodedAddress(...))` returns to caller (Detalhes da rota), which calls `routeConfigControllerProvider.notifier.setStartLocation(...)`.

## Sub-microsprint plan

Each MS dispatches `spoke-parity-checker` D-mid against `/tmp/spoke-a5/<MS>.png` baseline.

| MS | Scope | Est | Spoke gate |
|---|---|---|---|
| Pre-flight | Branch + reread spec/inventory §11.4 | 30min | None |
| **MS1** | Domain (`RouteConfig` sealed + `RouteDefaults`) + Riverpod controllers + tests | 4h | None (zero UI) |
| **MS2** | Shell tela `RouteDetailsPage` (topbar + 3 sections + 5 rows + checkboxes + Concluído) | 6h | Screenshot side-by-side `shell.png` |
| **MS3** | `PickerMode` enum + extend `AddStopPage` (Partida + Destino-select) | 4h | Toolbar OCR side-by-side `partida.png` |
| **MS4** | `TimePickerSheet` (wheel_picker + chips :00/:30) — 2 sub-pickers (Início + Término) | 6h | Drum picker feel + chips `iniciar-time.png` |
| **MS5** | `DestinationPickerPage` (3 RadioListTile + Confirmar) | 4h | Strings + radio order `destino.png` |
| **MS6** | `BreakPickerPage` (2 ChoiceChip Wraps + Confirmar) | 5h | Chips horário + duração `pause.png` |
| **MS7** | Wire Area 3 sheet rows → clickable + show config values | 3h | Row clickable feel |
| **MS8** | `SharedPreferencesAsync` persistência + FTUE trigger wire | 4h | FTUE behavior empírico |
| **MS9** | D4 closing parity + Maestro YAML smoke + PR | 4h | Full side-by-side todos 6 estados |

**Estimate:** 40-44h (5-6 dias úteis com revisões).

## Libraries

| Purpose | Package | Version | Cost | Context7 ID |
|---|---|---|---|---|
| Custom scroll wheel time picker | `wheel_picker` | `^0.3.0` | 0 | `/jaweii/flutter_wheel_picker` (queried 2026-06-01) |
| Radio screen / chips | (Material 3 stdlib) | n/a | 0 | stdlib exception per CLAUDE.md |

**Resolved at install time** (`flutter pub add wheel_picker`). Will record exact resolved version in MS1 commit + ADR-0040 amendment.

## ADRs filed during this Area

- **ADR-0040** — `wheel_picker ^0.3.0` adopted for time picker drum widget. Cost 0. Filed in MS1.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Back gesture orchestration breaks on nested routes (6 new routes deep) | `integration_test/route_details_flow_test.dart` em MS9 cobre todos paths |
| State leak Route A → Route B (config persiste de rota fechada) | `family + autoDispose` em MS1 + isolation unit test |
| Custom scroll wheel UX divergence vs Spoke | `flutter-perf-auditor` em MS4 + screenshot D-mid + flick velocity test |
| SharedPrefs schema drift Slice 3 backend | `schemaVersion: 1` + field names = futuros TypeBox |
| Compose ImageVector blindspot (uiautomator) recomenda divergência fantasma | Screenshot citation MANDATORY em todos D-mid + D4 (lesson `lesson_visual_screenshot_overrides_xml_inference_in_compose_apps`) |
| Picker reuse (AddStopPage) altera comportamento Area 4 ao adicionar `PickerMode` | `mode` é nullable, default null = comportamento atual; widget + integration tests Area 4 devem continuar passando |
| `copyWith` em `RouteConfig` nullable fields silently retains old value | Build entity manualmente, NÃO usar copyWith para nullables (lesson `lesson_copywith_nullable_field_pitfall`) |
| Maestro tap em ListTile rows falha silenciosamente | `Semantics(identifier:)` em todos rows desde MS2 commit 1 (lesson `lesson_maestro_flutter_listtile_tap_needs_semantics`) |
| FTUE flag false-positive (defaults SharedPrefs absent ≠ first route) | Flag `route_defaults_v1.firstRoute: true` setada explicitamente ao install; testado MS8 |
| Pausa chips empírico parcial (só vi 08:00 + 15:00 horários, não validei 11/12/13) | Re-dispatch `spoke-parity-checker` MS6 com nova captura `/tmp/spoke-a5-pause-full.xml` antes do commit final |

## Accessibility

1. **Semantics labels** — `Semantics(identifier: 'route_details_row_<key>')` em todos rows. `Semantics(identifier: 'route_details_confirm')` no botão Concluído.
2. **Tap targets ≥ 48×48dp** — ChoiceChip + RadioListTile já cumprem por default; rows com `ListTile` (height = 56dp).
3. **WCAG AA contrast** — usar `prototipo/tokens.js` colors (já validado em Areas 2-4); novos pontos só em time picker drum (verificar contrast text-on-background AA).

## Test strategy

| Layer | Tool | Coverage |
|---|---|---|
| Domain | `flutter_test` unit | `RouteConfig` sealed pattern + `RouteDefaults` JSON roundtrip |
| State (Riverpod) | `flutter_test` + `ProviderContainer` | Controllers update / valid / autoDispose isolation |
| Widgets | `flutter_test` widget | Each new page renders + interaction shape (no real network) |
| Repository | `flutter_test` + `SharedPreferencesAsync.setMockInitialValues` | Read/write/missing-envelope behavior |
| Integration | `integration_test` + M54 | Full FTUE + back gesture chain + persist+restore + reuse pickers Area 4 still works |
| Smoke E2E | Maestro YAML | `area5_route_details_flow.yaml` covering nav to/from each sub-picker |

**Tech debt explicit** (added to `TODO.md` MS9 commit):

- *2026-06: Solver-side validation (drive time fits in time window) deferred to Slice 3.*
- *2026-06: Multi-break ordering UI (rearrange list) deferred — Spoke não tem; só add/edit/delete.*

## Verification gates

- [ ] `flutter analyze` clean.
- [ ] `flutter test` ≥ 105 passing (current 91 + ~14 novos).
- [ ] `bun run typecheck` clean (backend não muda, mas slice 3 contract field names devem espelhar nomes Q4).
- [ ] Real-device golden path (14 steps §Goals) capturado screenshot por screen.
- [ ] `spoke-parity-checker` D4 dispatch reports clean (screenshot pixel evidence rule observado).
- [ ] `flutter-perf-auditor` dispatch reports clean (time picker drum specifically).
- [ ] `adr-guardian` reports clean.
- [ ] `/verify-slice` GO verdict.
- [ ] Maestro `area5_route_details_flow.yaml` PASS on M54.
- [ ] PR body filled per `M2-SLICE-CHECKLIST.md`.

## References

- `CLAUDE.md` — operating manual + Karpathy 4 + ADR-0035 source-of-truth hierarchy.
- `docs/08-ROADMAP-v2.md` "Área 5".
- `docs/inventory/2026-05-26-spoke-vs-rotpro.md` §11.4 (Detalhes da rota) + §13.C.2 (FTUE confirmation).
- `prototipo/tokens.js` — visual identity.
- `prototipo/screens-route-config.jsx` — visual reference.
- ADR-0010 (functional fork), ADR-0013 (schema source of truth), ADR-0018 (verify-slice), ADR-0024 (codegen hook), ADR-0035 (white-label hierarchy), ADR-0036 (D1/D4 parity gates), ADR-0037 (Maestro MCP inspection), ADR-0040 (wheel_picker — filed MS1).
- `/tmp/spoke-a5-*` 21 artefatos baseline captured 2026-06-01.
- Memory: `lesson_uiautomator_blindspot_compose_imagevectors`, `lesson_visual_screenshot_overrides_xml_inference_in_compose_apps`, `lesson_copywith_nullable_field_pitfall`, `lesson_maestro_flutter_listtile_tap_needs_semantics`, `lesson_slice_checklist_integration_test_gate`, `lesson_checkpoint_discipline_between_microsprints`, `lesson_git_diff_head_before_commit_after_workflows`.
- Context7: `/jaweii/flutter_wheel_picker` (queried 2026-06-01 — version `^0.3.0` confirmed current).
