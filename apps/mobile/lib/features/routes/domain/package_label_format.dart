/// Formato do identificador de parada (chip "A1" vs "1"). Espelha
/// `PackageLabelFormat.kt` do Spoke {BASE/Clássico, MODERN/Moderno}. O Spoke
/// usa Clássico como fallback (`a4e.java:16`); o RotPro usa Moderno como
/// default por escolha de produto (mais legível para etiquetar pacotes). O
/// toggle Moderno/Clássico vive na Área 10 (ainda não feita).
enum PackageLabelFormat {
  moderno,
  classico;

  static const PackageLabelFormat defaultFormat = PackageLabelFormat.moderno;

  /// Rótulo 1-based para a parada na posição [index] (0-based) da ordem
  /// otimizada. Moderno: a letra muda a cada bloco de 26 e o número é 1-based
  /// DENTRO do bloco (A1..A26, B1..). Clássico: número puro (1, 2, ...).
  String labelFor(int index) {
    switch (this) {
      case PackageLabelFormat.classico:
        return '${index + 1}';
      case PackageLabelFormat.moderno:
        final letter = String.fromCharCode(65 + (index ~/ 26));
        final number = index % 26 + 1;
        return '$letter$number';
    }
  }
}
