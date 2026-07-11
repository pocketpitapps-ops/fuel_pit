// lib/app_services/discounts/discount_calculator.dart

/// Funções utilitárias para cálculos de descontos em abastecimentos.
class DiscountCalculator {
  /// Preço final por litro após aplicar um cupão de cênt./L.
  static double applyPerLiterDiscount({
    required double pricePerLiter,
    required double centsPerLiter,
  }) {
    final discount = centsPerLiter / 100;
    final finalPrice = pricePerLiter - discount;
    return finalPrice.clamp(0, double.infinity);
  }

  /// Preço final por litro após aplicar um cupão em percentagem.
  static double applyPercentDiscount({
    required double pricePerLiter,
    required double percent,
  }) {
    final factor = 1 - (percent / 100);
    final finalPrice = pricePerLiter * factor;
    return finalPrice.clamp(0, double.infinity);
  }

  /// Total a pagar para um valor fixo de desconto (€ direto na fatura).
  static double applyFixedDiscount({
    required double baseTotal,
    required double fixedAmount,
  }) {
    final total = baseTotal - fixedAmount;
    return total.clamp(0, double.infinity);
  }

  /// Calcula o total (€) para N litros com um preço por litro (já com desconto aplicado).
  static double totalForLiters({
    required double liters,
    required double pricePerLiter,
  }) {
    return liters * pricePerLiter;
  }

  /// Calcula quantos litros consegues com um determinado valor (€).
  static double litersForValue({
    required double value,
    required double pricePerLiter,
  }) {
    if (pricePerLiter <= 0) return 0;
    return value / pricePerLiter;
  }
}
