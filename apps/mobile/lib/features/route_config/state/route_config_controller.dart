import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/route_config.dart';

part 'route_config_controller.g.dart';

/// Per-route configuration controller. Family-keyed by `routeId` so that
/// switching between routes (e.g. driver opens route A's wizard then route
/// B's) does not leak state across them. `autoDispose` (default for
/// `@riverpod`) drops the state when no listener remains.
@riverpod
class RouteConfigController extends _$RouteConfigController {
  @override
  RouteConfig build(String routeId) => RouteConfig.empty();

  void setStartLocation(StartLocation? value) {
    state = state.withStartLocation(value);
  }

  void setTimeStart(TimeStart? value) {
    state = state.withTimeStart(value);
  }

  void setTimeEnd(TimeEnd? value) {
    state = state.withTimeEnd(value);
  }

  void setDestination(Destination? value) {
    state = state.withDestination(value);
  }

  void addBreak(BreakConfig value) {
    state = state.withBreaks([...state.breaks, value]);
  }

  void updateBreak(int index, BreakConfig value) {
    final next = [...state.breaks];
    next[index] = value;
    state = state.withBreaks(next);
  }

  void removeBreak(int index) {
    final next = [...state.breaks]..removeAt(index);
    state = state.withBreaks(next);
  }

  void clear() {
    state = RouteConfig.empty();
  }
}

/// Reactive derived bool — `true` when the underlying [RouteConfig] is in a
/// shippable state (both times set, end after start).
@riverpod
bool isRouteConfigValid(Ref ref, String routeId) {
  final config = ref.watch(routeConfigControllerProvider(routeId));
  return config.isValid;
}
