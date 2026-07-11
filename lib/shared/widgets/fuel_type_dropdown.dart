// lib/pages/widgets/fuel_type_dropdown.dart
import 'package:flutter/material.dart';
import '../models/fuel_type.dart';

class FuelTypeDropdown extends StatelessWidget {
  final FuelType value;
  final ValueChanged<FuelType> onChanged;
  final String label;

  const FuelTypeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Combustível',
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<FuelType>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: FuelType.values
          .map(
            (ft) =>
                DropdownMenuItem<FuelType>(value: ft, child: Text(ft.label)),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        onChanged(value);
      },
    );
  }
}
