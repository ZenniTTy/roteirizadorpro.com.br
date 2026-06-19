# Área 7 PR-B2 — Mapa interativo (polyline + markers + kebab Reotimizar) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Desenhar a rota otimizada no mapa do PRE-CONFIRM (polyline ligando as paradas na ordem do solver + markers customizados por parada) e montar o kebab "Reotimizar rota..." que abre o `ReoptimizeOptionsSheet` já pronto.

**Architecture:** Polyline e markers são DERIVADOS do estado da rota ativa (`.select`, nunca rebuildam o mapa no drag do sheet). Polyline = 2 `Polyline` sobrepostos (contorno + interior) com `List<LatLng>` na ordem otimizada — só aparece quando `optimization == optimized`. Markers = `BitmapDescriptor.fromBytes()` desenhado via `dart:ui` `Canvas` (sem pacote, sem conflito de gesto — `Marker` nativo), cacheado por chave, entregue por um provider async. O kebab vive no PRE-CONFIRM e dispara `showReoptimizeOptionsSheet` → `optimize` → `applyOptimization` (mesmo padrão do `_onRefine` do B1).

**Tech Stack:** Flutter 3.44 / Dart 3.12, Riverpod 3 (`@riverpod` codegen), `google_maps_flutter` 2.x (já instalado), `dart:ui` (Canvas/PictureRecorder — sem dep nova). Microcopy PT-BR original (ADR-0010).

**Spec:** `docs/superpowers/specs/2026-06-14-area7-pr-b2-map-interactive.md` (Q1 manual-Canvas; Q3 sem ETA; Q4 kebab; Q5 polyline client-side).

---

## Fidelidade dump-first (regra desta fatia)

- **Polyline** = `PolylineGroup.Highlighted` do Spoke → cor da MARCA (token `prototipo/tokens.js`, NÃO a cor raw do Spoke), client-side entre `LatLng` na ordem otimizada, só em `optimization == optimized`.
- **Marker** mostra IDENTIFICAÇÃO da parada (o que o RotPro já tem: `deliveryId` ou número), **NÃO a hora estimada** (Q3 — ETA é Slice 3, o tempo local engana). O chip A1..AN do Spoke fica na LISTA, mas o marker do mapa precisa de ALGUM rótulo — usamos o `deliveryId` (já existe) ou o índice; decisão no Task 4 (default: `deliveryId ?? '${index+1}'`).
- **Kebab** "Reotimizar rota..." → abre `ReoptimizeOptionsSheet` (já pronto). Microcopy do item = original ("Reotimizar rota", sem reticências — o sheet abre inline).
- NÃO inventar FAB de reotimização no mapa (dump: não existe).

---

## File Structure (PR-B2)

**Domínio:**
- `apps/mobile/lib/features/routes/domain/route_geometry.dart` — NEW: helper puro `routePolylinePoints(List<Stop>) -> List<LatLng>` (ordem da lista).

**Apresentação / mapa:**
- `apps/mobile/lib/features/routes/presentation/widgets/stop_marker_bitmap.dart` — NEW: `Future<BitmapDescriptor> stopMarkerBitmap({required String label, required Color fill, required Color textColor, double devicePixelRatio})` — desenha o pino via `dart:ui` Canvas.
- `apps/mobile/lib/features/routes/state/route_map_markers_provider.dart` — NEW: `@riverpod` async que deriva `Set<Marker>` da rota ativa (gera/cacheia bitmaps).
- `apps/mobile/lib/features/routes/presentation/route_shell_page.dart` — MOD: o `GoogleMap` recebe `polylines:` (derivado, 2 sobrepostos) + `markers:` (do provider); o PRE-CONFIRM ganha um kebab → `_onReoptimize`.

**ADR:** nenhuma (sem dep nova — `dart:ui` + `google_maps_flutter` já instalado).

---

## Task 1: `routePolylinePoints` (geometria pura)

**Files:**
- Create: `apps/mobile/lib/features/routes/domain/route_geometry.dart`
- Test: `apps/mobile/test/features/routes/domain/route_geometry_test.dart`

- [ ] **Step 1: Escrever o teste que falha**

```dart
// apps/mobile/test/features/routes/domain/route_geometry_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:roteirizador_pro/features/routes/domain/route_geometry.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';

Stop _stop(String id, double lat, double lng) =>
    Stop(id: id, lat: lat, lng: lng, streetName: id, fullAddress: id);

void main() {
  test('mapeia stops para LatLng na ordem da lista', () {
    final pts = routePolylinePoints([
      _stop('a', -23.5, -46.6),
      _stop('b', -23.4, -46.5),
    ]);
    expect(pts, [const LatLng(-23.5, -46.6), const LatLng(-23.4, -46.5)]);
  });

  test('lista vazia => vazio; 1 stop => 1 ponto', () {
    expect(routePolylinePoints([]), isEmpty);
    expect(routePolylinePoints([_stop('a', 1, 2)]), [const LatLng(1, 2)]);
  });

  test('ignora stops marcados pendingRemoval (saem na próxima otimização)', () {
    final pts = routePolylinePoints([
      _stop('a', 1, 2),
      _stop('b', 3, 4).copyWith(pendingRemoval: true),
    ]);
    expect(pts, [const LatLng(1, 2)]);
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `cd apps/mobile && flutter test test/features/routes/domain/route_geometry_test.dart`
Expected: FAIL — `route_geometry.dart` não existe.

- [ ] **Step 3: Implementar**

```dart
// apps/mobile/lib/features/routes/domain/route_geometry.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'stop.dart';

/// Pontos da polyline da rota otimizada: um `LatLng` por parada ATIVA, na ordem
/// da lista (que já é a ordem do solver). Paradas marcadas `pendingRemoval`
/// (G5 — saem na próxima otimização) não entram na linha. Client-side: retas
/// entre pontos (espelha o `markerPolylineFlow` do Spoke; curva de routing real
/// é Slice 3).
List<LatLng> routePolylinePoints(List<Stop> stops) => [
      for (final s in stops)
        if (!s.pendingRemoval) LatLng(s.lat, s.lng),
    ];
```

- [ ] **Step 4: Rodar e ver passar**

Run: `cd apps/mobile && flutter test test/features/routes/domain/route_geometry_test.dart`
Expected: PASS (3 testes).

- [ ] **Step 5: Commit (da RAIZ)**

```bash
git add apps/mobile/lib/features/routes/domain/route_geometry.dart apps/mobile/test/features/routes/domain/route_geometry_test.dart
git commit -m "feat(routes): routePolylinePoints (geometria da rota) (Á7 PR-B2)"
```

---

## Task 2: Polyline no shell (derivada do estado)

**Files:**
- Modify: `apps/mobile/lib/features/routes/presentation/route_shell_page.dart`
- Test: `apps/mobile/test/features/routes/presentation/widgets/route_shell_polyline_test.dart`

- [ ] **Step 1: Escrever o teste que falha**

O switch de estado já existe (`isPreConfirm`). O teste pina a REGRA pública via helper mínimo: em PRE-CONFIRM a polyline é não-vazia, em DRAFT é vazia. Como o `GoogleMap` real não é testável em widget test (PlatformView), testamos a FUNÇÃO PURA que monta o `Set<Polyline>`.

Primeiro extraia a montagem para uma função testável `buildRoutePolylines(List<LatLng> points, {required Color fill, required Color border})` em `route_geometry.dart` (Task 1 host) — adicione ao teste de geometria:

```dart
// adicionar em route_geometry_test.dart
import 'package:flutter/material.dart' show Colors;

  test('buildRoutePolylines: vazio quando <2 pontos; 2 sobrepostos quando >=2', () {
    expect(buildRoutePolylines([], fill: Colors.blue, border: Colors.black), isEmpty);
    expect(
      buildRoutePolylines([const LatLng(0, 0)], fill: Colors.blue, border: Colors.black),
      isEmpty,
    );
    final pl = buildRoutePolylines(
      [const LatLng(0, 0), const LatLng(1, 1)],
      fill: Colors.blue,
      border: Colors.black,
    );
    expect(pl, hasLength(2)); // outer (border) + inner (fill)
    final ids = pl.map((p) => p.polylineId.value).toSet();
    expect(ids, {'route_outer', 'route_inner'});
    // inner mais à frente (zIndex maior) e mais fino que outer
    final inner = pl.firstWhere((p) => p.polylineId.value == 'route_inner');
    final outer = pl.firstWhere((p) => p.polylineId.value == 'route_outer');
    expect(inner.zIndex, greaterThan(outer.zIndex));
    expect(inner.width, lessThan(outer.width));
  });
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `cd apps/mobile && flutter test test/features/routes/domain/route_geometry_test.dart`
Expected: FAIL — `buildRoutePolylines` não existe.

- [ ] **Step 3: Implementar `buildRoutePolylines` em `route_geometry.dart`**

```dart
// adicionar a apps/mobile/lib/features/routes/domain/route_geometry.dart
import 'package:flutter/widgets.dart' show Color;

/// Monta a polyline da rota como DOIS traços sobrepostos: `route_outer`
/// (borda, mais espessa, atrás) + `route_inner` (preenchimento, mais fina, à
/// frente) — replica o efeito `borderBrandEmphasis` do Spoke (inner+outer).
/// Vazio com < 2 pontos (uma linha precisa de 2 pontas).
Set<Polyline> buildRoutePolylines(
  List<LatLng> points, {
  required Color fill,
  required Color border,
}) {
  if (points.length < 2) return const {};
  return {
    Polyline(
      polylineId: const PolylineId('route_outer'),
      points: points,
      color: border,
      width: 7,
      zIndex: 0,
    ),
    Polyline(
      polylineId: const PolylineId('route_inner'),
      points: points,
      color: fill,
      width: 4,
      zIndex: 1,
    ),
  };
}
```

(O import de `Color` via `package:flutter/widgets.dart` mantém o domínio sem material; `Polyline`/`LatLng` já vêm do `google_maps_flutter` importado no topo.)

- [ ] **Step 4: Rodar e ver passar**

Run: `cd apps/mobile && flutter test test/features/routes/domain/route_geometry_test.dart`
Expected: PASS (4 testes).

- [ ] **Step 5: Wire no shell**

Em `route_shell_page.dart`, no `build` do `_RouteShellPageState`, perto do `isPreConfirm`/`activeMetrics` (que já existem do B1), derivar os pontos e as polylines:

```dart
// imports no topo (se faltarem):
import '../domain/route_geometry.dart';
// (google_maps_flutter já importado)

// no build, após `final isPreConfirm = ...`:
final routePolylines = isPreConfirm
    ? buildRoutePolylines(
        routePolylinePoints(stops),
        fill: AppColors.primary,
        border: AppColors.bg, // contorno claro p/ contraste sobre o mapa
      )
    : const <Polyline>{};
```

E no widget `GoogleMap` (procurar `GoogleMap(` no arquivo), adicionar o parâmetro:

```dart
              child: GoogleMap(
                mapType: mapType,
                initialCameraPosition: _initialPosition,
                polylines: routePolylines,   // <-- ADICIONAR
                // ... resto inalterado
```

- [ ] **Step 6: Escrever o teste de regra do shell (função pura, não o GoogleMap)**

```dart
// apps/mobile/test/features/routes/presentation/widgets/route_shell_polyline_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:roteirizador_pro/features/routes/domain/route_geometry.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';

// O GoogleMap (PlatformView) não roda em widget test. Pinamos a REGRA que o
// shell aplica: PRE-CONFIRM (otimizado) → polyline não-vazia; DRAFT → vazia.
// Isso replica a expressão `isPreConfirm ? buildRoutePolylines(...) : {}` do shell.
Stop _stop(String id, double lat, double lng) =>
    Stop(id: id, lat: lat, lng: lng, streetName: id, fullAddress: id);

Set<Polyline> _shellPolylines({required bool isPreConfirm, required List<Stop> stops}) =>
    isPreConfirm
        ? buildRoutePolylines(
            routePolylinePoints(stops),
            fill: Colors.blue,
            border: Colors.white,
          )
        : const {};

void main() {
  final stops = [_stop('a', -23.5, -46.6), _stop('b', -23.4, -46.5)];

  test('PRE-CONFIRM → polyline não-vazia', () {
    expect(_shellPolylines(isPreConfirm: true, stops: stops), isNotEmpty);
  });

  test('DRAFT → polyline vazia', () {
    expect(_shellPolylines(isPreConfirm: false, stops: stops), isEmpty);
  });
}
```

- [ ] **Step 7: Codegen não necessário (sem @riverpod novo). Rodar analyze + testes**

Run: `cd apps/mobile && flutter analyze --no-pub lib/features/routes/presentation/route_shell_page.dart lib/features/routes/domain/route_geometry.dart test/features/routes/presentation/widgets/route_shell_polyline_test.dart && flutter test test/features/routes/domain/route_geometry_test.dart test/features/routes/presentation/widgets/route_shell_polyline_test.dart`
Expected: analyze sem lint novo; PASS.

- [ ] **Step 8: Commit (da RAIZ)**

```bash
git add apps/mobile/lib/features/routes/domain/route_geometry.dart apps/mobile/lib/features/routes/presentation/route_shell_page.dart apps/mobile/test/features/routes/domain/route_geometry_test.dart apps/mobile/test/features/routes/presentation/widgets/route_shell_polyline_test.dart
git commit -m "feat(routes): polyline da rota otimizada no mapa do PRE-CONFIRM (Á7 PR-B2)"
```

---

## Task 3: `stopMarkerBitmap` (pino via dart:ui Canvas)

**Files:**
- Create: `apps/mobile/lib/features/routes/presentation/widgets/stop_marker_bitmap.dart`
- Test: `apps/mobile/test/features/routes/presentation/widgets/stop_marker_bitmap_test.dart`

- [ ] **Step 1: Escrever o teste que falha**

O teste verifica que a função retorna um `BitmapDescriptor` válido (bytes não-vazios) para um label — não compara pixels (frágil). Usa `TestWidgetsFlutterBinding`.

```dart
// apps/mobile/test/features/routes/presentation/widgets/stop_marker_bitmap_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/stop_marker_bitmap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('gera um BitmapDescriptor para o label', () async {
    final d = await stopMarkerBitmap(
      label: 'A1',
      fill: Colors.blue,
      textColor: Colors.white,
    );
    expect(d, isA<BitmapDescriptor>());
  });

  test('labels diferentes geram bitmaps (não lança)', () async {
    final a = await stopMarkerBitmap(label: 'A1', fill: Colors.blue, textColor: Colors.white);
    final b = await stopMarkerBitmap(label: 'A10', fill: Colors.blue, textColor: Colors.white);
    expect(a, isA<BitmapDescriptor>());
    expect(b, isA<BitmapDescriptor>());
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `cd apps/mobile && flutter test test/features/routes/presentation/widgets/stop_marker_bitmap_test.dart`
Expected: FAIL — arquivo não existe.

- [ ] **Step 3: Implementar**

```dart
// apps/mobile/lib/features/routes/presentation/widgets/stop_marker_bitmap.dart
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Desenha o pino da parada (balão arredondado + label centrado) via `dart:ui`
/// Canvas e devolve um [BitmapDescriptor] p/ um `Marker` NATIVO do
/// google_maps_flutter (sem overlay em Stack — o gesto fica com o mapa; ver
/// lesson_googlemap_eats_gestures_use_column). Pipeline oficial confirmado via
/// Context7 (/flutter/website): PictureRecorder → Canvas → Picture.toImage →
/// toByteData(png) → BitmapDescriptor.fromBytes. SEM pacote, SEM dep nova.
///
/// O label é a IDENTIFICAÇÃO da parada (deliveryId/índice) — NÃO a hora
/// estimada (ETA é Slice 3, o tempo local engana — spec Q3).
Future<BitmapDescriptor> stopMarkerBitmap({
  required String label,
  required Color fill,
  required Color textColor,
  double devicePixelRatio = 3.0,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // Layout do texto (paragraph) p/ medir e centrar.
  final fontSize = 14.0 * devicePixelRatio;
  final padding = 8.0 * devicePixelRatio;
  final paragraphBuilder = ui.ParagraphBuilder(
    ui.ParagraphStyle(textAlign: TextAlign.center, fontSize: fontSize),
  )
    ..pushStyle(ui.TextStyle(color: textColor, fontWeight: FontWeight.w700))
    ..addText(label);
  final paragraph = paragraphBuilder.build()
    ..layout(const ui.ParagraphConstraints(width: double.infinity));

  final textW = paragraph.maxIntrinsicWidth;
  final textH = paragraph.height;
  final w = textW + padding * 2;
  final h = textH + padding * 2;
  final r = Radius.circular(h / 2);

  // Balão.
  canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), r),
    Paint()..color = fill,
  );
  // Texto centrado.
  canvas.drawParagraph(paragraph, Offset(padding, padding));

  final picture = recorder.endRecording();
  final image = await picture.toImage(w.ceil(), h.ceil());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
}
```

> **Nota de versão (verificar via Dart MCP no Step 4):** `BitmapDescriptor.bytes(...)` é a API atual (substituiu `fromBytes` deprecado nas versões recentes do `google_maps_flutter`). Se o analyzer reclamar, trocar por `BitmapDescriptor.fromBytes(...)`. CONFIRMAR a assinatura real instalada com o Dart MCP (`resolve_symbol BitmapDescriptor`) antes de assumir — é o tipo de drift pós-cutoff que a precedência Dart-MCP-first existe para pegar.

- [ ] **Step 4: Confirmar a API + rodar e ver passar**

Run: `cd apps/mobile && flutter analyze --no-pub lib/features/routes/presentation/widgets/stop_marker_bitmap.dart && flutter test test/features/routes/presentation/widgets/stop_marker_bitmap_test.dart`
Expected: analyze sem erro (se `BitmapDescriptor.bytes` não existir, usar `.fromBytes` e re-rodar); PASS (2 testes).

- [ ] **Step 5: Commit (da RAIZ)**

```bash
git add apps/mobile/lib/features/routes/presentation/widgets/stop_marker_bitmap.dart apps/mobile/test/features/routes/presentation/widgets/stop_marker_bitmap_test.dart
git commit -m "feat(routes): stopMarkerBitmap (pino via dart:ui Canvas) (Á7 PR-B2)"
```

---

## Task 4: `routeMapMarkersProvider` (Set<Marker> derivado, cacheado)

**Files:**
- Create: `apps/mobile/lib/features/routes/state/route_map_markers_provider.dart`
- Test: `apps/mobile/test/features/routes/state/route_map_markers_provider_test.dart`

- [ ] **Step 1: Escrever o teste que falha**

```dart
// apps/mobile/test/features/routes/state/route_map_markers_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';
import 'package:roteirizador_pro/features/routes/state/active_route_provider.dart';
import 'package:roteirizador_pro/features/routes/state/route_map_markers_provider.dart';
import 'package:roteirizador_pro/features/routes/state/routes_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Stop _stop(String id) =>
      Stop(id: id, lat: -23.5, lng: -46.6, streetName: id, fullAddress: id);

  test('sem rota ativa => vazio', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final markers = await c.read(routeMapMarkersProvider.future);
    expect(markers, isEmpty);
  });

  test('rota ativa com N stops => N markers', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final notifier = c.read(routesProvider.notifier);
    final id = notifier.createRoute(date: DateTime(2026, 6, 14));
    notifier.addStop(id, _stop('a'));
    notifier.addStop(id, _stop('b'));
    c.read(activeRouteIdProvider.notifier).setActiveRoute(id);

    final markers = await c.read(routeMapMarkersProvider.future);
    expect(markers, hasLength(2));
  });

  test('ignora pendingRemoval', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final notifier = c.read(routesProvider.notifier);
    final id = notifier.createRoute(date: DateTime(2026, 6, 14));
    notifier.addStop(id, _stop('a'));
    notifier.addStop(id, _stop('b'));
    c.read(activeRouteIdProvider.notifier).setActiveRoute(id);
    notifier.markStopForDeferredRemoval(id, 'b');

    final markers = await c.read(routeMapMarkersProvider.future);
    expect(markers, hasLength(1));
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `cd apps/mobile && flutter test test/features/routes/state/route_map_markers_provider_test.dart`
Expected: FAIL — provider não existe.

- [ ] **Step 3: Implementar**

```dart
// apps/mobile/lib/features/routes/state/route_map_markers_provider.dart
import 'package:flutter/material.dart' show Colors;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/theme/app_theme.dart';
import '../presentation/widgets/stop_marker_bitmap.dart';
import 'active_route_provider.dart';
import 'routes_provider.dart';

part 'route_map_markers_provider.g.dart';

/// `Set<Marker>` da rota ativa (um por parada ATIVA, na ordem). Cada marker usa
/// um bitmap desenhado via `dart:ui` (cacheado por label dentro de um build).
/// O label é a identificação da parada (`deliveryId` ou índice 1..N) — NÃO a
/// hora (ETA é Slice 3, spec Q3). Vazio quando não há rota ativa.
@riverpod
Future<Set<Marker>> routeMapMarkers(Ref ref) async {
  final id = ref.watch(activeRouteIdProvider);
  if (id == null) return const {};
  final route =
      ref.watch(routesProvider).where((r) => r.id == id).firstOrNull;
  if (route == null) return const {};

  final active = [
    for (final s in route.stops)
      if (!s.pendingRemoval) s,
  ];

  final cache = <String, BitmapDescriptor>{};
  final markers = <Marker>{};
  for (var i = 0; i < active.length; i++) {
    final s = active[i];
    final label = s.deliveryId ?? '${i + 1}';
    final icon = cache[label] ??= await stopMarkerBitmap(
      label: label,
      fill: AppColors.primary,
      textColor: Colors.white,
    );
    markers.add(
      Marker(
        markerId: MarkerId(s.id),
        position: LatLng(s.lat, s.lng),
        icon: icon,
        anchor: const Offset(0.5, 0.5),
      ),
    );
  }
  return markers;
}
```

- [ ] **Step 4: Codegen + rodar e ver passar**

Run: `cd apps/mobile && dart run build_runner build --delete-conflicting-outputs && flutter test test/features/routes/state/route_map_markers_provider_test.dart`
Expected: PASS (3 testes).

- [ ] **Step 5: Commit (da RAIZ — sem o .g.dart, que é gitignored)**

```bash
git add apps/mobile/lib/features/routes/state/route_map_markers_provider.dart apps/mobile/test/features/routes/state/route_map_markers_provider_test.dart
git commit -m "feat(routes): routeMapMarkersProvider (Set<Marker> da rota ativa) (Á7 PR-B2)"
```

---

## Task 5: Markers no shell (consumir o provider)

**Files:**
- Modify: `apps/mobile/lib/features/routes/presentation/route_shell_page.dart`

- [ ] **Step 1: Wire (sem teste novo — a regra é coberta pelo provider test da Task 4)**

No `build` do `_RouteShellPageState`, ler os markers (async, sem bloquear o mapa):

```dart
// imports (se faltarem):
import '../state/route_map_markers_provider.dart';

// no build, perto do routePolylines:
final routeMarkers =
    ref.watch(routeMapMarkersProvider).valueOrNull ?? const <Marker>{};
```

E no `GoogleMap`, adicionar:

```dart
                polylines: routePolylines,
                markers: routeMarkers,   // <-- ADICIONAR
```

> **Por que sem teste de widget aqui:** o `GoogleMap` é PlatformView (não renderiza em widget test). A lógica (N stops → N markers, ignora pendingRemoval) já está pinada no provider test (Task 4). O wire em si (passar o Set ao GoogleMap) é validado no smoke E2E do M54 (Task 7). Cobrir o wire com um teste que mocka o PlatformView seria teste-de-mock sem valor.

- [ ] **Step 2: Analyze**

Run: `cd apps/mobile && flutter analyze --no-pub lib/features/routes/presentation/route_shell_page.dart`
Expected: sem lint novo.

- [ ] **Step 3: Commit (da RAIZ)**

```bash
git add apps/mobile/lib/features/routes/presentation/route_shell_page.dart
git commit -m "feat(routes): markers da rota no mapa do PRE-CONFIRM (Á7 PR-B2)"
```

---

## Task 6: Kebab "Reotimizar rota..." no PRE-CONFIRM

**Files:**
- Modify: `apps/mobile/lib/features/routes/presentation/widgets/pre_confirm_view.dart`
- Modify: `apps/mobile/lib/features/routes/presentation/route_shell_page.dart`
- Test: `apps/mobile/test/features/routes/presentation/widgets/pre_confirm_kebab_test.dart`

- [ ] **Step 1: Ler o EditRouteFragment$Content no dump p/ a posição do kebab**

Run: `grep -rn "more_options\|overflow\|MoreVert\|kebab" ~/spoke-dump/jadx-out/sources/com/circuit/p016ui/home/editroute/EditRouteFragment*.java | head`. CONFIRMAR: o kebab do PRE-CONFIRM fica no topo da tela (toolbar do sheet). Decisão de implementação: adicionar um `onReoptimize` callback opcional ao `PreConfirmView` + um ícone kebab no header da `PreConfirmView` (acima do summary). Se o dump mostrar posição diferente, ajustar.

- [ ] **Step 2: Escrever o teste que falha**

```dart
// apps/mobile/test/features/routes/presentation/widgets/pre_confirm_kebab_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/pre_confirm_view.dart';

Stop _stop(String id) => Stop(
      id: id, lat: 0, lng: 0, streetName: id, fullAddress: id, deliveryId: 'A1',
    );

void main() {
  testWidgets('mostra o kebab "Reotimizar"; tap dispara onReoptimize', (tester) async {
    var reoptimized = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PreConfirmView(
            stops: [_stop('a')],
            durationMinutes: 5,
            distanceMeters: 800,
            onRefine: () {},
            onConfirm: () {},
            onStopTap: (_) {},
            onReoptimize: () => reoptimized = true,
          ),
        ),
      ),
    );
    final kebab = find.bySemanticsLabel('Opções da rota');
    expect(kebab, findsOneWidget);
    await tester.tap(kebab);
    expect(reoptimized, isTrue);
  });
}
```

- [ ] **Step 3: Rodar e ver falhar**

Run: `cd apps/mobile && flutter test test/features/routes/presentation/widgets/pre_confirm_kebab_test.dart`
Expected: FAIL — `onReoptimize` não é parâmetro de `PreConfirmView`.

- [ ] **Step 4: Adicionar `onReoptimize` ao `PreConfirmView`**

Em `pre_confirm_view.dart`: adicionar o campo `final VoidCallback onReoptimize;` ao construtor (required), e um `IconButton` kebab no header (antes do `RouteSummaryRow`):

```dart
// no construtor, após onStopTap:
    required this.onReoptimize,

// campo:
  final VoidCallback onReoptimize;

// no build, ANTES do RouteSummaryRow no Column children:
        Align(
          alignment: Alignment.centerRight,
          child: Semantics(
            label: 'Opções da rota',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: onReoptimize,
            ),
          ),
        ),
```

- [ ] **Step 5: Rodar e ver passar**

Run: `cd apps/mobile && flutter test test/features/routes/presentation/widgets/pre_confirm_kebab_test.dart`
Expected: PASS.

- [ ] **Step 6: `_onReoptimize` no shell + passar ao PreConfirmView**

Em `route_shell_page.dart`, adicionar o handler (espelha `_onRefine` do B1):

```dart
// imports (se faltarem):
import 'widgets/reoptimize_options_sheet.dart';

  /// Kebab "Reotimizar rota..." do PRE-CONFIRM → sheet {Atualizar / Recalcular}.
  /// `update` reordena só o que mudou (reorderFlexible); `reoptimize` recalcula
  /// do zero (restartRoute). Espelha o `_onRefine` (mesmo tratamento de erro).
  Future<void> _onReoptimize() async {
    final choice = await showReoptimizeOptionsSheet(context);
    if (!mounted || choice == null) return;
    final routeId = ref.read(activeRouteIdProvider);
    if (routeId == null) return;
    final stops = ref.read(currentRouteStopsProvider);
    if (stops.isEmpty) return;
    final type = switch (choice) {
      ReoptimizeChoice.update => OptimizeType.reorderFlexible,
      ReoptimizeChoice.reoptimize => OptimizeType.restartRoute,
    };
    final outcome =
        await ref.read(optimizationControllerProvider.notifier).optimize(
              start: GeoPoint(stops.first.lat, stops.first.lng),
              stops: stops,
              type: type,
            );
    if (!mounted) return;
    switch (outcome) {
      case OptimizationSuccess(:final result):
        ref.read(routesProvider.notifier).applyOptimization(routeId, result);
      case OptimizationFailure():
        final retry = await showOptimizationErrorDialog(context);
        if (!mounted) return;
        if (retry == OptimizationErrorChoice.retry) await _onReoptimize();
      case NotEnoughStops():
        await showNotEnoughStopsDialog(context);
    }
  }
```

E no ponto onde o `PreConfirmView` é montado (no switch `isPreConfirm` do build, B1), adicionar `onReoptimize: _onReoptimize,`.

- [ ] **Step 7: Codegen não necessário. Analyze + testes**

Run: `cd apps/mobile && flutter analyze --no-pub lib/features/routes/presentation/widgets/pre_confirm_view.dart lib/features/routes/presentation/route_shell_page.dart && flutter test test/features/routes/presentation/widgets/pre_confirm_kebab_test.dart test/features/routes/presentation/widgets/pre_confirm_view_test.dart`
Expected: analyze sem lint novo; PASS (incl. o pre_confirm_view_test existente — pode precisar adicionar `onReoptimize: () {}` aos pumps existentes; SE quebrar, adicionar o param aos testes do B1).

- [ ] **Step 8: Corrigir os testes do B1 que constroem PreConfirmView (param novo obrigatório)**

`onReoptimize` é `required` → todos os `PreConfirmView(...)` nos testes existentes (`pre_confirm_view_test.dart`, `route_shell_preconfirm_test.dart`) precisam de `onReoptimize: () {},`. Rodar a suite inteira p/ achar os call-sites:

Run: `cd apps/mobile && flutter test 2>&1 | grep -i "pre_confirm\|onReoptimize" | head`
Adicionar `onReoptimize: () {},` em cada construtor que faltar.

- [ ] **Step 9: Commit (da RAIZ)**

```bash
git add apps/mobile/lib/features/routes/presentation/widgets/pre_confirm_view.dart apps/mobile/lib/features/routes/presentation/route_shell_page.dart apps/mobile/test/features/routes/presentation/widgets/pre_confirm_kebab_test.dart apps/mobile/test/features/routes/presentation/widgets/pre_confirm_view_test.dart apps/mobile/test/features/routes/presentation/widgets/route_shell_preconfirm_test.dart
git commit -m "feat(routes): kebab Reotimizar no PRE-CONFIRM → ReoptimizeOptionsSheet (Á7 PR-B2)"
```

---

## Task 7: Gates do PR-B2 + abrir o PR

**Files:** (verificação)

- [ ] **Step 1: Suite + analyze completos**

Run: `cd apps/mobile && flutter analyze && flutter test`
Expected: analyze sem lint NOVO (baseline pré-existente); suite verde (670 + novos).

- [ ] **Step 2: Dispatch `flutter-perf-auditor`**

Sobre os arquivos novos (`route_geometry.dart`, `stop_marker_bitmap.dart`, `route_map_markers_provider.dart`) + o delta do shell. Foco: o `routeMapMarkersProvider` async não rebuilda o mapa por frame; a polyline/markers usam o estado via `.select` (não no drag). Bitmap cacheado por label. Resolver must-fix.

- [ ] **Step 3: Dispatch `spoke-parity-checker` D4 dump-only**

Comparar contra o baseline do mapa (`PolylineGroup`, `StopMarkerLabel`, kebab `more_options_reoptimize_route_title`). Confirmar: (a) polyline só em otimizado; (b) marker NÃO mostra hora (Q3); (c) kebab abre o sheet certo; (d) microcopy original. 0 must-fix p/ merge.

- [ ] **Step 4: Smoke E2E no M54 (mapa só se valida no device)**

Build debug no M54 (`flutter run -d <device-id>` ou o script). Golden path §Goals: otimizar → ver polyline + markers → kebab Reotimizar → Recalcular → polyline redesenha. Screenshot. (NÃO bloquear num integration_test que deadlocka com GoogleMap — risco declarado na spec; smoke manual/Maestro é o gate.)

- [ ] **Step 5: Atualizar TODO + CHANGELOG + session log**

`TODO.md` §Á7: marcar PR-B2 entregue + débito (ETA Slice 3; polyline reta Slice 3; tamanho marker por zoom + Highlighted ao toque = should-fix adiado). `docs/10-CHANGELOG.md` + session log.

- [ ] **Step 6: Commit docs + push + abrir PR**

```bash
git add TODO.md docs/
git commit -m "docs: Á7 PR-B2 — TODO + CHANGELOG + session log"
git push -u origin feat/m2-slice-2-area-7-pr-b2
gh pr create --base develop --title "feat(routes): Área 7 PR-B2 — mapa interativo (polyline + markers + kebab Reotimizar)" --body "<resumo + débito + gates>"
```

---

## Self-review (writing-plans)

**Cobertura da spec (PR-B2):** polyline Highlighted client-side ✅(T1/T2) · só em otimizado ✅(T2 regra) · markers via dart:ui Canvas ✅(T3) · Set<Marker> derivado cacheado ✅(T4) · markers no shell ✅(T5) · kebab→ReoptimizeOptionsSheet ✅(T6) · sem ETA no marker ✅(T3/T4 usam label de id, não hora) · gates+device ✅(T7). **Non-goals respeitados:** ETA (Slice 3), Ready-to-Run (PR-C), OrderStopGroups (PR-D), polyline curva (Slice 3), tamanho-por-zoom + Highlighted (should-fix adiado).

**Placeholders:** nenhum "TBD"; cada task tem código completo. A nota da Task 3 Step 3 (`BitmapDescriptor.bytes` vs `.fromBytes`) é uma verificação de API real via Dart MCP, não placeholder — o código default está escrito, com o fallback explícito.

**Consistência de tipos:** `routePolylinePoints`/`buildRoutePolylines` (T1/T2) consumidos no shell (T2 Step5) e no teste (T2 Step6). `stopMarkerBitmap` (T3) consumido pelo provider (T4). `routeMapMarkersProvider` (T4) consumido no shell (T5). `onReoptimize`/`_onReoptimize`/`showReoptimizeOptionsSheet`/`ReoptimizeChoice{update,reoptimize}` (T6) — os enums batem com o widget do B1. `OptimizeType{reorderFlexible,restartRoute}` reusados do PR-A.

**Risco conhecido reiterado:** GoogleMap × integration_test deadlock (Á5 MS9) → o gate do mapa é smoke E2E manual/Maestro no M54, NÃO integration_test (declarado T7 Step4 + spec §Risks).
