import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../route_config/state/picker_mode.dart';
import '../application/add_stop_ui_state.dart';
import 'current_route_stops_provider.dart';
import 'place_autocomplete_provider.dart';
import 'search_query_provider.dart';

part 'add_stop_ui_state_provider.g.dart';

/// Single source of truth for `AddStopPage`'s render branch.
/// Composes 3 upstream providers via `AddStopUiState.from`.
///
/// Family-keyed by [PickerMode] so each picker (Add Stop / Partida /
/// Destino) derives its own branch from its own search-query and
/// autocomplete state. `currentRouteStopsProvider` stays unkeyed — Section
/// A is only ever rendered in `mode == PickerMode.addStop`, so the
/// always-live active-route view is the right shape for every mode.
@riverpod
AddStopUiState addStopUiState(Ref ref, PickerMode mode) {
  final query = ref.watch(searchQueryProvider(mode));
  final predictions = ref.watch(placeAutocompleteProvider(mode));
  final routeStops = ref.watch(currentRouteStopsProvider);
  return AddStopUiState.from(
    query: query,
    predictions: predictions,
    routeStops: routeStops,
  );
}
