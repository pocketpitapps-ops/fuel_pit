// lib\features\coupons\domain\coupon.dart
/// Estados possíveis de um cupão na app.
enum CouponStatus { active, expired, used }

enum CouponKind { normal, loyalty }

enum CouponBenefitKind {
  directDiscount, // reduz o valor pago no abastecimento
  cardBalance, // acumula saldo/cashback em cartão/app
}

/// Modelo de cupão gravado em `user_coupons` no Supabase.
class Coupon {
  final String id;
  final String? userId;
  final String? customName;
  final String? code;
  final String? codeOverride;

  /// 'per_liter', 'percent', 'fixed', 'card_cashback'
  final String discountType;
  final double discountValue;
  final DateTime? validUntil;
  final bool isActive;
  final String? brand;

  /// Quantas vezes já foi usado este cupão.
  final int timesUsed;

  /// Limite máximo de utilizações (null = sem limite definido aqui).
  final int? usageLimit;
  final CouponBenefitKind benefitKind;
  final CouponKind kind;

  const Coupon({
    required this.id,
    this.userId,
    this.customName,
    this.code,
    this.codeOverride,
    required this.discountType,
    required this.discountValue,
    this.validUntil,
    required this.isActive,
    this.brand,
    this.timesUsed = 0,
    this.usageLimit,
    required this.benefitKind,
    this.kind = CouponKind.normal,
  });

  /// Constrói a partir de um registo vindo do Supabase.
  factory Coupon.fromJson(Map<String, dynamic> json) {
    DateTime? parseValid(dynamic raw) {
      if (raw is String && raw.isNotEmpty) {
        return DateTime.tryParse(raw);
      }
      if (raw is DateTime) return raw;
      return null;
    }

    CouponKind parseKind(String? raw) {
      switch (raw) {
        case 'loyalty':
          return CouponKind.loyalty;
        case 'normal':
        default:
          return CouponKind.normal;
      }
    }

    return Coupon(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      customName: json['custom_name'] as String?,
      code: null,
      codeOverride: json['code_override'] as String?,
      discountType: (json['discount_type'] ?? 'per_liter') as String,
      discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0.0,
      validUntil: parseValid(json['valid_until']),
      isActive: (json['is_active'] ?? true) as bool,
      brand: json['brand'] as String?,
      timesUsed: (json['times_used'] as int?) ?? 0,
      usageLimit: json['usage_limit'] as int?,
      benefitKind: _parseBenefitKind(json['benefit_kind'] as String?),
      kind: parseKind(json['coupon_kind'] as String?),
    );
  }

  static CouponBenefitKind _parseBenefitKind(String? raw) {
    switch (raw) {
      case 'card_balance':
        return CouponBenefitKind.cardBalance;
      case 'direct_discount':
      default:
        return CouponBenefitKind.directDiscount;
    }
  }

  /// Serializa para enviar para o Supabase.
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'custom_name': customName,
      'code_override': codeOverride,
      'discount_type': discountType,
      'discount_value': discountValue,
      'valid_until': validUntil?.toIso8601String().split('T').first,
      'is_active': isActive,
      'brand': brand,
      'times_used': timesUsed,
      'usage_limit': usageLimit,
      'benefit_kind': benefitKind == CouponBenefitKind.cardBalance
          ? 'card_balance'
          : 'direct_discount',
    };
  }

  String get effectiveCode =>
      (codeOverride?.isNotEmpty == true ? codeOverride! : '');

  CouponStatus get status {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (validUntil != null) {
      final expiry = DateTime(
        validUntil!.year,
        validUntil!.month,
        validUntil!.day,
      );
      if (today.isAfter(expiry)) {
        return CouponStatus.expired;
      }
    }

    return isActive ? CouponStatus.active : CouponStatus.used;
  }

  String get displayName {
    final code = effectiveCode.trim();
    if (customName != null && customName!.trim().isNotEmpty) {
      return customName!.trim();
    }
    if (code.isNotEmpty) {
      return code;
    }
    return 'Cupão sem nome';
  }

  Coupon copyWith({
    String? userId,
    String? customName,
    String? code,
    String? codeOverride,
    String? discountType,
    double? discountValue,
    DateTime? validUntil,
    bool? isActive,
    String? brand,
    int? timesUsed,
    int? usageLimit,
    CouponBenefitKind? benefitKind,
    CouponKind? kind,
  }) {
    return Coupon(
      id: id,
      userId: userId ?? this.userId,
      customName: customName ?? this.customName,
      code: code ?? this.code,
      codeOverride: codeOverride ?? this.codeOverride,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      validUntil: validUntil ?? this.validUntil,
      isActive: isActive ?? this.isActive,
      brand: brand ?? this.brand,
      timesUsed: timesUsed ?? this.timesUsed,
      usageLimit: usageLimit ?? this.usageLimit,
      benefitKind: benefitKind ?? this.benefitKind,
      kind: kind ?? this.kind,
    );
  }
}
