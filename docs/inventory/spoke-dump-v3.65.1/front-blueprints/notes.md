# Front blueprint — notes

**Data:** 2026-06-21
**Fonte:** `com.circuit.p016ui.notes` (jadx v3.65.1) + `values-pt-rBR/strings.xml`
**Escopo:** tela/modal de notas da parada e da pausa; row de notas no detail-sheet e no EditStop

---

## Visão geral da área

A área `notes` cobre **edição de notas de texto livres** vinculadas a uma parada (`BaseStopId`) ou a uma pausa (`BreakId`). É complementada por uma seção opcional de **fotos do pacote** (máx. 3 fotos, bloqueada por `PlanFeature.PackagePhotos`). Há **dois pontos de entrada**:

1. **Route Step Detail Sheet** (home shell) — row "Notas" clicável que abre o `NotesFragment`.
2. **Edit Stop / EditStopEditor** — row de notas embutido que também abre o `NotesFragment` (via `onNotesEditRequested()`).

---

## 1. NotesFragment / NotesScreen

**Nome:** Tela de Edição de Notas
**Propósito:** Permite escrever/editar texto livre de notas de uma parada ou pausa.
**Classe principal:** `com.circuit.ui.notes.NotesFragment` extends `AdaptiveModalFragment`
**Tela Compose:** `NotesScreen` (`NotesScreenKt` / `C3826g.m9843a`)
**ViewModel:** `com.circuit.ui.notes.NotesViewModel`

### Apresentação

- Renderizado como **`AdaptiveModalFragment`** com `AdaptiveModalSize.Medium` (enum: Small=0, **Medium=1**, Large=2).
- No celular em **MobilePortrait** (`Breakpoint.MobilePortrait` = `f23000h1`): modal de fundo com altura média.
- Em **MobileLandscape** / **Tablet** (`f23001i1` / `f23002j1`): comportamento adaptativo (toggle da visibilidade de estado local `x8a<Boolean>`).
- Não é navegação por rota — é um Fragment mostrado via `k6f.m36875j(fragment, fca(NotesEditorArgs))`.
- `m4283p(false)` no `onCreateDialog` — cancela ao tocar fora (dismiss-on-outside = false).

### Estrutura (ordem visual de cima para baixo)

```
TopBar
  [título]               "Editar notas"          (R.string.edit_notes_title)
  [botão direito]        "Concluído"              (R.string.done → "Concluído")

TextArea (ocupa o espaço restante com weight=1)
  placeholder            "Adicionar notas"        (R.string.add_notes_placeholder)
  padding                16dp todos os lados
  maxLines               ilimitado (Integer.MAX_VALUE)
  keyboard               texto (IME)
  estado salvo           SavedStateHandle key "NotesTextField"

[seção de fotos — condicional]
  Visível apenas quando: fotos != null (lista não vazia OU PackagePhotos habilitado)
  PhotoSection           (PackagePhoto.kt / hya.m33829d)
    — até 3 miniaturas de 80dp × 80dp em Row horizontal
    — se list.size() < 3 E PackagePhotos habilitado: botão "+"  (ic_add_photo_24)
    — tap na miniatura → abre PackagePhotoViewer (tela separada)
    — long-press / tap no "×" da miniatura → diálogo "Remover foto"
    padding              (16dp top, 0 bottom) / (0 top, 16dp bottom) no container
```

### Strings PT-BR verbatim

| Chave | Valor |
|---|---|
| `edit_notes_title` | `"Editar notas"` |
| `done` | `"Concluído"` |
| `add_notes_placeholder` | `"Adicionar notas"` |
| `package_photo_cleanup_warning` | `"Fotos são excluídas depois de 30 dias"` |
| `remove_photo_warning_alert_title` | `"Remover foto"` |
| `remove_photo_warning_alert_body` | `"Esta foto será removida da parada permanentemente."` |
| `cancel` | `"Cancelar"` |

### Navegação / entradas

| Origem | Payload | Observação |
|---|---|---|
| Route Step Detail Sheet (`OpenNotesEditor`) | `NotesEditorArgs.StopNote(stopId)` | via `EditRouteFragment.m9383o()` |
| `EditStopEditor` (row de notas) | `NotesEditorArgs.StopNote(stopId)` | via `xaaVar.m46257e(fca(StopNote(...)))` |
| Break row (pausa) | `NotesEditorArgs.BreakNote(breakId)` | mesmo Fragment, outro editor |

### Saída / ações

| Ação | Comportamento |
|---|---|
| Botão "Concluído" | Salva (se texto mudou) → dismiss |
| Back navigation | Salva (se texto mudou) → dismiss |
| IME submit (Enter) | Move cursor para cursor-end (não fecha) |
| Toque fora do modal | **NÃO** fecha (dismiss-on-outside = false) |

### Estados / defaults

| Campo | Default | Tipo |
|---|---|---|
| `textFieldValue` | texto atual da entidade (observado do repositório) | `TextFieldValue` |
| `photos` | `null` se lista vazia + feature desabilitada; `List<Uri>` caso contrário | nullable |
| `canAddPhoto` | `AppFeature.ChangeStopNotes.isEnabled && PlanFeature.PackagePhotos.isEnabled` | Boolean |
| Salvar no dismiss | Só salva se texto mudou (diff com valor original via `wi8.m45958a`) | — |
| Imagem do modal (Breakpoint) | MobileLandscape/Tablet: toggle de visibilidade adicional (x8a<Boolean>) | — |

### Feature gates

- **`AppFeature.ChangeStopNotes`** (`RouteSpecificFeature`) — gate da edição de notas em si. Se desabilitado: row no detail-sheet mostra `FeatureStatus` em vez de abrir o editor.
- **`PlanFeature.PackagePhotos`** — gate de plan (pago) para a seção de fotos. Se desabilitado E lista vazia: `photos = null` → seção de fotos oculta. [Fotos são funcionalidade de plano pago no Spoke — avaliar se RotPro vai ter]

### Ícones

| Drawable | Tamanho | Equivalente Lucide sugerido | Uso |
|---|---|---|---|
| `notes_16` | 16dp | `FileText` (16dp) | ícone do row no detail-sheet e EditStop |
| `note` | 24dp | `FileText` (24dp) | mesmo shape, usado no route step property |
| `ic_add_photo_24` | 24dp | `CameraPlus` / `ImagePlus` | botão "+" da seção de fotos |

> `notes_16` e `note` têm o mesmo shape (documento com dobra no canto superior direito + 2 linhas de texto). `notes_16` é preenchido escuro (`#141a27`), `note` é preenchido cinza-azulado (`#4a5874`).

### Precisa-runtime

- Animação de entrada/saída do modal (spring ou fade).
- Tamanho exato do modal em MobilePortrait (height da sheet no M54).
- Comportamento do campo de texto quando o teclado sobe (scroll, resize, ou push).
- Se as fotos têm animação de entrada (`AnimatedVisibility` com `fadeIn`/`slideInVertically` está no código — confirmar visualmente).

---

## 2. Row de Notas no Route Step Detail Sheet

**Classe construtora:** `com.circuit.ui.home.editroute.components.detailsheet.C3522a` (RouteStepPropertyFormatter)
**Modelo:** `RouteStepSheetPropertyUiModel`

### Estrutura do row

```
Row
  ícone esquerdo     note (24dp, #4a5874)
  texto central      [condicional]:
    — notas vazias + ChangeStopNotes habilitado:   "Adicionar notas"  (placeholder style)
    — notas vazias + ChangeStopNotes desabilitado: "Nenhuma nota adicionada"  (placeholder style)
    — notas preenchidas:                            texto das notas (default style)
  [thumbnail fotos]  aparece abaixo do texto se lista não vazia
  trailing           →  (indicador de navegação)
```

### Estilos de texto (`RouteStepSheetPropertyUiModel.Style`)

| Enum | Valor | Uso |
|---|---|---|
| `Default` | 0 | notas preenchidas |
| `Placeholder` | 1 | campo vazio (texto cinza) |
| `Outlined` | 2 | não usado nas notas |

### Strings PT-BR verbatim (contexto do row)

| Chave | Valor | Quando |
|---|---|---|
| `add_notes_placeholder` | `"Adicionar notas"` | vazio + feature habilitada |
| `edit_stop_no_notes_placeholder` | `"Nenhuma nota adicionada"` | vazio + feature desabilitada |

### Ação ao tap

- `ChangeStopNotes` habilitado → emit `OpenNotesEditor(notes = string atual ou "")` → Fragment mostra.
- `ChangeStopNotes` desabilitado → emit `ShowFeatureUpsell(AppFeature.ChangeStopNotes, featureStatus)` → upsell (fora do escopo B2C simples).

---

## 3. Row de Notas no EditStopEditor

**Classe:** `com.circuit.ui.edit.EditStopEditorKt` (função `Notes()`)

### Estrutura do row

```
Row (altura mínima 56dp)
  ícone esquerdo     notes_16 (16dp)
    — se ChangeStopNotes enabled:   tint da cor primária
    — se disabled:                  tint da cor secundária/disabled
  texto central      [condicional]:
    — notes vazias + feature habilitada:   "Adicionar notas"   (placeholder, cor secundária)
    — notes vazias + feature desabilitada: "Nenhuma nota adicionada"
  trailing ícone     ic_add_photo_24 (24dp) — visível APENAS se `z = true` (feature de foto ativa)
  padding            16dp todos os lados
```

### Comportamento ao tap

- `ChangeStopNotes` habilitado: `onNotesEditRequested()` → abre `NotesFragment` via navegação.
- `ChangeStopNotes` desabilitado: `ShowFeatureUpsell(AppFeature.ChangeStopNotes, featureStatus)`.
- `onNotesFocused()` também disparado (para scroll/focus management).

---

## 4. Diálogo "Remover foto"

**Classe:** `com.circuit.components.dialog.DialogC2606k`
**Disparo:** long-press (ou tap no "×") sobre miniatura de foto na seção de fotos.

### Estrutura

```
AlertDialog
  título    "Remover foto"
  corpo     "Esta foto será removida da parada permanentemente."
  botão 1   "Remover foto"    (ActionStyle destrutiva)
  botão 2   "Cancelar"        (ActionStyle secundária)
```

### Strings PT-BR verbatim

| Chave | Valor |
|---|---|
| `remove_photo_warning_alert_title` | `"Remover foto"` |
| `remove_photo_warning_alert_body` | `"Esta foto será removida da parada permanentemente."` |
| `cancel` | `"Cancelar"` |

---

## 5. Editores de notas (domínio)

Dois editores concretos, mesma interface `InterfaceC3820a` (`com.circuit.ui.notes.a`):

| Classe | Tipo de entidade | Campo observado | Save interactor |
|---|---|---|---|
| `StopNotesEditor` | `BaseStopId` | `AbstractC2848c.mo7153r().f24244p` (String notas da parada) | `C2942c1.m8809a(stopId, patch)` |
| `BreakNotesEditor` | `BreakId` | `ur0.f136187p` (String notas da pausa) | `C2992z0.m8889b(breakId, patch)` |

- O editor observa o repositório como `Flow<String>` e inicializa o `TextFieldValue` com o texto atual.
- `save()` só persiste se o texto **mudou** (`!wi8.m45958a(original, novo)`).
- Execução em `Dispatchers.IO` (`C24067m.f114664b`).

---

## 6. Fluxo de dados / arquitetura

```
NotesFragment
  └── NotesScreen (Compose)
        └── NotesViewModel
              ├── NotesEditorArgs (sealed: StopNote | BreakNote)  — args via SavedStateHandle
              ├── InterfaceC3820a (StopNotesEditor | BreakNotesEditor)
              │     ├── observe(): Flow<String>  — texto atual
              │     └── save(text): suspend      — persiste se mudou
              ├── x8a<TextFieldValue>  ("NotesTextField" — sobrevive a process death)
              ├── x8a<List<Uri>?>      — fotos (null = seção oculta)
              ├── x8a<Boolean>         — canAddPhoto
              └── GetFeatures          — lê PackagePhotos + ChangeStopNotes
```

---

## Notas de implementação para RotPro

1. **Sem botão "Salvar"**: o save acontece no "Concluído" e no back; não existe botão "Salvar" explícito.
2. **Fotos de pacote** (`PackagePhotos`) são `PlanFeature` (plano pago no Spoke). No RotPro isso mapeia para o paywall — **implementar a seção de fotos somente na Slice 4 ou posterior**; por ora omitir a seção.
3. **O campo de notas sobrevive a process death** via `SavedStateHandle` com key `"NotesTextField"`.
4. **A tela é um BottomSheet de tamanho Medium**, não uma tela full-screen. Flutter equivalente: `showModalBottomSheet` com `isScrollControlled: true` + `DraggableScrollableSheet`, ou `showDialog` com `barrierDismissible: false`.
5. **Save só se mudou**: comparar o texto atual com o texto inicial antes de chamar o update; evitar writes desnecessários.
6. **Break notes** usa o mesmo Fragment com `BreakNote` args — implementar o mesmo widget reutilizando a lógica com o provider correto.
7. **Precisa-runtime**: tamanho real da sheet no M54 + animação de fotos + comportamento com teclado.
