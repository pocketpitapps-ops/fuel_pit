// lib/features/profile/presentation/widgets/preferences_card_updated.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/user_profile.dart';
import '../../../../main.dart' show themeModeNotifier;

class PreferencesCardUpdated extends StatelessWidget {
  final UserProfile profile;
  final Function(UserProfile) onProfileChanged;

  const PreferencesCardUpdated({
    super.key,
    required this.profile,
    required this.onProfileChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.notifications_outlined,
              color: colorScheme.primary,
            ),
            title: const Text('Notificações'),
            subtitle: Text(
              'Alertas de preços e lembretes de abastecimento',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
            trailing: Switch(
              value: profile.notificationsEnabled,
              onChanged: (value) {
                onProfileChanged(profile.copyWith(notificationsEnabled: value));
              },
            ),
          ),
          const Divider(height: 0),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeModeNotifier,
            builder: (context, mode, _) {
              final isDarkMode = mode == ThemeMode.dark;

              return ListTile(
                leading: Icon(
                  Icons.dark_mode_outlined,
                  color: colorScheme.primary,
                ),
                title: const Text('Tema escuro'),
                trailing: Switch(
                  value: isDarkMode,
                  onChanged: (value) async {
                    themeModeNotifier.value = value
                        ? ThemeMode.dark
                        : ThemeMode.light;
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString(
                      'theme_mode',
                      value ? 'dark' : 'light',
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
