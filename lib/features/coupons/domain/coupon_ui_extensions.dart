// lib\features\coupons\domain\coupon_ui_extensions.dart
import 'package:flutter/material.dart';
import 'coupon.dart';

extension CouponUiX on Coupon {
  String get statusLabel {
    switch (status) {
      case CouponStatus.active:
        return 'Ativo';
      case CouponStatus.used:
        return 'Utilizado';
      case CouponStatus.expired:
        return 'Expirado';
    }
  }

  Color statusColor(ColorScheme scheme) {
    switch (status) {
      case CouponStatus.active:
        return Colors.green;
      case CouponStatus.used:
        return Colors.blue;
      case CouponStatus.expired:
        return Colors.red;
    }
  }

  String get valueLabel {
    switch (discountType) {
      case 'per_liter':
        return '${discountValue.toStringAsFixed(2)} €/L';
      case 'percent':
        return '${discountValue.toStringAsFixed(1)} %';
      case 'fixed':
        return '${discountValue.toStringAsFixed(2)} €';
      case 'card_cashback':
        return '${discountValue.toStringAsFixed(2)} € em cartão';
      default:
        return discountValue.toString();
    }
  }

  String get validityLabel {
    if (validUntil == null) return 'Sem data';
    return '${validUntil!.day.toString().padLeft(2, '0')}/'
        '${validUntil!.month.toString().padLeft(2, '0')}/'
        '${validUntil!.year}';
  }

  String get uiDisplayName {
    final code = codeOverride ?? '';
    final prettyCode = code.isEmpty ? '' : code.replaceAll('_', '');
    final value = valueLabel;

    if (prettyCode.isEmpty) {
      return value;
    }

    return '$prettyCode - $value';
  }
}
