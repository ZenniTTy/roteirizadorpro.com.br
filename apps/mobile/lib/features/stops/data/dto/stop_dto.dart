// Mirror of: apps/backend/src/routes/schemas.ts -> StopSchema
//
// Per ADR-0013: the TypeBox schema is the source of truth for the HTTP
// contract. This Dart class mirrors it 1:1 — fields and types match,
// no renaming. When the TypeBox StopSchema changes, this file changes
// in the same commit.

import 'package:flutter/foundation.dart';

@immutable
class StopDto {
  const StopDto({required this.lat, required this.lng, this.label});

  final double lat;
  final double lng;
  final String? label;

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      if (label != null) 'label': label,
    };
  }

  static StopDto fromJson(Map<String, dynamic> json) {
    return StopDto(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      label: json['label'] as String?,
    );
  }
}
