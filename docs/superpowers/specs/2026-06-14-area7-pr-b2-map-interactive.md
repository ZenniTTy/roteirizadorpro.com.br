# Spec — Área 7 PR-B2 (mapa interativo: polyline + markers numerados + kebab Reotimizar)

> **Date:** 2026-06-14
> **Author:** Claude Code (with Eduardo)
> **Status:** Awaiting user review before invoking `writing-plans`
> **Branch:** `feat/m2-slice-2-area-7-pr-b2` (off `develop` at `0e27cd1`)
> **Source of truth:** `docs/08-ROADMAP-v2.md` "Slice 2 — Área 7". Esta spec elabora o PR-B2 da Á7; se divergir do ROADMAP, o ROADMAP vence.

---

## Context

O **PR-B1** (mergeado, PR #31 → `develop`) entregou a ESTRUTURA do PRE-CONFIRM da Área 7: a lista ordenada de paradas com chips A1..AN, a linha de resumo, os 2 CTAs (Refinar/Confirmar), os sheets (Refinar ≠ Reotimizar), o FTUE de numeração e a remoção deferida (G5). Tudo isso renderiza no mesmo `route_shell_page.dart` por estado derivado (`isPreConfirm`), **usando o mapa estático atual** (o `GoogleMap` que existe desde a MS-A3, sem rota desenhada).

O **PR-B2** torna o mapa do PRE-CONFIRM **interativo e fiel ao Spoke**: desenha a rota otimizada (polyline ligando as paradas na ordem do solver), coloca markers customizados em cada parada, e monta o trigger de reotimização (o `ReoptimizeOptionsSheet`, já pronto+testado no B1, ganha o caller via kebab). Fecha visualmente o PRE-CONFIRM.

**Baseline dump-first (2026-06-14):** o relatório do `spoke-parity-checker` sobre `~/spoke-dump/jadx-out` (`MapController`, `PolylineGroup`, `StopMarkerLabel`, `MapToolbarControlsController`, `AbstractC3736v/w`, `EditRouteViewModel`) é a fonte estrutural. Ele **corrigiu 2 premissas erradas** do B1 (ver §Decisions Q3/Q4). Fica **fora** deste PR: o Ready-to-Run/Confirmar (PR-C), o OrderStopGroups/"Ordenar manualmente" (PR-D), e a hora estimada por parada no marker (Slice 3, com GraphHopper real).

## Decisions locked in this brainstorming session

| # | Question | Decision | Rationale |
|---|---|---|---|
| Q1 | Como replicar o marker custom do Spoke (que usa overlay Compose, não `BitmapDescriptor` nativo) no `google_maps_flutter`? | **`BitmapDescriptor.fromBytes()` desenhado via `dart:ui` `Canvas`** (`PictureRecorder` → `Canvas.drawRRect`/`drawParagraph` → `Picture.toImage()` → `image.toByteData(png)` → `fromBytes`), num `Marker` NATIVO. **Manual, SEM pacote.** | O `Marker` nativo NÃO sofre o conflito de `EagerGestureRecognizer` do `GoogleMap` PlatformView ([[lesson_googlemap_eats_gestures_use_column]]). Context7 (queried 2026-06-14, `/flutter/website`) confirma `Canvas`→`toImage`→`toByteData(ImageByteFormat.png)` como idiom oficial. Para um pino simples (forma + texto curto) desenhar no `Canvas` é ~30 linhas e mais controlável que renderizar uma árvore de widget offscreen (que exigiria `OverlayEntry`/pipeline frágil). **Sem dep nova → sem ADR de stack, sem custo.** Trade-off aceito: re-gerar o bitmap quando dados/zoom mudam (cache por chave). |
| Q2 | Tamanho do PR-B2? | **B2 completo num PR** (polyline + markers + wire kebab Reotimizar). | Os 3 itens são o "mapa do PRE-CONFIRM" coeso. O componente arriscado (GoogleMap) e o wire trivial (kebab) compartilham o mesmo shell — fatiar criaria um PR com mapa-sem-trigger. Coeso > granular aqui. |
| Q3 | O dump diz que o marker do Spoke mostra HORA ESTIMADA por parada. Mostrar no B2? | **NÃO — marker mostra só endereço.** ETA por parada é Slice 3 (GraphHopper real). | ⚠️ Bug-silencioso evitado: o `LocalRouteOptimizer` (NN+2-opt + Haversine) dá tempo TOTAL por estimativa geométrica grosseira (linha reta ÷ velocidade chutada). Derivar "chega 14:32" disso seria um número preciso-parecendo que MENTE ao motorista e mudaria drasticamente com o roteamento real. Paridade com o Spoke é estrutural (o marker existe, mostra a parada) — o Spoke tem hora porque tem backend real; nós não. Mostrar hora falsa = disparidade-que-engana. |
| Q4 | Onde o trigger do Reotimizar ancora? | **No KEBAB do PRE-CONFIRM** (não no toolbar do mapa). | ⚠️ Correção dump-first de premissa errada do B1: a cadeia jadx é kebab `more_options_reoptimize_route_title` "Reotimizar rota..." (`AbstractC3737w.f`) → `ReoptimizeActiveRoute` (`AbstractC4115a.h`) → `EditRouteViewModel AnonymousClass4` → `ShowReoptimizeRouteDialog` (`AbstractC3736v.l0`) → `ReoptimizeRouteDialog`. O `OrderStopGroupsOptimizeButtonType.Reoptimize` é OUTRA coisa (botão do sheet de grupos, PR-D). Não há FAB de reotimização no mapa (`MapToolbarFabMode {Drawer, Close, Hidden}` — no PRE-CONFIRM/Overview só Drawer + toggles satélite). |
| Q5 | A polyline vem do backend ou é traçada client-side? | **Client-side: retas (`LatLng`) entre stops na ordem otimizada.** | O dump prova (`markerPolylineFlow$2`) que o Spoke une os pontos da rota localmente — não há endpoint de polyline. Mesma filosofia do solver local. Quando o GraphHopper real entrar (Slice 3), a polyline pode virar curva real de routing — declarado como débito. Só aparece quando `optimization == OPTIMIZED` (no draft não há polyline). |

## Goals (acceptance for this slice)

Um install real no Samsung M54 do app de debug, com uma rota de ≥2 paradas, pode:

1. Tocar "Otimizar rota" → ao chegar no PRE-CONFIRM, **ver a rota desenhada no mapa** (uma linha ligando as paradas na ordem otimizada, na cor da marca).
2. Ver um **marker em cada parada** com o endereço/identificação visível, na ordem da rota.
3. No estado DRAFT (antes de otimizar), **NÃO ver polyline** — o mapa mostra só os markers das paradas soltas.
4. Tocar o **kebab (3 pontinhos)** no PRE-CONFIRM → ver o item "Reotimizar rota..." → tocá-lo abre o `ReoptimizeOptionsSheet` ({Ajustar o que mudou / Recalcular do zero}).
5. Escolher "Recalcular do zero" → a rota re-otimiza e o mapa redesenha a polyline na nova ordem.
6. O mapa continua arrastável/zoomável normalmente (o marker nativo não rouba o gesto do mapa).

### Non-goals (explicit, to keep scope tight)

- **Hora estimada de chegada por parada no marker** (Slice 3 — exige GraphHopper real; o número local engana).
- **Ready-to-Run / Confirmar → Iniciar** (PR-C).
- **OrderStopGroups / "Ordenar manualmente" / reotimizar-por-grupos** (PR-D).
- **Polyline curva de routing real** (Slice 3 — hoje é reta entre pontos).
- **Variação de tamanho do marker por zoom em 4 breakpoints** (should-fix do dump — começa com 1-2 tamanhos; o refino fica p/ o polish ou um should-fix do perf-auditor se houver sobreposição).
- **Estado `Highlighted` do marker ao toque** (should-fix — feedback de seleção; entra se o tap-no-marker for necessário antes do PR-C).
- **Markers via overlay Compose** (o Spoke usa; nós usamos `BitmapDescriptor` nativo por Q1 — divergência de implementação, não de comportamento, registrada).

## Architecture

### Mobile feature module layout

```
apps/mobile/lib/features/routes/
├── domain/
│   └── route_geometry.dart           # NEW: helper puro — List<Stop> → List<LatLng> (ordem da rota)
├── presentation/
│   ├── widgets/
│   │   ├── stop_marker_label.dart     # NEW: o widget do pino (forma + texto) que vira bitmap
│   │   └── route_map_layer.dart       # NEW (opcional): encapsula a lógica de Set<Marker>/Set<Polyline>
│   └── route_shell_page.dart          # MOD: GoogleMap ganha markers: + polylines: derivados do estado;
│                                      #      kebab (_buildSearchRow) ganha o item "Reotimizar rota..."
│                                      #      quando isPreConfirm → showReoptimizeOptionsSheet
└── state/
    └── route_map_provider.dart        # NEW (opcional): @riverpod deriva Set<Marker>+Set<Polyline> da rota ativa
```

> Decisão de granularidade a confirmar no plano: se a lógica de markers/polyline couber limpa no `build` do shell + 1-2 helpers puros, evita-se o `route_map_provider`/`route_map_layer` (YAGNI). O plano TDD decide ao ver o tamanho real. Princípio: bitmap-de-widget é assíncrono (`toImage` é `Future`), então provavelmente um provider `FutureProvider`/`@riverpod` que entrega `Set<Marker>` é o idiom mais limpo (o `build` do shell não pode `await`).

### Bitmap-via-Canvas (o ponto técnico central — decidido: `dart:ui` manual)

`BitmapDescriptor.fromBytes()` recebe `Uint8List` PNG. Geramos via `dart:ui` `Canvas` (NÃO widget→bitmap, NÃO pacote):
1. `final recorder = ui.PictureRecorder(); final canvas = Canvas(recorder);`
2. Desenhar o pino: `canvas.drawRRect(...)` (forma/balão) + `ui.ParagraphBuilder`/`canvas.drawParagraph(...)` (texto = identificação da parada).
3. `final picture = recorder.endRecording(); final image = await picture.toImage(w, h);`
4. `final bytes = await image.toByteData(format: ui.ImageByteFormat.png);`
5. `BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());`

Assíncrono e custa por marker — **cachear por chave** (`stopId` + label). Context7 (`/flutter/website`, 2026-06-14) confirma este pipeline como idiom oficial. Multiplicar dimensões por `ui.window.devicePixelRatio` para o pino não sair borrado.

### Architecture principles

1. **Marker nativo, nunca overlay em Stack** — o gesto do mapa é sagrado ([[lesson_googlemap_eats_gestures_use_column]]).
2. **Polyline/markers DERIVADOS do estado, não armazenados** — observam a rota ativa via `.select` (granular, não rebuilda o mapa a cada frame de drag — lição perf do B1).
3. **Bitmap cacheado por chave** — gerar PNG de widget é caro; nunca regerar por frame.
4. **Sem ETA falso** — nenhum número derivado do solver local vira "hora" no marker (Q3).
5. **No premature abstraction** — `route_map_provider`/`route_map_layer` só se a lógica não couber limpa no shell + helpers puros.

## Data flow

### Polyline no PRE-CONFIRM

`OptimizationController` aplica → `routesProvider` tem a rota com `stops` na ordem otimizada + `routeState.optimization == optimized`. O shell observa (`.select`) a rota ativa: se `isPreConfirm` (ou optimized), mapeia `stops → List<LatLng>` (via `route_geometry.dart`) e monta 2 `Polyline` sobrepostos (outer espesso cor-de-borda + inner fino cor-primária, replicando `borderBrandEmphasis` do dump). Passa `polylines: {outer, inner}` ao `GoogleMap`. No DRAFT (`optimization == creating`): `polylines: {}` (vazio).

### Markers

Para cada stop da rota ativa, gerar (async, cacheado) um `Marker` com `BitmapDescriptor` do widget `StopMarkerLabel(endereço)` + `position: LatLng(stop.lat, stop.lng)`. Provider `@riverpod` async entrega `Set<Marker>`; o shell consome via `ref.watch(...).valueOrNull ?? {}` (mapa sem markers enquanto gera — sem flicker bloqueante).

### Kebab → Reotimizar

`_buildSearchRow` do `_ActiveRouteSheet` tem o kebab (`_GradientCircleButton`, hoje `_comingSoon('Opções da Rota')`). ⚠️ **Mas no PRE-CONFIRM o `_ActiveRouteSheet` não é montado — é o `PreConfirmView`.** Logo o kebab "Reotimizar rota..." precisa existir NO contexto do PRE-CONFIRM. Decisão de plano: o `PreConfirmView` ganha um kebab no topo (ou o shell expõe um overflow no PRE-CONFIRM) → `onReoptimize` no `_RouteShellPageState`: `showReoptimizeOptionsSheet` → `update` (reorderFlexible) / `reoptimize` (restartRoute) → `optimize` → `applyOptimization`. Mesmo padrão do `_onRefine` já testado. (Confirmar no plano: onde exatamente o kebab vive no PRE-CONFIRM — o dump diz "kebab da tela de edição"; ler o `EditRouteFragment$Content` p/ a posição.)

## Implementation phases

| Fase | Scope | Verification |
|---|---|---|
| F1 — geometria + polyline | `route_geometry.dart` (puro) + 2 Polyline no shell derivados do estado | unit test do helper; widget test que o GoogleMap recebe polylines não-vazio em PRE-CONFIRM e vazio em DRAFT |
| F2 — marker bitmap | `StopMarkerLabel` widget + gerador bitmap cacheado + provider de `Set<Marker>` | widget test do label; teste do provider (N stops → N markers); golden opcional do pino |
| F3 — kebab Reotimizar | wire kebab→`ReoptimizeOptionsSheet` no PRE-CONFIRM + `_onReoptimize` | widget test da regra (kebab visível em PRE-CONFIRM, abre o sheet, escolha re-otimiza) |
| F4 — gates + device | analyze + test + perf-auditor + spoke-parity D4 + integration_test/smoke M54 | golden path §Goals no M54 (mapa nunca foi testado em integration_test — risco) |

## Libraries

**Nenhuma dependência nova.** O bitmap do marker é gerado com `dart:ui` (`PictureRecorder`/`Canvas`/`toImage`/`toByteData`), já disponível no Flutter. `google_maps_flutter` (`Polyline`, `Marker`, `BitmapDescriptor`) já está no `pubspec.yaml` desde a MS-A3. Decisão registrada em Q1 (Context7 `/flutter/website` queried 2026-06-14 confirmou o pipeline `Canvas`→`toImage`→`toByteData(png)`).

## ADRs filed during this slice

- **Nenhuma.** Sem mudança de stack (markers via `dart:ui` manual, `google_maps_flutter` já instalado). O `adr-guardian` deve dar PASS.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| **GoogleMap × integration_test deadlock** (lição da Á5 MS9: o GoogleMap trava o `integration_test`) | Reusar o idiom map-free stand-in da Á5 (`area5_route_details_flow_test`) OU testar o mapa só por widget test (markers/polyline derivados) + smoke E2E manual no M54. NÃO bloquear o PR num integration_test que deadlocka. |
| **Bitmap-de-widget assíncrono causa flicker** (markers somem/reaparecem) | Cache por chave + `valueOrNull ?? {}` (markers aparecem quando prontos, sem bloquear o mapa). Gerar em paralelo (`Future.wait`). |
| **ETA falso no marker** (bug silencioso) | Q3 — marker NÃO mostra hora. Só endereço. ETA é Slice 3. |
| **Polyline rebuilda o mapa a cada drag** (perf) | `.select` na rota ativa (lição perf B1); polyline só muda quando a ORDEM muda, não no drag do sheet. |
| **Marker nativo rouba gesto** | Q1 — `Marker` nativo NÃO usa overlay; o gesto fica com o mapa ([[lesson_googlemap_eats_gestures_use_column]]). |
| **Kebab no lugar errado** (drift) | Q4 — dump confirma kebab, não toolbar. Ler `EditRouteFragment$Content` no plano p/ a posição exata do kebab no PRE-CONFIRM. |

## Accessibility (Karpathy 3 minimum)

1. **Semantics no kebab** — "Reotimizar rota" / "Opções da rota" no `_GradientCircleButton`.
2. **Tap targets ≥ 48×48** — o kebab já é 48; markers do mapa são tap nativo (tamanho do bitmap ≥ 48 lógico).
3. **Contraste WCAG-AA** — a cor da polyline + texto do marker contra o mapa (normal E satélite) auditados contra `prototipo/tokens.js` antes do sign-off.

## Test strategy

| Layer | Tool | What it covers |
|---|---|---|
| domain | unit | `route_geometry`: stops → LatLng na ordem; lista vazia/1-stop |
| state | unit/provider | provider de markers: N stops → N markers; polyline vazia em DRAFT, não-vazia em PRE-CONFIRM |
| widget | widget test | `StopMarkerLabel` renderiza endereço; kebab visível em PRE-CONFIRM abre o sheet; escolha re-otimiza |
| device | smoke E2E (Maestro/manual) M54 | golden path §Goals — o mapa só se valida de fato no device |

**Tech debt explicit (added to `TODO.md` in the PR):**

- *2026-06-14:* ETA por parada no marker = Slice 3 (GraphHopper real; o tempo local engana — Q3).
- *2026-06-14:* polyline reta (não curva de routing) = Slice 3.
- *2026-06-14:* tamanho de marker por zoom (4 breakpoints) + estado `Highlighted` ao toque = should-fix adiado (polish/PR-C se necessário).
- *2026-06-14:* markers via `BitmapDescriptor` nativo (Spoke usa overlay Compose) — divergência de implementação consciente (Q1), não de comportamento.

## Verification gates (per `M2-SLICE-CHECKLIST.md`)

Para declarar o PR-B2 pronto:

- [ ] `flutter analyze` sem lint novo.
- [ ] `flutter test` passa (widget + unit dos novos; baseline 670 + novos).
- [ ] `flutter-perf-auditor` limpo (markers/polyline derivados sem rebuild do mapa no drag).
- [ ] `spoke-parity-checker` D4 dump-only: polyline Highlighted, markers, kebab Reotimizar conferem; microcopy original.
- [ ] `adr-guardian`: PASS (ou ADR nova se `widget_to_marker` for adicionado).
- [ ] Smoke E2E no M54: golden path §Goals (rota desenhada + kebab Reotimizar funcionam).
- [ ] PR body preenchido; Vercel preview SUCCESS.
- [ ] PR → `develop` (NUNCA `main`).

## References

- `CLAUDE.md` — operating manual (dump-first ADR-0045, microcopy original ADR-0035).
- `docs/08-ROADMAP-v2.md` — Slice 2 / Área 7.
- `docs/superpowers/specs/2026-06-13-area7-optimize-route-design.md` — design doc da Á7 (PR-A/B/C/D).
- `docs/superpowers/plans/2026-06-14-area7-pr-b1-preconfirm-structure.md` — o B1 que o B2 continua.
- Dump-first 2026-06-14 (relatório `spoke-parity-checker`): `MapController`/`MapController$markerPolylineFlow$2`, `map/polylines/{PolylineGroup,PolylineThickness,PolylinePriority}`, `map/labels/StopMarkerLabel` + `StopMarkerLabelContext` + `StopMarkerLabelOverlayKt`, `map/toolbars/{MapToolbarMode,MapToolbarFabMode}` + `MapToolbarControlsController`/`State`, `AbstractC3736v.l0`/`AbstractC3737w.f`/`AbstractC4115a.h`, `EditRouteViewModel AnonymousClass4`.
- Memória: [[lesson_googlemap_eats_gestures_use_column]], [[project_area7_prb1_execution_state]], [[lesson_spec_does_not_replace_reverifying_dump]], [[lesson_area7_refinar_vs_reotimizar_two_dialogs]].
- `prototipo/tokens.js` — cor da polyline + marker (token de marca).
- Context7: a consultar antes de decidir `widget_to_marker` vs. manual `dart:ui`.
