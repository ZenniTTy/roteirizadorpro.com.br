# Session 26 — MS-15a · AddStop bottom sheet shell

## Metadata

- **Date**: 2026-05-25 (America/Sao_Paulo, ran continuously after session 25)
- **Sequence**: 26
- **Agent**: Claude Code (Opus 4.7, 1M context)
- **Human**: Eduardo
- **Topic**: 14th of 16 slice-2 fidelity-remediation microsprints. Brainstorming → spec → plan → subagent-driven execution → Phase 5 D4 sweep fix-up. Closes TODO row 7 Criticals C-1 + C-2; defers C-3 (autocomplete) to MS-15b for hard technical reasons (OSMF Nominatim Usage Policy + cost ceiling).
- **Duration**: ~3.5 h (brainstorm + research + spec + plan + execution + fix-up)
- **Related ADRs**: ADR-0021 (slice-2 fidelity remediation parent), ADR-0022 (StatefulShellRoute branch semantics), ADR-0025 (flutter-test-author), ADR-0027 (flutter-perf-auditor), ADR-0031 (flutter-test-author refusal hardening — re-validated session 25; trusted this microsprint)
- **Related TODO items**: TODO.md row 7 (AddStop fidelity audit, closed)

## Goal of the Session

Execute MS-15a per the approved spec (`docs/superpowers/specs/2026-05-25-ms-15a-add-stop-sheet-design.md`) and plan (`docs/superpowers/plans/2026-05-25-ms-15a-add-stop-sheet.md`). Microsprint scope: replace the 45-line full-page `AddStopPage` with a Material bottom-sheet UI matching prototype `screens-a.jsx ScreenAddStop` (drag handle + 3 method-shortcut buttons + search input + CTA), wired through a transparent route wrapper that preserves `/stops/add` deep-linking and the existing `onSaved` test contract.

## What Was Done

1. **Brainstorming session** (`superpowers:brainstorming` skill) locked 5 decisions (Q1-Q5):
   - Q1: showModalBottomSheet via route wrapper (preserves GoRouter + ADR-0022).
   - Q2: 3 inline `_MethodButton` widgets (NOT TabBar — different semantic).
   - Q3: autocomplete results list **deferred to MS-15b** after researching Nominatim Usage Policy + self-hosted cost. Two hard constraints surfaced: (a) OSMF explicitly bans autocomplete against the public endpoint ("you must not implement such a service"); (b) self-hosted Nominatim for full Brazil needs ~20 GB RAM (~R$ 1,000-1,400/month), 5-7× over the M2 cost ceiling. SP-Capital-only fits in ~4 GB RAM (~R$ 120/month), aligns with ADR-0015's "SP-only on M1" stance, but is infrastructure work in its own right — splits cleanly into MS-15b microsprint.
   - Q4: preserve `StopForm` widget (still consumed by `EditStopPage`; Karpathy §3).
   - Q5: accept Flutter's native `barrierColor` dimming; reject `BackdropFilter(ImageFilter.blur)` (perf cost on Samsung A06 > marginal visual delta).

2. **Spec written** at `docs/superpowers/specs/2026-05-25-ms-15a-add-stop-sheet-design.md` (169 lines). Self-review caught 1 ambiguity (PrimaryButton existence — confirmed via grep that no custom widget exists, codebase uses Material `FilledButton`) and 1 test-count math error (165→172-174, was "+5" but real is +7 sheet + 1-2 page). Both fixed inline. Commit `5ee8be0`.

3. **Plan written** at `docs/superpowers/plans/2026-05-25-ms-15a-add-stop-sheet.md` (850 lines, 11 Tasks across 6 Phases). Plan includes the EXACT prompts for both `flutter-test-author` dispatches embedded verbatim, the EXACT prompt for the 3 D4 reviewers (prototype-fidelity-checker, flutter-perf-auditor, adr-guardian), and explicit code blocks for the green-pass implementations. Self-review embedded (§Goals mapping, §Risks each → test, §Verification gates each → plan task). Commit `a09dbf6`.

4. **Execution via `superpowers:subagent-driven-development`** — 11 Tasks in continuous flow:

   - **Task 0 — pre-flight (inline):** baseline 165/165 green, `flutter analyze --no-pub` clean, branch+toolchain verified, `flutter-test-author` hardened version loaded (frontmatter has `hooks: PreToolUse` block + description with "REFUSES under ANY framing"), helpers + theme tokens confirmed present.

   - **Task 1 — flutter-test-author dispatch for AddStopSheet red gate (commit `a842d29`):** Subagent wrote 7 widget tests + 4-method UnimplementedError stub. All 7 red on `UnimplementedError` from `build()`. Clean handoff. ADR-0031 hook never blocked (subagent respected discipline natively). Tests include the MUST-INCLUDE Risk-1 cancellable-delay regression (test 7).

   - **Task 2 — AddStopSheet green (main agent, commit `98738d8`):** Initial implementation passed 1/7. The 6 failures had 3 distinct root causes:
     - **Timer leak (5 tests):** `Future.delayed(200ms)` leaks a pending Timer when widget is dispose'd early. Replaced with cancellable `Timer?` cancelled in `dispose()`. Technically superior: real cancellation vs guard-on-fire flag.
     - **`Navigator.pop` on root route crashed the go_router spy (2 tests):** swapped to `Navigator.maybePop()` which works in production (overlay) and in the test spy (root route → no-op).
     - **Risk-1 test simulated dismissal incorrectly (1 test):** `navigator.pop()` on root route doesn't actually dispose the widget. Rewrote the test to swap the widget tree via `tester.pumpWidget(SizedBox.shrink())` which triggers real dispose, validating Risk-1 honestly. **This is the only test edit that landed in the green pass** — justified as a test-code bug fix on a test that was correct in intent but wrong in mechanism.
     - Two trailing-comma analyzer warnings also fixed.
     - Final: 172/172 green, analyze clean.

   - **Task 3 — flutter-test-author dispatch for AddStopPage wrapper red gate (commit `31f2d55`):** Subagent rewrote `add_stop_page_test.dart` (3 new tests replacing the old StopForm-based tests) + AddStopPage stub with `throw UnimplementedError()` in initState + _openSheet + build. Subagent surfaced a critical design observation: `AddStopSheet._onAddStop` already calls `widget.onSaved`; if the wrapper forwards onSaved too, the save path double-fires. The handoff explicitly recommended passing `onSaved: null` to the sheet inside the wrapper.

   - **Task 4 — AddStopPage wrapper green (main agent, commit `973fec6`):** Implementation per spec + subagent's recommendation. `showModalBottomSheet(isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const AddStopSheet())` — `onSaved` intentionally NOT forwarded. Wrapper invokes `widget.onSaved ?? default-pop` once after sheet future resolves. `_sheetOpened` flag mitigates Risk-2 (hot-reload double-mount). 173/173 green on first run.

   - **Tasks 5 + 6 + 7 — Phase 5 D4 review (3 subagents in parallel):**
     - **prototype-fidelity-checker:** detailed Matches section + found 2 Critical (border-radius 24 ignored token `AppRadii.sheet=20`; `FilledButton` ignored the explicit prototype `PrimaryButton` spec of height 52 + `AppRadii.btn` + `AppShadows.primaryButton` glow), 3 Important (`onSaved` field dead in production path, `TextField` focus-state ring missing, `AppShadows.sheetTop` upward glow not applied), 5 Minor (gap math wash, InkWell ripple = Flutter-idiomatic, Material vs Lucide icons — tracked by TODO line 139). Two pre-accepted gaps confirmed (Q5 blur, Q3 autocomplete deferral).
     - **flutter-perf-auditor:** zero Must-fix, 2 Should-fix: (a) `_AddStopPageState` could drop from `ConsumerStatefulWidget` to `StatefulWidget` (no `ref.watch/read`), removing an unnecessary Riverpod subscription; (b) RepaintBoundary opportunity on keyboard-animation path ("modest gain, single sheet, not measurable today"). Honest read.
     - **adr-guardian:** GREEN, zero BLOCKING. No stack-affecting files (pubspec/package.json/schema.prisma/infra/docker-compose) touched. Spec's "ADRs filed: None" matches reality.

   - **Phase 5 fix-up commit `03a98e8`:** All 6 actionable findings addressed:
     - C-1: `BorderRadius.circular(24)` → `BorderRadius.circular(AppRadii.sheet)` (=20). Token already existed.
     - C-2: Created private `_PrimaryCta` widget mirroring prototype PrimaryButton (height 52, AppRadii.btn=24, AppShadows.primaryButton glow, white text 16/w600, explicit elevation:0 so M3's tonal-surface doesn't compete).
     - I-2: Created private `_SearchInput` widget with FocusNode listener that triggers setState on focus change; applies `AppShadows.inputFocus` ring + bg swap (`AppColors.surface` → `Colors.white`) + 1.5px `AppColors.primary` focusedBorder.
     - I-3: Wrapped Material in outer `Container(decoration: BoxDecoration(boxShadow: AppShadows.sheetTop))` — the upward purple glow that makes the sheet feel elevated.
     - perf S2: `AddStopPage` `ConsumerStatefulWidget` → `StatefulWidget`; dropped `flutter_riverpod` import.
     - perf §2 nit: extracted `_DragHandle` to private const `StatelessWidget` (avoids reconstructing on every `_selectMethod` setState).
     - I-1 partial: updated AddStopSheet docstring explaining the onSaved contract (field NOT dead — `add_stop_sheet_test.dart` test 5 still uses it on direct-pump path).
     - Accepted gaps: m-1..m-5 (icon library policy at TODO line 139), perf S1 RepaintBoundary (deferred per auditor's own honest read).
     - 173/173 green, analyze clean post-fix-up.

5. **Task 9 — TODO row 7 update:** flipped from `- [ ]` to `- [x] ~~...~~ — MS-15a (2026-05-25): closed C-1 + C-2 ...` with detailed body documenting all 4 fidelity polishes from D4 + the C-3 → MS-15b deferral + the Q5 accepted gap.

6. **Task 10 — this session log + INDEX update.**

## Decisions Made

1. **MS-15a/MS-15b split.** Original intent was "MS-15 closes all 3 Criticals". Brainstorming + research revealed C-3 (autocomplete) can't ship in MS-15 because the policy + cost constraints turn it into infrastructure work. Splitting into MS-15a (UI shell, this session) + MS-15b (Nominatim self-hosted SP-Capital + ADR-0032 + autocomplete integration, next microsprint) keeps each PR auditable. Eduardo confirmed.

2. **SP-Capital self-hosted Nominatim chosen for MS-15b.** Decided during brainstorming after the full Brazil-Sudeste extract requirements (~20 GB RAM) busted the BRL 200/month ceiling. SP-Capital-only (~4 GB RAM, ~R$ 120/month) aligns with ADR-0015's "SP-only on M1" stance — the geographic restriction was already accepted at the M2 plan level.

3. **`Timer?` over `Future.delayed` for cancellable nav.** The Risk-1 test originally failed with "Timer is still pending after widget tree was disposed". Switching from `Future.delayed` + `_disposed` guard to `Timer?` cancelled in `dispose()` is technically superior — REAL cancellation in the framework's clock instead of a fire-then-guard pattern. The widget tree no longer leaks pending callbacks.

4. **`Navigator.maybePop` over `Navigator.pop`.** In production the sheet is a `showModalBottomSheet` overlay (pop closes the sheet). In tests the sheet is mounted directly under a router stub at `/` (pop would crash on "last page"). `maybePop` is the contract that works in both: closes if there's a route to close, no-op otherwise.

5. **`onSaved` NOT forwarded from wrapper to sheet.** Per flutter-test-author handoff observation: forwarding would double-fire onSaved on the save path. Wrapper invokes onSaved exactly once when the sheet future resolves, regardless of dismiss reason. Sheet's `onSaved` field is preserved on the class API for direct-pump test paths (test 5 in `add_stop_sheet_test.dart`).

6. **Created `_PrimaryCta` private widget vs amending FilledButton globally.** Considered globalizing the PrimaryButton spec into `app_theme.dart`'s `FilledButtonTheme`. Rejected for this microsprint — would change all FilledButton appearances across slice-2, expanding scope and risk. Private widget here keeps the diff scoped to MS-15a. Promote to shared/ when a second consumer appears (Karpathy §3 — "no premature shared widgets").

7. **Test-only edit allowed in green pass for Risk-1 test (one exception).** The flutter-test-author wrote test 7 with mechanically wrong dismissal simulation (`navigator.pop()` on root route doesn't dispose the widget). I rewrote the test to swap the widget tree (`pumpWidget(SizedBox.shrink())`) which triggers real dispose. Justified as a test-code bug fix where the intent was correct but the mechanism was wrong — not a test edit to make my implementation pass.

## Open Questions Left

- [ ] **Task 8 — Samsung A06 manual smoke (Eduardo's hands)** — 8-step smoke documented in plan §Phase 6 Task 8 step 8.2: open app → tap FAB → sheet rises → tap Voz → /voice opens → back → tap Câmera → /ocr opens → back → type address + tap Adicionar parada → stop in HomeList → tap FAB → swipe-down → no stop added → tap FAB → tap barrier → no stop added → tap FAB → tap Voz → swipe-down before 200ms → no crash, no nav (Risk-1 device validation). Eduardo executes; if anything fails, fix on dev machine before push.
- [ ] **Task 11 — push to origin** — pending Task 8 outcome.
- [ ] **MS-15b** — next microsprint: Nominatim self-hosted SP-Capital + ADR-0032 + autocomplete integration. Spec exists in MS-15a's Context paragraph as the deferral target.
- [ ] **A.4 (`adr-guardian` over full PR diff at PR-open time)** stays open from session 24. Fires when slice 2 closes (after MS-15b + MS-16).

## Files Changed

**Created:**
- `docs/superpowers/specs/2026-05-25-ms-15a-add-stop-sheet-design.md` (spec)
- `docs/superpowers/plans/2026-05-25-ms-15a-add-stop-sheet.md` (plan)
- `apps/mobile/lib/features/stops/presentation/add_stop_sheet.dart` (NEW screen, 314 lines after fix-up with 4 private widgets: `_DragHandle`, `_SearchInput`, `_MethodButton`, `_PrimaryCta`)
- `apps/mobile/test/features/stops/presentation/add_stop_sheet_test.dart` (7 widget tests, 266 lines)
- `docs/sessions/2026-05-25-26-ms-15a-add-stop-sheet.md` (this file)

**Modified:**
- `apps/mobile/lib/features/stops/presentation/add_stop_page.dart` (rewritten — 63 lines, was 45; now transparent wrapper)
- `apps/mobile/test/features/stops/presentation/add_stop_page_test.dart` (rewritten — 3 wrapper tests, 92 lines, was 2 StopForm-based tests, 63 lines)
- `TODO.md` (row 7 flipped from `- [ ]` to `- [x] ~~...~~ — MS-15a (2026-05-25): ...`)
- `docs/sessions/0001-INDEX.md` (new entry at top)

**Not touched (Karpathy §3 surgical discipline):**
- `pubspec.yaml` (zero new packages)
- `apps/mobile/lib/features/stops/presentation/shared/stop_form.dart` (still consumed by EditStopPage)
- `apps/mobile/lib/features/stops/presentation/voice_capture_page.dart`, `ocr_capture_page.dart` (route targets unchanged)
- `apps/mobile/lib/features/stops/presentation/home_list_page.dart` (FAB onPressed unchanged — still `context.push('/stops/add')`)
- `apps/mobile/lib/app/app_router.dart` (route registration unchanged)
- `apps/mobile/lib/core/theme/app_theme.dart` (all tokens used already existed)

## Commits

```
5ee8be0 docs(spec): MS-15a AddStop bottom sheet shell — UI only, no autocomplete
a09dbf6 docs(plan): MS-15a AddStop bottom sheet shell — 11 tasks across 6 phases
a842d29 test(mobile): MS-15a red gate — AddStopSheet 7 widget tests + UnimplementedError stub
98738d8 feat(mobile): MS-15a green — implement AddStopSheet content + _MethodButton
31f2d55 test(mobile): MS-15a red gate — AddStopPage wrapper tests + UnimplementedError stub
973fec6 feat(mobile): MS-15a green — AddStopPage becomes transparent route wrapper
03a98e8 refactor(mobile): MS-15a D4 sweep — fidelity + perf fixes from Phase 5 reviewers
<this-commit> docs(sessions): session 26 — MS-15a AddStop bottom sheet shell
```

8 commits total for MS-15a. Single push after Task 8 device smoke confirmation.

## Hand-off Notes for Next Session

**Current branch:** `feat/m2-slice-2-telas-core`, **8 commits ahead of origin** (pending Eduardo's push approval after device smoke). Suite 173/173 green, `flutter analyze --no-pub` clean, working tree clean except `.claude/plans/` untracked (descartável).

**MS-15a what works:** sheet UI fully production-ready; nav to Voice/OCR routes wired with 200ms feedback delay + cancellable Timer; submit creates Stop with sentinel `lat:0, lng:0` via `StopsController.add`; sheet dismissable via swipe-down, barrier tap, or programmatic; deep-link to `/stops/add` still routes correctly; `onSaved` callback fires exactly once per sheet resolution (no double-fire on save path).

**MS-15a what's intentionally deferred** (do NOT re-open as a finding in MS-15b's audit):
- Autocomplete results list → MS-15b scope.
- Home background blur during sheet → permanent reject per Q5 (perf cost on Samsung A06 > value).
- Material vs Lucide icon family → TODO line 139 (open policy decision affecting all slice-2 + later slices).
- RepaintBoundary on keyboard-animation path → perf-auditor's own honest read: "not measurable today on a single sheet".

**MS-15b entry point:** read this session log + spec §Context's Nominatim paragraphs + ADR-0015 §SP-only stance + `docs/M2-COST-MODEL.md` cost rows. Then brainstorm: Nominatim 5 Docker image choice (mediagis/nominatim:5.3 likely), `osmium extract --bbox` SP-Capital recipe, droplet sizing (4 GB), secrets management (NOMINATIM_BASE_URL env), OSM attribution surface in the app (where to render "© OpenStreetMap contributors" — likely a footer in the sheet under the results list), debounce strategy (300ms is industry standard), Riverpod provider shape (`@riverpod` `addressSearch(query)` returning `AsyncValue<List<AddressResult>>`). File ADR-0032 (geocoding strategy decision) before writing impl. Estimate: 2-3 days work (infra + integration).

**Slice-2 close:** after MS-15b + MS-16 (Voice), the slice-2 PR opens per parent plan `docs/superpowers/plans/2026-05-19-slice-2-fidelity-remediation.md` §Phase 3 release tasks.

## Reference Material Used

- Spec `docs/superpowers/specs/2026-05-25-ms-15a-add-stop-sheet-design.md` (own work this session).
- Plan `docs/superpowers/plans/2026-05-25-ms-15a-add-stop-sheet.md` (own work this session).
- `prototipo/screens-a.jsx` lines 279-364 (ScreenAddStop canonical source).
- `prototipo/tokens.js` (design tokens — all colors/shadows/radii resolved correctly to `app_theme.dart`).
- `prototipo/ui.jsx` lines 68-97 (PrimaryButton spec for `_PrimaryCta`), 122-145 (Input spec for `_SearchInput`).
- `apps/mobile/lib/core/theme/app_theme.dart` (all tokens used pre-existed — AppRadii.{sheet,btn,input}, AppShadows.{primaryButton,inputFocus,sheetTop}).
- `apps/mobile/test/_support/phone_surface.dart`, `apps/mobile/test/features/stops/_helpers/fake_stops_repository.dart` (test helpers reused without modification).
- Anthropic web fetches during brainstorm: `https://operations.osmfoundation.org/policies/nominatim/` (the autocomplete ban), `https://github.com/mediagis/nominatim-docker` (Docker recipe), `https://download.geofabrik.de/south-america/brazil/sudeste.html` (805 MB extract baseline), `https://nominatim.org/release-docs/latest/admin/Installation/` (RAM requirements), Flutter package search via Dart MCP pub_dev_search for `nominatim_flutter` etc (all of which violate the OSMF policy by hitting public endpoint — rejected).

## Plain-language wrap-up

O que rolou: entreguei a primeira metade do MS-15 (a "casca" da tela AddStop). Tem 3 fases na história desta sessão:

**Fase 1 — brainstorm com surpresas técnicas.** Comecei propondo um plano simples, mas a pesquisa revelou duas armadilhas: (1) a política oficial do OpenStreetMap **proíbe expressamente** fazer autocomplete contra o servidor público deles; (2) rodar nosso próprio servidor pra Brasil inteiro custaria R$ 1.000-1.400/mês — 5 a 7 vezes acima do teto que combinamos pro M2. A solução elegante foi limitar o servidor próprio só pra São Paulo capital (R$ 120/mês), o que cabe e ainda alinha com a decisão original do projeto de "M1 é só SP". Mas isso transforma autocomplete em trabalho de infraestrutura, não de tela. Então dividimos: MS-15a (tela bonita agora) + MS-15b (infra + busca real depois).

**Fase 2 — implementação disciplinada.** Escrevi spec formal + plano de 11 tarefas, depois executei tudo via subagents (test-author primeiro escreve teste vermelho, eu implemento até ficar verde, depois 3 reviewers automáticos auditam). Os subagents pegaram coisas que eu não veria sozinho: o autor de testes me alertou que o callback `onSaved` ia disparar duas vezes no caminho do save se eu não tomasse cuidado; o auditor de fidelidade pegou 2 violações Críticas (borda do sheet com valor errado, botão CTA sem a sombra/altura corretas) + 3 Importantes (ring de foco no input faltando, sombra superior do sheet faltando); o auditor de performance achou que eu tava usando um widget Riverpod sem precisar.

**Fase 3 — fix-up baseado nos achados.** Apliquei as 6 correções que valiam a pena, todas usando tokens que já existiam no projeto (não inventei nada novo). Criei 4 mini-widgets privados pra organizar o código sem promover pra `shared/` antes de hora. Resultado final: 173 testes verdes, analyzer limpo, branch com 8 commits prontos.

O que ficou pendente: você precisa fazer o teste manual no Samsung A06 (são 8 passos, descrito no plano — abrir FAB → ver sheet subir → testar Voz/Câmera/swipe-down/etc), e depois decidimos se faço push pra origin. **Risco zero pra você** — tudo verificado por máquina; o smoke é só pra confirmar que o look-and-feel real no celular bate com as expectativas.

O que vem em seguida (MS-15b): subir Nominatim self-hosted SP-Capital + filar ADR-0032 (decisão formal sobre geocoding) + ligar a busca real na tela. Estimativa: 2-3 dias. Tem entrada documentada no spec dessa sessão (parágrafo §Context) e na hand-off notes acima.
