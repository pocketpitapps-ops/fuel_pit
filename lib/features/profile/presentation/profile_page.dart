// lib/features/profile/presentation/profile_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import '../../../main.dart';
import '../../auth/auth_notifier.dart';
import '../../fillups/data/fillups_repository.dart';
import '../../coupons/data/coupons_repository.dart';
import '../domain/user_profile.dart';
import '../../vehicles/domain/vehicle.dart';
import '../data/user_profile_repository.dart';
import '../../vehicles/data/vehicles_repository.dart';
import 'edit_personal_data_page.dart';
import 'privacy_security_page.dart';
import '../../vehicles/presentation/vehicles_page.dart';
import '../../../shared/widgets/app_section_title.dart';
import '../../../shared/widgets/app_card.dart';
import 'widgets/profile_header_card.dart';
import 'widgets/vehicles_strip_card.dart';
import 'preferences_page.dart';

/// Página de perfil (hub):
/// - Dados pessoais
/// - Veículos
/// - Preferências da app
/// - Conta e sessão
/// - Terminar sessão (no fim)
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _profileRepository = UserProfileRepository();
  final _vehiclesRepository = VehiclesRepository();
  final _fillUpsRepository = FillUpsRepository();
  final _couponsRepository = CouponsRepository();
  late Future<UserProfile> _futureProfile;

  Vehicle? _defaultVehicle;
  bool _loadingVehicle = false;

  List<Vehicle> _allVehicles = [];
  bool _loadingAllVehicles = false;

  @override
  void initState() {
    super.initState();

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      _futureProfile = _profileRepository.getForCurrentUser();
      _loadDefaultVehicle();
    }
  }

  Future<void> _loadDefaultVehicle() async {
    setState(() {
      _loadingVehicle = true;
      _loadingAllVehicles = true;
    });

    try {
      final vehicle = await _vehiclesRepository.getDefaultVehicle();
      final all = await _vehiclesRepository.getAllVehicles();
      if (!mounted) return;
      setState(() {
        _defaultVehicle = vehicle;
        _allVehicles = all;
        _loadingVehicle = false;
        _loadingAllVehicles = false;
      });
    } catch (_) {
      debugPrint('Failed to load vehicles: $_');
      if (!mounted) return;
      setState(() {
        _defaultVehicle = null;
        _allVehicles = [];
        _loadingVehicle = false;
        _loadingAllVehicles = false;
      });
    }
  }

  /// Terminar sessão com confirmação.
  Future<void> _logout() async {
    final auth = context.read<AuthNotifier>();

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Terminar sessão'),
          content: const Text(
            'Tens a certeza que queres terminar sessão nesta conta?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Terminar sessão'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    await auth.fullLogout(); // <- usar fullLogout em vez de logout
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthOrHomeRoot()),
      (route) => false,
    );
  }

  Future<void> _deleteAccount() async {
    final auth = context.read<AuthNotifier>();
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar conta'),
          content: const Text(
            'Esta ação é permanente.\n\n'
            'Os teus dados nesta app (perfil, veículos, abastecimentos, '
            'cupões) serão removidos deste dispositivo. Queres continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Eliminar conta'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Sem sessão iniciada.');
      }
      final userId = user.id;

      // 1) Limpar dados do utilizador nas tabelas da app
      await _fillUpsRepository.deleteAllForUser(userId);
      await _couponsRepository.deleteAllForUser(userId);
      await _vehiclesRepository.deleteAllForUser(userId);
      await _profileRepository.deleteProfileForUser(userId);

      // 2) Chamar Edge Function para apagar o utilizador de auth.users
      final client = Supabase.instance.client;
      final session = client.auth.currentSession;

      if (session == null) {
        throw Exception('Sem sessão ativa para eliminar conta.');
      }

      await client.functions.invoke(
        'delete-user',
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );

      // 3) Logout local (ignora erro de network aqui)
      try {
        await auth.logout();
      } catch (_) {
        // Silently ignore: user already deleted — logout may fail on stale session
      }

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Conta eliminada nesta app.')),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthOrHomeRoot()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erro ao eliminar conta: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // Guard: em guest não pode ver nem gerir perfil.
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil'), centerTitle: true),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_outline, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Inicia sessão para gerir o teu perfil.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // volta ao HomeShell actual
                  },
                  child: const Text('Iniciar sessão'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<UserProfile>(
          future: _futureProfile,
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting ||
                (_loadingVehicle || _loadingAllVehicles) &&
                    _defaultVehicle == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (profileSnapshot.hasError || profileSnapshot.data == null) {
              return Center(
                child: Text(
                  'Erro ao carregar perfil:\n${profileSnapshot.error ?? 'Sem dados.'}',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              );
            }

            final profile = profileSnapshot.data!;
            final orderedVehicles = List<Vehicle>.from(_allVehicles);

            if (_defaultVehicle != null) {
              orderedVehicles.sort((a, b) {
                if (a.id == _defaultVehicle!.id &&
                    b.id != _defaultVehicle!.id) {
                  return -1;
                }
                if (b.id == _defaultVehicle!.id &&
                    a.id != _defaultVehicle!.id) {
                  return 1;
                }
                return 0;
              });
            }

            return ListView(
              children: [
                // Secção: Dados pessoais
                const AppSectionTitle(title: 'Dados pessoais'),
                ProfileHeaderCard(
                  profile: profile,
                  onTap: () async {
                    final changed = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => EditPersonalDataPage(profile: profile),
                      ),
                    );
                    if (changed == true) {
                      setState(() {
                        _futureProfile = _profileRepository.getForCurrentUser();
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Secção: Veículos
                const AppSectionTitle(title: 'Veículos'),
                VehiclesStripCard(
                  vehicles: orderedVehicles,
                  defaultVehicle: _defaultVehicle,
                  onTap: () async {
                    await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => const VehiclesPage()),
                    );
                    if (!mounted) return;
                    await _loadDefaultVehicle();
                  },
                ),

                const SizedBox(height: 16),

                // Secção: Preferências (abre página própria)
                const AppSectionTitle(title: 'Preferências'),
                AppCard(
                  child: ListTile(
                    leading: Icon(Icons.tune, color: colorScheme.primary),
                    subtitle: const Text(
                      'Moeda, abastecimento padrão, retenção de cupões '
                      'e notificações.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PreferencesPage(profile: profile),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Secção: Conta e sessão
                const AppSectionTitle(title: 'Conta, privacidade e segurança'),
                AppCard(
                  child: ListTile(
                    leading: Icon(
                      Icons.security_outlined,
                      color: colorScheme.primary,
                    ),
                    subtitle: const Text(
                      'Sessão, password, informação legal e ações de conta.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PrivacySecurityPage(
                            onDeleteAccount: _deleteAccount,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 32),

                // Terminar sessão no fim da página
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.exit_to_app, color: colorScheme.error),
                    label: const Text('Terminar sessão'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                    ),
                    onPressed: _logout,
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
