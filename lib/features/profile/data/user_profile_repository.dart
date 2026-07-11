// lib/features/profile/data/user_profile_repository.dart

import '../domain/user_profile.dart';
import '../../../core/supabase_client.dart';

class UserProfileRepository {
  /// Obtém o perfil do utilizador atual.
  /// Neste cenário assumimos que o trigger em auth.users já criou o perfil.
  Future<UserProfile> getForCurrentUser() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Sem utilizador autenticado.');
    }

    final response = await supabase
        .from('user_profile')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) {
      // Se isto acontecer, é porque o trigger falhou ou ainda não correu.
      throw Exception('Perfil de utilizador não encontrado.');
    }

    return UserProfile.fromJson(response);
  }

  /// Obtém o perfil de um utilizador pelo userId ou devolve null se não existir.
  Future<UserProfile?> fetchProfileByUserId(String userId) async {
    final res = await supabase
        .from('user_profile')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (res == null) return null;
    return UserProfile.fromJson(res);
  }

  /// Update completo a partir de um UserProfile (ecrã de edição de perfil).
  Future<UserProfile> updateProfile(UserProfile profile) async {
    try {
      final res = await supabase
          .from('user_profile')
          .update(profile.toUpdateJson())
          .eq('id', profile.id)
          .select()
          .single();

      return UserProfile.fromJson(res);
    } catch (e) {
      rethrow;
    }
  }

  /// Update “suave” por campos (quando não queres mexer em tudo).
  Future<void> updatePartial({
    required String userId,
    String? fullName,
    String? country,
    String? mobileNumber,
    String? currency,
    bool? notificationsEnabled,
  }) async {
    final data = <String, dynamic>{};

    if (fullName != null) data['full_name'] = fullName;
    if (country != null) data['country'] = country;
    if (mobileNumber != null) data['mobile_number'] = mobileNumber;
    if (currency != null) data['currency'] = currency;
    if (notificationsEnabled != null) {
      data['notifications_enabled'] = notificationsEnabled;
    }

    if (data.isEmpty) return;

    await supabase.from('user_profile').update(data).eq('user_id', userId);
  }

  Future<void> deleteProfileForUser(String userId) async {
    await supabase.from('user_profile').delete().eq('user_id', userId);
  }
}
