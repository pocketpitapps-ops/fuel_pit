// lib/app_services/db/vehicles_repository.dart
import '../domain/vehicle.dart';
import '../../../core/supabase_client.dart';

class VehiclesRepository {
  /// Devolve todos os veículos do utilizador atual.
  Future<List<Vehicle>> getVehicles() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Sem utilizador autenticado.');
    }

    final response = await supabase
        .from('vehicles')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: true);

    final data = (response as List<dynamic>).cast<Map<String, dynamic>>();
    return data.map(Vehicle.fromJson).toList();
  }

  /// Cria um novo veículo; se vier com isDefault=true,
  /// limpa os anteriores para este user.
  Future<void> addVehicle(Vehicle vehicle) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Sem utilizador autenticado.');
    }

    if (vehicle.isDefault) {
      await supabase
          .from('vehicles')
          .update({'is_default': false})
          .eq('user_id', user.id);
    }

    await supabase.from('vehicles').insert({
      'user_id': user.id,
      ...vehicle.toJson(),
    });
  }

  /// Atualiza um veículo existente; se isDefault=true,
  /// garante que é o único default do utilizador.
  Future<void> updateVehicle(Vehicle vehicle) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Sem utilizador autenticado.');
    }

    if (vehicle.isDefault) {
      await supabase
          .from('vehicles')
          .update({'is_default': false})
          .eq('user_id', user.id)
          .neq('id', vehicle.id);
    }

    await supabase
        .from('vehicles')
        .update(vehicle.toJson())
        .eq('id', vehicle.id)
        .eq('user_id', user.id);
  }

  /// Devolve o veículo marcado como principal, se existir.
  Future<Vehicle?> getDefaultVehicle() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Sem utilizador autenticado.');
    }

    // tenta obter o veículo marcado como default para este user
    final response = await supabase
        .from('vehicles')
        .select()
        .eq('user_id', user.id)
        .eq('is_default', true)
        .maybeSingle();

    if (response != null) {
      final v = Vehicle.fromJson(response);
      return v;
    }

    // fallback: se não houver default, escolher o primeiro veículo do user
    final listResponse = await supabase
        .from('vehicles')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: true)
        .limit(1);

    final list = (listResponse as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) return null;

    final first = Vehicle.fromJson(list.first);

    // opcional: marcar esse primeiro como default na BD
    await setDefaultVehicle(first.id);

    return first;
  }

  /// Marca um veículo como principal para o utilizador atual.
  Future<void> setDefaultVehicle(String vehicleId) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Sem utilizador autenticado.');
    }

    await supabase
        .from('vehicles')
        .update({'is_default': false})
        .eq('user_id', user.id);

    await supabase
        .from('vehicles')
        .update({'is_default': true})
        .eq('id', vehicleId)
        .eq('user_id', user.id);
  }

  Future<List<Vehicle>> getAllVehicles() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Sem utilizador autenticado.');

    final res = await supabase.from('vehicles').select().eq('user_id', user.id);

    return (res as List)
        .map((row) => Vehicle.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Apaga um veículo do utilizador atual.
  Future<void> deleteVehicle(String vehicleId) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Sem utilizador autenticado.');
    }

    // Ver se o veículo a apagar é o default
    final vehicleResponse = await supabase
        .from('vehicles')
        .select()
        .eq('id', vehicleId)
        .eq('user_id', user.id)
        .maybeSingle();

    final wasDefault =
        vehicleResponse != null &&
        (vehicleResponse['is_default'] as bool? ?? false);

    // Apagar o veículo
    await supabase
        .from('vehicles')
        .delete()
        .eq('id', vehicleId)
        .eq('user_id', user.id);

    if (!wasDefault) {
      return;
    }

    // Se apagámos o default, garantir outro como principal
    final listResponse = await supabase
        .from('vehicles')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: true)
        .limit(1);

    final list = (listResponse as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) {
      return; // já não há veículos
    }

    final newDefaultId = list.first['id'] as String;
    await setDefaultVehicle(newDefaultId);
  }

  /// Apaga todos os veículos de um utilizador (usado em eliminar conta).
  Future<void> deleteAllForUser(String userId) async {
    await supabase.from('vehicles').delete().eq('user_id', userId);
  }
}
