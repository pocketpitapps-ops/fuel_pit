// lib/features/onboarding/presentation/widgets/loyalty_step.dart
import 'package:flutter/material.dart';

import '../../../coupons/data/coupons_repository.dart';
import '../../../coupons/domain/coupon.dart';
import '../../../profile/data/user_profile_repository.dart';
import '../../../profile/domain/user_profile.dart';
import '../../../profile/domain/loyalty_brands.dart';

class LoyaltyStep extends StatefulWidget {
  final UserProfile profile;
  final UserProfileRepository profileRepo;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const LoyaltyStep({
    super.key,
    required this.profile,
    required this.profileRepo,
    required this.onBack,
    required this.onNext,
  });

  @override
  State<LoyaltyStep> createState() => _LoyaltyStepState();
}

class _LoyaltyStepState extends State<LoyaltyStep> {
  late List<String> _loyaltyBrands;
  late Map<String, double> _loyaltyPerLiterDiscounts;

  final Map<String, TextEditingController> _controllers = {};
  late Map<String, CouponBenefitKind> _loyaltyBenefitKinds;

  @override
  void initState() {
    super.initState();
    _loyaltyBrands = List<String>.from(widget.profile.loyaltyBrands);
    _loyaltyPerLiterDiscounts = Map<String, double>.from(
      widget.profile.loyaltyPerLiterDiscounts,
    );

    _loyaltyBenefitKinds = <String, CouponBenefitKind>{};

    // cria um controller por brand conhecida
    for (final brand in knownLoyaltyBrands) {
      final key = brand['key'] as String;
      final controller = TextEditingController(
        text: (_loyaltyPerLiterDiscounts[key] ?? 0).toStringAsFixed(2),
      );
      _controllers[key] = controller;

      // benefit kind default
      _loyaltyBenefitKinds[key] =
          CouponBenefitKind.directDiscount; // ou ler do profile se já tiveres
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool _hasBrand(String key) => _loyaltyBrands.contains(key);

  void _toggleBrand(String key, bool enabled) {
    setState(() {
      if (enabled) {
        if (!_loyaltyBrands.contains(key)) {
          _loyaltyBrands.add(key);
        }
      } else {
        _loyaltyBrands.remove(key);
        _loyaltyPerLiterDiscounts.remove(key);
      }
    });
  }

  Future<void> _save() async {
    // 0) Validar fidelizações ativas com desconto > 0
    for (final brand in knownLoyaltyBrands) {
      final key = brand['key']!;
      final controller = _controllers[key];
      if (controller == null) continue;

      if (_hasBrand(key)) {
        final raw = controller.text.replaceAll(',', '.');
        final discount = double.tryParse(raw) ?? 0;

        if (discount <= 0) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Para ativar uma fidelização, indica um desconto maior que 0 €/L '
                'ou desliga a marca.',
              ),
            ),
          );
          return; // trava o avanço, não grava nem sincroniza cupões
        }
      }
    }

    // 1) Atualizar UserProfile (loyaltyBrands + loyaltyPerLiterDiscounts)
    for (final brand in knownLoyaltyBrands) {
      final key = brand['key']!;
      final controller = _controllers[key];
      if (controller == null) continue;

      if (_hasBrand(key)) {
        _loyaltyPerLiterDiscounts[key] =
            double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
      } else {
        _loyaltyPerLiterDiscounts.remove(key);
      }
    }

    final updatedProfile = widget.profile.copyWith(
      hasCompletedOnboarding: false,
      loyaltyBrands: _loyaltyBrands,
      loyaltyPerLiterDiscounts: _loyaltyPerLiterDiscounts,
    );

    await widget.profileRepo.updateProfile(updatedProfile);

    // 2) Sincronizar cupões permanentes com fidelizações
    final couponsRepo = CouponsRepository();
    final userId = updatedProfile.userId;

    try {
      for (final brand in knownLoyaltyBrands) {
        final key = brand['key']!;
        final discount = _loyaltyPerLiterDiscounts[key] ?? 0;
        final benefitKind =
            _loyaltyBenefitKinds[key] ?? CouponBenefitKind.directDiscount;

        if (_hasBrand(key) && discount > 0) {
          await couponsRepo.upsertPermanentLoyaltyCoupon(
            userId: userId,
            brandKey: key,
            discountPerLiter: discount,
            benefitKind: benefitKind,
          );
        } else {
          await couponsRepo.deletePermanentLoyaltyCoupon(
            userId: userId,
            brandKey: key,
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao sincronizar cupões de fidelização.'),
          ),
        );
      }
    }

    // 3) Avançar para o passo seguinte (cupões)
    if (mounted) {
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Configurar fidelizações',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text(
              'Regista os descontos permanentes (Combina, cartão de combustível, apps de pontos, cashback, etc.).',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: knownLoyaltyBrands.length,
                itemBuilder: (context, index) {
                  final brand = knownLoyaltyBrands[index];
                  final key = brand['key'] as String;
                  final name = brand['name'] as String;
                  final desc = brand['description'] as String;
                  final controller = _controllers[key]!;
                  final benefitKind =
                      _loyaltyBenefitKinds[key] ??
                      CouponBenefitKind.directDiscount;

                  return _BrandLoyaltyTile(
                    brandKey: key,
                    title: name,
                    description: desc,
                    enabled: _hasBrand(key),
                    controller: controller,
                    benefitKind: benefitKind,
                    onBenefitKindChanged: (kind) {
                      setState(() {
                        _loyaltyBenefitKinds[key] = kind;
                      });
                    },
                    onToggle: (v) => _toggleBrand(key, v),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: widget.onBack,
                  child: const Text('Voltar'),
                ),
                const Spacer(),
                ElevatedButton(onPressed: _save, child: const Text('Avançar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandLoyaltyTile extends StatelessWidget {
  final String brandKey;
  final String title;
  final String description;
  final bool enabled;
  final TextEditingController controller;
  final ValueChanged<bool> onToggle;
  final CouponBenefitKind benefitKind;
  final ValueChanged<CouponBenefitKind> onBenefitKindChanged;

  const _BrandLoyaltyTile({
    required this.brandKey,
    required this.title,
    required this.description,
    required this.enabled,
    required this.controller,
    required this.onToggle,
    required this.benefitKind,
    required this.onBenefitKindChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(title),
              subtitle: Text(description),
              value: enabled,
              onChanged: onToggle,
            ),
            if (enabled) ...[
              TextFormField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Desconto permanente (€/L)',
                  suffixText: '€/L',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Desconto direto'),
                    selected: benefitKind == CouponBenefitKind.directDiscount,
                    onSelected: (selected) {
                      if (selected) {
                        onBenefitKindChanged(CouponBenefitKind.directDiscount);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Saldo em cartão'),
                    selected: benefitKind == CouponBenefitKind.cardBalance,
                    onSelected: (selected) {
                      if (selected) {
                        onBenefitKindChanged(CouponBenefitKind.cardBalance);
                      }
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
