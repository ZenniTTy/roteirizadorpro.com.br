import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:roteirizador_pro/features/routes/domain/route_geometry.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';

Stop _stop(String id, double lat, double lng) =>
    Stop(id: id, lat: lat, lng: lng, streetName: id, fullAddress: id);

void main() {
  test('mapeia stops para LatLng na ordem da lista', () {
    final pts = routePolylinePoints([
      _stop('a', -23.5, -46.6),
      _stop('b', -23.4, -46.5),
    ]);
    expect(pts, [const LatLng(-23.5, -46.6), const LatLng(-23.4, -46.5)]);
  });

  test('lista vazia => vazio; 1 stop => 1 ponto', () {
    expect(routePolylinePoints([]), isEmpty);
    expect(routePolylinePoints([_stop('a', 1, 2)]), [const LatLng(1, 2)]);
  });

  test('ignora stops marcados pendingRemoval (saem na próxima otimização)', () {
    final pts = routePolylinePoints([
      _stop('a', 1, 2),
      _stop('b', 3, 4).copyWith(pendingRemoval: true),
    ]);
    expect(pts, [const LatLng(1, 2)]);
  });
}
