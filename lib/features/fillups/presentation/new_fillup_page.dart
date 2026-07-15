// lib/features/fillups/presentation/new_fillup_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/supabase_client.dart';
import '../../../shared/models/fuel_type.dart';
import '../../../shared/widgets/fuel_type_dropdown.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/login_required_screen.dart';
import '../../auth/auth_notifier.dart';
import '../../auth/auth_state.dart';
import '../../coupons/data/coupons_repository.dart';
import '../../coupons/domain/coupon.dart';
import '../../coupons/domain/coupon_ui_extensions.dart';
import '../../stations/domain/station.dart';
import '../../vehicles/data/vehicles_repository.dart';
import '../../vehicles/domain/vehicle.dart';
import '../data/fillups_repository.dart';
import '../domain/fill_up.dart';

class NewFillUpPage extends StatefulWidget {
  const NewFillUpPage({
    super.key,
    this.initialStationName,
    this.initialFuelType,
    this.initialCoupon,
    this.station,
    this.existingFillUp,
  });

  final String? initialStationName;

  /// Continua string porque vem, por exemplo, de uma card de estação.
  final String? initialFuelType;
  final Coupon? initialCoupon;
  final Station? station;
  final FillUp? existingFillUp;

  @override
  State<NewFillUpPage> createState() => _NewFillUpPageState();
}

class _NewFillUpPageState extends State<NewFillUpPage> {
  final _formKey = GlobalKey<FormState>();

  final _stationNameController = TextEditingController();
  final _totalController = TextEditingController();
  final _pricePerLiterController = TextEditingController();
  final _litersController = TextEditingController();

  final _couponsRepository = CouponsRepository();
  final _fillUpsRepository = FillUpsRepository();
  final _vehiclesRepository = VehiclesRepository();

  Coupon? _selectedCoupon;
  late Future<List<Coupon>> _futureCoupons;

  /// Agora o estado guarda sempre FuelType.
  FuelType _fuelType = FuelType.gasolina95;

  DateTime _filledAt = DateTime.now();
  bool _isSaving = false;

  List<Vehicle> _vehicles = [];
  Vehicle? _selectedVehicle;
  bool _loadingVehicles = true;

  FuelType get _defaultFuel => FuelType.gasolina95;

  bool get isEditing => widget.existingFillUp != null;

  /// Brand do posto (se conhecida) para filtrar cupões.
  String? _stationBrandKey;

  @override
  void initState() {
    super.initState();

    if (isEditing) {
      final f = widget.existingFillUp!;
      _stationNameController.text = f.stationName ?? '';
      _fuelType = f.fuelType;
      _filledAt = f.filledAt;
      _totalController.text = f.totalPaid.toStringAsFixed(2);
      _pricePerLiterController.text = f.pricePerLiter.toStringAsFixed(3);
      _litersController.text = f.liters.toStringAsFixed(2);

      // se vier um cupão inicial (do histórico), usa-o
      if (widget.initialCoupon != null) {
        _selectedCoupon = widget.initialCoupon;
      }

      // Se o FillUp ainda não guarda brand, tenta inferir pelo nome do posto
      if (f.stationName != null && f.stationName!.trim().isNotEmpty) {
        _stationBrandKey = _inferBrandFromStationName(f.stationName!);
      }
    } else {
      _stationNameController.text = widget.initialStationName ?? '';
      _fuelType = _mapInitialFuelType(widget.initialFuelType) ?? _defaultFuel;
      _filledAt = DateTime.now();

      _selectedCoupon = widget.initialCoupon;

      // se vier um Station, usa a brand dele (string vinda da BD)
      if (widget.station != null) {
        _stationBrandKey = _normalizeBrand(widget.station!.brand);
      }
    }

    _futureCoupons = _loadCoupons();
    _loadVehicles();
  }

  @override
  void dispose() {
    _stationNameController.dispose();
    _totalController.dispose();
    _pricePerLiterController.dispose();
    _litersController.dispose();
    super.dispose();
  }

  /// Converte uma string (ex. vinda de StationCard) em FuelType.
  FuelType? _mapInitialFuelType(String? raw) {
    if (raw == null) return null;

    final fromDb = FuelTypeExt.fromDb(raw);
    if (fromDb != null) return fromDb;

    switch (raw) {
      case 'Gasolina 95':
        return FuelType.gasolina95;
      case 'Gasolina 98':
        return FuelType.gasolina98;
      case 'Gasóleo':
        return FuelType.gasoleoSimples;
      case 'Gasóleo Plus':
        return FuelType.gasoleoEspecial;
      case 'GPL':
        return FuelType.gpl;
    }
    return null;
  }

  String? _normalizeBrand(String? raw) {
    if (raw == null) return null;

    final lower = raw
        .trim()
        .toLowerCase()
        // remover acentos mais comuns
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        // remover espaços e pontuação típica
        .replaceAll('.', '')
        .replaceAll('-', '')
        .replaceAll('_', '')
        .replaceAll(' ', '');

    // mapear para keys canónicas
    if (lower.contains('galp')) return 'galp';
    if (lower.contains('repsol')) return 'repsol';
    if (lower.contains('bp')) return 'bp';
    if (lower.contains('prio')) return 'prio';
    if (lower.contains('cepsa')) return 'cepsa';
    if (lower.contains('shell')) return 'shell';
    if (lower.contains('oz')) return 'oz';
    if (lower.contains('alvesbandeira')) return 'alves_bandeira';
    if (lower.contains('auchan')) return 'auchan';
    if (lower.contains('intermarche')) return 'intermarche';
    if (lower.contains('pingodoce')) return 'pingo_doce';
    if (lower.contains('leclerc')) return 'leclerc';
    if (lower.contains('recheio')) return 'recheio';
    if (lower.contains('petroprix')) return 'petroprix';
    if (lower.contains('q8')) return 'q8';

    return lower; // fallback: devolve a string já normalizada
  }

  String? _inferBrandFromStationName(String name) {
    return _normalizeBrand(name);
  }

  Future<void> _loadVehicles() async {
    try {
      final defaultVehicle = await _vehiclesRepository.getDefaultVehicle();
      final all = await _vehiclesRepository.getAllVehicles();

      Vehicle? selected;

      if (defaultVehicle != null) {
        selected = all.firstWhere(
          (v) => v.id == defaultVehicle.id,
          orElse: () => all.isNotEmpty ? all.first : defaultVehicle,
        );
      } else if (all.isNotEmpty) {
        selected = all.first;
      }

      if (!mounted) return;
      setState(() {
        _vehicles = all;
        _selectedVehicle = selected;

        final vehicleFuel = selected?.fuelType;

        if (widget.initialFuelType != null) {
          final mapped = _mapInitialFuelType(widget.initialFuelType);
          if (mapped != null) {
            _fuelType = mapped;
          } else if (vehicleFuel != null) {
            _fuelType = vehicleFuel;
          } else {
            _fuelType = _defaultFuel;
          }
        } else if (vehicleFuel != null) {
          _fuelType = vehicleFuel;
        } else {
          _fuelType = _defaultFuel;
        }

        _loadingVehicles = false;
      });
    } catch (_) {
      debugPrint('Failed to load vehicles: $_');
      if (!mounted) return;
      setState(() {
        _vehicles = [];
        _selectedVehicle = null;
        _loadingVehicles = false;
      });
    }
  }

  Future<List<Coupon>> _loadCoupons() async {
    try {
      final baseCoupons = await _couponsRepository
          .getActiveCouponsForCurrentUser();

      final stationBrand = _normalizeBrand(_stationBrandKey);
      if (stationBrand == null || stationBrand.isEmpty) {
        return baseCoupons;
      }
      return baseCoupons;
    } catch (_) {
      // Silently ignore: coupon load failure is non-critical
      return [];
    }
  }

  /// Cupões ativos filtrados pela brand do posto (se conhecida).
  List<Coupon> _availableCouponsForStation(List<Coupon> all) {
    final stationBrand = _normalizeBrand(_stationBrandKey);

    if (stationBrand == null || stationBrand.isEmpty) {
      return <Coupon>[];
    }

    return all.where((c) {
      final couponBrand = _normalizeBrand(c.brand);
      return couponBrand == stationBrand;
    }).toList();
  }

  bool get _hasKnownBrand =>
      _stationBrandKey != null && _stationBrandKey!.trim().isNotEmpty;

  void _recalculateLiters() {
    final totalRaw = _totalController.text.replaceAll(',', '.');
    final priceRaw = _pricePerLiterController.text.replaceAll(',', '.');

    final total = double.tryParse(totalRaw);
    final price = double.tryParse(priceRaw);

    if (total == null || price == null || price == 0) return;

    final liters = total / price;
    _litersController.text = liters.toStringAsFixed(2);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filledAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _filledAt = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _filledAt.hour,
          _filledAt.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedVehicle == null) {
      // Segurança extra: não deixar gravar sem veículo.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escolhe um veículo antes de guardar o abastecimento.'),
        ),
      );
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tens de iniciar sessão.')));
      return;
    }

    final totalRaw = _totalController.text.replaceAll(',', '.');
    final priceRaw = _pricePerLiterController.text.replaceAll(',', '.');
    final litersRaw = _litersController.text.replaceAll(',', '.');

    final total = double.parse(totalRaw);
    final price = double.parse(priceRaw);
    final liters = double.parse(litersRaw);

    setState(() {
      _isSaving = true;
    });

    try {
      if (isEditing) {
        await _fillUpsRepository.updateFillUp(
          id: widget.existingFillUp!.id,
          stationName: _stationNameController.text.trim().isEmpty
              ? null
              : _stationNameController.text.trim(),
          vehicleId: _selectedVehicle!.id, // novo
          fuelType: _fuelType,
          liters: liters,
          pricePerLiter: price,
          totalPaid: total,
          filledAt: _filledAt,
          userCouponId: _selectedCoupon?.id,
        );
      } else {
        await _fillUpsRepository.addFillUp(
          vehicleId: _selectedVehicle!.id, // novo
          stationName: _stationNameController.text.trim().isEmpty
              ? null
              : _stationNameController.text.trim(),
          fuelType: _fuelType,
          liters: liters,
          pricePerLiter: price,
          totalPaid: total,
          filledAt: _filledAt,
          userCouponId: _selectedCoupon?.id,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao guardar abastecimento: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthNotifier>().state;
    final isGuest = authState.status == AuthStatus.guest;

    if (isGuest) {
      return LoginRequiredScreen.standard(
        context: context,
        message:
            'Para registar e guardar abastecimentos, precisas de iniciar sessão.',
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar abastecimento' : 'Novo abastecimento'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Posto
              TextFormField(
                controller: _stationNameController,
                decoration: const InputDecoration(
                  labelText: 'Posto',
                  hintText: 'Ex.: Galp XYZ',
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (value) {
                  setState(() {
                    if (widget.station != null) {
                      _stationBrandKey = _normalizeBrand(widget.station!.brand);
                    } else {
                      _stationBrandKey = _inferBrandFromStationName(value);
                    }
                    _futureCoupons = _loadCoupons();
                  });
                },
              ),
              const SizedBox(height: 12),

              // Veículo
              if (_loadingVehicles)
                const LinearProgressIndicator()
              else if (_vehicles.isEmpty)
                Text(
                  'Adiciona um veículo na página de Veículos antes de registar abastecimentos.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                )
              else
                DropdownButtonFormField<Vehicle>(
                  initialValue: _vehicles.contains(_selectedVehicle)
                      ? _selectedVehicle
                      : null,
                  decoration: const InputDecoration(labelText: 'Veículo'),
                  items: _vehicles.map((v) {
                    final nickname = v.nickname?.trim() ?? '';
                    final brand = v.brand?.trim() ?? '';
                    final model = v.model?.trim() ?? '';
                    final title = nickname.isNotEmpty
                        ? nickname
                        : [
                            brand,
                            model,
                          ].where((s) => s.isNotEmpty).join(' ').trim();

                    return DropdownMenuItem<Vehicle>(
                      value: v,
                      child: Text(title.isNotEmpty ? title : 'Veículo'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedVehicle = value;
                      if (value.fuelType != null) {
                        _fuelType = value.fuelType!;
                      }
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Escolhe um veículo';
                    }
                    return null;
                  },
                ),

              const SizedBox(height: 12),

              // Combustível (enum)
              FuelTypeDropdown(
                value: _fuelType,
                label: 'Combustível',
                onChanged: (value) {
                  setState(() => _fuelType = value);
                },
              ),

              const SizedBox(height: 12),

              // Data
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_filledAt.day.toString().padLeft(2, '0')}/'
                        '${_filledAt.month.toString().padLeft(2, '0')}/'
                        '${_filledAt.year}',
                        style: textTheme.bodyMedium,
                      ),
                      const Icon(Icons.calendar_today, size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Total pago
              TextFormField(
                controller: _totalController,
                decoration: const InputDecoration(
                  labelText: 'Total pago (€)',
                  hintText: 'Ex.: 60,00',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final raw = (value ?? '').replaceAll(',', '.');
                  final parsed = double.tryParse(raw);
                  if (parsed == null || parsed <= 0) {
                    return 'Introduz um valor válido';
                  }
                  return null;
                },
                onChanged: (_) => _recalculateLiters(),
              ),

              const SizedBox(height: 12),

              // Preço por litro
              TextFormField(
                controller: _pricePerLiterController,
                decoration: const InputDecoration(
                  labelText: 'Preço por litro (€/L)',
                  hintText: 'Ex.: 1,799',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final raw = (value ?? '').replaceAll(',', '.');
                  final parsed = double.tryParse(raw);
                  if (parsed == null || parsed <= 0) {
                    return 'Introduz um valor válido';
                  }
                  return null;
                },
                onChanged: (_) => _recalculateLiters(),
              ),

              const SizedBox(height: 12),

              // Litros
              TextFormField(
                controller: _litersController,
                decoration: const InputDecoration(
                  labelText: 'Litros abastecidos',
                  hintText: 'Ex.: 33,40',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final raw = (value ?? '').replaceAll(',', '.');
                  final parsed = double.tryParse(raw);
                  if (parsed == null || parsed <= 0) {
                    return 'Introduz um valor válido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Cupão
              FutureBuilder<List<Coupon>>(
                future: _futureCoupons,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }

                  final allCoupons = snapshot.data ?? [];
                  final filtered = _availableCouponsForStation(allCoupons);

                  // Sem brand conhecida -> campo desativado
                  if (!_hasKnownBrand) {
                    return TextFormField(
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Escolhe o posto para utilizar cupão',
                        prefixIcon: Icon(Icons.local_offer),
                      ),
                    );
                  }

                  // Com brand mas zero cupões compatíveis
                  if (filtered.isEmpty) {
                    return TextFormField(
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Sem cupões disponíveis',
                        prefixIcon: Icon(Icons.local_offer),
                      ),
                    );
                  }

                  // Há cupões -> dropdown + limpar
                  return Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Coupon>(
                          initialValue: () {
                            if (_selectedCoupon == null) {
                              return null;
                            }
                            final match = filtered.firstWhere(
                              (c) => c.id == _selectedCoupon!.id,
                              orElse: () => _selectedCoupon!,
                            );
                            return filtered.contains(match) ? match : null;
                          }(),
                          decoration: const InputDecoration(
                            labelText: 'Cupão (opcional)',
                            prefixIcon: Icon(Icons.local_offer),
                          ),
                          items: filtered.map((c) {
                            final label = c.uiDisplayName;
                            return DropdownMenuItem<Coupon>(
                              value: c,
                              child: Text(label),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedCoupon = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Remover cupão',
                        icon: const Icon(Icons.close),
                        onPressed: _selectedCoupon == null
                            ? null
                            : () {
                                setState(() {
                                  _selectedCoupon = null;
                                });
                              },
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              LoadingButton(
                isLoading: _isSaving,
                onPressed: _save,
                child: Text(isEditing ? 'Guardar alterações' : 'Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
