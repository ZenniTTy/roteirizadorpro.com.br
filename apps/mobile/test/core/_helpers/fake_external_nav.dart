import 'package:roteirizador_pro/core/services/external_nav.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';

/// Shared fake for ExternalNav. Records call arguments without invoking
/// url_launcher; use via `externalNavProvider.overrideWithValue(fake)`
/// in widget tests (same pattern as FakeAppPermissions and
/// FakeStopsRepository).
class FakeExternalNav implements ExternalNav {
  FakeExternalNav({
    this.openInGoogleMapsResult = true,
    this.openInWazeResult = true,
  });

  bool openInGoogleMapsResult;
  bool openInWazeResult;

  final List<List<Stop>> googleMapsCalls = [];
  final List<Stop> wazeCalls = [];

  @override
  Future<bool> openInGoogleMaps(List<Stop> stops) async {
    googleMapsCalls.add(List.unmodifiable(stops));
    return openInGoogleMapsResult;
  }

  @override
  Future<bool> openInWaze(Stop stop) async {
    wazeCalls.add(stop);
    return openInWazeResult;
  }
}
