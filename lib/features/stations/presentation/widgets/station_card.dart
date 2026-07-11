// lib/features/stations/presentation/widgets/station_card.dart
import 'package:flutter/material.dart';

import '../../../navigation/maps_navigation.dart';
import '../../domain/station.dart';
import '../../../coupons/domain/coupon.dart';
import '../../../../shared/models/fuel_type.dart';
import '../../../coupons/domain/discount_engine.dart';
import '../../domain/station_brand.dart';
import '../../../coupons/domain/coupon_station_compat.dart';

class StationCard extends StatefulWidget {
  const StationCard({
    super.key,
    required this.station,
    required this.defaultFillMode, // 'per_value' ou 'per_liters'
    required this.defaultFillValue, // € ou L, conforme modo
    required this.availableCoupons,
    this.onTapFillUp,
    this.onCouponSelected,
    this.isGuest = false,
  });

  final Station station;
  final String defaultFillMode;
  final double defaultFillValue;
  final List<Coupon> availableCoupons;
  final VoidCallback? onTapFillUp;
  final ValueChanged<Coupon?>? onCouponSelected;
  final bool isGuest;

  @override
  State<StationCard> createState() => _StationCardState();
}

class BrandStyle {
  final Color background;
  final String label;

  const BrandStyle(this.background, this.label);
}

BrandStyle getBrandStyle(StationBrand brand, ColorScheme scheme) {
  switch (brand) {
    case StationBrand.galp:
      return const BrandStyle(Color(0xFFFFA633), 'GALP');

    case StationBrand.bp:
      return const BrandStyle(Color(0xFF2FA15F), 'BP');

    case StationBrand.repsol:
      return const BrandStyle(Color(0xFF2563EB), 'REPS');

    case StationBrand.prio:
      return const BrandStyle(Color(0xFF7C3AED), 'PRIO');

    case StationBrand.cepsa:
      return const BrandStyle(Color(0xFFEF4444), 'CEPSA');

    case StationBrand.shell:
      return const BrandStyle(Color(0xFFF59E0B), 'SHELL');

    case StationBrand.oz:
      return const BrandStyle(Color(0xFF0F766E), 'OZ');

    case StationBrand.alvesBandeira:
      return const BrandStyle(Color(0xFF1E3A8A), 'AB');

    case StationBrand.auchan:
      return const BrandStyle(Color(0xFFBE185D), 'AUCH');

    case StationBrand.intermarche:
      return const BrandStyle(Color(0xFFEA580C), 'INTER');

    case StationBrand.pingoDoce:
      return const BrandStyle(Color(0xFF16A34A), 'PINGO');

    case StationBrand.leclerc:
      return const BrandStyle(Color(0xFF3B82F6), 'LECL');

    case StationBrand.recheio:
      return const BrandStyle(Color(0xFF22C55E), 'RECH');

    case StationBrand.petroprix:
      return const BrandStyle(Color(0xFFFB923C), 'PPRIX');

    case StationBrand.q8:
      return const BrandStyle(Color(0xFF6366F1), 'Q8');

    case StationBrand.generic:
      return BrandStyle(scheme.primary, 'GEN');

    case StationBrand.other:
      return BrandStyle(scheme.primaryContainer, 'POSTO');
  }
}

class _StationCardState extends State<StationCard> {
  Coupon? _selectedCoupon;

  Future<void> _openMapsForStation() async {
    final s = widget.station;

    final success = await MapsNavigationService.openStationOnMaps(
      stationName: s.name,
      brand: s.brand, // se tiveres algo deste género
      address: s.address,
      locality: s.locality,
      municipality: s.municipality,
      district: s.district,
      latitude: s.latitude,
      longitude: s.longitude,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o GPS para este posto.'),
        ),
      );
    }
  }

  Widget _buildBrandAvatar(ColorScheme colorScheme) {
    final brand = widget.station.normalizedBrand;
    final style = getBrandStyle(brand, colorScheme);

    return CircleAvatar(
      backgroundColor: style.background,
      child: Text(
        style.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.clip,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final trend = getPriceTrend(
      widget.station.currentPricePerLiter,
      widget.station.lastPricePerLiter,
    );

    IconData trendIcon;
    Color trendColor;

    switch (trend) {
      case PriceTrend.down:
        trendIcon = Icons.arrow_downward;
        trendColor = colorScheme.tertiary; // ou secondary
        break;
      case PriceTrend.up:
        trendIcon = Icons.arrow_upward;
        trendColor = colorScheme.error;
        break;
      case PriceTrend.same:
        trendIcon = Icons.remove;
        trendColor = colorScheme.outline;
        break;
    }

    // combustível como enum → label bonito
    final fuelLabel =
        widget.station.fuelTypeEnum?.label ?? widget.station.fuelTypeRaw;

    // Cálculo base em função do modo
    final pricePerLiter = widget.station.currentPricePerLiter;
    final mode = widget.defaultFillMode;
    final value = widget.defaultFillValue;

    double baseTotal; // €
    double liters; // L

    if (mode == 'per_liters') {
      liters = value;
      baseTotal = liters * pricePerLiter;
    } else {
      baseTotal = value;
      liters = baseTotal / pricePerLiter;
    }

    // Label do valor usado na simulação (L ou €)
    final fillLabel = mode == 'per_liters'
        ? '${value.toStringAsFixed(1)} L'
        : '${value.toStringAsFixed(0)} €';

    final couponsToApply = _selectedCoupon != null
        ? <Coupon>[_selectedCoupon!]
        : <Coupon>[];

    final discountResult = calculateDiscounts(
      liters: liters,
      pricePerLiter: pricePerLiter,
      coupons: couponsToApply,
    );

    final savings = discountResult.savings;

    // Cupões compatíveis com ESTE posto
    final compatibleCoupons = widget.availableCoupons.where((c) {
      return isCouponCompatibleWithStation(c, widget.station);
    }).toList();

    // Se o cupão selecionado deixar de ser compatível, limpa
    if (_selectedCoupon != null &&
        !compatibleCoupons.contains(_selectedCoupon)) {
      _selectedCoupon = null;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Linha principal: avatar + nome + preço + favorito
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBrandAvatar(colorScheme),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.station.name, style: textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$fuelLabel · ${pricePerLiter.toStringAsFixed(3)} €/L',
                            style: textTheme.bodyMedium,
                          ),
                          const SizedBox(width: 4),
                          Icon(trendIcon, color: trendColor, size: 16),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.station.distanceKm != null
                            ? 'Distância: ${widget.station.distanceKm!.toStringAsFixed(1)} km'
                            : 'Distância desconhecida',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    // Favorito só para utilizador autenticado
                    if (!widget.isGuest)
                      Icon(
                        widget.station.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: widget.station.isFavorite
                            ? colorScheme.primary
                            : colorScheme.outline,
                        size: 20,
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Simulador inline + cupão (apenas autenticado)
            if (!widget.isGuest)
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Simulação rápida',
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode == 'per_liters'
                          ? 'Abastecer $fillLabel aqui custa ~${baseTotal.toStringAsFixed(2)} €'
                          : 'Abastecer $fillLabel aqui dá ~${liters.toStringAsFixed(1)} L',
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),

                    // Dropdown de cupões — apenas compatíveis com este posto
                    if (compatibleCoupons.isNotEmpty) ...[
                      Text('Cupão disponível:', style: textTheme.bodySmall),
                      const SizedBox(height: 4),
                      DropdownButton<Coupon>(
                        isExpanded: true,
                        hint: const Text('Seleciona um cupão'),
                        value: _selectedCoupon,
                        items: [
                          ...compatibleCoupons.map(
                            (c) => DropdownMenuItem<Coupon>(
                              value: c,
                              child: Text(c.displayName),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCoupon = value;
                          });
                          widget.onCouponSelected?.call(value);
                        },
                      ),
                      if (_selectedCoupon != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedCoupon = null;
                            });
                            widget.onCouponSelected?.call(null);
                          },
                          child: const Text('Remover cupão'),
                        ),
                    ],

                    const SizedBox(height: 8),

                    // Resultado APENAS quando há cupão selecionado
                    if (_selectedCoupon != null) ...[
                      // Se for desconto direto, o total a pagar muda e faz sentido mostrar.
                      if (_selectedCoupon!.benefitKind ==
                          CouponBenefitKind.directDiscount) ...[
                        Text(
                          'Total com cupão: ${discountResult.finalTotal.toStringAsFixed(2)} €',
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Poupas ${savings.toStringAsFixed(2)} € neste abastecimento.',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.tertiary,
                          ),
                        ),
                      ],

                      // Se for saldo em cartão, o valor pago é o mesmo
                      // e só mostramos o saldo acumulado.
                      if (_selectedCoupon!.benefitKind ==
                          CouponBenefitKind.cardBalance) ...[
                        Text(
                          'Acumulas ${savings.toStringAsFixed(2)} € no cartão.',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.tertiary,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Linha de ações em baixo: Navegar (todos) + Abastecer (só autenticado)
            Row(
              children: [
                // Guest e autenticado podem navegar
                OutlinedButton.icon(
                  onPressed: _openMapsForStation,
                  icon: const Icon(Icons.navigation),
                  label: const Text('Navegar'),
                ),
                const Spacer(),
                if (!widget.isGuest)
                  FilledButton.icon(
                    onPressed: widget.onTapFillUp,
                    icon: const Icon(Icons.local_gas_station),
                    label: const Text('Abastecer'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
