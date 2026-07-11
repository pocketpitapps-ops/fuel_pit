// lib/features/fillups/domain/fillup_stats.dart
import '../../coupons/domain/coupon.dart';
import '../../coupons/domain/coupon_effect.dart';
import 'fill_up.dart';

class FillUpStats {
  final double totalDirectDiscount;
  final double totalCardBalance;
  final double totalLiters;
  final double totalPaid;

  const FillUpStats({
    required this.totalDirectDiscount,
    required this.totalCardBalance,
    required this.totalLiters,
    required this.totalPaid,
  });

  double get totalSavings => totalDirectDiscount + totalCardBalance;
}

Coupon? _findCouponById(List<Coupon> coupons, String id) {
  for (final c in coupons) {
    if (c.id == id) return c;
  }
  return null;
}

FillUpStats computeFillUpStats({
  required List<FillUp> fillups,
  required List<Coupon> coupons,
}) {
  double totalDirect = 0.0;
  double totalCard = 0.0;
  double totalLiters = 0.0;
  double totalPaid = 0.0;

  for (final f in fillups) {
    totalLiters += f.liters;
    totalPaid += f.totalPaid;

    final couponId = f.userCouponId;
    if (couponId == null) continue;

    final coupon = _findCouponById(coupons, couponId);
    if (coupon == null) continue;

    final effect = calculateCouponEffect(
      coupon: coupon,
      totalPaid: f.totalPaid,
      liters: f.liters,
    );

    totalDirect += effect.directDiscount;
    totalCard += effect.cardBalance;
  }

  return FillUpStats(
    totalDirectDiscount: totalDirect,
    totalCardBalance: totalCard,
    totalLiters: totalLiters,
    totalPaid: totalPaid,
  );
}
