import 'package:flutter/material.dart';
import 'package:roteirizador_pro/features/routes/domain/package_details.dart';
import 'package:roteirizador_pro/features/routes/domain/place_in_vehicle.dart';
import 'package:roteirizador_pro/features/routes/domain/stop_color.dart';
import 'package:roteirizador_pro/features/routes/domain/stop_order_policy.dart';
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
    this.packagesCount = 1,
    this.timeWindowStart,
    this.timeWindowEnd,
    this.priority,
    this.orderPolicy = StopOrderPolicy.auto,
    this.color,
    this.packageDetails,
    this.placeInVehicle,
    this.photoPaths = const [],
    this.accessInstructions,
    this.estimatedTimeAtStop,
    this.estimatedArrival,
    this.pendingRemoval = false,
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
  final int packagesCount;

  /// Janela de horário — tipo hora-do-dia (sem data) conforme dump v3.65.1 (H1).
  final TimeOfDay? timeWindowStart;
  final TimeOfDay? timeWindowEnd;

  final int? priority;

  /// Restrição de posição da parada na rota (F16). Ortogonal a [priority] (H4).
  final StopOrderPolicy orderPolicy;

  final StopColor? color;
  final PackageDetails? packageDetails;
  final PlaceInVehicle? placeInVehicle;
  final List<String> photoPaths;
  final String? accessInstructions;

  /// Tempo estimado na parada (substitui customDurationMinutes).
  final Duration? estimatedTimeAtStop;

  /// Horário ESTIMADO de chegada na parada (ETA). Espelha o `Instant` por stop
  /// que o Spoke exibe no slot esquerdo da step list ("14:32"). No Slice 2 é
  /// uma aproximação local cravada pelo `LocalRouteOptimizer` (horário da
  /// otimização + tempo de viagem acumulado, só deslocamento — sem tempo de
  /// serviço e sem trânsito). O Slice 3 (GraphHopper) substitui por ETA real
  /// com trânsito + tempo na parada, recalculado ao vivo. `null` enquanto a
  /// rota não foi otimizada (estado DRAFT → ícone Circle, sem hora).
  final DateTime? estimatedArrival;

  /// Marca a parada para remoção DEFERIDA quando a rota já está otimizada
  /// (G5 — espelha `ConfirmDeleteStopOnOptimizationDialog` do Spoke). O solver
  /// exclui paradas com esta flag na próxima otimização. Em rota DRAFT a
  /// remoção é imediata (não usa esta flag).
  final bool pendingRemoval;

  // Sentinela interna usada pelo copyWith para distinguir "omitido" de null.
  static const _omit = Object();

  Stop copyWith({
    String? id,
    Object? positionInRoute = _omit,
    Object? deliveryId = _omit,
    StopType? type,
    StopStatus? status,
    double? lat,
    double? lng,
    String? streetName,
    String? fullAddress,
    Object? notes = _omit,
    int? packagesCount,
    Object? timeWindowStart = _omit,
    Object? timeWindowEnd = _omit,
    Object? priority = _omit,
    StopOrderPolicy? orderPolicy,
    Object? color = _omit,
    Object? packageDetails = _omit,
    Object? placeInVehicle = _omit,
    List<String>? photoPaths,
    Object? accessInstructions = _omit,
    Object? estimatedTimeAtStop = _omit,
    Object? estimatedArrival = _omit,
    bool? pendingRemoval,
  }) {
    // Nullables usam a sentinela _omit: omitido → preserva; null explícito →
    // LIMPA o campo (lesson_copywith_nullable_field_pitfall / H2).
    return Stop(
      id: id ?? this.id,
      positionInRoute: identical(positionInRoute, _omit)
          ? this.positionInRoute
          : positionInRoute as int?,
      deliveryId: identical(deliveryId, _omit)
          ? this.deliveryId
          : deliveryId as String?,
      type: type ?? this.type,
      status: status ?? this.status,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      streetName: streetName ?? this.streetName,
      fullAddress: fullAddress ?? this.fullAddress,
      notes: identical(notes, _omit) ? this.notes : notes as String?,
      packagesCount: packagesCount ?? this.packagesCount,
      timeWindowStart: identical(timeWindowStart, _omit)
          ? this.timeWindowStart
          : timeWindowStart as TimeOfDay?,
      timeWindowEnd: identical(timeWindowEnd, _omit)
          ? this.timeWindowEnd
          : timeWindowEnd as TimeOfDay?,
      priority: identical(priority, _omit) ? this.priority : priority as int?,
      orderPolicy: orderPolicy ?? this.orderPolicy,
      color: identical(color, _omit) ? this.color : color as StopColor?,
      packageDetails: identical(packageDetails, _omit)
          ? this.packageDetails
          : packageDetails as PackageDetails?,
      placeInVehicle: identical(placeInVehicle, _omit)
          ? this.placeInVehicle
          : placeInVehicle as PlaceInVehicle?,
      photoPaths: photoPaths ?? this.photoPaths,
      accessInstructions: identical(accessInstructions, _omit)
          ? this.accessInstructions
          : accessInstructions as String?,
      estimatedTimeAtStop: identical(estimatedTimeAtStop, _omit)
          ? this.estimatedTimeAtStop
          : estimatedTimeAtStop as Duration?,
      estimatedArrival: identical(estimatedArrival, _omit)
          ? this.estimatedArrival
          : estimatedArrival as DateTime?,
      pendingRemoval: pendingRemoval ?? this.pendingRemoval,
    );
  }
}
