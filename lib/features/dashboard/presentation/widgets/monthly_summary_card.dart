// lib\features\dashboard\presentation\widgets\monthly_summary_card.dart
import 'package:flutter/material.dart';
import '../../../fillups/data/fillups_repository.dart';

class MonthlySummaryCard extends StatelessWidget {
  const MonthlySummaryCard({super.key, required this.summary});

  final FillUpsSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '${summary.totalPaid.toStringAsFixed(2)} € em '
          '${summary.totalLiters.toStringAsFixed(1)} L '
          '(${summary.count} abastec.)',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 2),
        Text(
          'Média: ${summary.averagePricePerLiter.toStringAsFixed(3)} €/L',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
        ),
        const SizedBox(height: 2),
        Text(
          'Média gasta por abastecimento: '
          '${(summary.count > 0 ? summary.totalPaid / summary.count : 0).toStringAsFixed(2)} €',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
        ),
      ],
    );
  }
}
