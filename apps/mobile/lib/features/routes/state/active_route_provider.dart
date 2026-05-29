import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'active_route_provider.g.dart';

/// Holds the id of the route whose shell is currently displayed.
/// `null` means no route selected — the shell shows the placeholder.
@Riverpod(keepAlive: true)
class ActiveRouteId extends _$ActiveRouteId {
  @override
  String? build() => null;

  void setActiveRoute(String? id) => state = id;
}
