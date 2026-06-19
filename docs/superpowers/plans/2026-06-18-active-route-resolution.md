# Active Route Resolution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** O shell de rota NUNCA é exibido sem uma rota ativa — ao abrir o app (cold start/restart), o `activeRouteId` é restaurado do disco; se ausente/inválido, auto-seleciona a rota mais recente; se não houver rotas, cria uma. Mata o bug "Nenhuma rota ativa selecionada" ao adicionar parada.

**Architecture:** Fiel ao Spoke (`ValidateActiveRoute` + `activeRouteRef` persistido no Firestore — ver `docs/sessions`/dump). RotPro replica com: (1) `ActiveRouteRepository` que persiste o id em `SharedPreferencesAsync` (idiom do `OptimizationFtueRepository`); (2) `ActiveRouteId.setActiveRoute` grava no repo (persiste); (3) um método `resolveActiveRoute()` no notifier que executa a cadeia restore→most-recent→create, chamado no boot do `RouteShellPage`. Proxy de "mais recente": `Route.date` (não há `lastEdited` até Slice 3 — divergência consciente documentada).

**Tech Stack:** Flutter + Riverpod 3 (`@riverpod` codegen), `SharedPreferencesAsync`, `flutter_test` + `mocktail`.

---

## File Structure

- **Create** `lib/features/routes/data/active_route_repository.dart` — persiste/lê o id da rota ativa em `SharedPreferencesAsync`. Responsabilidade única: I/O de persistência do `activeRouteId`. Espelha `optimization_ftue_repository.dart`.
- **Modify** `lib/features/routes/state/active_route_provider.dart` — `setActiveRoute` passa a persistir via repo; novo método `resolveActiveRoute()` (cadeia restore→recent→create); o provider lê o repo.
- **Modify** `lib/features/routes/presentation/route_shell_page.dart` — no `initState` postFrame, se `activeRouteId == null`, chama `resolveActiveRoute()`.
- **Test** `test/features/routes/data/active_route_repository_test.dart`, `test/features/routes/state/active_route_provider_test.dart`.

---

### Task 1: ActiveRouteRepository (persistência do id)

**Files:**
- Create: `lib/features/routes/data/active_route_repository.dart`
- Test: `test/features/routes/data/active_route_repository_test.dart`

- [ ] **Step 1: Write the failing test**

`test/features/routes/data/active_route_repository_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roteirizador_pro/features/routes/data/active_route_repository.dart';

class _MockPrefs extends Mock implements SharedPreferencesAsync {}

void main() {
  late _MockPrefs prefs;
  late ActiveRouteRepository repo;

  setUp(() {
    prefs = _MockPrefs();
    repo = ActiveRouteRepository(prefs);
  });

  test('read() returns the persisted id', () async {
    when(() => prefs.getString('active_route_id_v1'))
        .thenAnswer((_) async => 'route-42');
    expect(await repo.read(), 'route-42');
  });

  test('read() returns null when nothing persisted', () async {
    when(() => prefs.getString('active_route_id_v1'))
        .thenAnswer((_) async => null);
    expect(await repo.read(), isNull);
  });

  test('write(id) persists the id under the v1 key', () async {
    when(() => prefs.setString('active_route_id_v1', 'route-7'))
        .thenAnswer((_) async {});
    await repo.write('route-7');
    verify(() => prefs.setString('active_route_id_v1', 'route-7')).called(1);
  });

  test('write(null) removes the key (no orphan id)', () async {
    when(() => prefs.remove('active_route_id_v1')).thenAnswer((_) async {});
    await repo.write(null);
    verify(() => prefs.remove('active_route_id_v1')).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd apps/mobile && flutter test test/features/routes/data/active_route_repository_test.dart`
Expected: FAIL — `active_route_repository.dart` não existe (erro de import/compile). Após o stub do Step 3, FAIL na asserção.

- [ ] **Step 3: Write minimal implementation**

`lib/features/routes/data/active_route_repository.dart`:
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'active_route_repository.g.dart';

/// Production-backed repo (idiom de `optimizationFtueRepositoryProvider`).
@Riverpod(keepAlive: true)
ActiveRouteRepository activeRouteRepository(Ref ref) =>
    ActiveRouteRepository(SharedPreferencesAsync());

/// Persists the id of the active route so the shell can restore it across
/// app restarts. Mirrors Spoke's persisted `User.activeRouteRef` (Firestore)
/// — here the equivalent is a local SharedPreferences string. Stateless
/// beyond the injected [SharedPreferencesAsync].
class ActiveRouteRepository {
  ActiveRouteRepository(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const String _key = 'active_route_id_v1';

  /// The persisted active-route id, or null if none was ever stored.
  Future<String?> read() => _prefs.getString(_key);

  /// Persists [id], or removes the key entirely when [id] is null (so a
  /// cleared active route never leaves an orphan id on disk).
  Future<void> write(String? id) {
    if (id == null) return _prefs.remove(_key);
    return _prefs.setString(_key, id);
  }
}
```

- [ ] **Step 4: Run codegen + test to verify it passes**

Run: `cd apps/mobile && dart run build_runner build --delete-conflicting-outputs && flutter test test/features/routes/data/active_route_repository_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/features/routes/data/active_route_repository.dart apps/mobile/lib/features/routes/data/active_route_repository.g.dart apps/mobile/test/features/routes/data/active_route_repository_test.dart
git commit -m "feat(routes): ActiveRouteRepository persiste o id da rota ativa (Á7 PR-B2)"
```

---

### Task 2: setActiveRoute persiste + resolveActiveRoute (cadeia restore→recent→create)

**Files:**
- Modify: `lib/features/routes/state/active_route_provider.dart`
- Test: `test/features/routes/state/active_route_provider_test.dart`

**Context for the implementer:** O notifier `ActiveRouteId` (`@Riverpod(keepAlive: true)`, `build() => null`) hoje só tem `setActiveRoute(String? id) => state = id`. Ele precisa: (a) persistir no `ActiveRouteRepository` quando `setActiveRoute` é chamado; (b) um novo `Future<void> resolveActiveRoute()` que NÃO sobrescreve uma rota já ativa, e quando `state == null` executa: restaurar do repo (se o id ainda existe em `routesProvider`) → senão a rota mais recente por `date` → senão criar uma nova via `routesProvider.notifier.createRoute`. O `Routes` notifier expõe `createRoute({String? name, required DateTime date})` que retorna o id, e o estado é `List<Route>` (cada `Route` tem `id` e `date`). Para "criar quando não há nenhuma", use `name: null` (placeholder auto-gerado) e `date: DateTime.now()` — NÃO replicar a string "Minha primeira rota" do Spoke (microcopy original; o nome auto-gerado do RotPro é o weekday). Importe `package:roteirizador_pro/features/routes/domain/route.dart`.

- [ ] **Step 1: Write the failing test**

`test/features/routes/state/active_route_provider_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:roteirizador_pro/features/routes/data/active_route_repository.dart';
import 'package:roteirizador_pro/features/routes/domain/route.dart';
import 'package:roteirizador_pro/features/routes/state/active_route_provider.dart';
import 'package:roteirizador_pro/features/routes/state/routes_provider.dart';

class _MockRepo extends Mock implements ActiveRouteRepository {}

/// Routes notifier seeded with an explicit list (overrides the in-memory seed).
class _SeededRoutes extends Routes {
  _SeededRoutes(this._seed);
  final List<Route> _seed;
  @override
  List<Route> build() => _seed;
}

ProviderContainer _container({
  required List<Route> routes,
  required ActiveRouteRepository repo,
}) {
  final c = ProviderContainer(
    overrides: [
      routesProvider.overrideWith(() => _SeededRoutes(routes)),
      activeRouteRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  setUpAll(() => registerFallbackValue('x'));

  test('setActiveRoute persists the id', () async {
    final repo = _MockRepo();
    when(() => repo.write(any())).thenAnswer((_) async {});
    final c = _container(routes: const [], repo: repo);

    c.read(activeRouteIdProvider.notifier).setActiveRoute('route-9');

    expect(c.read(activeRouteIdProvider), 'route-9');
    await Future<void>.delayed(Duration.zero);
    verify(() => repo.write('route-9')).called(1);
  });

  test('resolveActiveRoute restores a still-existing persisted id', () async {
    final repo = _MockRepo();
    when(() => repo.read()).thenAnswer((_) async => 'r-old');
    when(() => repo.write(any())).thenAnswer((_) async {});
    final c = _container(
      routes: [
        Route(id: 'r-old', date: DateTime(2026, 6, 1)),
        Route(id: 'r-new', date: DateTime(2026, 6, 10)),
      ],
      repo: repo,
    );

    await c.read(activeRouteIdProvider.notifier).resolveActiveRoute();

    expect(c.read(activeRouteIdProvider), 'r-old');
  });

  test('resolveActiveRoute falls back to the most-recent route by date '
      'when the persisted id no longer exists', () async {
    final repo = _MockRepo();
    when(() => repo.read()).thenAnswer((_) async => 'gone');
    when(() => repo.write(any())).thenAnswer((_) async {});
    final c = _container(
      routes: [
        Route(id: 'r-old', date: DateTime(2026, 6, 1)),
        Route(id: 'r-new', date: DateTime(2026, 6, 10)),
      ],
      repo: repo,
    );

    await c.read(activeRouteIdProvider.notifier).resolveActiveRoute();

    expect(c.read(activeRouteIdProvider), 'r-new');
  });

  test('resolveActiveRoute creates a route when there are none', () async {
    final repo = _MockRepo();
    when(() => repo.read()).thenAnswer((_) async => null);
    when(() => repo.write(any())).thenAnswer((_) async {});
    final c = _container(routes: const [], repo: repo);

    await c.read(activeRouteIdProvider.notifier).resolveActiveRoute();

    final id = c.read(activeRouteIdProvider);
    expect(id, isNotNull);
    // The created route exists in routesProvider.
    expect(c.read(routesProvider).where((r) => r.id == id), isNotEmpty);
  });

  test('resolveActiveRoute is a no-op when a route is already active', () async {
    final repo = _MockRepo();
    when(() => repo.read()).thenAnswer((_) async => 'r-new');
    when(() => repo.write(any())).thenAnswer((_) async {});
    final c = _container(
      routes: [Route(id: 'r-keep', date: DateTime(2026, 6, 1))],
      repo: repo,
    );
    c.read(activeRouteIdProvider.notifier).setActiveRoute('r-keep');

    await c.read(activeRouteIdProvider.notifier).resolveActiveRoute();

    // Did not switch to the persisted 'r-new' — kept the live selection.
    expect(c.read(activeRouteIdProvider), 'r-keep');
    verifyNever(() => repo.read());
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd apps/mobile && flutter test test/features/routes/state/active_route_provider_test.dart`
Expected: FAIL — `resolveActiveRoute` não existe; `setActiveRoute` não persiste.

- [ ] **Step 3: Write minimal implementation**

`lib/features/routes/state/active_route_provider.dart` (substitui o corpo da classe):
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/active_route_repository.dart';
import 'routes_provider.dart';

part 'active_route_provider.g.dart';

/// Holds the id of the route whose shell is currently displayed.
/// `null` means unresolved — `resolveActiveRoute()` (called on shell boot)
/// guarantees a non-null id before the user can act, mirroring Spoke's
/// `ValidateActiveRoute` (which never leaves the editor without an active
/// route — persisted `activeRouteRef`, else most-recent, else create).
@Riverpod(keepAlive: true)
class ActiveRouteId extends _$ActiveRouteId {
  @override
  String? build() => null;

  /// Selects [id] as the active route AND persists it (fire-and-forget) so a
  /// restart restores the same route. Passing null clears both.
  void setActiveRoute(String? id) {
    state = id;
    // Fire-and-forget: the UI never blocks on the disk write; a failed write
    // only costs a wrong restore next launch (then the fallback kicks in).
    ref.read(activeRouteRepositoryProvider).write(id);
  }

  /// Boot resolver (Spoke `ValidateActiveRoute` parity). No-op when a route is
  /// already active (live selection wins). Otherwise: restore the persisted id
  /// if it still resolves; else pick the most-recent route by `date`; else
  /// create a fresh route. Always leaves [state] non-null when ≥1 route can
  /// exist. Writes the resolved id back so the next launch restores it.
  Future<void> resolveActiveRoute() async {
    if (state != null) return;

    final routes = ref.read(routesProvider);
    final persisted = await ref.read(activeRouteRepositoryProvider).read();

    if (persisted != null && routes.any((r) => r.id == persisted)) {
      setActiveRoute(persisted);
      return;
    }

    if (routes.isNotEmpty) {
      final mostRecent = routes.reduce(
        (a, b) => a.date.isAfter(b.date) ? a : b,
      );
      setActiveRoute(mostRecent.id);
      return;
    }

    // No routes at all → create one (auto-name = weekday placeholder,
    // original microcopy; NOT Spoke's "Minha primeira rota" verbatim).
    final newId = ref
        .read(routesProvider.notifier)
        .createRoute(date: DateTime.now());
    setActiveRoute(newId);
  }
}
```

- [ ] **Step 4: Run codegen + test to verify it passes**

Run: `cd apps/mobile && dart run build_runner build --delete-conflicting-outputs && flutter test test/features/routes/state/active_route_provider_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/features/routes/state/active_route_provider.dart apps/mobile/lib/features/routes/state/active_route_provider.g.dart apps/mobile/test/features/routes/state/active_route_provider_test.dart
git commit -m "feat(routes): resolveActiveRoute (restore->recent->create) + setActiveRoute persiste (Á7 PR-B2)"
```

---

### Task 3: Boot do shell chama resolveActiveRoute

**Files:**
- Modify: `lib/features/routes/presentation/route_shell_page.dart` (initState postFrame, ~linha 94)
- Test: `test/features/routes/presentation/route_shell_page_test.dart` (adiciona 1 teste)

**Context for the implementer:** O `_RouteShellPageState.initState` já tem um `WidgetsBinding.instance.addPostFrameCallback` (~linha 94) que lê `activeRouteIdProvider` e ajusta a fração do sheet. Hoje, se `activeId == null`, ele faz `return` cedo (linha 97: `if (activeId == null) return;`). É EXATAMENTE aí que o resolver deve entrar: quando `activeId == null`, chamar `ref.read(activeRouteIdProvider.notifier).resolveActiveRoute()` ANTES do early-return, para que o shell nunca permaneça sem rota. O resolver é async; após ele, o `ref.listen<String?>(activeRouteIdProvider, ...)` já existente no `build` (que seta o sheet em medium na transição null→id) cuida do ajuste do sheet. Então o postFrame só precisa disparar o resolve; não precisa reposicionar o sheet manualmente para o caso resolvido (o listener faz isso).

- [ ] **Step 1: Write the failing test**

Adicione ao final do `main()` em `test/features/routes/presentation/route_shell_page_test.dart` (reusa `_MutableFakeRoutes`, `_buildSentinelRouter`; NÃO seeda `activeRouteIdProvider` — deixa null pra exercitar o resolve). Importe `active_route_repository.dart` e crie um fake in-memory:

```dart
  // ── C5: shell boot resolves an active route when none is selected ──
  testWidgets(
      'C5 — shell sem rota ativa resolve para a mais recente no boot '
      '(nunca fica sem rota → add-stop não falha)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(kUserWithoutSub),
        routesProvider.overrideWith(
          () => _MutableFakeRoutes([
            domain.Route(id: 'r-old', date: DateTime(2026, 5, 20)),
            domain.Route(id: 'r-new', date: DateTime(2026, 5, 27)),
          ]),
        ),
        activeRouteRepositoryProvider
            .overrideWithValue(_FakeActiveRouteRepo()),
        // NOTE: activeRouteIdProvider is NOT overridden → starts null.
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.light().copyWith(splashFactory: NoSplash.splashFactory),
          routerConfig: _buildSentinelRouter(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Boot resolver picked the most-recent route by date.
    expect(container.read(activeRouteIdProvider), 'r-new');
  });
```

E declare o fake no topo (junto dos outros helpers top-level, fora de `main`):
```dart
/// In-memory fake of ActiveRouteRepository — no disk, starts empty.
class _FakeActiveRouteRepo implements ActiveRouteRepository {
  String? _stored;
  @override
  Future<String?> read() async => _stored;
  @override
  Future<void> write(String? id) async => _stored = id;
}
```

E o import no topo do arquivo de teste:
```dart
import 'package:roteirizador_pro/features/routes/data/active_route_repository.dart';
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd apps/mobile && flutter test test/features/routes/presentation/route_shell_page_test.dart --plain-name 'C5'`
Expected: FAIL — `activeRouteIdProvider` continua null (o shell não chama o resolver ainda).

- [ ] **Step 3: Write minimal implementation**

Em `lib/features/routes/presentation/route_shell_page.dart`, no `initState` postFrame, troque o early-return por uma chamada ao resolver. Localize:
```dart
      final activeId = ref.read(activeRouteIdProvider);
      if (activeId == null) return;
```
E substitua por:
```dart
      final activeId = ref.read(activeRouteIdProvider);
      if (activeId == null) {
        // Shell montou sem rota ativa (ex: cold start — o id vive em memória e
        // some no restart). Resolve fiel ao Spoke (ValidateActiveRoute):
        // restaura do disco → mais recente → cria. O `ref.listen` do build põe
        // o sheet em medium na transição null→id resultante. Sem isto, o
        // add-stop falharia com "Nenhuma rota ativa selecionada".
        ref.read(activeRouteIdProvider.notifier).resolveActiveRoute();
        return;
      }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd apps/mobile && flutter test test/features/routes/presentation/route_shell_page_test.dart`
Expected: PASS (todos os testes do shell, incl. C5; os C1-C4 e H6 intactos).

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/features/routes/presentation/route_shell_page.dart apps/mobile/test/features/routes/presentation/route_shell_page_test.dart
git commit -m "fix(routes): shell resolve rota ativa no boot (nunca sem rota; add-stop não falha) (Á7 PR-B2)"
```

---

### Task 4: Suite completa + analyze (regressão zero)

**Files:** nenhum novo — verificação.

- [ ] **Step 1: Run analyze**

Run: `cd apps/mobile && flutter analyze --no-pub lib/features/routes/`
Expected: No issues found (ou só os lints pré-existentes de outros arquivos, nenhum novo nos arquivos tocados).

- [ ] **Step 2: Run full suite**

Run: `cd apps/mobile && flutter test`
Expected: All tests passed! (contagem global + os ~9 novos: 4 repo + 5 provider; +C5 no shell).

- [ ] **Step 3: Commit (se houver ajuste)** — só se algum teste pré-existente precisou de ajuste por causa da persistência (ex: um teste do shell que assumia activeRouteId null permanente). Documente o porquê no commit.

---

## Divergências conscientes (documentar no TODO)

1. **"Mais recente" usa `Route.date`, não `lastEdited`** — o RotPro não tem `lastEdited`/`updatedAt` até o backend real (Slice 3). `date` é o proxy fiel para Slice 2.
2. **Persistência local (`SharedPreferences`), não Firestore** — o Spoke persiste `activeRouteRef` no Firestore; o RotPro só tem backend em Slice 3, então persiste local. Mesmo efeito observável (restaura no restart).
3. **Nome da rota auto-criada = weekday placeholder**, não "Minha primeira rota" verbatim (microcopy original).
