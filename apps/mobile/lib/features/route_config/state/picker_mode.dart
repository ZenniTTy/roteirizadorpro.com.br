/// Disambiguates which slot of [RouteConfig] the reused `AddStopPage`
/// (MS3) is being driven by. The page's search/typeahead pipeline is
/// identical for both modes — only the AppBar title and action label
/// change.
enum PickerMode { startLocation, endLocation }
