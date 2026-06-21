# Front blueprint — settings

Data: 2026-06-21
Fonte: `jadx-out/sources/com/circuit/p016ui/settings/` + `values-pt-rBR/strings.xml`
Classe principal: `com.circuit.ui.settings.SettingsFragment` (extends `PreferenceFragmentCompat`)

---

## Visão geral

A tela de Configurações é um `PreferenceFragmentCompat` único com quatro seções B2C + uma seção de Assinatura, construídas programaticamente (sem XML de preferências). Nenhum `RecyclerView` customizado — usa `PreferenceScreen` + `StyledPreferenceCategory` nativo. Transições de entrada/saída configuradas via `id7` (Shared Element / Fade). Toolbar com título clicável.

Acesso: drawer lateral → item "Configurações" (`drawer_settings_action_title`, ícone `baseline_settings_24`).

---

## 1. SettingsFragment (tela raiz)

**Nome/Propósito:** Tela de configurações completa do app — preferências gerais, de rota, assinatura, juridico/meta.
**Classe:** `com.circuit.ui.settings.SettingsFragment`

### Estrutura (ordem de renderização)

#### Seção 1 — Preferências gerais (`settings_section_general_preferences`)

| Linha | Tipo | Título | Sumário dinâmico | Pref key | Ação ao clicar |
|---|---|---|---|---|---|
| Tema | EnumPreference (row) | "Tema" (`app_theme_title`) | Enum atual formatado + info de nascer/pôr do sol se AUTOMATIC | UUID gerado | Abre `EnumPreferenceDialog` com opções de `AppTheme` |

**AppTheme — enum completo:**
- `LIGHT` → "Claro" (`app_theme_light`)
- `DARK` → "Escuro" (`app_theme_dark`)
- `SYSTEM` → "Mesmo do sistema" (`app_theme_follow_system`)
- `AUTOMATIC` → "Automático (Pôr do Sol/Nascer do Sol)" (`app_theme_automatic`)

Quando `AUTOMATIC` está ativo, o sumário exibe os horários de nascer e pôr do sol no formato `☀️ HH:mm / 🌃 HH:mm` (requer async — detectado via `isInternalUser`/`automaticAppThemeHandler`).

---

#### Seção 2 — Preferências de rota (`settings_section_route_preferences`)

| Linha | Tipo | Título PT-BR | Sumário dinâmico | Pref key | Ação ao clicar |
|---|---|---|---|---|---|
| App de navegação | NavigationPreference (row) | "App de navegação" (`navigation_app_title`) | Nome do app atual (ex. "Google Maps") | — | Abre `NavigationAppDialog` (Compose sheet) |
| Lado da parada | EnumPreference (row) | "Lado da parada" (`stop_side`) | Enum formatado via `UiFormatters.formatRoadSide()` | UUID gerado | Abre `EnumPreferenceDialog` com opções de `RoadSide` |
| Tempo médio na parada | DurationPreference (row) | "Tempo médio na parada" (`avg_time_at_stop_title`) | Duração formatada | UUID gerado | Abre `DurationInputPreferenceDialog` |
| Tipo de veículo | VehiclePreference (row) | "Tipo de veículo" (`vehicle_title`) | Nome do veículo atual (ex. "Carro") | — | Abre `VehicleTypeDialog` (Compose sheet) |
| Evitar pedágios | SwitchPreference | "Evitar pedágios" (`avoid_tolls`) | "Economizar evitando estradas com pedágio" (`save_costs_avoiding_toll_roads`) OU "Indisponível para este tipo de veículo" (`not_available_for_vehicle_type`) | `avoid_tolls` | Toggle (desabilitado quando veículo ≠ `CAR`) |
| ID de parada | Preference (row) | "ID de parada" (`package_identification_feature_title`) | Sumário com modo atual + formato | — | Abre `PackageLabelModeDialogFragment` (Compose modal) |
| Balão do modo de navegação | SwitchPreference | "Balão do modo de navegação" (`settings_bubble_title`) | "Veja informações de entrega enquanto navega" (`settings_bubble_subtitle`) | `settings_bubble_title` | Toggle — **visível apenas se `navigationBubble` suportado pelo dispositivo** |

**RoadSide — enum completo:**
- `ANY` → "Qualquer lado do veículo" (`any_side_of_vehicle`) / "Qualquer lado do veículo (recomendado)" (`any_side_of_vehicle_recommended`)
- `LEFT_ONLY` → "Apenas esquerdo" (`left_only_road_side_title`)
- `RIGHT_ONLY` → "Apenas direito" (`right_only_road_side_title`)

**VehicleType — enum completo + labels PT-BR + drawables:**
- `BIKE` → "Bicicleta" (`bike_title`), subtítulo "Somente Google Maps" (`bike_google_maps_only`), drawable: `vehicle_bike`
- `SCOOTER` → "Scooter" (`scooter_title`), sem subtítulo, drawable: `vehicle_scooter`
- `CAR` → "Carro" (`car_title`), sem subtítulo, drawable: `vehicle_car` — **default**
- `SMALL_TRUCK` → "Caminhão pequeno" (`small_truck_title`), sem subtítulo, drawable: `vehicle_small_truck`
- `TRUCK` → "Caminhão grande" (`large_truck_title`), subtítulo "Somente Sygic Maps" (`large_truck_sygic_maps_only`), drawable: `vehicle_large_truck`

**NavigationApp — enum completo + labels PT-BR (ordem no dialog):**
- `INTERNAL` → "Navegação do Spoke" (`circuit_internal_navigation`) — listado PRIMEIRO
- `GOOGLE` → "Google Maps" (`google_maps`)
- `WAZE` → "Waze" (`waze`)
- `YANDEX` → "Navegador Yandex" (`yandex_navigator`)
- `OTHER` → "Outro" (`navigation_app_other`)

**Defaults (extraídos do `Config.kt` / `rxc.get()`):**
- vehicleType: `CAR` (default)
- navigationApp: `GOOGLE` (default — sumário arranca com "Google Maps")
- avgTimeAtStop: `Duration.ofMinutes(1)` = 1 minuto (`hj4.f104611a`)
- roadSide: `ANY` (default)
- avoidTolls: `false` (switch off por default; desabilitado quando veículo ≠ `CAR`)
- navigationBubble: depende de `rxcVar.get().f24024g` + feature flag do device

---

#### Seção 3 — Assinatura (`settings_section_subscription`)

| Linha | Tipo | Título PT-BR | Visibilidade | Ação |
|---|---|---|---|---|
| "Cancelar assinatura" (`cancel_subscription_title`) | Preference (row) | — | Visível apenas se assinatura ativa E plano ≠ `Free` | Abre fluxo de cancelamento |
| "Comparar planos" (`compare_plans_title`) | Preference (row) | — | Sempre visível | Navega para tela de comparação |

**SubscriptionPlan — enum:**
- `Standard`
- `Lite`
- `Free`

Lógica de visibilidade do "Cancelar assinatura":
```
visible = subscriptionInfo != null && subscriptionInfo.isActive && subscriptionInfo.plan != SubscriptionPlan.Free
```
A seção de Assinatura é carregada assincronamente (via `GetSubscriptionInfo` + `getUser`); a categoria começa visível após carregamento do flow.

---

#### Seção 4 — (sem título) — Jurídico e meta

| Linha | Tipo | Título PT-BR | Sumário | Pref key | Ação |
|---|---|---|---|---|---|
| Licenças | Preference | "Licenças" (`licenses_title`) | "" | `licenses` | Abre tela de licenças OSS |
| Termos de uso | Preference | "Termos de uso" (`tos_title`) | "" | `terms_of_use` | Navega para URL de termos |
| Política de privacidade | Preference | "Política de privacidade" (`privacy_policy_title`) | "" | `privacy_policy` | Abre `https://spoke.com/privacy` (via Intent externo) |
| Versão | Preference | "Versão" (`version_title`) | `{app_name}-v{versionName}` | `app_version` | 5 toques seguidos → exporta logs de diagnóstico |
| Sair | Preference | "Sair" (`settings_logout`) | "" | — | Logout do usuário |

---

## 2. NavigationAppDialog

**Nome/Propósito:** Picker de app de navegação — seleciona qual app abrir ao navegar para uma parada.
**Classe:** `com.circuit.ui.settings.dialogs.NavigationAppDialog` (extends `AdaptiveModalDialog`, Compose)
**Tamanho:** `AdaptiveModalSize.FullWidth` (mesmo em phone/tablet)

### Estrutura
- Lista de opções: `RadioListTile` simples (sem ícone, apenas label) com seleção única
- Ordem: Navegação do Spoke → Google Maps → Waze → Navegador Yandex → Outro
- Botão cancelar (fecha sem salvar)
- Seleção confirmada ao toque → fecha dialog e persiste

### Strings PT-BR verbatim
- "Navegação do Spoke"
- "Google Maps"
- "Waze"
- "Navegador Yandex"
- "Outro"

### Navegação
- Abre por: row "App de navegação" em Preferências de Rota
- Fecha em: seleção ou cancelar

### Estados/Defaults
- Item atual marcado via `NavigationApp` enum comparação por referência
- Default: `GOOGLE` → "Google Maps"

### Ícones
- Nenhum ícone por item (lista texto puro)

### Precisa-runtime
- Confirmar se a lista mostra checkmark ou radio button destacado visualmente

---

## 3. VehicleTypeDialog

**Nome/Propósito:** Picker de tipo de veículo.
**Classe:** `com.circuit.ui.settings.dialogs.VehicleTypeDialog` (extends `AdaptiveModalDialog`, Compose)
**Tamanho:** `AdaptiveModalSize.FullWidth`

### Estrutura
- Lista de opções com: ícone drawable (ex. `vehicle_car`), título, subtítulo opcional
- Ordem: Bicicleta → Scooter → Carro → Caminhão pequeno → Caminhão grande
- Botão cancelar

### Strings PT-BR verbatim
- "Bicicleta" / subtítulo: "Somente Google Maps"
- "Scooter"
- "Carro"
- "Caminhão pequeno"
- "Caminhão grande" / subtítulo: "Somente Sygic Maps"

### Navegação
- Abre por: row "Tipo de veículo" em Preferências de Rota

### Estados/Defaults
- Default: `CAR` ("Carro")
- Item atual marcado por comparação de referência do enum

### Ícones (drawable → Lucide sugerido)
- `vehicle_bike` → `Bike` (Lucide)
- `vehicle_scooter` → `Bike` (variante, sem ícone direto no Lucide — usar `Bike`)
- `vehicle_car` → `Car` (Lucide)
- `vehicle_small_truck` → `Truck` (Lucide)
- `vehicle_large_truck` → `Truck` (Lucide, tamanho maior ou badge)

### Precisa-runtime
- Confirmar layout exato: ícone à esquerda ou à direita do texto?

---

## 4. EnumPreferenceDialog (Tema e Lado da parada)

**Nome/Propósito:** Dialog genérico de seleção de enum — reutilizado para "Tema" e "Lado da parada".
**Classe:** `com.circuit.components.settings.EnumPreferenceDialog`

### Estrutura
- Título = título da preferência (ex. "Tema" ou "Lado da parada")
- Lista de opções `RadioListTile` — cada item tem o nome do enum formatado
- Fechamento imediato ao selecionar

### Tema — opções e ordem:
1. "Claro" (LIGHT)
2. "Escuro" (DARK)
3. "Mesmo do sistema" (SYSTEM)
4. "Automático (Pôr do Sol/Nascer do Sol)" (AUTOMATIC)

### Lado da parada — opções e ordem:
1. "Qualquer lado do veículo (recomendado)" (ANY)
2. "Apenas esquerdo" (LEFT_ONLY)
3. "Apenas direito" (RIGHT_ONLY)

### Precisa-runtime
- Confirmar se existe botão "Cancelar" no rodapé ou apenas dismiss ao tocar fora

---

## 5. DurationInputPreferenceDialog (Tempo médio na parada)

**Nome/Propósito:** Input de duração em minutos para "Tempo médio na parada".
**Classe:** `com.circuit.components.settings.DurationInputPreferenceDialog`

### Estrutura
- Título: "Tempo médio na parada" (`avg_time_at_stop_title`)
- Campo de entrada numérico em minutos
- Placeholder: "Tempo em minutos" (`edit_time_at_stop_placeholder`)
- Valor mínimo: `Duration.ofMinutes(1)` (1 minuto = default)
- Botões: Confirmar / Cancelar

### Strings PT-BR verbatim
- "Tempo médio na parada"
- "Tempo em minutos"

### Navegação
- Abre por: row "Tempo médio na parada" em Preferências de Rota

### Precisa-runtime
- Confirmar se tem botões Confirm/Cancel ou apenas confirma ao fechar teclado

---

## 6. PackageLabelModeDialogFragment (ID de parada)

**Nome/Propósito:** Modal de configuração de ID de parada — define QUANDO os IDs são atribuídos (modo) e em qual FORMATO.
**Classe:** `com.circuit.ui.settings.package_labels.PackageLabelModeDialogFragment` (extends `AdaptiveModalFragment`, Compose)
**Tamanho:** `AdaptiveModalSize.WRAP_CONTENT` (todos os breakpoints)

### Estrutura
- Seção de MODO (PackageLabelMode):
  - "Depois da otimização da rota" (`package_identification_mode_ordered_option`) [OPTIMIZED_ORDER]
  - "Conforme as paradas são adicionadas" (`package_identification_mode_added_option`) [ADDED_ORDER]
- Seção de FORMATO (PackageLabelFormat):
  - "Clássico" (`package_identification_format_legacy_option`) [BASE]
  - "Moderno" (`package_identification_format_modern_option`) [MODERN]
- Cada opção tem título + descrição longa
- Botão "Voltar" / fechar (via `onBackClick`)
- Resultado enviado via `FragmentResult` com key `package_label_mode_result` (bundle: `confirmed: Boolean`)

### PackageLabelMode — enum:
- `ADDED_ORDER` (ordinal 0) → "Conforme as paradas são adicionadas"
- `OPTIMIZED_ORDER` (ordinal 1) → "Depois da otimização da rota"

### PackageLabelFormat — enum:
- `BASE` (ordinal 0) → "Clássico" — Os IDs usam número, pode causar confusão com número de parada
- `MODERN` (ordinal 1) → "Moderno" — Formato que distingue ID de número da parada

### Strings PT-BR verbatim (selecionadas)
- "ID de parada" (`package_identification_feature_title`)
- "Formato do ID de parada" (`package_identification_format_title`)
- "Atribuir IDs às paradas" (`package_identification_mode_title`)
- "Depois da otimização da rota"
- "Conforme as paradas são adicionadas"
- "Clássico"
- "Moderno"
- "Os IDs são %1$s e não serão alterados quando a rota for otimizada.\n\nPara usar quando você carrega o veículo conforme adiciona paradas ao Spoke."
- "Os IDs são %1$s e da confirmação da rota.\n\nPara usar quando você carrega o veículo depois de otimizar a rota com o Spoke."

### Navegação
- Abre por: row "ID de parada" em Preferências de Rota
- Fecha em: botão voltar ou confirmação; resultado propagado ao fragmento pai

### Precisa-runtime
- Confirmar layout exato (cards? lista com radio? accordion por seção?)
- Confirmar se exibe ambas as seções simultaneamente ou em steps

---

## 7. Seção Assinatura (detalhes de navegação)

### "Cancelar assinatura" → [B2B — cortar]
O fluxo de cancelamento (`cancel_subscription_title`) é parte do billing/subscription do Spoke (Stripe/AppStore). Para RotPro com paywall próprio via Pix (ADR-0030), esta opção não existe da mesma forma. Cortar ou adaptar para o modelo RotPro.

### "Comparar planos" → [B2B — cortar]
`compare_plans_title` leva a uma tela de comparação de planos Spoke (Standard/Lite/Free). RotPro tem apenas um plano (R$ 25,90/30 dias). Cortar.

---

## 8. Seção "Otimização de bateria" (Android Auto)

Label: `settings_section_battery_optimization` ("Otimização de bateria")
Aparece no dump mas sua renderização em SettingsFragment acontece via branch de `isInternalUser = true` apenas — é seção de **developer/debug** com limite de FPS de navegação ("Navigation frame rate limit"). **Cortar** da implementação B2C.

---

## Resumo de navegação

```
Drawer → item "Configurações"
  └─ SettingsFragment
       ├─ [Preferências gerais]
       │    └─ row Tema → EnumPreferenceDialog (LIGHT/DARK/SYSTEM/AUTOMATIC)
       ├─ [Preferências de rota]
       │    ├─ row App de navegação → NavigationAppDialog
       │    ├─ row Lado da parada → EnumPreferenceDialog (ANY/LEFT_ONLY/RIGHT_ONLY)
       │    ├─ row Tempo médio na parada → DurationInputPreferenceDialog
       │    ├─ row Tipo de veículo → VehicleTypeDialog
       │    ├─ row Evitar pedágios → Switch (disabled se veículo ≠ CAR)
       │    ├─ row ID de parada → PackageLabelModeDialogFragment
       │    └─ row Balão do modo de navegação → Switch (condicional ao device)
       ├─ [Assinatura] ← [B2B — cortar seção inteira para RotPro]
       │    ├─ Cancelar assinatura (visível apenas se ativo e plano ≠ Free)
       │    └─ Comparar planos
       └─ [sem título — Jurídico/Meta]
            ├─ Licenças → tela OSS
            ├─ Termos de uso → URL externa
            ├─ Política de privacidade → https://spoke.com/privacy
            ├─ Versão → (5 toques = export logs)
            └─ Sair → logout
```

---

## Notas de implementação RotPro

1. **Seção Assinatura**: substituir por link para renovação/status do Pix (ADR-0030). Remover "Cancelar assinatura" e "Comparar planos".
2. **Política de privacidade**: trocar URL `https://spoke.com/privacy` pela URL do RotPro.
3. **Navegação do Spoke** (`INTERNAL`): remover esta opção do NavigationAppDialog (feature proprietária do Spoke). Manter apenas GOOGLE / WAZE / YANDEX / OTHER.
4. **Yandex Navigator**: avaliar com cliente Ueslei se manter ou remover (nicho Brasil pequeno).
5. **Seção developer/debug**: remover toda a branch `isInternalUser = true` (Dialog Gallery, Recordings, AB tests, Backend, Network options, etc.).
6. **Tema AUTOMATIC** (Pôr do Sol/Nascer do Sol): requer API de localização para calcular horários. Considerar manter LIGHT/DARK/SYSTEM apenas num primeiro momento.
7. **Balão do modo de navegação**: condicionado à presença de app compatível (Google Maps/Waze instalado). Manter lógica condicional.
8. **Preferência de veículo e "Evitar pedágios"**: relação direta — ao trocar veículo de/para CAR o switch de pedágios habilita/desabilita automaticamente.
9. **PackageLabelModeDialogFragment**: fluxo completo necessário. Defaults na entrega inicial: modo = `OPTIMIZED_ORDER`, formato = `MODERN`.

### Precisa-runtime (consolidado)
- Layout visual de NavigationAppDialog e VehicleTypeDialog (checkmark, radio, posição ícone)
- Layout de PackageLabelModeDialogFragment (cards vs lista vs steps)
- Presença de botão Cancelar no EnumPreferenceDialog e DurationInputPreferenceDialog
- Comportamento do toolbar clicável em SettingsFragment (scroll-to-top? nenhuma ação?)
