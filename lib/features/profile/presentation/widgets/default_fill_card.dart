import 'package:flutter/material.dart';
import '../../domain/user_profile.dart';

class DefaultFillCard extends StatelessWidget {
  final UserProfile profile;
  final String fillMode;
  final TextEditingController controller;
  final Function(String) onModeChanged;
  final Function(UserProfile) onProfileChanged;

  const DefaultFillCard({
    super.key,
    required this.profile,
    required this.fillMode,
    required this.controller,
    required this.onModeChanged,
    required this.onProfileChanged,
  });

  void _applyChanges(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final raw = controller.text.replaceAll(',', '.');
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Indica um valor de abastecimento válido.',
            style: textTheme.bodyMedium,
          ),
        ),
      );
      return;
    }

    onProfileChanged(
      profile.copyWith(defaultFillMode: fillMode, defaultFillValue: parsed),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.local_gas_station),
            title: Text('Abastecimento padrão'),
            subtitle: Text('Valor usado na simulação rápida em Postos.'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: fillMode,
                        decoration: const InputDecoration(labelText: 'Modo'),
                        items: const [
                          DropdownMenuItem(
                            value: 'per_value',
                            child: Text('Por valor (€)'),
                          ),
                          DropdownMenuItem(
                            value: 'per_liters',
                            child: Text('Por litros (L)'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          onModeChanged(value);
                          _applyChanges(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: controller,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: fillMode == 'per_liters'
                              ? 'Litros'
                              : 'Valor (€)',
                        ),
                        onEditingComplete: () => _applyChanges(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
