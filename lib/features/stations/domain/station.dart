// lib/features/stations/domain/station.dart
import '../../../shared/models/fuel_type.dart';
import 'station_brand.dart';

class Station {
  final int id;
  final int? dgegId;
  final String name;
  final String? brand;
  final String? address;
  final String? district;
  final String? municipality;
  final String? locality;
  final String? postalCode;
  final double? latitude;
  final double? longitude;

  // Dados de preço “atual” para o combustível relevante
  final String fuelTypeRaw; // valor tal como vem da BD
  FuelType? get fuelTypeEnum =>
      FuelTypeExt.fromDb(fuelTypeRaw); // mapeia para o enum

  final double currentPricePerLiter;
  final double? lastPricePerLiter;
  final DateTime? lastUpdatedAt;

  // Flags de UI
  final double? distanceKm;
  final bool isFavorite;

  // Brand normalizada para UI
  StationBrand get normalizedBrand => normalizeBrand(brand);

  const Station({
    required this.id,
    this.dgegId,
    required this.name,
    this.brand,
    this.address,
    this.district,
    this.municipality,
    this.locality,
    this.postalCode,
    this.latitude,
    this.longitude,
    required this.fuelTypeRaw,
    required this.currentPricePerLiter,
    this.lastPricePerLiter,
    this.lastUpdatedAt,
    this.distanceKm,
    this.isFavorite = false,
  });

  Station copyWith({
    int? id,
    int? dgegId,
    String? name,
    String? brand,
    String? address,
    String? district,
    String? municipality,
    String? locality,
    String? postalCode,
    double? latitude,
    double? longitude,
    String? fuelTypeRaw,
    double? currentPricePerLiter,
    double? lastPricePerLiter,
    DateTime? lastUpdatedAt,
    double? distanceKm,
    bool? isFavorite,
  }) {
    return Station(
      id: id ?? this.id,
      dgegId: dgegId ?? this.dgegId,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      address: address ?? this.address,
      district: district ?? this.district,
      municipality: municipality ?? this.municipality,
      locality: locality ?? this.locality,
      postalCode: postalCode ?? this.postalCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      fuelTypeRaw: fuelTypeRaw ?? this.fuelTypeRaw,
      currentPricePerLiter: currentPricePerLiter ?? this.currentPricePerLiter,
      lastPricePerLiter: lastPricePerLiter ?? this.lastPricePerLiter,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      distanceKm: distanceKm ?? this.distanceKm,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'] as int,
      dgegId: json['dgeg_id'] as int?,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      address: json['address'] as String?,
      district: json['district'] as String?,
      municipality: json['municipality'] as String?,
      locality: json['locality'] as String?,
      postalCode: json['postal_code'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      fuelTypeRaw: json['fuel_type'] as String,
      currentPricePerLiter: (json['current_price_per_liter'] as num).toDouble(),
      lastPricePerLiter: (json['last_price_per_liter'] as num?)?.toDouble(),
      lastUpdatedAt: json['last_updated_at'] != null
          ? DateTime.parse(json['last_updated_at'] as String)
          : null,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      isFavorite: (json['is_favorite'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dgeg_id': dgegId,
      'name': name,
      'brand': brand,
      'address': address,
      'district': district,
      'municipality': municipality,
      'locality': locality,
      'postal_code': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'fuel_type': fuelTypeRaw,
      'current_price_per_liter': currentPricePerLiter,
      'last_price_per_liter': lastPricePerLiter,
      'last_updated_at': lastUpdatedAt?.toIso8601String(),
      'is_favorite': isFavorite,
      // distanceKm é só de UI, não gravamos
    };
  }
}

enum PriceTrend { up, down, same }

PriceTrend getPriceTrend(double current, double? last) {
  if (last == null) return PriceTrend.same;
  if (current < last) return PriceTrend.down;
  if (current > last) return PriceTrend.up;
  return PriceTrend.same;
}
