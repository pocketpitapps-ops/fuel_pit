// lib\core\supabase_config.dart
class SupabaseConfig {
  // URL base do seu projeto (ex: https://xxxx.supabase.co)
  static const String supabaseUrl = 'https://enharpxjvmwssnvfodma.supabase.co';

  // Se for usar supabase_flutter, você normalmente não precisa
  // desse campo aqui. Mas vou deixar caso você queira usar manualmente.
  static const String anonKey = 'COLOCA_A_SUA_ANON_KEY_AQUI';

  // Endpoint do Edge Function
  static String fuelNewsUrl() => '$supabaseUrl/functions/v1/fuel-news';
}
