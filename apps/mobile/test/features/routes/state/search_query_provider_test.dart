import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/route_config/state/picker_mode.dart';
import 'package:roteirizador_pro/features/routes/state/search_query_provider.dart';

void main() {
  late ProviderContainer container;
  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  test('initial state is empty string (addStop mode)', () {
    expect(container.read(searchQueryProvider(PickerMode.addStop)), '');
  });

  test('setQuery updates state (addStop mode)', () {
    container
        .read(searchQueryProvider(PickerMode.addStop).notifier)
        .setQuery('Av');
    expect(container.read(searchQueryProvider(PickerMode.addStop)), 'Av');
  });

  test('setQuery to empty string clears state (addStop mode)', () {
    container
        .read(searchQueryProvider(PickerMode.addStop).notifier)
        .setQuery('Av');
    container
        .read(searchQueryProvider(PickerMode.addStop).notifier)
        .setQuery('');
    expect(container.read(searchQueryProvider(PickerMode.addStop)), '');
  });

  // Regression: PickerMode-keyed isolation — MS3 cleanup 2026-06-02.
  test('typing in startLocation does not leak into addStop (and vice versa)',
      () {
    container
        .read(searchQueryProvider(PickerMode.startLocation).notifier)
        .setQuery('Buscar Av');
    container
        .read(searchQueryProvider(PickerMode.addStop).notifier)
        .setQuery('Adicionar Rua');

    expect(
      container.read(searchQueryProvider(PickerMode.startLocation)),
      'Buscar Av',
    );
    expect(
      container.read(searchQueryProvider(PickerMode.addStop)),
      'Adicionar Rua',
    );
    // endLocation stays untouched.
    expect(container.read(searchQueryProvider(PickerMode.endLocation)), '');
  });
}
