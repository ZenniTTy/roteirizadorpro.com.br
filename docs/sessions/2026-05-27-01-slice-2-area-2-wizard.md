# Session Log: Wizard Criar Rota (Área 2)

## Metadata

- **Date**: 2026-05-27
- **Sequence**: 01
- **Agent**: Antigravity IDE
- **Human**: Eduardo
- **Topic**: slice-2-area-2-wizard
- **Duration**: ~2h00m
- **Related ADRs**: none
- **Related TODO items**: Slice 2 — Telas Core Spoke-aligned

## Goal of the Session

Implementar o Wizard de "Criar Rota" (Área 2 da Slice 2) baseando-se fielmente na spec técnica M54 (Spoke), mantendo paridade com o design original aprovado do protótipo e TDD 100%.

## What Was Done

- Executada inspeção da view hierárquica (uiautomator dump) no M54 para mapear bounds dos inputs de "Criar Rota".
- Elaborada Spec Técnica (`docs/superpowers/specs/2026-05-27-wizard-criar-rota-design.md`) para o WizardRoutePage.
- Desenvolvido `WizardFormController` testável que gera nomes automáticos baseados no Riverpod `routesProvider`.
- Implementada a UI `WizardRoutePage` e ajustados os seletores de data (Hoje, Amanhã, Custom).
- Testes unitários/widgets implementados e testados até a passagem (`wizard_form_controller_test.dart` e `wizard_route_page_test.dart`).
- GoRouter (`/home/routes/create`) injetado e interligado ao botão do `AppDrawer`.
- Corrigidos warnings pontuais do `flutter analyze` e refatoradas variáveis não utilizadas.
- APK (app-debug) gerado, instalado e injetado inputs de login no device M54 do usuário.

## Decisions Made

1. Wizard não modal — O GoRouter emula um full-page route, diferente de modais, seguindo exatamente o funcionamento de transição do app referencial Spoke.
2. Tratamento "Reutilizar Paradas" — Bloqueado via Snackbars, pois a lógica demandará banco offline e requisições backend prontas apenas na "Área 2.5".

## Open Questions Left

Nenhuma.

## Files Changed

**Created**:
- `apps/mobile/lib/features/routes/application/wizard_form_controller.dart`
- `apps/mobile/lib/features/routes/presentation/wizard_route_page.dart`
- `apps/mobile/test/features/routes/application/wizard_form_controller_test.dart`
- `apps/mobile/test/features/routes/presentation/wizard_route_page_test.dart`
- `docs/superpowers/specs/2026-05-27-wizard-criar-rota-design.md`

**Modified**:
- `apps/mobile/lib/app.dart`
- `apps/mobile/lib/features/routes/presentation/widgets/app_drawer.dart`

## Commits Pushed

```
e4c03c8 fix(mobile): corrige lints no wizard de rota
9ab56f6 feat(mobile): wizard de criação de rota (Área 2) — formulário e GoRouter
```

## Hand-off Notes for Next Session

A Área 2 primária foi concluída. Próxima sessão deve revisar se a flag de Reutilizar Paradas será mockada agora, ou avançar para Área 3 (Tela Ativa de Rota). A branch atual `feat/m2-slice-2-area-2-drawer` está pronta para merge.

## Reference Material Used

- Protótipo Figma
- `uiautomator dump` da UI (Samsung M54)
