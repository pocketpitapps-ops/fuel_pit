// lib/features/stations/presentation/widgets/stations_header.dart
import 'package:flutter/material.dart';

import '../../../profile/domain/user_profile.dart';
import '../../../vehicles/domain/vehicle.dart';

class StationsHeader extends StatelessWidget {
  const StationsHeader({
    super.key,
    required this.fuelLabel,
    required this.profile,
    required this.couponsSnapshotError,
    required this.hasCoupons,
    required this.isGuest,
    this.locationLabel,
    this.onResetToNearby,
    this.defaultVehicle,
  });

  final String fuelLabel;
  final UserProfile? profile;
  final bool couponsSnapshotError;
  final bool hasCoupons;
  final bool isGuest;
  final String? locationLabel;
  final VoidCallback? onResetToNearby;
  final Vehicle? defaultVehicle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final titleText = locationLabel ?? 'Postos perto de ti';

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onResetToNearby,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      titleText,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.my_location,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  defaultVehicle != null
                      ? Icons.directions_car
                      : Icons.directions_car_outlined,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    fuelLabel, // ex: "Golf 7 • Gasolina 95" ou "Nenhum veículo definido • Gasolina 95"
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (couponsSnapshotError)
              Text(
                'Não foi possível carregar alguns cupões.',
                style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
              )
            else if (!hasCoupons && !isGuest)
              Text(
                'Sem cupões ativos. Podes adicionar na página de Cupões.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
