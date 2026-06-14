// test/features/routes/domain/package_label_format_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/domain/package_label_format.dart';

void main() {
  test('moderno gera A1..A26, B1.. (letra por dezena + 1-based)', () {
    expect(PackageLabelFormat.moderno.labelFor(0), 'A1');
    expect(PackageLabelFormat.moderno.labelFor(9), 'A10');
    expect(PackageLabelFormat.moderno.labelFor(25), 'A26');
    expect(PackageLabelFormat.moderno.labelFor(26), 'B1');
  });

  test('classico gera número puro 1-based', () {
    expect(PackageLabelFormat.classico.labelFor(0), '1');
    expect(PackageLabelFormat.classico.labelFor(9), '10');
  });

  test('moderno é o default declarado da Á7', () {
    expect(PackageLabelFormat.defaultFormat, PackageLabelFormat.moderno);
  });
}
