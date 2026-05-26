import 'package:flutter/foundation.dart';

import '../data/dto/stop_dto.dart';

enum StopSource { manual, voice, ocr, mapTap }

@immutable
class Stop {
  const Stop({
    required this.id,
    required this.lat,
    required this.lng,
    required this.source,
    required this.createdAt,
    this.label,
  });

  final String id;
  final double lat;
  final double lng;
  final String? label;
  final StopSource source;
  final DateTime createdAt;

  bool get isGeocoded => lat != 0 || lng != 0;

  Stop copyWith({
    String? id,
    double? lat,
    double? lng,
    String? label,
    StopSource? source,
    DateTime? createdAt,
  }) {
    return Stop(
      id: id ?? this.id,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      label: label ?? this.label,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lat': lat,
      'lng': lng,
      if (label != null) 'label': label,
      'source': source.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static Stop fromJson(Map<String, dynamic> json) {
    return Stop(
      id: json['id'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      label: json['label'] as String?,
      source: StopSource.values.byName(json['source'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  StopDto toDto() => StopDto(lat: lat, lng: lng, label: label);

  static Stop fromDto(
    StopDto dto, {
    required String id,
    StopSource source = StopSource.manual,
    DateTime? now,
  }) {
    return Stop(
      id: id,
      lat: dto.lat,
      lng: dto.lng,
      label: dto.label,
      source: source,
      createdAt: now ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Stop &&
        other.id == id &&
        other.lat == lat &&
        other.lng == lng &&
        other.label == label &&
        other.source == source &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(id, lat, lng, label, source, createdAt);
}
