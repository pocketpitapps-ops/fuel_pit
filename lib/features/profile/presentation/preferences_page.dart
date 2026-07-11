// lib/features/profile/presentation/preferences_page.dart
import 'package:flutter/material.dart';

import '../domain/user_profile.dart';
import '../data/user_profile_repository.dart';
import 'widgets/currency_card.dart';
import 'widgets/default_fill_card.dart';
import 'widgets/coupon_retention_card.dart';
import 'widgets/preferences_card_updated.dart';
import '../../../shared/widgets/app_section_title.dart';

/// Página para editar preferências da app:
/// - Moeda
/// - Abastecimento padrão
/// - Retenção de cupões
/// - Notificações / outras preferências
class PreferencesPage extends StatefulWidget {
  final UserProfile profile;

  const PreferencesPage({super.key, required this.profile});

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  final _profileRepository = UserProfileRepository();

  late UserProfile _profile;
  final _fillValueController = TextEditingController();
  String _fillMode = 'per_value';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;

    _fillMode = _profile.defaultFillMode;
    _fillValueController.text = _profile.defaultFillValue.toStringAsFixed(
      _profile.isPerLiters ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _fillValueController.dispose();
    super.dispose();
  }

  void _onProfileChanged(UserProfile newProfile) {
    setState(() {
      _profile = newProfile;
    });
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);

    try {
      await _profileRepository.updateProfile(_profile);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preferências guardadas.')));

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao guardar preferências: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferências da app'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const AppSectionTitle(title: 'Moeda'),
            CurrencyCard(
              profile: _profile,
              onProfileChanged: _onProfileChanged,
            ),
            const SizedBox(height: 16),

            const AppSectionTitle(title: 'Abastecimento padrão'),
            DefaultFillCard(
              profile: _profile,
              fillMode: _fillMode,
              controller: _fillValueController,
              onModeChanged: (mode) {
                setState(() => _fillMode = mode);
              },
              onProfileChanged: _onProfileChanged,
            ),
            const SizedBox(height: 16),

            const AppSectionTitle(title: 'Retenção de cupões'),
            CouponRetentionCard(
              profile: _profile,
              onProfileChanged: _onProfileChanged,
            ),
            const SizedBox(height: 16),

            const AppSectionTitle(title: 'Outras preferências'),
            PreferencesCardUpdated(
              profile: _profile,
              onProfileChanged: _onProfileChanged,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _savePreferences,
                child: _isSaving
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
                    : const Text('Guardar preferências'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
