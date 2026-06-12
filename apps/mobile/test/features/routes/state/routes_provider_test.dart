import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/domain/route.dart' as domain;
import 'package:roteirizador_pro/features/routes/domain/stop.dart';
import 'package:roteirizador_pro/features/routes/state/routes_provider.dart';
import '../_helpers/fake_package_photo_store.dart';

// ---------------------------------------------------------------------------
// Helpers de semeadura
// ---------------------------------------------------------------------------

/// Cria um container com FakePackagePhotoStore já sobrescrito.
ProviderContainer _makeContainer(FakePackagePhotoStore fakeStore) {
  final c = ProviderContainer(
    overrides: [
      packagePhotoStoreProvider.overrideWithValue(fakeStore),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

/// Stop mínimo válido.
Stop _stop({
  required String id,
  String? notes,
  int? positionInRoute,
  String? deliveryId,
  StopStatus status = StopStatus.pending,
  List<String> photoPaths = const [],
}) =>
    Stop(
      id: id,
      lat: -23.5,
      lng: -46.6,
      streetName: 'Rua Teste',
      fullAddress: 'Rua Teste, 1 — SP',
      notes: notes,
      positionInRoute: positionInRoute,
      deliveryId: deliveryId,
      status: status,
      photoPaths: photoPaths,
    );

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  test('build() returns a non-empty list of routes', () {
    final routes = container.read(routesProvider);
    expect(routes, isNotEmpty);
  });

  test('all routes have unique ids', () {
    final routes = container.read(routesProvider);
    final ids = routes.map((r) => r.id).toList();
    expect(ids.toSet().length, equals(ids.length));
  });

  test('all items are Route instances', () {
    final routes = container.read(routesProvider);
    expect(routes, everyElement(isA<domain.Route>()));
  });

  group('createRoute', () {
    test('appends a new draft route with the returned id', () {
      final notifier = container.read(routesProvider.notifier);
      final initialCount = container.read(routesProvider).length;
      final date = DateTime(2026, 6, 1);

      final id = notifier.createRoute(name: 'Minha rota', date: date);

      final after = container.read(routesProvider);
      expect(after.length, initialCount + 1);
      final created = after.firstWhere((r) => r.id == id);
      expect(created.name, 'Minha rota');
      expect(created.date, date);
      expect(created.status, domain.RouteStatus.draft);
      expect(created.stops, isEmpty);
    });

    test('null name leaves the route nameless (placeholder used downstream)',
        () {
      final notifier = container.read(routesProvider.notifier);
      final id = notifier.createRoute(name: null, date: DateTime(2026, 6, 2));
      final created =
          container.read(routesProvider).firstWhere((r) => r.id == id);
      expect(created.name, isNull);
    });

    test('generates distinct ids across consecutive calls', () async {
      final notifier = container.read(routesProvider.notifier);
      final id1 = notifier.createRoute(date: DateTime(2026, 6, 3));
      await Future<void>.delayed(const Duration(milliseconds: 2));
      final id2 = notifier.createRoute(date: DateTime(2026, 6, 4));
      expect(id1, isNot(equals(id2)));
    });
  });

  group('updateRouteMeta', () {
    test('updates name and date but preserves stops + status', () {
      final notifier = container.read(routesProvider.notifier);
      final id = notifier.createRoute(
        name: 'Original',
        date: DateTime(2026, 6, 5),
      );
      final original =
          container.read(routesProvider).firstWhere((r) => r.id == id);
      final newDate = DateTime(2026, 6, 10);
      notifier.updateRouteMeta(id, name: 'Editado', date: newDate);

      final updated =
          container.read(routesProvider).firstWhere((r) => r.id == id);
      expect(updated.name, 'Editado');
      expect(updated.date, newDate);
      expect(updated.status, original.status);
      expect(updated.stops, original.stops);
    });

    test(
        'null name actually clears the saved name (regression: must NOT '
        'preserve via copyWith null-fallback)', () {
      final notifier = container.read(routesProvider.notifier);
      final id = notifier.createRoute(
        name: 'Original',
        date: DateTime(2026, 6, 6),
      );
      notifier.updateRouteMeta(id, name: null, date: DateTime(2026, 6, 6));
      final updated =
          container.read(routesProvider).firstWhere((r) => r.id == id);
      expect(updated.name, isNull);
    });

    test('no-op when id does not match any route', () {
      final notifier = container.read(routesProvider.notifier);
      final before = container.read(routesProvider);
      notifier.updateRouteMeta(
        'nonexistent-id',
        name: 'whatever',
        date: DateTime(2026, 6, 7),
      );
      final after = container.read(routesProvider);
      expect(after, equals(before));
    });
  });

  // ---------------------------------------------------------------------------
  // T4 — mutações de stop: updateStop / removeStop / duplicateStop
  // ---------------------------------------------------------------------------

  group('updateStop', () {
    test(
        'substitui o stop pelo id preservando ordem e demais stops intactos '
        '(H9)', () {
      final fakeStore = FakePackagePhotoStore();
      final c = _makeContainer(fakeStore);
      final notifier = c.read(routesProvider.notifier);

      final id = notifier.createRoute(date: DateTime(2026, 6, 1));
      final s1 = _stop(id: 's1', notes: 'primeiro');
      final s2 = _stop(id: 's2', notes: 'meio');
      final s3 = _stop(id: 's3', notes: 'ultimo');
      notifier.addStop(id, s1);
      notifier.addStop(id, s2);
      notifier.addStop(id, s3);

      final updated = _stop(id: 's2', notes: 'meio-editado');
      notifier.updateStop(id, updated);

      final route = c.read(routesProvider).firstWhere((r) => r.id == id);
      expect(route.stops.length, 3);
      expect(route.stops[0].id, 's1');
      expect(route.stops[1].id, 's2');
      expect(route.stops[1].notes, 'meio-editado');
      expect(route.stops[2].id, 's3');
    });

    test('stop.id inexistente na rota é no-op — state inalterado', () {
      final fakeStore = FakePackagePhotoStore();
      final c = _makeContainer(fakeStore);
      final notifier = c.read(routesProvider.notifier);

      final id = notifier.createRoute(date: DateTime(2026, 6, 2));
      final s1 = _stop(id: 's1');
      notifier.addStop(id, s1);
      final before = c.read(routesProvider);

      notifier.updateStop(id, _stop(id: 'nao-existe'));

      final after = c.read(routesProvider);
      expect(
        after.firstWhere((r) => r.id == id).stops.length,
        before.firstWhere((r) => r.id == id).stops.length,
      );
    });
  });

  group('removeStop', () {
    test(
        'remove o stop da lista e chama deleteFor(routeId, stopId) '
        'exatamente 1× (H11)', () async {
      final fakeStore = FakePackagePhotoStore();
      final c = _makeContainer(fakeStore);
      final notifier = c.read(routesProvider.notifier);

      final id = notifier.createRoute(date: DateTime(2026, 6, 3));
      notifier.addStop(id, _stop(id: 'del-stop'));

      notifier.removeStop(id, 'del-stop');
      // deixa microtasks do deleteFor (async) completarem
      await Future<void>.value();

      final route = c.read(routesProvider).firstWhere((r) => r.id == id);
      expect(route.stops, isEmpty);
      expect(fakeStore.deleteForCalls, hasLength(1));
      expect(fakeStore.deleteForCalls.first, (id, 'del-stop'));
    });

    test('stopId inexistente é no-op e deleteFor NÃO é chamado', () async {
      final fakeStore = FakePackagePhotoStore();
      final c = _makeContainer(fakeStore);
      final notifier = c.read(routesProvider.notifier);

      final id = notifier.createRoute(date: DateTime(2026, 6, 4));
      notifier.addStop(id, _stop(id: 'real-stop'));
      final before =
          c.read(routesProvider).firstWhere((r) => r.id == id).stops.length;

      notifier.removeStop(id, 'fantasma');
      await Future<void>.value();

      final after =
          c.read(routesProvider).firstWhere((r) => r.id == id).stops.length;
      expect(after, before);
      expect(fakeStore.deleteForCalls, isEmpty);
    });
  });

  group('duplicateStop', () {
    test(
        'retorna id novo != original e a duplicata aparece imediatamente após '
        'o original (índice+1) com status pending, deliveryId null e '
        'positionInRoute null (H16 — campos obrigatórios)', () {
      final fakeStore = FakePackagePhotoStore();
      final c = _makeContainer(fakeStore);
      final notifier = c.read(routesProvider.notifier);

      final routeId = notifier.createRoute(date: DateTime(2026, 6, 5));
      final original = _stop(
        id: 'orig',
        positionInRoute: 3,
        deliveryId: 'A1',
        status: StopStatus.delivered,
        notes: 'notas-orig',
      );
      notifier.addStop(routeId, original);

      final newId = notifier.duplicateStop(routeId, 'orig');

      expect(newId, isNotNull);
      expect(newId, isNot('orig'));

      final route = c.read(routesProvider).firstWhere((r) => r.id == routeId);
      expect(route.stops.length, 2);
      expect(route.stops[0].id, 'orig');
      expect(route.stops[1].id, newId);

      final dup = route.stops[1];
      expect(dup.status, StopStatus.pending);
      expect(dup.deliveryId, isNull);
      expect(dup.positionInRoute, isNull);
    });

    test(
        'duplicata copia demais campos do original (notes, lat/lng, '
        'streetName, fullAddress)', () {
      final fakeStore = FakePackagePhotoStore();
      final c = _makeContainer(fakeStore);
      final notifier = c.read(routesProvider.notifier);

      final routeId = notifier.createRoute(date: DateTime(2026, 6, 6));
      final original = _stop(id: 'orig2', notes: 'entrega especial');
      notifier.addStop(routeId, original);

      final newId = notifier.duplicateStop(routeId, 'orig2');
      expect(newId, isNotNull);

      final dup =
          c.read(routesProvider).firstWhere((r) => r.id == routeId).stops[1];
      expect(dup.notes, 'entrega especial');
      expect(dup.lat, original.lat);
      expect(dup.lng, original.lng);
      expect(dup.streetName, original.streetName);
      expect(dup.fullAddress, original.fullAddress);
    });

    test(
        'após patch assíncrono de fotos a duplicata tem os photoPaths da '
        'cópia e copyAllCalls registra (routeId, idOriginal, idNovo) (H16)',
        () async {
      final fakeStore = FakePackagePhotoStore();
      fakeStore.copyAllResult = ['novo1.jpg', 'novo2.jpg'];
      final c = _makeContainer(fakeStore);
      final notifier = c.read(routesProvider.notifier);

      final routeId = notifier.createRoute(date: DateTime(2026, 6, 7));
      final original = _stop(id: 'foto-orig', photoPaths: ['a.jpg', 'b.jpg']);
      notifier.addStop(routeId, original);

      final newId = notifier.duplicateStop(routeId, 'foto-orig');
      expect(newId, isNotNull);

      // aguarda o patch assíncrono de fotos (copyAll) completar
      await Future<void>.delayed(Duration.zero);

      final dup =
          c.read(routesProvider).firstWhere((r) => r.id == routeId).stops[1];
      expect(dup.photoPaths, ['novo1.jpg', 'novo2.jpg']);
      expect(fakeStore.copyAllCalls, hasLength(1));
      expect(fakeStore.copyAllCalls.first, (routeId, 'foto-orig', newId));
    });

    test(
        'stopId inexistente retorna null, state inalterado e copyAll não '
        'é chamado', () {
      final fakeStore = FakePackagePhotoStore();
      final c = _makeContainer(fakeStore);
      final notifier = c.read(routesProvider.notifier);

      final routeId = notifier.createRoute(date: DateTime(2026, 6, 8));
      notifier.addStop(routeId, _stop(id: 'real'));
      final before = c
          .read(routesProvider)
          .firstWhere((r) => r.id == routeId)
          .stops
          .length;

      final result = notifier.duplicateStop(routeId, 'fantasma');

      expect(result, isNull);
      final after = c
          .read(routesProvider)
          .firstWhere((r) => r.id == routeId)
          .stops
          .length;
      expect(after, before);
      expect(fakeStore.copyAllCalls, isEmpty);
    });
  });
}
