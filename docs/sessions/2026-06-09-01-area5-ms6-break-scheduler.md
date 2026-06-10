# Área 5 MS6 — Break scheduler page (window model, ADR-0044)

## Metadata

- **Date**: 2026-06-09 (America/Sao_Paulo)
- **Sequence**: 01
- **Agent**: Claude Code (Opus 4.8)
- **Human**: Eduardo
- **Topic**: MS-A5.6 — sub-tela Pausa (break scheduler) seguindo o pipeline 5-fases
- **Related ADRs**: ADR-0044 (filed this session); ADR-0042 (numpad reused), ADR-0043 (same failure mode)
- **Related TODO items**: Área 5 MS6 (✅); MS7/MS8/MS9 ainda abertos

## Goal of the Session

Executar MS-A5.6 (Área 5 sub-tela Pausa) pelo pipeline 5-fases obrigatório do `docs/superpowers/plans/2026-06-06-slice2-completion.md`: pesquisa de stack moderna → dump LIVE fresco da Spoke só da sub-tela Pausa → implementar TDD → gates do harness → harness-current. Substituir o SnackBar interino "Pausa em breve" por um break scheduler real (returns-intent). NÃO abrir PR (esse é o MS-A5.9).

## What Was Done

- **Fase 1 (pesquisa):** workflow paralelo (Dart MCP + Context7) confirmou idiomas 3.44 — ChoiceChip vs SegmentedButton para single-select, showTimePicker vs numpad, showModalBottomSheet returns-intent, Riverpod 3 list mutation. Nenhum dos 3 breaking changes 3.44 (onReorderItem/RadioGroup/sealed-AsyncValue) se aplica a essa tela. Salvo em `/tmp/spoke-a56-pausa-inspection/phase1-research-findings.json`.
- **Fase 2 (dump LIVE):** inspecionei a Spoke ao vivo no M54 via Maestro MCP (launchApp → Detalhes da rota → "Adicionar pausa") em todos os estados. Capturas + bounds verbatim em `/tmp/spoke-a56-pausa-inspection/EVIDENCE.md`.
- **HALT estrutural (Fase 2):** a Spoke real CONTRADIZ o plano/domínio estruturalmente → escalei ANTES de implementar (ver Decisões #1). Eduardo decidiu match-Spoke (modelo janela + página full-screen + ADR).
- **ADR-0044 filed** documentando a correção (página full-screen "Configure a pausa" + break = janela `fromTime`/`toTime` + minutos livres; numpad reusado; dialog numérico para duração).
- **Fase 3 (TDD):** migrei `BreakConfig` (single `startTime` → window) no domínio + serialização `route_defaults_v1` (JSON arms) + 6 arquivos de teste; construí `break_scheduler_page.dart` (returns-intent, reusa `TimePickerSheet` numpad + dialog numérico); registrei a rota `break-scheduler` em `app.dart`; liguei `route_details_page._onTapAdicionarPausa` (push + `addBreak`) e atualizei `_pausaSection` pro range de janela.
- **Fase 4 (gates):** analyze limpo no escopo (23 lints pré-existentes intactos = MS-DEBT); checagem mecânica de "done" passou (escopo cirúrgico, zero markers de dívida, SnackBar removido, migração completa).
- **Validação anti-entropia (a pedido do Eduardo):** dois revisores adversariais (`code-reviewer` + `silent-failure-hunter`) → "limpo, zero must-fix". 3 achados acionáveis corrigidos: (a) label de duração derivado do valor em vez de flag `_durationIsDefault` (alinha ao docstring + remove estado redundante); (b) `Semantics(break_duration_cancel)` no botão Cancelar do dialog; (c) teste do degrade de envelope legado `{startTime}`. 2 nits de validação (from≤to, teto de minutos) conscientemente mantidos como fidelidade-Spoke (ADR §4 — única trava é `duração > 0`).
- **Harness-current:** roadmap MS6 ✅, inventário §16 DRILLED, plano §MS-A5.6 + spec sub-slice table + spec antigo Q7 REFUTADO, CHANGELOG, TODO.md — todos varridos no mesmo commit set (anti-pattern #22).
- **Testes:** 249 (baseline) → **263** (+14).

## Decisions Made

1. **Break = janela de horário, não horário único; página full-screen, não sheet (ADR-0044).** O plano/spec assumiam (a) um bottom sheet com (b) chips de duração 15/30/60 e (c) `BreakConfig` com um `startTime` único. O dump LIVE provou que a Spoke real é: **página full-screen** "Configure a pausa" (back arrow, NÃO sheet) + **janela** "Entre 08:00 / E 15:00" (dois campos, default 08:00–15:00, abrem o MESMO numpad ADR-0042) + **duração em minutos livre** (dialog numérico "Duração da pausa (minutos)", default 30, NÃO chips). O inventário §16 confirmava: o picker estava "Não drilled" — o modelo single-time era inferência nunca validada. Mesmo failure mode da ADR-0042/0043. Escalado no Phase-2 halt; Eduardo: "Siga o recomendado e as boas práticas igual o spoke."
2. **Migração de domínio é in-scope da MS6, não diferida.** Mudar `BreakConfig` de `{startTime}` → `{fromTime, toTime, durationMinutes}` toca o domínio + serialização + 6 arquivos de teste (mais largo que a lista original do plano), mas a tela não pode ser Spoke-correta sem o modelo janela — meio-shippar seria o anti-pattern de diferir divergência. JSON `route_defaults_v1` mudou `startTime`→`fromTime`/`toTime`; sem migração (Área 5 não shipou) — envelope legado degrada com log via `_breaksFromJson`.
3. **Validação de janela (from≤to) e teto de minutos NÃO foram adicionados.** Spoke não trava ordem nem teto; adicionar seria inventar affordance que a Spoke não tem (anti-pattern #12). A única trava é `duração > 0` (dialog Definir desabilitado), documentada no ADR §4 como "mirroring the solver-window rule, not a Spoke-invisible disable". Decisão consciente, não esquecimento — flagado pelo hunter, mantido.

## Open Questions Left

- [ ] **MS7** — tornar as 3 rows de config inline da Área 3 (Início/Ida e volta/Pausa) clickáveis → reabrir as sub-telas. Próximo passo.
- [ ] **MS8** — persistência `route_defaults_v1` + FTUE; re-confirmar Q8 "Salvar como padrão" default (UNCHECKED) vs conta Spoke fresh.
- [ ] **MS9** — primeiro `integration_test/` (`area5_route_details_flow_test.dart`, 5-route Android-back chain) + D4 spoke-parity + Maestro YAML + PR da Área 5.
- [ ] Comportamento da Spoke no caso "re-confirmar 30 sem mudar" não foi medido (assumido: mantém "Padrão (30 min)"); revisitar se um dump futuro mostrar diferente.

## Files Changed

**Created**:
- `apps/mobile/lib/features/route_config/presentation/pages/break_scheduler_page.dart`
- `apps/mobile/test/features/route_config/presentation/pages/break_scheduler_page_test.dart`
- `docs/decisions/0044-break-scheduler-window-domain-and-page.md`

**Modified** (lib): `app.dart`, `domain/route_config.dart`, `domain/route_defaults.dart`, `presentation/pages/route_details_page.dart`
**Modified** (test): `route_config_test.dart`, `route_config_controller_test.dart`, `route_defaults_test.dart`, `route_defaults_controller_test.dart`, `route_defaults_repository_test.dart`, `route_details_page_test.dart`
**Modified** (docs): `08-ROADMAP-v2.md`, `10-CHANGELOG.md`, `inventory/2026-05-26-spoke-vs-rotpro.md`, `superpowers/plans/2026-06-06-slice2-completion.md`, `superpowers/specs/2026-06-06-slice2-completion.md`, `superpowers/specs/2026-06-02-area5-route-details.md`, `TODO.md`

## Hand-off Notes for Next Session

- Branch `feat/m2-slice-2-area-5-route-details`. MS6 ✅. **Próximo: MS7 (wire das 3 config rows da Área 3).** NÃO abrir PR até MS9.
- O pipeline 5-fases funcionou exatamente como projetado: a Fase 2 (dump LIVE) pegou a 3ª contradição estrutural consecutiva (ADR-0042/0043/0044, todas mesmo failure mode "baseline inferido"). A regra "inventário descreve, Spoke decide" continua valendo — qualquer picker marcado "Não drilled" no §16 é inferência até inspeção LIVE.
- Numpad `TimePickerSheet` (ADR-0042) é agora reusado por 3 superfícies (Partida, Destino, Pausa) — qualquer mudança nele tem blast radius triplo.
- Evidência do dump em `/tmp/spoke-a56-pausa-inspection/` (EVIDENCE.md + phase1-research-findings.json) — efêmera, referenciada pelo ADR-0044.

## Reference Material Used

- Maestro MCP (M54 `RQCW401G33T`): `launchApp`/`run`/`inspect_screen`/`take_screenshot` da sub-tela Pausa ao vivo.
- Dart MCP + Context7: idiomas Flutter 3.44 (ChoiceChip/SegmentedButton, showTimePicker, showModalBottomSheet, Riverpod 3).
- ADR-0042 (numpad), ADR-0043 (Destino — template estrutural do ADR-0044).
- Memory: `feedback_spec_baseline_and_workflow_halt` (1st-occurrence surprise = escalar), `feedback_spoke_parity_zero_debt_per_ms`, `lesson_showmodalbottomsheet_returns_intent_pattern`, `lesson_uiautomator_blindspot_compose_imagevectors`.
- Workflow: `wza6xa6s7` (pesquisa Fase 1, 5 agentes).
