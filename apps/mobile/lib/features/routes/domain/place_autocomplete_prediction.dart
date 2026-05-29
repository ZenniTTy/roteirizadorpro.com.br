class PlaceAutocompletePrediction {
  const PlaceAutocompletePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  factory PlaceAutocompletePrediction.fromJson(Map<String, dynamic> json) {
    final structuredFormatting =
        json['structured_formatting'] as Map<String, dynamic>?;
    return PlaceAutocompletePrediction(
      placeId: json['place_id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      mainText: structuredFormatting?['main_text'] as String? ??
          json['description'] as String? ??
          '',
      secondaryText: structuredFormatting?['secondary_text'] as String? ?? '',
    );
  }
}
