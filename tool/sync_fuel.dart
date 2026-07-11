// tool/sync_fuel.dart
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart';

/// CONFIGURAÇÃO
///
/// ATUALIZA ESTES DOIS VALORES:
const supabaseUrl = 'https://enharpxjvmwssnvfodma.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVuaGFycHhqdm13c3NudmZvZG1hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk3NzUxNzIsImV4cCI6MjA5NTM1MTE3Mn0.yzJvj4CmF-eau8tlqk32dKGqR-IdBTuXqqJcVyIR6w0'; // NÃO commits isto público

// Endpoint da API Aberta que devolve postos individuais
const apiStationsUrl = 'https://api.apiaberta.pt/v1/fuel/stations';

// Se usares API key deles, define aqui
const apiAbertaKey = 'ak_I_fz0Wn3PxVFLd6AxIWQDv_WOjGeRq0R';

Future<void> main() async {
  debugPrint('*** MAIN DO sync_fuel.dart ***');
  try {
    debugPrint('A buscar postos da API Aberta...');
    final stations = await _fetchStations();

    debugPrint('Recebidos ${stations.length} registos (posto + combustível).');

    // Para cada linha (station_id + fuel_name + price)
    for (final item in stations) {
      final stationId = await _upsertStationFromItem(item);
      await _insertPriceFromItem(stationId, item);
    }

    debugPrint('Sync concluído com sucesso.');
  } catch (e, st) {
    debugPrint('Erro no sync: $e');
    debugPrint(st.toString()); // ou: debugPrint('$st');
    exitCode = 1;
  }
}

Future<List<Map<String, dynamic>>> _fetchStations() async {
  final headers = <String, String>{};
  if (apiAbertaKey.isNotEmpty) {
    headers['X-API-Key'] = apiAbertaKey;
  }

  final all = <Map<String, dynamic>>[];
  var page = 1;

  while (true) {
    final url = Uri.parse('$apiStationsUrl?page=$page');
    final resp = await http.get(url, headers: headers);

    if (resp.statusCode != 200) {
      throw Exception(
        'Erro ao chamar API Aberta (${resp.statusCode}) na página $page: ${resp.body}',
      );
    }

    final body = jsonDecode(resp.body);

    if (body is! Map<String, dynamic> || body['data'] is! List) {
      throw Exception(
        'Formato inesperado na resposta da API Aberta (página $page)',
      );
    }

    final meta = body['meta'] as Map<String, dynamic>?;
    final data = (body['data'] as List).cast<Map<String, dynamic>>();

    if (data.isEmpty) {
      break;
    }

    all.addAll(data);

    // Se tivermos informação de páginas, usamos para parar
    final pages = meta?['pages'] as int?;
    if (pages != null && page >= pages) {
      break;
    }

    // Evitar bater no rate limit: 60 req/min → ~1 req/s é seguro
    await Future.delayed(const Duration(milliseconds: 800));

    page++;
  }

  return all;
}

Future<int> _upsertStationFromItem(Map<String, dynamic> item) async {
  // station_id da API Aberta → dgeg_id na tua tabela (int4)
  final externalId = item['station_id'] as int;
  final name = item['name'] as String;
  final brand = item['brand'] as String?;
  final address = item['address'] as String?;
  final district = item['district'] as String?;
  final municipality = item['municipality'] as String?;
  final locality = item['locality'] as String?;
  final postalCode = item['postal_code'] as String?;
  final location = item['location'] as Map<String, dynamic>?;
  final latitude = (location?['lat'] as num?)?.toDouble();
  final longitude = (location?['lng'] as num?)?.toDouble();

  // IMPORTANTE: fuel_stations.dgeg_id deve ser UNIQUE
  final url = Uri.parse('$supabaseUrl/rest/v1/fuel_stations?select=id');

  final headers = {
    'apikey': supabaseAnonKey,
    'Authorization': 'Bearer $supabaseAnonKey',
    'Content-Type': 'application/json',
    // pedimos representação para garantir que há JSON no body
    'Prefer': 'resolution=merge-duplicates,return=representation',
  };

  final body = jsonEncode({
    'dgeg_id': externalId,
    'name': name,
    'brand': brand,
    'address': address,
    'district': district,
    'municipality': municipality,
    'locality': locality,
    'postal_code': postalCode,
    'latitude': latitude,
    'longitude': longitude,
    'is_active': true,
  });

  final resp = await http.post(url, headers: headers, body: body);

  if (resp.statusCode != 201 && resp.statusCode != 200) {
    throw Exception(
      'Erro ao upsert fuel_stations (${resp.statusCode}): ${resp.body}',
    );
  }

  // Algumas combinações de Prefer podem devolver corpo vazio.
  if (resp.body.isEmpty) {
    // Se não houver representação, faz um select pelo dgeg_id para obter o id.
    final getUrl = Uri.parse(
      '$supabaseUrl/rest/v1/fuel_stations?dgeg_id=eq.$externalId&select=id&limit=1',
    );
    final getResp = await http.get(
      getUrl,
      headers: {
        'apikey': supabaseAnonKey,
        'Authorization': 'Bearer $supabaseAnonKey',
      },
    );

    if (getResp.statusCode != 200) {
      throw Exception(
        'Erro a obter station_id (${getResp.statusCode}): ${getResp.body}',
      );
    }

    final list = jsonDecode(getResp.body) as List<dynamic>;
    if (list.isEmpty) {
      throw Exception(
        'Não foi possível encontrar station com dgeg_id=$externalId',
      );
    }
    final row = list.first as Map<String, dynamic>;
    return row['id'] as int;
  }

  final data = jsonDecode(resp.body) as List<dynamic>;
  final row = data.first as Map<String, dynamic>;
  return row['id'] as int;
}

Future<void> _insertPriceFromItem(
  int stationId,
  Map<String, dynamic> item,
) async {
  final fuelName = item['fuel_name'] as String; // ex: 'Gasolina simples 95'
  final price = (item['price_eur'] as num).toDouble();
  final updatedAt = item['updated_at'] as String?;

  final url = Uri.parse('$supabaseUrl/rest/v1/fuel_prices');

  final headers = {
    'apikey': supabaseAnonKey,
    'Authorization': 'Bearer $supabaseAnonKey',
    'Content-Type': 'application/json',
  };

  final body = jsonEncode({
    'station_id': stationId,
    'fuel_type': fuelName,
    'price_per_liter': price,
    'source': 'apiaberta',
    'valid_from': updatedAt ?? DateTime.now().toUtc().toIso8601String(),
  });

  final resp = await http.post(url, headers: headers, body: body);

  if (resp.statusCode != 201 && resp.statusCode != 200) {
    throw Exception(
      'Erro ao inserir fuel_prices (${resp.statusCode}): ${resp.body}',
    );
  }
}
