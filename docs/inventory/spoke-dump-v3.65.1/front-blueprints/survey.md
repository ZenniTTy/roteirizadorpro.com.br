# Front blueprint — survey

**Data:** 2026-06-21
**Fonte:** `jadx-out/sources/com/circuit/p016ui/survey/` + `com/circuit/p016ui/onboarding/` + `res/values-pt-rBR/strings.xml`
**Escopo:** pesquisas/feedback in-app — 3 superfícies distintas: (A) Pesquisa de Rota, (B) Pesquisa de Tradução, (C) Pesquisa de Onboarding (seleção de perfil de trabalho + follow-up para não-público-alvo).

---

## Visão Geral — Hierarquia de Classes

| Classe | Tipo | Propósito |
|--------|------|-----------|
| `com.circuit.ui.survey.SurveyDialogFragment` | `BottomSheetDialogFragment` | Contêiner das pesquisas pós-rota (RouteSurvey) e de tradução (TranslationSurvey) |
| `com.circuit.ui.survey.SurveyViewModel` | ViewModel | Estado + submit de resposta (positiva/negativa) + disparo do Play In-App Review |
| `com.circuit.ui.survey.SurveyType` | Enum | `RouteSurvey`, `TranslationSurvey` |
| `com.circuit.ui.survey.SurveyArgs` | `Parcelable` | Argumento de navegação: carrega `SurveyType` |
| `SurveyState` (`exd`) | data class | Campos: `question: StringResource`, `positiveAnswer: StringResource`, `negativeAnswer: StringResource` |
| `SurveyViewEvent` (`AbstractC4081b`) | sealed class | `Close`, `RequestReview` |
| `com.circuit.ui.onboarding.OnboardingSurveyFragment` | `Fragment` | Tela de perfil de trabalho no fluxo de onboarding |
| `OnboardingSurveyViewModel` (`C3831b`) | ViewModel | Lógica de seleção de opção + estado `Survey`/`FollowUp` |
| `OnboardingSurveyOption` | Enum | 5 opções de perfil (ver §C abaixo) |
| `OnboardingDisplayedState` | Enum | `Started`, `Completed` — persiste que o onboarding já foi exibido |

---

## A — SurveyDialogFragment (RouteSurvey e TranslationSurvey)

### 1. Nome, Propósito, Classe

**Nome:** Survey Dialog (Pesquisa de Feedback)
**Propósito:** Coleta resposta binária (positivo/negativo) do usuário sobre a rota concluída ou sobre a qualidade da tradução do app. Para RouteSurvey positivo, triggera o Play In-App Review API.
**Classe:** `com.circuit.ui.survey.SurveyDialogFragment` extends `BottomSheetDialogFragment`

### 2. Estrutura (em ordem de cima para baixo)

O Compose é renderizado por `cxd.m30586a(state, onPositive, onNegative, onSkip, modifier, ...)`. Baseado na análise do bytecode, a estrutura é uma `Column` com:

1. **Texto da pergunta** — `state.question` (string dinâmica vinda do backend/analytics), estilo título.
2. **Botão positivo** (linha com ícone à esquerda) — ícone `R.drawable.thumb_up` (polegar para cima) + texto `state.positiveAnswer`. Padding: topo 24dp. Ocupa largura total. Chama `onPositive`.
3. **Spacer** — 8dp.
4. **Botão negativo** (linha com ícone à esquerda) — ícone `R.drawable.thumb_down` (polegar para baixo) + texto `state.negativeAnswer`. Chama `onNegative`.
5. **Botão "Pular"** — texto simples, alinhado ao fim horizontal (fillMaxWidth), sem ícone. Chama `onSkip`.

O sheet é configurado no `onViewCreated` com `BottomSheetBehavior.setPeekHeight(Integer.MAX_VALUE)` + `isDraggable = true` — ou seja, altura máxima e não-recolhável.

### 3. Strings PT-BR Verbatim

Strings da pesquisa de **rota** (`RouteSurvey`) e **tradução** (`TranslationSurvey`) são carregadas dinamicamente (via backend/analytics — campo `question`, `positiveAnswer`, `negativeAnswer` em `SurveyState`). As strings fixas da UI são:

| Chave | String PT-BR |
|-------|-------------|
| `survey_translation_title` | `"Avalie a qualidade da tradução do app."` |
| `survey_translation_positive_answer` | `"A tradução é boa"` |
| `survey_translation_negative_answer` | `"Precisa melhorar"` |
| `survey_translation_skip` | `"Pular avaliação"` |
| `survey_translation_feedback` | `"Obrigado por nos ajudar a melhorar!"` |

Para `RouteSurvey`, as strings (pergunta, resposta positiva, negativa) vêm do backend — não estão fixas no APK.

### 4. Navegação

- **Acionado por:** `HomeViewModel` ao fim de uma rota completa. Probabilidade: `3.33%` (1/30). Lógica no `HomeViewModel`:
  - Se o idioma do dispositivo **NÃO é inglês** e `random < 0.0333` → `SurveyType.TranslationSurvey`
  - Senão, se `random < 0.0333` → `SurveyType.RouteSurvey`
  - Senão → nenhuma pesquisa
- **Aparece como:** `BottomSheetDialogFragment` sobre a tela atual (home/mapa).
- **Dismiss:**
  - Botão "Pular" → chama `m10057J()` → emite evento `Close` → fecha o sheet.
  - Botão negativo → submete resposta `false` → chama `m10057J()` → fecha.
  - Botão positivo (RouteSurvey) → submete resposta `true` → verifica cooldown 30 dias:
    - Último show < 30 dias atrás → fecha direto (`m10057J()`).
    - Último show >= 30 dias atrás → atualiza timestamp → emite evento `RequestReview` → abre **Play In-App Review** → fecha após review.
  - Botão positivo (TranslationSurvey) → submete resposta `true` → fecha direto (`m10057J()`).
  - Dismiss manual (swipe/back) → se `submitted == false` → registra analytics de "dismissed without answer".

### 5. Estados, Defaults, Enums

**`SurveyType`** (enum):
- `RouteSurvey` (ordinal 0) — pesquisa sobre a rota
- `TranslationSurvey` (ordinal 1) — pesquisa sobre qualidade da tradução

**`SurveyState`** (`exd`):
- `question: StringResource` — pergunta exibida (empty string por default na construção)
- `positiveAnswer: StringResource` — texto do botão positivo
- `negativeAnswer: StringResource` — texto do botão negativo

**Cooldown `RouteSurvey`:** 30 dias desde o último `positiveButtonClick` bem-sucedido (timestamp persistido em `DataStore`). Se dentro do cooldown → resposta é submetida mas o Play Review **não** é exibido.

**Flag `submitted` (`f33772p1: Boolean`):** `false` por default; marcado `true` na primeira interação (qualquer botão). Usado no `onDismiss` para saber se o dismiss foi manual.

### 6. Ícones (drawable → Lucide equivalente)

| drawable Spoke | Propósito | Lucide equivalente sugerido |
|---------------|-----------|----------------------------|
| `thumb_up` (vector drawable) | Botão positivo | `ThumbsUp` |
| `thumb_down` (vector drawable) | Botão negativo | `ThumbsDown` |

### 7. Precisa-runtime

- **Não** — estrutura completamente derivada do dump. Strings da `RouteSurvey` (pergunta/respostas) vêm do backend; a tela in-app só renderiza o que chega no `SurveyState`. Para TranslationSurvey todas as strings estão fixas no APK (listadas acima).

---

## B — Pesquisas Intercom (intercom_surveys_*)

As strings `intercom_surveys_*` presentes no `strings.xml` **pertencem ao SDK Intercom** (biblioteca de suporte/chat), não a código Circuit/Spoke próprio. Nenhum arquivo em `com/circuit/p016ui/survey/` as referencia. São usadas pelo SDK quando o time de suporte Spoke dispara surveys via painel Intercom.

**Para RotPro: [B2B — cortar].** RotPro não integra Intercom. Estas strings não precisam ser replicadas; o SDK não será incluído.

---

## C — OnboardingSurveyFragment (Pesquisa de Onboarding)

### C.1 — Tela Principal: Seleção de Perfil (estado `Survey`)

**Nome:** Onboarding Survey — Seleção de Perfil de Trabalho
**Propósito:** Primeira tela pós-login (onboarding) onde o usuário indica seu tipo de trabalho. Determina se o usuário é público-alvo (entrega de pacotes) ou não.
**Classe:** `com.circuit.ui.onboarding.OnboardingSurveyFragment` (Fragment Compose, estado `C3831b.b.Survey`)
**Arquivo de layout Compose:** `wpa.kt` (compilado como `wpa.java`)

#### Estrutura (em ordem de cima para baixo)

Tela cheia (`fillMaxWidth`, `fillMaxHeight`), fundo cor `theme.background`, coluna vertical:

1. **Cabeçalho (texto):**
   - Título: `"Início rápido"` — estilo heading, 40dp padding-bottom
   - Subtítulo: `"Qual opção descreve melhor seu trabalho?"` — estilo body

2. **Lista de opções de perfil** (LazyColumn ou Column com spacing 8dp entre cards) — 4 opções com card + 1 sem card (ver detalhes abaixo). Cada card tem:
   - Ícone ilustrativo (imagem PNG, `drawable-nodpi`) à esquerda
   - Título + subtítulo
   - Borda animada: selecionado → borda `theme.secondary` (selected); não-selecionado → borda `theme.outline` (default). Alpha animado: selecionado = 1.0, outros = 0.6.
   - Fundo: preenchido com alpha animado quando selecionado

3. **Texto de confirmação** (aparece abaixo das opções após seleção):
   - Visível apenas quando opção `PackageDelivery` está selecionada
   - Texto: `"Criamos o app para você!"` — estilo body, alpha animado (0.0 → 1.0)

4. **Botão de confirmação** (CTA primário):
   - Texto animado entre `"Vamos lá"` (PackageDelivery) e `"Continuar"` (outros grupos)
   - Aparece com translação vertical animada (56dp → 0dp) e alpha (0.0 → 1.0) após seleção
   - Ação: chama `onSubmitSurvey(selectedOption)`

#### Opções de Perfil (`OnboardingSurveyOption` enum, na ordem de exibição)

| Enum value | Drawable | Título PT-BR | Subtítulo PT-BR |
|-----------|---------|-------------|----------------|
| `PackageDelivery` (ordinal 0) | `onboarding_parcel_van.png` | `"Entrega de pacotes"` | `"UPS, DHL, FedEx..."` |
| `OrderDelivery` (ordinal 1) | `onboarding_scooter.png` | `"Entrega de pedidos"` | `"Uber Eats, Deliveroo..."` |
| `Services` (ordinal 2) | `onboarding_service_van.png` | `"Serviços"` | `"Jardineiro, encanador..."` |
| `Sales` (ordinal 3) | `onboarding_sales_car.png` | `"Vendas"` | `"Visitas a clientes"` |
| `None` (ordinal 4) | sem ícone (drawable = 0) | `"Nenhuma das opções acima"` | sem subtítulo |

`None` é renderizado diferente: sem card com borda (função `wpa.m46020a` separada), card com alpha 1.0 quando selected e border `theme.secondary`.

### C.2 — Strings PT-BR Verbatim (Tela Principal)

| Chave | String PT-BR |
|-------|-------------|
| `onboardingsurvey_title` | `"Início rápido"` |
| `onboardingsurvey_subtitle` | `"Qual opção descreve melhor seu trabalho?"` |
| `onboardingsurvey_targetgroup_button` | `"Entrega de pacotes"` |
| `onboardingsurvey_targetgroup_button_subtitle` | `"UPS, DHL, FedEx..."` |
| `onboardingsurvey_nontargetgroup1_button` | `"Entrega de pedidos"` |
| `onboardingsurvey_nontargetgroup1_button_subtitle` | `"Uber Eats, Deliveroo..."` |
| `onboardingsurvey_nontargetgroup2_button` | `"Serviços"` |
| `onboardingsurvey_nontargetgroup2_button_subtitle` | `"Jardineiro, encanador..."` |
| `onboardingsurvey_nontargetgroup3_button` | `"Vendas"` |
| `onboardingsurvey_nontargetgroup3_button_subtitle` | `"Visitas a clientes"` |
| `onboardingsurvey_nontargetgroup4_button` | `"Nenhuma das opções acima"` |
| `onboardingsurvey_targetgroup_confirmation_text` | `"Criamos o app para você!"` |
| `onboardingsurvey_targetgroup_confirmation_button` | `"Vamos lá"` |
| `onboardingsurvey_nontargetgroup_confirmation_button` | `"Continuar"` |

### C.3 — Navegação (Tela Principal)

- **De:** fluxo de login/cadastro → tutorial → OnboardingSurveyFragment (via navigation action `R.id.action_tutorial` após tutorial — ou direto pós-login se `OnboardingDisplayedState == Started`).
- **Ao confirmar `PackageDelivery`:**
  - Persiste `OnboardingDisplayedState.Completed`.
  - Analytics: `DriverEvents` (seleção + navegação).
  - Navega para tutorial (`R.id.action_tutorial`).
- **Ao confirmar qualquer não-público-alvo (`OrderDelivery`, `Services`, `Sales`, `None`):**
  - Analytics: evento de "não-público-alvo" enviado.
  - Muda estado interno para `FollowUp` → renderiza a **Tela Follow-Up** (§C.4) no lugar.
- **Back press:** interceptado — desabilitado (dispatcher registra handler mas sem ação — `finish()` não é chamado).

### C.4 — Tela Follow-Up: Mensagem de Redirecionamento (estado `FollowUp`)

**Nome:** Onboarding Follow-Up — "Criado para entregas"
**Propósito:** Exibida para usuários fora do público-alvo. Informa que o app é feito para entregadores de pacotes e oferece duas saídas: continuar mesmo assim ou desinstalar.
**Arquivo Compose:** `qpa.kt` (compilado como `qpa.java`)

#### Estrutura (em ordem de cima para baixo)

Coluna vertical, preenchimento de tela, fundo cor `theme.background`:

1. **Imagem ilustrativa** — `R.drawable.onb_survey_followup` (PNG, `drawable-nodpi`). Ocupa largura máxima, ContentScale = Crop. Formato próximo a 80% da largura.

2. **Bloco de texto** (column abaixo da imagem, padding horizontal 24dp):
   - Título: `"Criado para entregas"` — estilo heading, padding-top 24dp
   - Body: `"O Spoke foi criado para a entrega de pacotes, otimizando o planejamento de rotas longas e a organização de vários pacotes."` — padding-top 16dp

3. **Botão primário** (CTA filled):
   - `"Ainda quero testar o Spoke"` — padding-top 16dp, `fillMaxWidth`.
   - Ação: `onStillWantToTryCircuitClicked` → persiste `OnboardingDisplayedState.Completed` + analytics + navega para tutorial.

4. **Botão secundário** (outline/ghost, texto com cor de destaque/danger):
   - `"Desinstalar app"` — padding-top 8dp, `fillMaxWidth`.
   - Ação: `onDeleteAppClicked` → dispara `Intent("android.intent.action.DELETE", Uri.parse("package:com.underwood.route_optimiser"))` com `FLAG_ACTIVITY_NEW_TASK`. Abre o painel de desinstalação do sistema Android.

### C.5 — Strings PT-BR Verbatim (Follow-Up)

| Chave | String PT-BR |
|-------|-------------|
| `onboardingsurvey_followup_message_title` | `"Criado para entregas"` |
| `onboardingsurvey_followup_message_bodytext` | `"O Spoke foi criado para a entrega de pacotes, otimizando o planejamento de rotas longas e a organização de vários pacotes."` |
| `onboardingsurvey_followup_message_confirmation_button` | `"Ainda quero testar o Spoke"` |
| `onboardingsurvey_followup_message_uninstall_button` | `"Desinstalar app"` |

### C.6 — Estados e Enums

**`OnboardingDisplayedState`** (enum):
- `Started` (ordinal 0) — default. Onboarding ainda não completado.
- `Completed` (ordinal 1) — persiste que o usuário já passou pelo onboarding (qualquer caminho).

**`OnboardingSurveyViewModel` estados de UI** (`C3831b.b`):
- `Survey` — exibe a tela de seleção de perfil (§C.1)
- `FollowUp` — exibe a tela de redirecionamento (§C.4)

**`OnboardingSurveyViewModel` eventos de navegação** (`C3831b.a`):
- `NavigateToTutorial` — navega para a tela de tutorial
- `OpenDeletePackageSettings` — dispara intent de desinstalação
- `Finish` — `requireActivity().finish()` (não é mais chamado pela lógica atual; `NavigateToTutorial` cobre todos os caminhos de saída positiva)

**Estado inicial** (`OnboardingSurveyViewModel`): `OnboardingDisplayedState.Started` é gravado em DataStore assim que a tela é criada (indicando que o onboarding começou). `Completed` só é gravado ao confirmar uma opção.

### C.7 — Ícones (drawable → Lucide equivalente)

| drawable Spoke | Propósito | Observação |
|---------------|-----------|-----------|
| `onboarding_parcel_van.png` | Card PackageDelivery | Ilustração PNG — sem equivalente Lucide; usar `Truck` como fallback |
| `onboarding_scooter.png` | Card OrderDelivery | Ilustração PNG — `Bike` como fallback |
| `onboarding_service_van.png` | Card Services | Ilustração PNG — `Wrench` como fallback |
| `onboarding_sales_car.png` | Card Sales | Ilustração PNG — `Car` como fallback |
| `onb_survey_followup.png` | Imagem follow-up | Ilustração PNG — sem fallback Lucide (imagem decorativa) |

> **Nota ADR-0035:** as ilustrações PNG do Spoke (identidade visual do Spoke) **não devem ser replicadas**. O RotPro usará ilustrações originais com os mesmos propósitos/posicionamentos. O que este blueprint documenta é a **estrutura/posicionamento**, não os assets visuais.

### C.8 — Precisa-runtime

- **Não** — toda a estrutura, fluxo, strings e lógica de estados derivados do dump estático. Nenhum campo `Precisa-runtime`.

---

## Notas de Implementação para RotPro

1. **Pesquisa de Tradução (`TranslationSurvey`):** irrelevante para RotPro (app nativo PT-BR, sem multilíngue). **Omitir**.

2. **Pesquisa de Rota (`RouteSurvey`):** manter comportamento (disparo probabilístico 3.33% pós-rota + cooldown 30 dias + Play In-App Review). Strings dinâmicas virão do backend RotPro (não há SDK externo de analytics como no Spoke).

3. **Onboarding Survey:** a pergunta de perfil identifica o público-alvo. Para RotPro, o equivalente direto de `PackageDelivery` é o público-alvo (entregadores). As outras 4 opções ainda são relevantes pois o comportamento de "não-público-alvo" (mostrar mensagem de follow-up com opção de desinstalar) é funcionalidade B2C valiosa de retenção. **Manter todas as 5 opções** com microcopy adaptado para o contexto RotPro (trocar "Spoke" por "Roteirizador Pro" no body do follow-up).

4. **Intercom surveys:** [B2B — cortar] — SDK não incluído, strings ignoradas.

5. **`OnboardingDisplayedState.Started/Completed`:** persistir em `SharedPreferences` ou `DataStore`. Impede que o onboarding survey seja exibido novamente em sessions posteriores.
