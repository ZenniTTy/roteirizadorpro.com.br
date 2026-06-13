/// Disambiguates which slot of [RouteConfig] the reused `AddStopPage` is
/// being driven by, and carries every per-mode UI flag the page needs to
/// branch on. Adding a fourth mode is therefore a single enum entry +
/// matching values — the widget body's switch over `mode.<flag>` does not
/// require modification.
///
/// Per Spoke baseline 2026-06-02: the Partida/Destino location pickers have a
/// completely empty dark body, no method buttons, no "Desta rota" section, and
/// no "Escolher no mapa" footer. Each divergence is encoded as a flag here so
/// the call site (Detalhes da rota row tap) drives the page entirely via this
/// enum. The search-field placeholder ([hintText]) is an ORIGINAL RotPro
/// string ('Buscar endereço') shared by both location pickers — not Spoke's
/// verbatim 'Insira um endereço' (ADR-0035 forbids cloning Circuit microcopy).
///
/// Also doubles as the keying axis for `searchQueryProvider`,
/// `placeAutocompleteProvider`, and `addStopUiStateProvider` so the
/// Partida picker's search state cannot bleed into the Add Stop flow's
/// (or vice versa) when the user navigates between them. See
/// `lib/features/routes/state/`.
enum PickerMode {
  /// Default add-stop flow: opened from the active-route sheet to append
  /// a new stop to the live route. This is the only mode that surfaces
  /// the "Desta rota" matches, the Mapa/Leitor/Voz method shortcuts, the
  /// empty-state microcopy, and the "Escolher no mapa" footer. Selecting
  /// a result row creates a [Stop] and pops without a return value.
  addStop(
    hintText: 'Digite o endereço da parada',
    resultsSectionHeader: 'Adicionar nova parada',
    showMethodButtonsOnEmpty: true,
    showMicrocopyOnEmpty: true,
    showExistingStopsSection: true,
    showChooseOnMapFooter: true,
  ),

  /// Sub-picker for `Partida` row in Detalhes da rota — selects the
  /// route's [StartLocation]. Spoke renders a bare search-as-topbar over a
  /// black body (no method shortcuts, no route-stops section, no map
  /// footer).
  startLocation(
    hintText: 'Buscar endereço',
    resultsSectionHeader: 'Escolha o novo endereço',
    showMethodButtonsOnEmpty: false,
    showMicrocopyOnEmpty: false,
    showExistingStopsSection: false,
    showChooseOnMapFooter: false,
  ),

  /// Sub-picker for the `Destino` row when the user picks the
  /// "Destino em outro endereço" card in the Destino bottom sheet
  /// (`DestinationPickerSheet`, ADR-0043). Mirrors startLocation's
  /// structural Spoke shape. Pushed from `RouteDetailsPage` via the
  /// `end-location` GoRoute; selecting a result pops a [SpecificAddress]
  /// the page persists through `routeConfigController.setDestination`.
  endLocation(
    hintText: 'Buscar endereço',
    resultsSectionHeader: 'Escolha o novo endereço',
    showMethodButtonsOnEmpty: false,
    showMicrocopyOnEmpty: false,
    showExistingStopsSection: false,
    showChooseOnMapFooter: false,
  ),

  /// Sub-picker for the editor's "Mudar endereço" action (MS-A6 T17/H10).
  /// Pushed from `EditStopPage` via the `change-address` GoRoute nested
  /// under the edit route; selecting a result pops the record
  /// `({double lat, double lng, String streetName, String fullAddress})`
  /// and the editor swaps ONLY those four `Stop` fields. Mirrors the
  /// structural Spoke shape of the location pickers (bare search, no
  /// "Desta rota" section, no map footer).
  changeAddress(
    hintText: 'Buscar endereço',
    resultsSectionHeader: 'Escolha o novo endereço',
    showMethodButtonsOnEmpty: false,
    showMicrocopyOnEmpty: false,
    showExistingStopsSection: false,
    showChooseOnMapFooter: false,
  );

  const PickerMode({
    required this.hintText,
    required this.resultsSectionHeader,
    required this.showMethodButtonsOnEmpty,
    required this.showMicrocopyOnEmpty,
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

  /// When true, the empty-state body shows the
  /// "Adicione (as primeiras|novas) paradas..." instructional copy. Only
  /// the add-stop flow uses it; Partida/Destino keep the body bare.
  final bool showMicrocopyOnEmpty;

  /// When true, the results layout includes the "Desta rota (N)" section
  /// listing stops on the current route whose address matches the query.
  /// Only the add-stop flow shows this; Partida/Destino pickers do not.
  final bool showExistingStopsSection;

  /// When true, the results list ends with a "Escolher no mapa" affordance
  /// linking to the map-based picker. Only the add-stop flow uses it.
  final bool showChooseOnMapFooter;
}
