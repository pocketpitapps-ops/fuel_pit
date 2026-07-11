// lib/features/coupons/domain/coupon_station_compat.dart
import '../../stations/domain/station.dart';
import 'coupon.dart';

bool isCouponCompatibleWithStation(Coupon coupon, Station station) {
  // 1. Estado básico: tem de estar ativo e não expirado
  if (!coupon.isActive) return false;
  if (coupon.status == CouponStatus.expired) return false;

  // 2. Limite de utilizações, se existir
  if (coupon.usageLimit != null && coupon.timesUsed >= coupon.usageLimit!) {
    return false;
  }

  // 3. Marca: se o cupão trouxer brand, tem de coincidir com a do posto
  if (coupon.brand != null && coupon.brand!.trim().isNotEmpty) {
    final couponBrand = coupon.brand!.trim().toLowerCase();

    final stationBrandRaw = station.brand?.trim().toLowerCase();
    if (stationBrandRaw == null || stationBrandRaw.isEmpty) {
      // posto sem marca conhecida → cupão por marca não é compatível
      return false;
    }

    if (stationBrandRaw != couponBrand) {
      return false;
    }
  }

  // 4. (Opcional) Se no futuro adicionares fuelType ao cupão, restringes aqui.

  // Se passou todos os checks, consideramos compatível
  return true;
}
