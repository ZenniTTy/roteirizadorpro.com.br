import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_query_provider.g.dart';

/// Mirrors the live text in the add-stop search field.
/// `AddStopSearchBar` writes here on `onChanged`; `addStopUiStateProvider` reads
/// to drive state derivation (empty branch overrides stale loading async).
@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  void setQuery(String value) {
    state = value;
  }
}
