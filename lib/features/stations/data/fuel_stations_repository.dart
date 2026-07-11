// lib/app_services/db/fuel_stations_repository.dart
import 'dart:math';

import '../domain/station.dart';
import '../../../shared/models/fuel_type.dart';
import '../../../core/supabase_client.dart';

double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const earthRadiusKm = 6371.0;

  final dLat = _degToRad(lat2 - lat1);
  final dLon = _degToRad(lng2 - lng1);

  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_degToRad(lat1)) *
          cos(_degToRad(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);

  final c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadiusKm * c;
}

double _degToRad(double deg) => deg * pi / 180.0;

class FuelStationsRepository {
  Future<List<Station>> getNearbyStations({
    required double userLat,
    required double userLng,
    required FuelType fuelType,
    required double radiusKm,
    int limit = 50,
  }) async {
    // 1) Ler da view
    final response = await supabase
        .from('view_stations_with_prices')
        .select()
        .eq('fuel_type', fuelType.dbValue);

    final data = (response as List<dynamic>).cast<Map<String, dynamic>>();

    // 2) Transformar em Station
    final allStations = data.map(Station.fromJson).toList();

    // 3) Calcular distância e filtrar por raio
    final withDistances = allStations.map((s) {
      if (s.latitude != null && s.longitude != null) {
        final d = distanceKm(userLat, userLng, s.latitude!, s.longitude!);
        return s.copyWith(distanceKm: d);
      } else {
        return s;
      }
    }).toList();

    final filtered = withDistances
        .where((s) => s.distanceKm != null && s.distanceKm! <= radiusKm)
        .toList();

    // 4) Ordenar por distância e limitar
    filtered.sort((a, b) {
      final da = a.distanceKm ?? double.infinity;
      final db = b.distanceKm ?? double.infinity;
      return da.compareTo(db);
    });

    if (filtered.length > limit) {
      return filtered.sublist(0, limit);
    }
    return filtered;
  }

  Future<List<Station>> getByMunicipality({
    required String municipality,
    required FuelType fuelType,
  }) async {
    final response = await supabase
        .from('view_stations_with_prices')
        .select()
        .eq('fuel_type', fuelType.dbValue)
        .eq('municipality', municipality)
        .order('name', ascending: true);

    final data = (response as List<dynamic>).cast<Map<String, dynamic>>();
    return data.map(Station.fromJson).toList();
  }

  Future<List<Station>> getAllStations({FuelType? fuelType}) async {
    var query = supabase.from('view_stations_with_prices').select();

    if (fuelType != null) {
      query = query.eq('fuel_type', fuelType.dbValue);
    }

    final response = await query
        .order('municipality', ascending: true)
        .order('name', ascending: true);

    final data = (response as List<dynamic>).cast<Map<String, dynamic>>();

    return data.map(Station.fromJson).toList();
  }

  Future<void> setFavorite({
    required int stationId,
    required bool isFavorite,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    if (isFavorite) {
      await supabase.from('user_favorite_stations').upsert({
        'user_id': user.id,
        'station_id': stationId,
      });
    } else {
      await supabase
          .from('user_favorite_stations')
          .delete()
          .eq('user_id', user.id)
          .eq('station_id', stationId);
    }
  }
}
