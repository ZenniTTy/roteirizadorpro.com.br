# 2026-06-12-01 — Área 6 (MS-A6): Editar parada

## Metadata

- **Date**: 2026-06-12 (America/Sao_Paulo)
- **Sequence**: 01
- **Agent**: Claude Code
- **Human**: Eduardo
- **Topic**: Área 6 — Editar parada
- **Duration**: ~ várias sessões (T1–T12 em 2026-06-11; T13–T20 + fechamento em 2026-06-12)
- **Related ADRs**: ADR-0050 (path_provider local package photos) · herda ADR-0042 (numpad), ADR-0043 (Destino sheet), ADR-0045 (dump-first), ADR-0049 (D4 dump-only), ADR-0010/0035 (microcopy original)
- **Related TODO items**: "Area 6 (Editar parada — 14 campos)" · gatilho Á3 "Tap no stop card"

## Goal of the Session

Executar o plano MS-A6 (`docs/superpowers/plans/2026-06-11-area6-edit-stop-plan.md`) task-by-task em TDD red→green, fechando a Área 6 (Editar parada) do Slice 2: lista de stops no sheet do shell + página de edição full-screen com os 14 campos + sub-surfaces (cor, instruções, foto, localizador, pacotes, janela de chegada, tempo na parada), tudo ancorado no dump estático do Spoke v3.65.1 (fatos F1–F16). Fechamento com os gates do spec §5 e PR contra `develop`.

## What Was Done

- Executadas as tasks T13–T20 (T1–T12 na sessão anterior 2026-06-11), cada uma: dispatch `flutter-test-author` (RED + stub `UnimplementedError`) → implementação → GREEN → commit próprio.
  - **T13** Pacotes: `PackageCountRow` stepper + `PackageCountDialog` free-text commit-on-dismiss (PopScope). Bug real pego pelos testes: `TextEditingController` descartado durante a animação de saída do dialog → reescrito como `StatefulWidget` que possui o controller.
  - **T14** Ordem + Tipo: `_SegmentedRow<T>` (SegmentedButton, `showSelectedIcon:false` H21, update live).
  - **T15** Janela de chegada: `ArrivalWindowSheet` "Chegar entre"/"E" reusando o numpad `TimePickerSheet` (ADR-0042); formatos de display extraídos do jadx `UiFormatters.m8466v` ("Após 09:30" / "09:30 - 18:00" / "Qualquer momento"); um lado só é válido (H1).
  - **T16** Tempo na parada (`TimeAtStopDialog` min+seg, default global do `SettingsRepository`, F9/H14) + Localizador (`PackageFinderSheet` inline: ID + chips dim/tipo + 3 eixos Y/X/Z, F11/H13).
  - **T17** Mudar endereço: `PickerMode.changeAddress` (4º modo do AddStopPage), rota aninhada `change-address`, troca só dos 4 campos de endereço; instruções sticky resolvem pelo novo endereço (H18).
  - **T18** Duplicar (`duplicateStop` imediato + `pushReplacement` H11) + Remover (AlertDialog confirm F6).
  - **T19** `integration_test/area6_edit_stop_flow_test.dart` verde no M54 (idiom MS-A5.9: `/home` stand-in map-free, builders espelham produção, `handlePopRoute`, font-free theme, prefs in-memory).
  - **T20** Fechamento: gates + perf-auditor + verify-slice (D4 dump-only + adr-guardian) + smoke E2E release + docs sweep + PR.
- Dispatch `flutter-perf-auditor` (read-only): 0 must-fix. Should-fixes aplicados: `cacheWidth:128` nas thumbnails `Image.file`; corpo do editor `ListView` → `ListView.builder`; `.select` no watch de settings.
- Dispatch D4 `spoke-parity-checker` dump-only (ADR-0049): 0 must-fix; F1–F16/D1–D8/H1–H21 conformes.
- Dispatch `adr-guardian`: PASS — única mudança de stack é `path_provider ^2.1.5` (ADR-0050).
- Smoke E2E no APK release assinado no M54 (Maestro MCP): golden path criar rota → adicionar parada → editar tudo → duplicar → remover.

## Decisions Made

1. **2 fixes cross-área entraram na branch da Á6** — justificados pelo gate do smoke E2E (o golden path do plano exige criar→add→editar) + diretriz zero-débito. (a) `scripts/build-release-apk.sh` não injetava `MAPS_API_KEY` → release com Google Places quebrado em runtime; script agora lê do ambiente/`.env` e falha cedo se ausente. (b) Wizard "Criar rota" não tornava a rota criada ATIVA → "Adicionar parada" pós-create falhava com "Nenhuma rota ativa selecionada"; paridade ancorada no dump (`RouteCreateFragment.java:186-193` entrega o `RouteId` ao caller). Teste de widget pina o contrato.
2. **Microcopy "Direita" corrige o typo "Direta"** do dump (`place_in_vehicle_right`) — ADR-0010 (microcopy original, não clonar a do Circuit).
3. **Foto de pacote 100% local** via `getApplicationSupportDirectory()` (paralelo fiel ao `getFilesDir()` do Spoke) — sem upload; persistência real é Slice 3.

## Open Questions Left

- [ ] Órfãos de foto por restart (entre a duplicação e o restart) são aceitos até a persistência do Slice 3 (H16 — TODO já registrado no spec §3.3).
- [ ] As rotas de teste criadas no smoke ficam só em memória (somem ao matar o app) — limpeza não-necessária no Slice 2.

## Files Changed

**Created** (produção):
- `apps/mobile/lib/features/routes/domain/{stop_color,stop_order_policy,package_details,place_in_vehicle}.dart`
- `apps/mobile/lib/features/routes/data/package_photo_store.dart`
- `apps/mobile/lib/features/routes/presentation/pages/edit_stop_page.dart`
- `apps/mobile/lib/features/routes/presentation/widgets/{color_picker_sheet,stop_notes_section,access_instructions_sheet,package_count_row,package_count_dialog,arrival_window_sheet,time_at_stop_dialog,package_finder_sheet}.dart`
- `apps/mobile/lib/features/settings/data/settings_repository.dart` + `state/settings_controller.dart`
- `apps/mobile/lib/features/routes/data/address_instructions_repository.dart` + `state/address_instructions_controller.dart`
- `apps/mobile/integration_test/area6_edit_stop_flow_test.dart`
- `docs/decisions/0050-path-provider-local-package-photos.md`
- 16+ arquivos de teste em `apps/mobile/test/features/routes/**`

**Modified**:
- `apps/mobile/lib/features/routes/domain/stop.dart` (migração `TimeOfDay?` janela + `_omit` em 11 nullables)
- `apps/mobile/lib/features/routes/state/routes_provider.dart` (updateStop/removeStop/duplicateStop)
- `apps/mobile/lib/features/routes/presentation/route_shell_page.dart` (lista de stops + auto-expand)
- `apps/mobile/lib/features/routes/presentation/pages/add_stop_page.dart` (case changeAddress) + `lib/features/route_config/state/picker_mode.dart`
- `apps/mobile/lib/features/routes/presentation/wizard_route_page.dart` (setActiveRoute — fix smoke)
- `apps/mobile/lib/app.dart` (rotas edit + change-address)
- `apps/mobile/scripts/build-release-apk.sh` (MAPS_API_KEY — fix smoke)
- `apps/mobile/pubspec.yaml` (+`path_provider ^2.1.5`)
- `docs/08-ROADMAP-v2.md`, `TODO.md`, `docs/inventory/2026-05-26-spoke-vs-rotpro.md`, `docs/sessions/0001-INDEX.md`

## Commits Pushed

```
47165a3..c6a62de  T1–T12 (sessão 2026-06-11)
76b3a82  feat(routes): pacotes stepper + dialog (MS-A6 T13)
a2aa75d  feat(routes): ordem + tipo segmented (MS-A6 T14)
46ca501  feat(routes): janela de horário de chegada (MS-A6 T15)
bd95280  feat(routes): tempo na parada + localizador de pacotes (MS-A6 T16)
5485a11  feat(routes): mudar endereço (MS-A6 T17)
0ea319e  feat(routes): duplicar + remover parada (MS-A6 T18)
bfb3ddf  test(routes): integration_test Área 6 (MS-A6 T19)
7fb9aa2  perf(routes): aplica punch list do flutter-perf-auditor (MS-A6 T20)
dad8dd6  fix(build): injeta MAPS_API_KEY no APK release (MS-A6 T20d)
7d62e26  fix(routes): rota recém-criada vira a ativa no confirm do wizard (MS-A6 T20d)
b666d10  docs(sessions): MS-A6 fechamento
```

## Hand-off Notes for Next Session

- **Branch**: `feat/m2-slice-2-area-6-edit-stop` → **PR #28** contra `develop` (aberto). Aguardando review/merge.
- **Gates ao fim**: 606 testes host verdes · 23 lints (MS-DEBT, zero novos) · integration_test verde no M54 · D4 dump-only 0 must-fix · adr-guardian PASS · smoke E2E release OK.
- **Próxima área**: Á7 (Otimizar rota) — dependências Á6 (chips A1/A2) e Á3 (CTA Otimizar, slot do footer nasce lá) satisfeitas. Usar `onReorderItem` (Flutter 3.44, não `onReorder`).

## Lições (candidatas a memória)

1. **Teclado Samsung intercepta taps do Maestro sobre a área de conteúdo** — a janela do honeyboard cobre mais do que desenha; taps em rows visíveis "não disparam" (logs dizem COMPLETED, callback não roda). Sempre `hideKeyboard` antes de tap em resultado de busca. Diagnóstico definitivo veio de `adb shell input tap` + screencap a ~1s flagrando a SnackBar real.
2. **`flutter-test-author` morreu no meio do dispatch 3× nesta MS** (T7 na sessão anterior, T15/T16 nesta) — sempre verificar `git status` + estado dos arquivos após retorno de subagent e completar o gate (RED run + analyze) manualmente.
3. **Smoke E2E de release é gate de verdade**: pegou 2 gaps cross-área que 606 testes host + integration_test não viam (ambos de wiring de produção: dart-define e ativação de rota).
4. Lição Maestro adicional: `.at(0)` num finder composto aplica-se ANTES do `descendant` — escope primeiro, índice depois.

## Reference Material Used

- Dump estático Spoke v3.65.1: `~/spoke-dump/jadx-out` + `~/spoke-dump/res-decoded/res/values-pt-rBR/strings.xml` (strings PT-BR de package finder, time window, remove confirm, default brackets) + `docs/inventory/spoke-dump-v3.65.1/MASTER-TABLE.md`.
- jadx: `EditStopEditorKt`, `UiFormatters.m8465u/m8466v/m8453f`, `RouteCreateFragment.java:186-193`, `RouteCreateViewModel`, `PackageDetails.java`, `PlaceInVehicle.java`.
- Spec/plano: `docs/superpowers/specs/2026-06-11-area6-edit-stop-design.md` + `docs/superpowers/plans/2026-06-11-area6-edit-stop-plan.md`.
- Context7: `path_provider` (versão atual 2.1.5, ADR-0050).
