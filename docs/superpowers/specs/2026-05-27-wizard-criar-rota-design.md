# Especificação: Wizard "Criar Rota" (Área 2)

## Contexto
O Wizard "Criar Rota" é o fluxo de entrada para instanciar uma nova rota. Ele não usa modal ou bottom sheet; no Spoke, ele é uma página de tela cheia que empurra a view atual. Ele coleta `nome da rota` (opcional), `data da rota`, e possui a flag `Reutilizar paradas anteriores` para agilizar o setup diário do motoboy.

## Dados da Inspeção Funcional (M54 Spoke v3.65.1)

Baseado no uiautomator dump de 2026-05-27, a tela é estruturada verticalmente sem AppBar padrão, contendo:

| Widget Spoke | Bounds (M54) | Descrição RotPro (Padrão) |
|---|---|---|
| Botão Voltar | `[138,206]` (y) | `IconButton(Lucide.arrowLeft)` na top safe area |
| Título | `[295,371]` (y) | `Text` Headline |
| Label A | `[439,487]` (y) | `Text` "Nome da rota (opcional)" |
| Input A | `[522,657]` (y) | `TextFormField` customizado com hint text. O hint é o nome auto-gerado. |
| Label B | `[736,784]` (y) | `Text` "Selecione a data" |
| Radio 1 | `[807,965]` (y) | `RadioListTile` (Hoje + dd/MM) pré-selecionado |
| Radio 2 | `[999,1157]` (y) | `RadioListTile` (Amanhã + dd/MM) |
| Radio 3 | `[1191,1349]` (y) | `RadioListTile` ("Escolher data" -> showDatePicker) |
| Label C | `[1417,1465]` (y) | `Text` "Opções de início rápido" |
| Checkbox | `[1488,1646]` (y) | `CheckboxListTile` "Reutilizar paradas anteriores" |
| Botão Primário| `[2062,2220]` (y) | `FilledButton` / `ElevatedButton` full-width fixado no rodapé (safe area bottom) |

## Arquitetura de Estado (Riverpod)

Para o estado efêmero do formulário, criaremos o provedor `wizardRouteProvider` que mantém um state record `({ String? name, WizardDateOption dateOption, DateTime date, bool reuseStops })` ou usará um `StatefulWidget` simples caso preferível (o form não compartilha estado horizontalmente). Para manter o TDD e testes limpos: usaremos um `@riverpod` class (Notifier).

### Regras de Negócio do State
1. **Nome auto-gerado:** "[$diaDaSemana] Rota [$n]", onde $n é o número de rotas existentes para aquela data + 1. Se customName == nulo/vazio, o sistema usa o nome autogerado ao confirmar.
2. **Date Picker:** Se "Escolher data" for selecionado, o app chama `showDatePicker` (Android).
3. **Reuso de Paradas:** Ao selecionar `reuseStops`, o botão de CTA será modificado. Como "Reutilizar paradas" (Slice 3) ainda não foi implementado, a feature exibirá uma UI bloqueada ou toast alertando "Em breve", prosseguindo como vazia se o usuário confirmar.
4. **Submissão:** Ao submeter, despacha `ref.read(routesProvider.notifier).createRoute(name: finalName, date: date)`. O GoRouter limpa a tela (`context.pop()`) e ajusta a navegação se necessário (definindo a nova rota como ativa).

## Dependências e Restrições
- Depende do `RoutesNotifier` já existente e testado (ms-a1/drawer).
- Utilizar os tokens de design do protótipo e os ícones `lucide_icons`.
- **Restrição de código:** Sem comentários no arquivo (Rule 04), nomes autoexplicativos. Nenhuma importação não autorizada.
