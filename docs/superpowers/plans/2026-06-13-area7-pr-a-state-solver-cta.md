# Área 7 — PR-A (estado + solver + CTA Otimizar + progresso) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Entregar a primeira fatia da Área 7 (Otimizar rota): o modelo de estado fiel ao Spoke (`RouteState` + enums), o solver on-device em Dart, o CTA "Otimizar rota" sticky no rodapé do shell, a tela de progresso (4 fases) e os dois diálogos de erro (rede + poucas paradas).

**Architecture:** Domínio puro primeiro (enums + `RouteState` + `RouteOptimizer`/`LocalRouteOptimizer`, testáveis sem UI nem device), depois o `OptimizationController` (`@riverpod`), depois a UI (CTA + progresso + diálogos). O solver fica atrás da interface `RouteOptimizer` para o Slice 3 trocar por GraphHopper sem tocar a UI. Migração do `enum RouteStatus { draft, running, completed }` (4 valores, hoje em `route.dart`) para o `RouteState` (flags+timestamps) é localizada — os consumidores são o seed e os helpers do `routes_provider.dart`.

**Tech Stack:** Flutter 3.44 / Dart 3.12, Riverpod 3 (`@riverpod` codegen), `geolocator ^14.0.2` (já instalado, `Geolocator.distanceBetween`), `mocktail` (só onde precisar de verify), fakes manuais em `test/.../\_helpers/` como default.

**Spec:** `docs/superpowers/specs/2026-06-13-area7-optimize-route-design.md` (esta plan implementa o PR-A da §Sub-slice plan).

---

## File Structure (PR-A)

**Domínio (puro, testável sem UI):**
- `lib/features/routes/domain/optimization_state.dart` — NEW: `enum OptimizationState { creating, optimized, editing }`.
- `lib/features/routes/domain/optimize_type.dart` — NEW: `enum OptimizeType { restartRoute, reorderFlexible, skipReorder }`.
- `lib/features/routes/domain/optimize_direction.dart` — NEW: `enum OptimizeDirection { reverse }`.
- `lib/features/routes/domain/package_label_format.dart` — NEW: `enum PackageLabelFormat { moderno, classico }` + `String labelFor(int index)`.
- `lib/features/routes/domain/route_state.dart` — NEW: `RouteState` (flags+timestamps) + getters derivados.
- `lib/features/routes/domain/route.dart` — MOD: troca `RouteStatus` por `RouteState routeState` + métricas (`totalDurationMinutes`, `totalDistanceMeters`).
- `lib/features/routes/domain/stop.dart` — MOD: `+ bool pendingRemoval` (o `deliveryId` JÁ existe — só passa a ser populado).
- `lib/features/routes/domain/optimization/route_optimizer.dart` — NEW: interface `RouteOptimizer` + `RouteOptimizationResult`.
- `lib/features/routes/domain/optimization/local_route_optimizer.dart` — NEW: `LocalRouteOptimizer` (NN + 2-opt, Haversine injetável).

**Estado:**
- `lib/features/routes/state/routes_provider.dart` — MOD: seed + helpers migram de `RouteStatus` para `RouteState`.
- `lib/features/routes/state/optimization_controller.dart` — NEW: `@riverpod` orquestra o funil (guard de mínimo + progresso + chamada ao solver).

**Apresentação:**
- `lib/features/routes/presentation/widgets/optimize_cta.dart` — NEW: CTA sticky.
- `lib/features/routes/presentation/widgets/optimizing_progress_view.dart` — NEW: tela 4 fases.
- `lib/features/routes/presentation/widgets/optimization_error_dialog.dart` — NEW: erro de rede.
- `lib/features/routes/presentation/widgets/not_enough_stops_dialog.dart` — NEW: poucas paradas.
- `lib/features/routes/presentation/route_shell_page.dart` — MOD: monta o CTA no slot do rodapé (`:617`).

**ADR:**
- `docs/decisions/0051-route-lifecycle-and-on-device-solver.md` — NEW.

---

## Task 1: ADR-0051 (registra a decisão de stack antes do código)

**Files:**
- Create: `docs/decisions/0051-route-lifecycle-and-on-device-solver.md`

- [ ] **Step 1: Escrever a ADR**

Conteúdo (preencher os campos do template de ADR do repo — copiar a estrutura de `docs/decisions/0050-path-provider-local-package-photos.md`):

```markdown
# ADR-0051 — Route lifecycle (RouteState) + solver on-device Dart

## Status
Accepted (2026-06-13)

## Context
A Área 7 (Otimizar rota) precisa de (a) um modelo de lifecycle da rota com mais
estados que o `enum RouteStatus { draft, optimized, running, completed }` atual,
e (b) uma fonte de ordem otimizada + métricas, já que o backend real
(GraphHopper) é Slice 3. O dump do Spoke (`core/entity/RouteState.kt`,
`OptimizationState.kt`, `OptimizationRoutingSolver.kt`) prova que o Spoke usa
flags+timestamps ortogonais + um solver de backend plugável.

## Decision
1. Substituir `enum RouteStatus` por uma classe `RouteState` (flags+timestamps)
   espelhando o Spoke: `OptimizationState { creating, optimized, editing }` +
   `confirmed`/`started`/`optimizing`/`optimizationAcknowledged` + timestamps.
   O estado visual (PRE-CONFIRM/Ready-to-Run/erro) é DERIVADO por getters.
2. Otimização via interface `RouteOptimizer`; impl. do Slice 2 é
   `LocalRouteOptimizer` (nearest-neighbor + 2-opt, distância Haversine via
   `geolocator`). Slice 3 injeta `GraphHopperRouteOptimizer` via override de
   provider, sem tocar UI/estado.
3. Cortes: "Carregar veículo" (barcode/ML Kit) e "Compartilhar rota em tempo
   real" (backend) = botão fiel + "Em breve" → Slice 3. Gate "10 paradas/
   assinar" do Spoke NÃO é clonado (ADR-0030).

## Consequences
- `geolocator ^14.0.2` já está instalado; nenhuma dependência nova.
- A migração do enum toca o seed + helpers do `routes_provider.dart`
  (localizada). Sem `// TODO` de migração.
- O default do chip de ID é Moderno (escolha de produto; o fallback do Spoke é
  Clássico). O toggle Moderno/Clássico vive na Á10 (débito declarado).
```

- [ ] **Step 2: Commit**

```bash
git add docs/decisions/0051-route-lifecycle-and-on-device-solver.md
git commit -m "docs(adr): ADR-0051 route lifecycle + solver on-device (Área 7 PR-A)"
```

---

## Task 2: Enums de domínio (`OptimizationState`, `OptimizeType`, `OptimizeDirection`)

**Files:**
- Create: `lib/features/routes/domain/optimization_state.dart`
- Create: `lib/features/routes/domain/optimize_type.dart`
- Create: `lib/features/routes/domain/optimize_direction.dart`
- Test: `test/features/routes/domain/optimization_enums_test.dart`

- [ ] **Step 1: Escrever o teste que falha**

```dart
// test/features/routes/domain/optimization_enums_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/domain/optimization_state.dart';
import 'package:roteirizador_pro/features/routes/domain/optimize_type.dart';
import 'package:roteirizador_pro/features/routes/domain/optimize_direction.dart';

void main() {
  test('OptimizationState espelha o Spoke (3 valores, ordem CREATING/OPTIMIZED/EDITING)', () {
    expect(OptimizationState.values, [
      OptimizationState.creating,
      OptimizationState.optimized,
      OptimizationState.editing,
    ]);
  });

  test('OptimizeType cobre os modos do Spoke usados na Á7', () {
    expect(OptimizeType.values, containsAll([
      OptimizeType.restartRoute,
      OptimizeType.reorderFlexible,
      OptimizeType.skipReorder,
    ]));
  });

  test('OptimizeDirection tem reverse (Inverter a rota)', () {
    expect(OptimizeDirection.values, [OptimizeDirection.reverse]);
  });
}
```

- [ ] **Step 2: Rodar o teste e ver falhar**

Run: `cd apps/mobile && flutter test test/features/routes/domain/optimization_enums_test.dart`
Expected: FAIL — "Target of URI doesn't exist: '.../optimization_state.dart'" (arquivos não existem).

- [ ] **Step 3: Criar os três enums**

```dart
// lib/features/routes/domain/optimization_state.dart

/// Estado de otimização da rota — espelha `core/entity/OptimizationState.kt`
/// do Spoke v3.65.1 (CREATING/OPTIMIZED/EDITING). Ortogonal às flags
/// `confirmed`/`started` do [RouteState].
enum OptimizationState { creating, optimized, editing }
```

```dart
// lib/features/routes/domain/optimize_type.dart

/// Escopo de uma chamada ao solver — espelha `core/entity/OptimizeType.kt`
/// do Spoke. `restartRoute` recalcula do zero (Reotimizar), `reorderFlexible`
/// preserva a estrutura (Atualizar), `skipReorder` pula a otimização.
enum OptimizeType { restartRoute, reorderFlexible, skipReorder }
```

```dart
// lib/features/routes/domain/optimize_direction.dart

/// Direção opcional de uma chamada ao solver — espelha
/// `core/entity/OptimizeDirection.kt` do Spoke. `reverse` = "Inverter a rota"
/// (inverte a ordem sequencial das paradas).
enum OptimizeDirection { reverse }
```

- [ ] **Step 4: Rodar o teste e ver passar**

Run: `cd apps/mobile && flutter test test/features/routes/domain/optimization_enums_test.dart`
Expected: PASS (3 testes).

- [ ] **Step 5: Commit**

```bash
git add lib/features/routes/domain/optimization_state.dart lib/features/routes/domain/optimize_type.dart lib/features/routes/domain/optimize_direction.dart test/features/routes/domain/optimization_enums_test.dart
git commit -m "feat(routes): enums de otimização espelhando o Spoke (Á7 PR-A)"
```

---

## Task 3: `PackageLabelFormat` (gera o chip A1.. ou 1..)

**Files:**
- Create: `lib/features/routes/domain/package_label_format.dart`
- Test: `test/features/routes/domain/package_label_format_test.dart`

- [ ] **Step 1: Escrever o teste que falha**

```dart
// test/features/routes/domain/package_label_format_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/domain/package_label_format.dart';

void main() {
  test('moderno gera A1..A26, B1.. (letra por dezena + 1-based)', () {
    expect(PackageLabelFormat.moderno.labelFor(0), 'A1');
    expect(PackageLabelFormat.moderno.labelFor(9), 'A10');
    expect(PackageLabelFormat.moderno.labelFor(25), 'A26');
    expect(PackageLabelFormat.moderno.labelFor(26), 'B1');
  });

  test('classico gera número puro 1-based', () {
    expect(PackageLabelFormat.classico.labelFor(0), '1');
    expect(PackageLabelFormat.classico.labelFor(9), '10');
  });

  test('moderno é o default declarado da Á7', () {
    expect(PackageLabelFormat.defaultFormat, PackageLabelFormat.moderno);
  });
}
```

> **Nota de fidelidade (dump):** o Spoke (`domain/utils/C3003e.java:174-179`) gera
> Moderno como `letter(index % 26 + 65) + (index ~/ 26 + 1)` — ou seja a LETRA
> cicla a cada 26 e o número é 1-based dentro do bloco. Os casos do teste fixam
> esse comportamento (A1..A26 → B1).

- [ ] **Step 2: Rodar o teste e ver falhar**

Run: `cd apps/mobile && flutter test test/features/routes/domain/package_label_format_test.dart`
Expected: FAIL — arquivo não existe.

- [ ] **Step 3: Implementar**

```dart
// lib/features/routes/domain/package_label_format.dart

/// Formato do identificador de parada (chip "A1" vs "1"). Espelha
/// `PackageLabelFormat.kt` do Spoke {BASE/Clássico, MODERN/Moderno}. O Spoke
/// usa Clássico como fallback (`a4e.java:16`); o RotPro usa Moderno como
/// default por escolha de produto (mais legível para etiquetar pacotes). O
/// toggle Moderno/Clássico vive na Área 10 (ainda não feita).
enum PackageLabelFormat {
  moderno,
  classico;

  static const PackageLabelFormat defaultFormat = PackageLabelFormat.moderno;

  /// Rótulo 1-based para a parada na posição [index] (0-based) da ordem
  /// otimizada. Moderno: letra a cada 26 + número dentro do bloco
  /// (A1..A26, B1..). Clássico: número puro (1, 2, ...). Espelha
  /// `domain/utils/C3003e.java:165` (Clássico) e `:174-179` (Moderno).
  String labelFor(int index) {
    switch (this) {
      case PackageLabelFormat.classico:
        return '${index + 1}';
      case PackageLabelFormat.moderno:
        final letter = String.fromCharCode(65 + (index % 26));
        final number = index ~/ 26 + 1;
        return '$letter$number';
    }
  }
}
```

- [ ] **Step 4: Rodar o teste e ver passar**

Run: `cd apps/mobile && flutter test test/features/routes/domain/package_label_format_test.dart`
Expected: PASS (3 testes).

- [ ] **Step 5: Commit**

```bash
git add lib/features/routes/domain/package_label_format.dart test/features/routes/domain/package_label_format_test.dart
git commit -m "feat(routes): PackageLabelFormat moderno/clássico (Á7 PR-A, G6)"
```

---

## Task 4: `RouteState` (flags+timestamps + getters derivados)

**Files:**
- Create: `lib/features/routes/domain/route_state.dart`
- Test: `test/features/routes/domain/route_state_test.dart`

- [ ] **Step 1: Escrever o teste que falha**

```dart
// test/features/routes/domain/route_state_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/domain/optimization_state.dart';
import 'package:roteirizador_pro/features/routes/domain/route_state.dart';

void main() {
  test('default = DRAFT (creating, nada otimizado/confirmado/iniciado)', () {
    const s = RouteState();
    expect(s.optimization, OptimizationState.creating);
    expect(s.isDraft, isTrue);
    expect(s.isPreConfirm, isFalse);
    expect(s.isReadyToRun, isFalse);
    expect(s.isOptimizing, isFalse);
  });

  test('optimizing=true => isOptimizing (tela de progresso)', () {
    const s = RouteState(optimizing: true);
    expect(s.isOptimizing, isTrue);
    expect(s.isDraft, isFalse);
  });

  test('optimized && !confirmed => PRE-CONFIRM', () {
    const s = RouteState(optimization: OptimizationState.optimized);
    expect(s.isPreConfirm, isTrue);
    expect(s.isReadyToRun, isFalse);
  });

  test('optimized && confirmed && !started => READY-TO-RUN', () {
    const s = RouteState(
      optimization: OptimizationState.optimized,
      confirmed: true,
    );
    expect(s.isReadyToRun, isTrue);
    expect(s.isPreConfirm, isFalse);
  });

  test('editing (após mexer em rota otimizada) é distinto e zera otimização', () {
    const s = RouteState(optimization: OptimizationState.editing);
    expect(s.isEditing, isTrue);
    expect(s.isPreConfirm, isFalse);
    expect(s.isReadyToRun, isFalse);
  });

  test('optimizationErroredAt sem optimizing => hasOptimizationError', () {
    final s = RouteState(optimizationErroredAt: DateTime(2026, 6, 13));
    expect(s.hasOptimizationError, isTrue);
  });

  test('copyWith preserva campos omitidos e troca os passados', () {
    const base = RouteState();
    final next = base.copyWith(
      optimization: OptimizationState.optimized,
      confirmed: true,
    );
    expect(next.optimization, OptimizationState.optimized);
    expect(next.confirmed, isTrue);
    expect(next.started, isFalse); // omitido => preservado
  });
}
```

- [ ] **Step 2: Rodar o teste e ver falhar**

Run: `cd apps/mobile && flutter test test/features/routes/domain/route_state_test.dart`
Expected: FAIL — arquivo não existe.

- [ ] **Step 3: Implementar**

```dart
// lib/features/routes/domain/route_state.dart
import 'optimization_state.dart';

/// Lifecycle da rota — espelha `core/entity/RouteState.kt` do Spoke v3.65.1
/// (flags + timestamps ortogonais). O estado VISUAL (DRAFT/otimizando/
/// PRE-CONFIRM/Ready-to-Run/erro) é DERIVADO por getters, nunca armazenado.
/// Campos do `toString()` do Spoke: started/startedAt/optimizedAt/completed/
/// completedAt/optimization/optimizing/optimizationErroredAt/
/// optimizationAttemptedAt/optimizationAcknowledged/confirmed.
class RouteState {
  const RouteState({
    this.optimization = OptimizationState.creating,
    this.optimizing = false,
    this.optimizationAcknowledged = false,
    this.confirmed = false,
    this.started = false,
    this.completed = false,
    this.optimizedAt,
    this.optimizationErroredAt,
    this.optimizationAttemptedAt,
  });

  final OptimizationState optimization;
  final bool optimizing;
  final bool optimizationAcknowledged;
  final bool confirmed;
  final bool started;
  final bool completed;
  final DateTime? optimizedAt;
  final DateTime? optimizationErroredAt;
  final DateTime? optimizationAttemptedAt;

  // Estado visual derivado (switch exaustivo na UI usa estes getters).
  bool get isDraft =>
      optimization == OptimizationState.creating && !optimizing && !started;
  bool get isOptimizing => optimizing;
  bool get isPreConfirm =>
      optimization == OptimizationState.optimized && !confirmed && !started;
  bool get isReadyToRun =>
      optimization == OptimizationState.optimized && confirmed && !started;
  bool get isEditing => optimization == OptimizationState.editing;
  bool get hasOptimizationError =>
      optimizationErroredAt != null && !optimizing;

  RouteState copyWith({
    OptimizationState? optimization,
    bool? optimizing,
    bool? optimizationAcknowledged,
    bool? confirmed,
    bool? started,
    bool? completed,
    Object? optimizedAt = _omit,
    Object? optimizationErroredAt = _omit,
    Object? optimizationAttemptedAt = _omit,
  }) {
    return RouteState(
      optimization: optimization ?? this.optimization,
      optimizing: optimizing ?? this.optimizing,
      optimizationAcknowledged:
          optimizationAcknowledged ?? this.optimizationAcknowledged,
      confirmed: confirmed ?? this.confirmed,
      started: started ?? this.started,
      completed: completed ?? this.completed,
      optimizedAt: identical(optimizedAt, _omit)
          ? this.optimizedAt
          : optimizedAt as DateTime?,
      optimizationErroredAt: identical(optimizationErroredAt, _omit)
          ? this.optimizationErroredAt
          : optimizationErroredAt as DateTime?,
      optimizationAttemptedAt: identical(optimizationAttemptedAt, _omit)
          ? this.optimizationAttemptedAt
          : optimizationAttemptedAt as DateTime?,
    );
  }

  // Sentinela para o copyWith distinguir "omitido" de "null explícito"
  // (mesmo idiom de Stop.copyWith — lesson_copywith_nullable_field_pitfall).
  static const _omit = Object();
}
```

- [ ] **Step 4: Rodar o teste e ver passar**

Run: `cd apps/mobile && flutter test test/features/routes/domain/route_state_test.dart`
Expected: PASS (7 testes).

- [ ] **Step 5: Commit**

```bash
git add lib/features/routes/domain/route_state.dart test/features/routes/domain/route_state_test.dart
git commit -m "feat(routes): RouteState flags+timestamps espelhando o Spoke (Á7 PR-A)"
```

---

## Task 5: Migrar `Route` (RouteStatus → RouteState + métricas) e `Stop` (+ pendingRemoval)

**Files:**
- Modify: `lib/features/routes/domain/route.dart`
- Modify: `lib/features/routes/domain/stop.dart:35` (construtor) e `:74` (copyWith)
- Modify: `lib/features/routes/state/routes_provider.dart` (seed + createRoute + duplicateRoute)
- Test: `test/features/routes/domain/route_test.dart`

- [ ] **Step 1: Escrever o teste que falha**

```dart
// test/features/routes/domain/route_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/domain/optimization_state.dart';
import 'package:roteirizador_pro/features/routes/domain/route.dart';
import 'package:roteirizador_pro/features/routes/domain/route_state.dart';

void main() {
  test('Route default nasce DRAFT com métricas nulas', () {
    final r = Route(id: 'r1', date: DateTime(2026, 6, 13));
    expect(r.routeState.isDraft, isTrue);
    expect(r.totalDurationMinutes, isNull);
    expect(r.totalDistanceMeters, isNull);
  });

  test('copyWith troca routeState e métricas, preserva o resto', () {
    final r = Route(id: 'r1', date: DateTime(2026, 6, 13), name: 'Segunda');
    final next = r.copyWith(
      routeState: const RouteState(optimization: OptimizationState.optimized),
      totalDurationMinutes: 18,
      totalDistanceMeters: 5200,
    );
    expect(next.routeState.isPreConfirm, isTrue);
    expect(next.totalDurationMinutes, 18);
    expect(next.totalDistanceMeters, 5200);
    expect(next.name, 'Segunda'); // preservado
  });
}
```

- [ ] **Step 2: Rodar o teste e ver falhar**

Run: `cd apps/mobile && flutter test test/features/routes/domain/route_test.dart`
Expected: FAIL — `Route` ainda usa `status`/`RouteStatus`; `routeState`/métricas não existem.

- [ ] **Step 3: Reescrever `route.dart`**

Substituir o conteúdo de `lib/features/routes/domain/route.dart` por:

```dart
import 'route_state.dart';
import 'stop.dart';

/// Canonical top→bottom order matches the drawer bucket display order
/// (Spoke parity per inventory §11.6 revised 2026-05-27).
enum RoutePeriod { upcoming, today, thisWeek, thisMonth }

class Route {
  const Route({
    required this.id,
    required this.date,
    this.routeState = const RouteState(),
    this.name,
    this.stops = const [],
    this.totalDurationMinutes,
    this.totalDistanceMeters,
  });
  final String id;
  final DateTime date;
  final RouteState routeState;
  final String? name;
  final List<Stop> stops;

  /// Métricas da última otimização bem-sucedida (alimentam a linha summary do
  /// PRE-CONFIRM). Nulas até otimizar; zeradas ao invalidar (estado editing).
  final int? totalDurationMinutes;
  final double? totalDistanceMeters;

  String displayName() => name ?? _weekdayPtBr(date);

  Route copyWith({
    String? id,
    DateTime? date,
    RouteState? routeState,
    String? name,
    List<Stop>? stops,
    Object? totalDurationMinutes = _omit,
    Object? totalDistanceMeters = _omit,
  }) {
    return Route(
      id: id ?? this.id,
      date: date ?? this.date,
      routeState: routeState ?? this.routeState,
      name: name ?? this.name,
      stops: stops ?? this.stops,
      totalDurationMinutes: identical(totalDurationMinutes, _omit)
          ? this.totalDurationMinutes
          : totalDurationMinutes as int?,
      totalDistanceMeters: identical(totalDistanceMeters, _omit)
          ? this.totalDistanceMeters
          : totalDistanceMeters as double?,
    );
  }

  static const _omit = Object();
}

const _kWeekdayPtBr = <String>[
  '', // index 0 unused
  'segunda-feira',
  'terça-feira',
  'quarta-feira',
  'quinta-feira',
  'sexta-feira',
  'sábado',
  'domingo',
];

String _weekdayPtBr(DateTime d) => _kWeekdayPtBr[d.weekday];
```

> **Nota:** `enum RouteStatus` é REMOVIDO. O `name ?? this.name` do `name` é
> mantido como estava (o `updateRouteMeta` do provider já constrói o Route à
> mão quando precisa limpar o nome — não regredir isso).

- [ ] **Step 4: Adicionar `pendingRemoval` ao `Stop`**

Em `lib/features/routes/domain/stop.dart`, no construtor (após `this.estimatedTimeAtStop,` na linha 34) adicionar:

```dart
    this.pendingRemoval = false,
```

Após o campo `estimatedTimeAtStop` (linha 69) adicionar:

```dart
  /// Marca a parada para remoção DEFERIDA quando a rota já está otimizada
  /// (G5 — espelha `ConfirmDeleteStopOnOptimizationDialog` do Spoke). O solver
  /// exclui paradas com esta flag na próxima otimização. Em rota DRAFT a
  /// remoção é imediata (não usa esta flag).
  final bool pendingRemoval;
```

No `copyWith` (parâmetros, após `Object? estimatedTimeAtStop = _omit,` na linha 95) adicionar:

```dart
    bool? pendingRemoval,
```

E no retorno do `copyWith` (após o bloco `estimatedTimeAtStop:` na linha 136) adicionar:

```dart
      pendingRemoval: pendingRemoval ?? this.pendingRemoval,
```

- [ ] **Step 5: Migrar os consumidores em `routes_provider.dart`**

Em `lib/features/routes/state/routes_provider.dart`:

1. Trocar o import `import '../domain/route.dart';` por (manter) e adicionar `import '../domain/route_state.dart';` e `import '../domain/optimization_state.dart';`.
2. No `build()` (seed, linhas 27-52): substituir cada `status: RouteStatus.X` por `routeState:`:
   - `seed-today-1` (era `running`): `routeState: const RouteState(optimization: OptimizationState.optimized, confirmed: true, started: true)`.
   - `seed-today-2` (era `draft`): remover a linha `status:` (default já é DRAFT).
   - `seed-yesterday-1` (era `completed`): `routeState: const RouteState(completed: true)`.
   - `seed-lastweek-1` (era `completed`): `routeState: const RouteState(completed: true)`.
3. No `createRoute` (linha 64-68): remover `status: RouteStatus.draft,` (default).
4. No `duplicateRoute` (linha 101-106): remover `status: RouteStatus.draft,` (default).

- [ ] **Step 6: Rodar os testes e o analyze**

Run: `cd apps/mobile && flutter test test/features/routes/domain/route_test.dart && flutter analyze --no-pub lib/features/routes`
Expected: route_test PASS (2 testes). O analyze pode acusar OUTROS arquivos que ainda usam `RouteStatus`/`.status` — anotá-los e corrigir no Step 7.

- [ ] **Step 7: Corrigir os usos de `RouteStatus`/`.status` no código de produção**

Run para achar: `cd apps/mobile && grep -rln 'RouteStatus' lib --include='*.dart'`

Hoje (medido 2026-06-13) o `RouteStatus` em `lib/` vive em 3 arquivos: `domain/route.dart` (removido na T5 Step 3), `domain/stop.dart` (só import — confirmar e remover se sobrar), `state/routes_provider.dart` (migrado na T5 Step 5). Rodar `flutter analyze --no-pub lib` e corrigir qualquer leitura residual `r.status` → derivada do `routeState` (`r.status == RouteStatus.completed` → `r.routeState.completed`; `== RouteStatus.draft` → `r.routeState.isDraft`; `== RouteStatus.running` → `r.routeState.started`). Repetir até o analyze de `lib/` ficar limpo.

- [ ] **Step 8: Migrar os ~10 arquivos de TESTE que pinam `RouteStatus`**

Os testes existentes constroem `Route(status: RouteStatus.X)` — todos quebram com a migração. Achar: `cd apps/mobile && grep -rln 'RouteStatus' test --include='*.dart'`

Esperado (medido 2026-06-13): `routes_provider_test`, `current_route_stops_provider_test`, `group_routes_by_period_test`, `wizard_route_page_test`, `drawer_route_tile_test`, `route_shell_page_test`, `app_drawer_test`, `add_stop_page_test`, `edit_stop_page_test`, `stop_notes_section_test`. Em cada um, trocar `status: RouteStatus.draft` → (remover, é default) / `status: RouteStatus.running` → `routeState: const RouteState(optimization: OptimizationState.optimized, confirmed: true, started: true)` / `status: RouteStatus.completed` → `routeState: const RouteState(completed: true)`. Onde um teste ASSERTAVA `r.status == RouteStatus.X`, trocar pela derivada (`r.routeState.completed` etc). Adicionar o import de `route_state.dart`/`optimization_state.dart` onde faltar.

- [ ] **Step 9: Rodar a suite completa**

Run: `cd apps/mobile && flutter test`
Expected: PASS — todos os testes verdes após a migração de produção + testes. Se algum continuar vermelho por `RouteStatus`, voltar ao Step 8 para o arquivo faltante.

- [ ] **Step 10: Commit**

```bash
git add lib/features/routes/domain/route.dart lib/features/routes/domain/stop.dart lib/features/routes/state/routes_provider.dart test/features/routes/domain/route_test.dart
git add -A  # captura os arquivos de produção + testes migrados nos Steps 7-8
git commit -m "refactor(routes): migra RouteStatus->RouteState + métricas + Stop.pendingRemoval (Á7 PR-A)"
```

---

## Task 6: `RouteOptimizer` interface + `RouteOptimizationResult`

**Files:**
- Create: `lib/features/routes/domain/optimization/route_optimizer.dart`
- Test: (sem teste próprio — é interface; coberta pela Task 7)

- [ ] **Step 1: Criar a interface + o resultado**

```dart
// lib/features/routes/domain/optimization/route_optimizer.dart
import '../optimize_direction.dart';
import '../optimize_type.dart';
import '../stop.dart';

/// Ponto geográfico mínimo para o solver (evita acoplar a `LatLng` do
/// google_maps no domínio).
class GeoPoint {
  const GeoPoint(this.lat, this.lng);
  final double lat;
  final double lng;
}

/// Resultado de uma otimização: a ordem final das paradas (com `deliveryId`
/// já atribuído) + as métricas agregadas.
class RouteOptimizationResult {
  const RouteOptimizationResult({
    required this.orderedStops,
    required this.totalDurationMinutes,
    required this.totalDistanceMeters,
  });
  final List<Stop> orderedStops;
  final int totalDurationMinutes;
  final double totalDistanceMeters;
}

/// Fronteira do solver. A impl. do Slice 2 é `LocalRouteOptimizer` (on-device);
/// o Slice 3 injeta um `GraphHopperRouteOptimizer` sem tocar UI/estado.
abstract interface class RouteOptimizer {
  RouteOptimizationResult optimize({
    required GeoPoint start,
    GeoPoint? end,
    required List<Stop> stops,
    required OptimizeType type,
    OptimizeDirection? direction,
  });
}
```

- [ ] **Step 2: Confirmar que compila**

Run: `cd apps/mobile && flutter analyze --no-pub lib/features/routes/domain/optimization/route_optimizer.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/routes/domain/optimization/route_optimizer.dart
git commit -m "feat(routes): interface RouteOptimizer + RouteOptimizationResult (Á7 PR-A)"
```

---

## Task 7: `LocalRouteOptimizer` (NN + 2-opt, Haversine injetável)

**Files:**
- Create: `lib/features/routes/domain/optimization/local_route_optimizer.dart`
- Test: `test/features/routes/domain/optimization/local_route_optimizer_test.dart`

- [ ] **Step 1: Escrever o teste que falha**

```dart
// test/features/routes/domain/optimization/local_route_optimizer_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/domain/optimize_direction.dart';
import 'package:roteirizador_pro/features/routes/domain/optimize_type.dart';
import 'package:roteirizador_pro/features/routes/domain/package_label_format.dart';
import 'package:roteirizador_pro/features/routes/domain/optimization/local_route_optimizer.dart';
import 'package:roteirizador_pro/features/routes/domain/optimization/route_optimizer.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';

// Distância de teste determinística: |Δlat| + |Δlng| (Manhattan em "graus"),
// 1 grau = 1000 m. Injetada para o teste não depender da Terra real.
double _fakeDistance(double aLat, double aLng, double bLat, double bLng) =>
    ((aLat - bLat).abs() + (aLng - bLng).abs()) * 1000;

Stop _stop(String id, double lat, double lng) =>
    Stop(id: id, lat: lat, lng: lng, streetName: id, fullAddress: id);

void main() {
  final optimizer = LocalRouteOptimizer(distanceMeters: _fakeDistance);

  test('reordena por vizinho mais próximo a partir do start', () {
    // start em (0,0); paradas fora de ordem. A mais próxima do start é C(1,0).
    final result = optimizer.optimize(
      start: const GeoPoint(0, 0),
      stops: [_stop('A', 5, 0), _stop('B', 3, 0), _stop('C', 1, 0)],
      type: OptimizeType.restartRoute,
    );
    expect(result.orderedStops.map((s) => s.id).toList(), ['C', 'B', 'A']);
  });

  test('atribui deliveryId Moderno na ordem final (A1, A2, A3)', () {
    final result = optimizer.optimize(
      start: const GeoPoint(0, 0),
      stops: [_stop('A', 5, 0), _stop('B', 3, 0), _stop('C', 1, 0)],
      type: OptimizeType.restartRoute,
    );
    expect(result.orderedStops.map((s) => s.deliveryId).toList(),
        ['A1', 'A2', 'A3']);
  });

  test('direction reverse inverte a ordem otimizada', () {
    final result = optimizer.optimize(
      start: const GeoPoint(0, 0),
      stops: [_stop('A', 5, 0), _stop('B', 3, 0), _stop('C', 1, 0)],
      type: OptimizeType.reorderFlexible,
      direction: OptimizeDirection.reverse,
    );
    expect(result.orderedStops.map((s) => s.id).toList(), ['A', 'B', 'C']);
  });

  test('exclui paradas com pendingRemoval da ordem final (G5)', () {
    final result = optimizer.optimize(
      start: const GeoPoint(0, 0),
      stops: [
        _stop('A', 5, 0),
        _stop('B', 3, 0).copyWith(pendingRemoval: true),
        _stop('C', 1, 0),
      ],
      type: OptimizeType.restartRoute,
    );
    expect(result.orderedStops.map((s) => s.id).toList(), ['C', 'A']);
  });

  test('métricas: distância total > 0 e duração derivada da distância', () {
    final result = optimizer.optimize(
      start: const GeoPoint(0, 0),
      stops: [_stop('C', 1, 0)],
      type: OptimizeType.restartRoute,
    );
    expect(result.totalDistanceMeters, greaterThan(0));
    expect(result.totalDurationMinutes, greaterThanOrEqualTo(0));
  });

  test('formato Clássico gera 1,2,3', () {
    final classic = LocalRouteOptimizer(
      distanceMeters: _fakeDistance,
      labelFormat: PackageLabelFormat.classico,
    );
    final result = classic.optimize(
      start: const GeoPoint(0, 0),
      stops: [_stop('A', 5, 0), _stop('B', 3, 0)],
      type: OptimizeType.restartRoute,
    );
    expect(result.orderedStops.map((s) => s.deliveryId).toList(), ['1', '2']);
  });
}
```

- [ ] **Step 2: Rodar o teste e ver falhar**

Run: `cd apps/mobile && flutter test test/features/routes/domain/optimization/local_route_optimizer_test.dart`
Expected: FAIL — arquivo não existe.

- [ ] **Step 3: Implementar**

```dart
// lib/features/routes/domain/optimization/local_route_optimizer.dart
import 'package:geolocator/geolocator.dart';

import '../optimize_direction.dart';
import '../optimize_type.dart';
import '../package_label_format.dart';
import '../stop.dart';
import 'route_optimizer.dart';

/// Solver on-device (stand-in do GraphHopper até o Slice 3). Nearest-neighbor
/// a partir do `start` + refinamento 2-opt; distância via `geolocator`
/// (injetável para teste). Atribui `deliveryId` pela [labelFormat]. Velocidade
/// urbana constante converte distância em duração (o tempo com trânsito real
/// vem do GraphHopper no Slice 3).
class LocalRouteOptimizer implements RouteOptimizer {
  LocalRouteOptimizer({
    double Function(double, double, double, double)? distanceMeters,
    this.labelFormat = PackageLabelFormat.moderno,
    this.urbanSpeedMetersPerMinute = 400, // ~24 km/h
  }) : _distance = distanceMeters ?? Geolocator.distanceBetween;

  final double Function(double, double, double, double) _distance;
  final PackageLabelFormat labelFormat;
  final double urbanSpeedMetersPerMinute;

  @override
  RouteOptimizationResult optimize({
    required GeoPoint start,
    GeoPoint? end,
    required List<Stop> stops,
    required OptimizeType type,
    OptimizeDirection? direction,
  }) {
    // G5: paradas marcadas para remoção deferida saem aqui.
    final active = stops.where((s) => !s.pendingRemoval).toList();

    // Nearest-neighbor a partir do start.
    var ordered = _nearestNeighbor(start, active);
    // Refina com 2-opt (cap de iterações para O(n²) ficar barato).
    ordered = _twoOpt(start, ordered, end);

    if (direction == OptimizeDirection.reverse) {
      ordered = ordered.reversed.toList();
    }

    // Atribui deliveryId + posição na ordem final.
    final labeled = <Stop>[
      for (var i = 0; i < ordered.length; i++)
        ordered[i].copyWith(
          deliveryId: labelFormat.labelFor(i),
          positionInRoute: i,
        ),
    ];

    final distance = _totalDistance(start, labeled, end);
    return RouteOptimizationResult(
      orderedStops: labeled,
      totalDistanceMeters: distance,
      totalDurationMinutes: (distance / urbanSpeedMetersPerMinute).round(),
    );
  }

  List<Stop> _nearestNeighbor(GeoPoint start, List<Stop> stops) {
    final remaining = [...stops];
    final result = <Stop>[];
    var curLat = start.lat;
    var curLng = start.lng;
    while (remaining.isNotEmpty) {
      var bestIdx = 0;
      var bestDist = double.infinity;
      for (var i = 0; i < remaining.length; i++) {
        final d = _distance(curLat, curLng, remaining[i].lat, remaining[i].lng);
        if (d < bestDist) {
          bestDist = d;
          bestIdx = i;
        }
      }
      final next = remaining.removeAt(bestIdx);
      result.add(next);
      curLat = next.lat;
      curLng = next.lng;
    }
    return result;
  }

  List<Stop> _twoOpt(GeoPoint start, List<Stop> route, GeoPoint? end) {
    if (route.length < 3) return route;
    var best = [...route];
    var improved = true;
    var guard = 0;
    while (improved && guard < 50) {
      improved = false;
      guard++;
      for (var i = 0; i < best.length - 1; i++) {
        for (var j = i + 1; j < best.length; j++) {
          final candidate = [
            ...best.sublist(0, i),
            ...best.sublist(i, j + 1).reversed,
            ...best.sublist(j + 1),
          ];
          if (_totalDistance(start, candidate, end) <
              _totalDistance(start, best, end)) {
            best = candidate;
            improved = true;
          }
        }
      }
    }
    return best;
  }

  double _totalDistance(GeoPoint start, List<Stop> stops, GeoPoint? end) {
    if (stops.isEmpty) return 0;
    var total = _distance(start.lat, start.lng, stops.first.lat, stops.first.lng);
    for (var i = 0; i < stops.length - 1; i++) {
      total += _distance(
          stops[i].lat, stops[i].lng, stops[i + 1].lat, stops[i + 1].lng);
    }
    if (end != null) {
      total += _distance(stops.last.lat, stops.last.lng, end.lat, end.lng);
    }
    return total;
  }
}
```

- [ ] **Step 4: Rodar o teste e ver passar**

Run: `cd apps/mobile && flutter test test/features/routes/domain/optimization/local_route_optimizer_test.dart`
Expected: PASS (6 testes).

- [ ] **Step 5: Commit**

```bash
git add lib/features/routes/domain/optimization/local_route_optimizer.dart test/features/routes/domain/optimization/local_route_optimizer_test.dart
git commit -m "feat(routes): LocalRouteOptimizer NN+2-opt on-device (Á7 PR-A)"
```

---

## Task 8: `OptimizationController` (guard de mínimo + progresso + chamada ao solver)

**Files:**
- Create: `lib/features/routes/state/optimization_controller.dart`
- Test: `test/features/routes/state/optimization_controller_test.dart`

- [ ] **Step 1: Escrever o teste que falha**

```dart
// test/features/routes/state/optimization_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roteirizador_pro/features/routes/domain/optimize_direction.dart';
import 'package:roteirizador_pro/features/routes/domain/optimize_type.dart';
import 'package:roteirizador_pro/features/routes/domain/optimization/route_optimizer.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';
import 'package:roteirizador_pro/features/routes/state/optimization_controller.dart';

// Fake solver determinístico: devolve as paradas na ordem recebida.
class _FakeOptimizer implements RouteOptimizer {
  @override
  RouteOptimizationResult optimize({
    required GeoPoint start,
    GeoPoint? end,
    required List<Stop> stops,
    required OptimizeType type,
    OptimizeDirection? direction,
  }) =>
      RouteOptimizationResult(
        orderedStops: stops,
        totalDurationMinutes: 18,
        totalDistanceMeters: 5200,
      );
}

Stop _stop(String id) =>
    Stop(id: id, lat: 0, lng: 0, streetName: id, fullAddress: id);

ProviderContainer _container() => ProviderContainer(overrides: [
      routeOptimizerProvider.overrideWithValue(_FakeOptimizer()),
    ]);

void main() {
  test('guard de mínimo: < 1 parada => OptimizationOutcome.notEnoughStops, solver não roda', () async {
    final c = _container();
    addTearDown(c.dispose);
    final outcome = await c.read(optimizationControllerProvider.notifier).optimize(
          start: const GeoPoint(0, 0),
          stops: const [],
          type: OptimizeType.restartRoute,
        );
    expect(outcome, isA<NotEnoughStops>());
  });

  test('com paradas suficientes => OptimizationOutcome.success com métricas', () async {
    final c = _container();
    addTearDown(c.dispose);
    final outcome = await c.read(optimizationControllerProvider.notifier).optimize(
          start: const GeoPoint(0, 0),
          stops: [_stop('A'), _stop('B')],
          type: OptimizeType.restartRoute,
        );
    expect(outcome, isA<OptimizationSuccess>());
    final success = outcome as OptimizationSuccess;
    expect(success.result.totalDurationMinutes, 18);
    expect(success.result.orderedStops.length, 2);
  });
}
```

> **Nota:** o solver é injetado via `routeOptimizerProvider` (definido no Step 3),
> overridável no teste. O `OptimizationOutcome` é uma sealed class (resultado do
> `optimize`), exaustiva — a UI faz `switch` sem `default`.

- [ ] **Step 2: Rodar o teste e ver falhar**

Run: `cd apps/mobile && flutter test test/features/routes/state/optimization_controller_test.dart`
Expected: FAIL — `optimization_controller.dart` e `routeOptimizerProvider` não existem.

- [ ] **Step 3: Implementar o controller + o provider do solver**

```dart
// lib/features/routes/state/optimization_controller.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/optimize_direction.dart';
import '../domain/optimize_type.dart';
import '../domain/optimization/local_route_optimizer.dart';
import '../domain/optimization/route_optimizer.dart';
import '../domain/stop.dart';

part 'optimization_controller.g.dart';

/// Binding do solver. Slice 2 = `LocalRouteOptimizer` (on-device). Slice 3
/// sobrescreve este provider por um `GraphHopperRouteOptimizer` sem tocar a UI.
@Riverpod(keepAlive: true)
RouteOptimizer routeOptimizer(Ref ref) => LocalRouteOptimizer();

/// Resultado de uma tentativa de otimização. Sealed — a UI faz `switch`
/// exaustivo sem `default`.
sealed class OptimizationOutcome {
  const OptimizationOutcome();
}

/// Paradas insuficientes (G1) — o solver NÃO roda; a UI mostra o
/// `NotEnoughStopsDialog`.
class NotEnoughStops extends OptimizationOutcome {
  const NotEnoughStops();
}

/// Otimização concluída — a UI transita pro PRE-CONFIRM com o `result`.
class OptimizationSuccess extends OptimizationOutcome {
  const OptimizationSuccess(this.result);
  final RouteOptimizationResult result;
}

/// Falha de rede/solver — a UI mostra o `OptimizationErrorDialog`.
class OptimizationFailure extends OptimizationOutcome {
  const OptimizationFailure();
}

/// Orquestra o funil de otimização. Estado = a fase de progresso corrente
/// (null quando ocioso) para a UI mostrar a `OptimizingProgressView`.
@riverpod
class OptimizationController extends _$OptimizationController {
  @override
  OptimizationPhase? build() => null;

  /// Mínimo de paradas otimizáveis (espelha `OptimizationError.NotEnoughStops`
  /// do Spoke: "1 ou mais paradas além do ponto de partida e destino").
  static const int minStops = 1;

  Future<OptimizationOutcome> optimize({
    required GeoPoint start,
    GeoPoint? end,
    required List<Stop> stops,
    required OptimizeType type,
    OptimizeDirection? direction,
  }) async {
    final optimizable = stops.where((s) => !s.pendingRemoval).length;
    if (optimizable < minStops) {
      return const NotEnoughStops(); // G1 — solver não roda
    }

    try {
      state = OptimizationPhase.analysing;
      final optimizer = ref.read(routeOptimizerProvider);
      // As fases são visuais; o solver on-device é síncrono e rápido. Avança
      // as fases para o usuário ver o progresso (não bloqueia em I/O real).
      final result = optimizer.optimize(
        start: start,
        end: end,
        stops: stops,
        type: type,
        direction: direction,
      );
      state = null;
      return OptimizationSuccess(result);
    } catch (e) {
      state = null;
      return const OptimizationFailure();
    }
  }
}

/// Fase de progresso visível na `OptimizingProgressView` (4 fases do Spoke:
/// optimizing_analysing/sorting/traffic/creating).
enum OptimizationPhase { analysing, sorting, traffic, creating }
```

- [ ] **Step 4: Rodar o codegen + o teste**

Run: `cd apps/mobile && dart run build_runner build --delete-conflicting-outputs && flutter test test/features/routes/state/optimization_controller_test.dart`
Expected: codegen gera `optimization_controller.g.dart`; teste PASS (2 testes).

- [ ] **Step 5: Commit**

```bash
git add lib/features/routes/state/optimization_controller.dart lib/features/routes/state/optimization_controller.g.dart test/features/routes/state/optimization_controller_test.dart
git commit -m "feat(routes): OptimizationController + guard de mínimo (Á7 PR-A, G1)"
```

---

## Task 9: Diálogos `NotEnoughStopsDialog` + `OptimizationErrorDialog`

**Files:**
- Create: `lib/features/routes/presentation/widgets/not_enough_stops_dialog.dart`
- Create: `lib/features/routes/presentation/widgets/optimization_error_dialog.dart`
- Test: `test/features/routes/presentation/not_enough_stops_dialog_test.dart`
- Test: `test/features/routes/presentation/optimization_error_dialog_test.dart`

- [ ] **Step 1: Escrever os testes que falham**

```dart
// test/features/routes/presentation/not_enough_stops_dialog_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/not_enough_stops_dialog.dart';

void main() {
  testWidgets('mostra título "Adicione mais paradas" + único botão "Ok"', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showNotEnoughStopsDialog(context),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Adicione mais paradas'), findsOneWidget);
    expect(find.text('Ok'), findsOneWidget);
    // Distinto do erro de rede: NÃO tem "Pular otimização".
    expect(find.text('Pular otimização'), findsNothing);
  });
}
```

```dart
// test/features/routes/presentation/optimization_error_dialog_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/optimization_error_dialog.dart';

void main() {
  testWidgets('erro de rede: "Tentar de novo" + "Pular otimização"', (tester) async {
    OptimizationErrorChoice? choice;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async =>
              choice = await showOptimizationErrorDialog(context),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Tentar de novo'), findsOneWidget);
    expect(find.text('Pular otimização'), findsOneWidget);
    await tester.tap(find.text('Pular otimização'));
    await tester.pumpAndSettle();
    expect(choice, OptimizationErrorChoice.skip);
  });
}
```

- [ ] **Step 2: Rodar os testes e ver falhar**

Run: `cd apps/mobile && flutter test test/features/routes/presentation/not_enough_stops_dialog_test.dart test/features/routes/presentation/optimization_error_dialog_test.dart`
Expected: FAIL — arquivos não existem.

- [ ] **Step 3: Implementar os dois diálogos**

```dart
// lib/features/routes/presentation/widgets/not_enough_stops_dialog.dart
import 'package:flutter/material.dart';

/// G1 — paradas insuficientes para otimizar. Microcopy PT-BR original,
/// estrutura espelha `OptimiseNotEnoughStopsDialog` do Spoke
/// (título + corpo + único botão Ok). Distinto do erro de rede.
Future<void> showNotEnoughStopsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Adicione mais paradas'),
      content: const Text(
        'Para otimizar a rota, adicione pelo menos uma parada além do ponto '
        'de partida e do destino.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Ok'),
        ),
      ],
    ),
  );
}
```

```dart
// lib/features/routes/presentation/widgets/optimization_error_dialog.dart
import 'package:flutter/material.dart';

/// Escolha do usuário no diálogo de falha de otimização.
enum OptimizationErrorChoice { retry, skip }

/// Falha de REDE/solver ao otimizar. Microcopy PT-BR original,
/// estrutura espelha `optimization_failed_*` do Spoke (Tentar de novo / Pular
/// otimização). Distinto do `NotEnoughStopsDialog` (G1).
Future<OptimizationErrorChoice?> showOptimizationErrorDialog(
    BuildContext context) {
  return showDialog<OptimizationErrorChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Não foi possível otimizar'),
      content: const Text(
        'Confira sua conexão com a internet e tente de novo.',
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(OptimizationErrorChoice.skip),
          child: const Text('Pular otimização'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(OptimizationErrorChoice.retry),
          child: const Text('Tentar de novo'),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 4: Rodar os testes e ver passar**

Run: `cd apps/mobile && flutter test test/features/routes/presentation/not_enough_stops_dialog_test.dart test/features/routes/presentation/optimization_error_dialog_test.dart`
Expected: PASS (2 testes).

- [ ] **Step 5: Commit**

```bash
git add lib/features/routes/presentation/widgets/not_enough_stops_dialog.dart lib/features/routes/presentation/widgets/optimization_error_dialog.dart test/features/routes/presentation/not_enough_stops_dialog_test.dart test/features/routes/presentation/optimization_error_dialog_test.dart
git commit -m "feat(routes): diálogos de erro de otimização (rede + poucas paradas) (Á7 PR-A)"
```

---

## Task 10: `OptimizingProgressView` (tela 4 fases)

**Files:**
- Create: `lib/features/routes/presentation/widgets/optimizing_progress_view.dart`
- Test: `test/features/routes/presentation/optimizing_progress_view_test.dart`

- [ ] **Step 1: Escrever o teste que falha**

```dart
// test/features/routes/presentation/optimizing_progress_view_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/optimizing_progress_view.dart';
import 'package:roteirizador_pro/features/routes/state/optimization_controller.dart';

void main() {
  testWidgets('mostra o texto da fase corrente', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: OptimizingProgressView(phase: OptimizationPhase.sorting),
      ),
    ));
    expect(find.text('Encontrando a melhor ordem...'), findsOneWidget);
  });

  testWidgets('cada fase tem seu texto', (tester) async {
    for (final entry in {
      OptimizationPhase.analysing: 'Analisando suas paradas...',
      OptimizationPhase.sorting: 'Encontrando a melhor ordem...',
      OptimizationPhase.traffic: 'Considerando o trânsito...',
      OptimizationPhase.creating: 'Criando sua rota...',
    }.entries) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: OptimizingProgressView(phase: entry.key)),
      ));
      expect(find.text(entry.value), findsOneWidget);
    }
  });
}
```

- [ ] **Step 2: Rodar o teste e ver falhar**

Run: `cd apps/mobile && flutter test test/features/routes/presentation/optimizing_progress_view_test.dart`
Expected: FAIL — arquivo não existe.

- [ ] **Step 3: Implementar**

```dart
// lib/features/routes/presentation/widgets/optimizing_progress_view.dart
import 'package:flutter/material.dart';

import '../../state/optimization_controller.dart';

/// Tela de progresso da otimização (4 fases). Microcopy PT-BR original,
/// espelha as fases do Spoke (optimizing_analysing/sorting/
/// traffic/creating). Display-only — o avanço de fase é orquestrado pelo
/// `OptimizationController`.
class OptimizingProgressView extends StatelessWidget {
  const OptimizingProgressView({required this.phase, super.key});

  final OptimizationPhase phase;

  static const _labels = {
    OptimizationPhase.analysing: 'Analisando suas paradas...',
    OptimizationPhase.sorting: 'Encontrando a melhor ordem...',
    OptimizationPhase.traffic: 'Considerando o trânsito...',
    OptimizationPhase.creating: 'Criando sua rota...',
  };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(_labels[phase]!, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Rodar o teste e ver passar**

Run: `cd apps/mobile && flutter test test/features/routes/presentation/optimizing_progress_view_test.dart`
Expected: PASS (2 testes).

- [ ] **Step 5: Commit**

```bash
git add lib/features/routes/presentation/widgets/optimizing_progress_view.dart test/features/routes/presentation/optimizing_progress_view_test.dart
git commit -m "feat(routes): OptimizingProgressView 4 fases (Á7 PR-A)"
```

---

## Task 11: `OptimizeCta` (CTA sticky, gated abaixo do mínimo)

**Files:**
- Create: `lib/features/routes/presentation/widgets/optimize_cta.dart`
- Test: `test/features/routes/presentation/optimize_cta_test.dart`

- [ ] **Step 1: Escrever o teste que falha**

```dart
// test/features/routes/presentation/optimize_cta_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/optimize_cta.dart';

void main() {
  testWidgets('habilitado dispara onPressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: OptimizeCta(enabled: true, onPressed: () => tapped = true),
      ),
    ));
    expect(find.text('Otimizar rota'), findsOneWidget);
    await tester.tap(find.text('Otimizar rota'));
    expect(tapped, isTrue);
  });

  testWidgets('desabilitado (abaixo do mínimo) não dispara', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: OptimizeCta(enabled: false, onPressed: () => tapped = true),
      ),
    ));
    await tester.tap(find.text('Otimizar rota'));
    expect(tapped, isFalse);
  });

  testWidgets('tem Semantics de botão com o label', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: OptimizeCta(enabled: true, onPressed: () {})),
    ));
    expect(
      tester.getSemantics(find.text('Otimizar rota')),
      matchesSemantics(label: 'Otimizar rota', isButton: true, isEnabled: true, hasEnabledState: true, hasTapAction: true, isFocusable: true),
    );
  });
}
```

- [ ] **Step 2: Rodar o teste e ver falhar**

Run: `cd apps/mobile && flutter test test/features/routes/presentation/optimize_cta_test.dart`
Expected: FAIL — arquivo não existe.

- [ ] **Step 3: Implementar**

```dart
// lib/features/routes/presentation/widgets/optimize_cta.dart
import 'package:flutter/material.dart';

/// CTA sticky "Otimizar rota" (rodapé do shell, §10.5). `enabled` é falso
/// abaixo do mínimo de paradas (G1) — o botão fica desabilitado em vez de
/// rodar o solver sobre lista degenerada. Otimização é GRÁTIS (sem paywall;
/// o paywall só dispara em "Navegar" na Área 8).
class OptimizeCta extends StatelessWidget {
  const OptimizeCta({required this.enabled, required this.onPressed, super.key});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: const Icon(Icons.refresh),
        label: const Text('Otimizar rota'),
      ),
    );
  }
}
```

> **Nota visual:** o ícone `Icons.refresh` é placeholder de estrutura; o ícone
> Lucide final (`prototipo/tokens.js` — circular-arrows) entra no polish visual.
> Não bloqueia o PR-A. Cor/estilo herdam o tema (tokens do prototipo já
> aplicados no `FilledButton` do app).

- [ ] **Step 4: Rodar o teste e ver passar**

Run: `cd apps/mobile && flutter test test/features/routes/presentation/optimize_cta_test.dart`
Expected: PASS (3 testes). Se o `matchesSemantics` reclamar de flags, ajustar para os flags que o `FilledButton` realmente expõe (rodar o teste e ler o diff do matcher).

- [ ] **Step 5: Commit**

```bash
git add lib/features/routes/presentation/widgets/optimize_cta.dart test/features/routes/presentation/optimize_cta_test.dart
git commit -m "feat(routes): OptimizeCta sticky gated abaixo do mínimo (Á7 PR-A)"
```

---

## Task 12: Montar o CTA no rodapé do shell (`route_shell_page.dart`)

**Files:**
- Modify: `lib/features/routes/presentation/route_shell_page.dart:617` (slot do rodapé) + onde o `_RouteSheet` recebe seus callbacks.
- Test: `test/features/routes/presentation/route_shell_optimize_cta_test.dart`

- [ ] **Step 1: Ler o trecho atual e localizar o slot**

Run: `cd apps/mobile && grep -n 'showButtons && stops.isEmpty\|onAddStopTap\|class _RouteSheet\|required this.stops' lib/features/routes/presentation/route_shell_page.dart`
Identificar: (a) o bloco `if (showButtons && stops.isEmpty)` (rodapé empty-state, ~linha 617); (b) o construtor de `_RouteSheet` (onde os callbacks chegam, ~linha 471-495).

- [ ] **Step 2: Escrever o teste de widget que falha**

```dart
// test/features/routes/presentation/route_shell_optimize_cta_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/optimize_cta.dart';

// Este teste pina a regra de visibilidade do CTA no rodapé: o OptimizeCta
// aparece quando a rota ativa tem >=1 parada, e some quando vazia. Como o
// _RouteSheet é privado, exercemos a regra via o widget público OptimizeCta
// dentro de um harness mínimo que replica a condição (a montagem real é
// verificada no integration_test do fechamento da Á7).
void main() {
  testWidgets('CTA visível com paradas, ausente sem paradas', (tester) async {
    Widget harness({required bool hasStops}) => MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                if (hasStops) OptimizeCta(enabled: true, onPressed: () {}),
              ],
            ),
          ),
        );

    await tester.pumpWidget(harness(hasStops: false));
    expect(find.byType(OptimizeCta), findsNothing);

    await tester.pumpWidget(harness(hasStops: true));
    expect(find.byType(OptimizeCta), findsOneWidget);
  });
}
```

> **Honestidade do teste:** a montagem REAL dentro do `_RouteSheet` privado é
> coberta pelo integration_test no M54 (fechamento da Á7). Este widget test
> pina só a regra de visibilidade do CTA público, que é o que muda neste PR.

- [ ] **Step 3: Rodar o teste e ver passar (verde imediato — é a regra)**

Run: `cd apps/mobile && flutter test test/features/routes/presentation/route_shell_optimize_cta_test.dart`
Expected: PASS (1 teste). Confirma que `OptimizeCta` importa e a regra de visibilidade é a esperada.

- [ ] **Step 4: Montar o CTA no `route_shell_page.dart`**

Logo APÓS o bloco `if (showButtons && stops.isEmpty) Padding(...)` (que termina ~linha 635), adicionar o bloco irmão para a rota COM paradas:

```dart
              // CTA "Otimizar rota" — nasce aqui (Á7 PR-A). Aparece quando o
              // sheet está medium+ E a rota tem >=1 parada (o slot que era
              // vazio desde a MS-A6). Otimização é grátis (sem paywall).
              if (showButtons && stops.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 12),
                  child: OptimizeCta(
                    enabled:
                        stops.length >= OptimizationController.minStops,
                    onPressed: onOptimizeTap,
                  ),
                ),
```

Adicionar o import no topo do arquivo:

```dart
import '../state/optimization_controller.dart';
import 'widgets/optimize_cta.dart';
```

Adicionar `onOptimizeTap` ao `_RouteSheet` (construtor ~linha 471 + campo ~linha 495): declarar `final VoidCallback onOptimizeTap;` e `required this.onOptimizeTap,` no construtor. No ponto onde `_RouteSheet` é instanciado (o `ConsumerWidget` pai que monta o sheet), passar `onOptimizeTap: () => _onOptimize(ref, context)`.

- [ ] **Step 5: Implementar o handler `_onOptimize` no ConsumerWidget pai**

No widget que monta o `_RouteSheet` (o `RouteShellPage`/seu state), adicionar o método que lê os stops da rota ativa, chama o controller, e roteia o outcome (por enquanto, mostra os diálogos e um SnackBar para o sucesso — a transição visual pro PRE-CONFIRM é o PR-B):

```dart
  Future<void> _onOptimize(WidgetRef ref, BuildContext context) async {
    final stops = ref.read(currentRouteStopsProvider);
    if (stops.isEmpty) {
      await showNotEnoughStopsDialog(context);
      return;
    }
    // Start = posição da rota (Slice 2: usa o primeiro stop como referência
    // até a Partida real estar wirada; o solver é determinístico de qualquer
    // forma). O PR-B liga isto à Partida da config.
    final outcome =
        await ref.read(optimizationControllerProvider.notifier).optimize(
              start: GeoPoint(stops.first.lat, stops.first.lng),
              stops: stops,
              type: OptimizeType.restartRoute,
            );
    if (!context.mounted) return;
    switch (outcome) {
      case NotEnoughStops():
        await showNotEnoughStopsDialog(context);
      case OptimizationFailure():
        await showOptimizationErrorDialog(context);
      case OptimizationSuccess(:final result):
        // PR-B substitui este SnackBar pela transição ao PRE-CONFIRM.
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Rota otimizada: ${result.totalDurationMinutes} min, '
            '${result.orderedStops.length} paradas',
          ),
        ));
    }
  }
```

Adicionar os imports necessários no topo: `optimization/route_optimizer.dart` (para `GeoPoint`), `optimize_type.dart`, `widgets/not_enough_stops_dialog.dart`, `widgets/optimization_error_dialog.dart`.

> **Nota de escopo:** o SnackBar de sucesso é o honest-stub do PR-A — o PR-B o
> troca pela transição visual ao PRE-CONFIRM. NÃO é `onTap` vazio: é uma ação
> observável (mostra as métricas reais do solver). Sem bug silencioso.

- [ ] **Step 6: Rodar codegen (se algum provider mudou), analyze e a suite**

Run: `cd apps/mobile && dart run build_runner build --delete-conflicting-outputs && flutter analyze --no-pub lib/features/routes && flutter test`
Expected: analyze limpo no escopo; suite verde.

- [ ] **Step 7: Commit**

```bash
git add lib/features/routes/presentation/route_shell_page.dart test/features/routes/presentation/route_shell_optimize_cta_test.dart
git commit -m "feat(routes): monta CTA Otimizar no rodapé do shell + handler (Á7 PR-A)"
```

---

## Task 13: Gates do PR-A + abrir o PR

**Files:** (nenhum novo — verificação)

- [ ] **Step 1: Suite + analyze completos**

Run: `cd apps/mobile && flutter analyze && flutter test`
Expected: analyze sem lints novos (baseline 23 MS-DEBT inalterado); suite verde (baseline anterior + ~22 testes novos deste PR).

- [ ] **Step 2: Dispatch `flutter-perf-auditor`**

Dispatch o subagent `flutter-perf-auditor` sobre os widgets novos (`optimize_cta.dart`, `optimizing_progress_view.dart`, os diálogos). Resolver must-fix; should-fix vira TODO ou aplica.

- [ ] **Step 3: Dispatch `adr-guardian`**

Dispatch o subagent `adr-guardian` sobre o diff. Confirmar que a ADR-0051 cobre a mudança de lifecycle (nenhuma dep nova de stack — `geolocator` já estava no pubspec).

- [ ] **Step 4: Atualizar TODO.md com o débito declarado do PR-A**

Adicionar em `TODO.md`, sob a Área 7:
- O default Moderno do chip de ID é hard-coded; o toggle Moderno/Clássico é Á10 (G6).
- O `start` do `_onOptimize` usa o primeiro stop como referência até o PR-B ligar a Partida real.
- O SnackBar de sucesso é honest-stub até o PR-B trazer o PRE-CONFIRM.

- [ ] **Step 5: Commit + push + abrir PR**

```bash
git add TODO.md
git commit -m "docs(todo): débito declarado do Á7 PR-A"
git push -u origin feat/m2-slice-2-area-7-optimize
gh pr create --base develop --title "feat(routes): Área 7 PR-A — estado + solver + CTA Otimizar + progresso" --body "Primeira fatia da Área 7 (Otimizar rota). Implementa RouteState (flags+timestamps fiel ao Spoke), solver Dart on-device (NN+2-opt), CTA Otimizar sticky, tela de progresso (4 fases) e os diálogos de erro (rede + poucas paradas, G1). Spec: docs/superpowers/specs/2026-06-13-area7-optimize-route-design.md. ADR-0051."
```

> **Nota:** o integration_test no M54 + smoke E2E release são do **fechamento da
> Área 7** (após o PR-D), não de cada PR de fatia — o PR-A não tem fluxo de
> ponta-a-ponta navegável ainda (o PRE-CONFIRM é o PR-B). Os gates de fatia são
> analyze + suite + perf-auditor + adr-guardian, confirmados acima.
