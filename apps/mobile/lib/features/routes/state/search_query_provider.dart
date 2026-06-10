import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../route_config/state/picker_mode.dart';

part 'search_query_provider.g.dart';

/// Mirrors the live text in the add-stop search field. Family-keyed by
/// [PickerMode] so the Partida sub-picker's typed text cannot bleed into
/// the Add Stop flow (or vice versa) when the user navigates between
/// pickers without explicitly clearing the field.
///
/// `AddStopSearchBar` writes here on `onChanged`; `addStopUiStateProvider`
/// reads to drive state derivation (empty branch overrides stale loading
/// async).
@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build(PickerMode mode) => '';

  void setQuery(String value) {
    state = value;
  }
}
