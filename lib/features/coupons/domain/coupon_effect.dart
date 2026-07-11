// lib\features\coupons\domain\coupon_effect.dart
import 'coupon.dart';

/// Resultado do efeito de um cupão num abastecimento.
class CouponEffect {
  final double directDiscount; // em €
  final double cardBalance; // em €

  CouponEffect({required this.directDiscount, required this.cardBalance});

  double get totalDiscount => directDiscount + cardBalance;
}

/// Função pura que calcula o efeito de um cupão.
CouponEffect calculateCouponEffect({
  required Coupon coupon,
  required double totalPaid,
  required double liters,
}) {
  double direct = 0.0;
  double card = 0.0;

  switch (coupon.discountType) {
    case 'per_liter':
      final amount = coupon.discountValue * liters;
      if (coupon.benefitKind == CouponBenefitKind.directDiscount) {
        direct = amount;
      } else {
        card = amount;
      }
      break;

    case 'percent':
      final amount = totalPaid * (coupon.discountValue / 100.0);
      if (coupon.benefitKind == CouponBenefitKind.directDiscount) {
        direct = amount;
      } else {
        card = amount;
      }
      break;

    case 'fixed':
      if (coupon.benefitKind == CouponBenefitKind.directDiscount) {
        direct = coupon.discountValue;
      } else {
        card = coupon.discountValue;
      }
      break;

    case 'card_cashback':
      card = coupon.discountValue;
      break;

    default:
      break;
  }

  return CouponEffect(directDiscount: direct, cardBalance: card);
}
