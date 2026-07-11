import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VehiclePlateField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?) validator;

  const VehiclePlateField({
    super.key,
    required this.controller,
    required this.validator,
  });

  static String? validatePlate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final clean = value.toUpperCase().replaceAll(' ', '');
    if (clean.length != 6) {
      return 'Matrícula deve ter 6 caracteres (sem traços)';
    }

    final pattern1 = RegExp(r'^[A-Z]{2}\d{4}$');
    final pattern2 = RegExp(r'^\d{4}[A-Z]{2}$');
    final pattern3 = RegExp(r'^\d{2}[A-Z]{2}\d{2}$');
    final pattern4 = RegExp(r'^[A-Z]{2}\d{2}[A-Z]{2}$');

    if (!pattern1.hasMatch(clean) &&
        !pattern2.hasMatch(clean) &&
        !pattern3.hasMatch(clean) &&
        !pattern4.hasMatch(clean)) {
      return 'Formato inválido. Exemplos: AA0000, 0000AA, 00AA00, AA00AA';
    }

    return null;
  }

  static String normalizePlate(String raw) {
    final clean = raw.toUpperCase().replaceAll(' ', '');

    if (RegExp(r'^[A-Z]{2}\d{4}$').hasMatch(clean)) {
      return '${clean.substring(0, 2)}-${clean.substring(2, 4)}-${clean.substring(4, 6)}';
    }

    if (RegExp(r'^\d{4}[A-Z]{2}$').hasMatch(clean)) {
      return '${clean.substring(0, 2)}-${clean.substring(2, 4)}-${clean.substring(4, 6)}';
    }

    if (RegExp(r'^\d{2}[A-Z]{2}\d{2}$').hasMatch(clean)) {
      return '${clean.substring(0, 2)}-${clean.substring(2, 4)}-${clean.substring(4, 6)}';
    }

    if (RegExp(r'^[A-Z]{2}\d{2}[A-Z]{2}$').hasMatch(clean)) {
      return clean;
    }

    return clean;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.characters,
      decoration: const InputDecoration(
        labelText: 'Matrícula (opcional)',
        hintText: 'AA00AA / AA0000 / 00AA00 / 0000AA',
        prefixIcon: Icon(Icons.badge),
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
        LengthLimitingTextInputFormatter(6),
      ],
      validator: validator,
    );
  }
}
