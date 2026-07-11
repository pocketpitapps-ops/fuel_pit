// lib\features\vehicles\widgets\vehicle_brand_field.dart
import 'package:flutter/material.dart';

class VehicleBrandField extends StatelessWidget {
  final String? brand;
  final List<String> brands;
  final ValueChanged<String?> onChanged;

  const VehicleBrandField({
    super.key,
    required this.brand,
    required this.brands,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: 'Marca *'),
      initialValue: brand,
      items: brands
          .map((b) => DropdownMenuItem(value: b, child: Text(b)))
          .toList(),
      validator: (value) => value == null ? 'Escolhe a marca' : null,
      onChanged: onChanged,
    );
  }
}
