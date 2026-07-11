// lib/features/stations/presentation/widgets/stations_list.dart
import 'package:flutter/material.dart';

import '../../domain/station.dart';
import '../../../coupons/domain/coupon.dart';
import '../../../profile/domain/user_profile.dart';
import '../../../fillups/presentation/new_fillup_page.dart';
import 'station_card.dart';

class StationsList extends StatelessWidget {
  const StationsList({
    super.key,
    required this.stations,
    required this.sortAscending,
    required this.onToggleSort,
    required this.coupons,
    required this.profile,
    this.isGuest = false,
  });

  final List<Station> stations;
  final bool sortAscending;
  final VoidCallback onToggleSort;
  final List<Coupon> coupons;
  final UserProfile? profile;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    final defaultFillMode = profile?.defaultFillMode ?? 'per_value';
    final defaultFillValue = profile?.defaultFillValue ?? 40.0;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final sortLabel = sortAscending ? 'Mais perto' : 'Mais longe';

    return Column(
      children: [
        // Filtro de ordenação compacto com texto
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                sortLabel,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              IconButton(
                onPressed: onToggleSort,
                tooltip: sortAscending
                    ? 'Ordenar por mais longe'
                    : 'Ordenar por mais perto',
                icon: Icon(
                  sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.separated(
            itemCount: stations.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final station = stations[index];
              Coupon? selectedCouponForStation;

              return StationCard(
                station: station,
                defaultFillMode: defaultFillMode,
                defaultFillValue: defaultFillValue,
                availableCoupons: isGuest ? const [] : coupons,
                isGuest: isGuest,
                onCouponSelected: isGuest
                    ? null
                    : (coupon) {
                        selectedCouponForStation = coupon;
                      },
                onTapFillUp: isGuest
                    ? null
                    : () async {
                        final navigator = Navigator.of(context);
                        final textTheme = Theme.of(context).textTheme;
                        final saved = await navigator.push<bool>(
                          MaterialPageRoute(
                            builder: (_) => NewFillUpPage(
                              initialStationName: station.name,
                              initialFuelType: station.fuelTypeRaw,
                              initialCoupon: selectedCouponForStation,
                              station: station,
                            ),
                          ),
                        );

                        if (!context.mounted) return;

                        if (saved == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Abastecimento registado.',
                                style: textTheme.bodyMedium,
                              ),
                            ),
                          );
                        }
                      },
              );
            },
          ),
        ),
      ],
    );
  }
}
