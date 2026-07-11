// lib\features\vehicles\presentation\new_vehicle_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../domain/vehicle.dart';
import '../data/vehicles_repository.dart';
import 'widgets/vehicle_form.dart';
import '../../auth/auth_notifier.dart';
import '../../auth/auth_state.dart';
import '../../../shared/widgets/login_required_screen.dart';
import '../../../core/supabase_client.dart';

class NewVehiclePage extends StatefulWidget {
  final Vehicle? initialVehicle;

  const NewVehiclePage({super.key, this.initialVehicle});

  @override
  State<NewVehiclePage> createState() => _NewVehiclePageState();
}

class _NewVehiclePageState extends State<NewVehiclePage> {
  final _vehiclesRepository = VehiclesRepository();

  Map<String, Map<String, List<String>>> _data = {};
  Map<String, List<String>> _brandsByType = {};
  Map<String, List<String>> _modelsByBrand = {};
  bool _loadingData = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadBrandsModels();
  }

  Future<void> _loadBrandsModels() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/vehicles/brands_models.json',
      );
      final decoded = jsonDecode(raw) as Map<String, dynamic>;

      final Map<String, Map<String, List<String>>> data = {};
      final Map<String, List<String>> brandsByType = {};
      final Map<String, List<String>> modelsByBrand = {};

      decoded.forEach((typeKey, brandsValue) {
        final brandsMap = (brandsValue as Map<String, dynamic>);
        final Map<String, List<String>> brandModels = {};

        brandsMap.forEach((brandKey, modelsValue) {
          final modelsList = (modelsValue as List)
              .map((e) => e.toString())
              .toList();
          brandModels[brandKey] = modelsList;

          final existing = modelsByBrand[brandKey] ?? <String>[];
          final mergedSet = <String>{...existing, ...modelsList};
          final merged = mergedSet.toList()..sort();
          modelsByBrand[brandKey] = merged;
        });

        data[typeKey] = brandModels;
        final brands = brandModels.keys.toList()..sort();
        brandsByType[typeKey] = brands;
      });

      setState(() {
        _data = data;
        _brandsByType = brandsByType;
        _modelsByBrand = modelsByBrand;
        _loadingData = false;
        _loadError = null;
      });
    } catch (e) {
      setState(() {
        _loadingData = false;
        _loadError = 'Erro ao carregar lista de marcas/modelos';
      });
    }
  }

  Future<void> _saveVehicle(Vehicle vehicle, bool isEditing) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Sem utilizador autenticado.');
    }

    if (isEditing) {
      await _vehiclesRepository.updateVehicle(vehicle);
    } else {
      await _vehiclesRepository.addVehicle(vehicle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialVehicle != null;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final authState = context.watch<AuthNotifier>().state;
    final isGuest = authState.status == AuthStatus.guest;

    if (isGuest) {
      return LoginRequiredScreen.standard(
        context: context,
        message:
            'Para adicionar e editar veículos, cria uma conta ou inicia sessão.',
      );
    }

    if (_loadingData) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Editar veículo' : 'Novo veículo'),
          centerTitle: true,
        ),
        body: Center(
          child: Text(
            _loadError!,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar veículo' : 'Novo veículo'),
        centerTitle: true,
      ),
      body: VehicleForm(
        initialVehicle: widget.initialVehicle,
        data: _data,
        brandsByType: _brandsByType,
        modelsByBrand: _modelsByBrand,
        onSave: (vehicle) async {
          try {
            await _saveVehicle(vehicle, isEditing);

            if (!context.mounted) return;

            Navigator.of(context).pop(true);
          } catch (e) {
            if (!context.mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao guardar veículo: $e')),
            );
          }
        },
      ),
    );
  }
}
