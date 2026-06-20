// test/features/routes/domain/route_pr_c_test.dart
//
// TDD red — PR-C sub-unidade 1: campo optimizedStopsSnapshot em Route.
//
// Comportamentos pinados (lesson_copywith_nullable_field_pitfall):
//  - copyWith omitido ⇒ preserva snapshot anterior
//  - copyWith com lista não-nula ⇒ seta snapshot
//  - copyWith com null explícito ⇒ LIMPA snapshot (sentinela _omit)
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/domain/route.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';

Stop _stop(String id) => Stop(
      id: id,
      lat: 0,
      lng: 0,
      streetName: id,
      fullAddress: id,
    );

void main() {
  group('Route.optimizedStopsSnapshot — novo campo nullable (PR-C)', () {
    test(
      'Route nasce com optimizedStopsSnapshot=null (sem otimização ainda)',
      () {
        final r = Route(id: 'r1', date: DateTime(2026, 6, 20));
        expect(r.optimizedStopsSnapshot, isNull);
      },
    );

    test(
      'copyWith omitido preserva o snapshot anterior',
      () {
        final snapshot = [_stop('A'), _stop('B')];
        final r = Route(
          id: 'r1',
          date: DateTime(2026, 6, 20),
          optimizedStopsSnapshot: snapshot,
        );
        // omite optimizedStopsSnapshot no copyWith
        final next = r.copyWith(name: 'mudei so o nome');
        expect(next.optimizedStopsSnapshot, same(snapshot));
      },
    );

    test(
      'copyWith com lista não-nula seta o snapshot',
      () {
        final r = Route(id: 'r1', date: DateTime(2026, 6, 20));
        final snapshot = [_stop('X'), _stop('Y'), _stop('Z')];
        final next = r.copyWith(optimizedStopsSnapshot: snapshot);
        expect(next.optimizedStopsSnapshot, snapshot);
      },
    );

    test(
      'copyWith com null explícito LIMPA o snapshot (sentinela _omit — '
      'lesson_copywith_nullable_field_pitfall)',
      () {
        final snapshot = [_stop('A')];
        final r = Route(
          id: 'r1',
          date: DateTime(2026, 6, 20),
          optimizedStopsSnapshot: snapshot,
        );
        // passa null explícito: deve limpar, não preservar
        final next = r.copyWith(optimizedStopsSnapshot: null);
        expect(next.optimizedStopsSnapshot, isNull);
      },
    );
  });
}
