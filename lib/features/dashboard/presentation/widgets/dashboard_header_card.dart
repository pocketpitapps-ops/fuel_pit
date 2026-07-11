// lib/features/dashboard/presentation/widgets/dashboard_header_card.dart
import 'package:flutter/material.dart';

import '../../../../shared/models/fuel_type.dart';
import '../../../vehicles/domain/vehicle.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../core/config/vehicle_type_config.dart';

class DashboardHeaderCard extends StatelessWidget {
  final String userName;
  final Vehicle? vehicle;
  final String? vehicleName;

  const DashboardHeaderCard({
    super.key,
    required this.userName,
    required this.vehicle,
    required this.vehicleName,
  });

  String _buildDisplayName() {
    final trimmed = userName.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    return 'Motorista Fuel Pit';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final displayName = _buildDisplayName();
    final avatarLetter = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : '?';

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                avatarLetter,
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Olá, $displayName',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (vehicle != null && vehicleName != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(
                      iconForVehicleType(vehicle!.typeId) ??
                          Icons.directions_car,
                      size: 14,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    vehicleName!,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_gas_station, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    vehicle!.fuelType?.label ?? 'Combustível',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ] else
              Text(
                'Nenhum veículo principal definido',
                textAlign: TextAlign.center,
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
