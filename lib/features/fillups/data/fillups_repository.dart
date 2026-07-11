// lib/app_services/db/fillups_repository.dart
import '../domain/fill_up.dart';
import '../../coupons/domain/coupon.dart';
import '../../../shared/models/fuel_type.dart';
import '../../../core/supabase_client.dart';

class FillUpsRepository {
  Future<List<FillUp>> getAllFillUps() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Sem utilizador autenticado.');
    }

    final response = await supabase
        .from('fill_ups')
        .select()
        .eq('user_id', user.id)
        .order('filled_at', ascending: false);

    final data = (response as List<dynamic>).cast<Map<String, dynamic>>();
    return data.map(FillUp.fromJson).toList();
  }

  /// Abastecimentos entre datas (todos os veículos).
  Future<List<FillUp>> getFillUpsBetweenDates(
    DateTime start,
    DateTime end,
  ) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Sem utilizador autenticado.');
    }

    final response = await supabase
        .from('fill_ups')
        .select()
        .eq('user_id', user.id)
        .gte('filled_at', start.toUtc().toIso8601String())
        .lt('filled_at', end.toUtc().toIso8601String())
        .order('filled_at', ascending: false);

    final data = (response as List<dynamic>).cast<Map<String, dynamic>>();
    return data.map(FillUp.fromJson).toList();
  }

  /// Abastecimentos entre datas para um determinado veículo.
  Future<List<FillUp>> getFillUpsBetweenDatesForVehicle(
    DateTime start,
    DateTime end,
    String vehicleId,
  ) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Sem utilizador autenticado.');
    }

    final response = await supabase
        .from('fill_ups')
        .select()
        .eq('user_id', user.id)
        .eq('vehicle_id', vehicleId)
        .gte('filled_at', start.toUtc().toIso8601String())
        .lt('filled_at', end.toUtc().toIso8601String())
        .order('filled_at', ascending: false);

    final data = (response as List<dynamic>).cast<Map<String, dynamic>>();
    return data.map(FillUp.fromJson).toList();
  }

  /// Resumo mensal para todos os veículos.
  Future<FillUpsSummary> getMonthlySummary(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    final fillUps = await getFillUpsBetweenDates(start, end);

    double totalLiters = 0;
    double totalPaid = 0;

    for (final f in fillUps) {
      totalLiters += f.liters;
      totalPaid += f.totalPaid;
    }

    final avgPricePerLiter = totalLiters > 0 ? totalPaid / totalLiters : 0.0;

    return FillUpsSummary(
      totalLiters: totalLiters,
      totalPaid: totalPaid,
      averagePricePerLiter: avgPricePerLiter,
      count: fillUps.length,
    );
  }

  /// Resumo mensal para um veículo específico.
  Future<FillUpsSummary> getMonthlySummaryForVehicle(
    DateTime month,
    String vehicleId,
  ) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    final fillUps = await getFillUpsBetweenDatesForVehicle(
      start,
      end,
      vehicleId,
    );

    double totalLiters = 0;
    double totalPaid = 0;

    for (final f in fillUps) {
      totalLiters += f.liters;
      totalPaid += f.totalPaid;
    }

    final avgPricePerLiter = totalLiters > 0 ? totalPaid / totalLiters : 0.0;

    return FillUpsSummary(
      totalLiters: totalLiters,
      totalPaid: totalPaid,
      averagePricePerLiter: avgPricePerLiter,
      count: fillUps.length,
    );
  }

  /// Todos os abastecimentos de um veículo (útil para stats por veículo).
  Future<List<FillUp>> getFillUpsForVehicle(String vehicleId) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Sem utilizador autenticado.');
    }

    final response = await supabase
        .from('fill_ups')
        .select()
        .eq('user_id', user.id)
        .eq('vehicle_id', vehicleId)
        .order('filled_at', ascending: false);

    final data = (response as List<dynamic>).cast<Map<String, dynamic>>();
    return data.map(FillUp.fromJson).toList();
  }

  Future<void> addFillUp({
    required String vehicleId, // novo
    required String? stationName,
    required FuelType fuelType,
    required double liters,
    required double pricePerLiter,
    required double totalPaid,
    required DateTime filledAt,
    String? userCouponId,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Sem utilizador autenticado.');
    }

    await supabase.from('fill_ups').insert({
      'user_id': user.id,
      'vehicle_id': vehicleId,
      'station_name': stationName,
      'fuel_type': fuelType.dbValue,
      'liters': liters,
      'price_per_liter': pricePerLiter,
      'total_paid': totalPaid,
      'filled_at': filledAt.toUtc().toIso8601String(),
      'user_coupon_id': userCouponId,
    });

    if (userCouponId != null) {
      final couponRow = await supabase
          .from('user_coupons')
          .select('times_used, usage_limit, is_active, valid_from, valid_until')
          .eq('id', userCouponId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (couponRow != null) {
        final int currentUses = (couponRow['times_used'] as int?) ?? 0;
        final int? limit = couponRow['usage_limit'] as int?;
        final bool isActive = couponRow['is_active'] as bool? ?? true;

        final String? validFromStr = couponRow['valid_from'] as String?;
        final String? validUntilStr = couponRow['valid_until'] as String?;

        DateTime? validFrom = validFromStr != null
            ? DateTime.tryParse(validFromStr)
            : null;
        DateTime? validUntil = validUntilStr != null
            ? DateTime.tryParse(validUntilStr)
            : null;

        final now = DateTime.now().toUtc();
        final today = DateTime.utc(now.year, now.month, now.day);

        final bool inStart = validFrom == null || !validFrom.isAfter(today);
        final bool inEnd = validUntil == null || !validUntil.isBefore(today);
        final bool isWithinDateRange = inStart && inEnd;

        final int newUses = currentUses + 1;

        bool newIsActive = isActive;

        if (!isWithinDateRange) {
          newIsActive = false;
        } else if (limit != null) {
          newIsActive = newUses < limit;
        } else {
          newIsActive = true;
        }

        await supabase
            .from('user_coupons')
            .update({
              'times_used': newUses,
              'is_active': newIsActive,
              'last_used_at': today.toIso8601String(),
            })
            .eq('id', userCouponId)
            .eq('user_id', user.id);
      }
    }
  }

  Future<void> updateFillUp({
    required String id,
    String? stationName,
    String? vehicleId, // novo
    required FuelType fuelType,
    required double liters,
    required double pricePerLiter,
    required double totalPaid,
    required DateTime filledAt,
    String? userCouponId,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Sem utilizador autenticado.');

    final existingRow = await supabase
        .from('fill_ups')
        .select('user_coupon_id')
        .eq('id', id)
        .eq('user_id', user.id)
        .maybeSingle();

    if (existingRow == null) {
      throw Exception('Abastecimento não encontrado.');
    }

    final String? oldCouponId = existingRow['user_coupon_id'] as String?;

    await supabase
        .from('fill_ups')
        .update({
          'station_name': stationName,
          'vehicle_id': vehicleId,
          'fuel_type': fuelType.dbValue,
          'liters': liters,
          'price_per_liter': pricePerLiter,
          'total_paid': totalPaid,
          'filled_at': filledAt.toUtc().toIso8601String(),
          'user_coupon_id': userCouponId,
        })
        .eq('id', id)
        .eq('user_id', user.id);

    if (oldCouponId != userCouponId) {
      if (oldCouponId != null) {
        await _maybeReactivateCoupon(oldCouponId, user.id);
      }

      if (userCouponId != null) {
        final couponRow = await supabase
            .from('user_coupons')
            .select(
              'times_used, usage_limit, is_active, valid_from, valid_until',
            )
            .eq('id', userCouponId)
            .eq('user_id', user.id)
            .maybeSingle();

        if (couponRow != null) {
          final int currentUses = (couponRow['times_used'] as int?) ?? 0;
          final int? limit = couponRow['usage_limit'] as int?;
          final bool isActive = couponRow['is_active'] as bool? ?? true;

          final String? validFromStr = couponRow['valid_from'] as String?;
          final String? validUntilStr = couponRow['valid_until'] as String?;

          DateTime? validFrom = validFromStr != null
              ? DateTime.tryParse(validFromStr)
              : null;
          DateTime? validUntil = validUntilStr != null
              ? DateTime.tryParse(validUntilStr)
              : null;

          final now = DateTime.now().toUtc();
          final today = DateTime.utc(now.year, now.month, now.day);

          final bool inStart = validFrom == null || !validFrom.isAfter(today);
          final bool inEnd = validUntil == null || !validUntil.isBefore(today);
          final bool isWithinDateRange = inStart && inEnd;

          final int newUses = currentUses + 1;

          bool newIsActive = isActive;

          if (!isWithinDateRange) {
            newIsActive = false;
          } else if (limit != null) {
            newIsActive = newUses < limit;
          } else {
            newIsActive = true;
          }

          await supabase
              .from('user_coupons')
              .update({
                'times_used': newUses,
                'is_active': newIsActive,
                'last_used_at': today.toIso8601String(),
              })
              .eq('id', userCouponId)
              .eq('user_id', user.id);
        }
      }
    }
  }

  Future<void> deleteFillUp(String id) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Sem utilizador autenticado.');

    final row = await supabase
        .from('fill_ups')
        .select('user_coupon_id')
        .eq('id', id)
        .eq('user_id', user.id)
        .maybeSingle();

    if (row == null) {
      throw Exception('Abastecimento não encontrado.');
    }

    final String? couponId = row['user_coupon_id'] as String?;

    await supabase
        .from('fill_ups')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);

    if (couponId != null) {
      await _maybeReactivateCoupon(couponId, user.id);
    }
  }

  Future<void> _maybeReactivateCoupon(String couponId, String userId) async {
    final couponRow = await supabase
        .from('user_coupons')
        .select('times_used, usage_limit, is_active, valid_from, valid_until')
        .eq('id', couponId)
        .eq('user_id', userId)
        .maybeSingle();

    if (couponRow == null) return;

    final int currentUses = (couponRow['times_used'] as int?) ?? 0;
    final int? limit = couponRow['usage_limit'] as int?;
    final bool isActive = couponRow['is_active'] as bool? ?? false;

    final String? validFromStr = couponRow['valid_from'] as String?;
    final String? validUntilStr = couponRow['valid_until'] as String?;

    DateTime? validFrom = validFromStr != null
        ? DateTime.tryParse(validFromStr)
        : null;
    DateTime? validUntil = validUntilStr != null
        ? DateTime.tryParse(validUntilStr)
        : null;

    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);

    final bool inStart = validFrom == null || !validFrom.isAfter(today);
    final bool inEnd = validUntil == null || !validUntil.isBefore(today);
    final bool isWithinDateRange = inStart && inEnd;

    final int newUses = currentUses > 0 ? currentUses - 1 : 0;

    bool newIsActive = isActive;

    if (!isWithinDateRange) {
      await supabase
          .from('user_coupons')
          .update({'times_used': newUses, 'is_active': false})
          .eq('id', couponId)
          .eq('user_id', userId);
      return;
    }

    if (limit != null) {
      newIsActive = newUses < limit;
    } else {
      newIsActive = true;
    }

    await supabase
        .from('user_coupons')
        .update({'times_used': newUses, 'is_active': newIsActive})
        .eq('id', couponId)
        .eq('user_id', userId);
  }

  Future<Map<String, Coupon>> getCouponsById(Iterable<String> ids) async {
    final uniqueIds = ids.toSet();
    if (uniqueIds.isEmpty) return {};

    final response = await supabase
        .from('user_coupons')
        .select()
        .inFilter('id', uniqueIds.toList());

    final data = (response as List<dynamic>).cast<Map<String, dynamic>>();

    final map = <String, Coupon>{};
    for (final row in data) {
      final c = Coupon.fromJson(row);
      map[c.id] = c;
    }
    return map;
  }

  Future<double> getLast30DaysTotal() async {
    final now = DateTime.now();
    final limit = now.subtract(const Duration(days: 30));

    final all = await getAllFillUps();
    return all
        .where((f) => f.filledAt.isAfter(limit))
        .fold<double>(0.0, (sum, f) => sum + f.totalPaid);
  }

  Future<void> deleteAllForUser(String userId) async {
    await supabase.from('fill_ups').delete().eq('user_id', userId);
  }

  Future<List<FillUp>> getFillUpsByCouponId(String couponId) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Sem utilizador autenticado.');
    }

    final response = await supabase
        .from('fill_ups')
        .select()
        .eq('user_id', user.id)
        .eq('user_coupon_id', couponId)
        .order('filled_at', ascending: false);

    final data = (response as List<dynamic>).cast<Map<String, dynamic>>();
    return data.map(FillUp.fromJson).toList();
  }
}

class FillUpsSummary {
  final double totalLiters;
  final double totalPaid;
  final double averagePricePerLiter;
  final int count;

  const FillUpsSummary({
    required this.totalLiters,
    required this.totalPaid,
    required this.averagePricePerLiter,
    required this.count,
  });

  static FillUpsSummary empty() {
    return const FillUpsSummary(
      totalLiters: 0,
      totalPaid: 0,
      averagePricePerLiter: 0,
      count: 0,
    );
  }
}
