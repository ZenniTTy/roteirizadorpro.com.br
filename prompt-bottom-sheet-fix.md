# Problema no Bottom Sheet do Route Shell Page

O `DraggableScrollableSheet` em `apps/mobile/lib/features/routes/presentation/route_shell_page.dart` (chamado de `_ActiveRouteSheet`) não está reproduzindo o comportamento de drag (arraste) esperado, semelhante à tela da Spoke.

**Comportamentos esperados:**
1. Deve possuir 3 estados de altura (`snapSizes`):
   - **Pequeno:** Exibe apenas a pílula de busca ("Adicionar parada...") e o botão Kebab.
   - **Médio:** Exibe a pílula + 2 botões grandes verticais ("Adicionar paradas" e "Copiar paradas de uma rota anterior").
   - **Grande:** Ocupa grande parte da tela exibindo a lista de paradas (caso hajam).
2. O problema crônico: A área em branco/vazia abaixo do conteúdo não permite arrastar o Bottom Sheet para cima. O toque passa reto ou é ignorado. Em um `DraggableScrollableSheet`, o drag só é acionado se for disparado em um item de lista que propaga o scroll. 
3. Precisamos garantir que isso funcione na prática no aparelho e passe na validação do script Maestro `apps/mobile/scripts/test_drag.yaml`.

**O que já foi tentado e gerou o mesmo problema de toque fantasma ou quebras de tela:**
- Tentar usar `SingleChildScrollView` + `ConstrainedBox` com o `minHeight` preenchendo a tela.
- Tentar usar `ListView` com `AlwaysScrollableScrollPhysics` inserindo um `Container` transparente com a altura da tela no final do array de `children`.

**Seu Objetivo como Agent:**
Pesquise referências modernas (Context7/WebSearch) de como forçar o `DraggableScrollableSheet` do Flutter a capturar gestos de arraste (drag) em áreas vazias sem usar hacks que afetem as constraints, ou utilize pacotes de comportamento consagrado (como `snapping_sheet` ou `modal_bottom_sheet`) caso o widget nativo não dê conta desse caso com pouco conteúdo interno no estado inicial. Mantenha os mesmos ícones Lucide, fontes menores e botões roxos gradientes.
