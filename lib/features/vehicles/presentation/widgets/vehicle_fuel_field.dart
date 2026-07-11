import 'package:flutter/material.dart';

import '../../../../shared/models/fuel_type.dart';
import '../../../../shared/widgets/fuel_type_dropdown.dart';

class VehicleFuelField extends StatelessWidget {
  final FuelType value;
  final ValueChanged<FuelType> onChanged;

  const VehicleFuelField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FuelTypeDropdown(
      value: value,
      label: 'Combustível *',
      onChanged: onChanged,
    );
  }
}
