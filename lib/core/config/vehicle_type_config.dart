//lib\config\vehicle_type_config.dart
import 'package:flutter/material.dart';

/// Map explícito baseado nos IDs dos tipos
///  - carro
///  - jipe
///  - carrinha
///  - moto
const Map<String, IconData> kVehicleTypeIcons = {
  'carro': Icons.directions_car,
  'jipe': Icons.directions_car_filled,
  'carrinha': Icons.directions_car,
  'moto': Icons.two_wheeler,
};

/// Labels bonitos para cada tipo
const Map<String, String> kVehicleTypeLabels = {
  'carro': 'Carro',
  'jipe': 'Jipe / SUV',
  'carrinha': 'Carrinha / monovolume',
  'moto': 'Moto',
};

IconData? iconForVehicleType(String? rawTypeIdOrLabel) {
  if (rawTypeIdOrLabel == null || rawTypeIdOrLabel.trim().isEmpty) {
    return null; // sem tipo -> sem ícone
  }

  final raw = rawTypeIdOrLabel.trim();
  final lower = raw.toLowerCase(); // ex.: 'carro', 'carro / suv', 'moto'

  // 1) tenta usar o id diretamente, se já vier num formato conhecido
  //    (por ex. 'carro', 'moto', 'carrinha', 'jipe')
  final exactIdIcon = kVehicleTypeIcons[lower];
  if (exactIdIcon != null) return exactIdIcon;

  // 2) tenta inferir um id a partir de um label mais solto (ex.: 'Carro', 'Carro / SUV')
  String? inferredId;
  if (lower.contains('carro')) inferredId = 'carro';
  if (lower.contains('jipe') || lower.contains('suv')) inferredId = 'jipe';
  if (lower.contains('carrinha') || lower.contains('mono')) {
    inferredId = 'carrinha';
  }
  if (lower.contains('moto')) inferredId = 'moto';

  if (inferredId != null) {
    final icon = kVehicleTypeIcons[inferredId];
    if (icon != null) return icon;
  }

  // 3) tipo desconhecido -> sem ícone
  return null;
}
