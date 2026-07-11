import 'package:flutter/material.dart';
import '../../../vehicles/domain/vehicle.dart';
import '../../../../shared/models/fuel_type.dart';
import '../../../../core/config/vehicle_type_config.dart';
import '../../../../shared/widgets/app_card.dart';

class VehiclesStripCard extends StatelessWidget {
  final List<Vehicle> vehicles;
  final Vehicle? defaultVehicle;
  final VoidCallback onTap;

  const VehiclesStripCard({
    super.key,
    required this.vehicles,
    required this.defaultVehicle,
    required this.onTap,
  });

  String _displayTitle(Vehicle v) {
    final nickname = v.nickname?.trim() ?? '';
    if (nickname.isNotEmpty) return nickname;

    final brand = v.brand?.trim() ?? '';
    final model = v.model?.trim() ?? '';
    final combined = [brand, model].where((s) => s.isNotEmpty).join(' ').trim();
    return combined.isNotEmpty ? combined : 'Veículo';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (vehicles.isEmpty) {
      return AppCard(
        child: ListTile(
          leading: Icon(Icons.directions_car, color: colorScheme.primary),
          title: const Text('Nenhum veículo definido'),
          subtitle: const Text('Adiciona veículos na página de Veículos.'),
          trailing: Icon(Icons.chevron_right, color: colorScheme.outline),
          onTap: onTap,
        ),
      );
    }

    final defaultId = defaultVehicle?.id;

    return AppCard(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: vehicles.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final v = vehicles[index];
                    final isDefault = v.id == defaultId;
                    final iconData = iconForVehicleType(v.typeId);
                    final title = _displayTitle(v);
                    final subtitle = v.fuelType?.label ?? '';

                    return Container(
                      width: 150,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDefault
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                iconData,
                                size: 20,
                                color: isDefault
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurfaceVariant,
                              ),
                              if (isDefault) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.star,
                                  size: 16,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium,
                          ),
                          if (subtitle.isNotEmpty)
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: isDefault
                                    ? colorScheme.onPrimaryContainer.withValues(
                                        alpha: 0.8,
                                      )
                                    : colorScheme.outline,
                              ),
                            ),
                          if (isDefault) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Principal',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Ver todos',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
