// lib\app_services\discounts\discount_engine.dart
import 'coupon.dart';

class DiscountResult {
  final double baseTotal;
  final double finalTotal;
  final double cashbackOnCard;
  final List<Coupon> appliedCoupons;

  const DiscountResult({
    required this.baseTotal,
    required this.finalTotal,
    required this.cashbackOnCard,
    required this.appliedCoupons,
  });

  double get savings => baseTotal - finalTotal;
}

DiscountResult calculateDiscounts({
  required double liters,
  required double pricePerLiter,
  required List<Coupon> coupons,
}) {
  final double baseTotal = liters * pricePerLiter;
  double total = baseTotal;
  double cashback = 0.0;

  for (final c in coupons) {
    switch (c.discountType) {
      case 'per_liter':
        final discount = c.discountValue * liters;
        total -= discount;
        break;
      case 'percent':
        final discount = total * (c.discountValue / 100.0);
        total -= discount;
        break;
      case 'fixed':
        total -= c.discountValue;
        break;
      case 'card_cashback':
        cashback += c.discountValue;
        break;
      default:
        break;
    }
  }

  if (total < 0) total = 0;

  return DiscountResult(
    baseTotal: baseTotal,
    finalTotal: total,
    cashbackOnCard: cashback,
    appliedCoupons: coupons,
  );
}
