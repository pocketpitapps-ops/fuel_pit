import 'package:flutter/material.dart';

class VehicleTankField extends StatelessWidget {
  final TextEditingController controller;

  const VehicleTankField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Capacidade do depósito (L) (opcional)',
        prefixIcon: Icon(Icons.local_gas_station),
      ),
    );
  }
}
