// lib/pages/widgets/preference_card.dart
import 'package:flutter/material.dart';
import 'app_card.dart';

class PreferenceCard extends StatelessWidget {
  final String title;
  final String? description;
  final Widget child;

  const PreferenceCard({
    super.key,
    required this.title,
    this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.titleMedium),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
            ],
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
