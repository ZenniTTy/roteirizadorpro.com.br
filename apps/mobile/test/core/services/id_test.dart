import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/core/services/id.dart';

void main() {
  test('newId returns an RFC 4122 v4 UUID', () {
    final id = newId();

    // UUID v4 format: 8-4-4-4-12, with the version nibble '4' and
    // the variant bits 10xx in the y nibble.
    final pattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    expect(pattern.hasMatch(id), isTrue, reason: 'got $id');
  });

  test('newId is collision-free across many calls', () {
    final ids = <String>{for (var i = 0; i < 1000; i++) newId()};
    expect(ids.length, 1000);
  });
}
