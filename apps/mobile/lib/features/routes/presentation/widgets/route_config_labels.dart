import '../../../route_config/domain/route_config.dart';

/// Labels/subtítulos das linhas Início e Destino da step list — compartilhados
/// entre o config-summary (DRAFT) e as views otimizadas (PRE-CONFIRM/Ready), pra
/// a microcopy ser idêntica em um só lugar. As strings PT-BR são verbatim do
/// Spoke (`nnd.m39733i/m39736l/m39730e`): o Início muda entre DRAFT e otimizado;
/// o Destino é igual nos dois.

/// Linha principal do Início. Endereço custom quando definido; senão o
/// placeholder do estado: DRAFT "Iniciar no local atual" / otimizado
/// "Ponto de partida".
String startLabel(StartLocation? loc, {required bool optimized}) {
  if (loc != null && !loc.isUserCurrentLocation) return loc.address;
  return optimized ? 'Ponto de partida' : 'Iniciar no local atual';
}

/// Subtítulo do Início, por estado.
String startSubtitle({required bool optimized}) => optimized
    ? 'Posição do GPS usada ao otimizar'
    : 'Use a posição do GPS ao otimizar';

/// Linha principal do Destino. RoundTrip (default) = "Ida e volta".
String destinationLabel(Destination? destination) {
  return switch (destination) {
    null || RoundTrip() => 'Ida e volta',
    SpecificAddress(:final address) => address,
    NoDestination() => 'Nenhum destino',
  };
}

/// Subtítulo do Destino. RoundTrip usa "Retorne ao ponto de partida"; as outras
/// variantes não têm subtítulo na lista.
String? destinationSubtitle(Destination? destination) {
  return switch (destination) {
    null || RoundTrip() => 'Retorne ao ponto de partida',
    SpecificAddress() => null,
    NoDestination() => null,
  };
}
