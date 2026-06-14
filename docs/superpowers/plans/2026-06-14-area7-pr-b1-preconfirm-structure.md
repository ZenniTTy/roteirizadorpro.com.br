# Área 7 — PR-B1 (PRE-CONFIRM estrutura: aplicar otimização + lista ordenada + chips + summary + FTUE + Refinar/Reotimizar + remoção deferida) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Entregar a ESTRUTURA do estado PRE-CONFIRM da Área 7 (sem o mapa pesado, que é o PR-B2): aplicar o resultado da otimização à rota ativa, renderizar o PRE-CONFIRM no mesmo shell (lista ordenada com chips A1..AN + linha de resumo display-only + rodapé com 1 tempo + 2 CTAs "Refinar"/"Confirmar"), o FTUE de numeração (one-shot), os dois sheets distintos (Refinar ≠ Reotimizar) e a remoção deferida (G5).

**Architecture:** O PRE-CONFIRM NÃO é tela nova — é o mesmo `route_shell_page.dart` (= `EditRouteFragment` do Spoke, confirmado no jadx: não há `PreConfirmFragment`) renderizando por estado derivado de `RouteState`. O `_onOptimize` do PR-A (que só mostrava SnackBar) passa a APLICAR o resultado à rota (via `Routes.applyOptimization`), mudando `routeState` para `optimized` + gravando stops reordenados + métricas. O shell ganha um `switch` sobre o `RouteState` da rota ativa: `isDraft`→sheet atual; `isPreConfirm`→`PreConfirmView`. A metade superior (mapa+polyline) fica como o mapa ATUAL nesta fatia — o polyline+markers numerados são o PR-B2.

**Tech Stack:** Flutter 3.44 / Dart 3.12, Riverpod 3 (`@riverpod` codegen), `shared_preferences` (FTUE one-shot, idiom `MapPrefsRepository`), `mocktail` só onde precisar de verify, fakes manuais como default. Microcopy PT-BR **ORIGINAL** (ADR-0010) — estrutura do dump, texto reformulado (NUNCA verbatim das strings pt-rBR do Spoke).

**Spec:** `docs/superpowers/specs/2026-06-13-area7-optimize-route-design.md` (§Sub-slice plan PR-B, fatiado em B1/B2 por boas-práticas de risco). **Baseline dump-first (re-confirmada 2026-06-14):** `refine_route_dialog_*` (Refinar) ≠ `optimization_explainer_*` (Reotimizar kebab); `package_identification_eduction_dialog_*` (FTUE); `remove_stop_on_optimization_confirmation_dialog_*` + `removed_stop_dialog_*` (G5); `route_duration_hours_and_minutes_short`="%1$dh%2$dmin" (summary). PRE-CONFIRM = mesmo `EditRouteFragment` por estado (jadx).

---

## Fidelidade de microcopy (regra crítica desta fatia)

Toda string PT-BR abaixo é **original** — comparada 1:1 com `~/spoke-dump/res-decoded/res/values-pt-rBR/strings.xml` e deliberadamente reformulada. Referência (NÃO copiar) das strings do Spoke:
- Refinar: `refine_route_dialog_title`="Refinar a rota", `_reverse_title`="Inverter a rota", `_reverse_description`="Inverter a direção da rota", `_manual_title`="Ordenar a rota manualmente", `_manual_description`="Definir a ordem da rota desenhando no mapa".
- Reotimizar: `optimization_explainer_title`="Compare as opções", `_reoptimize`="Reotimizar", `_reoptimize_description`="Recalcula a rota do zero...", `_update_*` / `optimization_dialog_update_route_subtitle`="Reordenar apenas as paradas alteradas".
- FTUE: `package_identification_eduction_dialog_title`="IDs ajustados conforme a ordem de rota", `_configure`="Configurar...", `removed_stop_dialog_ok`="Entendi".
- G5: `remove_stop_on_optimization_confirmation_dialog_text`='A parada "%1$s" será removida da rota na próxima otimização.'

Cada microcopy NOVA neste plano já está reformulada. O reviewer de cada task DEVE confirmar que o texto não colide com a string-fonte do Spoke.

### ⚠️ MICROCOPY FINAL TRAVADA (2026-06-14, re-auditoria dump-first — substitui os exemplos verbatim no corpo das tasks)

A re-conferência 1:1 com `values-pt-rBR/strings.xml` em 2026-06-14 pegou colisões nos corpos das tasks abaixo ("Inverter a rota" era VERBATIM; "Ordenar manualmente"/"Reotimizar rota" near-verbatim). Decisão Eduardo: "siga as boas práticas" → reformular TUDO (zero colisão, ADR-0010). **Use ESTES textos, NÃO os dos snippets de código nas tasks 6–9:**

- **T6 IdEducationDialog:** título `Como a numeração funciona` · botões `Ajustar formato` (era "Configurar") + `Entendi` · corpo: `Cada parada ganha um código (A1, A2, A3…) que segue a ordem da rota. Se você reordenar ou otimizar de novo, os códigos se ajustam sozinhos.`
- **T7 RefineRouteSheet:** título `Ajustar a rota` (era "Refinar a rota") · item1 `Inverter a ordem` (era "Inverter a rota" = VERBATIM) + sub `Percorre as paradas de trás pra frente` · item2 `Definir a ordem na mão` (era "Ordenar manualmente") + sub `Você arrasta as paradas na sequência que quiser`.
- **T8 ReoptimizeOptionsSheet:** título `Como recalcular` (era "Compare as opções") · item1 `Ajustar o que mudou` (era "Atualizar rota") + sub `Mantém a rota e reposiciona só as paradas novas` · item2 `Recalcular do zero` (era "Reotimizar rota") + sub `Refaz a sequência inteira em busca da melhor ordem`.
- **T9 ConfirmDeferredRemovalDialog:** título `Remover esta parada?` · corpo `A parada {stopLabel} fica na lista por enquanto e sai da rota na próxima vez que você otimizar.` · botões `Cancelar` + `Remover`.

> **Importante p/ os testes:** o `expect(find.text('Inverter a rota'))` etc. nos snippets de teste das tasks 7/8 também precisam ser atualizados para os textos travados acima (o test-author ajusta o matcher ao texto final). O assert "distinto" (Refinar NÃO tem item do Reotimizar e vice-versa) continua válido com os novos textos.

---

## File Structure (PR-B1)

**Estado:**
- `lib/features/routes/state/routes_provider.dart` — MOD: `+ applyOptimization(routeId, RouteOptimizationResult)` (grava routeState=optimized + stops reordenados + métricas) e `+ markStopForDeferredRemoval(routeId, stopId)` (G5).
- `lib/features/routes/state/active_route_state_provider.dart` — NEW: `@riverpod` deriva o `RouteState` da rota ativa (p/ o shell fazer o switch sem watch da lista inteira).
- `lib/features/routes/state/optimization_ftue_repository.dart` — NEW: flag one-shot `numberingAcknowledged` (`SharedPreferencesAsync`, idiom `MapPrefsRepository`).

**Apresentação:**
- `lib/features/routes/presentation/widgets/route_summary_row.dart` — NEW: "Xh Ymin · N paradas · Y km" DISPLAY puro (sem onTap — G4).
- `lib/features/routes/presentation/widgets/delivery_id_chip.dart` — NEW: chip "A1".."AN" (lê `stop.deliveryId`).
- `lib/features/routes/presentation/widgets/id_education_dialog.dart` — NEW: FTUE numeração (one-shot) {Entendi/Configurar}.
- `lib/features/routes/presentation/widgets/refine_route_sheet.dart` — NEW: "Refinar a rota" {Inverter / Ordenar manual} → retorna enum intent.
- `lib/features/routes/presentation/widgets/reoptimize_options_sheet.dart` — NEW: kebab "Alternativas de reotimização" {Atualizar / Reotimizar} → retorna enum intent.
- `lib/features/routes/presentation/widgets/confirm_deferred_removal_dialog.dart` — NEW: G5 confirm ("removida na próxima otimização").
- `lib/features/routes/presentation/widgets/pre_confirm_view.dart` — NEW: corpo do PRE-CONFIRM (summary + lista ordenada com chips + rodapé 1 tempo + 2 CTAs).
- `lib/features/routes/presentation/route_shell_page.dart` — MOD: switch sobre o RouteState ativo (`isPreConfirm`→`PreConfirmView`); `_onOptimize` aplica o resultado; wire dos sheets + FTUE.

**ADR:** nenhuma (sem mudança de stack — `shared_preferences` já instalado).

---

## Task 1: `Routes.applyOptimization` + `markStopForDeferredRemoval`

**Files:**
- Modify: `lib/features/routes/state/routes_provider.dart`
- Test: `test/features/routes/state/routes_apply_optimization_test.dart`

- [ ] **Step 1: Escrever o teste que falha**

```dart
// test/features/routes/state/routes_apply_optimization_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roteirizador_pro/features/routes/domain/optimization_state.dart';
import 'package:roteirizador_pro/features/routes/domain/optimization/route_optimizer.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';
import 'package:roteirizador_pro/features/routes/state/routes_provider.dart';

Stop _stop(String id, {bool pendingRemoval = false}) => Stop(
      id: id, lat: 0, lng: 0, streetName: id, fullAddress: id,
      pendingRemoval: pendingRemoval,
    );

void main() {
  test('applyOptimization grava routeState=optimized + stops reordenados + métricas', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final notifier = c.read(routesProvider.notifier);
    final id = notifier.createRoute(date: DateTime(2026, 6, 14));
    notifier.addStop(id, _stop('A'));
    notifier.addStop(id, _stop('B'));

    final ordered = [_stop('B').copyWith(deliveryId: 'A1'), _stop('A').copyWith(deliveryId: 'A2')];
    notifier.applyOptimization(
      id,
      RouteOptimizationResult(
        orderedStops: ordered,
        totalDurationMinutes: 18,
        totalDistanceMeters: 5200,
      ),
    );

    final route = c.read(routesProvider).firstWhere((r) => r.id == id);
    expect(route.routeState.optimization, OptimizationState.optimized);
    expect(route.routeState.isPreConfirm, isTrue);
    expect(route.totalDurationMinutes, 18);
    expect(route.totalDistanceMeters, 5200);
    expect(route.stops.map((s) => s.id).toList(), ['B', 'A']); // reordenado
    expect(route.stops.first.deliveryId, 'A1');
  });

  test('markStopForDeferredRemoval marca pendingRemoval sem remover (G5)', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final notifier = c.read(routesProvider.notifier);
    final id = notifier.createRoute(date: DateTime(2026, 6, 14));
    notifier.addStop(id, _stop('A'));
    notifier.markStopForDeferredRemoval(id, 'A');

    final route = c.read(routesProvider).firstWhere((r) => r.id == id);
    expect(route.stops, hasLength(1)); // NÃO removeu
    expect(route.stops.first.pendingRemoval, isTrue); // marcou
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `cd apps/mobile && flutter test test/features/routes/state/routes_apply_optimization_test.dart`
Expected: FAIL — `applyOptimization`/`markStopForDeferredRemoval` não existem.

- [ ] **Step 3: Implementar os dois métodos no `Routes`**

Em `lib/features/routes/state/routes_provider.dart`, adicionar os imports `import '../domain/route_state.dart';`, `import '../domain/optimization_state.dart';`, `import '../domain/optimization/route_optimizer.dart';` (se faltarem) e, dentro da classe `Routes`, adicionar:

```dart
  /// Aplica o resultado da otimização à rota: troca para o estado otimizado
  /// (PRE-CONFIRM), substitui os stops pela ordem do solver (com deliveryId já
  /// atribuído) e grava as métricas. Espelha o efeito de `optimise` no Spoke
  /// (RouteState → OPTIMIZED + optimizedAt). Sem backend — Slice 2.
  void applyOptimization(String routeId, RouteOptimizationResult result) {
    state = [
      for (final r in state)
        if (r.id == routeId)
          r.copyWith(
            routeState: r.routeState.copyWith(
              optimization: OptimizationState.optimized,
              optimizing: false,
              optimizationAttemptedAt: DateTime.now(),
            ),
            stops: result.orderedStops,
            totalDurationMinutes: result.totalDurationMinutes,
            totalDistanceMeters: result.totalDistanceMeters,
          )
        else
          r,
    ];
  }

  /// G5 — marca a parada para remoção DEFERIDA (rota já otimizada): não remove
  /// agora; a parada some na próxima otimização (o solver exclui pendingRemoval).
  /// Em rota DRAFT a remoção continua imediata via removeStop (Área 6).
  void markStopForDeferredRemoval(String routeId, String stopId) {
    state = [
      for (final r in state)
        if (r.id == routeId)
          r.copyWith(
            stops: [
              for (final s in r.stops)
                s.id == stopId ? s.copyWith(pendingRemoval: true) : s,
            ],
          )
        else
          r,
    ];
  }
```

> **Nota:** `optimizedAt` fica a cargo do controller/UI? NÃO — o Spoke grava `optimizedAt` no apply. Mas como `DateTime.now()` não é testável de forma determinística e o teste não o verifica, gravamos `optimizationAttemptedAt` (auditoria) e deixamos `optimizedAt` para quando o PR-C precisar dele com injeção de clock. O `isPreConfirm` deriva de `optimization == optimized && !confirmed`, que já é satisfeito — o teste passa sem `optimizedAt`.

- [ ] **Step 4: Rodar e ver passar**

Run: `cd apps/mobile && flutter test test/features/routes/state/routes_apply_optimization_test.dart`
Expected: PASS (2 testes).

- [ ] **Step 5: Codegen + commit**

```bash
cd apps/mobile && dart run build_runner build --delete-conflicting-outputs
cd /Users/eduardorodrigues/Documents/Projetos/Clientes/ueslei-workana/app-roteirizadorpro
git add apps/mobile/lib/features/routes/state/routes_provider.dart apps/mobile/test/features/routes/state/routes_apply_optimization_test.dart
git commit -m "feat(routes): applyOptimization + markStopForDeferredRemoval (Á7 PR-B1)"
```

---

## Task 2: `activeRouteStateProvider` (RouteState da rota ativa)

**Files:**
- Create: `lib/features/routes/state/active_route_state_provider.dart`
- Test: `test/features/routes/state/active_route_state_provider_test.dart`

- [ ] **Step 1: Escrever o teste que falha**

```dart
// test/features/routes/state/active_route_state_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roteirizador_pro/features/routes/domain/optimization_state.dart';
import 'package:roteirizador_pro/features/routes/domain/route_state.dart';
import 'package:roteirizador_pro/features/routes/state/active_route_provider.dart';
import 'package:roteirizador_pro/features/routes/state/active_route_state_provider.dart';
import 'package:roteirizador_pro/features/routes/state/routes_provider.dart';

void main() {
  test('sem rota ativa => null', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(activeRouteStateProvider), isNull);
  });

  test('com rota ativa => o RouteState dela', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final notifier = c.read(routesProvider.notifier);
    final id = notifier.createRoute(date: DateTime(2026, 6, 14));
    c.read(activeRouteIdProvider.notifier).set(id);
    expect(c.read(activeRouteStateProvider)?.isDraft, isTrue);

    notifier.update(id, const RouteState(optimization: OptimizationState.optimized));
    expect(c.read(activeRouteStateProvider)?.isPreConfirm, isTrue);
  });
}
```

> **Nota:** este teste assume `activeRouteIdProvider` ter um setter `set(id)` e `Routes` ter um `update(id, routeState)` helper. CONFIRMAR na implementação: se `activeRouteIdProvider` já expõe forma de setar (ler o arquivo real `active_route_provider.dart` no Step 3), usar a API real; se `Routes` não tem `update`, adicionar um helper mínimo OU usar `applyOptimization` da Task 1 para chegar ao estado optimized. Ajustar o teste à API real ANTES de implementar (o test-author confirma a superfície).

- [ ] **Step 2: Rodar e ver falhar**

Run: `cd apps/mobile && flutter test test/features/routes/state/active_route_state_provider_test.dart`
Expected: FAIL — provider não existe (e/ou helpers de setup).

- [ ] **Step 3: Ler a API real + implementar**

Ler `lib/features/routes/state/active_route_provider.dart` e `current_route_stops_provider.dart` para a API exata (como setar a rota ativa, como `currentRouteStopsProvider` deriva). Criar:

```dart
// lib/features/routes/state/active_route_state_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/route_state.dart';
import 'active_route_provider.dart';
import 'routes_provider.dart';

part 'active_route_state_provider.g.dart';

/// `RouteState` da rota ativa (null quando não há rota ativa). O shell observa
/// ESTE provider via `.select` para alternar entre o sheet DRAFT e a
/// `PreConfirmView` sem reconstruir a cada mudança de stops. Espelha o Spoke,
/// onde o EditRouteFragment renderiza por estado (não por tela separada).
@riverpod
RouteState? activeRouteState(Ref ref) {
  final id = ref.watch(activeRouteIdProvider);
  if (id == null) return null;
  final routes = ref.watch(routesProvider);
  return routes.where((r) => r.id == id).firstOrNull?.routeState;
}
```

Ajustar o teste de setup à API real de `activeRouteIdProvider`/`Routes` (o test-author já terá feito no Step 1 — confirmar consistência).

- [ ] **Step 4: Codegen + rodar e ver passar**

Run: `cd apps/mobile && dart run build_runner build --delete-conflicting-outputs && flutter test test/features/routes/state/active_route_state_provider_test.dart`
Expected: PASS (2 testes).

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/features/routes/state/active_route_state_provider.dart apps/mobile/lib/features/routes/state/active_route_state_provider.g.dart apps/mobile/test/features/routes/state/active_route_state_provider_test.dart
git commit -m "feat(routes): activeRouteStateProvider para o switch de estado do shell (Á7 PR-B1)"
```

---

## Task 3: `RouteSummaryRow` (display-only, G4)

**Files:**
- Create: `lib/features/routes/presentation/widgets/route_summary_row.dart`
- Test: `test/features/routes/presentation/widgets/route_summary_row_test.dart`

- [ ] **Step 1: Escrever o teste que falha**

```dart
// test/features/routes/presentation/widgets/route_summary_row_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/route_summary_row.dart';

void main() {
  testWidgets('formata "Xh Ymin · N paradas · Z,Z km"', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: RouteSummaryRow(
          durationMinutes: 75,
          stopsCount: 12,
          distanceMeters: 5200,
        ),
      ),
    ));
    expect(find.textContaining('1h 15min'), findsOneWidget);
    expect(find.textContaining('12 paradas'), findsOneWidget);
    expect(find.textContaining('5,2 km'), findsOneWidget);
  });

  testWidgets('< 60 min mostra só minutos; 1 parada é singular', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: RouteSummaryRow(
          durationMinutes: 18,
          stopsCount: 1,
          distanceMeters: 800,
        ),
      ),
    ));
    expect(find.textContaining('18 min'), findsOneWidget);
    expect(find.textContaining('1 parada'), findsOneWidget);
    expect(find.textContaining('paradas'), findsNothing);
  });

  testWidgets('é display puro — sem InkWell/GestureDetector (G4)', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: RouteSummaryRow(durationMinutes: 18, stopsCount: 2, distanceMeters: 800),
      ),
    ));
    expect(find.byType(InkWell), findsNothing);
    expect(find.byType(GestureDetector), findsNothing);
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `cd apps/mobile && flutter test test/features/routes/presentation/widgets/route_summary_row_test.dart`
Expected: FAIL — arquivo não existe.

- [ ] **Step 3: Implementar**

```dart
// lib/features/routes/presentation/widgets/route_summary_row.dart
import 'package:flutter/material.dart';

/// Linha de resumo do PRE-CONFIRM: "Xh Ymin · N paradas · Z,Z km". DISPLAY puro
/// (G4) — NÃO é clicável (sem InkWell/GestureDetector/Semantics(button)). A
/// estrutura (tempo+paradas+distância) espelha o overview do Spoke; o texto é
/// microcopy PT-BR original.
class RouteSummaryRow extends StatelessWidget {
  const RouteSummaryRow({
    required this.durationMinutes,
    required this.stopsCount,
    required this.distanceMeters,
    super.key,
  });

  final int durationMinutes;
  final int stopsCount;
  final double distanceMeters;

  String _duration() {
    if (durationMinutes < 60) return '$durationMinutes min';
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  String _stops() => stopsCount == 1 ? '1 parada' : '$stopsCount paradas';

  String _distance() {
    final km = distanceMeters / 1000;
    return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        '${_duration()} · ${_stops()} · ${_distance()}',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `cd apps/mobile && flutter test test/features/routes/presentation/widgets/route_summary_row_test.dart`
Expected: PASS (3 testes).

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/features/routes/presentation/widgets/route_summary_row.dart apps/mobile/test/features/routes/presentation/widgets/route_summary_row_test.dart
git commit -m "feat(routes): RouteSummaryRow display-only (Á7 PR-B1, G4)"
```

---

## Task 4: `DeliveryIdChip` (chip A1..AN)

**Files:**
- Create: `lib/features/routes/presentation/widgets/delivery_id_chip.dart`
- Test: `test/features/routes/presentation/widgets/delivery_id_chip_test.dart`

- [ ] **Step 1: Escrever o teste que falha**

```dart
// test/features/routes/presentation/widgets/delivery_id_chip_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/delivery_id_chip.dart';

void main() {
  testWidgets('mostra o deliveryId', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: DeliveryIdChip(deliveryId: 'A1')),
    ));
    expect(find.text('A1'), findsOneWidget);
  });

  testWidgets('deliveryId null mostra "—" (parada não numerada ainda)', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: DeliveryIdChip(deliveryId: null)),
    ));
    expect(find.text('—'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `cd apps/mobile && flutter test test/features/routes/presentation/widgets/delivery_id_chip_test.dart`
Expected: FAIL — arquivo não existe.

- [ ] **Step 3: Implementar**

```dart
// lib/features/routes/presentation/widgets/delivery_id_chip.dart
import 'package:flutter/material.dart';

/// Chip do identificador de parada ("A1".."AN" no formato Moderno, ou "1".."N"
/// no Clássico — o texto vem pronto do solver em `stop.deliveryId`). Quando a
/// parada ainda não foi numerada (`deliveryId == null`), mostra "—". Cor/estilo
/// herdam o tema (tokens do prototipo); o visual final é o polish.
class DeliveryIdChip extends StatelessWidget {
  const DeliveryIdChip({required this.deliveryId, super.key});

  final String? deliveryId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 32),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        deliveryId ?? '—',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `cd apps/mobile && flutter test test/features/routes/presentation/widgets/delivery_id_chip_test.dart`
Expected: PASS (2 testes).

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/features/routes/presentation/widgets/delivery_id_chip.dart apps/mobile/test/features/routes/presentation/widgets/delivery_id_chip_test.dart
git commit -m "feat(routes): DeliveryIdChip A1..AN (Á7 PR-B1)"
```

---

## Task 5: `OptimizationFtueRepository` (one-shot numeração)

**Files:**
- Create: `lib/features/routes/state/optimization_ftue_repository.dart`
- Test: `test/features/routes/state/optimization_ftue_repository_test.dart`

- [ ] **Step 1: Ler o idiom existente**

Ler `lib/features/routes/data/` ou onde vive o `MapPrefsRepository` (idiom `SharedPreferencesAsync`, key versionada). Run: `grep -rln 'SharedPreferencesAsync\|MapPrefsRepository' apps/mobile/lib`. Replicar o padrão (injeção da instância de prefs para teste, key `numbering_ftue_v1`).

- [ ] **Step 2: Escrever o teste que falha**

```dart
// test/features/routes/state/optimization_ftue_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roteirizador_pro/features/routes/state/optimization_ftue_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('numberingAcknowledged: false por padrão, true após acknowledge', () async {
    final repo = OptimizationFtueRepository(SharedPreferencesAsync());
    expect(await repo.isNumberingAcknowledged(), isFalse);
    await repo.acknowledgeNumbering();
    expect(await repo.isNumberingAcknowledged(), isTrue);
  });
}
```

> **Nota:** confirmar a API de `SharedPreferencesAsync` no projeto (Dart MCP/Context7 se a assinatura do mock divergir). Se o idiom local usa um wrapper diferente, seguir o wrapper (o test-author ajusta o setup ao idiom real).

- [ ] **Step 3: Rodar e ver falhar**

Run: `cd apps/mobile && flutter test test/features/routes/state/optimization_ftue_repository_test.dart`
Expected: FAIL — arquivo não existe.

- [ ] **Step 4: Implementar (espelhando o idiom do MapPrefsRepository)**

```dart
// lib/features/routes/state/optimization_ftue_repository.dart
import 'package:shared_preferences/shared_preferences.dart';

/// Flags one-shot dos FTUEs de otimização (idiom de `MapPrefsRepository`).
/// `numberingAcknowledged` = o usuário já viu o educativo de numeração; a 2ª
/// otimização não re-mostra o modal. Persistido em `SharedPreferencesAsync`.
class OptimizationFtueRepository {
  OptimizationFtueRepository(this._prefs);
  final SharedPreferencesAsync _prefs;

  static const _numberingKey = 'numbering_ftue_v1';

  Future<bool> isNumberingAcknowledged() async =>
      await _prefs.getBool(_numberingKey) ?? false;

  Future<void> acknowledgeNumbering() async =>
      _prefs.setBool(_numberingKey, true);
}
```

- [ ] **Step 5: Rodar e ver passar**

Run: `cd apps/mobile && flutter test test/features/routes/state/optimization_ftue_repository_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add apps/mobile/lib/features/routes/state/optimization_ftue_repository.dart apps/mobile/test/features/routes/state/optimization_ftue_repository_test.dart
git commit -m "feat(routes): OptimizationFtueRepository one-shot numeração (Á7 PR-B1)"
```

---

## Task 6: `IdEducationDialog` (FTUE numeração)

**Files:**
- Create: `lib/features/routes/presentation/widgets/id_education_dialog.dart`
- Test: `test/features/routes/presentation/widgets/id_education_dialog_test.dart`

- [ ] **Step 1: Escrever o teste que falha**

```dart
// test/features/routes/presentation/widgets/id_education_dialog_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/id_education_dialog.dart';

void main() {
  testWidgets('mostra título + "Entendi" + "Configurar"; "Entendi" retorna acknowledge', (tester) async {
    IdEducationChoice? choice;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async => choice = await showIdEducationDialog(context),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Como a numeração funciona'), findsOneWidget);
    expect(find.text('Entendi'), findsOneWidget);
    expect(find.text('Configurar'), findsOneWidget);
    await tester.tap(find.text('Entendi'));
    await tester.pumpAndSettle();
    expect(choice, IdEducationChoice.acknowledge);
  });
}
```

> **Microcopy original** (NÃO verbatim — o Spoke usa "IDs ajustados conforme a ordem de rota"): título "Como a numeração funciona", corpo reformulado, "Entendi"/"Configurar".

- [ ] **Step 2: Rodar e ver falhar**

Run: `cd apps/mobile && flutter test test/features/routes/presentation/widgets/id_education_dialog_test.dart`
Expected: FAIL — arquivo não existe.

- [ ] **Step 3: Implementar**

```dart
// lib/features/routes/presentation/widgets/id_education_dialog.dart
import 'package:flutter/material.dart';

/// Escolha do usuário no FTUE de numeração.
enum IdEducationChoice { acknowledge, configure }

/// FTUE one-shot: explica que o ID de cada parada (A1..AN) segue a ORDEM da
/// rota e muda quando a ordem muda. ESTRUTURA espelha o
/// `package_identification_eduction_dialog_*` do Spoke (título + corpo +
/// Entendi/Configurar), mas o TEXTO é microcopy PT-BR ORIGINAL (ADR-0010),
/// nunca verbatim. "Configurar" levará ao formato do ID (Á10) — aqui é
/// honest-stub no caller.
Future<IdEducationChoice?> showIdEducationDialog(BuildContext context) {
  return showDialog<IdEducationChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Como a numeração funciona'),
      content: const Text(
        'Cada parada ganha um código (A1, A2, A3...) que segue a ordem da rota. '
        'Se você reordenar ou otimizar de novo, os códigos se ajustam sozinhos.',
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(IdEducationChoice.configure),
          child: const Text('Configurar'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(IdEducationChoice.acknowledge),
          child: const Text('Entendi'),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `cd apps/mobile && flutter test test/features/routes/presentation/widgets/id_education_dialog_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/features/routes/presentation/widgets/id_education_dialog.dart apps/mobile/test/features/routes/presentation/widgets/id_education_dialog_test.dart
git commit -m "feat(routes): IdEducationDialog FTUE numeração (Á7 PR-B1)"
```

---

## Task 7: `RefineRouteSheet` (Refinar a rota — Inverter / Ordenar manual)

**Files:**
- Create: `lib/features/routes/presentation/widgets/refine_route_sheet.dart`
- Test: `test/features/routes/presentation/widgets/refine_route_sheet_test.dart`

- [ ] **Step 1: Escrever o teste que falha**

```dart
// test/features/routes/presentation/widgets/refine_route_sheet_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/refine_route_sheet.dart';

void main() {
  testWidgets('mostra "Inverter a rota" e "Ordenar manualmente"; tap Inverter retorna invert', (tester) async {
    RefineRouteChoice? choice;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async => choice = await showRefineRouteSheet(context),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Inverter a rota'), findsOneWidget);
    expect(find.text('Ordenar manualmente'), findsOneWidget);
    // Distinto do Reotimizar: NÃO tem "Reotimizar"/"Atualizar".
    expect(find.text('Reotimizar'), findsNothing);
    await tester.tap(find.text('Inverter a rota'));
    await tester.pumpAndSettle();
    expect(choice, RefineRouteChoice.invert);
  });

  testWidgets('tap "Ordenar manualmente" retorna manualOrder', (tester) async {
    RefineRouteChoice? choice;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async => choice = await showRefineRouteSheet(context),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ordenar manualmente'));
    await tester.pumpAndSettle();
    expect(choice, RefineRouteChoice.manualOrder);
  });
}
```

> **Microcopy original** (estrutura do `refine_route_dialog_*`, texto reformulado). "Ordenar manualmente" abrirá o OrderStopGroups (PR-D) — aqui o caller faz honest-stub "Em breve".

- [ ] **Step 2: Rodar e ver falhar**

Run: `cd apps/mobile && flutter test test/features/routes/presentation/widgets/refine_route_sheet_test.dart`
Expected: FAIL — arquivo não existe.

- [ ] **Step 3: Implementar**

```dart
// lib/features/routes/presentation/widgets/refine_route_sheet.dart
import 'package:flutter/material.dart';

/// Escolha no sheet "Refinar a rota". DISTINTO do `ReoptimizeOptionsSheet`
/// (kebab) — ver lesson_area7_refinar_vs_reotimizar_two_dialogs.
enum RefineRouteChoice { invert, manualOrder }

/// Sheet aberto pelo botão "Refinar" (rodapé do PRE-CONFIRM). ESTRUTURA espelha
/// o `refine_route_dialog_*` do Spoke {Inverter a rota / Ordenar a rota
/// manualmente}; TEXTO é microcopy PT-BR ORIGINAL (ADR-0010). NÃO confundir com
/// o "Reotimizar rota..." do kebab (`ReoptimizeOptionsSheet`).
Future<RefineRouteChoice?> showRefineRouteSheet(BuildContext context) {
  return showModalBottomSheet<RefineRouteChoice>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.swap_vert),
            title: const Text('Inverter a rota'),
            subtitle: const Text('Percorre as paradas na ordem contrária'),
            onTap: () =>
                Navigator.of(context).pop(RefineRouteChoice.invert),
          ),
          ListTile(
            leading: const Icon(Icons.gesture),
            title: const Text('Ordenar manualmente'),
            subtitle: const Text('Defina a sequência desenhando no mapa'),
            onTap: () =>
                Navigator.of(context).pop(RefineRouteChoice.manualOrder),
          ),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `cd apps/mobile && flutter test test/features/routes/presentation/widgets/refine_route_sheet_test.dart`
Expected: PASS (2 testes).

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/features/routes/presentation/widgets/refine_route_sheet.dart apps/mobile/test/features/routes/presentation/widgets/refine_route_sheet_test.dart
git commit -m "feat(routes): RefineRouteSheet (Inverter/Ordenar manual) (Á7 PR-B1)"
```

---

## Task 8: `ReoptimizeOptionsSheet` (kebab — Atualizar / Reotimizar)

**Files:**
- Create: `lib/features/routes/presentation/widgets/reoptimize_options_sheet.dart`
- Test: `test/features/routes/presentation/widgets/reoptimize_options_sheet_test.dart`

- [ ] **Step 1: Escrever o teste que falha**

```dart
// test/features/routes/presentation/widgets/reoptimize_options_sheet_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/reoptimize_options_sheet.dart';

void main() {
  testWidgets('mostra "Atualizar rota" e "Reotimizar rota"; tap Reotimizar retorna reoptimize', (tester) async {
    ReoptimizeChoice? choice;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async => choice = await showReoptimizeOptionsSheet(context),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Atualizar rota'), findsOneWidget);
    expect(find.text('Reotimizar rota'), findsOneWidget);
    // Distinto do Refinar: NÃO tem "Inverter a rota".
    expect(find.text('Inverter a rota'), findsNothing);
    await tester.tap(find.text('Reotimizar rota'));
    await tester.pumpAndSettle();
    expect(choice, ReoptimizeChoice.reoptimize);
  });

  testWidgets('tap "Atualizar rota" retorna update', (tester) async {
    ReoptimizeChoice? choice;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async => choice = await showReoptimizeOptionsSheet(context),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Atualizar rota'));
    await tester.pumpAndSettle();
    expect(choice, ReoptimizeChoice.update);
  });
}
```

> **Microcopy original** (estrutura do `optimization_explainer_*` / `optimization_dialog_*`, texto reformulado). `reoptimize`→`OptimizeType.restartRoute`; `update`→`OptimizeType.reorderFlexible` (mapeado no caller, Task 11).

- [ ] **Step 2: Rodar e ver falhar**

Run: `cd apps/mobile && flutter test test/features/routes/presentation/widgets/reoptimize_options_sheet_test.dart`
Expected: FAIL — arquivo não existe.

- [ ] **Step 3: Implementar**

```dart
// lib/features/routes/presentation/widgets/reoptimize_options_sheet.dart
import 'package:flutter/material.dart';

/// Escolha no sheet "Alternativas de reotimização" (kebab "Reotimizar
/// rota..."). DISTINTO do `RefineRouteSheet` — ver
/// lesson_area7_refinar_vs_reotimizar_two_dialogs.
enum ReoptimizeChoice { update, reoptimize }

/// Sheet aberto pelo kebab "Reotimizar rota...". ESTRUTURA espelha o
/// `optimization_explainer_*` do Spoke (Compare as opções → Atualizar /
/// Reotimizar); TEXTO é microcopy PT-BR ORIGINAL (ADR-0010). `update` reordena
/// só as paradas alteradas (OptimizeType.reorderFlexible); `reoptimize`
/// recalcula do zero (OptimizeType.restartRoute).
Future<ReoptimizeChoice?> showReoptimizeOptionsSheet(BuildContext context) {
  return showModalBottomSheet<ReoptimizeChoice>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.update),
            title: const Text('Atualizar rota'),
            subtitle: const Text('Reordena só o que mudou, mantendo o resto'),
            onTap: () => Navigator.of(context).pop(ReoptimizeChoice.update),
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: const Text('Reotimizar rota'),
            subtitle: const Text('Recalcula tudo do zero em busca da melhor ordem'),
            onTap: () =>
                Navigator.of(context).pop(ReoptimizeChoice.reoptimize),
          ),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `cd apps/mobile && flutter test test/features/routes/presentation/widgets/reoptimize_options_sheet_test.dart`
Expected: PASS (2 testes).

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/features/routes/presentation/widgets/reoptimize_options_sheet.dart apps/mobile/test/features/routes/presentation/widgets/reoptimize_options_sheet_test.dart
git commit -m "feat(routes): ReoptimizeOptionsSheet (Atualizar/Reotimizar) (Á7 PR-B1)"
```

---

## Task 9: `ConfirmDeferredRemovalDialog` (G5)

**Files:**
- Create: `lib/features/routes/presentation/widgets/confirm_deferred_removal_dialog.dart`
- Test: `test/features/routes/presentation/widgets/confirm_deferred_removal_dialog_test.dart`

- [ ] **Step 1: Escrever o teste que falha**

```dart
// test/features/routes/presentation/widgets/confirm_deferred_removal_dialog_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/confirm_deferred_removal_dialog.dart';

void main() {
  testWidgets('explica remoção deferida + confirma retorna true', (tester) async {
    bool? confirmed;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async =>
              confirmed = await showConfirmDeferredRemovalDialog(context, stopLabel: 'A2'),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.textContaining('próxima'), findsOneWidget); // "na próxima otimização"
    await tester.tap(find.text('Remover'));
    await tester.pumpAndSettle();
    expect(confirmed, isTrue);
  });
}
```

> **Microcopy original** (estrutura de `remove_stop_on_optimization_confirmation_dialog_text`, texto reformulado).

- [ ] **Step 2: Rodar e ver falhar**

Run: `cd apps/mobile && flutter test test/features/routes/presentation/widgets/confirm_deferred_removal_dialog_test.dart`
Expected: FAIL — arquivo não existe.

- [ ] **Step 3: Implementar**

```dart
// lib/features/routes/presentation/widgets/confirm_deferred_removal_dialog.dart
import 'package:flutter/material.dart';

/// G5 — confirma a remoção DEFERIDA de uma parada numa rota JÁ otimizada: a
/// parada não some na hora, sai na próxima otimização. ESTRUTURA espelha o
/// `ConfirmDeleteStopOnOptimizationDialog` do Spoke; TEXTO é microcopy PT-BR
/// ORIGINAL (ADR-0010). Retorna true se o usuário confirmar.
Future<bool?> showConfirmDeferredRemovalDialog(
  BuildContext context, {
  required String stopLabel,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Remover esta parada?'),
      content: Text(
        'A parada $stopLabel continua na lista por enquanto e sai da rota na '
        'próxima vez que você otimizar.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Remover'),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `cd apps/mobile && flutter test test/features/routes/presentation/widgets/confirm_deferred_removal_dialog_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/features/routes/presentation/widgets/confirm_deferred_removal_dialog.dart apps/mobile/test/features/routes/presentation/widgets/confirm_deferred_removal_dialog_test.dart
git commit -m "feat(routes): ConfirmDeferredRemovalDialog (Á7 PR-B1, G5)"
```

---

## Task 10: `PreConfirmView` (summary + lista ordenada com chips + rodapé)

**Files:**
- Create: `lib/features/routes/presentation/widgets/pre_confirm_view.dart`
- Test: `test/features/routes/presentation/widgets/pre_confirm_view_test.dart`

- [ ] **Step 1: Escrever o teste que falha**

```dart
// test/features/routes/presentation/widgets/pre_confirm_view_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/delivery_id_chip.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/pre_confirm_view.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/route_summary_row.dart';

Stop _stop(String id, String deliveryId) => Stop(
      id: id, lat: 0, lng: 0, streetName: 'Rua $id', fullAddress: 'Rua $id, 100',
      deliveryId: deliveryId,
    );

void main() {
  testWidgets('renderiza summary + lista ordenada com chips + 2 CTAs', (tester) async {
    var refined = false;
    var confirmed = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PreConfirmView(
          stops: [_stop('a', 'A1'), _stop('b', 'A2')],
          durationMinutes: 18,
          distanceMeters: 5200,
          onRefine: () => refined = true,
          onConfirm: () => confirmed = true,
          onStopTap: (_) {},
        ),
      ),
    ));
    expect(find.byType(RouteSummaryRow), findsOneWidget);
    expect(find.byType(DeliveryIdChip), findsNWidgets(2));
    expect(find.text('A1'), findsOneWidget);
    expect(find.text('Refinar'), findsOneWidget);
    expect(find.text('Confirmar'), findsOneWidget);

    await tester.tap(find.text('Refinar'));
    expect(refined, isTrue);
    await tester.tap(find.text('Confirmar'));
    expect(confirmed, isTrue);
  });

  testWidgets('usa ListView.builder (lista de dados de provider)', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PreConfirmView(
          stops: [_stop('a', 'A1')],
          durationMinutes: 5,
          distanceMeters: 800,
          onRefine: () {},
          onConfirm: () {},
          onStopTap: (_) {},
        ),
      ),
    ));
    expect(find.byType(ListView), findsOneWidget);
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `cd apps/mobile && flutter test test/features/routes/presentation/widgets/pre_confirm_view_test.dart`
Expected: FAIL — arquivo não existe.

- [ ] **Step 3: Implementar**

```dart
// lib/features/routes/presentation/widgets/pre_confirm_view.dart
import 'package:flutter/material.dart';

import '../../domain/stop.dart';
import 'delivery_id_chip.dart';
import 'route_summary_row.dart';

/// Corpo do PRE-CONFIRM (metade inferior do shell nesta fatia; o mapa+polyline
/// da metade superior é o PR-B2). Mostra a linha de resumo (display-only, G4),
/// a lista de paradas NA ORDEM OTIMIZADA com chip de ID, e o rodapé com 1
/// indicador de tempo + 2 CTAs ("Refinar" / "Confirmar"). Espelha a estrutura
/// do PRE-CONFIRM do Spoke; microcopy original.
class PreConfirmView extends StatelessWidget {
  const PreConfirmView({
    required this.stops,
    required this.durationMinutes,
    required this.distanceMeters,
    required this.onRefine,
    required this.onConfirm,
    required this.onStopTap,
    super.key,
  });

  final List<Stop> stops;
  final int durationMinutes;
  final double distanceMeters;
  final VoidCallback onRefine;
  final VoidCallback onConfirm;
  final void Function(String stopId) onStopTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RouteSummaryRow(
          durationMinutes: durationMinutes,
          stopsCount: stops.length,
          distanceMeters: distanceMeters,
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: stops.length,
            itemBuilder: (context, i) {
              final s = stops[i];
              return ListTile(
                leading: DeliveryIdChip(deliveryId: s.deliveryId),
                title: Text(s.streetName),
                subtitle: Text(s.fullAddress),
                onTap: () => onStopTap(s.id),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRefine,
                    child: const Text('Refinar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onConfirm,
                    child: const Text('Confirmar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```

> **Nota:** o "1 indicador de tempo" do rodapé (spec §4) é o `RouteSummaryRow` no topo do corpo nesta fatia; um indicador de tempo dedicado no rodapé (estilo Spoke, ao lado dos CTAs) entra no PR-B2 junto com o mapa, se o dump confirmar a posição. Aqui o summary cobre o display de tempo sem onTap (G4 respeitado). NÃO adicionar 2º indicador de tempo agora (evita divergência).

- [ ] **Step 4: Rodar e ver passar**

Run: `cd apps/mobile && flutter test test/features/routes/presentation/widgets/pre_confirm_view_test.dart`
Expected: PASS (2 testes).

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/features/routes/presentation/widgets/pre_confirm_view.dart apps/mobile/test/features/routes/presentation/widgets/pre_confirm_view_test.dart
git commit -m "feat(routes): PreConfirmView summary+lista+chips+CTAs (Á7 PR-B1)"
```

---

## Task 11: Wire no shell — switch de estado + aplicar otimização + FTUE + sheets

**Files:**
- Modify: `lib/features/routes/presentation/route_shell_page.dart`
- Test: `test/features/routes/presentation/widgets/route_shell_preconfirm_test.dart`

- [ ] **Step 1: Ler o `_onOptimize` e o ponto de switch atuais**

Run: `cd apps/mobile && grep -n '_onOptimize\|activeRouteState\|_ActiveRouteSheet(\|OptimizationSuccess' lib/features/routes/presentation/route_shell_page.dart`. Localizar (a) o `_onOptimize` (que hoje mostra SnackBar no `OptimizationSuccess`), (b) onde o corpo da rota ativa é montado (o `_ActiveRouteSheet`), (c) o `build` do `_RouteShellPageState`.

- [ ] **Step 2: Escrever o teste de widget (regra do switch)**

```dart
// test/features/routes/presentation/widgets/route_shell_preconfirm_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/pre_confirm_view.dart';

// O switch real (RouteState ativo → PreConfirmView vs sheet DRAFT) vive no
// _RouteShellPageState privado e é coberto pelo integration_test do fechamento
// da Á7. Aqui pinamos a regra de seleção via um harness mínimo que replica a
// condição (o widget público PreConfirmView aparece quando isPreConfirm).
Stop _stop(String id) => Stop(id: id, lat: 0, lng: 0, streetName: id, fullAddress: id, deliveryId: 'A1');

void main() {
  testWidgets('PreConfirmView visível em PRE-CONFIRM, ausente em DRAFT', (tester) async {
    Widget harness({required bool isPreConfirm}) => MaterialApp(
          home: Scaffold(
            body: isPreConfirm
                ? PreConfirmView(
                    stops: [_stop('a')],
                    durationMinutes: 5,
                    distanceMeters: 800,
                    onRefine: () {},
                    onConfirm: () {},
                    onStopTap: (_) {},
                  )
                : const SizedBox.shrink(),
          ),
        );
    await tester.pumpWidget(harness(isPreConfirm: false));
    expect(find.byType(PreConfirmView), findsNothing);
    await tester.pumpWidget(harness(isPreConfirm: true));
    expect(find.byType(PreConfirmView), findsOneWidget);
  });
}
```

> **Honestidade do teste:** a montagem real dentro do `_RouteShellPageState` privado é coberta pelo integration_test (fechamento da Á7). Este widget test pina a regra do widget público — idiom já usado no `route_shell_optimize_cta_test.dart` do PR-A.

- [ ] **Step 3: Rodar e ver passar (verde — é a regra)**

Run: `cd apps/mobile && flutter test test/features/routes/presentation/widgets/route_shell_preconfirm_test.dart`
Expected: PASS (1 teste).

- [ ] **Step 4: `_onOptimize` aplica o resultado (substitui o SnackBar honest-stub)**

No `_onOptimize` do `_RouteShellPageState`, no `case OptimizationSuccess(:final result):`, substituir o `ScaffoldMessenger...SnackBar(...)` por:

```dart
      case OptimizationSuccess(:final result):
        final routeId = ref.read(activeRouteIdProvider);
        if (routeId == null) return;
        // FTUE one-shot ANTES de aplicar (Spoke mostra o educativo na 1ª vez).
        final ftue = ref.read(optimizationFtueRepositoryProvider);
        if (!await ftue.isNumberingAcknowledged()) {
          if (!mounted) return;
          final choice = await showIdEducationDialog(context);
          if (choice == IdEducationChoice.acknowledge) {
            await ftue.acknowledgeNumbering();
          }
          // "Configurar" leva ao formato do ID (Á10) — honest-stub aqui.
          if (choice == IdEducationChoice.configure && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ajuste de formato do ID — em breve.')),
            );
          }
        }
        ref.read(routesProvider.notifier).applyOptimization(routeId, result);
        // O switch de estado do build leva ao PreConfirmView automaticamente.
```

Adicionar o provider do FTUE repo. Em `optimization_ftue_repository.dart` (Task 5) adicionar (ou em `optimization_controller.dart` junto ao `routeOptimizerProvider`):

```dart
@Riverpod(keepAlive: true)
OptimizationFtueRepository optimizationFtueRepository(Ref ref) =>
    OptimizationFtueRepository(SharedPreferencesAsync());
```

Imports no shell: `optimization_ftue_repository.dart`, `widgets/id_education_dialog.dart`.

- [ ] **Step 5: Montar o switch de estado no `build` do `_RouteShellPageState`**

No `build`, derivar o estado ativo: `final activeState = ref.watch(activeRouteStateProvider);`. Onde hoje o `_ActiveRouteSheet` é montado (o sheet com `stops`), envolver numa decisão: se `activeState?.isPreConfirm == true`, montar o `PreConfirmView` no lugar do conteúdo do sheet (mantendo o mapa atual em cima — o PR-B2 troca o mapa). Passar:
- `stops: stops` (já reordenados pelo applyOptimization),
- `durationMinutes`/`distanceMeters`: ler da rota ativa (`ref.watch(routesProvider.select(...))` para `totalDurationMinutes`/`totalDistanceMeters` da rota ativa; null-safe com `?? 0`),
- `onRefine: _onRefine` (Step 6),
- `onConfirm: _onConfirm` (honest-stub: o Ready-to-Run é PR-C → SnackBar "Confirmação — em breve" OU já grava `confirmed:true`? NÃO — confirmar leva ao Ready-to-Run que é PR-C; aqui é honest-stub observável),
- `onStopTap`: o mesmo handler de editar parada existente.

> **Nota de escopo:** `onConfirm` é honest-stub no PR-B1 (o Ready-to-Run é PR-C). Mostrar SnackBar "Tudo certo — a confirmação final chega na próxima etapa." (observável, sem bug silencioso). NÃO gravar `confirmed:true` ainda (sem destino Ready-to-Run, o estado ficaria órfão).

- [ ] **Step 6: `_onRefine` + `_onReoptimize` (kebab) no `_RouteShellPageState`**

```dart
  Future<void> _onRefine() async {
    final choice = await showRefineRouteSheet(context);
    if (!mounted || choice == null) return;
    final routeId = ref.read(activeRouteIdProvider);
    if (routeId == null) return;
    switch (choice) {
      case RefineRouteChoice.invert:
        final stops = ref.read(currentRouteStopsProvider);
        final outcome =
            await ref.read(optimizationControllerProvider.notifier).optimize(
                  start: GeoPoint(stops.first.lat, stops.first.lng),
                  stops: stops,
                  type: OptimizeType.reorderFlexible,
                  direction: OptimizeDirection.reverse,
                );
        if (!mounted) return;
        if (outcome is OptimizationSuccess) {
          ref.read(routesProvider.notifier).applyOptimization(routeId, outcome.result);
        }
      case RefineRouteChoice.manualOrder:
        // OrderStopGroups é o PR-D — honest-stub observável.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ordenar no mapa — em breve.')),
        );
    }
  }
```

O kebab "Reotimizar rota..." é wirado onde o kebab da rota ativa existe (se já houver um PopupMenu no shell; senão, fica para o PR onde o kebab é montado — confirmar via grep `PopupMenuButton`/kebab no shell. Se o kebab NÃO existe ainda no shell, NÃO criar aqui — registrar como item do PR-C/PR-D e o `ReoptimizeOptionsSheet` fica testado mas montado depois; declarar no TODO).

Imports: `widgets/refine_route_sheet.dart`, `widgets/reoptimize_options_sheet.dart`, `domain/optimize_direction.dart` (já?).

- [ ] **Step 7: Wire da remoção deferida (G5) no caminho de remover parada**

Localizar onde a remoção de parada é disparada hoje (Área 6 — provavelmente no editor de parada ou num swipe/menu). Run: `grep -rn 'removeStop\|onDeleteStop\|Remover' lib/features/routes/presentation`. No ponto que chama `removeStop`, ramificar por estado: se `ref.read(activeRouteStateProvider)?.isPreConfirm == true` (rota otimizada), chamar `showConfirmDeferredRemovalDialog` + `markStopForDeferredRemoval`; senão (DRAFT), manter o `removeStop` imediato (Área 6).

> **Nota:** se o ponto de remoção estiver fora do escopo do shell (ex.: dentro do `edit_stop_page`), e wirar lá exigir tocar muito código da Á6, registrar como sub-item e cobrir o ramo otimizado no PR-C/fechamento — mas o `ConfirmDeferredRemovalDialog` + `markStopForDeferredRemoval` já ficam prontos e testados. Decidir ao ler o código real; NÃO forçar wire que toque demais a Á6.

- [ ] **Step 8: Codegen + analyze + suite**

Run: `cd apps/mobile && dart run build_runner build --delete-conflicting-outputs && flutter analyze --no-pub lib/features/routes && flutter test`
Expected: analyze sem lint novo; suite verde (baseline 638 + os deste PR). Resolver qualquer switch não-exaustivo (o `RouteState` ativo no build deve cobrir os getters relevantes ou ter um else/default seguro — como é `RouteState?` derivado, usar `if (isPreConfirm)`/`else` em vez de switch exaustivo).

- [ ] **Step 9: Commit**

```bash
git add apps/mobile/lib/features/routes/presentation/route_shell_page.dart apps/mobile/lib/features/routes/state/optimization_ftue_repository.dart apps/mobile/lib/features/routes/state/optimization_ftue_repository.g.dart apps/mobile/test/features/routes/presentation/widgets/route_shell_preconfirm_test.dart
git commit -m "feat(routes): wire PRE-CONFIRM no shell (aplicar otimização + FTUE + Refinar) (Á7 PR-B1)"
```

---

## Task 12: Gates do PR-B1 + abrir o PR

**Files:** (verificação)

- [ ] **Step 1: Suite + analyze completos**

Run: `cd apps/mobile && flutter analyze && flutter test`
Expected: analyze sem lint NOVO (baseline pré-existente); suite verde (638 + ~22 novos).

- [ ] **Step 2: Dispatch `flutter-perf-auditor`**

Sobre os widgets novos (`pre_confirm_view.dart` [tem ListView.builder — confirmar disciplina], `route_summary_row.dart`, `delivery_id_chip.dart`, os sheets/dialogs) + o delta do shell. Resolver must-fix.

- [ ] **Step 3: Dispatch `spoke-parity-checker` D4 dump-only**

Comparar a implementação contra `refine_route_dialog_*`/`optimization_explainer_*`/`package_identification_eduction_*`/`remove_stop_on_optimization_*` + o design doc. **Confirmar especialmente:** (a) Refinar ≠ Reotimizar (2 sheets, conteúdo certo em cada); (b) NENHUMA microcopy é verbatim das strings pt-rBR. 0 must-fix p/ merge.

- [ ] **Step 4: Atualizar TODO + CHANGELOG + session log**

`TODO.md` §Á7: marcar PR-B1 entregue + débito (onConfirm honest-stub até PR-C; mapa+polyline = PR-B2; kebab Reotimizar montado quando o kebab existir; remoção deferida wirada se viável sem tocar a Á6). `docs/10-CHANGELOG.md` + session log da execução.

- [ ] **Step 5: Commit + push + abrir PR**

```bash
git add TODO.md docs/
git commit -m "docs: Á7 PR-B1 — TODO + CHANGELOG + session log"
git push -u origin feat/m2-slice-2-area-7-pre-confirm
gh pr create --base develop --title "feat(routes): Área 7 PR-B1 — PRE-CONFIRM estrutura (aplicar otimização + lista+chips + summary + FTUE + Refinar/Reotimizar + remoção deferida)" --body "<resumo do que entrou + débito + gates>"
```

> **integration_test no M54 + smoke E2E release = fechamento da Á7** (após PR-D). O PR-B1 entrega estrutura testável por widget/unit; o fluxo navegável completo (DRAFT→otimizar→PRE-CONFIRM→Refinar→Confirmar) com o mapa é validado no fechamento.

---

## Self-review (writing-plans)

**Cobertura da spec (PR-B):** PreConfirmView ✅(T10) · RouteSummaryRow display-only G4 ✅(T3) · chips A1..AN ✅(T4) · 1 tempo + 2 CTAs ✅(T10) · IdEducationDialog one-shot ✅(T5/T6/T11) · RefineRouteSheet Inverter real ✅(T7/T11) · Ordenar-manual→stub PR-D ✅(T7/T11) · ReoptimizeOptionsSheet ✅(T8, montado quando o kebab existir) · remoção deferida G5 ✅(T1/T9/T11). **Fora do B1 (→B2):** mapa+polyline+markers numerados (declarado). **Fora do B1 (→PR-C):** Confirmar→Ready-to-Run (onConfirm é honest-stub).

**Placeholders:** nenhum "TBD"; cada task tem código completo. As 3 notas de "decidir ao ler o código real" (T2 setup, T11.6 kebab, T11.7 remoção) são pontos onde a API real do repo precisa ser confirmada — o implementer LÊ o arquivo e ajusta, com o fallback explícito (não forçar wire que toque demais). Isso é honesto, não placeholder.

**Consistência de tipos:** `RouteOptimizationResult`/`OptimizeType`/`OptimizeDirection`/`GeoPoint` do PR-A reusados; enums de intent novos (`RefineRouteChoice`/`ReoptimizeChoice`/`IdEducationChoice`) definidos em suas tasks e consumidos no wire (T11) com os mesmos nomes. `applyOptimization`/`markStopForDeferredRemoval` (T1) consumidos em T11.
