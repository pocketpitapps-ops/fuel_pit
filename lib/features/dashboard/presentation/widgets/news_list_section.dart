// lib/pages/widgets/news_list_section.dart

import 'package:flutter/material.dart';
import 'package:fuel_pit/shared/models/news_item.dart';

// lib/pages/widgets/news_list_section.dart

class NewsListSection extends StatelessWidget {
  final List<NewsItem> items;
  final bool isLoading;
  final void Function(String url) onOpenUrl;

  const NewsListSection({
    super.key,
    required this.items,
    required this.isLoading,
    required this.onOpenUrl,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (items.isEmpty) {
      final textTheme = Theme.of(context).textTheme;
      final colorScheme = Theme.of(context).colorScheme;

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Sem notícias de combustível neste momento.',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
        ),
      );
    }

    // Altura aproximada para 5 tiles (5 * ~80px)
    const double containerHeight = 400;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 4.0,
          ).copyWith(bottom: 8),
          child: Text(
            'Notícias de combustível em Portugal',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(
          height: containerHeight,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final news = items[index];
                return ListTile(
                  dense: true,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: news.imageUrl != null && news.imageUrl!.isNotEmpty
                        ? Image.network(
                            news.imageUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            // se der erro de carregamento, cai para imagem genérica
                            errorBuilder: (_, _, _) {
                              return Image.asset(
                                'assets/images/fuel_news_placeholder.png',
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                        : Image.asset(
                            'assets/images/fuel_news_placeholder.png',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                  ),
                  title: Text(
                    news.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    news.sourceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => onOpenUrl(news.url),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
