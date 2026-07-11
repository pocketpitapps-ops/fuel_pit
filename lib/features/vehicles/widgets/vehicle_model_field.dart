// lib\features\vehicles\widgets\vehicle_model_field.dart
import 'package:flutter/material.dart';

class VehicleModelField extends StatelessWidget {
  final String? brand;
  final String? model;
  final List<String> models;
  final Map<String, Map<String, List<String>>> data;
  final void Function(String? model, String? inferredType) onChanged;

  const VehicleModelField({
    super.key,
    required this.brand,
    required this.model,
    required this.models,
    required this.data,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Modelo *'),
          initialValue: model,
          items: models
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          validator: (value) {
            if (brand == null) {
              return 'Escolhe primeiro a marca';
            }
            return value == null ? 'Escolhe o modelo' : null;
          },
          onChanged: (brand == null)
              ? null
              : (value) {
                  if (value == null) return;

                  String? inferredType;
                  data.forEach((typeKey, brandsMap) {
                    final modelsForBrand = brandsMap[brand];
                    if (modelsForBrand != null &&
                        modelsForBrand.contains(value)) {
                      inferredType = typeKey;
                    }
                  });

                  onChanged(value, inferredType);
                },
        ),
        if (brand == null) ...[
          const SizedBox(height: 4),
          Text(
            'Escolhe primeiro a marca para veres os modelos disponíveis.',
            style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
          ),
        ],
      ],
    );
  }
}
