import 'package:flutter/material.dart';

import '../../../../core/config/vehicle_type_config.dart';

class VehicleTypeField extends StatelessWidget {
  final String? vehicleTypeId;
  final Map<String, List<String>> brandsByType;
  final ValueChanged<String?> onChanged;

  const VehicleTypeField({
    super.key,
    required this.vehicleTypeId,
    required this.brandsByType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final typeIcon = iconForVehicleType(vehicleTypeId);

    return Row(
      children: [
        CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: typeIcon == null
              ? const Icon(Icons.directions_car)
              : Icon(typeIcon, color: colorScheme.onPrimaryContainer),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Tipo de veículo *'),
            initialValue: vehicleTypeId,
            items: brandsByType.keys
                .map(
                  (typeId) => DropdownMenuItem(
                    value: typeId,
                    child: Text(kVehicleTypeLabels[typeId] ?? typeId),
                  ),
                )
                .toList(),
            validator: (value) =>
                value == null ? 'Escolhe o tipo de veículo' : null,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
