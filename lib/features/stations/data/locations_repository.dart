import 'package:fuel_pit/features/stations/domain/municipality.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationsRepository {
  final SupabaseClient supabase;

  LocationsRepository(this.supabase);

  Future<List<Municipality>> getAllMunicipalities() async {
    final response = await supabase.from('distinct_municipalities').select('*');

    final data = (response as List<dynamic>).cast<Map<String, dynamic>>();
    return data.map(Municipality.fromJson).toList();
  }
}
