import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../application/add_stop_ui_state.dart';
import 'current_route_stops_provider.dart';
import 'place_autocomplete_provider.dart';
import 'search_query_provider.dart';

part 'add_stop_ui_state_provider.g.dart';

/// Single source of truth for `AddStopPage`'s render branch.
/// Composes 3 upstream providers via `AddStopUiState.from`.
@riverpod
AddStopUiState addStopUiState(Ref ref) {
  final query = ref.watch(searchQueryProvider);
  final predictions = ref.watch(placeAutocompleteProvider);
  final routeStops = ref.watch(currentRouteStopsProvider);
  return AddStopUiState.from(
    query: query,
    predictions: predictions,
    routeStops: routeStops,
  );
}
