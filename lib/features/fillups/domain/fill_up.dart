// lib/features/fillups/domain/fill_up.dart

import 'package:fuel_pit/shared/models/fuel_type.dart';

class FillUp {
  final String id;
  final String userId;
  final String? stationName;

  /// Veículo associado ao abastecimento (nullable para dados antigos).
  final String? vehicleId;

  /// Tipo de combustível no domínio (sempre enum na app).
  final FuelType fuelType;

  final double liters;
  final double pricePerLiter;
  final double totalPaid;
  final DateTime filledAt;
  final String? userCouponId;

  const FillUp({
    required this.id,
    required this.userId,
    this.stationName,
    this.vehicleId,
    required this.fuelType,
    required this.liters,
    required this.pricePerLiter,
    required this.totalPaid,
    required this.filledAt,
    this.userCouponId,
  });

  factory FillUp.fromJson(Map<String, dynamic> json) {
    final rawFuelType = json['fuel_type'] as String?;
    final fuelTypeEnum = rawFuelType != null
        ? FuelTypeExt.fromDb(rawFuelType)
        : null;

    return FillUp(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      stationName: json['station_name'] as String?,
      vehicleId: json['vehicle_id'] as String?, // novo
      fuelType: fuelTypeEnum ?? FuelType.gasolina95,
      liters: (json['liters'] as num?)?.toDouble() ?? 0,
      pricePerLiter: (json['price_per_liter'] as num?)?.toDouble() ?? 0,
      totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0,
      filledAt: json['filled_at'] is String
          ? DateTime.parse(json['filled_at'] as String)
          : (json['filled_at'] as DateTime),
      userCouponId: json['user_coupon_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // id fica a cargo do Supabase (uuid default)
      'user_id': userId,
      'station_name': stationName,
      'vehicle_id': vehicleId, // novo
      'fuel_type': fuelType.dbValue,
      'liters': liters,
      'price_per_liter': pricePerLiter,
      'total_paid': totalPaid,
      'filled_at': filledAt.toUtc().toIso8601String(),
      'user_coupon_id': userCouponId,
    };
  }

  FillUp copyWith({
    String? id,
    String? userId,
    String? stationName,
    String? vehicleId,
    FuelType? fuelType,
    double? liters,
    double? pricePerLiter,
    double? totalPaid,
    DateTime? filledAt,
    String? userCouponId,
  }) {
    return FillUp(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      stationName: stationName ?? this.stationName,
      vehicleId: vehicleId ?? this.vehicleId,
      fuelType: fuelType ?? this.fuelType,
      liters: liters ?? this.liters,
      pricePerLiter: pricePerLiter ?? this.pricePerLiter,
      totalPaid: totalPaid ?? this.totalPaid,
      filledAt: filledAt ?? this.filledAt,
      userCouponId: userCouponId ?? this.userCouponId,
    );
  }
}
