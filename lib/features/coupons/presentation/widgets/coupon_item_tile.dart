// lib/pages/widgets/coupon_item_tile.dart
import 'package:flutter/material.dart';
import '../../domain/coupon.dart';
import '../../../../shared/widgets/app_card.dart';

/// Card visual para apresentar um cupão na lista:
/// mostra nome, código, tipo, valor, validade e estado (Ativo/Utilizado/Expirado).
class CouponItemTile extends StatelessWidget {
  final Coupon coupon;

  const CouponItemTile({super.key, required this.coupon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final status = coupon.status;
    final validLabel = coupon.validUntil != null
        ? '${coupon.validUntil!.day.toString().padLeft(2, '0')}/${coupon.validUntil!.month.toString().padLeft(2, '0')}/${coupon.validUntil!.year}'
        : 'Sem data';

    String statusLabel;
    Color statusColor;
    switch (status) {
      case CouponStatus.expired:
        statusLabel = 'Expirado';
        statusColor = Colors.red;
        break;
      case CouponStatus.used:
        statusLabel = 'Utilizado';
        statusColor = Colors.blue;
        break;
      case CouponStatus.active:
        statusLabel = 'Ativo';
        statusColor = Colors.green;
        break;
    }

    String valueLabel;
    switch (coupon.discountType) {
      case 'per_liter':
        valueLabel = '${coupon.discountValue.toStringAsFixed(2)} €/L';
        break;
      case 'percent':
        valueLabel = '${coupon.discountValue.toStringAsFixed(1)} %';
        break;
      case 'fixed':
        valueLabel = '${coupon.discountValue.toStringAsFixed(2)} €';
        break;
      case 'card_cashback':
        valueLabel = '${coupon.discountValue.toStringAsFixed(2)} € em cartão';
        break;
      default:
        valueLabel = coupon.discountValue.toString();
    }

    final code = coupon.effectiveCode;

    final name = coupon.customName?.trim().isNotEmpty == true
        ? coupon.customName!.trim()
        : (code.isNotEmpty ? code : 'Cupão sem nome');

    final isExpired = status == CouponStatus.expired;
    final isReallyActive = status == CouponStatus.active;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // topo: nome + pill valor / expirado
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(name, style: textTheme.titleMedium)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isExpired
                        ? colorScheme.errorContainer
                        : (isReallyActive
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isExpired ? 'Expirado' : valueLabel,
                    style: textTheme.labelSmall?.copyWith(
                      color: isExpired
                          ? colorScheme.onErrorContainer
                          : (isReallyActive
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // código e tipo
            Row(
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 4),
                const Spacer(),
                Text(
                  coupon.discountType,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // validade + estado
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  'Válido até: $validLabel',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
                const Spacer(),
                Text(
                  statusLabel,
                  style: textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
