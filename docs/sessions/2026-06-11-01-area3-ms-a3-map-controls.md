# 2026-06-11-01 — Área 3 MS-A3: controles de mapa reais + Copiar paradas (dump-first)

## Metadata

- **Date**: 2026-06-11 (America/Sao_Paulo)
- **Sequence**: 01
- **Agent**: Claude Code
- **Human**: Eduardo
- **Topic**: Área 3 map controls
- **Duration**: ~2h30m
- **Related ADRs**: none (sem mudança de stack — deps já no pubspec)
- **Related TODO items**: Area 3 (gatilhos da tela ativa de rota)

## Goal of the Session

Wirar os controles funcionais da tela ativa de rota (Área 3) que eram stubs `_comingSoon`: layer toggle do mapa, recenter, e "Copiar paradas de uma rota anterior". Disciplina dump-first (ADR-0045) + TDD + zero divergência Spoke deferida. Os 3 gatilhos restantes (Otimizar/stop-card/kebab) apontam pra telas ainda não construídas → ficam como 1ª task dos MSs A7/A6/A9.

## What Was Done

1. **Onboarding + dump-first baseline.** Workflow de 3 leitores paralelos (MASTER-TABLE + jadx-out + inventário). A varredura confirmou a lição `lesson_master_table_covers_setup_not_active_shell`: a MASTER-TABLE não cobre o shell ativo. Resolvi o comportamento dos 2 controles 100% no código decompilado (`EditRouteFragment` event handlers via `rm9` sealed events, `MapController`, `MapToolbarControlsController`) + strings PT-BR (`res-decoded/.../strings.xml`) — sem runtime, sem poluir a conta licenciada.
2. **Task 3 (Copiar paradas) — TDD.** Teste primeiro (push p/ `/home/routes/reuse-stops` via GoRouter real + sentinel) → RED (era SnackBar) → GREEN (`context.push`).
3. **Task 1 (layer toggle) — TDD.** Criado `MapControlsState` (immutable) + `MapPrefsRepository` (SharedPreferencesAsync, key `map_type_v1`) + `MapControlsController` (`@riverpod` keepAlive). Stubs `UnimplementedError` → RED → GREEN. Wirado no shell: `GoogleMap.mapType` lê o provider via `.select`; botão chama `toggleMapType()` + toast PT-BR original.
4. **Task 2 (recenter) — TDD.** Criado `LocationService` (wrapper geolocator, sealed `LocationResult` ready/denied/unavailable, callbacks injetados p/ testabilidade) + `locationServiceProvider`. Wirado: tap → `currentLocation()` → switch exaustivo → `startFollowing()` + `animateCamera`, ou toast gracioso sem permissão.
5. **Task 4 (visibilidade) — HALT + escalação.** Achei contradição estrutural inventário↔dump; escalei. Eduardo: "copie como está no dump da Spoke". O dump prova visibilidade por flow ativo, não por sheet → controles sempre visíveis no flow base = match-Spoke já correto. Zero código (teste de regressão + correção do inventário §6.2bis).
6. **2 reviewers adversariais.** perf-auditor (1 should-fix: RepaintBoundary dos controles) + code-reviewer (1 Important: race no flag `_programmaticCameraMove`). **Ambos corrigidos no MS com teste**, zero deferido.
7. **Smoke E2E no M54** (Maestro MCP): layer toggle (normal↔satélite confirmado por pixel), recenter (permissão→GPS real, câmera animou SP→Ribeirão Preto), Copiar paradas→Reutilizar. Todos verdes.

## Decisions Made

1. **Estado de mapa num provider testável, não no StatefulWidget.** `MapControlsController` (`@riverpod` keepAlive) detém `mapType` (persistido) + `followingUser` (efêmero). TDD ficou inviável dentro do State; o provider torna toggle/persist/follow/race testáveis.
2. **Race-fix por contador, não flag booleano.** `onCameraMoveStarted` chega por platform channel possivelmente DEPOIS de `animateCamera` resolver. Um flag resetado síncrono corre; um contador `_pendingProgrammaticMoves` consumido 1-por-evento é ordem-independente. (Achado do code-reviewer, confiança 82.)
3. **Task 4 = match-Spoke já correto (dump refutou inventário).** §6.2bis "controles só com sheet collapsed" era inferência de 1 snapshot; `MapToolbarControlsController` é uma `Stack<Flow>` → visibilidade por flow, não por altura do sheet. Nenhuma mudança de código; inventário corrigido + teste de regressão.
4. **Sem ADR.** Nenhuma mudança de stack (geolocator/google_maps/permission_handler/shared_preferences já no pubspec, sem bump). adr-guardian não aplica.
5. **3 gatilhos restantes deferidos aos seus MSs.** Otimizar→A7, stop-card→A6, kebab→A9 apontam pra telas inexistentes → 1ª task de cada MS, não wirar contra placeholder "em breve".

## Open Questions Left

- [ ] `followingUser` é estado sem consumidor de UI hoje (a câmera não persegue o GPS continuamente — recenter é um `animateCamera` único). É scaffold para o follow real do modo Delivery (Área 8). Não é fluxo morto (testado), mas a paridade total com `FollowMyLocation` (câmera que persegue) só existe quando a Área 8 ligar o stream. Registrado pelo code-reviewer; intencional neste MS.

## Files Changed

**Created**:
- `apps/mobile/lib/features/routes/domain/map_controls_state.dart`
- `apps/mobile/lib/features/routes/data/map_prefs_repository.dart`
- `apps/mobile/lib/features/routes/data/location_service.dart`
- `apps/mobile/lib/features/routes/state/map_controls_controller.dart`
- `apps/mobile/test/features/routes/state/map_controls_controller_test.dart`
- `apps/mobile/test/features/routes/data/location_service_test.dart`

**Modified**:
- `apps/mobile/lib/features/routes/presentation/route_shell_page.dart` (wirou layer toggle + recenter + Copiar paradas; removeu `_comingSoon` top-level órfão; RepaintBoundary nos controles)
- `apps/mobile/test/features/routes/presentation/route_shell_page_test.dart` (+ testes de mapa/recenter/regressão de visibilidade)
- `docs/08-ROADMAP-v2.md` (Área 3 → ~90%)
- `docs/10-CHANGELOG.md` (entrada MS-A3)
- `docs/inventory/2026-05-26-spoke-vs-rotpro.md` (§6.2bis corrigido)
- `TODO.md` (Area 3)

## Commits Pushed

```
0365373 feat(routes): Área 3 MS-A3 — controles de mapa reais + Copiar paradas (dump-first)
```

Branch `feat/m2-slice-2-area-3-triggers` pushada para `origin` (`e5748d3..0365373`). PR ainda não aberto.

## Hand-off Notes for Next Session

- **Branch atual:** `feat/m2-slice-2-area-3-triggers` (pushada, sem PR aberto). Mira `develop` (NUNCA `main`).
- **Área 3 → ~90%.** Faltam só os 3 gatilhos que dependem de telas futuras: CTA Otimizar (1ª task MS-A7), tap stop-card (1ª task MS-A6), kebab "Opções da rota" (1ª task MS-A9). NÃO wirar contra placeholder "em breve".
- **Próximo na ordem forçada do roadmap:** Área 6 (Editar parada — sheet 14 campos). Consome #4–#10 da MASTER-TABLE (dump-first). O tap no stop-card (Á3) é a 1ª task dela.
- **Idiom novo reusável:** controle de mapa testável = provider Riverpod + serviço com callbacks injetados (geolocator) + sealed result. O race-fix por contador pending-move serve pra qualquer tela que anime câmera + observe pan (Área 8 delivery).
- **308 testes host** (baseline +24). 23 lints MS-DEBT intocados.

## Reference Material Used

- Dump estático Spoke v3.65.1: `~/spoke-dump/jadx-out/sources` (`EditRouteFragment`, `MapController`, `MapToolbarControlsController`, `p000/rm9.java`, `p000/om9.java`) + `~/spoke-dump/res-decoded/res/values-pt-rBR/strings.xml`.
- Dart MCP: `geolocator-14.0.2` (`getPositionStream`, `LocationSettings`, `checkPermission`/`requestPermission`, `LocationPermission`).
- `docs/inventory/spoke-dump-v3.65.1/MASTER-TABLE.md` + `docs/inventory/2026-05-26-spoke-vs-rotpro.md` §6.2bis/§10.5/§10.9/§10.13.
- Maestro MCP (smoke E2E no M54): `inspect_screen`, `run`, `take_screenshot`.
