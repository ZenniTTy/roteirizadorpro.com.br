# Front blueprint — onboarding
**Data:** 2026-06-21
**Fonte:** jadx-out de Spoke v3.65.1 (`com.underwood.route_optimiser`)
**Escopo:** fluxo de onboarding pós-login para usuários novos — 3 telas em sequência: Survey → Tutorial → Home.

---

## Visão geral do fluxo

```
[Splash / Login] → onboarding_survey (se OnboardingDisplayedState == Started)
                 → home (se OnboardingDisplayedState == Completed OU usuário já existia)

onboarding_survey → tutorial (ao selecionar qualquer opção)
tutorial          → home (CTA "Começar" / "Vamos lá")
```

**Gate no MainViewModel:** ao autenticar, verifica `OnboardingDisplayedState` salvo em `SavedStateHandle`.
- Se `Started` E usuário não tem rotas: dispara `ShowOnboardingSurvey` → navega para `onboarding_survey`.
- Se `Completed` OU usuário já tem rotas: dispara `ShowHome`.
- Se não autenticado: dispara `ShowLogin`.

O `OnboardingDisplayedState` é marcado como `Completed` em dois momentos:
1. Quando o usuário seleciona **PackageDelivery** na survey e avança.
2. Quando o usuário toca **"Ainda quero testar o Spoke"** no follow-up (non-target group).

---

## Tela 1 — OnboardingSurveyScreen

**Classe:** `com.circuit.ui.onboarding.OnboardingSurveyFragment` + Composable `wpa` (`OnboardingSurveyScreen.kt`)
**Propósito:** Pergunta qual tipo de trabalho o usuário faz, para segmentar target group (entrega de pacotes) vs non-target group.
**Tipo:** Fragment com Composable (Jetpack Compose), fullscreen, sem AppBar.
**Back press:** interceptado — não faz nada (back press desabilitado nessa tela).

### Estrutura (ordem de cima para baixo)

1. **Título** — `"Início rápido"` (`onboardingsurvey_title`)
2. **Subtítulo** — `"Qual opção descreve melhor seu trabalho?"` (`onboardingsurvey_subtitle`)
3. **Lista de opções** — 4 cards ilustrados + 1 texto-puro (ordem fixa, enum index):
   - 0 `PackageDelivery` — card com ilustração `onboarding_parcel_van` · `"Entrega de pacotes"` · subtítulo `"UPS, DHL, FedEx..."`
   - 1 `OrderDelivery` — card com ilustração `onboarding_scooter` · `"Entrega de pedidos"` · subtítulo `"Uber Eats, Deliveroo..."`
   - 2 `Services` — card com ilustração `onboarding_service_van` · `"Serviços"` · subtítulo `"Jardineiro, encanador..."`
   - 3 `Sales` — card com ilustração `onboarding_sales_car` · `"Vendas"` · subtítulo `"Visitas a clientes"`
   - 4 `None` — sem ilustração (drawable = 0), sem subtítulo · `"Nenhuma das opções acima"`
4. **Botão de confirmação** (aparece após seleção, com animação de slide-up + fade):
   - Se `PackageDelivery` selecionado: `"Vamos lá"` (`onboardingsurvey_targetgroup_confirmation_button`)
   - Se qualquer outro selecionado: `"Continuar"` (`onboardingsurvey_nontargetgroup_confirmation_button`)
5. **Texto de confirmação** (aparece apenas quando `PackageDelivery` selecionado, com fade):
   - `"Criamos o app para você!"` (`onboardingsurvey_targetgroup_confirmation_text`)

### Strings PT-BR verbatim

| Chave | Valor |
|---|---|
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
| `onboardingsurvey_targetgroup_confirmation_button` | `"Vamos lá"` |
| `onboardingsurvey_nontargetgroup_confirmation_button` | `"Continuar"` |
| `onboardingsurvey_targetgroup_confirmation_text` | `"Criamos o app para você!"` |

### Estados / enums

```
OnboardingSurveyOption { PackageDelivery(0), OrderDelivery(1), Services(2), Sales(3), None(4) }
```

- Estado inicial: nenhuma opção selecionada; botão de confirmação oculto (alpha=0, translateY=56dp).
- Ao selecionar uma opção: botão aparece com animação; selecionada fica com borda ativa; as demais ficam em alpha=0.6 (exceto `None` que fica alpha=1 e fundo transparente quando é ela selecionada).
- `None` (índice 4): sem drawable, sem subtítulo, sem fundo preenchido no card (apenas borda).

### Navegação

- Toque no botão de confirmação com `PackageDelivery`:
  → Marca `OnboardingDisplayedState = Completed`
  → Navega para `tutorial` (popUpTo `onboarding_survey` inclusive)
- Toque no botão de confirmação com non-target group (1, 2, 3, 4):
  → Não marca Completed ainda
  → Navega para `tutorial` (mesma action `action_tutorial`)
  → Interno: muda estado do ViewModel para `FollowUp` (mostrará `OnboardingFollowUpScreen` no Fragment)

**Nota:** O Fragment usa dois Composables diferentes controlados por estado do ViewModel:
- Estado `Survey`: exibe `wpa` (OnboardingSurveyScreen)
- Estado `FollowUp`: exibe `qpa` (OnboardingFollowUpScreen)

A transição `Survey → FollowUp` acontece ao selecionar uma opção non-target group E confirmar.

### Ícones / drawables

| Drawable | Equivalente Lucide sugerido |
|---|---|
| `onboarding_parcel_van` | imagem PNG customizada (van + caixas) — não substituir por ícone |
| `onboarding_scooter` | imagem PNG customizada (scooter) |
| `onboarding_service_van` | imagem PNG customizada (van de serviço) |
| `onboarding_sales_car` | imagem PNG customizada (carro de vendas) |

Todas as ilustrações existem em variante `drawable-nodpi` e `drawable-night-nodpi`.

### Precisa-runtime

Não. Estrutura, strings e lógica de estado completamente mapeadas pelo dump.

---

## Tela 1b — OnboardingFollowUpScreen (non-target group)

**Classe:** Composable `qpa` (`OnboardingFollowUpScreen.kt`)
**Propósito:** Informa que o Spoke foi criado para entregas de pacotes e oferece escolha entre desinstalar ou continuar testando.
**Quando aparece:** O Fragment `OnboardingSurveyFragment` alterna para esse Composable quando o estado interno é `FollowUp` (após seleção de opção 1–4 e confirmação).
**Tipo:** Fullscreen, sem AppBar, sem botão de back funcional.

### Estrutura (ordem de cima para baixo)

1. **Imagem** — `onb_survey_followup` (PNG, largura máx 480dp, centralizada), disponível em variante night.
2. **Título** — `"Criado para entregas"` (`onboardingsurvey_followup_message_title`)
3. **Corpo** — `"O Spoke foi criado para a entrega de pacotes, otimizando o planejamento de rotas longas e a organização de vários pacotes."` (`onboardingsurvey_followup_message_bodytext`)
4. **Botão primário** — `"Ainda quero testar o Spoke"` (`onboardingsurvey_followup_message_confirmation_button`)
5. **Botão secundário (texto)** — `"Desinstalar app"` (`onboardingsurvey_followup_message_uninstall_button`)

### Strings PT-BR verbatim

| Chave | Valor |
|---|---|
| `onboardingsurvey_followup_message_title` | `"Criado para entregas"` |
| `onboardingsurvey_followup_message_bodytext` | `"O Spoke foi criado para a entrega de pacotes, otimizando o planejamento de rotas longas e a organização de vários pacotes."` |
| `onboardingsurvey_followup_message_confirmation_button` | `"Ainda quero testar o Spoke"` |
| `onboardingsurvey_followup_message_uninstall_button` | `"Desinstalar app"` |

### Navegação

- `"Ainda quero testar o Spoke"`:
  → Marca `OnboardingDisplayedState = Completed`
  → Navega para `tutorial` (action `NavigateToTutorial`)
- `"Desinstalar app"`:
  → Dispara Intent `ACTION_DELETE` com `package:com.underwood.route_optimiser` (abre o diálogo de desinstalação do Android)
  → **[B2B — cortar]** — RotPro NÃO implementa esse botão; remover ou substituir por "Fechar" / "Sair" sem desinstalar.

### Ícones

| Drawable | Equivalente |
|---|---|
| `onb_survey_followup` | imagem PNG (ilustração temática de entregas) — criação original para RotPro |

### Precisa-runtime

Não para estrutura. Sim para verificar o tamanho/proporção exatos da imagem e o espaçamento vertical real.

---

## Tela 2 — TutorialScreen (vídeo de onboarding)

**Classe:** `com.circuit.ui.tutorial.TutorialFragment` (`TutorialFragment.kt`)
**Propósito:** Exibe um vídeo curto de 15 segundos introduzindo o app, com CTA para começar.
**Tipo:** Fragment View-based (XML + VideoView, não Compose). Usa `ConstraintLayout` com `ConstraintSet` animado.
**Back press:** interceptado — não faz nada (back press desabilitado nessa tela).

### Estrutura base (`fragment_tutorial.xml`)

1. **Título** (`@id/title`) — `"Como usar o Spoke"` (`onboarding_video_title`) — `textAppearanceHeadline2`, centralizado, marginTop=32dp
2. **Card de vídeo** (`@id/card`) — `MaterialCardView`, cornerRadius=24dp, clickável, margens 32dp de cada lado (guias `collapsedStartGuideline` e `collapsedEndGuideline` = 64dp dos bordos):
   - `VideoView` (`@id/videoView`) — reproduz o vídeo automaticamente em loop; URI obtido do ViewModel
   - `View` scrim (`@id/scrim`) — sobreposição semitransparente sobre o vídeo; cor `video_view_scrim`; visível enquanto o vídeo está carregando (alpha 0), aparece gradualmente (alpha=0.73, duração=400ms) quando o MediaPlayer está pronto
3. **ImageView ícone** (`@id/videoIcon`) — visível enquanto vídeo NÃO está expandido; mostra ícone animado sobre o card; elevation=10dp
4. **TextView label** (`@id/videoLabel`) — texto sobre o card, centralizado, cor `constants_light_100`, elevation=10dp; visível quando vídeo NÃO está expandido; conteúdo vem do estado (`videoText`)
5. **MaterialButton CTA** (`@id/get_started`) — rodapé, marginBottom=24dp; texto e estado "activated" controlados pelo ViewModel

### Dois `ConstraintSet` (animados com `ConstraintLayout.animateLayoutChanges`)

| Estado | ConstraintSet | Descrição |
|---|---|---|
| Colapsado (`isExpanded=false`) | `set_tutorial_collapsed.xml` | Card ocupa área central (guias 64dp); scrim visível; título e botão visíveis |
| Expandido (`isExpanded=true`) | `set_tutorial_expanded.xml` | Card expande para preencher a tela inteira (guias `component_padding`); título e scrim ficam ocultos |

A transição de colapsado → expandido é animada automaticamente pelo `ConstraintLayout` via `ConstraintSet.applyTo()`.

### Estados / TutorialState (classe `pne`)

| Campo | Tipo | Significado |
|---|---|---|
| `lowerButtonText` (int) | `@StringRes` | Texto do CTA |
| `videoText` (int) | `@StringRes` | Texto exibido sobre o vídeo (label) |
| `videoIcon` (int) | `@DrawableRes` | Ícone exibido sobre o vídeo |
| `isExpanded` (bool) | Boolean | Se o card de vídeo está expandido (fullscreen) |
| `isLowerButtonActivated` (bool) | Boolean | Se o botão está no estado "activated" (cor diferente) |
| `backgroundColor` (u54) | Cor | Preto quando expandido; `lightBackground` quando colapsado |

**Estado inicial:**
```
lowerButtonText = onboarding_video_skip ("Já usei o Spoke antes")
videoText       = onboarding_video_overlay_text ("Conheça o Spoke em 15 segundos")
videoIcon       = R.drawable.play
isExpanded      = false
isLowerButtonActivated = false
```

**Transições de estado:**

1. **Vídeo completa pela primeira vez** (`onCompletion`, `isExpanded=false`):
   → `isExpanded = true` (card vira fullscreen)
   → `lowerButtonText` e outros permanecem iguais

2. **Vídeo completa novamente** (`onCompletion`, `isExpanded=true`):
   → `lowerButtonText = onboarding_video_button` (`"Começar"`)
   → `videoText = onboarding_video_watch_again` (`"Assistir de novo"`)
   → `videoIcon = R.drawable.replay`
   → `isExpanded = false` (volta ao tamanho colapsado)
   → `isLowerButtonActivated = true`

3. **Toque no card** (quando `isExpanded=false`, scrim visível):
   → fade do scrim para alpha=1.0 (duração=80ms)
   → depois `GoHome` (sai do tutorial)

4. **Toque no botão CTA** (`get_started`):
   → chama `TutorialViewModel.m10064J()` → dispara evento `GoHome`
   → navega para `home` (popUpTo `nav_graph` inclusive = limpa backstack completo)

### Strings PT-BR verbatim

| Chave | Valor |
|---|---|
| `onboarding_video_title` | `"Como usar o Spoke"` |
| `onboarding_video_overlay_text` | `"Conheça o Spoke em 15 segundos"` |
| `onboarding_video_skip` | `"Já usei o Spoke antes"` |
| `onboarding_video_button` | `"Começar"` |
| `onboarding_video_watch_again` | `"Assistir de novo"` |

### Ícones / drawables

| Drawable | Quando | Equivalente Lucide sugerido |
|---|---|---|
| `R.drawable.play` | Estado inicial, vídeo não completou | `Play` (Lucide) |
| `R.drawable.replay` | Após vídeo completar 2ª vez | `RotateCcw` (Lucide) |

### Navegação

- Botão CTA ou toque no card → `action_home` → `HomeFragment` (backstack limpo)
- **Não há botão voltar** (interceptado; back press não faz nada)

### Transições de entrada

O Fragment declara `EnterTransition` e usa `postponeEnterTransition(0ms)` para aguardar o VideoView carregar.

### Precisa-runtime

Sim, para:
- Confirmar a URI do vídeo (provavelmente arquivo local no APK ou asset remoto)
- Verificar comportamento visual do scrim overlay + timing exato da animação de expansão
- Observar como o card se comporta em dispositivos com diferentes aspect ratios

---

## Estados e enum centrais

### `OnboardingDisplayedState`
```
enum { Started, Completed }
```
- Persistido em `SavedStateHandle` (chave `rpa.f130540b[0]`).
- `Started` = onboarding ainda não concluído → mostrar survey.
- `Completed` = concluído → ir direto para Home.

### `OnboardingSurveyOption`
```
enum {
  PackageDelivery(0, drawable=onboarding_parcel_van, label=targetgroup_button, subtitle=targetgroup_button_subtitle),
  OrderDelivery  (1, drawable=onboarding_scooter,     label=nontargetgroup1_button, subtitle=nontargetgroup1_button_subtitle),
  Services       (2, drawable=onboarding_service_van, label=nontargetgroup2_button, subtitle=nontargetgroup2_button_subtitle),
  Sales          (3, drawable=onboarding_sales_car,   label=nontargetgroup3_button, subtitle=nontargetgroup3_button_subtitle),
  None           (4, drawable=none,                   label=nontargetgroup4_button, subtitle=none)
}
```

### `ExitedTutorialScreenState` (analytics only)
```
enum { NOT_PLAYED("Not played"), PLAYING("Playing"), FINISHED_PLAYING("Finished playing") }
```
Usado apenas para rastreamento analítico ao sair do tutorial — não afeta UI.

---

## Navegação completa do fluxo

```
Splash (startDestination)
  ├── action_onboarding_survey → onboarding_survey (popUpTo=onboarding_survey, inclusive)
  └── action_home → home (popUpTo=splash, inclusive)

Login
  ├── action_tutorial → tutorial (popUpTo=login, inclusive)
  ├── action_onboarding_survey → onboarding_survey
  └── action_home → home (popUpTo=login, inclusive)

onboarding_survey
  └── action_tutorial → tutorial (popUpTo=onboarding_survey, inclusive)

tutorial
  └── action_home → home (launchSingleTop=true, popUpTo=nav_graph, inclusive)
```

---

## Notas para RotPro (clone B2C)

1. **Manter:** Survey completa (5 opções, order fixa), strings PT-BR verbatim, lógica de estado `OnboardingDisplayedState`, Tutorial com vídeo + CTA, transição survey→tutorial→home.
2. **Adaptar:** Substituir o vídeo do Spoke por vídeo/animação próprio do RotPro. Substituir ilustrações das opções por assets próprios (mesma função semântica). Remover referência a "Spoke" nas strings — será "Roteirizador Pro".
3. **Cortar — [B2B — cortar]:** Botão "Desinstalar app" no FollowUpScreen (Intent ACTION_DELETE). Não existe equivalente válido para RotPro.
4. **Cortar — Apple/Facebook auth** na LoginFragment: por diretiva do cliente Ueslei (ADR-0035 §7.1 locked directives). Não afeta diretamente o onboarding, mas impacta o pré-requisito.
5. **`cluster_feature_onboarding_*`** — strings que aparecem na busca por "onboarding" NÃO pertencem a este fluxo; são tooltips do editor de clusters na tela de rota ativa (Área 8+). Fora do escopo aqui.
