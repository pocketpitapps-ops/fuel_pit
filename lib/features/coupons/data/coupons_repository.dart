// lib\features\coupons\data\coupons_repository.dart
import '../domain/coupon.dart';
import '../../profile/domain/user_profile.dart';
import '../../../core/supabase_client.dart';
import '../../stations/domain/station_brand.dart';

class CouponsRepository {
  CouponsRepository();

  String _codePrefixForBrand(StationBrand? brand) {
    switch (brand) {
      case StationBrand.galp:
        return 'GALP';
      case StationBrand.bp:
        return 'BP';
      case StationBrand.prio:
        return 'PRIO';
      case StationBrand.intermarche:
        return 'INTER';
      case StationBrand.repsol:
        return 'REPSOL';
      case StationBrand.cepsa:
        return 'CEPSA';
      case StationBrand.shell:
        return 'SHELL';
      case StationBrand.auchan:
        return 'AUCHAN';
      case StationBrand.leclerc:
        return 'LECLERC';
      default:
        return 'OTHER';
    }
  }

  Future<String> _generateAutoCode({
    required String userId,
    required String? brand,
  }) async {
    final normalizedBrand = normalizeBrand(brand); // StationBrand?

    final prefix = _codePrefixForBrand(normalizedBrand);
    final brandKey = normalizedBrand.name;

    final res = await supabase
        .from('user_coupons')
        .select('code_override')
        .eq('user_id', userId)
        .eq('brand', brandKey);

    final List data = res as List;

    int maxNumber = 0;
    for (final row in data) {
      final code = row['code_override'] as String?;
      if (code == null) continue;
      if (!code.startsWith(prefix)) continue;

      final parts = code.split('_');
      final last = parts.isNotEmpty ? parts.last : '';
      final n = int.tryParse(last) ?? 0;
      if (n > maxNumber) maxNumber = n;
    }

    final nextNumber = maxNumber + 1;
    return '${prefix}_${nextNumber.toString().padLeft(3, '0')}';
  }

  Future<Coupon?> getLoyaltyCoupon({
    required String userId,
    required String brand,
  }) async {
    final normalizedBrand = normalizeBrand(brand).name;

    final response = await supabase
        .from('user_coupons')
        .select()
        .eq('user_id', userId)
        .eq('brand', normalizedBrand)
        .eq('is_active', true)
        .limit(1);

    final data = response as List<dynamic>;
    if (data.isEmpty) return null;

    final json = data.first as Map<String, dynamic>;
    return Coupon.fromJson(json);
  }

  Future<Coupon> ensureLoyaltyCoupon({
    required String userId,
    required String brand,
    required String discountType,
    required double discountValue,
  }) async {
    final existing = await getLoyaltyCoupon(userId: userId, brand: brand);
    if (existing != null) return existing;

    final newCoupon = Coupon(
      id: '', // gerado pela BD ou UUID local
      userId: userId,
      customName: 'Fidelização $brand',
      codeOverride: null,
      discountType: discountType,
      discountValue: discountValue,
      validUntil: null, // desconto permanente
      isActive: true,
      brand: brand,
      timesUsed: 0,
      usageLimit: null,
      benefitKind: CouponBenefitKind.directDiscount,
      kind: CouponKind.loyalty,
    );

    await addCoupon(newCoupon);

    final inserted = await getLoyaltyCoupon(userId: userId, brand: brand);
    if (inserted == null) {
      // fallback se por algum motivo não encontrar – opcional
      return newCoupon;
    }
    return inserted;
  }

  Future<List<Coupon>> getAllCoupons() async {
    final response = await supabase
        .from('user_coupons')
        .select()
        .order('valid_until', ascending: true);

    final data = (response as List<dynamic>).cast<Map<String, dynamic>>();
    return data.map(Coupon.fromJson).toList();
  }

  Future<List<Coupon>> getAllCouponsForCurrentUser() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Sem utilizador autenticado.');
    }

    final response = await supabase
        .from('user_coupons')
        .select()
        .eq('user_id', user.id)
        .order('valid_until', ascending: true);

    final data = (response as List<dynamic>).cast<Map<String, dynamic>>();
    return data.map(Coupon.fromJson).toList();
  }

  Future<List<Coupon>> getActiveCouponsForCurrentUser() async {
    final all = await getAllCouponsForCurrentUser();
    return all.where((c) => c.status == CouponStatus.active).toList();
  }

  Future<void> addCoupon(Coupon coupon) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Sem utilizador autenticado.');
    }

    final currentCode = coupon.codeOverride?.trim().isNotEmpty == true
        ? coupon.codeOverride!.trim()
        : null;

    final autoCode =
        currentCode ??
        await _generateAutoCode(userId: user.id, brand: coupon.brand);

    final data = coupon.toJson();
    data['user_id'] = user.id;
    data['usage_limit'] = coupon.usageLimit ?? 1;
    data['times_used'] = coupon.timesUsed;
    data['brand'] = normalizeBrand(coupon.brand).name;
    data['code_override'] = autoCode;

    await supabase.from('user_coupons').insert(data).select();
  }

  Future<void> updateCoupon(String id, Map<String, dynamic> patch) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Sem utilizador autenticado.');
    }

    await supabase
        .from('user_coupons')
        .update(patch)
        .eq('id', id)
        .eq('user_id', user.id);
  }

  Future<void> deleteCoupon(String id) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Sem utilizador autenticado.');
    }

    await supabase
        .from('user_coupons')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);
  }

  Future<void> markCouponUsed(String id) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Sem utilizador autenticado.');
    }

    final response = await supabase
        .from('user_coupons')
        .select('usage_limit, times_used')
        .eq('id', id)
        .eq('user_id', user.id)
        .single();

    final usageLimit = response['usage_limit'] as int?;
    final timesUsed = (response['times_used'] as int?) ?? 0;

    final newTimes = timesUsed + 1;

    final now = DateTime.now().toUtc();
    final todayStr = now.toIso8601String().split('T').first;

    final patch = <String, dynamic>{
      'times_used': newTimes,
      'last_used_at': todayStr,
      'updated_at': now.toIso8601String(),
    };

    if (usageLimit != null && newTimes >= usageLimit) {
      patch['is_active'] = false;
    }

    await supabase
        .from('user_coupons')
        .update(patch)
        .eq('id', id)
        .eq('user_id', user.id);
  }

  Future<void> cleanupOldCouponsForCurrentUser(UserProfile profile) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Sem utilizador autenticado.');
    }

    final now = DateTime.now().toUtc();

    final expiredLimit = now.subtract(
      Duration(days: profile.expiredCouponsRetentionDays),
    );
    final usedLimit = now.subtract(
      Duration(days: profile.usedCouponsRetentionDays),
    );

    final expiredLimitStr = expiredLimit.toIso8601String().split('T').first;
    final usedLimitStr = usedLimit.toIso8601String().split('T').first;

    await supabase
        .from('user_coupons')
        .delete()
        .eq('user_id', user.id)
        .lte('valid_until', expiredLimitStr);

    await supabase
        .from('user_coupons')
        .delete()
        .eq('user_id', user.id)
        .not('last_used_at', 'is', null)
        .lte('last_used_at', usedLimitStr);
  }

  Future<List<Coupon>> getActiveNonExpiredForCurrentUser() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Sem utilizador autenticado.');
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final response = await supabase
        .from('user_coupons')
        .select()
        .eq('user_id', user.id);

    final data = (response as List<dynamic>).cast<Map<String, dynamic>>();
    final all = data.map(Coupon.fromJson).toList();

    return all.where((c) {
      if (!c.isActive) return false;
      final v = c.validUntil;
      if (v == null) return false;
      final expiry = DateTime(v.year, v.month, v.day);
      return !today.isAfter(expiry);
    }).toList()..sort(
      (a, b) => (a.validUntil ?? today).compareTo(b.validUntil ?? today),
    );
  }

  Future<void> deleteAllForUser(String userId) async {
    await supabase.from('user_coupons').delete().eq('user_id', userId);
  }

  Future<Coupon?> findCouponByCodeOverride(
    String userId,
    String codeOverride,
  ) async {
    final res = await supabase
        .from('user_coupons')
        .select()
        .eq('user_id', userId)
        .eq('code_override', codeOverride)
        .maybeSingle();

    if (res == null) return null;
    return Coupon.fromJson(res); // adapta ao teu factory
  }

  Future<void> upsertPermanentLoyaltyCoupon({
    required String userId,
    required String brandKey,
    required double discountPerLiter,
    required CouponBenefitKind benefitKind,
  }) async {
    const loyaltyPrefix = 'LOYALTY_';
    final codeOverride = '$loyaltyPrefix$brandKey';

    final existing = await findCouponByCodeOverride(userId, codeOverride);

    final benefitKindStr = benefitKind == CouponBenefitKind.cardBalance
        ? 'card_balance'
        : 'direct_discount';

    if (existing == null) {
      final coupon = Coupon(
        id: '',
        userId: userId,
        customName: 'Fidelização $brandKey',
        code: null,
        codeOverride: codeOverride,
        discountType: 'per_liter',
        discountValue: discountPerLiter,
        validUntil: null,
        isActive: true,
        brand: brandKey,
        timesUsed: 0,
        usageLimit: 99999,
        benefitKind: benefitKind,
      );
      await addCoupon(coupon);
    } else {
      final patch = <String, dynamic>{
        'discount_type': 'per_liter',
        'discount_value': discountPerLiter,
        'is_active': true,
        'brand': brandKey,
        'benefit_kind': benefitKindStr,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      await updateCoupon(existing.id, patch);
    }
  }

  Future<void> deletePermanentLoyaltyCoupon({
    required String userId,
    required String brandKey,
  }) async {
    const loyaltyPrefix = 'LOYALTY_';
    final codeOverride = '$loyaltyPrefix$brandKey';

    await supabase
        .from('user_coupons')
        .delete()
        .eq('user_id', userId)
        .eq('code_override', codeOverride);
  }
}
