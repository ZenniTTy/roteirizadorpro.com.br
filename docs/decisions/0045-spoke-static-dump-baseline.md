# ADR-0045: Dump estático completo do Spoke v3.65.1 como baseline funcional (uma vez, não tela-por-tela)

- **Status:** Accepted
- **Date:** 2026-06-09
- **Deciders:** Eduardo
- **Related ADRs:** ADR-0035 (white-label: shipped product 100% identidade original), ADR-0036/0037 (parity gates + Maestro MCP runtime), ADR-0041/0042/0043/0044 (os 4 retrabalhos por baseline inferido que este ADR existe para acabar)

## Context

O clone funcional do Spoke vinha sofrendo um **failure mode recorrente**: o inventário (`docs/inventory/2026-05-26-spoke-vs-rotpro.md`) é uma **paráfrase** escrita por observação de superfície, com **20 telas/pickers marcados "Não drilled"** (§11, linhas 1811-1832) — nunca inspecionados a fundo. Cada microsprint pegava uma dessas linhas e completava a lacuna por **inferência** ("botão de pausa provavelmente abre um sheet com chips 15/30/60"). Quatro vezes seguidas a inferência saiu errada e gerou ADR de correção depois de já ter código:

- ADR-0041→0042: time picker era numpad, não wheel (baseline 0-byte).
- ADR-0043: Destino era sheet 3-cards, não página RadioListTile (baseline mislabeled).
- ADR-0044: Pausa era página full-screen + janela de horário + minutos livres, não sheet + chips (baseline "Não drilled").

A inspeção em runtime (Maestro MCP, clicar tela-por-tela) é boa para **confirmar** um detalhe, mas péssima para **mapear** um app inteiro: deixa lacunas por construção, e cada lacuna vira um palpite. Eduardo relatou que num outro projeto **"baixar o app completamente"** (extração estática do APK) acelerou demais o desenvolvimento — a intuição correta, e já permitida (APK inspection, decompilation, resource extraction são permitidos quando esclarecem ambiguidade mais rápido que runtime).

Pesquisa de melhores práticas 2026 (Context7 + WebSearch, workflow `w3hyaqz5j`) definiu o pipeline e as ferramentas, confirmando versões ao vivo.

## Decision

**1. Fazer o dump estático completo do Spoke v3.65.1, uma vez, e derivar dele uma tabela-mestre que substitui a inferência por fato.** O Spoke (`com.underwood.route_optimiser`) é distribuído como **split App Bundle** (base.apk + split_config.{pt,arm64_v8a,xxhdpi}.apk). O pipeline:

| Etapa | Ferramenta (versão) | Entrega |
|---|---|---|
| Puxar os 4 splits | `adb pull` (loop com `tr -d '\r'`) | os 4 .apk no disco |
| Juntar num APK standalone | **APKEditor V1.4.9** (REAndroid) | `spoke-merged.apk` com recursos completos (textos PT-BR + ícones xxhdpi) |
| Extrair recursos | **apktool 3.0.2** | `strings-pt-rBR.xml` (2.404 textos), manifest, drawables |
| Decompilar código | **jadx 1.5.5** (`--deobf`) | 53.036 `.java` legíveis (`com.circuit.ui.*`) |
| Organizar | Grep/ripgrep + análise | `MASTER-TABLE.md` (string→recurso→tela→modelo das 20 telas) |

**Por que NÃO bundletool:** `build-apks --mode=universal` exige o `.aab` ORIGINAL (do dono do build), que não temos — só os splits instalados, e AAB→splits é irreversível. bundletool é a ferramenta errada para juntar splits puxados de um device.

**2. Artefatos LEVES no repo, PESADOS fora (decisão de Eduardo, meio-termo).** Entram no git, sob `docs/inventory/spoke-dump-v3.65.1/`: a tabela-mestre, os `strings-*.xml` (o ouro, ~440 KB), o manifest, a árvore de telas, e o README com o comando de regeneração. Ficam FORA do git (em `~/spoke-dump`, regeneráveis em ~10 min): o APK binário (106 MB), os 53k `.java` decompilados (587 MB), e drawables binários. O `.gitignore` bloqueia os pesados. Isto captura 100% do valor auditável sem inchar o histórico do git permanentemente com código de terceiro.

**3. Divisão de trabalho dump-estático vs runtime (a inversão que mata o retrabalho).** O dump responde **O QUÊ existe** (textos exatos, campos, defaults, ranges, enums de picker, árvore de telas — verdade congelada). O runtime (Maestro MCP, per ADR-0037) responde **COMO se comporta** (qual tela o tap abre, back-stack, animações — verdade viva). **Ordem nova:** dump PRIMEIRO (gera a tabela + hipóteses concretas com texto exato), runtime DEPOIS só para CONFIRMAR cada linha (campo `Precisa-runtime` por linha da tabela). Deixa-se de "clicar para descobrir o que tem" e passa-se a "clicar 1x para confirmar o que o dump já disse". O `spoke-parity-checker` (ADR-0036) continua sendo o gate D4 — agora alimentado pela tabela em vez de inferência.

**4. Versão travada no nome.** Tudo carrega `v3.65.1` (versionCode 3650100). Skew de versão é o risco nº1 de análise estática; o nome da pasta + o header de cada doc tornam o skew visível, e re-puxar é o caminho quando o app atualizar.

## Consequences

- **Positive (mata o failure mode):** os 20 "Não drilled" viram 20 linhas rastreáveis a um recurso real. As Áreas 6-11 (que têm pickers complexos) passam a ser executadas contra fato, não palpite. Sem mais ADRs-de-correção do tipo 0041-0044.
- **Positive (textos PT-BR prontos):** 2.404 strings PT-BR verbatim eliminam a necessidade de inventar microcópia (anti-pattern #21) — embora ADR-0035 ainda mande escrever PT-BR ORIGINAL, agora temos a referência exata do que cada tela diz.
- **Positive (árvore de navegação completa):** `com.circuit.ui.*` revela o mapa de telas inteiro (ex: `ui/home/editroute/components/detailsheet/breaks`, `ui/delivery/signature`, `ui/dialogs/timewindowpicker`) — descoberto sem clicar.
- **Positive (descobertas além do inventário):** o dump revelou superfícies que o inventário não tinha (ex: `break_detail_sheet_*` — comportamento da Pausa DURANTE a entrega, que o ADR-0044 não cobriu porque foca no agendamento).
- **Negative (Pairip + ofuscação parcial):** algumas classes vêm `a/b/c`; a lógica fina de classes ofuscadas não é confiável. Mitigação: confiar em strings (sobrevivem) + nomes de pacote (legíveis); o `Precisa-runtime` marca o que o dump não fecha.
- **Negative (skew de versão):** dump é snapshot congelado de v3.65.1; o app na loja pode atualizar. Mitigação: versão no nome + re-pull.
- **Neutro (legal):** o dump é artefato de engenharia interno (permitido no repo); o shipped product mantém identidade 100% original (ADR-0035). Não reempacotar nem rodar APK modificado.

## Alternatives considered

1. **Continuar incremental (runtime per microsprint).** Rejeitado — é o status quo que gerou 4 retrabalhos. Paga "inspeção + susto + refação" 20×; o dump paga "inspeção" 1×.
2. **bundletool universal.** Rejeitado — exige o `.aab` original que não temos (limitação arquitetural confirmada). APKEditor é a ferramenta certa para splits puxados de device.
3. **Tudo no repo (resposta literal inicial de Eduardo).** Substituído pelo meio-termo após eu sinalizar o trade-off: commitar 106 MB de APK + 587 MB de código de terceiro incharia o histórico do git permanentemente. Os leves auditáveis + regeneração documentada capturam o valor sem o custo.
4. **Só extração técnica, sem tabela-mestre.** Rejeitado por Eduardo — adiaria o trabalho de organização e o ganho anti-retrabalho viria parcial. A tabela é o que torna o dump consultável em vez de um monte de arquivos.

## References

- Pesquisa de best-practices (workflow `w3hyaqz5j`, Context7 + WebSearch 2026): APKEditor V1.4.9, apktool 3.0.2, jadx 1.5.5, bundletool 1.18.3 (descartado), versões verificadas ao vivo.
- Dump materializado: `docs/inventory/spoke-dump-v3.65.1/` (README + strings + manifest + ui-screen-tree + MASTER-TABLE).
- Artefatos pesados (fora do git): `~/spoke-dump/` (regeneração no README).
- Failure mode que isto encerra: ADR-0041/0042/0043/0044 (todos "baseline inferido corrigido por dump live").
- Inventário a ser atualizado: `docs/inventory/2026-05-26-spoke-vs-rotpro.md` §11 (20 "Não drilled" → rastreáveis à tabela).
- Memory: `lesson_spoke_visual_inspection_before_coding`, `feedback_spec_baseline_and_workflow_halt`, `lesson_uiautomator_blindspot_compose_imagevectors`, `feedback_spoke_parity_zero_debt_per_ms`.
