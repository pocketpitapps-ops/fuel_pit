import 'package:flutter/material.dart';

import '../../domain/vehicle.dart';
import '../../../../shared/models/fuel_type.dart';
import 'vehicle_type_field.dart';
import 'vehicle_brand_field.dart';
import 'vehicle_model_field.dart';
import 'vehicle_plate_field.dart';
import 'vehicle_fuel_field.dart';
import 'vehicle_tank_field.dart';

class VehicleForm extends StatefulWidget {
  final Vehicle? initialVehicle;
  final Map<String, Map<String, List<String>>> data;
  final Map<String, List<String>> brandsByType;
  final Map<String, List<String>> modelsByBrand;
  final Future<void> Function(Vehicle) onSave;

  const VehicleForm({
    super.key,
    required this.initialVehicle,
    required this.data,
    required this.brandsByType,
    required this.modelsByBrand,
    required this.onSave,
  });

  @override
  State<VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends State<VehicleForm> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _plateController = TextEditingController();
  final _tankCapacityController = TextEditingController();

  String? _vehicleTypeId;
  String? _brand;
  String? _model;
  FuelType _selectedFuelType = FuelType.gasolina95;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final v = widget.initialVehicle;
    if (v != null) {
      _nicknameController.text = v.nickname ?? '';
      _plateController.text = v.plate ?? '';
      _selectedFuelType = v.fuelType ?? FuelType.gasolina95;
      _tankCapacityController.text = v.tankCapacityL?.toString() ?? '';
      _vehicleTypeId = v.typeId;
      _brand = v.brand;
      _model = v.model;
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _plateController.dispose();
    _tankCapacityController.dispose();
    super.dispose();
  }

  String? _validateNickname(String? value) {
    return null;
  }

  String? _validatePlate(String? value) {
    return VehiclePlateField.validatePlate(value);
  }

  String _normalizePlate(String raw) {
    return VehiclePlateField.normalizePlate(raw);
  }

  List<String> _computeAvailableBrands() {
    if (_vehicleTypeId != null) {
      return (widget.data[_vehicleTypeId] ?? {}).keys.toList()..sort();
    }

    final all = <String>{};
    widget.data.forEach((_, brandsMap) {
      all.addAll(brandsMap.keys);
    });
    final list = all.toList();
    list.sort();
    return list;
  }

  List<String> _computeAvailableModels() {
    if (_brand == null) return <String>[];

    if (_vehicleTypeId != null) {
      final list = widget.data[_vehicleTypeId]?[_brand] ?? <String>[];
      final sorted = list.toList()..sort();
      return sorted;
    }

    final list = widget.modelsByBrand[_brand] ?? <String>[];
    final sorted = list.toList()..sort();
    return sorted;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final tankCapacity =
        double.tryParse(_tankCapacityController.text.replaceAll(',', '.')) ?? 0;

    setState(() => _isSaving = true);

    try {
      final normalizedPlate = _plateController.text.trim().isEmpty
          ? null
          : _normalizePlate(_plateController.text);

      final isEditing = widget.initialVehicle != null;

      final vehicle = isEditing
          ? widget.initialVehicle!.copyWith(
              nickname: _nicknameController.text.trim(),
              brand: _brand,
              model: _model,
              plate: normalizedPlate,
              fuelType: _selectedFuelType,
              tankCapacityL: tankCapacity,
              typeId: _vehicleTypeId,
            )
          : Vehicle(
              id: '',
              nickname: _nicknameController.text.trim(),
              brand: _brand,
              model: _model,
              plate: normalizedPlate,
              fuelType: _selectedFuelType,
              tankCapacityL: tankCapacity,
              isDefault: false,
              typeId: _vehicleTypeId,
            );

      await widget.onSave(vehicle);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final brands = _computeAvailableBrands();
    final models = _computeAvailableModels();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Campos essenciais: tipo, marca, modelo e combustível.',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
            const SizedBox(height: 16),

            // Nome
            TextFormField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: 'Nome (opcional)',
                hintText: 'Ex.: Carro do dia-a-dia',
              ),
              validator: _validateNickname,
            ),
            const SizedBox(height: 12),

            VehicleTypeField(
              vehicleTypeId: _vehicleTypeId,
              brandsByType: widget.brandsByType,
              onChanged: (value) {
                setState(() {
                  _vehicleTypeId = value;
                  _brand = null;
                  _model = null;
                });
              },
            ),
            const SizedBox(height: 12),

            VehicleBrandField(
              brand: _brand,
              brands: brands,
              onChanged: (value) {
                setState(() {
                  _brand = value;
                  _model = null;
                });
              },
            ),
            const SizedBox(height: 12),

            VehicleModelField(
              brand: _brand,
              model: _model,
              models: models,
              data: widget.data,
              onChanged: (value, inferredType) {
                setState(() {
                  _model = value;
                  if (inferredType != null) {
                    _vehicleTypeId = inferredType;
                  }
                });
              },
            ),
            const SizedBox(height: 12),

            VehiclePlateField(
              controller: _plateController,
              validator: _validatePlate,
            ),
            const SizedBox(height: 12),

            VehicleFuelField(
              value: _selectedFuelType,
              onChanged: (value) {
                setState(() => _selectedFuelType = value);
              },
            ),
            const SizedBox(height: 12),

            VehicleTankField(controller: _tankCapacityController),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Guardar'),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _isSaving
                    ? null
                    : () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancelar',
                  style: TextStyle(color: colorScheme.outline),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
