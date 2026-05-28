class PlaceDetails {
  const PlaceDetails({
    required this.lat,
    required this.lng,
    required this.shortFormattedAddress,
    required this.formattedAddress,
  });

  final double lat;
  final double lng;
  final String shortFormattedAddress;
  final String formattedAddress;
}
