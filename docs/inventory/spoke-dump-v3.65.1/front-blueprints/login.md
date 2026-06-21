# Front blueprint — login

**Data:** 2026-06-21
**Fonte:** `com.circuit.p016ui.login` + `com.circuit.p016ui.onboarding` + `com.circuit.p016ui.tutorial` (jadx ofuscado via Pairip)
**Classe principal:** `LoginFragment` + `LoginViewModel` + `LoginState (C3794g)` + `LoginScreen (AbstractC3793f)` + `LoginEvent (AbstractC3788a)`
**Layout raiz:** `R.layout.fragment_login` — FrameLayout com três camadas sobrepostas

---

## Visão geral do fluxo

```
Splash ──action_login──► LoginFragment (tela intro)
                              │
            ┌─────────────────┼──────────────────┐
            ▼                 ▼                  ▼
       Google Sign-In   Continuar c/ e-mail  Continuar c/ telefone
       (direto)            │                     │
                     ┌─────┤                 EnterPhone ──► PhoneVerification
                     ▼     ▼
                EnterEmail → EmailLogin (senha) ou EmailSignUp (cadastro)
                                    │
                             handleSuccessfulLogin
                                    │
              ┌─────────────────────┤
              ▼                     ▼
       OpenHome (usuário         OpenOnboardingSurvey (novo usuário,
       existente)                primeira vez)
```

**Nota:** Apple Sign-In existe no Spoke original mas é **[B2B — cortar]** para RotPro (ADR-0035 + diretriz do cliente: sem Apple auth). Google Sign-In permanece. Login anônimo (botão `login_anonymous_button`) está **sempre `GONE`** na v3.65.1 — hard-coded no Fragment.

---

## Tela 1 — Intro / Seleção de método (LoginScreen.Intro)

**Classe LoginScreen:** `AbstractC3793f.f` (o valor `f32049k = true` → `intro_screen` visível)
**Propósito:** Primeira tela do app não-autenticado. Apresenta o produto e oferece os métodos de login.

### Estrutura (ordem na tela, de cima para baixo)

| Elemento | ID | Tipo | Conteúdo / comportamento |
|---|---|---|---|
| Imagem de fundo | `login_background` | ImageView | `@drawable/il_welcome_bg`, scaleType=centerCrop. Alpha = 1.0f (normal) ou 0.3f quando `loading=true`. |
| Logo / hero | `login_hero` | ImageView | `@drawable/login_brand_logo`, 28dp de altura, centrado, marginTop=80dp. |
| Descrição | `intro_description` | TextView | Texto dinâmico via `LoginState.description`. Default = `""`. Visível quando `login_default_group` está ativo. Estilo `textAppearanceHeadingHeavy`, textAlignment=center, maxLines=2, altura fixa=96dp. |
| Botão Google | `login_google_button` | MaterialButton (style `Button.Login`) | Texto: "Continuar com Google". Ícone: `@drawable/google_login` (iconGravity=textStart). marginStart/End=32dp. |
| Botão Apple | `login_apple_button` | MaterialButton (style `Button.Login`) | Texto: "Continuar com Apple". Ícone: `@drawable/apple_login`. **[B2B — cortar]** Spoke inclui; RotPro exclui por diretriz do cliente. |
| Botão E-mail | `login_email_button` | MaterialButton (style `Button.Login`) | Texto: "Continuar com e-mail". Ícone: `@drawable/mail` (iconGravity=textStart). |
| Botão Telefone | `login_phone_button` | MaterialButton (`materialButtonTextStyle`) | Texto: "Continuar com telefone". Sem ícone. Posicionado à esquerda do barrier, com marginEnd=8dp ao barrier. |
| Botão Anônimo | `login_anonymous_button` | MaterialButton (`materialButtonTextStyle`) | Texto: "Pular". Ícone: `@drawable/chevron_right` (iconGravity=textEnd). **Sempre `visibility=GONE`** (hard-coded no Fragment — não renderizado). |
| Disclaimer legal | `login_legal_disclaimer` | TextView | Texto: "Ao continuar, você concorda com a %1$s e os %2$s do Spoke" — formatado com SpannableString onde %1$s = "Política de privacidade" (link → `https://spoke.com/privacy`) e %2$s = "Termos de uso" (link → `https://spoke.com/terms`). Estilo `textAppearanceLabelDefault`, textAlignment=center, maxWidth=250dp, marginBottom=`@dimen/padding`. Cor do texto: `constants_light_70`, link: `constants_light_100`. |

### Grupo "login_reason" (modo alternativo)

Aparece quando `loading=true` no estado intro (`AbstractC3793f.f(loading=true)`) — obscurece os botões e exibe o motivo de login.

| Elemento | ID | Conteúdo |
|---|---|---|
| Ícone nuvem | `login_reason_icon` | `@drawable/baseline_cloud_queue_24`, tint=`constants_light_100`, altura=50dp. |
| Título | `login_reason_title` | "Por que preciso fazer login?" |
| Parágrafo 1 | `login_reason_info_1` | "O Spoke sincroniza automaticamente suas rotas e andamento nos outros dispositivos em que você fez login. Assim, você sempre terá um back-up para nunca perder uma rota." |
| Parágrafo 2 | `login_reason_info_2` | "Não vendemos seus dados a terceiros." |

### Strings PT-BR verbatim (Tela Intro)

```
gauth_button_title          → "Continuar com Google"
apple_signin_button_title   → "Continuar com Apple"
email_auth_button_title     → "Continuar com e-mail"
teams_secondary_button_title → "Continuar com telefone"
skip                        → "Pular"
login_disclaimer_text       → "Ao continuar, você concorda com a %1$s e os %2$s do Spoke"
privacy_policy_title        → "Política de privacidade"
tos_title                   → "Termos de uso"
login_reason_title          → "Por que preciso fazer login?"
login_reason_description    → "O Spoke sincroniza automaticamente suas rotas e andamento nos outros dispositivos em que você fez login. Assim, você sempre terá um back-up para nunca perder uma rota."
login_reason_description_extra → "Não vendemos seus dados a terceiros."
intro_large_title           → "Planejador de várias paradas para entregadores"
intro_session_expired_title → "Sessão expirada. Entre novamente."
```

### Navegação

- Toque em "Continuar com Google" → `onContinueWithGoogleClick` → autenticação direta → `handleSuccessfulLogin`
- Toque em "Continuar com e-mail" → troca para `LoginScreen.EnterEmail`
- Toque em "Continuar com telefone" → troca para `LoginScreen.EnterPhone`
- Back press na Intro → consumido (não navega para fora)

### Estados / defaults

- Estado inicial: `LoginState(description="", loading=false, screen=Intro, errorInput=null)`
- Sessão expirada: description = "Sessão expirada. Entre novamente."
- `loading=true` durante auth via Google: fundo escurece (alpha=0.3f), `login_reason_group` aparece

### Precisa-runtime

- Transição visual entre Intro e EnterEmail (animação de crossfade/slide)
- Comportamento exato da barra de sistema (DefaultSystemBarStylist, tema `ThemeOverlay.LoginIntro`)

---

## Tela 2 — Digite o e-mail (LoginScreen.EnterEmail)

**Classe:** `AbstractC3793f.d` (singleton `d.f32054m`)
**Propósito:** Coletar o endereço de e-mail. O sistema decide se o usuário existe ou não após o submit.

### Estrutura (`email_login_screen` — NestedScrollView)

| Elemento | ID | Tipo | Conteúdo |
|---|---|---|---|
| Logo | `logo` | ImageView | `@drawable/logo_nobg`, 72×72dp, marginTop=48dp. Visível apenas se `R.bool.show_login_input_logo = true`. |
| Espaçador | `login_title_top` | Space | marginTop=16dp (goneMarginTop=60dp quando logo ausente). |
| Subtítulo | `input_subtitle` | TextView | Oculto (`GONE`) neste estado (sem subtítulo). |
| Título | `input_title` | TextView | "Digite seu endereço de e-mail para continuar". Estilo `textAppearanceHeadline2`. |
| Campo | `input` | TogglePasswordEditText | Hint: "endereço de e-mail". inputType=`TYPE_TEXT_VARIATION_EMAIL_ADDRESS` (33). imeOptions=actionDone. `toggleEnabled=false` (olho de senha oculto). textDirection=anyRtl, textAlignment=viewStart. |
| Progresso | `progress` | ContentLoadingProgressBar | INVISIBLE por padrão; VISIBLE quando `loading=true`. Posicionado sobreposto ao fim do campo. |
| Erro | `input_error` | TextView | GONE por padrão; VISIBLE quando `errorInput != null`. Cor `fgCriticalEmphasis`, textAlignment=center. |
| Botão principal | `continue_button` | MaterialButton | Texto: "Continuar". Submit do e-mail. |
| Ação secundária | `input_secondary_action` | MaterialButton (`materialButtonTextStyle`) | Texto: "Entrar com o Google em um toque". Visível apenas neste estado (IconResource `R.integer.gauth_button_on_email_title` presente → `num2 != null`). |

### Strings PT-BR verbatim (EnterEmail)

```
enter_your_email_address_to_continue → "Digite seu endereço de e-mail para continuar"
sign_in_email_address_placeholder    → "endereço de e-mail"
continue_button_title                → "Continuar"
gauth_button_on_email_title          → "Entrar com o Google em um toque"
```

### Navegação

- Toque em "Continuar" (ou tecla Enter / IME actionDone) → `enteredEmailAddress(email)`
  - Se e-mail inválido → `errorInput = R.string.invalid_email_error`
  - Se e-mail existe com senha → troca para `LoginScreen.EmailLogin(email)`
  - Se e-mail existe com Google → inicia `onContinueWithGoogleClick`
  - Se e-mail existe com Apple → inicia `onContinueWithAppleClick` (**[B2B — cortar]**)
  - Se e-mail novo → troca para `LoginScreen.EmailSignUp(email)`
- Toque em "Entrar com o Google em um toque" → `onContinueWithGoogleClick`
- Teclado aparece automaticamente quando `email_login_screen` fica visível (`f32044f = true` → `requestFocus + showSoftInput`)

### Estados / defaults

- inputType = 33 (`TYPE_CLASS_TEXT | TYPE_TEXT_VARIATION_EMAIL_ADDRESS`)
- Ao trocar de tela, o campo é limpo (`.setText("")` no observer de screen)

### Erros

```
invalid_email_error → "Seu e-mail é inválido. Verifique e tente novamente."
generic_error       → "Algo deu errado. Tente novamente."
```

### Precisa-runtime

- Animação/transição de retorno da EnterEmail para Intro (back press)

---

## Tela 3 — Insira sua senha (LoginScreen.EmailLogin)

**Classe:** `AbstractC3793f.b(email: String)`
**Propósito:** Usuário existente com senha. Autentica via email+senha.

### Estrutura (reutiliza `email_login_screen`)

| Elemento | ID | Conteúdo |
|---|---|---|
| Subtítulo | `input_subtitle` | E-mail do usuário (a string `email` passada como `subtitle`). VISIBLE. |
| Título | `input_title` | "Insira sua senha". |
| Campo | `input` | TogglePasswordEditText. Hint: "senha". inputType=`TYPE_CLASS_TEXT | TYPE_TEXT_VARIATION_PASSWORD` (129 — campo senha com toggle de visibilidade). `toggleEnabled=true`. |
| Botão principal | `continue_button` | Texto: "Entrar". |
| Ação secundária | `input_secondary_action` | Texto: "Esqueceu a senha?". VISIBLE. |

### Strings PT-BR verbatim (EmailLogin)

```
enter_password_title          → "Insira sua senha"
sign_in_password_placeholder  → "senha"
sign_in_button_title          → "Entrar"
forgot_password_title         → "Esqueceu a senha?"
```

### Navegação

- Toque em "Entrar" → `enteredPassword(password)` → `authenticate` → `handleSuccessfulLogin`
- Toque em "Esqueceu a senha?" → emite evento `ShowForgotPassword(email)` → exibe diálogo de redefinição
- Back press → volta para EnterEmail

### Erros

```
invalid_password_error → "A senha inserida está incorreta. Verifique e tente novamente."
generic_error          → "Algo deu errado. Tente novamente."
```

### Precisa-runtime

- Toggle de visibilidade da senha (componente `TogglePasswordEditText` — comportamento do olho)

---

## Tela 4 — Defina sua senha (LoginScreen.EmailSignUp)

**Classe:** `AbstractC3793f.c(email: String)`
**Propósito:** Novo usuário. Define a senha para criar a conta.

### Estrutura (reutiliza `email_login_screen`)

| Elemento | ID | Conteúdo |
|---|---|---|
| Subtítulo | `input_subtitle` | E-mail do usuário. VISIBLE. |
| Título | `input_title` | "Defina sua senha". |
| Campo | `input` | inputType=129 (senha), `toggleEnabled=true`, hint="senha". |
| Botão principal | `continue_button` | Texto: "Cadastrar-se". |
| Ação secundária | `input_secondary_action` | GONE (sem ação secundária no sign-up). |

### Strings PT-BR verbatim (EmailSignUp)

```
password_title         → "Defina sua senha"
sign_up_button_title   → "Cadastrar-se"
```

### Erros

```
weak_password_error → "Senha muito curta. Ela precisa ter pelo menos 6 caracteres."
generic_error       → "Algo deu errado. Tente novamente."
```

---

## Tela 5 — Digite o número de telefone (LoginScreen.EnterPhone)

**Classe:** `AbstractC3793f.e` (singleton `e.f32055m`)
**Propósito:** Método alternativo de login via SMS OTP.

### Estrutura (reutiliza `email_login_screen`)

| Elemento | ID | Conteúdo |
|---|---|---|
| Subtítulo | `input_subtitle` | GONE. |
| Título | `input_title` | "Digite seu número de telefone para continuar". |
| Campo | `input` | inputType=`TYPE_CLASS_PHONE` (3). `toggleEnabled=false`. Hint: "número de telefone". |
| Botão principal | `continue_button` | Texto: "Continuar". |
| Ação secundária | `input_secondary_action` | GONE. |

### Strings PT-BR verbatim (EnterPhone)

```
enter_your_phone_number_to_continue → "Digite seu número de telefone para continuar"
sign_in_phone_number_placeholder    → "número de telefone"
continue_button_title               → "Continuar"
```

### Erros

```
invalid_phone_error      → "O telefone inserido é inválido. Tente adicionar o código do país e de área."
login_phone_generic_error → "Algo deu errado. Se você tentar novamente e não funcionar, experimente com outro dispositivo, conexão de rede ou e-mail."
too_many_login_requests  → "Este dispositivo fez muitas solicitações de login. Tente de novo mais tarde"
```

### Navegação

- Toque em "Continuar" → `enteredPhoneNumber(phone)` → aguarda SMS → troca para `LoginScreen.PhoneVerification(phone)`

---

## Tela 6 — Insira o código de verificação (LoginScreen.PhoneVerification)

**Classe:** `AbstractC3793f.g(phoneNumber: String)`
**Propósito:** Confirmar OTP recebido via SMS.

### Estrutura (reutiliza `email_login_screen`)

| Elemento | ID | Conteúdo |
|---|---|---|
| Subtítulo | `input_subtitle` | Número de telefone formatado. VISIBLE. |
| Título | `input_title` | "Insira o código de verificação". |
| Campo | `input` | inputType=`TYPE_CLASS_NUMBER` (2). `toggleEnabled=false`. Hint: "código de verificação". |
| Botão principal | `continue_button` | Texto: "Entrar". |
| Ação secundária | `input_secondary_action` | GONE. |

### Strings PT-BR verbatim (PhoneVerification)

```
code_label_title                   → "Insira o código de verificação"
sign_in_verification_code_placeholder → "código de verificação"
sign_in_button_title               → "Entrar"
```

### Erros

```
invalid_validation_code_error → "O código de validação inserido está incorreto. Verifique e tente novamente."
```

---

## Tela 7 — Finish Setup / Autofill confirmado (LoginScreen.AutofillConfirmed)

**Classe:** `AbstractC3793f.a(install: DeepLinkAction.Install)`
**Propósito:** Detectado deep-link de instalação com e-mail ou telefone pré-preenchido (link de convite). Confirma a conta sugerida.

**Visibilidade:** `finish_setup_screen` (ConstraintLayout separado, fora do NestedScrollView).

### Estrutura (`finish_setup_screen`)

| Elemento | ID | Tipo | Conteúdo |
|---|---|---|---|
| Título | `finish_setup_title` | ShrinkBeforeBreakTextView | "Entrar com %1$s?" onde %1$s = e-mail ou telefone do deep-link. Estilo `textAppearanceHeadline2`, marginTop=100dp. |
| Botão primário | `finish_primary_button` | LoadingMaterialButton | Texto: "Entrar" (ou o texto do estado). Possui estado `loading`. |
| Botão secundário | `finish_secondary_button` | MaterialButton (`materialButtonOutlinedStyle`) | Texto: "Usar outra conta". |

### Strings PT-BR verbatim (AutofillConfirmed)

```
login_sign_up_with_x           → "Entrar com %1$s?"
login_button_use_another_account → "Usar outra conta"
sign_in_button_title           → "Entrar"
```

### Navegação

- Toque no botão primário → `autofillConfirmed(install)` → `handleSuccessfulLogin`
- Toque em "Usar outra conta" → volta para Intro (`LoginScreen.Intro`)

---

## Diálogo — Esqueceu a senha?

**Classe:** `DialogC2609l0` (diálogo simples de confirmação, componente `com.circuit.components.dialog`)
**Acionado por:** evento `LoginEvent.ShowForgotPassword(email)` emitido pelo `LoginViewModel`

### Estrutura

| Elemento | Conteúdo |
|---|---|
| Título | "Quer redefinir a senha de %1$s?" (email substituído) |
| Corpo (implícito) | "Se você esqueceu a senha da sua conta, podemos enviar um e-mail de redefinição de senha." |
| Botão positivo | "Redefinir senha" → chama `onForgotPasswordClick` → envia e-mail e exibe Snackbar |
| Botão negativo (implícito) | Fechar / Cancelar |

### Toast/Snackbar após confirmação

```
reset_password_confirmation → "Enviamos um e-mail com as instruções para redefinir a senha de %1$s"
```

### Strings PT-BR verbatim (Forgot Password)

```
recover_password             → "Quer redefinir a senha de %1$s?"
reset_password_description   → "Se você esqueceu a senha da sua conta, podemos enviar um e-mail de redefinição de senha."
reset_password_action        → "Redefinir senha"
reset_password_confirmation  → "Enviamos um e-mail com as instruções para redefinir a senha de %1$s"
```

---

## Tela pós-login 1 — Pesquisa de perfil (OnboardingSurvey)

**Classe:** `OnboardingSurveyFragment` + `OnboardingSurveyViewModel (C3831b)` — Compose UI
**Quando aparece:** Apenas na primeira autenticação (`isNewUser = true` via `f31953v1.f25983b`) → evento `OpenOnboardingSurvey`
**Layout:** Compose (sem XML de layout — renderizado via `ComposeView`)

### Estrutura (ordem visual)

1. **Título:** "Início rápido"
2. **Subtítulo:** "Qual opção descreve melhor seu trabalho?"
3. **Opções (cards verticais):**

| Enum | Ícone | Título | Subtítulo |
|---|---|---|---|
| `PackageDelivery` | `onboarding_parcel_van` | "Entrega de pacotes" | "UPS, DHL, FedEx..." |
| `OrderDelivery` | `onboarding_scooter` | "Entrega de pedidos" | "Uber Eats, Deliveroo..." |
| `Services` | `onboarding_service_van` | "Serviços" | "Jardineiro, encanador..." |
| `Sales` | `onboarding_sales_car` | "Vendas" | "Visitas a clientes" |
| `None` | — (sem ícone) | "Nenhuma das opções acima" | — |

4. **Após seleção de `PackageDelivery`:**
   - Exibe mensagem: título "Criados o app para você!", botão "Vamos lá" → avança para Tutorial
5. **Após seleção de qualquer não-alvo (`OrderDelivery`/`Services`/`Sales`/`None`):**
   - Exibe bottom sheet ou tela de confirmação com: título "Criado para entregas", corpo "O Spoke foi criado para a entrega de pacotes, otimizando o planejamento de rotas longas e a organização de vários pacotes.", botão "Ainda quero testar o Spoke" (→ avança), botão "Desinstalar app" (→ abre loja/desinstala)
   - Botão de continuar: "Continuar"

### Strings PT-BR verbatim (OnboardingSurvey)

```
onboardingsurvey_title                        → "Início rápido"
onboardingsurvey_subtitle                     → "Qual opção descreve melhor seu trabalho?"
onboardingsurvey_targetgroup_button           → "Entrega de pacotes"
onboardingsurvey_targetgroup_button_subtitle  → "UPS, DHL, FedEx..."
onboardingsurvey_nontargetgroup1_button       → "Entrega de pedidos"
onboardingsurvey_nontargetgroup1_button_subtitle → "Uber Eats, Deliveroo..."
onboardingsurvey_nontargetgroup2_button       → "Serviços"
onboardingsurvey_nontargetgroup2_button_subtitle → "Jardineiro, encanador..."
onboardingsurvey_nontargetgroup3_button       → "Vendas"
onboardingsurvey_nontargetgroup3_button_subtitle → "Visitas a clientes"
onboardingsurvey_nontargetgroup4_button       → "Nenhuma das opções acima"
onboardingsurvey_targetgroup_confirmation_text   → "Criados o app para você!"
onboardingsurvey_targetgroup_confirmation_button → "Vamos lá"
onboardingsurvey_nontargetgroup_confirmation_button → "Continuar"
onboardingsurvey_followup_message_title       → "Criado para entregas"
onboardingsurvey_followup_message_bodytext    → "O Spoke foi criado para a entrega de pacotes, otimizando o planejamento de rotas longas e a organização de vários pacotes."
onboardingsurvey_followup_message_confirmation_button → "Ainda quero testar o Spoke"
onboardingsurvey_followup_message_uninstall_button   → "Desinstalar app"
```

### Navegação

- `PackageDelivery` selecionado → confirmação inline → `action_tutorial` → Tutorial
- Qualquer não-alvo → follow-up → "Ainda quero testar" → `action_tutorial` → Tutorial
- "Desinstalar app" → intenção de desinstalação (fora do fluxo principal)

### Precisa-runtime

- Layout exato dos cards (Compose — não visível no XML)
- Animação de confirmação após seleção
- Ordem dos botões follow-up (primário vs outlined)

---

## Tela pós-login 2 — Tutorial / Vídeo (TutorialFragment)

**Classe:** `TutorialFragment` — Fragment com layout XML
**Quando aparece:** Após OnboardingSurvey (`action_tutorial`) ou diretamente (action de login se já passou survey)
**Layout:** `R.layout.fragment_tutorial`

### Estrutura

| Elemento | ID | Conteúdo |
|---|---|---|
| Título | `title` | "Como usar o Spoke". Estilo `textAppearanceHeadline2`, textAlignment=center, marginTop=32dp. |
| Card de vídeo | `card` | MaterialCardView, cornerRadius=24dp, margem de 64dp lateral (guidelines). Contém VideoView + scrim escuro. |
| Ícone de play | `videoIcon` | ImageView sobre o card (elevation=10dp), centralizado. |
| Label do vídeo | `videoLabel` | "Conheça o Spoke em 15 segundos". Cor `constants_light_100`, elevation=10dp. |
| Botão inferior | `get_started` | MaterialButton (`materialButtonTextStyle`). Texto: "Começar" (ou "Assistir de novo" após assistir). |
| Botão "pular" | (implícito — visível programaticamente) | "Já usei o Spoke antes". Oculto até assistir ou pelo estado. |

### Strings PT-BR verbatim (Tutorial)

```
onboarding_video_title        → "Como usar o Spoke"
onboarding_video_overlay_text → "Conheça o Spoke em 15 segundos"
onboarding_video_button       → "Começar"
onboarding_video_watch_again  → "Assistir de novo"
onboarding_video_skip         → "Já usei o Spoke antes"
```

### Navegação

- "Começar" → inicia vídeo (muda texto para "Assistir de novo")
- Após vídeo ou "Já usei o Spoke antes" → `action_home` (navega para Home, popUpTo nav_graph inclusive)

### Precisa-runtime

- URL/recurso do vídeo (não exposta no jadx — provavelmente Firebase Remote Config)
- Exatamente quando o botão "skip" se torna visível

---

## Enum — SignInType

```kotlin
enum class SignInType {
    GOOGLE,          // 0
    EMAIL_PASSWORD,  // 1
    APPLE,           // 2  [B2B — cortar para RotPro]
    PHONE,           // 3
    ANONYMOUS        // 4  [nunca exposto na UI v3.65.1]
}
```

---

## Eventos de navegação (LoginEvent / AbstractC3788a)

| Evento | Ação no Fragment |
|---|---|
| `HideKeyboard` | `InputMethodManager.hideSoftInputFromWindow` |
| `OpenHome` | `navigate(R.id.action_home)` — popUpTo login inclusive (usuário existente) |
| `OpenOnboardingSurvey` | `navigate(R.id.action_onboarding_survey)` — novo usuário |
| `LaunchIntent(intent)` | `startActivity(intent)` — usado pelo Apple Sign-In (WebView OAuth) |
| `ShowForgotPassword(email)` | Exibe `DialogC2609l0` com confirmação de redefinição |
| `Toast(res)` | Snackbar/Toast com string de recurso (`generic_error` por default em falhas) |

---

## Lógica de roteamento pós-login (handleSuccessfulLogin)

```
handleSuccessfulLogin:
  1. Registra analytics + atualiza timestamp de sessão
  2. Aguarda mobVar.mo9079a() → string de equipe (B2B Dispatch)
     → se string não-null: [B2B — cortar] (TeamSwitcher)
  3. Verifica f31953v1.f25983b (flag "novo usuário"):
     → false → emit OpenHome (usuário existente)
     → true  → emit OpenOnboardingSurvey (primeira vez)
  Em erro:
     → emit Toast(generic_error) + limpa loading + re-habilita UI (m9813K)
```

---

## Mapeamento de ícones (drawable → Lucide)

| drawable Spoke | Equivalente Lucide sugerido | Uso |
|---|---|---|
| `google_login` | — (logo Google — usar asset original) | Botão Google |
| `apple_login` | — (logo Apple) | **[B2B — cortar]** |
| `mail` | `Mail` (Lucide) | Botão e-mail |
| `chevron_right` | `ChevronRight` (Lucide) | Botão anônimo (nunca visível) |
| `baseline_cloud_queue_24` | `Cloud` (Lucide) | Seção "Por que fazer login?" |
| `login_brand_logo` | Logo RotPro original | Hero da tela intro |
| `logo_nobg` | Logo RotPro (sem fundo) | Topo do input screen |
| `il_welcome_bg` | Imagem de fundo RotPro original | Fundo da tela intro |

---

## Notas de implementação para RotPro

1. **Apple Sign-In não implementar** — diretriz do cliente (ADR-0035). O botão `login_apple_button` não deve existir.
2. **Anonymous login não implementar** — hard-coded `GONE` no Spoke; para RotPro omitir completamente.
3. **O campo `input` é sempre um único EditText reutilizado** — não são telas separadas, é o mesmo Fragment com sub-estados controlados por `LoginScreen`. Implementar como um único widget/tela Flutter com state machine.
4. **Transição entre intro e input screens:** a intro fica `VISIBLE` e a `email_login_screen` fica `INVISIBLE` (não GONE) no início — reserva espaço para transição suave.
5. **Teclado auto-focus:** quando `email_login_screen` fica visível (`f32044f = true`), o Fragment chama `requestFocus + showSoftInput` automaticamente.
6. **IME actionDone:** Enter no teclado físico (`KEYCODE_ENTER`, keyCode=66) e IME action "Done" (actionId=6) ambos disparam submit (`m9810m()`).
7. **Deep-link de instalação:** `AutofillConfirmed` é ativado por `DeepLinkAction.Install` — cobre tanto `Install.Email` quanto `Install.Phone`. Não é um fluxo de cadastro padrão.
8. **OnboardingSurvey é Compose** — não tem XML de layout; requer runtime para verificar layout exato dos cards e animações.
9. **Fluxo B2B TeamSwitcher** (`joined_team_switcher_*`) — presente no jadx mas é **[B2B — cortar]** para RotPro.

---

## Campos Precisa-runtime consolidados

| Item | Motivo |
|---|---|
| Animação de transição intro → input | Não é XML, é transition do Fragment (`MaterialFadeThrough`) |
| Comportamento exact do `TogglePasswordEditText` | Componente custom da biblioteca interna Spoke |
| Layout exato do OnboardingSurvey | UI em Compose — não acessível via XML |
| URL/fonte do vídeo no Tutorial | Provavelmente Remote Config — não exposto no APK |
| Tema `ThemeOverlay.LoginIntro` (cores da intro) | Não drillado neste blueprint |
