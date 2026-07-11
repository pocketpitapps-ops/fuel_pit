// lib/features/profile/presentation/widgets/account_actions_card.dart
import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_card.dart';

class AccountActionsCard extends StatelessWidget {
  final VoidCallback onNavigateToPrivacy;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  const AccountActionsCard({
    super.key,
    required this.onNavigateToPrivacy,
    required this.onLogout,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.security_outlined, color: colorScheme.primary),
            title: const Text('Conta e segurança'),
            subtitle: const Text(
              'Gerir sessão, password, privacidade e dados legais.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onNavigateToPrivacy,
          ),
          // Mantemos onLogout / onDeleteAccount nas props para uso em PrivacySecurityPage,
          // mas não mostramos aqui para não tornar essas ações demasiado apelativas
          // na página principal de perfil.
        ],
      ),
    );
  }
}
