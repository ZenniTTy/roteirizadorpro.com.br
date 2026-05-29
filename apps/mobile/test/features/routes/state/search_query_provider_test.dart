import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/state/search_query_provider.dart';

void main() {
  late ProviderContainer container;
  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  test('initial state is empty string', () {
    expect(container.read(searchQueryProvider), '');
  });

  test('setQuery updates state', () {
    container.read(searchQueryProvider.notifier).setQuery('Av');
    expect(container.read(searchQueryProvider), 'Av');
  });

  test('setQuery to empty string clears state', () {
    container.read(searchQueryProvider.notifier).setQuery('Av');
    container.read(searchQueryProvider.notifier).setQuery('');
    expect(container.read(searchQueryProvider), '');
  });
}
