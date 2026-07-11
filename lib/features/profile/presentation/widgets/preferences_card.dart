import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../main.dart' show themeModeNotifier;
import '../../../../shared/widgets/app_card.dart';

class PreferencesCard extends StatelessWidget {
  const PreferencesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.notifications_outlined,
              color: colorScheme.primary,
            ),
            title: const Text('Notificações'),
            subtitle: const Text(
              'Alertas de preços e lembretes de abastecimento',
            ),
            trailing: Switch(
              value: true, // futuro: ligar ao UserProfile.notificationsEnabled
              onChanged: (value) {
                // futuro: guardar preferência
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
