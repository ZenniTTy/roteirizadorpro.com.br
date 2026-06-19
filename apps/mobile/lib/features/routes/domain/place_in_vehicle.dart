/// Eixo lateral do veículo (fato F11, dump v3.65.1).
enum PlaceX { left, right }

/// Eixo longitudinal do veículo (F11).
enum PlaceY { front, middle, back }

/// Eixo vertical do veículo (F11).
enum PlaceZ { floor, shelf }

/// Value object imutável com a localização do pacote no veículo (F11).
/// Componentes todos-nulos são válidos ("Não definido").
class PlaceInVehicle {
  const PlaceInVehicle({this.x, this.y, this.z});

  final PlaceX? x;
  final PlaceY? y;
  final PlaceZ? z;

  /// Código curto: iniciais dos eixos DEFINIDOS na ordem Y, X, Z;
  /// `null` quando nenhum eixo está definido (F11).
  ///
  /// As iniciais derivam da microcopy PT-BR:
  /// Frente/Meio/Atrás → F/M/A · Esquerda/Direita → E/D ·
  /// Chão/Prateleira → C/P.
  String? get shortCode {
    if (x == null && y == null && z == null) return null;
    final buffer = StringBuffer();
    switch (y) {
      case PlaceY.front:
        buffer.write('F');
      case PlaceY.middle:
        buffer.write('M');
      case PlaceY.back:
        buffer.write('A');
      case null:
        break;
    }
    switch (x) {
      case PlaceX.left:
        buffer.write('E');
      case PlaceX.right:
        buffer.write('D');
      case null:
        break;
    }
    switch (z) {
      case PlaceZ.floor:
        buffer.write('C');
      case PlaceZ.shelf:
        buffer.write('P');
      case null:
        break;
    }
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaceInVehicle && other.x == x && other.y == y && other.z == z;

  @override
  int get hashCode => Object.hash(x, y, z);
}
