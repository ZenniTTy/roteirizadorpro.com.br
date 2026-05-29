# Drawer lateral — Slice 2 Área 2 (primeira tela)

> **Status:** spec revisado 2026-05-27 pós-inspeção visual ao vivo.
>
> **Fonte canônica:** dump `uiautomator` + screencap do Spoke v3.65.1 ao vivo no Samsung M54 (tabela `bounds | desc | padrão | widget` abaixo). Inventário §10.1 + §11.6 são **paraphrase** — quando conflitarem com o dump, dump ganha.
>
> **Revisão crítica 2026-05-27:** primeira tentativa implementou Material `Drawer` lateral + hamburger dentro do sheet header. Inspeção visual no Spoke mostrou que é **`ModalBottomSheet` quase fullscreen** + **hamburger floating circular sobre o mapa**. Retrabalho completo. Memory `lesson-spoke-visual-inspection-before-coding` documenta a regra: dump antes de spec, sempre.

## Contexto

Pós-reset 2026-05-26, `_HomePlaceholderPage` em `lib/app.dart` é o destino do redirect de auth. Precisa virar `RouteShellPage` — a tela que hospeda a rota ativa e expõe o drawer via hamburger no header do sheet. Sem drawer não há navegação entre rotas; toda Área 2 (Rotas) depende dele.

## Escopo (slice 2 — UI primeiro, backend stubbed)

**IN:**
- `RouteShellPage` substitui `_HomePlaceholderPage` em `/home`.
- `AppDrawer` widget com header (avatar/nome/email/plano/Assinar/Help/Settings) + lista 4-buckets + CTA "Criar rota".
- Modelo local `Route` + `RouteStatus` + `groupRoutesByPeriod(routes, now)` puro.
- `routesProvider` (Riverpod) com seed list in-memory de rotas mock (não persistido — schema real é Slice 3).
- `activeRouteIdProvider` reativo.
- Tap em "Criar rota" / kebab / Help / Settings / Assinar = `SnackBar` "Em breve" (as telas reais vêm nos próximos commits da Área 2).

**OUT (próximos commits da Área 2):**
- Popup 3-dot real (vem depois do drawer)
- Wizard "Criar rota" (idem)
- Tela Settings real (Área 10)
- Persistência de rotas (Slice 3)
- Paywall do botão Assinar (Slice 4)
- Empty state do drawer com 0 rotas — mockado com lista populada por padrão; teste cobre a função `groupRoutesByPeriod` retornando map vazio.

## Tabela canônica do dump (Spoke v3.65.1 @ 1080×2400, sheet expandido sobre rota vazia)

| Bounds | content-desc / text | Padrão visual | Widget Flutter |
|---|---|---|---|
| `[0,0][1080,1245]` | "Mapa do Google" (TextureView) | Map full-width, ocupa metade superior quando sheet expandido; full-screen quando collapsed | `GoogleMap` (Área 3 entrega o mapa real; Slice 2 = placeholder colorido) |
| **`[79,171][147,239]`** | **"Menu"** | **Hamburger circular FLUTUANTE** (~24dp icon dentro de ~48dp tappable circle) sobre o mapa, top-left, FORA do sheet | `Positioned(top: 12, left: 16)` + `Material(shape: CircleBorder(), elevation: 4) + InkWell + IconButton(LucideIcons.menu)` |
| `[934,886][1002,954]` | "Alternar modo de mapa" | Layer toggle circular floating, direita | `Positioned(right: 16, top: <about middle of map>)` + circle Material |
| `[934,1054][1002,1122]` | "Alternar para o mapa" | Recenter circular floating, direita abaixo do layer toggle | `Positioned(right: 16, top: <below layer toggle>)` + circle Material |
| `[~,1268][1080,1336]` | search pill `Toque para adicionar` (TextField) | Pinned no topo do sheet, sticky tanto collapsed quanto expanded | `TextField` dentro do `DraggableScrollableSheet` header |
| `[720,1268][788,1336]` | "Ler etiqueta de endereço" | OCR icon dentro da pill | `IconButton(LucideIcons.scanLine)` |
| `[833,1268][901,1336]` | "Dite o endereço" | Voice icon dentro da pill | `IconButton(LucideIcons.mic)` |
| `[968,1268][1036,1336]` | "Menu" (segundo "Menu" — não confundir) | Kebab 3-dot da rota, dentro da pill | `IconButton(LucideIcons.ellipsisVertical)` |
| `[0,1245]...[1080,2400]` | empty state quando rota sem paradas | Sheet expandido cobrindo metade inferior do mapa | `DraggableScrollableSheet` snap collapsed (`0.14`) / expanded (`~0.86`) |
| `[259,1656][822,1761]` | text "Adicione as primeiras paradas..." | Microcopy do empty state | `Text` |
| `[408,1967][764,2023]` | text "Adicionar paradas" | Filled primary CTA empty state | `FilledButton` |
| `[184,2125][898,2181]` | text "Copiar paradas de uma rota anterior" | Text-style CTA secundário empty state | `TextButton` |

## "Drawer" — na verdade `RoutesSheet` (bottom modal sheet quase-fullscreen)

Quando o usuário toca o hamburger flutuante `[79,171]`, abre uma surface chamada no inventário de "drawer 90% width" — **mas o screenshot ao vivo mostra que é um bottom sheet draggable de baixo pra cima, ~95% de altura, com X close no canto superior esquerdo**. NÃO é Material `Drawer` lateral.

**Implementação correta:** `showModalBottomSheet<void>(isScrollControlled: true, useSafeArea: true, useRootNavigator: true, ...)` retornando um widget com:
- Top bar: `IconButton(LucideIcons.x)` (close) à esquerda + `IconButton(LucideIcons.circleHelp)` (PopupMenu Help) + `IconButton(LucideIcons.settings)` à direita
- Header card: avatar + nome + email + linha plano (condicional)
- Botão "Assinar" (condicional `!hasActiveSubscription`)
- `ListView` 4 buckets + `DrawerRouteTile`
- `FilledButton.icon` "Criar rota" pinned no rodapé

Largura: 100% da tela (Material default do bottom sheet — não restringe a 90%). Scrim opaco automático.

## Decisões fixas

| Decisão | Valor | Fonte |
|---|---|---|
| Entry point | Hamburger circular flutuante top-left no `RouteShellPage` | dump `[79,171][147,239]` |
| Surface "drawer" | `showModalBottomSheet(isScrollControlled: true)` ~95% altura | screenshot ao vivo 2026-05-27 |
| Close gesture | Botão X top-left **+** drag-down (Material `DraggableScrollableSheet` interno OU `enableDrag: true` no modal) | screenshot ao vivo |
| Botão "Assinar" | Condicional `!user.hasActiveSubscription` | §10.1 amendment (mantém) |
| Help icon | `PopupMenuButton` (não `Navigator.push`) | §10.1 amendment (mantém) |
| Settings icon | `context.push('/settings')` (stub Slice 2) | §10.1 amendment (mantém) |
| Active route indicator | Cor primary no `Text` da linha | §10.1 (mantém) |
| Sort buckets top→bottom | Próximas → Hoje → Semana → Mês | §11.6 corrigido (mantém) |
| Sort dentro de bucket | Descendente por `Route.date` | §11.6 corrigido (mantém) |
| Mocktail | `mocktail ^1.0.5` se precisar `verify/when`; senão manual fakes | ADR-0025 (mantém) |

## Estrutura de arquivos

```
apps/mobile/lib/features/routes/
├── domain/
│   ├── route.dart                    # class Route, enum RouteStatus, enum RoutePeriod
│   └── group_routes_by_period.dart   # função pura groupRoutesByPeriod()
├── state/
│   ├── routes_provider.dart          # @riverpod RoutesNotifier (in-memory seed)
│   ├── routes_provider.g.dart        # gerado
│   ├── active_route_provider.dart    # @riverpod activeRouteId
│   └── active_route_provider.g.dart  # gerado
└── presentation/
    ├── route_shell_page.dart         # Scaffold + Drawer + sheet placeholder
    └── widgets/
        ├── app_drawer.dart           # Drawer root (3 zonas)
        ├── drawer_header_card.dart   # avatar + nome + email + plano + Assinar
        ├── drawer_top_icons.dart     # Help (PopupMenu) + Settings (IconButton)
        ├── drawer_route_list.dart    # ListView com 4 buckets
        ├── drawer_route_tile.dart    # row data + nome + kebab
        └── drawer_create_cta.dart    # FilledButton.icon "Criar rota"

apps/mobile/test/features/routes/
├── domain/
│   ├── route_test.dart
│   └── group_routes_by_period_test.dart   # cobre 4 buckets + edge cases vazio/só hoje/só futuras
├── state/
│   └── routes_provider_test.dart
└── presentation/
    ├── route_shell_page_test.dart
    └── widgets/
        ├── app_drawer_test.dart
        ├── drawer_header_card_test.dart   # Assinar condicional
        └── drawer_route_tile_test.dart    # active vs inactive color
```

## Domain model

```dart
enum RouteStatus { draft, optimized, running, completed }

enum RoutePeriod { upcoming, today, thisWeek, thisMonth }
// ordem do enum = ordem canônica top→bottom no drawer

class Route {
  const Route({
    required this.id,
    required this.date,    // só data (year/month/day); hora ignorada pro grouping
    required this.status,
    this.name,             // null = exibir só dia-da-semana auto-gerado
  });
  final String id;
  final DateTime date;
  final RouteStatus status;
  final String? name;
}
```

## groupRoutesByPeriod (algoritmo)

Função pura, totalmente testável sem widget tree:

```dart
Map<RoutePeriod, List<Route>> groupRoutesByPeriod(
  List<Route> routes,
  DateTime now,
);
```

Regras:
- Comparações ignoram hora — comparar `DateTime(y, m, d)` zerado.
- `now` é injetado pra teste determinístico.
- "Semana corrente" = segunda-feira da semana de `now` até `now` (PT-BR — segunda como primeiro dia).
- `upcoming` = `route.date > today`
- `today` = `route.date == today`
- `thisWeek` = `route.date >= mondayOfWeek(now) && route.date < today`
- `thisMonth` = `route.date.month == now.month && route.date.year == now.year && route.date < mondayOfWeek(now)`
- Rotas mais antigas que mês corrente: **descartadas** no Slice 2 (mock fixo curto; Slice 3 vai precisar de scroll/lazy load — gap aceito).
- Cada lista do mapa retornada está ordenada `desc` por `date`.
- Buckets vazios são omitidos do mapa (não renderiza header se não há itens).

## RoutesNotifier (Slice 2 stub)

```dart
@Riverpod(keepAlive: true)
class RoutesNotifier extends _$RoutesNotifier {
  @override
  List<Route> build() {
    final now = DateTime.now();
    return [
      Route(id: 'r1', date: now, status: RouteStatus.running,
            name: '${_weekday(now)} Rota 2'),
      Route(id: 'r2', date: now, status: RouteStatus.draft,
            name: _weekday(now)),
      Route(id: 'r3', date: now.subtract(Duration(days: 1)),
            status: RouteStatus.completed, name: 'Segunda-Feira'),
    ];
  }
}
```

Sem persistência. Sem CRUD ainda (`createRoute` etc. virão com o Wizard).

## activeRouteIdProvider

`@Riverpod(keepAlive: true)` simples — `String?` controllado pela `RouteShellPage` quando o usuário tap numa rota no drawer (Slice 2 stub: muda o `activeRouteId` + fecha drawer + snackbar "Rota selecionada"). A integração de fato com a tela ativa vem na Área 3.

## RouteShellPage layout (Slice 2 stub)

```
Scaffold
  drawerEnableOpenDragGesture: false
  drawer: AppDrawer()
  body: Stack
    - Container (cor surface, placeholder do mapa Área 3)
    - DraggableScrollableSheet stub
      - Header row:
        - IconButton(Lucide.menu) → Scaffold.of(context).openDrawer()
        - TextField disabled "Toque para adicionar" (Área 4 entry)
      - Body: SizedBox empty
```

O hamburger é o entry point obrigatório do drawer (swipe está OFF).

## Tokens visuais aplicados (de `lib/core/theme/app_theme.dart`)

- Fundo drawer: `AppColors.bg` (#FFFFFF) — Spoke usa fundo escuro, mas RotPro = white-label visual nosso
- Header card: `AppColors.surface` + `AppRadii.card` + `AppShadows.card`
- Active route text: `AppColors.primary`
- Inactive route text: `AppColors.text`
- Muted text (email/plano): `AppColors.textMuted`
- CTA Criar rota: `FilledButton.icon` com `Lucide.plus`
- Help icon: `Lucide.circleHelp` (PopupMenu trigger)
- Settings icon: `Lucide.settings`
- Kebab: `Lucide.ellipsisVertical`
- Avatar fallback: `Lucide.user` em círculo `AppColors.primaryLight`

## Verification

```bash
cd apps/mobile
flutter analyze --no-pub                                    # clean
dart run build_runner build --delete-conflicting-outputs    # gera .g.dart
flutter test test/features/routes/                          # verde
flutter test                                                # full suite verde
flutter run -d RQCW401G33T                                  # smoke debug no M54
```

Smoke E2E completo (release APK contra prod API) **não é gate deste commit isolado** — vai no PR fechado da Área 2 inteira.

## Auditoria pré-commit

- `flutter analyze` clean
- `flutter test` verde
- `flutter-perf-auditor` opcional (drawer simples; ListView fixo curto)
- `spoke-parity-checker` D4 closing
- Pre-commit Lefthook (formatter + analyze sobre os .dart alterados)

## Gaps deixados explícitos

1. **"Próximas rotas" empírico** — confirmar com Eduardo criando rota futura no Spoke (Maestro bloqueou). Implementação baseada em §11.6 deduzido + sort canônico do enum.
2. **Avatar real** — Slice 2 usa fallback `Lucide.user`. Upload de foto Slice 5+.
3. **Linha do plano "Standard · Renova-se em..."** — Slice 2 mostra texto fixo "Sem assinatura ativa" porque `user.hasActiveSubscription` ainda não existe. Modelagem real Slice 4.
4. **Help PopupMenu items "Em breve"** — não abre Intercom (Slice 3+).
5. **Tap em rota apenas troca `activeRouteId` + snackbar.** Navegação real pra tela ativa = Área 3.
