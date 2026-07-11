// lib\features\coupons\presentation\widgets\new_coupon_sheet.dart
import 'package:flutter/material.dart';

import '../../../stations/domain/station_brand.dart';
import '../../domain/coupon.dart';
import '../../data/coupons_repository.dart';
import '../../../../core/supabase_client.dart';
import '../../../../shared/widgets/loading_button.dart';

class NewCouponSheet extends StatefulWidget {
  final Coupon? initialCoupon;

  const NewCouponSheet({super.key, this.initialCoupon});

  @override
  State<NewCouponSheet> createState() => _NewCouponSheetState();
}

class _NewCouponSheetState extends State<NewCouponSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();

  String _selectedType = 'per_liter';
  CouponBenefitKind _benefitKind = CouponBenefitKind.directDiscount;
  DateTime? _validUntil;
  bool _isSaving = false;

  String? _brandKey;
  List<Map<String, dynamic>> _availableBrands = [];
  bool _isLoadingBrands = true;

  @override
  void initState() {
    super.initState();
    _loadBrands();

    final initial = widget.initialCoupon;
    if (initial != null) {
      _nameController.text = initial.customName ?? '';
      _valueController.text = initial.discountValue.toStringAsFixed(2);
      _selectedType = initial.discountType;
      _validUntil = initial.validUntil;
      _brandKey = initial.brand;
      _benefitKind = initial.benefitKind;
    }
  }

  Future<void> _loadBrands() async {
    try {
      final res = await supabase
          .from('station_brands_view')
          .select('brand_key, brand_raw');

      final rows = (res as List).cast<Map<String, dynamic>>();

      final seenKeys = <String>{};
      final processed = <Map<String, dynamic>>[];

      for (final row in rows) {
        final key = row['brand_key'] as String;
        final enumBrand = normalizeBrand(key);

        if (enumBrand == StationBrand.other) {
          if (!seenKeys.contains('other')) {
            seenKeys.add('other');
            processed.add({'brand_key': 'other', 'brand_raw': 'Outros postos'});
          }
        } else {
          if (!seenKeys.contains(key)) {
            seenKeys.add(key);
            processed.add(row);
          }
        }
      }

      setState(() {
        _availableBrands = processed;
        _brandKey =
            _brandKey ??
            (processed.isNotEmpty
                ? processed.first['brand_key'] as String
                : null);
        _isLoadingBrands = false;
      });
    } catch (_) {
      setState(() {
        _isLoadingBrands = false;
      });
    }
  }

  String get _discountLabel {
    switch (_selectedType) {
      case 'per_liter':
        return 'Valor por litro (€/L)';
      case 'percent':
        return 'Percentagem (%)';
      case 'fixed':
        return 'Valor do desconto (€)';
      case 'card_cashback':
        return 'Valor em cartão (€)';
      default:
        return 'Valor do desconto';
    }
  }

  String get _discountSuffix {
    switch (_selectedType) {
      case 'per_liter':
        return '€/L';
      case 'percent':
        return '%';
      case 'fixed':
      case 'card_cashback':
        return '€';
      default:
        return '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: _validUntil ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (result != null) {
      setState(() {
        _validUntil = result;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_brandKey == null || _brandKey!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolhe o posto do cupão.')),
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

    final value =
        double.tryParse(_valueController.text.replaceAll(',', '.')) ?? 0;

    setState(() {
      _isSaving = true;
    });

    try {
      final name = _nameController.text.trim();
      final initial = widget.initialCoupon;

      if (initial == null) {
        final coupon = Coupon(
          id: '',
          userId: user.id,
          customName: name.isEmpty ? null : name,
          code: null,
          codeOverride: null,
          discountType: _selectedType,
          discountValue: value,
          validUntil: _validUntil,
          isActive: true,
          brand: _brandKey,
          timesUsed: 0,
          usageLimit: 1,
          benefitKind: _benefitKind,
        );

        await CouponsRepository().addCoupon(coupon);
      } else {
        final patch = <String, dynamic>{
          'custom_name': name.isEmpty ? null : name,
          'discount_type': _selectedType,
          'discount_value': value,
          'valid_until': _validUntil?.toIso8601String().split('T').first,
          'brand': _brandKey,
          'benefit_kind': _benefitKind == CouponBenefitKind.cardBalance
              ? 'card_balance'
              : 'direct_discount',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };

        await CouponsRepository().updateCoupon(initial.id, patch);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao guardar cupão: $e')));
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final validLabel = _validUntil != null
        ? '${_validUntil!.day.toString().padLeft(2, '0')}/'
              '${_validUntil!.month.toString().padLeft(2, '0')}/'
              '${_validUntil!.year}'
        : 'Sem data';

    final isEditing = widget.initialCoupon != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Editar cupão' : 'Novo cupão',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do cupão (opcional)',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.local_offer, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isEditing
                              ? 'Atualiza os dados deste cupão ativo.'
                              : 'Este cupão será guardado na tua conta e aplicado nos cálculos de desconto.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _BrandDropdown(
                    isLoading: _isLoadingBrands,
                    availableBrands: _availableBrands,
                    value: _brandKey,
                    onChanged: (value) {
                      setState(() => _brandKey = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  _DiscountTypeDropdown(
                    value: _selectedType,
                    onChanged: (value) {
                      setState(() => _selectedType = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _valueController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: _discountLabel,
                      prefixIcon: const Icon(Icons.euro),
                      suffixText: _discountSuffix,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Indica o valor do desconto';
                      }
                      final v = double.tryParse(value.replaceAll(',', '.'));
                      if (v == null || v <= 0) {
                        return 'Valor inválido';
                      }
                      if (_selectedType == 'percent' && (v <= 0 || v > 100)) {
                        return 'Percentagem deve ser entre 0 e 100';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.calendar_today,
                      color: colorScheme.primary,
                    ),
                    title: const Text('Validade'),
                    subtitle: Text(validLabel),
                    trailing: TextButton(
                      onPressed: _pickDate,
                      child: const Text('Escolher data'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Benefício do cupão',
                      style: textTheme.titleSmall,
                    ),
                  ),
                  RadioGroup<CouponBenefitKind>(
                    groupValue: _benefitKind,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _benefitKind = value);
                    },
                    child: Column(
                      children: [
                        RadioListTile<CouponBenefitKind>(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Desconto direto na bomba'),
                          value: CouponBenefitKind.directDiscount,
                        ),
                        RadioListTile<CouponBenefitKind>(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Saldo em cartão/app'),
                          value: CouponBenefitKind.cardBalance,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  LoadingButton(
                    isLoading: _isSaving,
                    onPressed: _save,
                    child: Text(isEditing ? 'Guardar alterações' : 'Guardar'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(color: colorScheme.outline),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandDropdown extends StatelessWidget {
  final bool isLoading;
  final List<Map<String, dynamic>> availableBrands;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _BrandDropdown({
    required this.isLoading,
    required this.availableBrands,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Posto do cupão',
        prefixIcon: Icon(Icons.local_gas_station),
      ),
      items: isLoading
          ? const []
          : availableBrands.map((row) {
              final key = row['brand_key'] as String;
              final enumBrand = key == 'other'
                  ? StationBrand.other
                  : normalizeBrand(key);
              final label = stationBrandLabel(enumBrand);

              return DropdownMenuItem<String>(value: key, child: Text(label));
            }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Escolhe o posto do cupão';
        }
        return null;
      },
    );
  }
}

class _DiscountTypeDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _DiscountTypeDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Tipo de desconto'),
      items: const [
        DropdownMenuItem<String>(value: 'per_liter', child: Text('Cênt./L')),
        DropdownMenuItem<String>(
          value: 'percent',
          child: Text('Percentagem %'),
        ),
        DropdownMenuItem<String>(value: 'fixed', child: Text('Valor fixo €')),
        DropdownMenuItem<String>(
          value: 'card_cashback',
          child: Text('€ em cartão'),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;
        onChanged(value);
      },
    );
  }
}
