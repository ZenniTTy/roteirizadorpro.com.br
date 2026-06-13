/// Dimensão do pacote (fato F11, dump v3.65.1).
enum PackageDimension { small, medium, large }

/// Tipo do pacote (fato F11, dump v3.65.1).
enum PackageType { box, bag, letter }

/// Value object imutável com dimensão e tipo do pacote (F11).
/// Componentes todos-nulos são válidos ("Não definido").
class PackageDetails {
  const PackageDetails({this.dimension, this.type});

  final PackageDimension? dimension;
  final PackageType? type;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PackageDetails &&
          other.dimension == dimension &&
          other.type == type;

  @override
  int get hashCode => Object.hash(dimension, type);
}
