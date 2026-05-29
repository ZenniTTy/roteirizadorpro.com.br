# Popup 3-dot da rota — Área 2 tela 2

> Spec curto. Estrutura/comportamento espelhado do Spoke per ADR-0035.
>
> **Fonte canônica:** dump `uiautomator` + screencap do Spoke v3.65.1 ao vivo no Samsung M54 (2026-05-27, drawer aberto + tap no kebab da rota `27 de mai. quarta-feira`).

## Tabela canônica do dump (1080×2400)

| Bounds | Texto | Padrão visual | Widget Flutter |
|---|---|---|---|
| `[492,788][899,846]` | "Definir nome e data" | Item topo do popup, altura ~58px text + padding (~135px row total) | `PopupMenuItem(value: RouteAction.editMeta, child: Text(...))` |
| `[492,923][759,981]` | "Duplicar rota" | Item middle, mesma altura | `PopupMenuItem(value: RouteAction.duplicate, child: Text(...))` |
| `[492,1058][726,1116]` | "Excluir rota" | Item bottom, **sem cor destrutiva** (texto cinza padrão) | `PopupMenuItem(value: RouteAction.delete, child: Text(...))` |

## Comportamento

- **Tipo:** `PopupMenuButton<RouteAction>` Material (dropdown ancorado), NÃO bottom sheet.
- **Ancoragem:** abre abaixo + alinhado à esquerda do kebab (`anchor.bottomLeft` aproximadamente). PopupMenu padrão do Material faz isso automaticamente quando o kebab é o trigger.
- **Width:** ~497px no Spoke. PopupMenu Material default usa `IntrinsicWidth` baseado no maior item — vai dar mesma largura sem precisar setar.
- **Sem ícones leading** nos items, sem `PopupMenuDivider`, sem `TextStyle(color: Colors.red)` no "Excluir".
- **Fecha** ao tap fora (scrim invisível do `PopupMenu` Material).
- **Fechamento por tap em item:** dispatcha ação e fecha.

## Decisões fixas

| Decisão | Valor | Fonte |
|---|---|---|
| Widget | `PopupMenuButton<RouteAction>` (não `showMenu` manual) | Material default |
| Trigger | `IconButton` kebab dentro de `DrawerRouteTile` é substituído por `PopupMenuButton` | refator |
| 3 ações | `editMeta`, `duplicate`, `delete` | inventory §10.2 + dump |
| Cor destrutiva | NENHUMA (confirma observação canônica) | dump |
| Stub Slice 2 | Todas as 3 ações abrem `SnackBar` "em breve" | as telas reais são próximas iterações da Área 2 |

## RotPro decision aplicada

**Excluir rota → AlertDialog confirm** (ROADMAP linha 54) fica pra **quando a feature real entrar** (próxima tela "Excluir rota"). Slice 2 commit deste popup é só **wiring do menu + ações que abrem snackbar**.

## Arquivos

NOVO:
- `apps/mobile/lib/features/routes/domain/route_action.dart` — enum
- `apps/mobile/lib/features/routes/presentation/widgets/route_kebab_menu.dart` — `PopupMenuButton<RouteAction>`

MODIFICADO:
- `drawer_route_tile.dart` — troca `IconButton(kebab)` por `RouteKebabMenu(onSelected: ...)`
- `app_drawer.dart` — `onRouteKebab` recebe `(route, action)` ao invés de só `(route)`
- `drawer_route_list.dart` — propaga callback com `action`

TESTES:
- `route_kebab_menu_test.dart` — renderiza 3 items + onSelected callback recebe `RouteAction` correto
- `drawer_route_tile_test.dart` — atualizado pra checar que `RouteKebabMenu` aparece, não mais `IconButton` solto

## Verification

```bash
flutter analyze --no-pub
flutter test
```

## Gaps deixados explícitos

1. AlertDialog de confirm pra "Excluir rota" — vem com a tela "Excluir rota" real.
2. "Definir nome e data" abre Form (Wizard parametrizado) — vem na 3ª tela da Área 2.
3. "Duplicar rota" exige backend endpoint `POST /routes/:id/duplicate` (Slice 3).
