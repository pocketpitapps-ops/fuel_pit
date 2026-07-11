// lib/pages/profile/widgets/currency_card.dart
import 'package:flutter/material.dart';

import '../../domain/user_profile.dart';

class CurrencyCard extends StatelessWidget {
  final UserProfile profile;
  final Function(UserProfile) onProfileChanged;

  const CurrencyCard({
    super.key,
    required this.profile,
    required this.onProfileChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        leading: Icon(Icons.euro, color: colorScheme.primary),
        title: const Text('Moeda'),
        subtitle: Text(profile.currency),
        trailing: Icon(Icons.chevron_right, color: colorScheme.outline),
        onTap: () async {
          final options = ['EUR', 'USD', 'GBP', 'BRL', 'JPY'];

          final newCurrency = await showModalBottomSheet<String>(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (context) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: options.map((c) {
                  final isSelected = c == profile.currency;
                  return ListTile(
                    leading: isSelected
                        ? Icon(Icons.check, color: colorScheme.primary)
                        : null,
                    title: Text(c),
                    onTap: () => Navigator.of(context).pop(c),
                  );
                }).toList(),
              );
            },
          );

          if (newCurrency != null && newCurrency != profile.currency) {
            onProfileChanged(profile.copyWith(currency: newCurrency));
          }
        },
      ),
    );
  }
}
