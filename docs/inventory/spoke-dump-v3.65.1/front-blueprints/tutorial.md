# Front blueprint — tutorial
Data: 2026-06-21
Fonte: `com/circuit/p016ui/tutorial/` + `com/circuit/p016ui/onboarding/` — dump estático Spoke v3.65.1
Escopo: fluxo pós-login inicial (survey de perfil → vídeo tutorial).

---

## Visão geral do fluxo

O fluxo de tutorial ocorre UMA ÚNICA VEZ, imediatamente após o primeiro login bem-sucedido. É composto por duas telas em sequência:

```
Login
  └─ action_tutorial → OnboardingSurvey (obrigatório, pula p/ tutorial apenas para targetgroup)
                           ├─ PackageDelivery → TutorialFragment (vídeo)
                           │                        └─ action_home → Home
                           ├─ OrderDelivery / Services / Sales / None → follow-up (redirect)
                           │       └─ action_tutorial → TutorialFragment OU finish/uninstall
                           └─ (back desabilitado — OnBackPressedDispatcher sem ação)
```

Nav graph: `res/navigation/nav_main.xml`
- `login → action_tutorial → tutorial` (popUpTo login, inclusive)
- `onboarding_survey → action_tutorial → tutorial` (popUpTo survey, inclusive)
- `tutorial → action_home → home` (launchSingleTop, popUpTo nav_graph)

---

## Tela 1 — OnboardingSurvey

**Propósito:** Classificar o perfil do usuário antes de exibir o tutorial. Determina se o Spoke é adequado para o seu caso de uso.

**Classe:** `com.circuit.ui.onboarding.OnboardingSurveyFragment` (Fragment com Compose body via `eh4` — ComposeView wrapper)
**ViewModel:** `OnboardingSurveyViewModel` (`com.circuit.ui.onboarding.b`)
**Arquivo Compose:** `OnboardingSurveyScreen.kt` (decompilado em `p000/wpa.java`)

### Estados da tela (enum `OnboardingSurveyViewModel.b` — UI state)

| Estado | toString | Conteúdo exibido |
|---|---|---|
| `Survey` | "Survey" | Tela de seleção de perfil (inicial) |
| `FollowUp` | "FollowUp" | Tela de acompanhamento (para perfis não-alvo) |

### Estado de exibição (enum `OnboardingDisplayedState`)

| Valor | toString |
|---|---|
| `Started` | "Started" |
| `Completed` | "Completed" |

### Estado Survey — estrutura de layout

**Título:** "Início rápido" (`onboardingsurvey_title`)
**Subtítulo:** "Qual opção descreve melhor seu trabalho?" (`onboardingsurvey_subtitle`)

**Cards de opção (enum `OnboardingSurveyOption`)** — exibidos verticalmente, um por linha, com ícone ilustrativo à esquerda:

| Enum | Drawable | Label (PT-BR verbatim) | Sublabel (PT-BR verbatim) |
|---|---|---|---|
| `PackageDelivery` | `onboarding_parcel_van` | "Entrega de pacotes" | "UPS, DHL, FedEx..." |
| `OrderDelivery` | `onboarding_scooter` | "Entrega de pedidos" | "Uber Eats, Deliveroo..." |
| `Services` | `onboarding_service_van` | "Serviços" | "Jardineiro, encanador..." |
| `Sales` | `onboarding_sales_car` | "Vendas" | "Visitas a clientes" |
| `None` | sem drawable (0) | "Nenhuma das opções acima" | sem sublabel |

**Comportamento dos cards:** cada card possui borda animada (sem borda quando `selectedOption == null`; borda primária quando selecionado; borda secundária/neutra quando outro está selecionado). Alpha do card: `1.0f` quando selecionado ou nulo; `0.6f` quando outro está selecionado. `None` tem fundo colorido quando selecionado; os demais também têm fundo colorido quando selecionados.

**Texto de confirmação** (aparece com alpha animado após seleção de `PackageDelivery`):
- "Criamos o app para você!" (`onboardingsurvey_targetgroup_confirmation_text`) — visível apenas quando `PackageDelivery` selecionado

**Botão de confirmação** (aparece após qualquer seleção — traduz Y de offset 56dp → 0dp animado):
- Se `PackageDelivery`: texto "Vamos lá" (`onboardingsurvey_targetgroup_confirmation_button`)
- Outros: texto "Continuar" (`onboardingsurvey_nontargetgroup_confirmation_button`)

**Navegação ao confirmar:**
- `PackageDelivery` → `action_tutorial` → `TutorialFragment`
- Qualquer outro → abre estado `FollowUp`

### Estado FollowUp — estrutura de layout

Exibido quando o usuário selecionou um perfil não-alvo (OrderDelivery, Services, Sales, None) e confirmou.

**Título:** "Criado para entregas" (`onboardingsurvey_followup_message_title`)
**Corpo:** "O Spoke foi criado para a entrega de pacotes, otimizando o planejamento de rotas longas e a organização de vários pacotes." (`onboardingsurvey_followup_message_bodytext`)

**Botões (dois):**
1. "Ainda quero testar o Spoke" (`onboardingsurvey_followup_message_confirmation_button`) → navega para `TutorialFragment` (`action_tutorial`)
2. "Desinstalar app" (`onboardingsurvey_followup_message_uninstall_button`) → dispara `Intent("android.intent.action.DELETE", "package:com.underwood.route_optimiser")` com flag `FLAG_ACTIVITY_NEW_TASK`

**Evento de navegação (sealed class `OnboardingSurveyViewModel.a`):**
- `NavigateToTutorial` → `action_tutorial`
- `OpenDeletePackageSettings` → Intent de desinstalação
- `Finish` → `requireActivity().finish()`

### Comportamento de back

`OnBackPressedDispatcher` registrado mas sem ação real na survey — back não faz nada (usuário não pode sair da tela sem selecionar).

### Analytics

- `DriverEvents.C2435x0.f21380k1` — "Onboarding survey shown" (disparado no ViewModel init)

### Precisa-runtime

- Animações de transição Survey → FollowUp (Compose AnimatedContent ou similar)
- Comportamento exato do botão "Desinstalar app" em Android 12+ (pode abrir configurações do app em vez de uninstall direto)

---

## Tela 2 — TutorialFragment (Vídeo Tutorial)

**Propósito:** Exibir um vídeo de 15 segundos ("Conheça o Spoke em 15 segundos") para apresentar o app ao usuário. É a última tela antes do Home.

**Classe:** `com.circuit.ui.tutorial.TutorialFragment` (Fragment, View-based — não Compose)
**ViewModel:** `TutorialViewModel` (`com.circuit.ui.tutorial.TutorialViewModel`)
**Layout raiz:** `res/layout/fragment_tutorial.xml` — `ConstraintLayout` (`@id/container`)
**Transições:** `setEnterTransition` customizado com delay 0ms; exit + reenter transitions também configurados

### TutorialState (classe `pne`)

| Campo | Tipo | Descrição | Default inicial |
|---|---|---|---|
| `lowerButtonText` | `@StringRes Int` | Texto do botão inferior | `R.string.onboarding_video_skip` |
| `videoText` | `@StringRes Int` | Texto do label sobre o vídeo (colapsado) | `R.string.onboarding_video_overlay_text` |
| `videoIcon` | `@DrawableRes Int` | Ícone exibido sobre o vídeo (colapsado) | `R.drawable.play` |
| `isExpanded` | `Boolean` | Se o vídeo está em modo expandido (tocando em tela cheia) | `false` |
| `isLowerButtonActivated` | `Boolean` | Se o botão inferior está ativado (estilo diferente) | `false` |
| `background` | `u54` (cor) | Fundo da tela: preto quando expandido, `lightBackground` quando colapsado | `lightBackground` |

**TutorialState após vídeo completo (vídeo assistido até o fim):**
```
lowerButtonText = R.string.onboarding_video_button  // "Começar"
videoText       = R.string.onboarding_video_watch_again  // "Assistir de novo"
videoIcon       = R.drawable.replay
isExpanded      = false  // volta ao estado colapsado
isLowerButtonActivated = true
```

**TutorialState quando card tocado (vídeo expandido — tela cheia):**
```
isExpanded = true  (fundo vira preto)
```

### Estrutura de layout (fragment_tutorial.xml)

```
ConstraintLayout (@id/container) — fundo dinâmico (preto ou lightBackground)
  ├── Guideline expandedStartGuideline   (begin=component_padding)
  ├── Guideline expandedEndGuideline     (end=component_padding)
  ├── Guideline collapsedStartGuideline  (begin=64dp)
  ├── Guideline collapsedEndGuideline    (end=64dp)
  │
  ├── TextView @id/title
  │     text="@string/onboarding_video_title"  → "Como usar o Spoke"
  │     style=textAppearanceHeadline2
  │     textAlignment=center
  │     marginTop=32dp
  │     constraintStart=expandedStartGuideline, constraintEnd=expandedEndGuideline
  │
  ├── MaterialCardView @id/card   (cornerRadius=24dp, marginTop=32dp, marginBottom=32dp)
  │     clickable=true  (toque → expande vídeo)
  │     constraintStart=collapsedStartGuideline, constraintEnd=collapsedEndGuideline
  │     (quando colapsado)
  │   └── FrameLayout
  │         ├── VideoView @id/videoView  (layout_gravity=center)
  │         └── View @id/scrim  (background=@color/video_view_scrim)
  │               visibility: GONE quando expandido; VISIBLE quando colapsado
  │               alpha animada: 0.73f quando vídeo preparado (400ms); 1.0f quando toque navega ao Home (80ms)
  │
  ├── ImageView @id/videoIcon   (elevation=10dp)
  │     visibility: VISIBLE quando colapsado; GONE quando expandido
  │     src: dinâmico por estado (play → replay após assistir)
  │
  ├── TextView @id/videoLabel   (elevation=10dp, textColor=constants_light_100)
  │     visibility: GONE quando colapsado; VISIBLE quando expandido ← ATENÇÃO: lógica INVERTIDA
  │     text: dinâmico por estado ("Conheça o Spoke em 15 segundos" → "Assistir de novo")
  │     textAlignment=center
  │     marginStart=24dp, marginEnd=24dp
  │     style=textAppearanceHeadline4
  │     vertical chain packed com videoIcon
  │
  └── MaterialButton @id/get_started  (style=materialButtonTextStyle)
        textColor=@color/map_action_color_state
        text: dinâmico por estado
        isActivated: dinâmico (true quando vídeo assistido — altera aparência)
        marginBottom=24dp
        constraintStart=expandedStartGuideline, constraintEnd=expandedEndGuideline
```

**Observação sobre visibilidade:** `videoIcon` é VISIBLE (`visibility=0`) quando NÃO expandido; `videoLabel` é VISIBLE quando expandido. No estado inicial (colapsado), mostra ícone play; no estado expandido (toque no card), mostra o label de texto.

### ConstraintSets dinâmicos (set_tutorial_collapsed / set_tutorial_expanded)

Aplicadas via `ConstraintSet.applyTo()` com transição (`TransitionManager`) ao mudar `isExpanded`:

- **`set_tutorial_collapsed.xml`** — card ancorando em `collapsedStartGuideline`/`collapsedEndGuideline`, com `marginTop=32dp`/`marginBottom=32dp` entre título e botão.
- **`set_tutorial_expanded.xml`** — card ocupa toda a tela (ancorando em `parent` top/bottom, `expandedStartGuideline`/`expandedEndGuideline`). Título e botão ficam sobrepostos visualmente (o card cobre tudo — tela cheia).

### Comportamento do VideoView

- URI configurada via `k1` (lazy, classe `C25470qs` — provavelmente de assets ou URL pré-definida)
- `setOnCompletionListener` = ViewModel
- Ao completar (`onCompletion`):
  - Se `isExpanded == true`: dispara `"Tutorial fullscreen video tapped"` analytic; emite state com `lowerButtonText="Começar"`, `videoText="Assistir de novo"`, `videoIcon=R.drawable.replay`, `isExpanded=false`, `isLowerButtonActivated=true`
  - `mediaPlayer.start()` — reinicia o loop (o vídeo fica em loop infinito)
- `onResume` → `videoView.start()` (retoma playback ao voltar ao fragment)
- Ao `isExpanded` mudar para `true` via `distinctUntilChanged`: `videoView.seekTo(0)` (reinicia para o início ao expandir)

### Interações do usuário

| Elemento | Ação | Resultado |
|---|---|---|
| Card (`@id/card`) toque | `onClickListener` | ViewModel: `isExpanded = true` → vídeo fullscreen |
| Botão inicial ("Já usei o Spoke antes") | `onClickListener` | ViewModel: navega para Home (emite `GoHome`) |
| Botão final ("Começar") | `onClickListener` (mesmo botão) | ViewModel: navega para Home (emite `GoHome`) |
| Back (hardware) | `OnBackPressedDispatcher` | Se `isExpanded`: volta ao estado colapsado (`GoHome` não; reverte expand). Se colapsado: navega ao Home |

**Lógica de back (case 23 em `C2077cn`):**
```
if (isExpanded) → m36781I(update state: isExpanded=false)  // colapsa
else → m10064J()  // navega para Home
```

### TutorialEvent (sealed class `AbstractC4114a`)

| Evento | toString | Ação |
|---|---|---|
| `GoHome` (classe `a`) | "GoHome" | Navega via `action_home → Home` |

### Analytics (DriverEvents)

| Classe | Evento | Quando |
|---|---|---|
| `c56` | "Tutorial video shown" | `TutorialViewModel` init (construtor) |
| `d56` | "Tutorial video skipped" | Botão pressionado e vídeo NÃO estava expandido (`!l1`) |
| `e56` | "Tutorial video tapped" | Vídeo expandido (card tocado) e botão pressionado |
| `f56` | "Tutorial video watched" | `onCompletion` com `isExpanded == true` |
| `b56` | "Tutorial fullscreen video tapped" | `onCompletion` com `isExpanded == true` (mesmo evento) |

**Evento "Exited tutorial activity"** (com propriedade `State`):
- Disparado em `m10064J()` sempre que o usuário sai da tela
- State = `ExitedTutorialScreenState`:
  - `NOT_PLAYED` ("Not played") — vídeo nunca chegou ao fullscreen
  - `PLAYING` ("Playing") — vídeo estava em fullscreen mas não terminou
  - `FINISHED_PLAYING` ("Finished playing") — vídeo assistiu até o fim

### Strings PT-BR verbatim (tutorial)

| String key | Valor PT-BR verbatim |
|---|---|
| `onboarding_video_title` | "Como usar o Spoke" |
| `onboarding_video_overlay_text` | "Conheça o Spoke em 15 segundos" |
| `onboarding_video_skip` | "Já usei o Spoke antes" |
| `onboarding_video_button` | "Começar" |
| `onboarding_video_watch_again` | "Assistir de novo" |

### Drawables de ícone (sobre o vídeo)

| Drawable | Equivalente Lucide sugerido | Quando |
|---|---|---|
| `R.drawable.play` | `Play` | Estado inicial (vídeo não assistido) |
| `R.drawable.replay` | `RotateCcw` | Após assistir até o fim |

> Nota: `R.drawable.play_arrow` também existe mas NÃO é referenciado pela tela de tutorial — apenas `play` e `replay`.

### Precisa-runtime

- URI exata do vídeo tutorial (asset local ou URL remota? — a classe `C25470qs` com índice 22 esconde o valor)
- Comportamento visual exato da transição ConstraintSet collapsed ↔ expanded (timing, interpolador)
- Alpha do scrim no estado collapsed inicial (o vídeo começa com scrim opaco e anima para 0.73f quando preparado — mas o estado inicial do scrim não é visível até `onPrepared`)

---

## Componente contextual — Cluster Feature Onboarding (tooltips in-route)

**NÃO é uma tela separada.** São tooltips sobrepostos ao mapa dentro do `HomeFragment` (edição de rota), exibidos quando o usuário usa o modo de agrupamento manual pela primeira vez.

**Implementação:** strings + lógica dentro de `MapController` ou similar. NÃO há Fragment/Activity separado no namespace `tutorial/`.

### Strings PT-BR verbatim (cluster onboarding in-route)

| String key | Valor PT-BR verbatim |
|---|---|
| `cluster_feature_onboarding_start` | "Iniciar" |
| `cluster_feature_onboarding_step1` | "Agrupe no mapa as paradas a serem realizadas primeiro" |
| `cluster_feature_onboarding_step2` | "Crie quantos grupos forem necessários, na ordem em que você queira dirigir" |
| `cluster_feature_onboarding_step3` | "Toque em \"Reotimizar rota\" para revisar a nova rota" |
| `cluster_feature_onboarding_tooltip_draw_on_map` | "Desenhar para agrupar as paradas" |
| `cluster_feature_onboarding_tooltip_erase` | "Desenhar para diminuir os grupos" |
| `cluster_feature_onboarding_tooltip_expand` | "Desenhar para expandir os grupos" |
| `cluster_feature_onboarding_tooltip_start_drawing_first` | "Criar o primeiro grupo" |
| `cluster_feature_onboarding_tooltip_start_drawing_many` | "Criar quantos grupos forem necessários" |
| `cluster_feature_onboarding_tooltip_start_drawing_second` | "Criar um segundo grupo" |

**Relevância RotPro:** este componente pertence à Área de agrupamento/clusters (funcionalidade de Reotimizar). Documentar na área correspondente, não aqui.

---

## Resumo de implementação RotPro

### O que implementar

1. **OnboardingSurvey** — tela Compose pós-login com 5 cards de seleção de perfil. Apenas `PackageDelivery` avança direto ao tutorial; os demais exibem o FollowUp com opção de desinstalar ou "ainda quero testar".
2. **TutorialFragment** — tela View-based com `VideoView`, card clicável para fullscreen, botão inferior com dois estados de texto ("Já usei o Spoke antes" → "Começar"), vídeo em loop, ConstraintSets animados para collapsed/expanded.

### O que NÃO implementar (B2B / fora de escopo)

- Cluster feature onboarding tooltips — pertence à Área de clusters (Área 8+), não ao tutorial de onboarding.
- A lógica de desinstalar app — RotPro não vai oferecer "Desinstalar app"; substituir o botão por "Voltar" ou omitir o FollowUp por completo (decisão: Eduardo/Ueslei).

### Decisão pendente (Eduardo/Ueslei)

- O FollowUp para perfis não-alvo deve existir no RotPro? O Spoke exibe porque monitora conversão. Para RotPro B2C focado em entregadores, pode-se simplificar: survey → se PackageDelivery → tutorial; caso contrário → tutorial diretamente (sem tela de followup).
- O vídeo tutorial: será o mesmo vídeo do Spoke (não pode — é propriedade deles) ou um vídeo novo do RotPro? O URI do vídeo precisa ser produzido; sem ele a tela fica em branco.
