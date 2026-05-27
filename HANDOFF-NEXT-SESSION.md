# Handoff — próxima sessão (Slice 2 Área 2 em andamento)

> **Para o assistente AI que abrir a próxima sessão:** este arquivo é o prompt
> de entrada. Lê inteiro antes de qualquer ação. Substitui parcialmente o
> onboarding ritual padrão do `CLAUDE.md` (ainda lê o `CLAUDE.md`, mas o
> contexto desta branch está consolidado aqui).

## Onde estamos (2026-05-27 fim de sessão)

- **Branch ativa:** `feat/m2-slice-2-area-2-drawer` (saiu de `develop`).
- **Não foi mergeada ainda.** A branch contém 4 commits:
  - `780023e feat(mobile): drawer lateral (Área 2, tela 1) — white-label Spoke`
  - `bb2fe58 feat(mobile): popup 3-dot da rota (Área 2, tela 2) — kebab actions`
  - `4048411 fix(mobile): drawer audit follow-up — logout, error states, perf`
  - `fc2ad50 chore(antigravity): frontmatter triggers + list formatting on .agent/rules/`
- **36/36 testes verde**, `flutter analyze --no-pub` clean, APK debug
  instalado no Samsung M54 (`RQCW401G33T`) apontando pra prod API
  (`https://api.roteirizadorpro.com.br`).
- **Auditoria pós-implementação aplicada** (code-reviewer + silent-failure-hunter):
  - MUST-FIX 1: logout reachable via item "Sair" no PopupMenu Help do drawer
    (temporário até Settings real chegar na Área 10).
  - MUST-FIX 2: `currentUserProvider` distingue 3 estados (data/loading/error)
    e renderiza `UserViewModel.unavailable()` em loading+error, evitando UI
    misleading quando token expira.
  - SHOULD-FIX 3: floating map controls + sheet collapsed icons agora
    disparam SnackBar "em breve" ao invés de `onTap: () {}` silencioso.
  - SHOULD-FIX 4: `DrawerRouteList` refatorado pra single `ListView.builder`
    com lista achatada virtualizada (`sealed class _Row`). Headers + tiles +
    headerSlot são linhas do mesmo ListView — sem nested ListView, sem
    shrinkWrap. Escala pra Slice 3 CRUD.
  - NIT 5: `DrawerHeaderCard` parâmetros mortos `onHelp`/`onSettings` removidos.
  - NIT 6: `groupRoutesByPeriod` emite `debugPrint` em `kDebugMode` quando
    rotas mais antigas que mês corrente são descartadas (Slice 2 scope).
- **Smoke visual definitivo do drawer aberto pendente** — Eduardo precisa
  logar com email/senha no app e abrir o drawer pelo hamburger floating
  pra confirmar que o layout final renderiza como esperado.

## Telas já feitas da Área 2

1. ✅ **Drawer lateral** (commit `780023e`) — hamburger circular flutuante
   `top-left` sobre o mapa abre `AppDrawer` como `showModalBottomSheet`
   `isScrollControlled + useSafeArea`. X close + Help PopupMenu +
   Configurações na top bar. Header card com avatar + nome + email +
   linha plano opcional + botão "Assinar" condicional
   (`!hasActiveSubscription`). Lista 4 buckets dinâmicos
   ("Próximas" / "Hoje" / "Esta semana" / "Este mês"). CTA "Criar rota"
   pinned ao rodapé respeitando SafeArea.
2. ✅ **Popup 3-dot da rota** (commit `bb2fe58`) — `RouteKebabMenu`
   = `PopupMenuButton<RouteAction>` com 3 itens plain-text:
   "Definir nome e data" / "Duplicar rota" / "Excluir rota". Sem ícones
   leading, sem divider, sem cor destrutiva. Todas as 3 ações disparam
   `SnackBar` "<label> — em breve" (stubs Slice 2).

## Telas restantes da Área 2 (ordem ROADMAP)

3. ⏭️ **Wizard "Criar rota" full-screen** — próxima tela. 3 zonas:
   - Zona A: TextField "Nome da rota (opcional)" com placeholder
     auto-gerado `"[dia-da-semana] Rota [N]"` (incrementa por dia)
   - Zona B: 3 radio rows ("Hoje" pré-selecionado / "Amanhã" /
     "Escolher data" com chevron-right que abre `showDatePicker` Material 3
     locale PT-BR)
   - Zona C: checkbox "Reutilizar paradas anteriores" (uncheck default —
     quando marcado, CTA muda label e navega pra tela "Reutilizar paradas")
   - CTA filled primary "Confirmar" pinned, sem modal de sucesso
   - Detalhe: ROADMAP linha 41–47 + inventário §6.2 + §10.3
4. **Form "Definir nome e data"** — reusa o Wizard parametrizado por
   `Route?` (null=create / non-null=edit). Quando edit: X close + título
   "Editar rota" + TextField pré-populado + sem Zona C + CTA "Salvar
   alterações".
5. **Tela "Reutilizar paradas" + picker rota fonte**.
6. **Duplicar rota** — backend endpoint Slice 3.
7. **Excluir rota** — AlertDialog confirm (RotPro decision per ROADMAP).

Depois sai da Área 2 → Área 3 (mapa Google Maps SDK real +
`DraggableScrollableSheet` 2 snap points + lista de stops).

## Regras NÃO-NEGOCIÁVEIS estabelecidas nesta sessão

### 1. Inventário descreve, Spoke decide. Sem dump, sem spec.

Adicionada como item duro do `docs/M2-SLICE-CHECKLIST.md` §Implementação.
Toda tela Spoke-aligned começa com:

```bash
# Confirma que o Spoke está em foco no M54
adb -s RQCW401G33T shell dumpsys window | grep mCurrentFocus

# Dump da hierarquia e screenshot do estado-alvo
adb -s RQCW401G33T shell uiautomator dump /sdcard/spoke-<state>.xml
adb -s RQCW401G33T pull /sdcard/spoke-<state>.xml /tmp/
adb -s RQCW401G33T exec-out screencap -p > /tmp/spoke-<state>.png

# Extrair tabela bounds | content-desc/text
python3 -c "
import re
with open('/tmp/spoke-<state>.xml') as f: xml = f.read()
for m in re.finditer(r'<node[^>]*?(?:content-desc=\"([^\"]+)\"|text=\"([^\"]+)\")[^>]*?bounds=\"(\[[0-9]+,[0-9]+\]\[[0-9]+,[0-9]+\])\"', xml):
    cd, txt, bounds = m.group(1) or '', m.group(2) or '', m.group(3)
    if cd or txt: print(f'{bounds:32s}  desc={cd!r:40s}  text={txt!r}')
"
```

Produzir tabela canônica `bounds | content-desc/text | padrão visual |
widget Flutter`. Coluna do widget Flutter nomeia widget específico
(`Positioned(top:X, left:Y) FloatingActionButton.small`,
`DraggableScrollableSheet`, `showModalBottomSheet(isScrollControlled:true)`)
— **não** família genérica. Se inventário e dump conflitarem, dump ganha
e inventário é amendado no mesmo commit do spec.

**Por que essa regra existe:** a sessão queimou 2h refazendo o drawer
porque eu li o paraphrase "drawer 90% width" do inventário e implementei
Material `Drawer` lateral. O dump ao vivo revelou que era um
`ModalBottomSheet` quase-fullscreen + hamburger floating no canto
superior esquerdo. Memória do erro:
`~/.claude/projects/<project>/memory/lesson_spoke_visual_inspection_before_coding.md`.

### 2. Dispatch do `spoke-parity-checker` D1 deve pedir TABELA explícita

A description do dispatch precisa explicitar pedido pela tabela
`bounds | desc | padrão | widget` — não só "edge cases". Edge cases vêm
DEPOIS da baseline estrutural. Atualizado em `M2-SLICE-CHECKLIST.md`.

### 3. APK debug em device físico precisa `--dart-define`

Build padrão `flutter build apk --debug` aponta pra `http://10.0.2.2:3000`
(default do `lib/core/env/app_env.dart`) — IP de loopback do emulador
Android, inacessível do M54. Login falha silenciosamente. **Sempre** usar:

```bash
flutter build apk --debug --target-platform android-arm64 \
  --dart-define=API_BASE_URL=https://api.roteirizadorpro.com.br \
  --dart-define=APP_ENV=production
```

OU rodar `bash apps/mobile/scripts/build-release-apk.sh` que já tem isso
wired. Memória `lesson_flutter_run_release_needs_dart_define.md` documenta.

### 4. TDD red→green via `flutter-test-author` continua obrigatório

Subagent escreve testes failing FIRST + stubs `throw UnimplementedError()`.
Hook `.claude/hooks/block-test-author-impl.sh` impede o subagent de
escrever lógica em `lib/` — implementer (operador) só implementa depois
dos vermelhos. ADR-0025 + ADR-0031.

**Conhecido:** o hook bloqueia também edits no `lib/` mesmo quando o
subagent estaria só restaurando um stub com `throw UnimplementedError()`
(falsa positiva). Workaround: aceitar que o operador faz o último passo
de cascata + retorno do stub. Não modificar o hook.

### 5. Tokens visuais do `prototipo/` desde commit 1

ADR-0035. `lib/core/theme/app_theme.dart` já mapeou `AppColors`,
`AppRadii`, `AppShadows` do `prototipo/tokens.js`. Não usar `Colors.red`
direto — usar `AppColors.error`. Lucide icons via `lucide_icons_flutter`
package (`LucideIcons.menu`, `LucideIcons.ellipsisVertical`, etc.).

### 6. Sem `onTap: () {}` silenciosos em UI interativa

Toda affordance visível ao usuário (botão, IconButton, InkWell, suffix
icon de TextField) DEVE ter callback que dispara algo observável —
mesmo que seja só `SnackBar` "em breve" stub. Botão "vazio" parece app
quebrado. Aplica-se mesmo durante stubs Slice 2/3. Vide
`route_shell_page.dart` `_comingSoon()` helper.

### 7. `AsyncValue` em provider: sempre branch nos 3 estados

Quando um provider deriva de `AsyncValue<T>` (típico: `currentUserProvider`
lendo `authControllerProvider`), NÃO usar `auth.value` direto — isso
colapsa `AsyncLoading`, `AsyncError`, e `AsyncData(null)` num único
`null`. Branch explicitamente:

```dart
final auth = ref.watch(authControllerProvider);
if (auth.hasError) return MyViewModel.unavailable();
if (auth.isLoading) return MyViewModel.unavailable();
final user = auth.value;
if (user == null) return MyViewModel.empty();
return MyViewModel.fromUser(user);
```

`unavailable()` ≠ `empty()` semanticamente. Drawer/UI deve renderizar
visualmente distinto pros 2 casos (degraded vs logged-out).

### 8. `ListView` em UI com lista de dados → sempre `ListView.builder`

Não usar `ListView(children: [...])` pra listas que vêm de provider
(podem crescer). Achata pra `List<_Row>` (sealed class) e usa
`ListView.builder(itemCount: rows.length, itemBuilder: ...)`. Headers
de bucket, cards, tudo é "linha". Padrão estabelecido em
`drawer_route_list.dart`.

### 9. Pipeline de validação antes de cada commit

```bash
cd apps/mobile
dart run build_runner build --delete-conflicting-outputs   # se mexeu @riverpod
flutter analyze --no-pub                                    # ZERO issues
flutter test                                                # 100% verde
# Build + reinstall pra smoke visual no M54
flutter build apk --debug --target-platform android-arm64 \
  --dart-define=API_BASE_URL=https://api.roteirizadorpro.com.br \
  --dart-define=APP_ENV=production
adb -s RQCW401G33T install -r build/app/outputs/flutter-apk/app-debug.apk
```

## Estrutura atual de `apps/mobile/lib/features/routes/`

```
lib/features/routes/
├── domain/
│   ├── group_routes_by_period.dart   # função pura, 4 buckets
│   ├── route.dart                    # Route + RouteStatus + RoutePeriod enums
│   ├── route_action.dart             # enum {editMeta, duplicate, delete}
│   └── user_view_model.dart          # UserViewModel pro drawer
├── presentation/
│   ├── route_shell_page.dart         # Scaffold + hamburger floating + sheet collapsed
│   └── widgets/
│       ├── app_drawer.dart           # ConsumerWidget + showModalBottomSheet shell
│       ├── drawer_header_card.dart   # avatar + name + email + plano + Assinar
│       ├── drawer_route_list.dart    # ListView 4 buckets agrupados
│       ├── drawer_route_tile.dart    # row com data + nome + RouteKebabMenu
│       └── route_kebab_menu.dart     # PopupMenuButton<RouteAction>
└── state/
    ├── active_route_provider.dart    # @riverpod class ActiveRouteId
    ├── current_user_provider.dart    # @riverpod UserViewModel from AuthController
    └── routes_provider.dart          # @riverpod List<Route> seed in-memory
```

## Decisões fixas a NÃO mexer sem motivo

- `RouteShellPage` **não** tem AppBar — mapa full-screen + hamburger floating
  via `Positioned(top: padding.top + 12, left: 16)`.
- `drawerEnableOpenDragGesture: false` no Scaffold (Spoke não habilita
  swipe-from-edge).
- Sheet collapsed do RouteShellPage fica em `Scaffold.bottomNavigationBar`,
  NÃO em `Stack` — assim Material lida com inset do system nav bar
  automaticamente.
- Hamburger floating é `Material(shape: CircleBorder(), elevation: 4) +
  InkWell + Icon(LucideIcons.menu)` num `SizedBox(48×48)`. Não trocar por
  `FloatingActionButton` (perde a aparência do Spoke).
- `AppDrawer.show()` é `static Future<void>` — usa `showModalBottomSheet`
  com `isScrollControlled: true + useSafeArea: true`. Body é
  `DraggableScrollableSheet(initialChildSize: 1.0, minChildSize: 0.5)`.
- `routesProvider` é function-style `@riverpod List<Route> routes(Ref ref)`
  (não Notifier) — isso permite `routesProvider.overrideWithValue(...)`
  nos testes. Quando precisar de CRUD (Slice 3), refatora pra
  `@riverpod class RoutesNotifier`.
- `currentUserProvider` mapeia `authControllerProvider.value` (não
  `valueOrNull` — não existe nesta versão do Riverpod) pro
  `UserViewModel`. `hasActiveSubscription` é sempre `false` em Slice 2
  (paywall vem em Slice 4).
- Testes com `MaterialApp(theme: AppTheme.light().copyWith(splashFactory:
  NoSplash.splashFactory))` — sem isso, o shader `ink_sparkle.frag`
  quebra os widget tests no SDK atual.

## Onde estão coisas importantes

| Documento | Caminho | Pra quê |
|---|---|---|
| CLAUDE.md raiz | `CLAUDE.md` | Manual operacional do projeto |
| ROADMAP completo | `docs/08-ROADMAP-v2.md` | 10 áreas do Slice 2 |
| Checklist por slice | `docs/M2-SLICE-CHECKLIST.md` | Regra "dump antes de spec" está aqui |
| Inventário Spoke vs RotPro | `docs/inventory/2026-05-26-spoke-vs-rotpro.md` | §10.1 + §10.2 + §11.6 são os relevantes pra Área 2 |
| Spec do drawer | `docs/superpowers/specs/2026-05-27-drawer-lateral-design.md` | Inclui tabela bounds canônica |
| Spec do popup | `docs/superpowers/specs/2026-05-27-popup-3dot-route-design.md` | Idem |
| Memórias da sessão | `~/.claude/projects/-Users-eduardorodrigues-Documents-Projetos-Clientes-ueslei-workana-app-roteirizadorpro/memory/` | Lessons learned persistem entre sessões |
| Subagents disponíveis | `.claude/agents/` | spoke-parity-checker, flutter-test-author, flutter-perf-auditor, adr-guardian, prototype-fidelity-checker |
| Hooks ativos | `.claude/hooks/` | block-env, block-secrets (block-test-author-impl), format-dart, run-riverpod-codegen, analyze-changed-dart, warn-adr-drift, check-dto-mirror, reinject-roadmap |

## Convenções estabelecidas (atualizadas nesta sessão)

- **DTO mirror** (ADR-0013) — qualquer edit em
  `apps/backend/src/<feature>/schemas.ts` exige espelho Dart em
  `apps/mobile/lib/features/<feature>/data/dto/` **no mesmo commit**.
  Não vale pra Slice 2 (que é UI-only até Slice 3 chegar).
- **Conventional Commits** + lefthook 2.x. Use `bun run commit` pro
  wizard interactive ou `/commit` skill.
- **Branches por slice** — `feat/m2-slice-N-<topic>`. Não commitar
  direto na develop.
- **Session log opcional** pós-reset. Crie `docs/sessions/YYYY-MM-DD-NN-<topic>.md`
  só quando o aprendizado da sessão não é óbvio do git log.

## Onboarding ritual recomendado pra próxima sessão

1. Lê este HANDOFF inteiro.
2. `cat CLAUDE.md` — manual operacional.
3. `cat docs/08-ROADMAP-v2.md` — seção Área 2 (linhas 35–55).
4. `cat docs/M2-SLICE-CHECKLIST.md` — regra "Inventário descreve, Spoke
   decide. Sem dump, sem spec." está aqui.
5. `cat docs/superpowers/specs/2026-05-27-drawer-lateral-design.md` e
   `2026-05-27-popup-3dot-route-design.md` — pra ver o padrão da tabela
   bounds que toda spec daqui pra frente tem que ter.
6. `git log --oneline feat/m2-slice-2-area-2-drawer ^develop` — ver os 2
   commits da sessão anterior.
7. `cd apps/mobile && flutter analyze && flutter test` — confirma 35/35
   verde antes de começar (se não tiver, algo regrediu).
8. `adb devices` — confirma M54 conectado.
9. Pergunta ao Eduardo: continuamos com a Tela 3 (Wizard "Criar rota")?

## Próxima tela em detalhe: Wizard "Criar rota"

**Antes de qualquer linha de código:**

1. No Spoke (M54), entrar numa rota qualquer → toque hamburger → toque
   "Criar rota" no rodapé do drawer. Capturar:
   - Screenshot do wizard renderizado
   - `uiautomator dump` da hierarquia
   - Tabela `bounds | desc | padrão | widget` cobrindo:
     - Top bar (back-arrow esquerda + título centralizado)
     - Campo Nome (TextField + placeholder dinâmico)
     - Section "Selecione a data" + 3 radio rows
     - "Escolher data" → screenshot do `showDatePicker` resultante
     - Section "Opções de início rápido" + checkbox "Reutilizar paradas"
     - CTA "Confirmar"
2. Amendar inventário `docs/inventory/2026-05-26-spoke-vs-rotpro.md`
   §10.3 se algo conflitar com a paraphrase atual.
3. Escrever spec curto em
   `docs/superpowers/specs/YYYY-MM-DD-wizard-criar-rota-design.md` com
   a tabela canônica ancorada no dump.
4. Dispatch `flutter-test-author` pra escrever os failing tests.
5. Implementar.
6. analyze + test + build + reinstall + smoke.
7. Commit.

**Arquitetura sugerida** (a confirmar com o dump):
- Nova GoRoute `/routes/new` (full-screen, não modal).
- `WizardCriarRotaPage` — `ConsumerStatefulWidget` (state local pra nome,
  data selecionada, checkbox).
- `routesProvider` ganha método `addRoute(Route route)` — vira Notifier
  (`@riverpod class RoutesNotifier`).
- Auto-naming: helper `_generateRouteName(DateTime date, List<Route>
  existingForDay)` retorna `"quarta-feira"` (1ª do dia) ou
  `"quarta-feira Rota 2"` (2ª+).
- `showDatePicker` com `locale: const Locale('pt', 'BR')` (precisa
  registrar `flutter_localizations` no `MaterialApp`).

## Pendências de baixa prioridade (não bloqueantes)

- **Smoke visual definitivo do drawer + popup no M54** — Eduardo precisa
  logar manualmente no app instalado e validar visual.
- **`ink_sparkle.frag` workaround** — todos os widget tests usam
  `splashFactory: NoSplash.splashFactory`. Acompanhar release do Flutter
  pra retirar quando o bug do shader for fixed upstream.
- **Linha plano "Standard • Renova-se em..."** — renderiza só quando
  `user.planLine != null`. Slice 4 pluga.
- **Avatar real do user** — Slice 2 usa fallback `LucideIcons.user`
  dentro de `CircleAvatar`. Upload de foto = Slice 5+.

## Quando esta sessão fechar

Quando a Área 2 inteira terminar (Wizard + Form editar + Reutilizar
paradas + Duplicar + Excluir):

1. Roda `flutter analyze && flutter test` final — tudo verde.
2. Roda `bash apps/mobile/scripts/build-release-apk.sh` — APK assinado.
3. Smoke E2E completo no M54 com prod API.
4. Abre PR `feat/m2-slice-2-area-2-drawer → develop`.
5. Dispatch `spoke-parity-checker` D4 closing pro PR.
6. Após merge, próxima branch: `feat/m2-slice-2-area-3-active-route`
   (mapa Google Maps SDK + DraggableScrollableSheet + lista de stops).
