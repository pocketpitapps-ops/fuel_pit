// lib\features\profile\domain\user_profile.dart

class UserProfile {
  final String id;
  final String userId;
  final String? fullName;
  final String? username; // novo
  final String? email;
  final String? country;
  final String? mobileNumber; // novo
  final String currency;
  final bool hasCompletedOnboarding;
  final List<String> loyaltyBrands;
  final Map<String, double> loyaltyPerLiterDiscounts;

  // Preferências FuelPit
  final String defaultFillMode; // 'per_value' ou 'per_liters'
  final double defaultFillValue; // € ou L, consoante o modo
  final bool notificationsEnabled;

  /// Quantos dias manter cupões expirados na base de dados.
  final int expiredCouponsRetentionDays;

  /// Quantos dias manter cupões utilizados na base de dados.
  final int usedCouponsRetentionDays;

  const UserProfile({
    required this.id,
    required this.userId,
    this.fullName,
    this.username, // novo
    this.email,
    this.country,
    this.mobileNumber, // novo
    required this.currency,
    required this.defaultFillMode,
    required this.defaultFillValue,
    required this.notificationsEnabled,
    this.expiredCouponsRetentionDays = 180, // 6 meses por defeito
    this.usedCouponsRetentionDays = 365, // 1 ano por defeito
    this.hasCompletedOnboarding = false,
    this.loyaltyBrands = const [],
    this.loyaltyPerLiterDiscounts = const {},
  });

  bool get isPerValue => defaultFillMode == 'per_value';
  bool get isPerLiters => defaultFillMode == 'per_liters';

  bool hasLoyaltyForBrand(String brandKey) => loyaltyBrands.contains(brandKey);
  double? loyaltyDiscountForBrand(String brandKey) =>
      loyaltyPerLiterDiscounts[brandKey];

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String?,
      username: json['username'] as String?, // novo
      email: json['email'] as String?,
      country: json['country'] as String?,
      mobileNumber: json['mobile_number'] as String?, // novo
      currency: (json['currency'] as String?)?.trim() ?? 'EUR',

      // Se nada bater certo, escolhe um default seguro (Gasolina 95).
      defaultFillMode: (json['default_fill_mode'] as String?) ?? 'per_value',
      defaultFillValue:
          (json['default_fill_value'] as num?)?.toDouble() ?? 40.0,
      notificationsEnabled: (json['notifications_enabled'] as bool?) ?? true,
      expiredCouponsRetentionDays:
          (json['expired_coupons_retention_days'] as int?) ?? 180,
      usedCouponsRetentionDays:
          (json['used_coupons_retention_days'] as int?) ?? 365,
      hasCompletedOnboarding:
          (json['has_completed_onboarding'] as bool?) ?? false,
      loyaltyBrands:
          (json['loyalty_brands'] as List<dynamic>?)?.cast<String>() ??
          const [],
      loyaltyPerLiterDiscounts:
          (json['loyalty_discounts'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ??
          const {},
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'username': username, // novo
      'email': email,
      'country': country,
      'mobile_number': mobileNumber, // novo
      'currency': currency,
      // Guardamos o valor da BD definido no enum.
      'default_fill_mode': defaultFillMode,
      'default_fill_value': defaultFillValue,
      'notifications_enabled': notificationsEnabled,
      'expired_coupons_retention_days': expiredCouponsRetentionDays,
      'used_coupons_retention_days': usedCouponsRetentionDays,
      'has_completed_onboarding': hasCompletedOnboarding,
      'loyalty_brands': loyaltyBrands,
      'loyalty_discounts': loyaltyPerLiterDiscounts,
    };
  }

  UserProfile copyWith({
    String? fullName,
    String? username,
    String? email,
    String? country,
    String? mobileNumber,
    String? currency,
    String? defaultFillMode,
    double? defaultFillValue,
    bool? notificationsEnabled,
    int? expiredCouponsRetentionDays,
    int? usedCouponsRetentionDays,
    bool? hasCompletedOnboarding,
    List<String>? loyaltyBrands,
    Map<String, double>? loyaltyPerLiterDiscounts,
  }) {
    return UserProfile(
      id: id,
      userId: userId,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      country: country ?? this.country,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      currency: currency ?? this.currency,
      defaultFillMode: defaultFillMode ?? this.defaultFillMode,
      defaultFillValue: defaultFillValue ?? this.defaultFillValue,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      expiredCouponsRetentionDays:
          expiredCouponsRetentionDays ?? this.expiredCouponsRetentionDays,
      usedCouponsRetentionDays:
          usedCouponsRetentionDays ?? this.usedCouponsRetentionDays,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      loyaltyBrands: loyaltyBrands ?? this.loyaltyBrands,
      loyaltyPerLiterDiscounts:
          loyaltyPerLiterDiscounts ?? this.loyaltyPerLiterDiscounts,
    );
  }
}
