import '../domain/place_autocomplete_prediction.dart';
import '../domain/stop.dart';

/// UI state for `AddStopPage` derived from (query, autocomplete async, route stops).
/// Pattern-match exhaustively in the widget via `switch (state)` — Dart compiler
/// will catch missing branches.
///
/// Spoke parity §10.21 + §11.4 (amended 2026-05-28):
/// - 3 content states (empty / zero-result / with-results) — not 2.
/// - 2 result sections (Desta rota + Adicionar nova).
/// - Empty microcopy varies with `stopCount`.
sealed class AddStopUiState {
  const AddStopUiState();
}

/// `query.isEmpty` — show microcopy + 3 method shortcut buttons.
/// Microcopy varies: 0 stops → "Adicione as primeiras paradas..."; ≥1 stop →
/// "Adicione novas paradas ou encontre paradas na rota".
final class EmptyVariant extends AddStopUiState {
  const EmptyVariant({required this.stopCount});
  final int stopCount;
}

/// `query.isNotEmpty && async.isLoading` — debounced request in-flight.
final class Loading extends AddStopUiState {
  const Loading();
}

/// `query.isNotEmpty && async.hasError` — autocomplete network/API error.
final class ErrorState extends AddStopUiState {
  const ErrorState(this.error);
  final Object error;
}

/// `query.isNotEmpty && async.hasData && data.isEmpty` — no candidates returned.
final class ZeroResults extends AddStopUiState {
  const ZeroResults();
}

/// `query.isNotEmpty && async.hasData && data.isNotEmpty` — split into 2 sections.
final class WithResults extends AddStopUiState {
  const WithResults({
    required this.matchesInRoute,
    required this.newCandidates,
  });
  final List<Stop> matchesInRoute;
  final List<PlaceAutocompletePrediction> newCandidates;
}
