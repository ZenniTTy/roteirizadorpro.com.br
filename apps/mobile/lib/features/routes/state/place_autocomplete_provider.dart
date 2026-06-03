import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../route_config/state/picker_mode.dart';
import '../data/repositories/places_repository.dart';
import '../domain/place_autocomplete_prediction.dart';

part 'place_autocomplete_provider.g.dart';

/// Debounced Places autocomplete results for the add-stop search field.
/// Family-keyed by [PickerMode] so each picker (Add Stop vs Partida vs
/// Destino) keeps its own debounce timer and result list — switching
/// pickers does not cancel an in-flight call belonging to the other.
@riverpod
class PlaceAutocomplete extends _$PlaceAutocomplete {
  Timer? _debounce;

  @override
  FutureOr<List<PlaceAutocompletePrediction>> build(PickerMode mode) {
    ref.onDispose(() {
      _debounce?.cancel();
    });
    return [];
  }

  void search(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      state = const AsyncData([]);
      return;
    }

    state = const AsyncLoading();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final repository = ref.read(placesRepositoryProvider);
        final results = await repository.autocomplete(query);
        state = AsyncData(results);
      } catch (e, st) {
        state = AsyncError(e, st);
      }
    });
  }
}
