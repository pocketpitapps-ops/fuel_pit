// lib/pages/vehicles_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/vehicle.dart';
import '../../../shared/models/fuel_type.dart';
import '../data/vehicles_repository.dart';
import '../../../core/config/vehicle_type_config.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/login_required_screen.dart';
import '../../auth/auth_notifier.dart';
import '../../auth/auth_state.dart';
import 'new_vehicle_page.dart';

class VehiclesPage extends StatefulWidget {
  const VehiclesPage({super.key});

  @override
  State<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends State<VehiclesPage> {
  late Future<List<Vehicle>> _futureVehicles;
  final _vehiclesRepository = VehiclesRepository();

  @override
  void initState() {
    super.initState();
    _futureVehicles = _vehiclesRepository.getVehicles();
  }

  Future<void> _refresh() async {
    setState(() {
      _futureVehicles = _vehiclesRepository.getVehicles();
    });
  }

  /// Abre a página para criar/editar veículo.
  Future<void> _openNewVehiclePage({Vehicle? initialVehicle}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NewVehiclePage(initialVehicle: initialVehicle),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _refresh();
    }
  }

  /// Marca um veículo como principal via repositório.
  Future<void> _setDefaultVehicle(String vehicleId) async {
    try {
      await _vehiclesRepository.setDefaultVehicle(vehicleId);

      if (!mounted) return;
      await _refresh();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veículo principal atualizado.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao definir principal: $e')));
    }
  }

  Future<void> _onDeleteVehicle(Vehicle vehicle) async {
    try {
      await _vehiclesRepository.deleteVehicle(vehicle.id);
      if (!mounted) return;

      await _refresh();
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Veículo removido.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao remover veículo: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthNotifier>().state;
    final isGuest = authState.status == AuthStatus.guest;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    if (isGuest) {
      return LoginRequiredScreen.standard(
        context: context,
        message:
            'Os veículos são guardados na tua conta para personalizar estatísticas e abastecimentos.',
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Veículos'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<Vehicle>>(
          future: _futureVehicles,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
              );
            }

            // Copiamos para lista mutável para poder ordenar.
            final vehicles = (snapshot.data ?? []).toList();

            if (vehicles.isEmpty) {
              return Center(
                child: Text(
                  'Ainda não adicionaste nenhum veículo.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }

            // Regra 1: se só houver um veículo, consideramos principal (UI).
            if (vehicles.length == 1 && !vehicles.first.isDefault) {
              vehicles[0] = vehicles[0].copyWith(isDefault: true);
            }

            // Regra 2: se nenhum tiver isDefault, o primeiro passa a principal (UI).
            if (vehicles.isNotEmpty && !vehicles.any((v) => v.isDefault)) {
              vehicles[0] = vehicles[0].copyWith(isDefault: true);
            }

            // Regra 3: ordenar para que o principal fique no topo.
            vehicles.sort((a, b) {
              if (a.isDefault == b.isDefault) return 0;
              return a.isDefault ? -1 : 1;
            });

            final hasDefault = vehicles.any((v) => v.isDefault);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!hasDefault) ...[
                  const _NoDefaultVehicleHintCard(),
                  const SizedBox(height: 16),
                ],
                Expanded(
                  child: ListView.separated(
                    itemCount: vehicles.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final vehicle = vehicles[index];

                      return _VehicleListTile(
                        vehicle: vehicle,
                        onEdit: () =>
                            _openNewVehiclePage(initialVehicle: vehicle),
                        onDeleted: () => _onDeleteVehicle(vehicle),
                        onSetDefault: () => _setDefaultVehicle(vehicle.id),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openNewVehiclePage(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Card de aviso quando não há veículo principal definido.
class _NoDefaultVehicleHintCard extends StatelessWidget {
  const _NoDefaultVehicleHintCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: colorScheme.onTertiaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Seleciona um veículo como principal para usarmos nas estatísticas.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onTertiaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tile de um veículo na lista.
class _VehicleListTile extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDeleted;
  final VoidCallback onSetDefault;

  const _VehicleListTile({
    required this.vehicle,
    required this.onEdit,
    required this.onDeleted,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final nickname = (vehicle.nickname?.trim().isNotEmpty ?? false)
        ? vehicle.nickname!.trim()
        : ([vehicle.brand, vehicle.model]
              .where((s) => s != null && s.trim().isNotEmpty)
              .map((s) => s!.trim())
              .join(' '));

    final displayName = nickname.isEmpty ? 'Veículo sem nome' : nickname;
    final brand = vehicle.brand ?? '';
    final model = vehicle.model ?? '';
    final plate = vehicle.plate ?? '';
    final fuelTypeLabel = vehicle.fuelType?.label ?? 'Combustível';
    final tankCapacity = vehicle.tankCapacityL ?? 0;
    final isDefault = vehicle.isDefault;

    final subtitleParts = <String>[];
    if (brand.isNotEmpty || model.isNotEmpty) {
      subtitleParts.add([brand, model].where((s) => s.isNotEmpty).join(' '));
    }
    if (plate.isNotEmpty) {
      subtitleParts.add(plate.toUpperCase());
    }
    final subtitle = subtitleParts.join(' • ');
    final iconData = iconForVehicleType(vehicle.typeId);

    return AppCard(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: iconData == null
              ? null
              : Icon(iconData, color: colorScheme.onPrimaryContainer),
        ),
        title: Row(
          children: [
            Expanded(child: Text(displayName, style: textTheme.titleMedium)),
            IconButton(
              tooltip: 'Definir como principal',
              icon: Icon(
                isDefault ? Icons.star : Icons.star_border,
                color: isDefault ? colorScheme.primary : colorScheme.outline,
              ),
              onPressed: isDefault ? null : onSetDefault,
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: textTheme.bodyMedium),
            ],
            const SizedBox(height: 4),
            Text(
              '$fuelTypeLabel • Depósito ${tankCapacity.toStringAsFixed(1)} L',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.delete_outline, color: colorScheme.error),
              onPressed: () async {
                final shouldDelete = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      title: const Text('Remover veículo'),
                      content: Text(
                        'Tens a certeza que queres remover o veículo "$nickname"?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: const Text('Remover'),
                        ),
                      ],
                    );
                  },
                );

                if (shouldDelete != true) return;
                onDeleted();
              },
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: colorScheme.outline),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }
}
