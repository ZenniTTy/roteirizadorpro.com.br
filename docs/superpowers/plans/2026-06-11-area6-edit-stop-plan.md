# MS-A6 — Editar parada: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Spec (governa tudo):** [`docs/superpowers/specs/2026-06-11-area6-edit-stop-design.md`](../specs/2026-06-11-area6-edit-stop-design.md) — fatos **F1–F16** (dump v3.65.1 com evidência), decisões **D1–D8** (Eduardo), hardening **H1–H21** (verificação adversarial pré-plano). Cada task cita os IDs que implementa; em dúvida de detalhe, o spec §6 governa. NÃO re-derivar fatos: estão todos lá com arquivo:linha.

**Goal:** lista de stops no sheet do shell + página "Editar parada" completa (14 campos, edits live por campo) + 3 ações + entrypoints, Spoke-fiel por dump.

**Architecture:** página GoRouter full-screen (`/home/routes/active/:routeId/stops/:stopId/edit`) sobre o domínio `Stop` migrado (enums + `_omit`); edits aplicados live via `routesProvider.updateStop` a cada commit-on-dismiss de sub-surface; 2 repositories novos (settings + instruções por endereço) espelhando o idiom `RouteDefaultsController`; fotos locais via `image_picker` + `path_provider` (ADR curta).

**Tech Stack:** Flutter 3.44 / Riverpod 3 codegen / GoRouter 14 / SharedPreferencesAsync / image_picker 1.2.2 (já no pubspec) / path_provider 2.1.5 (novo).

**Disciplina por task:** TDD red→green (dispatch `flutter-test-author` para o teste ANTES de cada widget/provider novo — stub `throw UnimplementedError()`); `flutter analyze` sem lint novo (23 MS-DEBT intocados); commit por task (`feat(routes): …`); `Semantics(identifier:)` em todo tappable novo (H19, prefixos `stop_card_*`/`edit_stop_*`); zero divergência deferida. Workflows: `filesToTouch` SEMPRE inclui `app.dart` quando a task toca navegação (H20).

**Baseline de entrada:** branch `feat/m2-slice-2-area-6-edit-stop` · 308 testes verdes · 23 lints MS-DEBT.

---

### Task 1 — Domínio: enums + value objects (F8–F11, F16)

**Files:**
- Create: `apps/mobile/lib/features/routes/domain/stop_color.dart`
- Create: `apps/mobile/lib/features/routes/domain/stop_order_policy.dart`
- Create: `apps/mobile/lib/features/routes/domain/package_details.dart`
- Create: `apps/mobile/lib/features/routes/domain/place_in_vehicle.dart`
- Test: `apps/mobile/test/features/routes/domain/stop_domain_test.dart`

- [ ] **Step 1:** teste falhando (flutter-test-author) cobrindo: `StopColor.values.length == 5` (ordem blue/teal/purple/pink/orange — F10); `StopOrderPolicy.values == [first, auto, last]` e default semântico `auto` (F16); `PackageDetails` e `PlaceInVehicle` aceitam componentes todos-nulos e implementam `==`/`hashCode` por valor; `PlaceInVehicle.shortCode` concatena letras dos eixos definidos na ordem Y,X,Z (ex.: front+left+floor → "FEC"-equivalente em microcopy ORIGINAL — definir letras nossas, não copiar as do Spoke) e `null` quando nenhum eixo definido (F11).
- [ ] **Step 2:** rodar → RED. Implementar:

```dart
// stop_color.dart — 5 valores, mapeados a tokens prototipo na UI (não aqui)
enum StopColor { blue, teal, purple, pink, orange }

// stop_order_policy.dart
enum StopOrderPolicy { first, auto, last }

// package_details.dart
enum PackageDimension { small, medium, large }
enum PackageType { box, bag, letter }
class PackageDetails { // imutável, == por valor
  const PackageDetails({this.dimension, this.type});
  final PackageDimension? dimension;
  final PackageType? type;
}

// place_in_vehicle.dart
enum PlaceX { left, right }
enum PlaceY { front, middle, back }
enum PlaceZ { floor, shelf }
class PlaceInVehicle {
  const PlaceInVehicle({this.x, this.y, this.z});
  final PlaceX? x; final PlaceY? y; final PlaceZ? z;
  String? get shortCode; // ordem Y,X,Z; null se tudo nulo
}
```

- [ ] **Step 3:** GREEN → commit `feat(routes): Área 6 domain enums + value objects (MS-A6 T1)`.

### Task 2 — Domínio: migração do `Stop` (H1, H2, H3, H4)

**Files:**
- Modify: `apps/mobile/lib/features/routes/domain/stop.dart` (arquivo inteiro — campos têm ZERO usos externos, grep confirmado no spec §6)
- Test: `apps/mobile/test/features/routes/domain/stop_test.dart`

- [ ] **Step 1:** teste falhando: (a) **um teste clears-it POR campo nullable** — `copyWith` com sentinela limpa `notes`, `timeWindowStart`, `timeWindowEnd`, `priority`, `deliveryId`, `positionInRoute`, `accessInstructions`, `color`, `packageDetails`, `placeInVehicle`, `estimatedTimeAtStop` (H2 — classe do bug Route.name); (b) defaults: `orderPolicy == auto`, `packagesCount == 1` (int não-nulável, H3), `photoPaths` vazio.
- [ ] **Step 2:** RED → migrar o `Stop`:

```dart
// Campos REMOVIDOS: colorHex (→ StopColor? color), customDurationMinutes (→ Duration? estimatedTimeAtStop)
// Campos MIGRADOS:  timeWindowStart/End: DateTime? → TimeOfDay?  (H1 — hora-do-dia, lado único válido)
// Campos NOVOS:     orderPolicy (default auto) · packageDetails · placeInVehicle ·
//                   photoPaths (List<String>, default const []) · accessInstructions (String?)
// MANTIDOS:         priority (int? — solver Slice 3; DISTINTO de orderPolicy, H4) · packagesCount (int =1)
// copyWith: sentinela estática `_omit` (Object) — TODOS os nullables usam
//   `identical(x, _omit) ? this.x : x as T?` (sem `?? this.x` em nullable nenhum).
```

- [ ] **Step 3:** GREEN (os testes existentes de `Stop` continuam passando — ajustar os que citavam `colorHex`/`customDurationMinutes`, só existem em `stop.dart` tests) → commit `feat(routes): Stop v2 — campos Área 6 + copyWith _omit em todos os nullables (MS-A6 T2)`.

### Task 3 — `PackagePhotoStore` (F12, H15, H16, H17) + ADR path_provider

**Files:**
- Create: `apps/mobile/lib/features/routes/data/package_photo_store.dart`
- Create: `docs/decisions/0050-path-provider-local-package-photos.md` (curta: dep first-party 2.1.5, fotos locais per F12, sem upload)
- Modify: `apps/mobile/pubspec.yaml` (`path_provider: ^2.1.5`)
- Test: `apps/mobile/test/features/routes/data/package_photo_store_test.dart`

- [ ] **Step 1:** teste falhando com diretório base **injetado** (ctor recebe `Future<Directory> Function() baseDirProvider` — nos testes, um temp dir; em produção, `getApplicationSupportDirectory` per H17): `saveFor(routeId, stopId, sourceFile)` copia para `package_photos/<routeId>/<stopId>/<uuid>.jpg` e retorna o path; `copyAll(routeId, fromStopId, toStopId)` duplica ARQUIVOS e retorna os paths novos (H16 — paths nunca compartilhados); `deleteFor(routeId, stopId)` remove o diretório; todas degradam com `debugPrint` + retorno vazio/false em erro de I/O (H15 — nunca throw para a UI).
- [ ] **Step 2:** RED → implementar + `bun install` não (Dart): rodar `dart pub add path_provider` em apps/mobile → hook `warn-adr-drift` satisfeito pela ADR-0050 no mesmo commit.
- [ ] **Step 3:** GREEN → commit `feat(routes): PackagePhotoStore local-only + ADR-0050 path_provider (MS-A6 T3)`.

### Task 4 — Mutações do `routesProvider` (H9, H11, H16)

**Files:**
- Modify: `apps/mobile/lib/features/routes/state/routes_provider.dart`
- Test: `apps/mobile/test/features/routes/state/routes_provider_test.dart`

- [ ] **Step 1:** teste falhando: `updateStop(routeId, stop)` substitui por id preservando ordem; `removeStop(routeId, stopId)` remove e chama `photoStore.deleteFor` (fake injetado via override do provider do store); `duplicateStop(routeId, stopId) → String?` insere cópia **logo após a original** com: id novo, `status: pending`, `deliveryId/positionInRoute: null`, demais campos copiados, `photoPaths` = resultado de `photoStore.copyAll` (H16); retorna o id novo (caller navega — H11). Stop inexistente → no-op/null.
- [ ] **Step 2:** RED → implementar (o store vem de um `packagePhotoStoreProvider` simples; chamadas de I/O são `unawaited` + `debugPrint` em falha — estado nunca bloqueia em I/O).
- [ ] **Step 3:** GREEN → commit `feat(routes): updateStop/removeStop/duplicateStop (MS-A6 T4)`.

### Task 5 — `SettingsRepository` + controller (D4, F9, H14, H15)

**Files:**
- Create: `apps/mobile/lib/features/settings/data/settings_repository.dart`
- Create: `apps/mobile/lib/features/settings/state/settings_controller.dart`
- Test: `apps/mobile/test/features/settings/...` (espelhar os de `route_defaults_*`)

- [ ] **Step 1:** teste falhando: envelope `settings_v1` em SharedPreferencesAsync com `defaultStopDuration` (default `Duration(minutes: 1)` quando ausente/corrompido — com `debugPrint` no corrompido + teste do envelope corrompido, H15); `SettingsController` = `@Riverpod(keepAlive: true)` com `Future<Settings> build()` + `setDefaultStopDuration(Duration)` que persiste e atualiza `state` (H14 — espelho exato de `RouteDefaultsController`).
- [ ] **Step 2:** RED → implementar (codegen roda via hook). **NOTA Á10:** este repository é o que a Área 10 pluga depois — só UI faltará.
- [ ] **Step 3:** GREEN → commit `feat(settings): SettingsRepository mínimo — defaultStopDuration (MS-A6 T5)`.

### Task 6 — `AddressInstructionsRepository` + controller (F13, H18, H15)

**Files:**
- Create: `apps/mobile/lib/features/routes/data/address_instructions_repository.dart`
- Create: `apps/mobile/lib/features/routes/state/address_instructions_controller.dart`
- Test: espelho dos de T5.

- [ ] **Step 1:** teste falhando: envelope `address_instructions_v1`; chave = `fullAddress.trim().toLowerCase()` (H18); `instructionFor(fullAddress) → String?`; `saveDefault(fullAddress, text)`; `clearDefault(fullAddress)`; corrompido → default + `debugPrint` + teste.
- [ ] **Step 2:** RED → implementar. **Step 3:** GREEN → commit `feat(routes): AddressInstructionsRepository sticky-ao-endereço (MS-A6 T6)`.

### Task 7 — Lista de stops no sheet do shell (§3.2.1, H5–H8)

**Files:**
- Modify: `apps/mobile/lib/features/routes/presentation/route_shell_page.dart`
- Modify: `apps/mobile/test/features/routes/presentation/route_shell_page_test.dart` (amendment dos asserts collapsed-default → semear rota SEM stops, H6)

- [ ] **Step 1:** teste falhando: (a) com rota ativa de 2 stops, sheet renderiza header "2 paradas" + nome da rota (tap → push `routes/:routeId/edit` — H8) + seção "Paradas" com cards (badge "01"/"02" tabular, rua, endereço, dot status; `Semantics(identifier: 'stop_card_<n>')`); (b) tap no card pusha `/home/routes/active/<routeId>/stops/<stopId>/edit` (sentinel router como em `route_shell_page_test` atual); (c) **com stops ≥1 os 2 big buttons NÃO renderizam** (H5 — empty-state-only); (d) com 0 stops, estado atual intacto (config + empty state + botões); (e) auto-expand one-shot para `_expandedFraction` quando constrói com ≥1 stop; colapso manual não é revertido (H6).
- [ ] **Step 2:** RED → implementar: branch com stops usa `ListView.builder` (config summary = item 0; corpo SCROLLA com lista transbordando — intencional/match-Spoke, H7); branch vazio preserva a estrutura atual; `ref.listen` na contagem de stops da rota ativa para o one-shot 0→≥1.
- [ ] **Step 3:** GREEN + amendment dos testes existentes → commit `feat(routes): stop list no sheet ativo + auto-expand (MS-A6 T7)`.

### Task 8 — Rota + `EditStopPage` shell (D1, F3, H12, H19)

**Files:**
- Create: `apps/mobile/lib/features/routes/presentation/pages/edit_stop_page.dart`
- Modify: `apps/mobile/lib/app.dart` (rota `routes/active/:routeId/stops/:stopId/edit`, query `?new=1` lida via `state.uri.queryParameters`)
- Test: `apps/mobile/test/features/routes/presentation/pages/edit_stop_page_test.dart`

- [ ] **Step 1:** teste falhando: header (Ajuda stub à esq → SnackBar; título; "Concluído" à dir com `Semantics('edit_stop_done')` → só `pop`, F3); badge "Adicionada" quando `?new=1`; card endereço (rua h6 + endereço completo, read-only); ordem visual das seções per §10.6 (asserts de presença na ordem: chips → endereço → instruções → notas → rows → ações); **stopId que não resolve → pop pós-frame** (H12, teste dedicado); página observa o stop via `ref.watch(routesProvider.select(...))` — mutações externas re-renderizam.
- [ ] **Step 2:** RED → implementar a página com TODAS as rows presentes como elementos visíveis mas com `onTap` ainda stub-SnackBar interno temporário POR ROW (substituídos nas tasks 9–16; nunca `onTap: () {}` silencioso). Chip ID: display "Pendente"/`deliveryId` + tap → SnackBar "em breve" (D7 — tela de formato é Á10).
- [ ] **Step 3:** GREEN → commit `feat(routes): EditStopPage shell + rota (MS-A6 T8)`.

### Task 9 — Entrypoints (H9, H11; F4, F5)

**Files:**
- Modify: `route_shell_page.dart` (await-push do add-stop + toast "Ver"), `add_stop_page.dart` (`_onSectionATap` + pop com id), test de ambos.

- [ ] **Step 1:** teste falhando: (a) `_addStopFromPrediction` finaliza com `context.pop(stop.id)`; (b) os 2 pushes do shell para `/home/routes/add-stop` viram `final newStopId = await context.push<String>(...)`; quando retorna id → SnackBar "Parada adicionada" + action "Ver" (`Semantics` não aplica em SnackBarAction; testar callback) que faz hide + push `.../stops/<id>/edit?new=1` (H9 — context do shell, vivo); (c) `_onSectionATap` pop com intent `(editStopId: stop.id)` → AddStopPage pop → shell pusha o editor (H11 — sem empilhar sobre add-stop).
- [ ] **Step 2:** RED → implementar. **Step 3:** GREEN → commit `feat(routes): entrypoints do editor — tap, Section A, toast Ver (MS-A6 T9)`.

### Task 10 — Chip cor + `ColorPickerSheet` (F10, H13)

**Files:** Create `.../widgets/color_picker_sheet.dart` + test; Modify `edit_stop_page.dart`.

- [ ] **Step 1:** teste falhando: sheet (`showModalBottomSheet(useRootNavigator: true, useSafeArea: true)` — H13) com header [Limpar | Cor | Concluído], 5 swatches (tokens prototipo mapeados por `StopColor`), check na selecionada; retorna `StopColor?` no Concluído, sentinel-clear no Limpar, null em dismiss (sem mudança); chip no editor mostra a cor atual e chama `updateStop` no retorno (live, F3).
- [ ] **Step 2:** RED → implementar. **Step 3:** GREEN → commit `feat(routes): color picker 5 cores (MS-A6 T10)`.

### Task 11 — Notas + foto (F12, H15, H17)

**Files:** Modify `edit_stop_page.dart`; Create `.../widgets/stop_notes_section.dart` + test (fake do `ImagePicker` via wrapper injetável `Future<XFile?> Function()`).

- [ ] **Step 1:** teste falhando: TextField multiline com valor de `stop.notes`, commit no unfocus/done → `updateStop` (live); botão câmera (`Semantics('edit_stop_camera')`) chama o picker wrapper → em sucesso, `photoStore.saveFor` + `updateStop` com path appended → thumbnail renderiza; **negação/cancelamento → SnackBar, sem mudança de estado** (H17); thumbnail de path morto → placeholder + `debugPrint` (H15, teste com path inexistente).
- [ ] **Step 2:** RED → implementar (produção: `ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 1280, imageQuality: 80)` — H17; capturar `PlatformException` `camera_access_denied`).
- [ ] **Step 3:** GREEN → commit `feat(routes): notas + foto de pacote local (MS-A6 T11)`.

### Task 12 — Instruções de acesso (F13, §13.C.3, H18)

**Files:** Create `.../widgets/access_instructions_sheet.dart` + test; Modify `edit_stop_page.dart`.

- [ ] **Step 1:** teste falhando: sheet com header [Limpar | Instruções de acesso | Salvar], TextField multiline auto-focused, switch "Salvar como padrão para este endereço" (microcopy ORIGINAL equivalente); pré-preenche `stop.accessInstructions ?? repo[chave]` (H18); Salvar com switch ON grava nos dois, OFF só no Stop; Limpar limpa o campo (e o default do endereço se switch ON).
- [ ] **Step 2:** RED → implementar. **Step 3:** GREEN → commit `feat(routes): instruções de acesso sticky (MS-A6 T12)`.

### Task 13 — Pacotes: stepper + dialog (F8, H3)

**Files:** Create `.../widgets/package_count_row.dart` + `package_count_dialog.dart` + tests; Modify `edit_stop_page.dart`.

- [ ] **Step 1:** teste falhando: row com stepper [− N +] clamp **1..9999**, "−" no mínimo ATIVO e clampa (H3 — sem disabled inventado); cada tap → `updateStop` live; tap no NÚMERO abre dialog com TextField numérico (filtro dígitos, max 4 chars), placeholder "1", **commit on dismiss** (F8); valor ≤1 persiste como 1.
- [ ] **Step 2:** RED → implementar. **Step 3:** GREEN → commit `feat(routes): pacotes stepper + dialog (MS-A6 T13)`.

### Task 14 — Ordem + Tipo (F16, H21)

**Files:** Modify `edit_stop_page.dart` (+ widgets inline ou `.../widgets/stop_segmented_rows.dart`) + test.

- [ ] **Step 1:** teste falhando: `SegmentedButton<StopOrderPolicy>` 3 segments (Primeira/Automática/Última) e `SegmentedButton<StopType>` 2 segments (Entrega/Coleta), ambos `showSelectedIcon: false` (H21), `selected: {valor atual}`, mudança → `updateStop` live; **sempre habilitados** (§13.C.1).
- [ ] **Step 2:** RED → implementar. **Step 3:** GREEN → commit `feat(routes): ordem + tipo segmented (MS-A6 T14)`.

### Task 15 — Horário de chegada: janela (F7, H1, D8)

**Files:** Create `.../widgets/arrival_window_sheet.dart` + test; Modify `edit_stop_page.dart`.

- [ ] **Step 1:** teste falhando: sheet com 2 rows ("Chegar entre" / "E" — microcopy original equivalente) que abrem o numpad `TimePickerSheet` existente (ADR-0042, import de route_config); **um lado só é válido**; ambos vazios = limpar (display "Qualquer momento"); display parcial "Após HH:MM"/"Antes de HH:MM" (H1 — DIVERGE da BreakSchedulerPage: sem validação ambos-obrigatórios); commit → `updateStop` com `copyWith` usando `_omit` corretamente para limpar.
- [ ] **Step 2:** RED → implementar. **Step 3:** GREEN → commit `feat(routes): janela de horário de chegada (MS-A6 T15)`.

### Task 16 — Tempo na parada + Localizador (F9, F11, H14, H13)

**Files:** Create `.../widgets/time_at_stop_dialog.dart` + `package_finder_sheet.dart` + tests; Modify `edit_stop_page.dart`.

- [ ] **Step 1 (tempo):** teste falhando: dialog 2 campos numéricos "Minutos"/"Segundos" (filtro dígitos, max 5), placeholders = componentes do default global (via `settingsController` — `valueOrNull`, fallback declarado SÓ no controller, H14); ambos vazios → null (= "Padrão (1 min)" na row); commit on dismiss → `updateStop`.
- [ ] **Step 2 (localizador):** teste falhando: sheet header [Limpar | Localizador de pacotes | Concluído]; row "ID de parada" (display `deliveryId` ?? "Pendente"); seção "Descrição do pacote": 2 chip-groups single-select (Pequeno/Médio/Grande; Caixa/Sacola/Carta); seção "Lugar no veículo": 3 chip-rows (Y/X/Z) — TUDO INLINE na mesma sheet (H13); retorna `(PackageDetails?, PlaceInVehicle?)` on dismiss; row do editor mostra "Não definido" ou o texto longo juntado por ", " (F11).
- [ ] **Step 3:** RED → implementar ambos → GREEN → commit `feat(routes): tempo na parada + localizador de pacotes (MS-A6 T16)`.

### Task 17 — Mudar endereço (F1/#8, H10)

**Files:** Modify `picker_mode.dart` (+`changeAddress`), `add_stop_page.dart` (4º case do switch), `app.dart` (rota aninhada `change-address` sob a rota de edit, modo via constructor — `state.extra` PROIBIDO), `edit_stop_page.dart`; tests.

- [ ] **Step 1:** teste falhando: row "Mudar endereço" pusha a rota aninhada; AddStopPage em `changeAddress` (Section A omitida, header "Escolha o novo endereço", sem map footer) popa record `({double lat, double lng, String streetName, String fullAddress})` (H10); editor recebe e faz `updateStop` trocando SÓ os 4 campos; instruções sticky passam a resolver pelo novo endereço (H18 — teste).
- [ ] **Step 2:** RED → implementar. **Step 3:** GREEN → commit `feat(routes): mudar endereço (MS-A6 T17)`.

### Task 18 — Duplicar + Remover (F5, F6, H11)

**Files:** Modify `edit_stop_page.dart` + test.

- [ ] **Step 1:** teste falhando: "Duplicar parada" → `duplicateStop` imediato (sem dialog, F5) → **`pushReplacement`** do editor da duplicata com `?new=1` (H11); "Remover parada" (texto na cor de erro, `Semantics('edit_stop_remove')`) → `AlertDialog` confirm com microcopy ORIGINAL equivalente a "Quer remover X da rota?" (F6) → confirmar = `removeStop` + pop; cancelar = nada.
- [ ] **Step 2:** RED → implementar. **Step 3:** GREEN → commit `feat(routes): duplicar + remover parada (MS-A6 T18)`.

### Task 19 — integration_test no M54 (gate; idiom Á5 MS9)

**Files:** Create `apps/mobile/integration_test/area6_edit_stop_flow_test.dart`.

- [ ] **Step 1:** autorar com o idiom estabelecido (map-free `/home` stand-in; `WidgetsBinding.instance.handlePopRoute()` para system-back; font-free theme; **builders do `_router()` stand-in espelham produção** — lição MS9): cadeia stop-card → editor → (cor → back) → (janela → back) → (mudar endereço → back) → Concluído → Android-back popa um nível por vez; + duplicar abre editor novo; + remover com confirm volta à lista.
- [ ] **Step 2:** `cd apps/mobile && flutter test integration_test/area6_edit_stop_flow_test.dart -d RQCW401G33T` → **ler o OUTPUT** ("All tests passed!"), não o exit code. Commit `test(routes): integration_test Área 6 (MS-A6 T19)`.

### Task 20 — Fechamento (gates §5 do spec)

- [ ] `flutter analyze` (só os 23 MS-DEBT) + `flutter test` (≥ 308 + novos) — colar contagens.
- [ ] Dispatch `flutter-perf-auditor` (EditStopPage + lista do shell); must-fix corrigidos no MS.
- [ ] `/verify-slice` → dispara `spoke-parity-checker` **D4 dump-only** + `adr-guardian` (ADR-0050 cobre o path_provider). Runtime SÓ os 2 cliques do spec §4 (toast pós-add; tap-no-número Pacotes).
- [ ] Smoke E2E release no M54 (golden path: criar rota → add stop → editar tudo → duplicar → remover).
- [ ] Docs sweep no mesmo commit set: roadmap (Á6 ✅ + estado Á3 "falta kebab/Otimizar"), TODO.md, CHANGELOG, inventário (§10.5 header/footer confirmados), session log se houver lição não-óbvia.
- [ ] PR `feat/m2-slice-2-area-6-edit-stop` → **`develop`** (NUNCA main). Pós-merge: checkpoint (push + TODO + index).

---

## Self-review (executado 2026-06-11)

- **Cobertura do spec:** F1–F16 ✓ (F1/F2→T8; F3→T8/10–16; F4→T9; F5/F6→T18; F7→T15; F8→T13; F9→T16; F10→T10; F11→T16; F12→T3/11; F13→T12; F14 fora de escopo declarado; F15→T17/18; F16→T14). D1–D8 ✓. H1–H21 ✓ (H1→T2/15; H2→T2; H3→T13; H4→T2; H5–H8→T7; H9→T9; H10→T17; H11→T9/18; H12→T8; H13→T10/16; H14→T5/16; H15→T3/5/6/11; H16→T3/4; H17→T3/11; H18→T6/12/17; H19→todas; H20→processo; H21→T14).
- **Sem placeholders:** cada task tem arquivos exatos, contrato, asserts nomeados e comando/commit.
- **Consistência de tipos:** `StopColor?`/`StopOrderPolicy`/`PackageDetails?`/`PlaceInVehicle?`/`TimeOfDay?`/`Duration?` consistentes entre T1/T2 e T10–T16; record do H10 usado em T17.
