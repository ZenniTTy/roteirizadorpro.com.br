/// Disambiguates which slot of [RouteConfig] the reused `AddStopPage` is
/// being driven by, and carries every per-mode UI flag the page needs to
/// branch on. Adding a fourth mode is therefore a single enum entry +
/// matching values — the widget body's switch over `mode.<flag>` does not
/// require modification.
///
/// Per Spoke baseline 2026-06-02: the Partida picker has a completely empty
/// dark body, no method buttons, no "Desta rota" section, no
/// "Escolher no mapa" footer, and uses a distinct search-field placeholder.
/// Each divergence is encoded as a flag here so the call site (Detalhes da
/// rota row tap) drives the page entirely via this enum.
///
/// `endLocation` is wired by Slice 2 Area 5 MS5 (DestinationPickerPage).
enum PickerMode {
  /// Sub-picker for `Partida` row in Detalhes da rota — selects the route's
  /// [StartLocation]. Spoke renders a bare search-as-topbar over a black body
  /// (no method shortcuts, no route-stops section, no map footer).
  startLocation(
    hintText: 'Buscar local de partida',
    resultsSectionHeader: 'Escolha o novo endereço',
    showMethodButtonsOnEmpty: false,
    showExistingStopsSection: false,
    showChooseOnMapFooter: false,
  ),

  /// Sub-picker for `Destino` row when the user picks "Selecionar endereço" —
  /// wired by MS5. Mirrors startLocation's structural Spoke shape.
  endLocation(
    hintText: 'Buscar local de destino',
    resultsSectionHeader: 'Escolha o novo endereço',
    showMethodButtonsOnEmpty: false,
    showExistingStopsSection: false,
    showChooseOnMapFooter: false,
  );

  const PickerMode({
    required this.hintText,
    required this.resultsSectionHeader,
    required this.showMethodButtonsOnEmpty,
    required this.showExistingStopsSection,
    required this.showChooseOnMapFooter,
  });

  /// Placeholder shown inside the search field when empty. Drives
  /// `AddStopSearchBar`'s `hintText`.
  final String hintText;

  /// Header label above the new-candidates list. Spoke uses
  /// `Escolha o novo endereço` for both location pickers and
  /// `Adicionar nova parada` for the add-stop flow.
  final String resultsSectionHeader;

  /// When true, the empty-state body renders the Mapa/Leitor/Voz buttons.
  /// Partida + Destino location pickers set this `false` (Spoke empty body).
  final bool showMethodButtonsOnEmpty;

  /// When true, the results layout includes the "Desta rota (N)" section
  /// listing stops on the current route whose address matches the query.
  /// Only the add-stop flow shows this; Partida/Destino pickers do not.
  final bool showExistingStopsSection;

  /// When true, the results list ends with a "Escolher no mapa" affordance
  /// linking to the map-based picker. Only the add-stop flow uses it.
  final bool showChooseOnMapFooter;
}
