// lib/features/profile/presentation/widgets/coupon_retention_card.dart
import 'package:flutter/material.dart';
import '../../domain/user_profile.dart';

class CouponRetentionCard extends StatefulWidget {
  final UserProfile profile;
  final Function(UserProfile) onProfileChanged;

  const CouponRetentionCard({
    super.key,
    required this.profile,
    required this.onProfileChanged,
  });

  @override
  State<CouponRetentionCard> createState() => _CouponRetentionCardState();
}

class _CouponRetentionCardState extends State<CouponRetentionCard> {
  late int _expiredDays;
  late int _usedDays;

  final List<_RetentionOption> _options = const [
    _RetentionOption(label: '3 meses', days: 90),
    _RetentionOption(label: '6 meses', days: 180),
    _RetentionOption(label: '1 ano', days: 365),
  ];

  @override
  void initState() {
    super.initState();
    _expiredDays = widget.profile.expiredCouponsRetentionDays;
    _usedDays = widget.profile.usedCouponsRetentionDays;
  }

  _RetentionOption _findClosestOption(int days) {
    _RetentionOption best = _options.first;
    int bestDiff = (days - best.days).abs();
    for (final opt in _options.skip(1)) {
      final diff = (days - opt.days).abs();
      if (diff < bestDiff) {
        best = opt;
        bestDiff = diff;
      }
    }
    return best;
  }

  void _updateProfile() {
    widget.onProfileChanged(
      widget.profile.copyWith(
        expiredCouponsRetentionDays: _expiredDays,
        usedCouponsRetentionDays: _usedDays,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expiredSelected = _findClosestOption(_expiredDays);
    final usedSelected = _findClosestOption(_usedDays);

    return Card(
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.sell_outlined),
            title: Text('Retenção de cupões'),
            subtitle: Text(
              'Define por quanto tempo a app mantém cupões expirados e '
              'utilizados na tua conta.',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                DropdownButtonFormField<_RetentionOption>(
                  initialValue: expiredSelected,
                  decoration: const InputDecoration(
                    labelText: 'Cupões expirados',
                  ),
                  items: _options
                      .map(
                        (o) => DropdownMenuItem<_RetentionOption>(
                          value: o,
                          child: Text(o.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _expiredDays = value.days);
                    _updateProfile(); // só atualiza perfil em memória
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<_RetentionOption>(
                  initialValue: usedSelected,
                  decoration: const InputDecoration(
                    labelText: 'Cupões utilizados',
                  ),
                  items: _options
                      .map(
                        (o) => DropdownMenuItem<_RetentionOption>(
                          value: o,
                          child: Text(o.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _usedDays = value.days);
                    _updateProfile(); // só atualiza perfil em memória
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RetentionOption {
  final String label;
  final int days;
  const _RetentionOption({required this.label, required this.days});
}
