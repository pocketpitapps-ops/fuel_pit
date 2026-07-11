import 'package:flutter/material.dart';

import '../../coupons/domain/coupon.dart';
import '../domain/fill_up.dart';

class HistoryFillUpTile extends StatelessWidget {
  final FillUp fillUp;
  final Coupon? coupon;
  final double savings;
  final double cashback;
  final VoidCallback onTap;

  const HistoryFillUpTile({
    super.key,
    required this.fillUp,
    required this.coupon,
    required this.savings,
    required this.cashback,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final stationName = fillUp.stationName ?? 'Posto sem nome';
    final couponName = coupon?.customName ?? coupon?.effectiveCode;
    final hasCoupon = coupon != null;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(stationName),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${fillUp.liters.toStringAsFixed(1)} L • ${fillUp.totalPaid.toStringAsFixed(2)} €',
              ),
              Text('${fillUp.pricePerLiter.toStringAsFixed(3)} €/L'),
              if (hasCoupon && couponName != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Cupão: $couponName',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
              if (savings > 0 || cashback > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Poupança: ${savings.toStringAsFixed(2)} €'
                  '${cashback > 0 ? ' | Cashback: ${cashback.toStringAsFixed(2)} €' : ''}',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
