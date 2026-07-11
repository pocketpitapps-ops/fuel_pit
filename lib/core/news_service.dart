// lib/app_services/news_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/models/news_item.dart';

abstract class NewsService {
  Future<List<NewsItem>> fetchNews({String? topic});
}

class FuelNewsService implements NewsService {
  FuelNewsService();

  final SupabaseClient _client = Supabase.instance.client;

  @override
  Future<List<NewsItem>> fetchNews({String? topic}) async {
    final body = (topic != null && topic.trim().isNotEmpty)
        ? {'topic': topic.trim()}
        : null;

    try {
      final response = await _client.functions.invoke('fuel-news', body: body);

      final data = response.data;

      if (data == null || data['articles'] == null) {
        return [];
      }

      final List<dynamic> articles = data['articles'] as List<dynamic>;

      return articles
          .whereType<Map<String, dynamic>>()
          .map(NewsItem.fromJson)
          .toList();
    } catch (e) {
      // Podes logar o erro aqui se quiseres
      rethrow;
    }
  }
}
