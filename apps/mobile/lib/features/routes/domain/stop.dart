import 'package:uuid/uuid.dart';

enum StopType { delivery, pickup }

enum StopStatus { pending, delivered, failed, pickedUp }

class Stop {
  Stop({
    String? id,
    this.positionInRoute,
    this.deliveryId,
    this.type = StopType.delivery,
    this.status = StopStatus.pending,
    required this.lat,
    required this.lng,
    required this.streetName,
    required this.fullAddress,
    this.notes,
    this.colorHex,
    this.packagesCount = 1,
    this.timeWindowStart,
    this.timeWindowEnd,
    this.customDurationMinutes,
    this.priority,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final int? positionInRoute;

  /// Formatted identifier like "A1" or "1"
  final String? deliveryId;
  final StopType type;
  final StopStatus status;

  final double lat;
  final double lng;
  final String streetName;
  final String fullAddress;

  final String? notes;
  final String? colorHex;
  final int packagesCount;

  final DateTime? timeWindowStart;
  final DateTime? timeWindowEnd;
  final int? customDurationMinutes;
  final int? priority;

  Stop copyWith({
    String? id,
    int? positionInRoute,
    String? deliveryId,
    StopType? type,
    StopStatus? status,
    double? lat,
    double? lng,
    String? streetName,
    String? fullAddress,
    String? notes,
    String? colorHex,
    int? packagesCount,
    DateTime? timeWindowStart,
    DateTime? timeWindowEnd,
    int? customDurationMinutes,
    int? priority,
  }) {
    return Stop(
      id: id ?? this.id,
      positionInRoute: positionInRoute ?? this.positionInRoute,
      deliveryId: deliveryId ?? this.deliveryId,
      type: type ?? this.type,
      status: status ?? this.status,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      streetName: streetName ?? this.streetName,
      fullAddress: fullAddress ?? this.fullAddress,
      notes: notes ?? this.notes,
      colorHex: colorHex ?? this.colorHex,
      packagesCount: packagesCount ?? this.packagesCount,
      timeWindowStart: timeWindowStart ?? this.timeWindowStart,
      timeWindowEnd: timeWindowEnd ?? this.timeWindowEnd,
      customDurationMinutes:
          customDurationMinutes ?? this.customDurationMinutes,
      priority: priority ?? this.priority,
    );
  }
}
