// lib/features/dashboard/presentation/widgets/dashboard_highlights_card.dart
import 'package:flutter/material.dart';

import '../../../coupons/domain/coupon.dart';
import '../../../fillups/domain/fill_up.dart';
import '../../../fillups/data/fillups_repository.dart';
import '../../../dashboard/presentation/widgets/monthly_summary_card.dart';
import '../../../fillups/domain/fillup_stats.dart';

class DashboardHighlightsCard extends StatelessWidget {
  const DashboardHighlightsCard({
    super.key,
    required this.hasMultipleVehicles,
    required this.summaryAll,
    required this.summaryFavorite,
    required this.lastFillUpAll,
    required this.lastFillUpFavorite,
    required this.favoriteVehicleName,
    required this.nextCoupon,
    required this.activeCouponsCount,
    required this.onAddCoupon,
    this.globalStats,
    this.favoriteStats,
  });

  final bool hasMultipleVehicles;
  final FillUpsSummary summaryAll;
  final FillUpsSummary summaryFavorite;
  final FillUp? lastFillUpAll;
  final FillUp? lastFillUpFavorite;
  final String? favoriteVehicleName;
  final Coupon? nextCoupon;
  final int activeCouponsCount;
  final VoidCallback onAddCoupon;
  final FillUpStats? globalStats;
  final FillUpStats? favoriteStats;

  // ---------- Helpers de comparação ----------

  bool _summariesAreEqual() {
    return summaryAll.totalLiters == summaryFavorite.totalLiters &&
        summaryAll.totalPaid == summaryFavorite.totalPaid &&
        summaryAll.averagePricePerLiter ==
            summaryFavorite.averagePricePerLiter &&
        summaryAll.count == summaryFavorite.count;
  }

  bool _statsAreEqual(FillUpStats? global, FillUpStats? favorite) {
    if (global == null || favorite == null) return false;
    return global.totalSavings == favorite.totalSavings &&
        global.totalDirectDiscount == favorite.totalDirectDiscount &&
        global.totalCardBalance == favorite.totalCardBalance;
  }

  bool _lastFillUpsAreEqual(FillUp? all, FillUp? favorite) {
    if (all == null || favorite == null) return false;
    return all.stationName == favorite.stationName &&
        all.liters == favorite.liters &&
        all.pricePerLiter == favorite.pricePerLiter &&
        all.totalPaid == favorite.totalPaid &&
        all.filledAt == favorite.filledAt;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final showGlobalSummaryCard = hasMultipleVehicles && !_summariesAreEqual();

    final showGlobalSavings =
        hasMultipleVehicles &&
        globalStats != null &&
        !_statsAreEqual(globalStats, favoriteStats);

    final showGlobalLastFillUp =
        hasMultipleVehicles &&
        lastFillUpAll != null &&
        !_lastFillUpsAreEqual(lastFillUpAll, lastFillUpFavorite);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            'Destaques',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),

        // -------- Resumo do mês --------
        if (showGlobalSummaryCard) ...[
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumo do mês – todos os veículos',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  MonthlySummaryCard(summary: summaryAll),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasMultipleVehicles
                      ? 'Resumo do mês – ${favoriteVehicleName ?? 'veículo favorito'}'
                      : 'Resumo do mês',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                MonthlySummaryCard(summary: summaryFavorite),
              ],
            ),
          ),
        ),

        // -------- Poupança com cupões --------
        if ((globalStats != null && showGlobalSavings) ||
            favoriteStats != null) ...[
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Poupança total com cupões',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (showGlobalSavings && globalStats != null) ...[
                    Text(
                      '${globalStats!.totalSavings.toStringAsFixed(2)} € no total (todos os veículos)',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.tertiary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Desconto direto: '
                      '${globalStats!.totalDirectDiscount.toStringAsFixed(2)} €',
                      style: textTheme.bodySmall,
                    ),
                    Text(
                      'Saldo acumulado em cartão: '
                      '${globalStats!.totalCardBalance.toStringAsFixed(2)} €',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (favoriteStats != null) ...[
                    Text(
                      '${favoriteStats!.totalSavings.toStringAsFixed(2)} € no ${favoriteVehicleName ?? 'veículo favorito'}',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.tertiary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Desconto direto: '
                      '${favoriteStats!.totalDirectDiscount.toStringAsFixed(2)} €',
                      style: textTheme.bodySmall,
                    ),
                    Text(
                      'Saldo acumulado em cartão: '
                      '${favoriteStats!.totalCardBalance.toStringAsFixed(2)} €',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.secondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 12),

        // -------- Último abastecimento --------
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildLastFillUpSection(
              context,
              textTheme,
              colorScheme,
              hasMultipleVehicles,
              showGlobalLastFillUp ? lastFillUpAll : null,
              lastFillUpFavorite,
              favoriteVehicleName,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // -------- Cupões --------
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Próximo cupão a expirar (esquerda, mais largo)
                Expanded(
                  flex: 2,
                  child: _buildNextCouponSection(
                    context,
                    textTheme,
                    colorScheme,
                    nextCoupon,
                  ),
                ),
                const SizedBox(width: 12),
                // Cupões ativos (direita)
                Expanded(
                  flex: 1,
                  child: _buildActiveCouponsSection(
                    context,
                    textTheme,
                    colorScheme,
                    activeCouponsCount,
                    onAddCoupon,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------- Secções auxiliares ----------

  Widget _buildLastFillUpSection(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
    bool hasMultipleVehicles,
    FillUp? lastFillUpAll,
    FillUp? lastFillUpFavorite,
    String? favoriteVehicleName,
  ) {
    if (lastFillUpFavorite == null && lastFillUpAll == null) {
      return Text(
        'Ainda não registaste abastecimentos.',
        textAlign: TextAlign.center,
        style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
      );
    }

    final children = <Widget>[];

    if (hasMultipleVehicles && lastFillUpAll != null) {
      children.addAll([
        Text(
          'Último abastecimento (todos os veículos)',
          textAlign: TextAlign.center,
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        _buildSingleFillUpLine(textTheme, colorScheme, lastFillUpAll),
        const SizedBox(height: 8),
      ]);
    }

    if (lastFillUpFavorite != null) {
      children.addAll([
        Text(
          hasMultipleVehicles
              ? 'Último abastecimento – ${favoriteVehicleName ?? 'veículo favorito'}'
              : 'Último abastecimento',
          textAlign: TextAlign.center,
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        _buildSingleFillUpLine(textTheme, colorScheme, lastFillUpFavorite),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children,
    );
  }

  Widget _buildSingleFillUpLine(
    TextTheme textTheme,
    ColorScheme colorScheme,
    FillUp fill,
  ) {
    final stationName = fill.stationName ?? 'Posto desconhecido';
    final total = fill.liters * fill.pricePerLiter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                stationName,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${total.toStringAsFixed(2)} €',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${fill.filledAt.day.toString().padLeft(2, '0')}/'
          '${fill.filledAt.month.toString().padLeft(2, '0')} '
          '• ${fill.liters.toStringAsFixed(1)} L a '
          '${fill.pricePerLiter.toStringAsFixed(3)} €/L',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
        ),
      ],
    );
  }

  Widget _buildNextCouponSection(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
    Coupon? coupon,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Próximo cupão a expirar',
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        if (coupon != null) ...[
          Text(
            coupon.customName ?? coupon.effectiveCode,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          if (coupon.validUntil != null) ...[
            const SizedBox(height: 2),
            Text(
              'Válido até '
              '${coupon.validUntil!.day.toString().padLeft(2, '0')}/'
              '${coupon.validUntil!.month.toString().padLeft(2, '0')}',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ] else
          Text(
            'Sem cupões prestes a expirar.',
            style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  Widget _buildActiveCouponsSection(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
    int activeCouponsCount,
    VoidCallback onAddCoupon,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Cupões ativos',
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          '$activeCouponsCount',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        if (activeCouponsCount == 0)
          TextButton(
            onPressed: onAddCoupon,
            child: const Text('Adicionar cupão'),
          ),
      ],
    );
  }
}
