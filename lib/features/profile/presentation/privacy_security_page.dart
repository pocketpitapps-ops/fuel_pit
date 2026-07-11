// lib/features/profile/presentation/privacy_security_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/user_profile.dart';
import '../data/user_profile_repository.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_section_title.dart';

/// Página de Conta, Privacidade e Segurança.
/// Agrupa: conta e sessão, segurança (password),
/// informação legal e ações de conta (eliminar conta).
class PrivacySecurityPage extends StatefulWidget {
  final VoidCallback onDeleteAccount;

  const PrivacySecurityPage({super.key, required this.onDeleteAccount});

  @override
  State<PrivacySecurityPage> createState() => _PrivacySecurityPageState();
}

class _PrivacySecurityPageState extends State<PrivacySecurityPage> {
  final _profileRepository = UserProfileRepository();

  late Future<UserProfile> _futureProfile;

  // Form password
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSavingPassword = false;

  @override
  void initState() {
    super.initState();
    _futureProfile = _profileRepository.getForCurrentUser();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Altera a password do utilizador autenticado.
  Future<void> _changePassword() async {
    final next = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (next != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A confirmação de password não coincide.'),
        ),
      );
      return;
    }

    if (next.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A nova password deve ter pelo menos 6 caracteres.'),
        ),
      );
      return;
    }

    setState(() {
      _isSavingPassword = true;
    });

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('Sem utilizador autenticado.');
      }

      await client.auth.updateUser(UserAttributes(password: next));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password alterada com sucesso.')),
      );

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao alterar password: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPassword = false;
        });
      }
    }
  }

  /// Abre links de política/termos (por enquanto apenas mostra SnackBar).
  Future<void> _openLegalLink(String type) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Abrir $type (por implementar).')));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conta, privacidade e segurança'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<UserProfile>(
          future: _futureProfile,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || snapshot.data == null) {
              return Center(
                child: Text(
                  'Erro ao carregar dados de conta:\n${snapshot.error ?? ''}',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              );
            }

            final profile = snapshot.data!;

            return ListView(
              children: [
                const AppSectionTitle(title: 'Conta, privacidade e segurança'),
                _AccountSessionCard(profile: profile),

                const AppSectionTitle(title: 'Segurança'),
                _PasswordCard(
                  currentPasswordController: _currentPasswordController,
                  newPasswordController: _newPasswordController,
                  confirmPasswordController: _confirmPasswordController,
                  isSaving: _isSavingPassword,
                  onSave: _changePassword,
                ),

                const AppSectionTitle(title: 'Informação legal'),
                _LegalInfoCard(onOpenLink: _openLegalLink),

                const AppSectionTitle(title: 'Ações de conta'),
                AppCard(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.delete_forever,
                          color: colorScheme.error,
                        ),
                        title: const Text('Eliminar conta'),
                        subtitle: const Text(
                          'Ação permanente. Usa apenas se deixares de usar a app.',
                        ),
                        onTap: widget.onDeleteAccount,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Mostra um resumo da conta (email e ID).
class _AccountSessionCard extends StatelessWidget {
  final UserProfile profile;

  const _AccountSessionCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final email = profile.email ?? 'Sem email associado';
    final userId = profile.userId;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 32,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    email,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: $userId',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Form para alterar a password.
class _PasswordCard extends StatelessWidget {
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final bool isSaving;
  final VoidCallback onSave;

  const _PasswordCard({
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password atual',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nova password',
                prefixIcon: Icon(Icons.lock_reset),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar nova password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                ),
                onPressed: isSaving ? null : onSave,
                child: isSaving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : const Text('Alterar password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Links para política de privacidade e termos.
class _LegalInfoCard extends StatelessWidget {
  final Future<void> Function(String type) onOpenLink;

  const _LegalInfoCard({required this.onOpenLink});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.privacy_tip_outlined,
              color: colorScheme.primary,
            ),
            title: const Text('Política de privacidade'),
            subtitle: const Text('Como tratamos os teus dados'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onOpenLink('política de privacidade'),
          ),
          const Divider(height: 0),
          ListTile(
            leading: Icon(
              Icons.description_outlined,
              color: colorScheme.primary,
            ),
            title: const Text('Termos de utilização'),
            subtitle: const Text('Condições de uso da Fuel Pit'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onOpenLink('termos de utilização'),
          ),
        ],
      ),
    );
  }
}
