import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:roteirizador_pro/features/routes/domain/route_geometry.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';

Stop _stop(String id, double lat, double lng) =>
    Stop(id: id, lat: lat, lng: lng, streetName: id, fullAddress: id);

Set<Polyline> _shellPolylines({
  required bool isPreConfirm,
  required List<Stop> stops,
}) =>
    isPreConfirm
        ? buildRoutePolylines(
            routePolylinePoints(stops),
            fill: Colors.blue,
            border: Colors.white,
          )
        : const {};

void main() {
  final stops = [_stop('a', -23.5, -46.6), _stop('b', -23.4, -46.5)];

  test('PRE-CONFIRM → polyline não-vazia', () {
    expect(_shellPolylines(isPreConfirm: true, stops: stops), isNotEmpty);
  });

  test('DRAFT → polyline vazia', () {
    expect(_shellPolylines(isPreConfirm: false, stops: stops), isEmpty);
  });
}
