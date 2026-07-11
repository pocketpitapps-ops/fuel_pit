// lib/models/news_item.dart

class NewsItem {
  final String title;
  final String? description;
  final String url;
  final String? imageUrl;
  final DateTime? publishedAt;
  final String sourceName;

  NewsItem({
    required this.title,
    required this.url,
    required this.sourceName,
    this.description,
    this.imageUrl,
    this.publishedAt,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      title: json['title'] as String? ?? 'Sem título',
      description: json['description'] as String?,
      url: json['url'] as String? ?? '',
      imageUrl: json['urlToImage'] as String?, // vem da função fuel-news
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'] as String)
          : null,
      sourceName: (json['source'] is Map && json['source']['name'] != null)
          ? json['source']['name'] as String
          : 'Desconhecido',
    );
  }
}
