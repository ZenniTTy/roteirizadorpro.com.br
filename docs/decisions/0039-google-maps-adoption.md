# ADR-0039: Google Maps SDK Adoption (M2 Parity Pivot)

- **Status:** Accepted
- **Date:** 2026-05-27
- **Deciders:** Eduardo
- **Related ADRs:** ADR-0035 (Spoke Parity Pivot), ADR-0016 (Deprecated: Map Library Policy)

## Context

Na M1, o aplicativo adotou a biblioteca `flutter_map` (OpenStreetMap) e evitou o Google Maps para minimizar custos e evitar o lock-in de vendors. A política estava oficializada na ADR-0016.
No entanto, na M2, o projeto pivotou estruturalmente para um clone 100% fiel do app Spoke (ADR-0035 e ROADMAP-v2). A auditoria de inventário (`docs/inventory/2026-05-26-spoke-vs-rotpro.md`) confirmou que o Spoke utiliza o Google Maps SDK como camada base (TextureView) em suas telas.

Para manter a equivalência estrita de comportamento visual e fluidez (que os entregadores esperam), precisamos descontinuar o uso do `flutter_map` e adotar o pacote oficial `google_maps_flutter`. O roadmap v2 já especificava explicitamente o uso deste pacote para M2.

## Decision

1. **Descontinuar o `flutter_map`** e `latlong2` em favor do pacote oficial `google_maps_flutter`.
2. O uso do Google Maps SDK substitui a política estabelecida pela ADR-0016. A restrição de uso de "Free Tier only" agora se apoia no limite mensal gratuito ($200) da Google Maps Platform; caso o limite seja ultrapassado no futuro, revisaremos os custos.
3. A API Key (`com.google.android.geo.API_KEY`) no Android deverá ser injetada via `local.properties` (fora de controle de versão), utilizando `manifestPlaceholders`. No iOS, deverá ser injetada no `AppDelegate.swift` conforme padrão oficial do Flutter.

## Consequences

- **Positivo:** UI mais parecida com o Spoke, desempenho robusto nativo em mapas, renderização de POIs padrão.
- **Negativo:** Lock-in forte no ecossistema Google, potencial cobrança de uso do Maps na produção caso o tráfego escale significativamente no futuro.
- **Segurança:** O operador (Eduardo) é responsável por restringir a API Key no console da Google Cloud ao SHA-1/Application ID (Android) e Bundle ID (iOS) do aplicativo, e assegurar que a mesma nunca seja commitada no repositório.
