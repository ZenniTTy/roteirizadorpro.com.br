import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/application/add_stop_ui_state.dart';

void main() {
  group('AddStopUiState sealed hierarchy', () {
    test('EmptyVariant carries stopCount', () {
      const s = EmptyVariant(stopCount: 3);
      expect(s.stopCount, 3);
    });

    test('ZeroResults is a const value (no payload)', () {
      const a = ZeroResults();
      const b = ZeroResults();
      expect(
        identical(a, b),
        isTrue,
        reason: 'const-equal sentinels should share instance',
      );
    });

    test('Loading is a const value (no payload)', () {
      const a = Loading();
      const b = Loading();
      expect(identical(a, b), isTrue);
    });
  });
}
