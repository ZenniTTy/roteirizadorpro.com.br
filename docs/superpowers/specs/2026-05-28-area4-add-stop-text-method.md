# Spec — Area 4 (Add stop via TEXT method, Google Places stub)

> **Date:** 2026-05-28
> **Author:** Claude Code (with Eduardo)
> **Status:** Approved 2026-05-28 by Eduardo (Slack-style confirm "Spec aprovado"). Next: `superpowers:writing-plans` → `docs/superpowers/plans/2026-05-28-area4-add-stop-text-method.md`
> **Branch:** `feat/m2-slice-2-area-4-add-stop-text` (off `develop` at HEAD = `cd37a65`)
> **Source of truth:** `docs/08-ROADMAP-v2.md` Slice 2 — Area 4 (texto autocomplete). This spec elaborates that section; if the two disagree, the ROADMAP wins and the contradiction is a bug to fix in the same PR.

> **Single sources of truth (do NOT duplicate here):**
> - Spoke parity behavioral baseline → `docs/inventory/2026-05-26-spoke-vs-rotpro.md` §10.21 (a tela) + §11.4 (texto method) — both already amended 2026-05-28 with D1 findings of this microsprint.
> - Visual identity tokens → `prototipo/tokens.js` per ADR-0035.
> - Stack lock + ORM contract → `CLAUDE.md` "Stack — Locked Versions" + ADR-0013.

---

## Context

Slice 2 of M2 ("Telas Core Spoke-aligned") shipped 3 PRs so far: drawer (`feat/m2-slice-2-area-2-drawer` merged via `cd37a65`), route shell with map+sheet, and wizard create/edit. Routes can be created and listed; the active route is tracked via `activeRouteIdProvider` (Riverpod 3 keepAlive notifier). The route shell already renders an in-memory list of stops on its sheet — but there is no way for the user to ADD a stop, so the empty state is the only state observed today.

This spec closes that gap with the TEXT method only. Voice, OCR, and tap-on-map remain stubs (each ships in its own PR because of native dependencies — mic permissions, ML Kit binary, reverse-geocode).

**Discovery surprise** (D1 dispatch 2026-05-28): `add_stop_page.dart` was previously believed to be a skeleton but is actually 128 lines of working code consuming `placeAutocompleteProvider` (Google Places v1 real, debounce 500ms). The active-route wiring, search bar, and 3 method buttons are already in place. The work in this PR is structural completion to Spoke parity, not greenfield.

## Decisions locked in this brainstorming session

7 questions resolved via `AskUserQuestion` 2026-05-28 (4 + 3 in two rounds). All 7 = the user's recommended-default option.

| # | Question | Decision | Rationale |
|---|---|---|---|
| Q1 | Backend de autocomplete neste PR: Google Places real (que já está) vs stub hardcoded? | **Manter Google Places real** | App fica usável ponta-a-ponta agora; smoke test Maestro pode testar busca real. Custo de Places até Slice 3 trocar por Nominatim é aceito. Reverter pra stub seria deletar código funcional pra reescrever depois. |
| Q2 | Auto-open de edit-stop após criar parada (Spoke §11.4 BIG FIND inline) — implementar agora ou adiar? | **Adiar — pop() voltando ao shell, parity break documentado** | Edit-stop sheet completa (14 campos) é Area 6, próximo PR. Implementar inline neste PR dobraria escopo. Option B (pushReplacement pra rota stub) cria 2 deltas em vez de 1 quando Area 6 chegar. Pop() é o gap menos ambíguo de reverter. |
| Q3 | Seção "Desta rota (N)" — busca em stops da rota ativa, tap leva pra edit-stop. Implementar agora? | **(a) Implementar com tap stubbed (SnackBar "Editar parada em breve")** | Estrutural — Spoke renderiza essa seção SEMPRE que match houver. Parity visual completa neste PR; tap só fica adiado. Smoke test consegue ver a UX inteira. Quando Area 6 chegar, troca SnackBar por context.push do edit-stop. |
| Q4 | Footer "Escolher no mapa" — wirar pro stub do `add_stop_map_page.dart` ou stub SnackBar? | **Wirar pro stub do mapa existente** | `add_stop_map_page.dart` já está registrado no GoRouter como `/home/routes/add-stop/map`. Quando Area 5 implementar tap-on-map real, só o destino do tap muda. Smoke test consegue tocar e navegar. |
| Q5 | Microcopy do empty state — implementar variação 0-stops vs ≥1-stop ou hardcode 1? | **Implementar variação condicional** | Parity Spoke completa. Custo ~5 linhas + 1 teste. Sem variação, rota não-vazia continua dizendo "Adicione as primeiras paradas" — incorreto factualmente. |
| Q6 | Transição de entrada (Spoke = slide-from-bottom; RotPro = GoRouter default right-to-left). Implementar `CustomTransitionPage` agora? | **Adiar pra polish pass final do Slice 2** | Animações são cosméticas; todas as telas do Slice 2 com mesma divergence serão ajustadas em um único PR de polish. `CustomTransitionPage` tem gotchas de keyboard timing que aumentariam risco neste PR. |
| Q7 | Spec formal em `docs/superpowers/specs/` ou brainstorm-direto-pra-código? | **Spec formal + writing-plans + TDD** | 4 must-fixes estruturais + drift de inventário + BIG FIND adiado pra Area 6 = registro escrito ajuda a próxima sessão entender o estado. CLAUDE.md pós-reset permite skip, mas Eduardo enforçou "documentar tudo, nada esquecido". |

## Goals (acceptance for this slice)

A real Android M54 install of `v1.1.0-area4` (debug build with `--dart-define-from-file=apps/mobile/.env`) can, against production API:

1. **Open** the route shell with at least one route active. Tap the search pill "Adicionar parada...". The add-stop screen pushes via GoRouter default transition. Keyboard auto-opens; cursor in the search field.
2. **Empty state (rota vazia)** — see the microcopy *"Adicione as primeiras paradas para começar a criar sua rota"* + 3 method shortcut buttons (Mapa / Leitor / Voz). Search bar shows `[input | OCR | Voice | X]`.
3. **Empty state (rota com ≥1 stop)** — see the microcopy *"Adicione novas paradas ou encontre paradas na rota"* + same 3 method shortcut buttons.
4. **Type 2 characters** (e.g. "Av") — `placeAutocompleteProvider` fires, results appear within ~600 ms. Search bar transforms: OCR + Voice icons **disappear** (only `[input | X]` remains).
5. **Results state shows 2 sections**: Section A "Desta rota (N)" (only when query matches stops on the active route) + Section B "Adicionar nova parada" (Google Places candidates).
6. **Footer "Escolher no mapa"** is visible at the bottom of the results list with map icon + chevron. Tap navigates to `/home/routes/add-stop/map` (existing stub page).
7. **Tap a result row in Section B** — `getPlaceDetails` fires, a `Stop` is built and added to the active route via `routesProvider.addStop(activeRouteId, stop)`. `context.pop()` returns to the route shell. The new stop's pin is visible on the GoogleMap.
8. **Tap a result row in Section A** — SnackBar shows *"Editar parada em breve"* (Area 6 will replace with `context.push` to edit-stop).
9. **Zero-result state (query.isNotEmpty && results.isEmpty)** — see *"Nenhum resultado encontrado / Tente reformular a pesquisa"* + the 3 method buttons reappear (fallback to choose another method).
10. **Clear input** (tap X) — search bar reverts to empty state; OCR + Voice icons return; 3 method buttons visible again.
11. **Android back gesture** from the add-stop screen — returns to the route shell, no crash, no leftover keyboard.
12. **No regression**: the 5 smoke tests from the previous PR (drawer + wizard create/edit + reuse-stops + cancel-with-X) still pass.

### Non-goals (explicit, to keep scope tight)

- **Voice method** (Spoke §3.2 item 10b, RotPro §10.21 method #4) — stub SnackBar mantido; **Area 7** (or Slice 3+, has native `speech_to_text` + mic permission).
- **OCR method** (Spoke §3.2 item 10, RotPro §10.21 method #3) — stub SnackBar mantido; **Area 7** (or Slice 3+, has ML Kit binary).
- **Tap-on-map flow** (Spoke §10.21 method #2) — `add_stop_map_page.dart` continua stub visual; **Area 5** (has reverse-geocode dependency, Nominatim arrives in Slice 3).
- **CSV upload** (Spoke §12.A.6, RotPro 5th method) — kebab da rota → "Importar manifesto"; **Slice 3+**.
- **Edit-stop sheet completa** (14 campos, Spoke §10.6 + §11.5) — **Area 6** (next PR). This PR ships the SnackBar stub in Section A tap.
- **BIG FIND auto-open inline** (Spoke §11.4 amended) — Area 6 implements; this PR uses `context.pop()` as documented gap.
- **Custom slide-from-bottom transition** (Q6) — **polish pass final do Slice 2**.
- **Nominatim SP real** (Slice 3 trade-out of Google Places).
- **Stop status / pins coloridos** (Spoke §10.5 item 31) — Slice 2 area later; Slice 3 backend persists.

## Architecture

> Spoke parity baseline = inventory §10.21 + §11.4 (already amended 2026-05-28). This section covers ONLY RotPro-specific implementation choices that the inventory doesn't dictate.

### Page layout (replaces current `Stack`-based)

```
Scaffold(resizeToAvoidBottomInset: true)
└─ SafeArea
   └─ Column
      ├─ AddStopSearchBar (fixed, sticky top)
      │  └─ reactive: hides OCR+Voice when query.isNotEmpty
      └─ Expanded
         └─ ContentSwitcher (3 branches via switch on derived state)
            ├─ EmptyState: microcopy varies on activeRoute.stops.length + 3 method buttons + Mapa footer NOT shown
            ├─ ZeroResultState: "Nenhum resultado" + 3 method buttons + Mapa footer NOT shown
            └─ ResultsState: ListView with [Section A] + [Section B] + footer "Escolher no mapa"
```

**Rationale for Column over Stack** (Risk 2 mitigation, from D1 risk register): the previous Stack + `Positioned(top: 120)` works only because content sits below a hardcoded offset. Adding the footer and the 2 sections makes the height dynamic; the keyboard inset would then push the footer below the visible area or cause `RenderFlex` overflow. Column + Expanded delegates layout to Flutter's standard flow + the keyboard inset goes to the Expanded's clip.

### Derived state (Risk 3 mitigation)

Encapsulate `(query, predictionsAsync)` into a single derived value via `ref.watch`:

```dart
final addStopUiStateProvider = Provider.autoDispose<AddStopUiState>((ref) {
  final query = ref.watch(searchQueryProvider);   // String
  final preds = ref.watch(placeAutocompleteProvider); // AsyncValue<List<Prediction>>
  final routeStops = ref.watch(currentRouteStopsProvider); // List<Stop>
  return AddStopUiState.from(query, preds, routeStops);
});

sealed class AddStopUiState {
  const AddStopUiState();
  factory AddStopUiState.from(...) { ... }
}

final class EmptyVariant extends AddStopUiState { final int stopCount; }
final class ZeroResults extends AddStopUiState {}
final class WithResults extends AddStopUiState {
  final List<Stop> matchesInRoute;     // Section A
  final List<Prediction> newCandidates; // Section B
}
final class Loading extends AddStopUiState {}
final class ErrorState extends AddStopUiState { final Object err; }
```

The widget then does `switch (uiState) { case EmptyVariant(): ... case WithResults(): ... }` — exhaustive at compile time. Edge case (user clears input while request in-flight): `predictionsAsync.isLoading` keeps `Loading`, but if `query.isEmpty` we override to `EmptyVariant`. Single source of truth = `addStopUiStateProvider`.

### Routing (no changes to GoRouter)

Existing routes unchanged:
- `/home/routes/add-stop` → `AddStopPage` (this PR)
- `/home/routes/add-stop/map` → `AddStopMapPage` (existing stub, footer wires to it)

No `:routeId` path param. Active route comes from `activeRouteIdProvider`. Guard for `null` activeRouteId (lifecycle race) → SnackBar "Nenhuma rota ativa" + `context.pop()`.

### Test surface (per `superpowers:test-driven-development`)

| Layer | Tests | Why |
|---|---|---|
| Domain | `AddStopUiState.from` — 5 branches (empty 0 stops, empty ≥1 stop, zero-results, with-results both sections, with-results only Section B). | Branch logic is the heart of the UI; widget test would re-test it implicitly but at higher cost. |
| Provider | `currentRouteStopsProvider` derivation; SnackBar guard for null activeRouteId; addStop wiring | Riverpod side already works; just guards. |
| Widget | `add_stop_page_test.dart` — render each variant + tap behavior (Section A tap = SnackBar; Section B tap = addStop call + pop; footer tap = push `/map`). | Spoke parity §10.21 + §11.4 must be observable in widget tree. |
| Integration | `integration_test/add_stop_flow_test.dart` — golden path: open → type → see results → tap Section B → pop returns to shell. Runs on M54. | Risk 1 mitigation. Mandatory per slice checklist. |
| Smoke (Maestro) | 4-fluxo punch list run on M54 — see "Verification" section. | Lesson persisted: widget+integration don't catch GoRouter branch-stack + Android back. |

## Risk register

> Inventory §10.21 + §11.4 already lists Spoke baseline risks. Only RotPro-specific risks here.

**Risk 1 — Smoke test Maestro mandatory before commit**  
Persisted lesson: widget tests + analyze pass but device-only issues (gesture conflicts, keyboard timing, GoRouter stack) hit. Mitigation: integration_test in plan + Maestro punch-list before final commit, NOT after PR opens.

**Risk 2 — `Stack` → `Column` migration may break visual regressions**  
Current `Stack + Positioned(top: 120)` has a working empty state. Refactor to Column may shift element positions by sub-pixel amounts. Mitigation: 1 golden test per state (empty 0/≥1, zero-result, with-results, loading) using `alchemist` package already in pubspec.

**Risk 3 — Derived state provider re-renders if not memoized**  
`addStopUiStateProvider` rebuilds every time `searchQueryProvider` or `placeAutocompleteProvider` change. With debounce 500ms it's fine, but if Slice 3 rebaixar pra 300ms + Section A filter is O(n²), rebuild storm. Mitigation: `Provider.autoDispose` + `select` em consumers downstream + memoize Section A filter result via `equatable`.

**Risk 4 — Inventory drift between this PR and Area 6 PR**  
The §11.4 BIG FIND amendment defers Option A inline (DraggableScrollableSheet) to Area 6. If Area 6 spec misses the amendment, it'll re-implement Spoke from §11.4 original wording. Mitigation: this spec explicitly notes "Area 6 reverts pop() and implements Option A inline" in §Decision Q2 and in Inventory amendment block.

## Open items for Area 6 (next PR — to NOT lose context)

When the Area 6 PR opens, the implementer must read:
- Inventory §11.4 amendment 4 (BIG FIND clarified: edit-stop sheet is inline, NOT push)
- This spec §Q2 rationale + §Goals 7 (the pop() that Area 6 will revert)
- This spec §Q3 rationale (Section A tap currently = SnackBar, Area 6 replaces with context.push to edit-stop)
- The `add_stop_page.dart` returning state at the time Area 6 starts — it should be functioning per §Goals here.

Area 6 deliverables that close THESE gaps:
1. Implement edit-stop sheet (Spoke §10.6 + §11.5, 14 campos).
2. Replace the SnackBar in `AddStopPage` Section A tap with `context.push('/home/routes/stops/:id/edit')`.
3. Replace the `context.pop()` in `AddStopPage` Section B tap with the inline DraggableScrollableSheet open per §11.4 BIG FIND.
4. Restore "user can keep typing without going back" UX from Spoke §11.4.

## References

- Inventory: `docs/inventory/2026-05-26-spoke-vs-rotpro.md` §10.21 + §11.4 (both amended 2026-05-28).
- ROADMAP: `docs/08-ROADMAP-v2.md` Slice 2 Area 4.
- Slice checklist: `docs/M2-SLICE-CHECKLIST.md` (verification gates).
- ADRs: 0013 (schema source of truth), 0035 (Spoke white-label hierarchy), 0036 (parity gate), 0037 (Maestro MCP inspection).
- Previous specs in this directory (drawer, popup-3dot, wizard) — tone + depth model.
