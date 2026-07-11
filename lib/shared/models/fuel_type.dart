// lib/models/fuel_type.dart

enum FuelType { gasolina95, gasolina98, gasoleoSimples, gasoleoEspecial, gpl }

extension FuelTypeExt on FuelType {
  /// Valor exatamente igual ao que está gravado na BD (coluna fuel_type)
  String get dbValue {
    switch (this) {
      case FuelType.gasolina95:
        return 'Gasolina simples 95';
      case FuelType.gasolina98:
        return 'Gasolina especial 98'; // ajustar quando existirem na BD
      case FuelType.gasoleoSimples:
        return 'Gasóleo simples';
      case FuelType.gasoleoEspecial:
        return 'Gasóleo especial';
      case FuelType.gpl:
        return 'GPL Auto';
    }
  }

  /// Label para mostrar na UI
  String get label {
    switch (this) {
      case FuelType.gasolina95:
        return 'Gasolina 95';
      case FuelType.gasolina98:
        return 'Gasolina 98';
      case FuelType.gasoleoSimples:
        return 'Gasóleo';
      case FuelType.gasoleoEspecial:
        return 'Gasóleo Plus';
      case FuelType.gpl:
        return 'GPL';
    }
  }

  static FuelType? fromDb(String? value) {
    switch (value) {
      case 'Gasolina simples 95':
        return FuelType.gasolina95;
      case 'Gasolina especial 98':
        return FuelType.gasolina98;
      case 'Gasóleo simples':
        return FuelType.gasoleoSimples;
      case 'Gasóleo especial':
        return FuelType.gasoleoEspecial;
      case 'GPL Auto':
        return FuelType.gpl;
      default:
        return null;
    }
  }
}
