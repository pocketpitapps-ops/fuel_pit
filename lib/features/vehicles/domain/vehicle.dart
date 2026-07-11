// lib/models/vehicle.dart
import '../../../shared/models/fuel_type.dart';

class Vehicle {
  final String id;
  final String? nickname;
  final String? brand;
  final String? model;
  final String? plate;
  final FuelType? fuelType;
  final double? tankCapacityL;
  final bool isDefault;

  final String? typeId;

  const Vehicle({
    required this.id,
    this.nickname,
    this.brand,
    this.model,
    this.plate,
    this.fuelType,
    this.tankCapacityL,
    this.isDefault = false,
    this.typeId,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: (json['id'] as String?) ?? '',
      nickname: json['nickname'] as String?,
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      plate: json['plate'] as String?,
      fuelType: FuelTypeExt.fromDb(json['fuel_type'] as String?),
      tankCapacityL: (json['tank_capacity_l'] as num?)?.toDouble(),
      isDefault: (json['is_default'] ?? false) as bool,
      typeId: json['type_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nickname': nickname,
      'brand': brand,
      'model': model,
      'plate': plate,
      'fuel_type': fuelType?.dbValue,
      'tank_capacity_l': tankCapacityL,
      'is_default': isDefault,
      'type_id': typeId,
    };
  }

  Vehicle copyWith({
    String? nickname,
    String? brand,
    String? model,
    String? plate,
    FuelType? fuelType,
    double? tankCapacityL,
    bool? isDefault,
    String? typeId,
  }) {
    return Vehicle(
      id: id,
      nickname: nickname ?? this.nickname,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      plate: plate ?? this.plate,
      fuelType: fuelType ?? this.fuelType,
      tankCapacityL: tankCapacityL ?? this.tankCapacityL,
      isDefault: isDefault ?? this.isDefault,
      typeId: typeId ?? this.typeId,
    );
  }
}
